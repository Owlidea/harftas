import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../app/app_model.dart';
import '../../config/asset_paths.dart';
import '../../core/core.dart';
import '../../progress/calendar.dart';
import '../../progress/missions.dart';
import '../../progress/progression.dart';
import '../../progress/summaries.dart';
import '../../services/ads_service.dart';
import '../../services/analytics.dart';
import '../../services/haptics_service.dart';
import '../theme/tokens.dart';
import 'fx_art.dart';
import 'tile_renderer.dart';

/// UI state machine (spec 14): Idle -> Dragging -> Resolving -> Idle | Over.
/// Input is locked while resolving.
enum UiPhase { idle, dragging, resolving, pickJokerCell, pickJokerLetter, pickHammerCell, stuck, over }

sealed class GameToast {
  const GameToast();
}

class MissionToast extends GameToast {
  const MissionToast(this.mission);
  final Mission mission;
}

class LevelToast extends GameToast {
  const LevelToast(this.reward);
  final LevelUpReward reward;
}

class WeeklyToast extends GameToast {
  const WeeklyToast(this.goal);
  final WeeklyGoal goal;
}

class TextToast extends GameToast {
  const TextToast(this.kind);
  final TextToastKind kind;
}

enum TextToastKind { dailyNoPowerups, noPowerupLeft }

/// Floating label (word score, combo, board clear).
class ScorePopup {
  ScorePopup(this.painter, this.at, this.startMs, {this.big = false});
  final TextPainter painter;
  final Offset at; // board-local
  final double startMs;
  final bool big;
}

/// A sprite-sheet effect playing on the board canvas (tile pop, dust puff,
/// hammer, joker). [center] is board-local.
class BoardFx {
  BoardFx(this.sheet, this.center, this.size, this.startMs);
  final FxSheet sheet;
  final Offset center;
  final double size;
  final double startMs;
}

/// The "×N" combo flourish: burst sheet plus a 3D numeral popped by code.
class ComboFx {
  ComboFx(this.count, this.center, this.startMs);
  final int count;
  final Offset center; // board-local
  final double startMs;

  static const double durationMs = 900;
}

/// A one-shot sprite sheet played by the game screen above everything.
class OverlayFx {
  const OverlayFx(this.asset, {this.align = const Alignment(0, -0.18), this.size = 340});
  final String asset;
  final Alignment align;
  final double size;
}

/// Board geometry in global coordinates, measured by the screen.
class BoardGeometry {
  const BoardGeometry(this.rect);
  final Rect rect;

  double get padding => rect.width * 0.022;
  double get gap => rect.width * 0.012;
  double get cell => (rect.width - 2 * padding - 7 * gap) / 8;
  double get step => cell + gap;

  /// Local rect of cell (x, y).
  Rect cellRect(int x, int y) => Rect.fromLTWH(padding + x * step, padding + y * step, cell, cell);
  Rect cellRectIndex(int i) => cellRect(Grid.xOf(i), Grid.yOf(i));

  Size pieceSize(Shape s, [double scale = 1]) =>
      Size((s.width * cell + (s.width - 1) * gap) * scale, (s.height * cell + (s.height - 1) * gap) * scale);

  /// Cell under a global point, or null.
  int? cellAt(Offset global) {
    final l = global - rect.topLeft;
    final x = ((l.dx - padding) / step).floor();
    final y = ((l.dy - padding) / step).floor();
    if (x < 0 || y < 0 || x > 7 || y > 7) return null;
    return Grid.indexOf(x, y);
  }
}

class GameController extends ChangeNotifier {
  GameController({required this.app, required GameState state, this.dailyDay, this.tutorial = false, this.onResolved})
    : _state = state,
      displayGrid = state.grid.copy(),
      scoreFrom = state.score,
      scoreTo = state.score {
    placedAt.fillRange(0, 64, _never);
    highlightAt.fillRange(0, 64, _never);
    clearAt.fillRange(0, 64, _never);
    phase = _phaseFor(state);
    if (state.isOver) _onGameOver(initial: true);
  }

  static const double _never = -1e12;

  /// Sentinel threshold: timestamps above this are real.
  static const double never = -1e11;

  /// Test hook: replaces the wall clock (milliseconds).
  @visibleForTesting
  static double Function()? debugNow;

  final AppModel app;
  final DayKey? dailyDay;
  final bool tutorial;
  final void Function(GameAction action, List<GameEvent> events)? onResolved;

  /// The engine of the game's own word language (karar 29).
  GameEngine get engine => app.engineFor(_state.language)!;

  GameState _state;
  GameState get state => _state;
  Grid displayGrid;
  UiPhase phase = UiPhase.idle;
  bool reduceMotion = false;

  /// Bumped every animation frame; painters listen to this, not to the
  /// controller, so widgets do not rebuild per frame.
  final ValueNotifier<int> frame = ValueNotifier(0);

  final Stopwatch _clock = Stopwatch()..start();
  double get nowMs => debugNow?.call() ?? _clock.elapsedMicroseconds / 1000;
  double _animUntil = 0;
  Duration _lastTick = Duration.zero;

  final Float64List placedAt = Float64List(64);
  final Float64List highlightAt = Float64List(64);
  final Float64List clearAt = Float64List(64);
  double handDealtAt = _never;

  int scoreFrom;
  int scoreTo;
  double scoreAt = _never;
  final List<ScorePopup> popups = [];
  double shakeAt = _never;
  double shakeAmp = 0;
  final ParticlePool particles = ParticlePool();

  BoardGeometry? geometry;
  final Map<int, Offset> slotCenters = {};

  // Drag
  int? dragPiece;
  Offset dragPointer = Offset.zero;
  ({int x, int y})? dragTarget;
  PlacementPreview? dragPreview;

  // Return-to-hand spring
  int? returningPiece;
  Offset returnFrom = Offset.zero;
  double returnAt = _never;

  /// "+N" bubble for the current drag preview (built once per change).
  TextPainter? previewLabel;

  int? selectedPiece;
  int? jokerCell;

  GameEndResult? endResult;
  bool endRecorded = false;
  final List<GameToast> toasts = [];

  /// One-shot celebration sprite sheets to play over the screen; drained by
  /// the game screen.
  final List<OverlayFx> effects = [];

  /// Sprite effects painted by the board itself.
  final List<BoardFx> boardFx = [];
  ComboFx? comboFx;
  final List<Timer> _timers = [];
  Palette? _palette;

  set palette(Palette p) => _palette = p;

  // ------------------------------------------------------------- frames

  bool get animating =>
      nowMs < _animUntil ||
      particles.active ||
      dragPiece != null ||
      returningPiece != null ||
      popups.isNotEmpty ||
      boardFx.isNotEmpty ||
      comboFx != null;

  void tick(Duration elapsed) {
    final dt = ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0, 0.05).toDouble();
    _lastTick = elapsed;
    particles.update(dt);
    final now = nowMs;
    popups.removeWhere((p) => now - p.startMs > Motion.scoreFloat.inMilliseconds + 400);
    boardFx.removeWhere((f) => now - f.startMs > f.sheet.grid.durationMs);
    final cf = comboFx;
    if (cf != null && now - cf.startMs > ComboFx.durationMs) comboFx = null;
    if (returningPiece != null && now - returnAt > Motion.returnToHand.inMilliseconds) {
      returningPiece = null;
    }
    frame.value++;
  }

  double get displayedScore {
    final t = ((nowMs - scoreAt) / Motion.counter.inMilliseconds).clamp(0, 1).toDouble();
    return scoreFrom + (scoreTo - scoreFrom) * Curves.easeOut.transform(t);
  }

  // ------------------------------------------------------------- drag

  bool get inputLocked => phase == UiPhase.resolving || phase == UiPhase.over;

  bool startDrag(int piece, Offset pointer) {
    if (inputLocked || phase == UiPhase.stuck || state.hand[piece] == null) return false;
    if (phase == UiPhase.pickHammerCell || phase == UiPhase.pickJokerCell) phase = UiPhase.idle;
    if (nowMs < handDealtAt) return false;
    dragPiece = piece;
    selectedPiece = null;
    dragPointer = pointer;
    phase = UiPhase.dragging;
    _feedback(SoundId.pick, null);
    _updateTarget();
    notifyListeners();
    return true;
  }

  void updateDrag(Offset pointer) {
    if (dragPiece == null) return;
    dragPointer = pointer;
    final before = dragTarget;
    _updateTarget();
    if (before != dragTarget) notifyListeners();
  }

  /// Global top-left of the dragged piece (lifted above the finger).
  Offset dragTopLeft(Shape s) {
    final g = geometry!;
    final size = g.pieceSize(s, Motion.dragScale);
    final lift = Motion.dragLift + size.height / 2;
    final leftHand = app.settings.leftHanded ? 12.0 : 0.0;
    return dragPointer - Offset(size.width / 2 - leftHand, lift + size.height / 2);
  }

  void _updateTarget() {
    final g = geometry;
    final i = dragPiece;
    if (g == null || i == null) return;
    final shape = state.hand[i]!.shape;
    // Compare using the unscaled size so the ghost sits under the piece.
    final tl =
        dragTopLeft(shape) +
        Offset(
              g.pieceSize(shape, Motion.dragScale).width - g.pieceSize(shape).width,
              g.pieceSize(shape, Motion.dragScale).height - g.pieceSize(shape).height,
            ) /
            2;
    final fx = (tl.dx - g.rect.left - g.padding) / g.step;
    final fy = (tl.dy - g.rect.top - g.padding) / g.step;
    ({int x, int y})? best;
    var bestD = 0.9; // magnet radius in cells
    for (var y = fy.floor() - 1; y <= fy.ceil() + 1; y++) {
      for (var x = fx.floor() - 1; x <= fx.ceil() + 1; x++) {
        if (!shape.fits(state.grid, x, y)) continue;
        final d = math.sqrt((x - fx) * (x - fx) + (y - fy) * (y - fy));
        if (d < bestD) {
          bestD = d;
          best = (x: x, y: y);
        }
      }
    }
    if (best != dragTarget) {
      dragTarget = best;
      dragPreview = best == null ? null : engine.preview(state, i, best.x, best.y);
      final pv = dragPreview;
      final pal = _palette;
      previewLabel = pv == null || pv.hits.isEmpty || pal == null
          ? null
          : _label('+${pv.score.wordPoints}', pal.onAccent, g.cell * 0.34);
    }
  }

  void endDrag() {
    final i = dragPiece;
    if (i == null) return;
    final target = dragTarget;
    dragPiece = null;
    dragTarget = null;
    dragPreview = null;
    if (target == null) {
      returningPiece = i;
      returnFrom = dragPointer;
      returnAt = nowMs;
      phase = _phaseFor(state);
      _feedback(SoundId.invalid, HapticKind.invalid);
      notifyListeners();
      return;
    }
    _apply(PlaceAction(i, target.x, target.y));
  }

  void cancelDrag() {
    if (dragPiece == null) return;
    dragPiece = null;
    dragTarget = null;
    dragPreview = null;
    phase = _phaseFor(state);
    notifyListeners();
  }

  /// Tap-to-place (accessibility alternative to dragging).
  void tapPiece(int i) {
    if (inputLocked || state.hand[i] == null) return;
    selectedPiece = selectedPiece == i ? null : i;
    if (phase == UiPhase.pickHammerCell || phase == UiPhase.pickJokerCell) phase = UiPhase.idle;
    _feedback(SoundId.pick, HapticKind.button);
    notifyListeners();
  }

  void tapCell(int index) {
    if (inputLocked) return;
    switch (phase) {
      case UiPhase.pickHammerCell:
        if (state.grid.isFilled(index)) _apply(HammerAction(Grid.xOf(index), Grid.yOf(index)));
        return;
      case UiPhase.pickJokerCell:
        if (!state.grid.isFilled(index)) {
          jokerCell = index;
          phase = UiPhase.pickJokerLetter;
          notifyListeners();
        }
        return;
      default:
        break;
    }
    final sel = selectedPiece;
    if (sel == null || state.hand[sel] == null) return;
    final first = state.hand[sel]!.shape.cells.first;
    final x = Grid.xOf(index) - first.dx;
    final y = Grid.yOf(index) - first.dy;
    if (engine.canPlace(state, sel, x, y)) {
      selectedPiece = null;
      _apply(PlaceAction(sel, x, y));
    } else {
      _feedback(SoundId.invalid, HapticKind.invalid);
    }
  }

  // ---------------------------------------------------------- powerups

  void tapPowerup(PowerupType t) {
    if (inputLocked) return;
    if (state.mode == GameMode.daily) {
      toasts.add(const TextToast(TextToastKind.dailyNoPowerups));
      notifyListeners();
      return;
    }
    if (state.powerup(t) <= 0) {
      toasts.add(const TextToast(TextToastKind.noPowerupLeft));
      notifyListeners();
      return;
    }
    selectedPiece = null;
    switch (t) {
      case PowerupType.refresh:
        _apply(const RefreshAction());
      case PowerupType.joker:
        phase = phase == UiPhase.pickJokerCell ? _phaseFor(state) : UiPhase.pickJokerCell;
        notifyListeners();
      case PowerupType.hammer:
        phase = phase == UiPhase.pickHammerCell ? _phaseFor(state) : UiPhase.pickHammerCell;
        notifyListeners();
    }
  }

  void chooseJokerLetter(String? letter) {
    final cell = jokerCell;
    jokerCell = null;
    if (letter == null || cell == null) {
      phase = _phaseFor(state);
      notifyListeners();
      return;
    }
    _apply(JokerAction(Grid.xOf(cell), Grid.yOf(cell), letter));
  }

  void endGame() {
    if (phase == UiPhase.stuck) _apply(const EndAction());
  }

  /// Bonus XP the rewarded "2x XP" already paid for this game.
  int xpBonus = 0;

  /// Offered once per game, and only when there is something worth doubling.
  bool get canDoubleXp => !tutorial && phase == UiPhase.over && xpBonus == 0 && (endResult?.xpGained ?? 0) >= 10;

  /// Rewarded "2x XP": pays this game's XP a second time, right away.
  Future<void> doubleXp() async {
    if (!canDoubleXp) return;
    final xp = endResult!.xpGained;
    if (!await app.watchRewarded(RewardPlacement.doubleXp)) return;
    xpBonus = xp;
    app.services.analytics.log(AnalyticsEvent.xpDoubled, {'xp': xp});
    final ups = app.grantBonusXp(xp);
    for (final l in ups) {
      toasts.add(LevelToast(l));
      if (!reduceMotion) effects.add(const OverlayFx(AssetPaths.fxLevelUp));
    }
    if (ups.isNotEmpty) _feedback(SoundId.levelUp, null);
    // A classic result is only a preview until the player leaves: redo it so
    // the "next goal" line counts the bonus.
    if (!endRecorded) endResult = app.previewGameEnd(state);
    notifyListeners();
  }

  bool get canContinue =>
      !tutorial &&
      state.mode == GameMode.classic &&
      state.isOver &&
      state.overReason == GameOverReason.noFit &&
      !state.continueUsed &&
      !endRecorded;

  Future<void> continueGame() async {
    if (!canContinue) return;
    final ok = await app.watchRewarded(RewardPlacement.continueGame);
    if (!ok) return;
    app.services.analytics.log(AnalyticsEvent.continueUsed);
    endResult = null;
    _apply(const ContinueAction());
  }

  /// Records an unrecorded classic result and shows an interstitial if due.
  Future<void> leaveFinishedGame() async {
    if (tutorial || !state.isOver) return;
    if (!endRecorded) {
      endRecorded = true;
      endResult = await app.recordGameEnd(state);
    }
    await app.maybeInterstitial(state.mode);
  }

  /// Animates the current hand in (screen opened / game resumed).
  void playEntrance() {
    handDealtAt = nowMs;
    _animUntil = nowMs + Motion.handIn.inMilliseconds + 3 * Motion.handStagger.inMilliseconds + 50;
  }

  void reset(GameState s) {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _state = s;
    displayGrid = s.grid.copy();
    placedAt.fillRange(0, 64, _never);
    highlightAt.fillRange(0, 64, _never);
    clearAt.fillRange(0, 64, _never);
    scoreFrom = scoreTo = s.score;
    popups.clear();
    particles.clear();
    boardFx.clear();
    comboFx = null;
    xpBonus = 0;
    endResult = null;
    endRecorded = false;
    selectedPiece = null;
    handDealtAt = nowMs;
    _animUntil = nowMs + Motion.handIn.inMilliseconds + 3 * Motion.handStagger.inMilliseconds;
    phase = _phaseFor(s);
    notifyListeners();
  }

  // ------------------------------------------------------------ resolve

  void _apply(GameAction action) {
    final before = _state;
    final StepResult r;
    try {
      r = engine.apply(before, action);
    } on InvalidActionException catch (e, st) {
      app.services.crash.record(e, st, reason: 'invalid action from UI');
      phase = _phaseFor(before);
      notifyListeners();
      return;
    }
    _state = r.state;
    final events = r.events;
    final t0 = nowMs;
    final g = geometry;

    // Board as it looks right after placement, before explosions.
    final pre = before.grid.copy();
    var placedCells = 0;
    final placedIdx = <int>[];
    int? jokerIdx;
    for (final e in events) {
      if (e is PiecePlaced) {
        final piece = before.hand[e.pieceIndex]!;
        // Event cells are ascending grid indices = the shape's reading order.
        for (var k = 0; k < piece.size; k++) {
          final idx = e.cells[k];
          pre.set(idx, Cell(piece.letters[k]));
          placedAt[idx] = t0;
          placedCells++;
          placedIdx.add(idx);
        }
      } else if (e is JokerPlaced) {
        pre.set(e.cell, Cell(e.letter, isJoker: true));
        placedAt[e.cell] = t0;
        jokerIdx = e.cell;
      }
    }
    displayGrid = pre;

    final hits = [for (final e in events.whereType<WordsFound>()) ...e.hits];
    final score = events.whereType<ScoreAwarded>().lastOrNull;
    var end = t0 + (placedCells > 0 || events.any((e) => e is JokerPlaced) ? Motion.settle.inMilliseconds : 0);
    final hiStart = t0 + Motion.settle.inMilliseconds;
    final popStart = hiStart + Motion.wordHighlight.inMilliseconds;

    // Rendered sprite effects (optional art, see FxArt); none with reduced motion.
    void fx(String name, int cell, double cells, double startMs) {
      final sheet = FxArt.sheet(name);
      if (g == null || sheet == null || reduceMotion) return;
      boardFx.add(BoardFx(sheet, g.cellRectIndex(cell).center, g.cell * cells, startMs));
    }

    if (jokerIdx != null) fx(FxArt.joker, jokerIdx, 3.0, t0);
    // The mallet lands ~230 ms into its sheet; the tile breaks on impact.
    var hammerDelay = 0.0;
    if (action is HammerAction && g != null && !reduceMotion && FxArt.sheet(FxArt.hammer) != null) {
      hammerDelay = 233;
      fx(FxArt.hammer, Grid.indexOf(action.x, action.y), 3.2, t0);
    }

    if (hits.isNotEmpty) {
      final popped = <int>{};
      for (final h in hits) {
        for (var k = 0; k < h.cells.length; k++) {
          final c = h.cells[k];
          highlightAt[c] = hiStart;
          final at = popStart + k * Motion.popPerLetter.inMilliseconds;
          clearAt[c] = clearAt[c] > t0 ? math.min(clearAt[c], at) : at;
          end = math.max(end, at + Motion.pop.inMilliseconds);
          if (popped.add(c)) fx(FxArt.tilePop, c, 2.6, at);
        }
      }
    }
    for (final e in events.whereType<CellsCleared>()) {
      if (hits.isNotEmpty) continue;
      // Hammer / continue: pop row by row, left to right.
      for (var k = 0; k < e.cells.length; k++) {
        final at = t0 + hammerDelay + (e.cells.length > 1 ? (k % 8) * Motion.popPerLetter.inMilliseconds : 0);
        clearAt[e.cells[k]] = at;
        end = math.max(end, at + Motion.pop.inMilliseconds);
        fx(FxArt.tilePop, e.cells[k], 2.6, at);
      }
    }

    if (score != null && score.score.total > 0) {
      scoreFrom = displayedScore.round();
      scoreTo = _state.score;
      scoreAt = hits.isNotEmpty ? popStart : t0;
    } else {
      scoreFrom = scoreTo = _state.score;
    }

    final dealt = events.whereType<HandDealt>().isNotEmpty;
    if (dealt) handDealtAt = end;
    _animUntil = end + (dealt ? Motion.handIn.inMilliseconds + 3 * Motion.handStagger.inMilliseconds : 0) + 50;
    // The landing ring outlasts the settle bounce.
    if (placedIdx.isNotEmpty) _animUntil = math.max(_animUntil, t0 + Motion.landRing.inMilliseconds + 20);

    // Feedback, popups, particles, shake.
    final pal = _palette;
    if (placedCells > 0) _feedback(SoundId.drop, HapticKind.place);
    if (action is RefreshAction) {
      _feedback(SoundId.puRefresh, HapticKind.word);
      if (!reduceMotion) effects.add(const OverlayFx(AssetPaths.fxRefresh, align: Alignment(0, 0.70), size: 190));
    }
    if (action is JokerAction) _feedback(SoundId.puJoker, HapticKind.place);
    if (action is HammerAction) _at(t0 + hammerDelay, () => _feedback(SoundId.puHammer, HapticKind.word));
    if (hits.isNotEmpty && g != null) {
      final maxLen = hits.map((h) => h.length).reduce(math.max);
      final combo = hits.length;
      _at(
        hiStart,
        () => _feedback(
          maxLen >= 7 ? SoundId.wordL : (maxLen >= 5 ? SoundId.wordM : SoundId.wordS),
          combo >= 2 ? HapticKind.combo : HapticKind.word,
        ),
      );
      if (combo >= 2) {
        _at(
          popStart,
          () => _feedback(combo >= 4 ? SoundId.combo3 : (combo == 3 ? SoundId.combo2 : SoundId.combo1), null),
        );
      }
      final streak = score?.streakAfter ?? 0;
      if (streak >= 2) {
        // Each streak step climbs the pentatonic scale (C D E G A C …).
        const steps = [0, 2, 4, 7, 9, 12, 14, 16];
        final semis = steps[math.min(streak - 2, steps.length - 1)];
        _at(popStart + 120, () => app.services.audio.play(SoundId.streakUp, pitch: math.pow(2, semis / 12).toDouble()));
      }
      if ((score?.score.clearBonus ?? 0) > 0) {
        _at(end, () {
          _feedback(SoundId.boardClear, HapticKind.combo);
          if (!reduceMotion) {
            effects.add(const OverlayFx(AssetPaths.fxBoardClear));
            notifyListeners();
          }
        });
      }
      if (!reduceMotion && pal != null) {
        _at(popStart, () {
          for (final h in hits) {
            for (final c in h.cells) {
              // The rendered shards carry the pop; keep only a sprinkle of theme colour.
              final n = FxArt.sheet(FxArt.tilePop) != null ? 1 + combo : 3 + combo * 2;
              particles.spawn(g.cellRectIndex(c).center, pal.highlight, n, g.cell * 5, g.cell * 0.18);
            }
          }
        });
        if (combo >= 3) {
          shakeAt = popStart;
          shakeAmp = g.cell * (combo >= 4 ? 0.12 : 0.07);
        }
      }
      if (pal != null) {
        // One popup per move at the centre of all exploding cells.
        var cx = 0.0, cy = 0.0, n = 0;
        for (final h in hits) {
          for (final c in h.cells) {
            final r = g.cellRectIndex(c);
            cx += r.center.dx;
            cy += r.center.dy;
            n++;
          }
        }
        final at = Offset(cx / n, cy / n);
        popups.add(
          ScorePopup(_label('+${score?.score.wordPoints ?? 0}', pal.ink, g.cell * 0.62), at, popStart, big: true),
        );
        if (combo >= 2) {
          final art = !reduceMotion && FxArt.sheet(FxArt.comboBurst) != null && FxArt.sheet(FxArt.comboNums) != null;
          if (art) {
            // Below the "+N" label, kept inside the board.
            final m = g.cell * 1.4;
            final size = g.rect.size;
            comboFx = ComboFx(
              combo,
              Offset(at.dx.clamp(m, size.width - m), (at.dy + g.cell * 1.2).clamp(m, size.height - m)),
              popStart + 60,
            );
          } else {
            popups.add(
              ScorePopup(_label('×$combo', pal.highlight, g.cell * 0.46), at + Offset(0, g.cell * 0.7), popStart + 80),
            );
          }
        }
        if ((score?.score.clearBonus ?? 0) > 0) {
          popups.add(
            ScorePopup(_label('+100', pal.success, g.cell * 0.7), g.rect.size.center(Offset.zero), end, big: true),
          );
        }
      }
    }

    phase = UiPhase.resolving;
    selectedPiece = null;
    notifyListeners();

    // Persist immediately (spec 7.1: save after every move).
    if (!tutorial) {
      unawaited(app.saveGame(_state, dailyDay));
      final summary = MoveSummary.fromEvents(action, events);
      _logAnalytics(action, summary);
      if (action is! ContinueAction && action is! EndAction) {
        final rec = app.recordMove(summary);
        _adoptGrants();
        for (final m in rec.missions) {
          toasts.add(MissionToast(m));
        }
        if (rec.weekly != null) toasts.add(WeeklyToast(rec.weekly!));
        if (!reduceMotion && (rec.missions.isNotEmpty || rec.weekly != null)) {
          // A reward was just paid out: the gift opens under the toast.
          effects.add(const OverlayFx(AssetPaths.fxGiftOpen, align: Alignment(0, -0.56), size: 170));
        }
        for (final l in rec.levelUps) {
          toasts.add(LevelToast(l));
          if (!reduceMotion) effects.add(const OverlayFx(AssetPaths.fxLevelUp));
        }
      }
    }

    _timers.add(Timer(Duration(microseconds: ((end - t0) * 1000).round()), () => _finish(action, events)));
  }

  void _finish(GameAction action, List<GameEvent> events) {
    displayGrid = _state.grid.copy();
    for (var i = 0; i < 64; i++) {
      if (!displayGrid.isFilled(i)) {
        clearAt[i] = _never;
        highlightAt[i] = _never;
      }
    }
    phase = _phaseFor(_state);
    notifyListeners();
    onResolved?.call(action, events);
    if (_state.isOver) _onGameOver();
  }

  Future<void> _onGameOver({bool initial = false}) async {
    if (tutorial) return;
    phase = UiPhase.over;
    if (!initial) _feedback(SoundId.gameOver, null);
    if (state.mode == GameMode.daily) {
      if (!app.dailyDoneToday) {
        endRecorded = true;
        endResult = await app.recordGameEnd(state);
      } else {
        endRecorded = true;
        endResult = null;
      }
    } else {
      endResult = app.previewGameEnd(state);
    }
    if (endResult?.newRecord ?? false) {
      _at(nowMs + 500, () => _feedback(SoundId.newRecord, HapticKind.combo));
    }
    for (final r in endResult?.rewards ?? const <Reward>[]) {
      if (r is LevelUpReward) _at(nowMs + 900, () => _feedback(SoundId.levelUp, null));
    }
    notifyListeners();
  }

  /// Rewards paid mid-game (missions, levels, the weekly goal) are recorded
  /// in the saved classic game by the app model; pick that state up so the
  /// new powerups are usable now and survive the next save.
  void _adoptGrants() {
    final saved = app.savedClassic;
    if (tutorial || _state.mode != GameMode.classic || saved == null || identical(saved, _state)) return;
    if (saved.seed == _state.seed && saved.actions.length > _state.actions.length) _state = saved;
  }

  UiPhase _phaseFor(GameState s) => switch (s.status) {
    GameStatus.over => UiPhase.over,
    GameStatus.stuck => UiPhase.stuck,
    GameStatus.playing => UiPhase.idle,
  };

  void _at(double ms, VoidCallback f) {
    final delay = ms - nowMs;
    if (delay <= 0) {
      f();
    } else {
      _timers.add(Timer(Duration(microseconds: (delay * 1000).round()), f));
    }
  }

  void _feedback(SoundId? sound, HapticKind? haptic) {
    if (sound != null) app.services.audio.play(sound);
    if (haptic != null) app.services.haptics.play(haptic);
  }

  TextPainter _label(String text, Color color, double size) => TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color, height: 1, fontFamily: 'AppFont'),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  void _logAnalytics(GameAction a, MoveSummary m) {
    final an = app.services.analytics;
    if (a is PlaceAction) an.log(AnalyticsEvent.move, {'placed_cells': m.placedCells, 'words': m.words.length});
    for (final w in m.words) {
      an.log(AnalyticsEvent.wordFormed, {'length': w.length, 'score': w.score});
    }
    if (m.combo >= 2) an.log(AnalyticsEvent.combo, {'n': m.combo});
    if (m.powerup != null) an.log(AnalyticsEvent.powerupUsed, {'type': m.powerup!.name});
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    frame.dispose();
    super.dispose();
  }
}

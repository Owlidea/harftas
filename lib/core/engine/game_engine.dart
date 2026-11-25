import '../config/balance_config.dart';
import '../dictionary.dart';
import '../gen/hand_generator.dart';
import '../model/game_action.dart';
import '../model/game_state.dart';
import '../model/grid.dart';
import '../model/piece.dart';
import '../rules/placement.dart';
import '../rules/scoring.dart';
import '../rules/word_detector.dart';
import 'game_event.dart';

class InvalidActionException implements Exception {
  const InvalidActionException(this.message);
  final String message;
  @override
  String toString() => 'InvalidActionException: $message';
}

class StepResult {
  const StepResult(this.state, this.events);
  final GameState state;
  final List<GameEvent> events;
}

/// Result of a hypothetical placement (drag preview, spec 10).
class PlacementPreview {
  const PlacementPreview(this.hits, this.score);
  final List<WordHit> hits;
  final MoveScore score;
}

/// Pure game rules. Same engine + same (seed, mode, powerups, actions)
/// always yields the same state (spec 7.3, 17).
///
/// One engine per word language: [config] and [dictionary] must be of the
/// same language, and an engine only accepts states of its own language.
class GameEngine {
  GameEngine({required this.config, required this.dictionary, WordDictionary? common})
    : detector = WordDetector(config, dictionary),
      hands = HandGenerator(config, common: common ?? SetWordDictionary.empty);

  final BalanceConfig config;
  final WordDictionary dictionary;
  final WordDetector detector;
  final HandGenerator hands;

  Map<PowerupType, int> defaultPowerups(GameMode mode) => {
    for (final t in PowerupType.values) t: mode == GameMode.daily ? 0 : config.initialPowerups,
  };

  GameState newGame({
    required int seed,
    required GameMode mode,
    required DateTime startedAt,
    Map<PowerupType, int>? powerups,
  }) {
    final pw = mode == GameMode.daily
        ? defaultPowerups(GameMode.daily)
        : Map<PowerupType, int>.unmodifiable(powerups ?? defaultPowerups(mode));
    final grid = Grid.empty();
    final hand = _deal(seed, 0, 0, grid, mode);
    final s = GameState(
      language: config.language.code,
      mode: mode,
      seed: seed,
      grid: grid,
      hand: List.unmodifiable(hand),
      score: 0,
      streak: 0,
      bestStreak: 0,
      powerups: pw,
      initialPowerups: pw,
      handCounter: 1,
      actions: const [],
      startedAt: startedAt,
      status: GameStatus.playing,
      overReason: null,
      continueUsed: false,
      wordCount: 0,
      longestWord: '',
      bestWord: '',
      bestWordScore: 0,
    );
    return _settle(s, <GameEvent>[]).state;
  }

  GameState replay({
    required int seed,
    required GameMode mode,
    required DateTime startedAt,
    required Map<PowerupType, int> initialPowerups,
    required List<GameAction> actions,
  }) {
    var s = newGame(seed: seed, mode: mode, startedAt: startedAt, powerups: initialPowerups);
    for (final a in actions) {
      s = apply(s, a).state;
    }
    return s;
  }

  StepResult apply(GameState s, GameAction a) {
    _requireLanguage(s);
    final StepResult r = switch (a) {
      PlaceAction() => _place(s, a),
      RefreshAction() => _refresh(s),
      JokerAction() => _joker(s, a),
      HammerAction() => _hammer(s, a),
      ContinueAction() => _continue(s),
      EndAction() => _end(s),
      GrantAction() => _grant(s, a),
    };
    return StepResult(r.state.copyWith(actions: List.unmodifiable([...s.actions, a])), List.unmodifiable(r.events));
  }

  /// Recomputes status / refills for a state built outside [apply]
  /// (e.g. loaded from storage). Does not record an action.
  GameState revalidate(GameState s) {
    _requireLanguage(s);
    return s.isOver ? s : _settle(s, <GameEvent>[]).state;
  }

  void _requireLanguage(GameState s) {
    if (s.language != config.language.code) {
      throw InvalidActionException('${s.language} game given to the ${config.language.code} engine');
    }
  }

  bool canPlace(GameState s, int pieceIndex, int x, int y) {
    if (s.status != GameStatus.playing) return false;
    if (pieceIndex < 0 || pieceIndex >= s.hand.length) return false;
    final p = s.hand[pieceIndex];
    return p != null && p.shape.fits(s.grid, x, y);
  }

  /// True if hand piece [pieceIndex] fits somewhere on the board.
  bool canPlaceAnywhere(GameState s, int pieceIndex) {
    final p = s.hand[pieceIndex];
    return p != null && Placement.canPlaceShape(s.grid, p.shape);
  }

  /// Words and score a placement would produce, without changing [s].
  PlacementPreview? preview(GameState s, int pieceIndex, int x, int y) {
    if (!canPlace(s, pieceIndex, x, y)) return null;
    final grid = s.grid.copy();
    final placed = _put(grid, s.hand[pieceIndex]!, x, y);
    final hits = detector.detect(grid, placed);
    final cleared = _cleared(hits);
    final r = scoreMove(
      config: config,
      hits: hits,
      placedCells: s.hand[pieceIndex]!.size,
      // VARSAYIM: +100 only if the board held tiles before this move.
      gridEmptyAfter: s.grid.filledCount > 0 && grid.filledCount == cleared.length,
      streakBefore: s.streak,
    );
    return PlacementPreview(hits, r.score);
  }

  // ---------------------------------------------------------------- actions

  StepResult _place(GameState s, PlaceAction a) {
    if (s.status != GameStatus.playing) {
      throw InvalidActionException('place while ${s.status.name}');
    }
    if (!canPlace(s, a.pieceIndex, a.x, a.y)) {
      throw InvalidActionException('piece ${a.pieceIndex} does not fit at (${a.x},${a.y})');
    }
    final piece = s.hand[a.pieceIndex]!;
    final grid = s.grid.copy();
    final placed = _put(grid, piece, a.x, a.y);
    final events = <GameEvent>[PiecePlaced(a.pieceIndex, placed)];
    final hand = List<Piece?>.of(s.hand)..[a.pieceIndex] = null;
    final next = _resolve(
      s.copyWith(hand: List.unmodifiable(hand)),
      grid,
      placed,
      placedCells: piece.size,
      resetStreakWithoutWords: true,
      events: events,
    );
    return _settle(next, events);
  }

  StepResult _refresh(GameState s) {
    _requirePowerup(s, PowerupType.refresh);
    final events = <GameEvent>[];
    final pw = _spend(s, PowerupType.refresh, events);
    final hand = _deal(s.seed, s.handCounter, s.score, s.grid, s.mode);
    events.add(HandDealt(hand, s.handCounter));
    final next = s.copyWith(powerups: pw, hand: List.unmodifiable(hand), handCounter: s.handCounter + 1);
    return _settle(next, events);
  }

  StepResult _joker(GameState s, JokerAction a) {
    _requirePowerup(s, PowerupType.joker);
    _requireInBounds(a.x, a.y);
    final idx = Grid.indexOf(a.x, a.y);
    if (s.grid.isFilled(idx)) throw const InvalidActionException('joker on filled cell');
    final letter = config.language.normalize(a.letter);
    if (!config.language.isLetter(letter)) {
      throw InvalidActionException('invalid joker letter: ${a.letter}');
    }
    final events = <GameEvent>[];
    final pw = _spend(s, PowerupType.joker, events);
    final grid = s.grid.copy()..set(idx, Cell(letter, isJoker: true));
    events.add(JokerPlaced(idx, letter));
    final next = _resolve(
      s.copyWith(powerups: pw),
      grid,
      [idx],
      placedCells: 0, // VARSAYIM: no placement bonus for jokers
      resetStreakWithoutWords: false, // karar 13
      events: events,
    );
    return _settle(next, events);
  }

  StepResult _hammer(GameState s, HammerAction a) {
    _requirePowerup(s, PowerupType.hammer);
    _requireInBounds(a.x, a.y);
    final idx = Grid.indexOf(a.x, a.y);
    if (!s.grid.isFilled(idx)) throw const InvalidActionException('hammer on empty cell');
    final events = <GameEvent>[];
    final pw = _spend(s, PowerupType.hammer, events);
    final grid = s.grid.copy()..set(idx, null);
    events.add(CellsCleared([idx]));
    // No word detection, no score, streak unchanged; no clear bonus.
    return _settle(s.copyWith(powerups: pw, grid: grid), events);
  }

  StepResult _continue(GameState s) {
    if (s.mode != GameMode.classic) throw const InvalidActionException('continue only in classic');
    if (s.status != GameStatus.over || s.overReason != GameOverReason.noFit) {
      throw const InvalidActionException('continue only after a no-fit game over');
    }
    if (s.continueUsed) throw const InvalidActionException('continue already used');

    final rows = List<int>.generate(Grid.size, (y) => y)
      ..sort((a, b) {
        final d = s.grid.rowCount(b) - s.grid.rowCount(a);
        return d != 0 ? d : a - b; // VARSAYIM: ties -> upper row first
      });
    final chosen = rows.take(2).where((y) => s.grid.rowCount(y) > 0).toList()..sort();
    final grid = s.grid.copy();
    final cleared = <int>[];
    for (final y in chosen) {
      for (var x = 0; x < Grid.size; x++) {
        final i = Grid.indexOf(x, y);
        if (grid.isFilled(i)) {
          grid.set(i, null);
          cleared.add(i);
        }
      }
    }
    final events = <GameEvent>[ContinueApplied(chosen), CellsCleared(cleared)];
    return _settle(
      s.copyWith(grid: grid, continueUsed: true, status: GameStatus.playing, clearOverReason: true),
      events,
    );
  }

  StepResult _end(GameState s) {
    if (s.status != GameStatus.stuck) throw const InvalidActionException('end only while stuck');
    final events = <GameEvent>[const StatusChanged(GameStatus.over, GameOverReason.noFit)];
    return StepResult(s.copyWith(status: GameStatus.over, overReason: GameOverReason.noFit), events);
  }

  StepResult _grant(GameState s, GrantAction a) {
    if (s.mode != GameMode.classic) throw const InvalidActionException('grants only in classic');
    if (s.status == GameStatus.over) throw const InvalidActionException('game is over');
    final pw = Map<PowerupType, int>.of(s.powerups);
    for (final e in a.powerups.entries) {
      if (e.value < 0) throw InvalidActionException('negative grant: ${e.key.name}');
      pw[e.key] = (pw[e.key] ?? 0) + e.value;
    }
    // Board, hand and score are untouched; a stuck game stays stuck but now
    // has something to spend.
    return _settle(s.copyWith(powerups: Map.unmodifiable(pw)), <GameEvent>[]);
  }

  // ---------------------------------------------------------------- helpers

  /// Detect, clear, score and update stats after cells were added.
  GameState _resolve(
    GameState s,
    Grid grid,
    List<int> placed, {
    required int placedCells,
    required bool resetStreakWithoutWords,
    required List<GameEvent> events,
  }) {
    final hits = detector.detect(grid, placed);
    final clearedList = _cleared(hits);
    for (final i in clearedList) {
      grid.set(i, null);
    }
    final r = scoreMove(
      config: config,
      hits: hits,
      placedCells: placedCells,
      // VARSAYIM: +100 only if the board held tiles before this move
      // (a piece that is itself a word on an empty board is not a "clear").
      gridEmptyAfter: grid.isEmpty && s.grid.filledCount > 0,
      streakBefore: s.streak,
      resetStreakWithoutWords: resetStreakWithoutWords,
    );
    if (hits.isNotEmpty) {
      events
        ..add(WordsFound(hits))
        ..add(CellsCleared(clearedList));
    }
    final total = s.score + r.score.total;
    events.add(ScoreAwarded(r.score, r.streakAfter, total));

    var longest = s.longestWord;
    var best = s.bestWord;
    var bestScore = s.bestWordScore;
    for (final h in hits) {
      if (h.length > longest.length) longest = h.word;
      final ws = h.baseScoreX10 ~/ 10;
      if (ws > bestScore) {
        bestScore = ws;
        best = h.word;
      }
    }
    return s.copyWith(
      grid: grid,
      score: total,
      streak: r.streakAfter,
      bestStreak: r.streakAfter > s.bestStreak ? r.streakAfter : s.bestStreak,
      wordCount: s.wordCount + hits.length,
      longestWord: longest,
      bestWord: best,
      bestWordScore: bestScore,
    );
  }

  /// Refill if the hand is used up, then decide playing / stuck / over.
  StepResult _settle(GameState s, List<GameEvent> events) {
    var next = s;
    if (next.hand.every((p) => p == null)) {
      if (next.mode == GameMode.daily && next.handCounter >= config.dailyHandLimit) {
        events.add(const StatusChanged(GameStatus.over, GameOverReason.handLimit));
        return StepResult(next.copyWith(status: GameStatus.over, overReason: GameOverReason.handLimit), events);
      }
      final hand = _deal(next.seed, next.handCounter, next.score, next.grid, next.mode);
      events.add(HandDealt(hand, next.handCounter));
      next = next.copyWith(hand: List.unmodifiable(hand), handCounter: next.handCounter + 1);
    }

    final GameStatus status;
    GameOverReason? reason;
    if (Placement.canPlaceAny(next.grid, next.hand)) {
      status = GameStatus.playing;
    } else if (next.mode == GameMode.classic && next.hasAnyPowerup) {
      status = GameStatus.stuck;
    } else {
      status = GameStatus.over;
      reason = GameOverReason.noFit;
    }
    if (status != s.status) events.add(StatusChanged(status, reason));
    return StepResult(next.copyWith(status: status, overReason: reason, clearOverReason: reason == null), events);
  }

  List<Piece> _deal(int seed, int counter, int score, Grid grid, GameMode mode) => hands.deal(
    seed: seed,
    handCounter: counter,
    score: score,
    grid: grid,
    easing: mode == GameMode.classic ? EasingMode.grid : EasingMode.letters, // karar 5
  );

  /// Places [piece]; returns the filled indices in reading order.
  List<int> _put(Grid grid, Piece piece, int x, int y) {
    final cells = piece.shape.indicesAt(x, y);
    for (var i = 0; i < cells.length; i++) {
      grid.set(cells[i], Cell(piece.letters[i]));
    }
    return cells;
  }

  /// Union of all hit cells, ascending (shared cells once).
  static List<int> _cleared(List<WordHit> hits) {
    final set = <int>{for (final h in hits) ...h.cells};
    return set.toList()..sort();
  }

  void _requirePowerup(GameState s, PowerupType t) {
    if (s.mode == GameMode.daily) {
      throw const InvalidActionException('powerups are disabled in the daily puzzle');
    }
    if (s.status == GameStatus.over) throw const InvalidActionException('game is over');
    if (s.powerup(t) <= 0) throw InvalidActionException('no ${t.name} left');
  }

  static void _requireInBounds(int x, int y) {
    if (x < 0 || y < 0 || x >= Grid.size || y >= Grid.size) {
      throw InvalidActionException('($x,$y) out of bounds');
    }
  }

  Map<PowerupType, int> _spend(GameState s, PowerupType t, List<GameEvent> events) {
    final pw = Map<PowerupType, int>.of(s.powerups)..[t] = s.powerup(t) - 1;
    events.add(PowerupUsed(t, pw[t]!));
    return Map.unmodifiable(pw);
  }
}

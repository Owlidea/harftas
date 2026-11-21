import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:harfblok/core/core.dart';

import 'helpers.dart';

final _t0 = DateTime.utc(2026, 11, 13, 9);

GameEngine _engine({BalanceConfig cfg = BalanceConfig.defaults}) =>
    GameEngine(config: cfg, dictionary: testDictionary, common: testDictionary);

PlaceAction? _firstFit(GameEngine e, GameState s) {
  for (var p = 0; p < s.hand.length; p++) {
    final piece = s.hand[p];
    if (piece == null) continue;
    final pos = Placement.positions(s.grid, piece.shape);
    if (pos.isNotEmpty) return PlaceAction(p, pos.first.x, pos.first.y);
  }
  return null;
}

Grid _filled(String letter, {Set<int> holes = const {}}) {
  final g = Grid.empty();
  for (var i = 0; i < 64; i++) {
    if (!holes.contains(i)) g.set(i, Cell(letter));
  }
  return g;
}

void main() {
  group('newGame', () {
    test('classic: 3 pieces, 1 of each powerup, playing', () {
      final s = _engine().newGame(seed: 1, mode: GameMode.classic, startedAt: _t0);
      expect(s.hand.length, 3);
      expect(s.hand.every((p) => p != null), isTrue);
      expect(s.handCounter, 1);
      expect(s.status, GameStatus.playing);
      expect(s.powerups, {PowerupType.refresh: 1, PowerupType.joker: 1, PowerupType.hammer: 1});
    });

    test('daily: no powerups, same hands for same date regardless of grid (karar 5)', () {
      final e = _engine();
      final seed = Rng.dailySeed(2026, 11, 13);
      final a = e.newGame(seed: seed, mode: GameMode.daily, startedAt: _t0);
      final b = e.newGame(seed: seed, mode: GameMode.daily, startedAt: _t0);
      expect(a.powerups.values.every((v) => v == 0), isTrue);
      expect(a.hand.toString(), b.hand.toString());

      // Two players placing differently still get the same 2nd hand.
      var p1 = a, p2 = b;
      for (var i = 0; i < 3; i++) {
        p1 = e.apply(p1, _firstFit(e, p1)!).state;
      }
      for (var i = 2; i >= 0; i--) {
        final piece = p2.hand[i]!;
        final pos = Placement.positions(p2.grid, piece.shape).last;
        p2 = e.apply(p2, PlaceAction(i, pos.x, pos.y)).state;
      }
      expect(p1.handCounter, 2);
      expect(p1.hand.toString(), p2.hand.toString());
    });
  });

  group('place', () {
    test('fills cells, scores placement, empties slot, records action', () {
      final e = _engine();
      final s0 = e.newGame(seed: 3, mode: GameMode.classic, startedAt: _t0);
      final a = _firstFit(e, s0)!;
      final size = s0.hand[a.pieceIndex]!.size;
      final r = e.apply(s0, a);
      expect(r.state.hand[a.pieceIndex], isNull);
      expect(r.state.actions.length, 1);
      expect(r.state.score, greaterThanOrEqualTo(size));
      expect(r.events.first, isA<PiecePlaced>());
      // Original state untouched (immutability).
      expect(s0.grid.isEmpty, isTrue);
      expect(s0.actions, isEmpty);
    });

    test('invalid placement throws', () {
      final e = _engine();
      final s = e.newGame(seed: 3, mode: GameMode.classic, startedAt: _t0);
      expect(() => e.apply(s, const PlaceAction(0, 8, 0)), throwsA(isA<InvalidActionException>()));
      final placed = e.apply(s, PlaceAction(0, 0, 0)).state;
      expect(() => e.apply(placed, const PlaceAction(0, 0, 0)), throwsA(isA<InvalidActionException>()));
    });

    test('new hand after all three pieces are used', () {
      final e = _engine();
      var s = e.newGame(seed: 4, mode: GameMode.classic, startedAt: _t0);
      for (var i = 0; i < 3; i++) {
        s = e.apply(s, _firstFit(e, s)!).state;
      }
      expect(s.handCounter, 2);
      expect(s.remainingPieces, 3);
    });

    test('word placement explodes cells and updates stats', () {
      final e = _engine();
      final base = e.newGame(seed: 5, mode: GameMode.classic, startedAt: _t0);
      final grid = board(['KA......', '.......Z']).grid;
      final mono = Piece(ShapeCatalog.byFamily[ShapeFamily.mono]!.single, ['R']);
      final s = base.copyWith(grid: grid, hand: [mono, base.hand[1], base.hand[2]]);
      final r = e.apply(s, const PlaceAction(0, 2, 0));
      expect(r.state.grid.at(0, 0), isNull);
      expect(r.state.grid.at(7, 1)?.letter, 'Z');
      expect(r.state.score, 3 + 1);
      expect(r.state.wordCount, 1);
      expect(r.state.longestWord, 'KAR');
      expect(r.state.streak, 1);
      expect(r.events.whereType<WordsFound>().single.hits.single.word, 'KAR');
    });

    test('a word-piece on an empty board gives no +100 clear bonus', () {
      final e = _engine();
      final base = e.newGame(seed: 5, mode: GameMode.classic, startedAt: _t0);
      final i3 = ShapeCatalog.byFamily[ShapeFamily.i3]!.first;
      final s = base.copyWith(
        hand: [
          Piece(i3, ['K', 'A', 'R']),
          base.hand[1],
          base.hand[2],
        ],
      );
      final r = e.apply(s, const PlaceAction(0, 0, 0)).state;
      expect(r.grid.isEmpty, isTrue);
      expect(r.score, 3 + 3);
    });

    test('preview matches the real move', () {
      final e = _engine();
      final base = e.newGame(seed: 5, mode: GameMode.classic, startedAt: _t0);
      final mono = Piece(ShapeCatalog.byFamily[ShapeFamily.mono]!.single, ['R']);
      final s = base.copyWith(grid: board(['KA......']).grid, hand: [mono, base.hand[1], base.hand[2]]);
      final pv = e.preview(s, 0, 2, 0)!;
      expect(pv.hits.single.word, 'KAR');
      expect(pv.score.total, 3 + 1 + 100);
      expect(e.apply(s, const PlaceAction(0, 2, 0)).state.score, pv.score.total);
      expect(e.preview(s, 0, 0, 0), isNull);
    });
  });

  group('powerups (spec 6)', () {
    test('refresh deals a new hand and spends one', () {
      final e = _engine();
      final s = e.newGame(seed: 6, mode: GameMode.classic, startedAt: _t0);
      final r = e.apply(s, const RefreshAction()).state;
      expect(r.powerup(PowerupType.refresh), 0);
      expect(r.handCounter, 2);
      expect(r.hand.toString(), isNot(s.hand.toString()));
      expect(() => e.apply(r, const RefreshAction()), throwsA(isA<InvalidActionException>()));
    });

    test('joker forms a word: 0 points for the joker letter, no placement bonus', () {
      final e = _engine();
      final base = e.newGame(seed: 7, mode: GameMode.classic, startedAt: _t0);
      final s = base.copyWith(grid: board(['KA......', '.......Z']).grid);
      final r = e.apply(s, const JokerAction(2, 0, 'r')).state;
      expect(r.score, 2);
      expect(r.grid.at(0, 0), isNull);
      expect(r.streak, 1);
      expect(r.powerup(PowerupType.joker), 0);
    });

    test('joker without a word leaves streak unchanged', () {
      final e = _engine();
      final base = e.newGame(seed: 7, mode: GameMode.classic, startedAt: _t0);
      final s = base.copyWith(streak: 3);
      final r = e.apply(s, const JokerAction(5, 5, 'Z')).state;
      expect(r.streak, 3);
      expect(r.grid.at(5, 5)?.isJoker, isTrue);
    });

    test('hammer removes one cell without detection or score', () {
      final e = _engine();
      final base = e.newGame(seed: 8, mode: GameMode.classic, startedAt: _t0);
      final s = base.copyWith(grid: board(['KAR.....']).grid, streak: 2);
      final r = e.apply(s, const HammerAction(1, 0)).state;
      expect(r.grid.at(1, 0), isNull);
      expect(r.score, 0);
      expect(r.streak, 2);
      expect(() => e.apply(r, const HammerAction(1, 0)), throwsA(isA<InvalidActionException>()));
    });

    test('daily puzzle rejects every powerup and continue', () {
      final e = _engine();
      final s = e.newGame(seed: 9, mode: GameMode.daily, startedAt: _t0, powerups: {PowerupType.hammer: 5});
      for (final a in [
        const RefreshAction(),
        const JokerAction(0, 0, 'A'),
        const HammerAction(0, 0),
        const ContinueAction(),
      ]) {
        expect(() => e.apply(s, a), throwsA(isA<InvalidActionException>()), reason: '$a');
      }
    });
  });

  group('game over (spec 2.6)', () {
    test('full board with powerups -> stuck; end -> over', () {
      final e = _engine();
      final s = e.revalidate(e.newGame(seed: 10, mode: GameMode.classic, startedAt: _t0).copyWith(grid: _filled('Z')));
      expect(s.status, GameStatus.stuck);
      expect(() => e.apply(s, _firstFit(e, s) ?? const PlaceAction(0, 0, 0)), throwsA(isA<InvalidActionException>()));
      final over = e.apply(s, const EndAction()).state;
      expect(over.status, GameStatus.over);
      expect(over.overReason, GameOverReason.noFit);
    });

    test('stuck -> hammer can open a hole', () {
      final e = _engine();
      final s = e.revalidate(e.newGame(seed: 10, mode: GameMode.classic, startedAt: _t0).copyWith(grid: _filled('Z')));
      final r = e.apply(s, const HammerAction(0, 0)).state;
      final fits = Placement.canPlaceAny(r.grid, r.hand);
      expect(r.status, fits ? GameStatus.playing : GameStatus.stuck);
    });

    test('no powerups -> over; continue clears 2 fullest rows once', () {
      final e = _engine();
      final none = {for (final t in PowerupType.values) t: 0};
      final base = e.newGame(seed: 11, mode: GameMode.classic, startedAt: _t0, powerups: none);
      // Row 5 has a hole so rows 0 and 1 (full, upper first) are chosen.
      final i4 = ShapeCatalog.byFamily[ShapeFamily.i4]!.first;
      final o4 = ShapeCatalog.byFamily[ShapeFamily.o4]!.single;
      final hand = [Piece(i4, 'ZZZZ'.split('')), Piece(i4, 'ZZZZ'.split('')), Piece(o4, 'ZZZZ'.split(''))];
      final s = e.revalidate(
        base.copyWith(
          grid: _filled('Z', holes: {Grid.indexOf(3, 5)}),
          hand: hand,
        ),
      );
      expect(s.status, GameStatus.over);
      final r = e.apply(s, const ContinueAction());
      expect(r.events.whereType<ContinueApplied>().single.rows, [0, 1]);
      expect(r.state.continueUsed, isTrue);
      expect(r.state.grid.rowCount(0), 0);
      expect(r.state.grid.rowCount(1), 0);
      expect(r.state.grid.rowCount(2), 8);
      expect(r.state.status, GameStatus.playing);
      final again = r.state.copyWith(status: GameStatus.over, overReason: GameOverReason.noFit);
      expect(() => e.apply(again, const ContinueAction()), throwsA(isA<InvalidActionException>()));
    });

    test('daily ends after the hand limit (karar 6)', () {
      final e = _engine(cfg: BalanceConfig.defaults.copyWith(dailyHandLimit: 2));
      var s = e.newGame(seed: 12, mode: GameMode.daily, startedAt: _t0);
      var moves = 0;
      while (!s.isOver) {
        s = e.apply(s, _firstFit(e, s)!).state;
        moves++;
      }
      expect(moves, 6);
      expect(s.overReason, GameOverReason.handLimit);
    });
  });

  group('replay & persistence (spec 7.3, 14, 17)', () {
    // Deterministic bot that also exercises powerups and continue.
    GameState play(GameEngine e, int seed, GameMode mode) {
      var s = e.newGame(seed: seed, mode: mode, startedAt: _t0);
      final r = Rng.fromSeed(seed ^ 0xABCDEF);
      for (var step = 0; step < 400 && !(s.isOver && (s.continueUsed || mode == GameMode.daily)); step++) {
        GameAction a;
        if (s.status == GameStatus.over) {
          a = const ContinueAction();
        } else if (s.status == GameStatus.stuck) {
          if (s.powerup(PowerupType.refresh) > 0) {
            a = const RefreshAction();
          } else if (s.powerup(PowerupType.hammer) > 0) {
            a = HammerAction(Grid.xOf(r.nextInt(64)), 0);
            final filled = [
              for (var i = 0; i < 64; i++)
                if (s.grid.isFilled(i)) i,
            ];
            final idx = filled[r.nextInt(filled.length)];
            a = HammerAction(Grid.xOf(idx), Grid.yOf(idx));
          } else if (s.powerup(PowerupType.joker) > 0) {
            final empty = [
              for (var i = 0; i < 64; i++)
                if (!s.grid.isFilled(i)) i,
            ];
            if (empty.isEmpty) {
              a = const EndAction();
            } else {
              final idx = empty[r.nextInt(empty.length)];
              a = JokerAction(Grid.xOf(idx), Grid.yOf(idx), TrAlphabet.all[r.nextInt(29)]);
            }
          } else {
            a = const EndAction();
          }
        } else {
          final options = <PlaceAction>[];
          for (var p = 0; p < s.hand.length; p++) {
            final piece = s.hand[p];
            if (piece == null) continue;
            for (final pos in Placement.positions(s.grid, piece.shape)) {
              options.add(PlaceAction(p, pos.x, pos.y));
            }
          }
          a = options[r.nextInt(options.length)];
        }
        s = e.apply(s, a).state;
      }
      return s;
    }

    test('seed + actions always reproduce the same game (50 seeds, both modes)', () {
      final e = _engine();
      for (var seed = 0; seed < 50; seed++) {
        for (final mode in GameMode.values) {
          final s = play(e, seed, mode);
          expect(s.isOver, isTrue, reason: 'seed $seed ${mode.name}');
          final replayed = e.replay(
            seed: s.seed,
            mode: s.mode,
            startedAt: s.startedAt,
            initialPowerups: s.initialPowerups,
            actions: s.actions,
          );
          expect(jsonEncode(replayed.toJson()), jsonEncode(s.toJson()), reason: 'seed $seed ${mode.name}');
        }
      }
    });

    test('JSON round trip mid-game continues identically', () {
      final e = _engine();
      var s = e.newGame(seed: 21, mode: GameMode.classic, startedAt: _t0);
      for (var i = 0; i < 10 && !s.isOver; i++) {
        s = e.apply(s, _firstFit(e, s)!).state;
      }
      final restored = GameState.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
      expect(jsonEncode(restored.toJson()), jsonEncode(s.toJson()));
      final a = _firstFit(e, s);
      if (a != null) {
        expect(jsonEncode(e.apply(restored, a).state.toJson()), jsonEncode(e.apply(s, a).state.toJson()));
      }
    });

    test('unknown save version is rejected (storage resets safely)', () {
      final e = _engine();
      final j = e.newGame(seed: 1, mode: GameMode.classic, startedAt: _t0).toJson()..['v'] = 99;
      expect(() => GameState.fromJson(j), throwsFormatException);
    });
  });
}

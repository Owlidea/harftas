import 'package:flutter_test/flutter_test.dart';
import 'package:harfblok/core/core.dart';

void main() {
  const cfg = BalanceConfig.defaults;

  group('Rng', () {
    test('same seed -> same sequence', () {
      final a = Rng.fromSeed(42), b = Rng.fromSeed(42);
      for (var i = 0; i < 1000; i++) {
        expect(a.nextUint32(), b.nextUint32());
      }
    });
    test('mul32 equals native 32-bit multiply', () {
      final r = Rng.fromSeed(99);
      for (var i = 0; i < 2000; i++) {
        final a = r.nextUint32(), b = r.nextUint32();
        expect(Rng.mul32(a, b), (a * b) & 0xFFFFFFFF);
      }
    });
    test('different seeds and streams diverge', () {
      expect(Rng.fromSeed(1).nextUint32(), isNot(Rng.fromSeed(2).nextUint32()));
      expect(Rng.stream(7, 0).nextUint32(), isNot(Rng.stream(7, 1).nextUint32()));
    });
    test('nextInt stays in range and covers it', () {
      final r = Rng.fromSeed(3);
      final seen = <int>{};
      for (var i = 0; i < 5000; i++) {
        final v = r.nextInt(7);
        expect(v, inInclusiveRange(0, 6));
        seen.add(v);
      }
      expect(seen.length, 7);
    });
    test('weighted never picks zero weight', () {
      final r = Rng.fromSeed(9);
      for (var i = 0; i < 2000; i++) {
        expect(r.weighted([0, 3, 0, 1]), anyOf(1, 3));
      }
    });
    test('golden values are stable across versions', () {
      // Changing the RNG breaks saved games and daily puzzles: keep these fixed.
      final r = Rng.fromSeed(12345);
      expect([for (var i = 0; i < 3; i++) r.nextUint32()], [518667457, 440444462, 4232892992]);
      expect(Rng.dailySeed(2026, 11, 13), 2279953648);
      expect(Rng.dailySeed(2026, 11, 13), isNot(Rng.dailySeed(2026, 11, 14)));
    });
  });

  group('ShapeCatalog (spec 2.3)', () {
    test('28 unique orientations in the expected families', () {
      expect(ShapeCatalog.all.length, 28);
      int n(ShapeFamily f) => ShapeCatalog.byFamily[f]!.length;
      expect(n(ShapeFamily.mono), 1);
      expect(n(ShapeFamily.i2), 2);
      expect(n(ShapeFamily.i3), 2);
      expect(n(ShapeFamily.l3), 4);
      expect(n(ShapeFamily.o4), 1);
      expect(n(ShapeFamily.i4), 2);
      expect(n(ShapeFamily.t4), 4);
      expect(n(ShapeFamily.l4), 8);
      expect(n(ShapeFamily.sz4), 4);
    });
    test('sizes match families', () {
      for (final e in ShapeCatalog.familiesBySize.entries) {
        for (final f in e.value) {
          for (final s in ShapeCatalog.byFamily[f]!) {
            expect(s.size, e.key, reason: s.id);
          }
        }
      }
    });
    test('placement: 2x2 square at (7,7) is out of bounds, at (6,6) fits empty grid', () {
      final o = ShapeCatalog.byFamily[ShapeFamily.o4]!.single;
      expect(o.fits(Grid.empty(), 7, 7), isFalse);
      expect(o.fits(Grid.empty(), 6, 6), isTrue);
      expect(o.indicesAt(6, 6), [54, 55, 62, 63]);
      final g = Grid.empty()..set(63, Cell('A'));
      expect(o.fits(g, 6, 6), isFalse);
    });
    test('Ğ rule: only cells with a same-piece cell to the left AND above', () {
      final o = ShapeCatalog.byFamily[ShapeFamily.o4]!.single;
      expect([for (var i = 0; i < 4; i++) o.canHoldSoftG(i)], [false, false, false, true]);
      for (final s in [...ShapeCatalog.byFamily[ShapeFamily.mono]!, ...ShapeCatalog.byFamily[ShapeFamily.i4]!]) {
        for (var i = 0; i < s.size; i++) {
          expect(s.canHoldSoftG(i), isFalse);
        }
      }
    });
  });

  group('LetterGenerator constraints (spec 4)', () {
    final gen = LetterGenerator(cfg);
    final hg = HandGenerator(cfg, common: SetWordDictionary.empty);

    test('vowel bounds rounding (karar 7)', () {
      expect(gen.vowelBounds(3), (min: 1, max: 2));
      expect(gen.vowelBounds(5), (min: 2, max: 3));
      expect(gen.vowelBounds(12), (min: 4, max: 8));
      expect(gen.vowelBounds(1), (min: 1, max: 1));
    });

    test('2000 hands respect every constraint', () {
      for (var seed = 0; seed < 2000; seed++) {
        final hand = hg.generateRaw(Rng.fromSeed(seed), 0);
        final letters = [for (final p in hand) ...p.letters];
        final n = letters.length;
        final b = gen.vowelBounds(n);
        final vowels = letters.where(TrAlphabet.isVowel).length;
        expect(vowels, inInclusiveRange(b.min, b.max), reason: '$hand');

        final counts = <String, int>{};
        for (final l in letters) {
          counts[l] = (counts[l] ?? 0) + 1;
        }
        for (final e in counts.entries) {
          if (cfg.scoreOf(e.key) >= 5) expect(e.value, 1, reason: '$hand');
        }
        expect(letters.where(cfg.rareLetters.contains).length, lessThanOrEqualTo(2));

        for (final p in hand) {
          for (var i = 0; i < p.size; i++) {
            if (p.letters[i] == 'Ğ') expect(p.shape.canHoldSoftG(i), isTrue, reason: '$p');
          }
        }
        expect(letters.every(TrAlphabet.isLetter), isTrue);
      }
    });

    test('piece size distribution roughly follows 15/35/35/15', () {
      final counts = List<int>.filled(5, 0);
      final r = Rng.fromSeed(77);
      const n = 20000;
      for (var i = 0; i < n; i++) {
        counts[hg.pickShape(r, 0).size]++;
      }
      expect(counts[1] / n, closeTo(0.15, 0.015));
      expect(counts[2] / n, closeTo(0.35, 0.015));
      expect(counts[3] / n, closeTo(0.35, 0.015));
      expect(counts[4] / n, closeTo(0.15, 0.015));
    });

    test('difficulty tiers shift weights with score', () {
      expect(cfg.sizeWeightsFor(0), [15, 35, 35, 15]);
      expect(cfg.sizeWeightsFor(299), [15, 35, 35, 15]);
      expect(cfg.sizeWeightsFor(300), [12, 33, 37, 18]);
      expect(cfg.sizeWeightsFor(99999), [6, 25, 41, 28]);
    });

    test('deal() is deterministic per (seed, handCounter)', () {
      final g = Grid.empty();
      String key(int c) => hg
          .deal(seed: 5, handCounter: c, score: 0, grid: g, easing: EasingMode.none)
          .map((p) => p.toString())
          .join('|');
      expect(key(3), key(3));
      expect(key(3), isNot(key(4)));
    });
  });

  group('Easing rule (spec 4, classic)', () {
    test('finds a hand that forms a common word when one exists', () {
      // Grid with "KA" at row 0; any piece starting with R next to it forms KAR.
      final grid = Grid.fromRows([
        'KA......',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
      ]);
      final common = SetWordDictionary.fromWords(['KAR', 'KAL', 'KAN', 'KAT', 'KAZ', 'KAS', 'KAY']);
      final hg = HandGenerator(cfg, common: common);
      var eased = 0;
      for (var seed = 0; seed < 200; seed++) {
        final h = hg.deal(seed: seed, handCounter: 0, score: 0, grid: grid, easing: EasingMode.grid);
        if (hg.canFormCommonWord(grid, h)) eased++;
      }
      // Without easing a random hand rarely qualifies; with 20 attempts most do.
      expect(eased, greaterThan(150));
    });
  });
}

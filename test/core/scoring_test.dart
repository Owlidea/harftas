import 'package:flutter_test/flutter_test.dart';
import 'package:harfblok/core/core.dart';

import 'helpers.dart';

/// Hand-calculated scenarios (docs/algoritma.md §5 + spec 5).
void main() {
  const cfg = BalanceConfig.defaults;
  final det = WordDetector(cfg, testDictionary);

  ScoreResult score(List<String> rows, {int streakBefore = 0, int? placed}) {
    final b = board(rows);
    final hits = det.detect(b.grid, b.newCells);
    final g = b.grid.copy();
    for (final h in hits) {
      for (final i in h.cells) {
        g.set(i, null);
      }
    }
    final newCount = b.newCells.length;
    return scoreMove(
      config: cfg,
      hits: hits,
      placedCells: placed ?? newCount,
      gridEmptyAfter: g.isEmpty,
      streakBefore: streakBefore,
    );
  }

  test('1: KAR, 3 cells, other cells remain -> 3 + 3 = 6', () {
    final r = score(['kar.....', '.......Z']);
    expect(r.score.wordPoints, 3);
    expect(r.score.total, 6);
    expect(r.streakAfter, 1);
  });

  test('2: KALEM + ELMA combo x2, streak 2 -> 46 + 3 = 49', () {
    final r = score([
      '........',
      '........',
      '........',
      'KALeM...',
      '...l....',
      '...m....',
      '...A....',
      '.......Z',
    ], streakBefore: 2);
    // base10 = 6*20 + 5*15 = 195; 195*2*12/100 = 46.8 -> 46
    expect(r.score.combo, 2);
    expect(r.score.wordPoints, 46);
    expect(r.score.total, 49);
    expect(r.streakAfter, 3);
  });

  test('3: ELMA + KAR in one segment, 2 cells -> 21 + 2 = 23', () {
    final r = score(['ELMakAR.', '.......Z']);
    // (75 + 30) * 2 * 10 / 100 = 21
    expect(r.score.wordPoints, 21);
    expect(r.score.total, 23);
  });

  test('4: ARABA beats ARA; 5-letter x2', () {
    final r = score(['aRABA...', '.......Z']);
    // A1 R1 A1 B3 A1 = 7 x2 = 14
    expect(r.score.wordPoints, 14);
    expect(r.score.total, 15);
  });

  test('5: no word -> placement only, streak resets', () {
    final r = score(['zzzz....'], streakBefore: 5);
    expect(r.score.total, 4);
    expect(r.streakAfter, 0);
  });

  test('6: board emptied -> +100', () {
    final r = score(['kar.....']);
    expect(r.score.clearBonus, 100);
    expect(r.score.total, 106);
  });

  test('7: streak multiplier caps at x2.0', () {
    final r = score(['kar.....', '.......Z'], streakBefore: 15);
    expect(r.score.streakMultiplierX10, 20);
    expect(r.score.wordPoints, 6);
    expect(r.streakAfter, 16);
  });

  test('8: 8-letter word x6', () {
    final r = score(['KARALAMa', '.......Z']);
    // K1 A1 R1 A1 L1 A1 M2 A1 = 9 x6 = 54
    expect(r.score.wordPoints, 54);
    expect(r.score.total, 55);
  });

  test('9: x1.5 then x1.1 streak, floor once: KARE 4*1.5*1.1 = 6.6 -> 6', () {
    final r = score(['KARe....', '.......Z'], streakBefore: 1);
    expect(r.score.wordPoints, 6);
    expect(r.score.total, 7);
  });

  test('10: joker letter scores 0, no placement bonus, no streak reset', () {
    final b = board(['KA......', '.......Z']);
    b.grid.set(Grid.indexOf(2, 0), Cell('R', isJoker: true));
    final hits = det.detect(b.grid, [Grid.indexOf(2, 0)]);
    final r = scoreMove(
      config: cfg,
      hits: hits,
      placedCells: 0,
      gridEmptyAfter: false,
      streakBefore: 0,
      resetStreakWithoutWords: false,
    );
    expect(r.score.total, 2);
    final none = scoreMove(
      config: cfg,
      hits: const [],
      placedCells: 0,
      gridEmptyAfter: false,
      streakBefore: 4,
      resetStreakWithoutWords: false,
    );
    expect(none.streakAfter, 4);
    expect(none.score.total, 0);
  });

  test('11: three words combo x3 with streak x1.1', () {
    // Row 0: KAR (new R). Row 2: NAR (new R). Column 7: KAR vertical (new R).
    final r = score(['KAr.....', '........', 'NAr....K', '.......A', '.......r', 'Z.......'], streakBefore: 1);
    // 3 words, each base 3 -> base10 = 90; 90 * 3 * 11 / 100 = 29.7 -> 29
    expect(r.score.combo, 3);
    expect(r.score.wordPoints, 29);
    expect(r.score.total, 32);
  });

  test('12: 6- and 7-letter multipliers', () {
    WordHit hit(int letterSum, int len) => WordHit(
      word: 'X',
      cells: List.filled(len, 0),
      direction: WordDirection.horizontal,
      letterSum: letterSum,
      baseScoreX10: letterSum * cfg.lengthMultiplierX10[len]!,
    );
    final six = scoreMove(config: cfg, hits: [hit(7, 6)], placedCells: 2, gridEmptyAfter: false, streakBefore: 0);
    expect(six.score.wordPoints, 21); // 7 x3
    final seven = scoreMove(config: cfg, hits: [hit(9, 7)], placedCells: 1, gridEmptyAfter: false, streakBefore: 0);
    expect(seven.score.wordPoints, 36); // 9 x4
  });
}

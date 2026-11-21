import 'package:flutter_test/flutter_test.dart';
import 'package:harfblok/core/core.dart';

import 'helpers.dart';

void main() {
  const cfg = BalanceConfig.defaults;
  final det = WordDetector(cfg, testDictionary);

  List<String> words(List<String> rows, {WordDetector? d}) {
    final b = board(rows);
    return [for (final h in (d ?? det).detect(b.grid, b.newCells)) h.word];
  }

  test('horizontal word with one new cell', () {
    expect(words(['KAr.....']), ['KAR']);
  });

  test('vertical word', () {
    expect(words(['.K......', '.A......', '.r......']), ['KAR']);
  });

  test('no word without a new cell (rule 2.5b)', () {
    final onlyKar = WordDetector(cfg, SetWordDictionary.fromWords(['KAR']));
    // KAR is made of old cells only; the new E does not belong to any word.
    expect(words(['KARe....'], d: onlyKar), isEmpty);
  });

  test('segment boundaries: a gap breaks the word', () {
    expect(words(['KA.r....']), isEmpty);
  });

  test('grid edges: last columns and last rows', () {
    expect(words(['.....KAr']), ['KAR']);
    expect(words(['........', '........', '........', '........', '........', '.......K', '.......A', '.......r']), [
      'KAR',
    ]);
  });

  test('reads only left-to-right and top-to-bottom', () {
    expect(words(['RAk.....']), isEmpty); // "KAR" reversed
    expect(words(['r.......', 'A.......', 'K.......']), isEmpty);
  });

  test('conflict: longest wins (ARABA over ARA)', () {
    expect(words(['aRABA...']), ['ARABA']);
  });

  test('conflict: equal length -> higher letter score (LEM over ALE)', () {
    expect(words(['alem....']), ['LEM']);
  });

  test('conflict: equal length and score -> leftmost (ALE over LEA)', () {
    expect(words(['alea....']), ['ALE']);
  });

  test('non-overlapping words in one segment both count', () {
    expect(words(['ELMakAR.']), ['ELMA', 'KAR']);
  });

  test('horizontal + vertical share a cell; both count, cell cleared once', () {
    final b = board(['........', '........', '........', 'KALeM...', '...l....', '...m....', '...A....']);
    final hits = det.detect(b.grid, b.newCells);
    expect([for (final h in hits) h.word], ['KALEM', 'ELMA']);
    expect(hits[0].direction, WordDirection.horizontal);
    expect(hits[1].direction, WordDirection.vertical);
    final cleared = {for (final h in hits) ...h.cells};
    expect(cleared.length, 8);
  });

  test('full 8-letter row', () {
    final hits = det.detect(board(['KARALAMa']).grid, board(['KARALAMa']).newCells);
    expect(hits.single.word, 'KARALAMA');
    expect(hits.single.length, 8);
  });

  test('MIN_WORD_LEN = 4 ignores 3-letter words', () {
    final d4 = WordDetector(cfg.copyWith(minWordLength: 4), testDictionary);
    expect(words(['KAr.....'], d: d4), isEmpty);
    expect(words(['KARe....'], d: d4), ['KARE']);
  });

  test('Turkish letters: İ vs I are different words', () {
    expect(words(['KİR.....'.replaceFirst('R', 'r')]), ['KİR']);
    expect(words(['KIr.....']), ['KIR']);
  });

  test('joker letters count 0 in letterSum', () {
    final b = board(['KA......']);
    b.grid.set(Grid.indexOf(2, 0), Cell('R', isJoker: true));
    final hits = det.detect(b.grid, [Grid.indexOf(2, 0)]);
    expect(hits.single.word, 'KAR');
    expect(hits.single.letterSum, 2);
  });

  test('performance: detection well under 5 ms per move', () {
    final b = board(['ELMakAR.', 'aRABA...', '...l....', '...m....', '...A....']);
    final sw = Stopwatch()..start();
    for (var i = 0; i < 2000; i++) {
      det.detect(b.grid, b.newCells);
    }
    sw.stop();
    expect(sw.elapsedMicroseconds / 2000, lessThan(5000));
  });
}

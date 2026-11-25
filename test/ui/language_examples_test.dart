// The intro and tutorial examples of every word language must be real words
// of that language's dictionary, and the tutorial steps must build exactly
// the words their hints promise (karar 29).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:harfblok/core/core.dart';
import 'package:harfblok/data/dictionary/dictionary_codec.dart';
import 'package:harfblok/ui/game/language_examples.dart';

/// Where the tutorial's single-letter piece goes in each step; step 4 first
/// hammers the cell it then fills.
const _targets = [(4, 3), (3, 4), (2, 2), (4, 3)];

/// Every run of 3+ letters in rows and columns, and all its sub-runs.
Iterable<String> _runs(List<String> rows) sync* {
  final lines = [
    ...rows,
    for (var x = 0; x < rows.first.length; x++) [for (final r in rows) r[x]].join(),
  ];
  for (final line in lines) {
    for (final run in line.split('.')) {
      for (var a = 0; a < run.length; a++) {
        for (var b = a + 3; b <= run.length; b++) {
          yield run.substring(a, b);
        }
      }
    }
  }
}

void main() {
  for (final language in WordLanguage.values) {
    final file = File('assets/dict/words_${language.code}.bin');
    final ex = LanguageExamples.of(language);
    final config = BalanceConfig.defaultsFor(language);

    group('${language.code} examples', () {
      late SetWordDictionary dict;
      setUpAll(() => dict = SetWordDictionary(DictionaryCodec.decode(file.readAsBytesSync())));

      bool isWord(String w) {
        final k = WordKey.fromWord(w, language);
        return k != null && dict.containsKey(k);
      }

      test('every example word is in the dictionary', () {
        for (final w in {ex.goal, ex.across, ex.down, ex.scoreWord, ex.firstWord, ...ex.tutorialWords}) {
          expect(isWord(w), isTrue, reason: w);
        }
        expect(ex.goal.length, 3);
        expect(ex.scoreWord.length, 5);
      });

      test('boards use only the language letters', () {
        final boards = [ex.readingRows, ex.stuckRows, ...ex.tutorialBoards];
        for (final rows in boards) {
          for (final ch in rows.join().split('')) {
            if (ch != '.') expect(language.isLetter(ch), isTrue, reason: '$ch in $rows');
          }
        }
        expect(ex.tutorialLetters.every(language.isLetter), isTrue);
      });

      test('the crowded board spells no word', () {
        for (final run in _runs(ex.stuckRows)) {
          expect(isWord(run), isFalse, reason: run);
        }
      });

      test('the reading board spells exactly its two words', () {
        final words = {for (final r in _runs(ex.readingRows)) if (isWord(r)) r};
        expect(words, {ex.across, ex.down});
      });

      test('each tutorial step builds the words its hint promises', () {
        final engine = GameEngine(config: config, dictionary: dict);
        final piece = ShapeCatalog.byFamily[ShapeFamily.mono]!.single;
        final built = <String>[];
        for (var step = 0; step < 4; step++) {
          final base = engine.newGame(
            seed: 7,
            mode: GameMode.classic,
            startedAt: DateTime.utc(2026, 11, 25),
            powerups: {PowerupType.refresh: 0, PowerupType.joker: 0, PowerupType.hammer: step == 3 ? 1 : 0},
          );
          var s = base.copyWith(
            grid: Grid.fromRows(ex.tutorialBoards[step]),
            hand: [
              null,
              Piece(piece, [ex.tutorialLetters[step]]),
              null,
            ],
            status: GameStatus.playing,
          );
          final (x, y) = _targets[step];
          if (step == 3) s = engine.apply(s, HammerAction(x, y)).state;
          final r = engine.apply(s, PlaceAction(1, x, y));
          final words = [
            for (final e in r.events.whereType<WordsFound>())
              for (final h in e.hits) h.word,
          ]..sort();
          expect(words, isNotEmpty, reason: 'step ${step + 1}');
          built.addAll(words);
        }
        expect(built.first, ex.firstWord);
        expect(built.toSet(), ex.tutorialWords.toSet());
      });
    }, skip: file.existsSync() ? false : 'assets/dict/words_${language.code}.bin is not built yet');
  }
}

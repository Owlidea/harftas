import 'package:flutter_test/flutter_test.dart';
import 'package:harfblok/core/core.dart';

const _en = WordLanguage.english;
const _tr = WordLanguage.turkish;

/// The base-32 keys of the dictionaries before karar 29, for comparison.
int _base32(String upper) {
  var key = 0, scale = 1;
  for (var i = 0; i < upper.length; i++) {
    key += TrAlphabet.codeOf(upper[i]) * scale;
    scale *= 32;
  }
  return key;
}

void main() {
  group('Letters (karar 29)', () {
    test('Turkish letters keep their codes 1..29; new letters are appended', () {
      for (var i = 0; i < TrAlphabet.count; i++) {
        final l = TrAlphabet.all[i];
        expect(Letters.codeOf(l), TrAlphabet.codeOf(l), reason: l);
      }
      expect([Letters.codeOf('Q'), Letters.codeOf('W'), Letters.codeOf('X')], [30, 31, 32]);
      expect(Letters.count, lessThan(64)); // WordKey: 6 bits per letter
    });

    test('every letter of every language has a code', () {
      for (final lang in WordLanguage.values) {
        for (final l in lang.letters) {
          expect(Letters.codeOf(l), greaterThan(0), reason: '${lang.code}: $l');
        }
      }
    });
  });

  group('WordKey', () {
    test('Turkish keys sort exactly like the old base-32 keys', () {
      const words = ['KAR', 'KARE', 'ZİL', 'ÇAĞ', 'AĞAÇ', 'ÜZÜM', 'IŞIK', 'İLİK', 'ŞEKER', 'ABACI', 'ZZZZZZZZ'];
      final byNew = [...words]..sort((a, b) => WordKey.fromWord(a)!.compareTo(WordKey.fromWord(b)!));
      final byOld = [...words]..sort((a, b) => _base32(a).compareTo(_base32(b)));
      expect(byNew, byOld);
    });

    test('English words with Q, W and X round-trip', () {
      for (final w in ['QUIZ', 'WAX', 'BOXES', 'ZYZZYVAS']) {
        final k = WordKey.fromWord(w, _en);
        expect(k, isNotNull, reason: w);
        expect(WordKey.decode(k!), w);
        expect(WordKey.lengthOf(k), w.length);
      }
    });

    test('a word is checked against its own language', () {
      expect(WordKey.fromWord('WIFI'), isNull); // Turkish by default
      expect(WordKey.fromWord('wifi', _en), isNotNull);
      expect(WordKey.fromWord('ağaç', _en), WordKey.fromWord('AGAC', _en)); // accents fold in English
      expect(WordKey.fromWord('AGAC'), isNot(WordKey.fromWord('AĞAÇ'))); // but not in Turkish
    });
  });

  group('English text', () {
    test('accents fold, ligatures and ß expand, NFD input works', () {
      expect(_en.normalize(' café '), 'CAFE');
      expect(_en.normalize('naïve'), 'NAIVE');
      expect(_en.normalize('Straße'), 'STRASSE');
      expect(_en.normalize('encyclopædia'), 'ENCYCLOPAEDIA');
      expect(_en.normalize('café'), 'CAFE');
      expect(_en.normalize('İstanbul'), 'ISTANBUL');
      expect(_en.normalize('ılık'), 'ILIK');
    });

    test('only A-Z make a word', () {
      expect(_en.isWord('HELLO'), isTrue);
      expect(_en.isWord("DON'T"), isFalse);
      expect(_en.isWord('HI-FI'), isFalse);
      expect(_en.isWord(''), isFalse);
      expect(_tr.isWord('QUIZ'), isFalse);
    });

    test('compare follows each alphabet', () {
      expect(_en.compare('QUIZ', 'RUM'), lessThan(0)); // Q before R in English
      expect(_tr.compare('ÇAY', 'DAĞ'), lessThan(0)); // Ç before D in Turkish
      expect(_tr.compare('CAN', 'ÇAY'), lessThan(0));
      expect(_en.compare('CAT', 'CATS'), lessThan(0));
    });
  });

  group('English balance config', () {
    final cfg = BalanceConfig.english;

    test('letter tables cover exactly the English alphabet', () {
      expect(cfg.language, _en);
      expect(cfg.letterScores.keys.toSet(), _en.letters.toSet());
      expect(cfg.letterWeights.keys.toSet(), _en.letters.toSet());
      expect(cfg.rareLetters.every(_en.isLetter), isTrue);
      expect(cfg.letterWeights.values.every((w) => w > 0), isTrue);
    });

    test('JSON keeps the language and falls back to its own tables', () {
      final back = BalanceConfig.fromJson(cfg.toJson());
      expect(back.language, _en);
      expect(back.letterWeights, cfg.letterWeights);
      final sparse = BalanceConfig.fromJson({'language': 'en', 'handSize': 3});
      expect(sparse.letterScores, cfg.letterScores);
      final legacy = BalanceConfig.fromJson({'handSize': 3}); // files before karar 29
      expect(legacy.language, _tr);
      expect(legacy.letterScores, BalanceConfig.defaults.letterScores);
    });

    test('2000 English hands use English letters and respect the hand rules', () {
      final gen = LetterGenerator(cfg);
      final hg = HandGenerator(cfg, common: SetWordDictionary.empty);
      for (var seed = 0; seed < 2000; seed++) {
        final hand = hg.generateRaw(Rng.fromSeed(seed), 0);
        final letters = [for (final p in hand) ...p.letters];
        expect(letters.every(_en.isLetter), isTrue, reason: '$hand');
        final b = gen.vowelBounds(letters.length);
        expect(letters.where(_en.isVowel).length, inInclusiveRange(b.min, b.max), reason: '$hand');
        expect(letters.where(cfg.rareLetters.contains).length, lessThanOrEqualTo(cfg.maxRarePerHand));
        final counts = <String, int>{};
        for (final l in letters) {
          counts[l] = (counts[l] ?? 0) + 1;
        }
        for (final e in counts.entries) {
          if (cfg.scoreOf(e.key) >= cfg.noDuplicateScoreThreshold) expect(e.value, 1, reason: '$hand');
        }
      }
    });
  });

  group('Engine and saved games', () {
    final t0 = DateTime.utc(2026, 11, 25, 9);
    final enWords = SetWordDictionary.fromWords(const ['CAT', 'DOG', 'QUIZ', 'TAX', 'AXE', 'SEA', 'TEA'], _en);
    final en = GameEngine(config: BalanceConfig.english, dictionary: enWords, common: enWords);
    final tr = GameEngine(config: BalanceConfig.defaults, dictionary: SetWordDictionary.fromWords(const ['KAR']));

    test('a new game carries the language of its engine', () {
      expect(en.newGame(seed: 1, mode: GameMode.classic, startedAt: t0).language, 'en');
      expect(tr.newGame(seed: 1, mode: GameMode.classic, startedAt: t0).language, 'tr');
    });

    test('an engine refuses games of another language', () {
      final s = tr.newGame(seed: 1, mode: GameMode.classic, startedAt: t0);
      expect(() => en.revalidate(s), throwsA(isA<InvalidActionException>()));
      expect(() => en.apply(s, const EndAction()), throwsA(isA<InvalidActionException>()));
    });

    test('jokers take letters of the game language only', () {
      final s = en.newGame(seed: 3, mode: GameMode.classic, startedAt: t0);
      final cell = [for (var i = 0; i < 64; i++) i].firstWhere((i) => !s.grid.isFilled(i));
      final x = Grid.xOf(cell), y = Grid.yOf(cell);
      expect(en.apply(s, JokerAction(x, y, 'q')).state.grid[cell]!.letter, 'Q');
      expect(en.apply(s, JokerAction(x, y, 'é')).state.grid[cell]!.letter, 'E'); // accents fold
      expect(() => en.apply(s, JokerAction(x, y, 'ß')), throwsA(isA<InvalidActionException>())); // two letters
      expect(() => en.apply(s, JokerAction(x, y, '1')), throwsA(isA<InvalidActionException>()));
      expect(
        () => tr.apply(tr.newGame(seed: 3, mode: GameMode.classic, startedAt: t0), JokerAction(x, y, 'q')),
        throwsA(isA<InvalidActionException>()),
      );
    });

    test('the language survives a save, and old saves are Turkish', () {
      final s = en.newGame(seed: 5, mode: GameMode.daily, startedAt: t0);
      final back = GameState.fromJson(s.toJson());
      expect(back.language, 'en');
      expect(en.revalidate(back).hand.length, s.hand.length);
      final old = s.toJson()..remove('lang');
      expect(GameState.fromJson(old).language, 'tr');
    });
  });
}

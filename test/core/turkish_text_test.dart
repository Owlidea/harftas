import 'package:flutter_test/flutter_test.dart';
import 'package:harfblok/core/core.dart';

void main() {
  group('TurkishText case conversion (spec 3)', () {
    test('ılık -> ILIK', () => expect(TurkishText.toUpper('ılık'), 'ILIK'));
    test('iğne -> İĞNE', () => expect(TurkishText.toUpper('iğne'), 'İĞNE'));
    test('IŞIK -> ışık', () => expect(TurkishText.toLower('IŞIK'), 'ışık'));
    test('İstanbul -> istanbul', () => expect(TurkishText.toLower('İstanbul'), 'istanbul'));
    test('all lowercase Turkish letters round-trip', () {
      const lower = 'abcçdefgğhıijklmnoöprsştuüvyz';
      final upper = TurkishText.toUpper(lower);
      expect(upper, TrAlphabet.letters);
      expect(TurkishText.toLower(upper), lower);
    });
  });

  group('normalize', () {
    test('circumflex letters are reduced', () {
      expect(TurkishText.normalize('kâğıt'), 'KAĞIT');
      expect(TurkishText.normalize('millî'), 'MİLLİ');
      expect(TurkishText.normalize('mahkûm'), 'MAHKUM');
    });
    test('decomposed sequences are composed (NFC subset)', () {
      expect(TurkishText.normalize('çay'), 'ÇAY');
      expect(TurkishText.normalize('dağ'), 'DAĞ');
      expect(TurkishText.normalize('İstanbul'), 'İSTANBUL');
      // Broken lowercase of İ ("i" + combining dot) must not become two letters.
      expect(TurkishText.normalize('i̇nce'), 'İNCE');
      expect(TurkishText.normalize('kâr'), 'KAR');
      expect(TurkishText.normalize('özür'), 'ÖZÜR');
    });
    test('trims whitespace', () => expect(TurkishText.normalize('  ev '), 'EV'));
  });

  group('isAlphabetic', () {
    test('accepts Turkish letters only', () {
      expect(TurkishText.isAlphabetic('ÇĞİÖŞÜ'), isTrue);
      expect(TurkishText.isAlphabetic('QUIZ'), isFalse);
      expect(TurkishText.isAlphabetic('WEB'), isFalse);
      expect(TurkishText.isAlphabetic('AB-C'), isFalse);
      expect(TurkishText.isAlphabetic(''), isFalse);
    });
  });

  group('WordKey', () {
    test('encode/decode round trip', () {
      for (final w in ['KAR', 'ĞÇŞİÖÜ', 'KARALAMA', 'JİLET']) {
        expect(WordKey.decode(WordKey.fromWord(w)!), w);
      }
    });
    test('case-insensitive, Turkish-aware', () {
      expect(WordKey.fromWord('ılık'), WordKey.fromWord('ILIK'));
      expect(WordKey.fromWord('ılık'), isNot(WordKey.fromWord('İLİK')));
    });
    test('rejects >8 letters and foreign letters', () {
      expect(WordKey.fromWord('KARALAMAK'), isNull);
      expect(WordKey.fromWord('WIFI'), isNull);
    });
    test('different lengths never collide', () {
      expect(WordKey.fromWord('KAR'), isNot(WordKey.fromWord('KARA')));
    });
  });
}

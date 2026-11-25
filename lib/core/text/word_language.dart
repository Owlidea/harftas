import 'alphabet.dart';
import 'latin_text.dart';
import 'turkish_text.dart';

/// A language the board can be played in: its letters, its vowels and the way
/// raw text becomes board letters.
///
/// Board letters are upper case, one UTF-16 code unit each, and have a code in
/// `Letters`. The language's letter scores and weights live in its
/// `BalanceConfig`; its words in its own packed dictionary.
sealed class WordLanguage {
  const WordLanguage();

  /// ISO 639-1 code; also the suffix of the language's asset files.
  String get code;

  /// Upper-case letters in collation order (joker picker, Kelime Defteri).
  String get alphabet;

  Set<String> get vowels;

  /// Raw text -> upper-case board letters, trimmed. Characters that are not
  /// letters of this language are kept, so [isWord] can reject the text.
  String normalize(String input);

  List<String> get letters => alphabet.split('');

  bool isLetter(String upper) => upper.length == 1 && alphabet.contains(upper);

  bool isVowel(String upper) => vowels.contains(upper);

  /// True if [upper] is non-empty and made only of this language's letters.
  bool isWord(String upper) {
    if (upper.isEmpty) return false;
    for (var i = 0; i < upper.length; i++) {
      if (!alphabet.contains(upper[i])) return false;
    }
    return true;
  }

  /// Dictionary order of two words of this language.
  int compare(String a, String b) {
    final n = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < n; i++) {
      final d = alphabet.indexOf(a[i]) - alphabet.indexOf(b[i]);
      if (d != 0) return d;
    }
    return a.length - b.length;
  }

  static const WordLanguage turkish = TurkishLanguage();
  static const WordLanguage english = EnglishLanguage();

  /// Every playable language, in the order the settings list shows them.
  static const List<WordLanguage> values = [turkish, english];

  static WordLanguage? byCode(String? code) {
    for (final l in values) {
      if (l.code == code) return l;
    }
    return null;
  }

  @override
  String toString() => code;
}

/// 29 letters; dotted İ and dotless I are different letters, circumflex
/// vowels are plain vowels (karar 12, `TurkishText`).
final class TurkishLanguage extends WordLanguage {
  const TurkishLanguage();

  @override
  String get code => 'tr';

  @override
  String get alphabet => TrAlphabet.letters;

  @override
  Set<String> get vowels => TrAlphabet.vowels;

  @override
  String normalize(String input) => TurkishText.normalize(input);
}

/// 26 letters, accents folded (CAFÉ -> CAFE). Y counts as a consonant for the
/// vowel quota of a hand.
final class EnglishLanguage extends WordLanguage {
  const EnglishLanguage();

  @override
  String get code => 'en';

  @override
  String get alphabet => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  @override
  Set<String> get vowels => const {'A', 'E', 'I', 'O', 'U'};

  @override
  String normalize(String input) => LatinText.fold(input).toUpperCase().trim();
}

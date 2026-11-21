/// Turkish alphabet (29 letters). Letter codes are 1..29; 0 means "no letter".
abstract final class TrAlphabet {
  static const String letters = 'ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ';

  static final List<String> all = List.unmodifiable(letters.split(''));

  static final Map<String, int> _codes = {for (var i = 0; i < all.length; i++) all[i]: i + 1};

  static const Set<String> vowels = {'A', 'E', 'I', 'İ', 'O', 'Ö', 'U', 'Ü'};

  static int get count => all.length;

  /// Returns the 1-based code of an uppercase Turkish letter, or 0.
  static int codeOf(String upperLetter) => _codes[upperLetter] ?? 0;

  static String letterOf(int code) => all[code - 1];

  static bool isLetter(String s) => _codes.containsKey(s);

  static bool isVowel(String upperLetter) => vowels.contains(upperLetter);
}

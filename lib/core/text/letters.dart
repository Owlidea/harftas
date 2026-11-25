/// Letter codes shared by every word language (1-based; 0 means "no letter").
///
/// The first 29 codes are the Turkish alphabet in its own order, so Turkish
/// codes, word keys and their ascending order are the same as before other
/// languages existed. Letters other languages need are only ever appended:
/// the codes are baked into the packed dictionaries (`assets/dict/`).
/// [WordKey] stores 6 bits per letter, so there is room for 63 letters.
abstract final class Letters {
  static const String all =
      'ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ'
      'QWX';

  static final List<String> _list = List.unmodifiable(all.split(''));

  static final Map<String, int> _codes = {for (var i = 0; i < _list.length; i++) _list[i]: i + 1};

  static int get count => _list.length;

  /// Code of an upper-case board letter, or 0.
  static int codeOf(String letter) => _codes[letter] ?? 0;

  static String letterOf(int code) => _list[code - 1];
}

/// Accent folding for languages whose word games ignore diacritics
/// ("café" is played as CAFE). Turkish does not use this: its dotted and
/// dotless letters are distinct letters (see `TurkishText`).
abstract final class LatinText {
  /// Lower-case precomposed letters -> base letters. Upper-case input is
  /// looked up through its lower-case form.
  static const Map<String, String> _fold = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'ā': 'a',
    'ă': 'a',
    'ą': 'a',
    'ç': 'c',
    'ć': 'c',
    'č': 'c',
    'ĉ': 'c',
    'ċ': 'c',
    'ď': 'd',
    'đ': 'd',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ē': 'e',
    'ĕ': 'e',
    'ė': 'e',
    'ę': 'e',
    'ě': 'e',
    'ğ': 'g',
    'ĝ': 'g',
    'ġ': 'g',
    'ģ': 'g',
    'ĥ': 'h',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ĩ': 'i',
    'ī': 'i',
    'į': 'i',
    'ı': 'i',
    'İ': 'i',
    'ĵ': 'j',
    'ķ': 'k',
    'ĺ': 'l',
    'ļ': 'l',
    'ľ': 'l',
    'ł': 'l',
    'ñ': 'n',
    'ń': 'n',
    'ņ': 'n',
    'ň': 'n',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ø': 'o',
    'ō': 'o',
    'ő': 'o',
    'ŕ': 'r',
    'ř': 'r',
    'ś': 's',
    'ŝ': 's',
    'ş': 's',
    'š': 's',
    'ș': 's',
    'ţ': 't',
    'ť': 't',
    'ț': 't',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ũ': 'u',
    'ū': 'u',
    'ů': 'u',
    'ű': 'u',
    'ų': 'u',
    'ŵ': 'w',
    'ý': 'y',
    'ÿ': 'y',
    'ŷ': 'y',
    'ź': 'z',
    'ż': 'z',
    'ž': 'z',
    'ß': 'ss',
    'ẞ': 'ss',
    'æ': 'ae',
    'œ': 'oe',
  };

  /// Removes diacritics, also from decomposed (NFD) input, and expands
  /// ligatures. Case is kept only for letters without diacritics.
  static String fold(String input) {
    final sb = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x0300 && rune <= 0x036F) continue; // combining marks
      final ch = String.fromCharCode(rune);
      sb.write(_fold[ch] ?? _fold[ch.toLowerCase()] ?? ch);
    }
    return sb.toString();
  }
}

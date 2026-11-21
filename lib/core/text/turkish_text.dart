import 'alphabet.dart';

/// Locale-correct Turkish text helpers.
///
/// Dart's built-in `toUpperCase` / `toLowerCase` are NOT Turkish-aware
/// ("i" -> "I", "İ" -> "i̇"), so every case conversion in the app goes through
/// this class.
abstract final class TurkishText {
  static const Map<String, String> _toUpper = {'i': 'İ', 'ı': 'I', 'ç': 'Ç', 'ğ': 'Ğ', 'ö': 'Ö', 'ş': 'Ş', 'ü': 'Ü'};

  static const Map<String, String> _toLower = {'İ': 'i', 'I': 'ı', 'Ç': 'ç', 'Ğ': 'ğ', 'Ö': 'ö', 'Ş': 'ş', 'Ü': 'ü'};

  /// Circumflex letters are reduced to their plain Turkish counterparts.
  static const Map<String, String> _circumflex = {
    'â': 'a',
    'Â': 'A',
    'î': 'i',
    'Î': 'İ',
    'û': 'u',
    'Û': 'U',
    'ô': 'o',
    'Ô': 'O',
  };

  // Combining marks that may appear in decomposed (NFD) input.
  static const int _dotAbove = 0x0307;
  static const int _cedilla = 0x0327;
  static const int _breve = 0x0306;
  static const int _diaeresis = 0x0308;
  static const int _circumflexMark = 0x0302;

  static const Map<String, String> _compose = {
    'ç': 'ç',
    'Ç': 'Ç',
    'ş': 'ş',
    'Ş': 'Ş',
    'ğ': 'ğ',
    'Ğ': 'Ğ',
    'ö': 'ö',
    'Ö': 'Ö',
    'ü': 'ü',
    'Ü': 'Ü',
    'İ': 'İ',
    // "i" + dot above is what a non-Turkish lowercase of "İ" produces.
    'i̇': 'i',
  };

  static String toUpper(String input) {
    final sb = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      sb.write(_toUpper[ch] ?? ch.toUpperCase());
    }
    return sb.toString();
  }

  static String toLower(String input) {
    final sb = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      sb.write(_toLower[ch] ?? ch.toLowerCase());
    }
    return sb.toString();
  }

  /// Canonical composition for the Turkish letter set (NFC subset).
  ///
  /// Only the combining sequences that can produce Turkish letters are
  /// composed; a lone circumflex mark is dropped. Full Unicode NFC is not
  /// needed because the alphabet is closed.
  static String composeTurkish(String input) {
    final runes = input.runes.toList();
    final sb = StringBuffer();
    for (var i = 0; i < runes.length; i++) {
      final base = runes[i];
      if (i + 1 < runes.length) {
        final mark = runes[i + 1];
        if (mark == _circumflexMark) {
          sb.writeCharCode(base);
          i++;
          continue;
        }
        if (mark == _dotAbove || mark == _cedilla || mark == _breve || mark == _diaeresis) {
          final composed = _compose[String.fromCharCodes([base, mark])];
          if (composed != null) {
            sb.write(composed);
            i++;
            continue;
          }
        }
      }
      sb.writeCharCode(base);
    }
    return sb.toString();
  }

  static String stripCircumflex(String input) {
    final sb = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      sb.write(_circumflex[ch] ?? ch);
    }
    return sb.toString();
  }

  /// Full pipeline for comparison / dictionary keys:
  /// compose -> strip circumflex -> Turkish uppercase -> trim.
  static String normalize(String input) => toUpper(stripCircumflex(composeTurkish(input))).trim();

  /// True if [upper] consists only of the 29 Turkish letters.
  static bool isAlphabetic(String upper) {
    if (upper.isEmpty) return false;
    for (final rune in upper.runes) {
      if (!TrAlphabet.isLetter(String.fromCharCode(rune))) return false;
    }
    return true;
  }
}

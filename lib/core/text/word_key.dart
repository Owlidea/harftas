import 'letters.dart';
import 'word_language.dart';

/// Packs a word of up to 8 board letters into one integer: base-64 digits,
/// letter i = digit i (6 bits each, 48 bits max). Digits are [Letters] codes,
/// shared by every language. 0 is never a valid key.
///
/// Turkish codes are below 32, so Turkish keys sort in the same order as the
/// older base-32 keys did (both orders are "last letter first").
///
/// Uses multiplication instead of shifts so results are identical on the web
/// (where shifts are 32-bit but integers are exact up to 2^53).
abstract final class WordKey {
  static const int maxLength = 8;
  static const int bitsPerLetter = 6;

  static const List<int> _pow64 = [1, 64, 4096, 262144, 16777216, 1073741824, 68719476736, 4398046511104];

  static int append(int key, int position, int letterCode) => key + letterCode * _pow64[position];

  /// Number of letters in [key].
  static int lengthOf(int key) {
    var n = 0;
    for (var k = key; k != 0; k ~/= 64) {
      n++;
    }
    return n;
  }

  static int fromCodes(List<int> codes) {
    assert(codes.length <= maxLength);
    var key = 0;
    for (var i = 0; i < codes.length; i++) {
      key = append(key, i, codes[i]);
    }
    return key;
  }

  /// Returns null when [word] (any case) has letters outside [language] or
  /// is too long.
  static int? fromWord(String word, [WordLanguage language = WordLanguage.turkish]) {
    final upper = language.normalize(word);
    if (!language.isWord(upper) || upper.length > maxLength) return null;
    return fromCodes([for (var i = 0; i < upper.length; i++) Letters.codeOf(upper[i])]);
  }

  static String decode(int key) {
    final sb = StringBuffer();
    var k = key;
    while (k != 0) {
      sb.write(Letters.letterOf(k % 64));
      k ~/= 64;
    }
    return sb.toString();
  }
}

import 'alphabet.dart';
import 'turkish_text.dart';

/// Packs a word of up to 8 Turkish letters into one integer: base-32 digits,
/// letter i = digit i (i.e. 5 bits each, 40 bits max). 0 is never a valid key.
///
/// Uses multiplication instead of shifts so results are identical on the web
/// (where shifts are 32-bit but integers are exact up to 2^53).
abstract final class WordKey {
  static const int maxLength = 8;
  static const int bitsPerLetter = 5;

  static const List<int> _pow32 = [1, 32, 1024, 32768, 1048576, 33554432, 1073741824, 34359738368];

  static int append(int key, int position, int letterCode) => key + letterCode * _pow32[position];

  /// Number of letters in [key].
  static int lengthOf(int key) {
    var n = 0;
    for (var k = key; k != 0; k ~/= 32) {
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

  /// Returns null when [word] (any case) has non-Turkish letters or is too long.
  static int? fromWord(String word) {
    final upper = TurkishText.normalize(word);
    if (!TurkishText.isAlphabetic(upper)) return null;
    final letters = upper.split('');
    if (letters.length > maxLength) return null;
    return fromCodes([for (final l in letters) TrAlphabet.codeOf(l)]);
  }

  static String decode(int key) {
    final sb = StringBuffer();
    var k = key;
    while (k != 0) {
      sb.write(TrAlphabet.letterOf(k % 32));
      k ~/= 32;
    }
    return sb.toString();
  }
}

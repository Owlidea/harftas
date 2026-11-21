import '../config/balance_config.dart';
import '../model/shape.dart';
import '../rng/rng.dart';
import '../text/alphabet.dart';

/// Assigns letters to the cells of a hand under the spec 4 constraints:
/// - vowels: floor(0.4n)..ceil(0.6n), at least 1 (karar 7)
/// - letters scoring >= 5: at most one of each per hand
/// - rare letters: at most 2 per hand (karar 8)
/// - Ğ only where the shape has a cell to its left AND above (karar 9)
class LetterGenerator {
  LetterGenerator(this.config)
    : _letters = TrAlphabet.all,
      _weights = [for (final l in TrAlphabet.all) config.letterWeights[l] ?? 0];

  final BalanceConfig config;
  final List<String> _letters;
  final List<int> _weights;

  static const String softG = 'Ğ';

  ({int min, int max}) vowelBounds(int n) {
    var min = (config.vowelMinRatio * n).floor();
    if (min < config.minVowelsPerHand) min = config.minVowelsPerHand;
    var max = (config.vowelMaxRatio * n).ceil();
    if (max > n) max = n;
    if (min > max) min = max;
    return (min: min, max: max);
  }

  List<List<String>> assign(List<Shape> shapes, Rng rng) {
    final slots = <({int piece, int cell, bool softGOk})>[];
    for (var p = 0; p < shapes.length; p++) {
      for (var c = 0; c < shapes[p].size; c++) {
        slots.add((piece: p, cell: c, softGOk: shapes[p].canHoldSoftG(c)));
      }
    }
    rng.shuffle(slots);

    final n = slots.length;
    final bounds = vowelBounds(n);
    final out = [for (final s in shapes) List<String>.filled(s.size, '')];
    final used = <String, int>{};
    var vowels = 0;
    var rare = 0;
    final w = List<int>.filled(_letters.length, 0);

    for (var i = 0; i < n; i++) {
      final slot = slots[i];
      final remaining = n - i;
      final mustVowel = bounds.min - vowels >= remaining;
      final mustConsonant = vowels >= bounds.max;

      for (var k = 0; k < _letters.length; k++) {
        final l = _letters[k];
        final isV = TrAlphabet.isVowel(l);
        var ok = _weights[k] > 0;
        if (ok && mustVowel && !isV) ok = false;
        if (ok && mustConsonant && isV) ok = false;
        if (ok && config.scoreOf(l) >= config.noDuplicateScoreThreshold && (used[l] ?? 0) > 0) {
          ok = false;
        }
        if (ok && config.rareLetters.contains(l) && rare >= config.maxRarePerHand) {
          ok = false;
        }
        if (ok && l == softG && !slot.softGOk) ok = false;
        w[k] = ok ? _weights[k] : 0;
      }

      final letter = _letters[rng.weighted(w)];
      out[slot.piece][slot.cell] = letter;
      used[letter] = (used[letter] ?? 0) + 1;
      if (TrAlphabet.isVowel(letter)) vowels++;
      if (config.rareLetters.contains(letter)) rare++;
    }
    return out;
  }
}

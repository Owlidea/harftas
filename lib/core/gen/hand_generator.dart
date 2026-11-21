import '../config/balance_config.dart';
import '../dictionary.dart';
import '../model/grid.dart';
import '../model/piece.dart';
import '../model/shape.dart';
import '../rng/rng.dart';
import '../rules/word_detector.dart';
import '../text/alphabet.dart';
import '../text/word_key.dart';
import 'letter_generator.dart';

/// How a new hand is made "playable" (spec 4 kolaylaştırıcı kural).
enum EasingMode {
  none,

  /// Classic: some piece + placement on the current grid forms a common word.
  grid,

  /// Daily: grid-independent (stays fair, karar 5) — the hand's letters can
  /// spell at least one common 3–4 letter word.
  letters,
}

class HandGenerator {
  HandGenerator(this.config, {required WordDictionary common})
    : letters = LetterGenerator(config),
      _commonDetector = WordDetector(config, common),
      _common = common,
      _spellable = [
        for (final k in common.keys)
          if (WordKey.lengthOf(k) >= 3 && WordKey.lengthOf(k) <= 4) _counts(WordKey.decode(k).split('')),
      ];

  final BalanceConfig config;
  final LetterGenerator letters;
  final WordDetector _commonDetector;
  final WordDictionary _common;
  final List<List<int>> _spellable;

  static List<int> _counts(Iterable<String> letters) {
    final c = List<int>.filled(TrAlphabet.count + 1, 0);
    for (final l in letters) {
      c[TrAlphabet.codeOf(l)]++;
    }
    return c;
  }

  /// Size (1..4) -> family (uniform) -> orientation (uniform). Karar 16.
  Shape pickShape(Rng rng, int score) {
    final size = rng.weighted(config.sizeWeightsFor(score)) + 1;
    final families = ShapeCatalog.familiesBySize[size]!;
    final family = families[rng.nextInt(families.length)];
    final options = ShapeCatalog.byFamily[family]!;
    return options[rng.nextInt(options.length)];
  }

  List<Piece> generateRaw(Rng rng, int score) {
    final shapes = [for (var i = 0; i < config.handSize; i++) pickShape(rng, score)];
    final ls = letters.assign(shapes, rng);
    return [for (var i = 0; i < shapes.length; i++) Piece(shapes[i], ls[i])];
  }

  /// Deals hand number [handCounter]. Tries up to `easingMaxAttempts` hands
  /// until one satisfies [easing]; otherwise keeps the last attempt.
  List<Piece> deal({
    required int seed,
    required int handCounter,
    required int score,
    required Grid grid,
    required EasingMode easing,
  }) {
    final rng = Rng.stream(seed, handCounter);
    // On an empty board the grid rule would only pick pieces that are words
    // by themselves (free +100 clears), so it is skipped there.
    final skipGrid = easing == EasingMode.grid && grid.isEmpty;
    final attempts = easing != EasingMode.none && !skipGrid && !_common.isEmpty ? config.easingMaxAttempts : 1;
    late List<Piece> hand;
    for (var a = 0; a < attempts; a++) {
      hand = generateRaw(rng, score);
      if (attempts == 1) return hand;
      final ok = easing == EasingMode.grid ? canFormCommonWord(grid, hand) : canSpellCommonWord(hand);
      if (ok) return hand;
    }
    return hand;
  }

  /// True if some common 3–4 letter word uses only letters from [hand].
  bool canSpellCommonWord(List<Piece> hand) {
    final have = _counts([for (final p in hand) ...p.letters]);
    outer:
    for (final need in _spellable) {
      for (var i = 1; i < need.length; i++) {
        if (need[i] > have[i]) continue outer;
      }
      return true;
    }
    return false;
  }

  /// VARSAYIM: "kurulabilir" = one piece, one placement on the current grid.
  bool canFormCommonWord(Grid grid, List<Piece> hand) {
    final scratch = grid.copy();
    for (final piece in hand) {
      final shape = piece.shape;
      for (var y = 0; y <= Grid.size - shape.height; y++) {
        for (var x = 0; x <= Grid.size - shape.width; x++) {
          if (!shape.fits(scratch, x, y)) continue;
          final cells = shape.indicesAt(x, y);
          for (var i = 0; i < cells.length; i++) {
            scratch.set(cells[i], Cell(piece.letters[i]));
          }
          final found = _commonDetector.detect(scratch, cells).isNotEmpty;
          for (final c in cells) {
            scratch.set(c, null);
          }
          if (found) return true;
        }
      }
    }
    return false;
  }
}

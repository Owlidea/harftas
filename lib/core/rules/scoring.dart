import '../config/balance_config.dart';
import 'word_detector.dart';

class MoveScore {
  const MoveScore({
    required this.wordPoints,
    required this.placementPoints,
    required this.clearBonus,
    required this.combo,
    required this.streakMultiplierX10,
  });

  static const MoveScore zero = MoveScore(
    wordPoints: 0,
    placementPoints: 0,
    clearBonus: 0,
    combo: 0,
    streakMultiplierX10: 10,
  );

  /// After combo, streak and floor rounding.
  final int wordPoints;
  final int placementPoints;
  final int clearBonus;

  /// Number of words exploded this move (combo multiplier).
  final int combo;

  /// 10 = x1.0 ... 20 = x2.0.
  final int streakMultiplierX10;

  int get total => wordPoints + placementPoints + clearBonus;

  @override
  String toString() =>
      'MoveScore(words=$wordPoints place=$placementPoints clear=$clearBonus combo=$combo streak=${streakMultiplierX10 / 10} total=$total)';
}

class ScoreResult {
  const ScoreResult(this.score, this.streakAfter);
  final MoveScore score;
  final int streakAfter;
}

/// Pure scoring (spec 5, docs/algoritma.md §2). Integer math in x10 scale;
/// one floor at the end: words -> combo -> streak -> floor -> placement/clear.
///
/// [resetStreakWithoutWords]: false for joker moves that form no word
/// (karar 13: such moves leave the streak unchanged).
ScoreResult scoreMove({
  required BalanceConfig config,
  required List<WordHit> hits,
  required int placedCells,
  required bool gridEmptyAfter,
  required int streakBefore,
  bool resetStreakWithoutWords = true,
}) {
  final placement = placedCells * config.placementPointsPerCell;
  if (hits.isEmpty) {
    return ScoreResult(
      MoveScore(wordPoints: 0, placementPoints: placement, clearBonus: 0, combo: 0, streakMultiplierX10: 10),
      resetStreakWithoutWords ? 0 : streakBefore,
    );
  }

  var base10 = 0;
  for (final h in hits) {
    base10 += h.baseScoreX10;
  }
  final combo = hits.length;
  final streakAfter = streakBefore + 1;
  var streak10 = 10 + (streakAfter - 1) * config.streakStepX10;
  if (streak10 > config.streakCapX10) streak10 = config.streakCapX10;

  final wordPoints = (base10 * combo * streak10) ~/ 100;
  final clear = gridEmptyAfter ? config.clearBoardBonus : 0;

  return ScoreResult(
    MoveScore(
      wordPoints: wordPoints,
      placementPoints: placement,
      clearBonus: clear,
      combo: combo,
      streakMultiplierX10: streak10,
    ),
    streakAfter,
  );
}

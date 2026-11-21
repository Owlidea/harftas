import 'dart:math' as math;

import '../core/model/game_state.dart';

/// Spec 8: XP = score / 10; level N -> N+1 needs round(500 * N^1.5) XP
/// (karar 14: per level, not cumulative).
abstract final class Levels {
  static int xpForScore(int score) => score ~/ 10;

  static int xpToNext(int level) => (500 * math.pow(level, 1.5)).round();

  /// Level (starting at 1) and XP progress inside it for [totalXp].
  static ({int level, int intoLevel, int needed}) fromTotalXp(int totalXp) {
    var level = 1;
    var rest = totalXp;
    while (rest >= xpToNext(level)) {
      rest -= xpToNext(level);
      level++;
    }
    return (level: level, intoLevel: rest, needed: xpToNext(level));
  }

  /// Reward for reaching [level] (spec 8: theme, tile style, powerup).
  static LevelReward rewardFor(int level) {
    const unlocks = <int, LevelReward>{
      3: LevelReward.tileStyle('soft'),
      5: LevelReward.theme('olive'),
      8: LevelReward.tileStyle('sharp'),
      10: LevelReward.theme('lavender'),
      15: LevelReward.theme('amber'),
    };
    return unlocks[level] ?? LevelReward.powerup(PowerupType.values[level % PowerupType.values.length]);
  }
}

class LevelReward {
  const LevelReward.theme(String this.themeId) : tileStyleId = null, powerup = null;
  const LevelReward.tileStyle(String this.tileStyleId) : themeId = null, powerup = null;
  const LevelReward.powerup(PowerupType this.powerup) : themeId = null, tileStyleId = null;

  final String? themeId;
  final String? tileStyleId;
  final PowerupType? powerup;
}

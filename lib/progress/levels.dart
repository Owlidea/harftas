import '../core/model/game_state.dart';

/// Spec 8: XP = score / 10. Karar 21: level N -> N+1 needs 250 + 150 * N XP
/// (per level, not cumulative). The original round(500 * N^1.5) put level 5
/// about a month and level 10 half a year away for a daily player, so most
/// rewards were never reached.
abstract final class Levels {
  static int xpForScore(int score) => score ~/ 10;

  static int xpToNext(int level) => 250 + 150 * level;

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

  /// Reward for reaching [level] (spec 8: theme, tile style, board style,
  /// powerup). A cosmetic lands every few levels; the rest are powerups.
  static LevelReward rewardFor(int level) {
    const unlocks = <int, LevelReward>{
      3: LevelReward.tileStyle('soft'),
      4: LevelReward.boardStyle('felt'),
      5: LevelReward.theme('olive'),
      7: LevelReward.boardStyle('grain'),
      8: LevelReward.tileStyle('sharp'),
      10: LevelReward.theme('lavender'),
      12: LevelReward.tileStyle('grain'),
      14: LevelReward.boardStyle('marble'),
      15: LevelReward.theme('amber'),
      20: LevelReward.tileStyle('marble'),
    };
    return unlocks[level] ?? LevelReward.powerup(PowerupType.values[level % PowerupType.values.length]);
  }
}

class LevelReward {
  const LevelReward.theme(String this.themeId) : tileStyleId = null, boardStyleId = null, powerup = null;
  const LevelReward.tileStyle(String this.tileStyleId) : themeId = null, boardStyleId = null, powerup = null;
  const LevelReward.boardStyle(String this.boardStyleId) : themeId = null, tileStyleId = null, powerup = null;
  const LevelReward.powerup(PowerupType this.powerup) : themeId = null, tileStyleId = null, boardStyleId = null;

  final String? themeId;
  final String? tileStyleId;
  final String? boardStyleId;
  final PowerupType? powerup;
}

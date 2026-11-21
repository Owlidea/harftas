import '../core/model/game_state.dart';
import 'calendar.dart';
import 'levels.dart';
import 'missions.dart';
import 'profile.dart';
import 'streak.dart';
import 'summaries.dart';
import 'wordbook.dart';

/// Something the player earned; the UI shows these after a game.
sealed class Reward {
  const Reward();
}

class LevelUpReward extends Reward {
  const LevelUpReward(this.level, this.reward);
  final int level;
  final LevelReward reward;
}

class MissionReward extends Reward {
  const MissionReward(this.mission);
  final Mission mission;
}

class StreakBadgeReward extends Reward {
  const StreakBadgeReward(this.days, this.themeId);
  final int days;
  final String themeId;
}

class GameEndResult {
  const GameEndResult({
    required this.xpGained,
    required this.newRecord,
    required this.rewards,
    required this.newWords,
    this.dailyResult,
    this.shieldUsed = false,
    this.missionsAfter = const [],
  });

  final int xpGained;
  final bool newRecord;
  final List<Reward> rewards;
  final int newWords;
  final DailyResult? dailyResult;
  final bool shieldUsed;

  /// Today's missions after this game (for the game-over summary).
  final List<Mission> missionsAfter;
}

/// Pure progression rules (spec 8). Mutates the given profile / wordbook.
abstract final class Progression {
  static const Map<int, String> streakThemes = {7: 'dawn', 30: 'sea', 100: 'midnight'};

  static void ensureMissions(PlayerProfile p, DayKey today) {
    if (p.missionsDay != today.toString()) {
      p.missionsDay = today.toString();
      p.missions = MissionPool.forDay(today);
    }
  }

  /// Returns newly completed missions and any level-ups their XP caused.
  static ({List<Mission> missions, List<LevelUpReward> levelUps}) applyMove(
    PlayerProfile p,
    MoveSummary move,
    DayKey today,
  ) {
    ensureMissions(p, today);
    final done = _updateMissions(p, (m) => MissionPool.applyMove(m, move));
    final levels = <LevelUpReward>[for (final m in done) ...addXp(p, m.rewardXp)];
    return (missions: done, levelUps: levels);
  }

  static GameEndResult applyGameEnd(PlayerProfile p, Wordbook book, GameSummary g, DayKey today) {
    ensureMissions(p, today);
    final rewards = <Reward>[];

    var newWords = 0;
    for (final w in g.words) {
      if (book.add(w.word, w.score, today)) newWords++;
    }

    final newRecord = g.mode == GameMode.classic && g.score > p.bestScore;
    if (newRecord) p.bestScore = g.score;
    p.totalGames++;
    p.totalWords += g.wordCount;
    p.totalLetters += g.words.fold(0, (n, w) => n + w.length);
    if (g.bestStreak > p.bestMoveStreak) p.bestMoveStreak = g.bestStreak;

    for (final m in _updateMissions(p, (m) => MissionPool.applyGame(m, g))) {
      rewards
        ..add(MissionReward(m))
        ..addAll(addXp(p, m.rewardXp));
    }

    DailyResult? daily;
    var shieldUsed = false;
    if (g.mode == GameMode.daily && p.dailyFor(today) == null) {
      final r = p.streak.complete(today);
      p.streak = r.streak;
      shieldUsed = r.shieldUsed;
      for (final days in r.reached) {
        p.badges.add('streak_$days');
        final theme = streakThemes[days]!;
        p.unlockedThemes.add(theme);
        rewards.add(StreakBadgeReward(days, theme));
      }
      daily = DailyResult(
        score: g.score,
        words: g.wordCount,
        longestLength: g.longestLength,
        streakAfter: r.streak.current,
      );
      p.daily[today.toString()] = daily;
    }

    final xp = Levels.xpForScore(g.score);
    rewards.addAll(addXp(p, xp));

    return GameEndResult(
      xpGained: xp,
      newRecord: newRecord,
      rewards: rewards,
      newWords: newWords,
      dailyResult: daily,
      shieldUsed: shieldUsed,
      missionsAfter: List.unmodifiable(p.missions),
    );
  }

  static List<LevelUpReward> addXp(PlayerProfile p, int xp) {
    final before = Levels.fromTotalXp(p.totalXp).level;
    p.totalXp += xp;
    final after = Levels.fromTotalXp(p.totalXp).level;
    return [for (var l = before + 1; l <= after; l++) _grantLevel(p, l)];
  }

  static LevelUpReward _grantLevel(PlayerProfile p, int level) {
    final r = Levels.rewardFor(level);
    if (r.themeId != null) p.unlockedThemes.add(r.themeId!);
    if (r.tileStyleId != null) p.unlockedTileStyles.add(r.tileStyleId!);
    if (r.powerup != null) p.powerups[r.powerup!] = (p.powerups[r.powerup!] ?? 0) + 1;
    return LevelUpReward(level, r);
  }

  static List<Mission> _updateMissions(PlayerProfile p, Mission Function(Mission) f) {
    final completed = <Mission>[];
    p.missions = [
      for (final m in p.missions)
        () {
          final n = f(m);
          if (!m.done && n.done) {
            completed.add(n);
            p.powerups[n.rewardPowerup] = (p.powerups[n.rewardPowerup] ?? 0) + 1;
          }
          return n;
        }(),
    ];
    return completed;
  }

  /// Spec 12: interstitial only at game end, at most every 3 games, never in
  /// the first 3 sessions, never after the daily puzzle, never if ads removed.
  static bool shouldShowInterstitial(
    PlayerProfile p,
    GameMode mode, {
    required int everyGames,
    required int freeSessions,
  }) {
    if (p.adsRemoved || mode == GameMode.daily) return false;
    if (p.sessions <= freeSessions) return false;
    return p.gamesSinceInterstitial + 1 >= everyGames;
  }
}

extension DailyStreakX on DailyStreak {
  int get nextMilestone => DailyStreak.milestones.firstWhere((m) => m > current, orElse: () => 0);
}

import '../core/model/game_state.dart';
import 'achievements.dart';
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

class AchievementReward extends Reward {
  const AchievementReward(this.achievement);
  final Achievement achievement;
}

class WeeklyReward extends Reward {
  const WeeklyReward(this.goal);
  final WeeklyGoal goal;
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
    this.totalXpAfter = 0,
  });

  final int xpGained;
  final bool newRecord;
  final List<Reward> rewards;
  final int newWords;
  final DailyResult? dailyResult;
  final bool shieldUsed;

  /// Today's missions after this game (for the game-over summary).
  final List<Mission> missionsAfter;

  /// Total XP once everything this game earned is counted.
  final int totalXpAfter;
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

  static void ensureWeekly(PlayerProfile p, DayKey today) {
    if (p.weekly?.week != WeeklyGoal.weekOf(today)) p.weekly = WeeklyGoal.forDay(today);
  }

  /// Returns newly completed missions, the weekly goal if this move finished
  /// it, and any level-ups their XP caused.
  static ({List<Mission> missions, WeeklyGoal? weekly, List<LevelUpReward> levelUps}) applyMove(
    PlayerProfile p,
    MoveSummary move,
    DayKey today,
  ) {
    ensureMissions(p, today);
    ensureWeekly(p, today);
    if (move.combo > p.bestCombo) p.bestCombo = move.combo;
    final done = _updateMissions(p, (m) => MissionPool.applyMove(m, move));
    final levels = <LevelUpReward>[for (final m in done) ...addXp(p, m.rewardXp)];
    final weekly = _updateWeekly(p, (m) => MissionPool.applyMove(m, move));
    if (weekly != null) levels.addAll(addXp(p, WeeklyGoal.rewardXp));
    return (missions: done, weekly: weekly, levelUps: levels);
  }

  static GameEndResult applyGameEnd(PlayerProfile p, Wordbook book, GameSummary g, DayKey today) {
    ensureMissions(p, today);
    ensureWeekly(p, today);
    final rewards = <Reward>[];

    var newWords = 0;
    for (final w in g.words) {
      if (book.add(w.word, w.score, today)) newWords++;
    }

    final newRecord = g.mode == GameMode.classic && g.score > p.bestScoreFor(g.language);
    if (newRecord) p.setBestScore(g.language, g.score);
    p.totalGames++;
    p.totalWords += g.wordCount;
    p.totalLetters += g.words.fold(0, (n, w) => n + w.length);
    if (g.bestStreak > p.bestMoveStreak) p.bestMoveStreak = g.bestStreak;
    p.boardClears += g.boardClears;

    for (final m in _updateMissions(p, (m) => MissionPool.applyGame(m, g))) {
      rewards
        ..add(MissionReward(m))
        ..addAll(addXp(p, m.rewardXp));
    }

    final weekly = _updateWeekly(p, (m) => MissionPool.applyGame(m, g));
    if (weekly != null) {
      rewards
        ..add(WeeklyReward(weekly))
        ..addAll(addXp(p, WeeklyGoal.rewardXp));
    }

    DailyResult? daily;
    var shieldUsed = false;
    if (g.mode == GameMode.daily && p.dailyFor(today, g.language) == null) {
      // One streak for all languages: a second language's puzzle on the same
      // day leaves it as it is (complete() is a no-op for a day already played).
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
      p.daily[PlayerProfile.dailyKey(today, g.language)] = daily;
    }

    final xp = Levels.xpForScore(g.score);
    rewards.addAll(addXp(p, xp));
    rewards.addAll(claimAchievements(p, book, g.language));

    return GameEndResult(
      xpGained: xp,
      newRecord: newRecord,
      rewards: rewards,
      newWords: newWords,
      dailyResult: daily,
      shieldUsed: shieldUsed,
      missionsAfter: List.unmodifiable(p.missions),
      totalXpAfter: p.totalXp,
    );
  }

  /// Marks every newly reached achievement as earned and pays its XP.
  static List<Reward> claimAchievements(PlayerProfile p, Wordbook book, [String language = 'tr']) {
    final out = <Reward>[];
    for (final a in Achievements.all) {
      if (p.achievements.contains(a.id) || !Achievements.reached(a, p, book, language)) continue;
      p.achievements.add(a.id);
      out
        ..add(AchievementReward(a))
        ..addAll(addXp(p, a.rewardXp));
    }
    return out;
  }

  static List<LevelUpReward> addXp(PlayerProfile p, int xp) {
    final before = Levels.fromTotalXp(p.totalXp).level;
    p.totalXp += xp;
    final after = Levels.fromTotalXp(p.totalXp).level;
    return [for (var l = before + 1; l <= after; l++) _grantLevel(p, l)];
  }

  /// Unlocks every theme / tile style whose level the player has already
  /// passed. Rewards added in an update (e.g. new tile styles) would otherwise
  /// stay locked for players who were above that level. Powerups are not
  /// re-granted. Returns true when something was unlocked.
  static bool syncLevelUnlocks(PlayerProfile p) {
    final level = Levels.fromTotalXp(p.totalXp).level;
    var changed = false;
    for (var l = 2; l <= level; l++) {
      final r = Levels.rewardFor(l);
      if (r.themeId != null) changed = p.unlockedThemes.add(r.themeId!) || changed;
      if (r.tileStyleId != null) changed = p.unlockedTileStyles.add(r.tileStyleId!) || changed;
      if (r.boardStyleId != null) changed = p.unlockedBoardStyles.add(r.boardStyleId!) || changed;
    }
    return changed;
  }

  static LevelUpReward _grantLevel(PlayerProfile p, int level) {
    final r = Levels.rewardFor(level);
    if (r.themeId != null) p.unlockedThemes.add(r.themeId!);
    if (r.tileStyleId != null) p.unlockedTileStyles.add(r.tileStyleId!);
    if (r.boardStyleId != null) p.unlockedBoardStyles.add(r.boardStyleId!);
    if (r.powerup != null) p.powerups[r.powerup!] = (p.powerups[r.powerup!] ?? 0) + 1;
    return LevelUpReward(level, r);
  }

  /// Advances the weekly goal; returns it when this update completed it
  /// (its powerups are granted here, its XP by the caller).
  static WeeklyGoal? _updateWeekly(PlayerProfile p, Mission Function(Mission) f) {
    final w = p.weekly;
    if (w == null || w.mission.done) return null;
    final next = WeeklyGoal(week: w.week, mission: f(w.mission));
    p.weekly = next;
    if (!next.mission.done) return null;
    for (final t in PowerupType.values) {
      p.powerups[t] = (p.powerups[t] ?? 0) + WeeklyGoal.rewardPowerups;
    }
    return next;
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

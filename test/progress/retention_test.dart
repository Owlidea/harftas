import 'package:flutter_test/flutter_test.dart';
import 'package:harfblok/core/core.dart';
import 'package:harfblok/progress/achievements.dart';
import 'package:harfblok/progress/calendar.dart';
import 'package:harfblok/progress/missions.dart';
import 'package:harfblok/progress/profile.dart';
import 'package:harfblok/progress/progression.dart';
import 'package:harfblok/progress/summaries.dart';
import 'package:harfblok/progress/wordbook.dart';

MoveSummary _move(List<String> words, {int streak = 1, bool cleared = false}) => MoveSummary(
  words: [for (final w in words) WordResult(w, w.length)],
  placedCells: 3,
  streakAfter: streak,
  clearedBoard: cleared,
);

GameSummary _game({
  int score = 400,
  List<String> words = const [],
  GameMode mode = GameMode.classic,
  int boardClears = 0,
  int bestStreak = 0,
}) => GameSummary(
  mode: mode,
  score: score,
  moves: 40,
  duration: const Duration(minutes: 4),
  words: [for (final w in words) WordResult(w, w.length)],
  usedPowerups: false,
  bestStreak: bestStreak,
  boardClears: boardClears,
  continued: false,
);

void main() {
  const monday = DayKey(2026, 11, 23);
  const sunday = DayKey(2026, 11, 29);

  group('Weekly goal', () {
    test('weeks run Monday to Sunday and everyone gets the same goal', () {
      expect(monday.weekday, 1);
      expect(WeeklyGoal.weekOf(monday), WeeklyGoal.weekOf(sunday));
      expect(WeeklyGoal.weekOf(sunday.addDays(1)), WeeklyGoal.weekOf(monday) + 1);
      expect(WeeklyGoal.daysLeft(monday), 7);
      expect(WeeklyGoal.daysLeft(sunday), 1);
      final a = WeeklyGoal.forDay(monday);
      final b = WeeklyGoal.forDay(sunday);
      expect((a.week, a.mission.type, a.mission.target), (b.week, b.mission.type, b.mission.target));
    });

    test('every goal in the rotation can be advanced by play', () {
      for (var w = 0; w < 14; w++) {
        final goal = WeeklyGoal.forDay(monday.addDays(7 * w));
        final m = goal.mission;
        final moved = MissionPool.applyMove(m, _move(['KALEM', 'ŞEKER', 'ÇÖZÜM', 'ÜZÜMY', 'ZARFÖ'], cleared: true));
        final played = MissionPool.applyGame(m, _game(score: 500, mode: GameMode.daily));
        expect(moved.progress + played.progress, greaterThan(0), reason: '${m.type} week $w');
      }
    });

    test('progress carries over the week, completes once, pays XP and powerups, then resets', () {
      final p = PlayerProfile();
      Progression.ensureWeekly(p, monday);
      // Force a known goal so the test does not depend on the rotation.
      p.weekly = WeeklyGoal(
        week: WeeklyGoal.weekOf(monday),
        mission: const Mission(type: MissionType.scoreTotal, tier: MissionTier.hard, target: 1000),
      );
      final book = Wordbook();
      final xp0 = p.totalXp;
      final r1 = Progression.applyGameEnd(p, book, _game(score: 600), monday);
      expect(r1.rewards.whereType<WeeklyReward>(), isEmpty);
      expect(p.weekly!.mission.progress, 600);
      final before = Map.of(p.powerups);
      final r2 = Progression.applyGameEnd(p, book, _game(score: 600), monday.addDays(2));
      expect(r2.rewards.whereType<WeeklyReward>(), hasLength(1));
      expect(p.weekly!.mission.done, isTrue);
      for (final t in PowerupType.values) {
        expect(p.powerups[t]! - before[t]!, greaterThanOrEqualTo(WeeklyGoal.rewardPowerups), reason: t.name);
      }
      expect(p.totalXp - xp0, greaterThanOrEqualTo(WeeklyGoal.rewardXp + 120));
      // Finished goals are not paid twice.
      final r3 = Progression.applyGameEnd(p, book, _game(score: 900), sunday);
      expect(r3.rewards.whereType<WeeklyReward>(), isEmpty);
      // A new week brings a new, unfinished goal.
      Progression.ensureWeekly(p, sunday.addDays(1));
      expect(p.weekly!.week, WeeklyGoal.weekOf(monday) + 1);
      expect(p.weekly!.mission.done, isFalse);
      expect(p.weekly!.mission.progress, 0);
    });

    test('a move can finish the weekly goal mid-game and survives a save', () {
      final p = PlayerProfile();
      p.weekly = WeeklyGoal(
        week: WeeklyGoal.weekOf(monday),
        mission: const Mission(type: MissionType.comboTwo, tier: MissionTier.hard, target: 1),
      );
      final r = Progression.applyMove(p, _move(['KAR', 'ELMA']), monday);
      expect(r.weekly, isNotNull);
      expect(p.bestCombo, 2);
      final back = PlayerProfile.fromJson(p.toJson());
      expect(back.weekly!.mission.done, isTrue);
      expect(back.bestCombo, 2);
    });
  });

  group('Achievements', () {
    test('ids are unique and tiers of a kind ascend', () {
      expect(Achievements.all.map((a) => a.id).toSet(), hasLength(Achievements.all.length));
      for (final k in AchievementKind.values) {
        final targets = [
          for (final a in Achievements.all)
            if (a.kind == k) a.target,
        ];
        expect(targets, isNotEmpty, reason: k.name);
        expect(targets, [...targets]..sort(), reason: k.name);
      }
    });

    test('earned once at game end, with XP, and never again', () {
      final p = PlayerProfile();
      final book = Wordbook();
      final r = Progression.applyGameEnd(
        p,
        book,
        _game(score: 520, words: ['KALEM', 'KAR'], boardClears: 1, bestStreak: 5),
        monday,
      );
      final got = r.rewards.whereType<AchievementReward>().map((a) => a.achievement.id).toSet();
      // 5-letter word, 500 points, a 5-move streak and a cleared board.
      expect(got, containsAll(['length_5', 'score_500', 'moveStreak_5', 'clears_1']));
      expect(got, isNot(contains('score_1000')));
      expect(p.achievements, got);
      expect(p.boardClears, 1);
      expect(r.totalXpAfter, p.totalXp);
      expect(p.totalXp, greaterThanOrEqualTo(52 + 100 * got.length));
      final again = Progression.applyGameEnd(p, book, _game(score: 100), monday);
      expect(again.rewards.whereType<AchievementReward>(), isEmpty);
      expect(PlayerProfile.fromJson(p.toJson()).achievements, got);
    });

    test('rare-letter and combo achievements read the wordbook and best combo', () {
      final p = PlayerProfile();
      final book = Wordbook();
      Progression.applyMove(p, _move(['KAR', 'ELMA', 'NAR']), monday);
      final r = Progression.applyGameEnd(p, book, _game(words: ['JİLET']), monday);
      final got = r.rewards.whereType<AchievementReward>().map((a) => a.achievement.id).toSet();
      expect(got, containsAll(['rare_1', 'combo_2', 'combo_3']));
      expect(Achievements.progress(Achievements.all.firstWhere((a) => a.id == 'combo_4'), p, book), 3);
    });
  });
}

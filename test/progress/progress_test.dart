import 'package:flutter_test/flutter_test.dart';
import 'package:harfblok/core/core.dart';
import 'package:harfblok/progress/calendar.dart';
import 'package:harfblok/progress/levels.dart';
import 'package:harfblok/progress/missions.dart';
import 'package:harfblok/progress/profile.dart';
import 'package:harfblok/progress/progression.dart';
import 'package:harfblok/progress/streak.dart';
import 'package:harfblok/progress/summaries.dart';
import 'package:harfblok/progress/wordbook.dart';

GameSummary _game({
  int score = 300,
  List<String> words = const ['KAR'],
  GameMode mode = GameMode.classic,
  bool powerups = false,
}) => GameSummary(
  mode: mode,
  score: score,
  moves: 20,
  duration: const Duration(minutes: 3),
  words: [for (final w in words) WordResult(w, w.length)],
  usedPowerups: powerups,
  bestStreak: 3,
  boardClears: 0,
  continued: false,
);

void main() {
  group('DayKey — Istanbul midnight (spec 7.2, 17)', () {
    test('20:59 UTC is still the same day in Istanbul, 21:00 UTC is the next', () {
      expect(DayKey.istanbul(DateTime.utc(2026, 11, 13, 20, 59)).toString(), '2026-11-13');
      expect(DayKey.istanbul(DateTime.utc(2026, 11, 13, 21, 0)).toString(), '2026-11-14');
    });
    test('year boundary', () {
      expect(DayKey.istanbul(DateTime.utc(2026, 12, 31, 21, 30)).toString(), '2027-01-01');
    });
    test('arithmetic and parsing', () {
      const d = DayKey(2026, 2, 28);
      expect(d.addDays(1).toString(), '2026-03-01');
      expect(d.daysUntil(const DayKey(2026, 3, 2)), 2);
      expect(DayKey.parse('2026-11-13'), const DayKey(2026, 11, 13));
      expect(const DayKey(2026, 11, 13).nextMidnightUtc, DateTime.utc(2026, 11, 13, 21));
    });
  });

  group('Levels (spec 8)', () {
    test('XP = score / 10; level N needs round(500 * N^1.5)', () {
      expect(Levels.xpForScore(1234), 123);
      expect(Levels.xpToNext(1), 500);
      expect(Levels.xpToNext(2), 1414);
      expect(Levels.xpToNext(4), 4000);
      expect(Levels.fromTotalXp(0).level, 1);
      expect(Levels.fromTotalXp(499).level, 1);
      expect(Levels.fromTotalXp(500).level, 2);
      expect(Levels.fromTotalXp(500 + 1414).level, 3);
    });
    test('rewards: themes, tile styles, powerups', () {
      expect(Levels.rewardFor(5).themeId, 'olive');
      expect(Levels.rewardFor(3).tileStyleId, 'soft');
      expect(Levels.rewardFor(2).powerup, isNotNull);
      expect(Levels.rewardFor(12).tileStyleId, 'grain');
      expect(Levels.rewardFor(20).tileStyleId, 'marble');
    });
    test('styles added later unlock for players already past their level', () {
      var xp = 0;
      for (var l = 1; l < 13; l++) {
        xp += Levels.xpToNext(l);
      }
      final p = PlayerProfile(totalXp: xp); // level 13, saved before 'grain' existed
      expect(p.unlockedTileStyles, {'classic'});
      expect(Progression.syncLevelUnlocks(p), isTrue);
      expect(p.unlockedTileStyles, containsAll(['soft', 'sharp', 'grain']));
      expect(p.unlockedTileStyles, isNot(contains('marble')));
      expect(Progression.syncLevelUnlocks(p), isFalse);
    });
  });

  group('DailyStreak (spec 8)', () {
    const d1 = DayKey(2026, 11, 1);
    test('consecutive days grow; same day is idempotent', () {
      var s = const DailyStreak().complete(d1).streak;
      expect(s.current, 1);
      s = s.complete(d1.addDays(1)).streak;
      expect(s.current, 2);
      expect(s.complete(d1.addDays(1)).streak.current, 2);
    });
    test('one missed day uses the monthly shield once', () {
      var s = const DailyStreak().complete(d1).streak.complete(d1.addDays(1)).streak;
      final r = s.complete(d1.addDays(3));
      expect(r.shieldUsed, isTrue);
      expect(r.streak.current, 3);
      s = r.streak;
      final again = s.complete(d1.addDays(5));
      expect(again.shieldUsed, isFalse);
      expect(again.streak.current, 1);
    });
    test('shield is available again next month', () {
      final s = DailyStreak(current: 5, best: 5, lastPlayed: const DayKey(2026, 11, 30), shieldMonthUsed: '2026-11');
      final r = s.complete(const DayKey(2026, 12, 2));
      expect(r.shieldUsed, isTrue);
      expect(r.streak.current, 6);
    });
    test('milestones 7 / 30 / 100 are reported once', () {
      var s = DailyStreak(current: 6, best: 6, lastPlayed: d1);
      final r = s.complete(d1.addDays(1));
      expect(r.reached, [7]);
      s = r.streak;
      expect(s.complete(d1.addDays(2)).reached, isEmpty);
    });
    test('displayed value drops to 0 after the streak breaks', () {
      final s = DailyStreak(current: 4, best: 4, lastPlayed: d1, shieldMonthUsed: '2026-11');
      expect(s.displayed(d1.addDays(1)), 4);
      expect(s.displayed(d1.addDays(2)), 0);
    });
  });

  group('Missions (spec 8)', () {
    test('three per day, one per tier, deterministic', () {
      final a = MissionPool.forDay(const DayKey(2026, 11, 13));
      final b = MissionPool.forDay(const DayKey(2026, 11, 13));
      expect(a.map((m) => m.tier), [MissionTier.easy, MissionTier.medium, MissionTier.hard]);
      expect(a.map((m) => m.toJson()).toList(), b.map((m) => m.toJson()).toList());
    });
    test('move-based progress', () {
      const m = Mission(type: MissionType.wordsOfLength, tier: MissionTier.easy, target: 2, length: 4);
      final move = MoveSummary(
        words: const [WordResult('KARE', 6), WordResult('KAR', 3)],
        placedCells: 1,
        streakAfter: 1,
        clearedBoard: false,
      );
      final after = MissionPool.applyMove(m, move);
      expect(after.progress, 1);
      expect(MissionPool.applyMove(after, move).done, isTrue);
    });
    test('letter and combo missions', () {
      const letter = Mission(type: MissionType.wordWithLetter, tier: MissionTier.easy, target: 3, letter: 'R');
      const combo = Mission(type: MissionType.comboTwo, tier: MissionTier.easy, target: 1);
      final move = MoveSummary(
        words: const [WordResult('KAR', 3), WordResult('NAR', 3)],
        placedCells: 1,
        streakAfter: 1,
        clearedBoard: false,
      );
      expect(MissionPool.applyMove(letter, move).progress, 2);
      expect(MissionPool.applyMove(combo, move).done, isTrue);
    });
    test('game-based progress keeps the best game', () {
      const m = Mission(type: MissionType.scoreNoPowerups, tier: MissionTier.hard, target: 700);
      expect(MissionPool.applyGame(m, _game(score: 800, powerups: true)).progress, 0);
      expect(MissionPool.applyGame(m, _game(score: 800)).done, isTrue);
    });
  });

  group('Progression.applyGameEnd', () {
    test('records stats, wordbook, XP and new record', () {
      final p = PlayerProfile();
      final book = Wordbook();
      const day = DayKey(2026, 11, 13);
      final r = Progression.applyGameEnd(p, book, _game(score: 520, words: ['KAR', 'KAR', 'ELMA']), day);
      expect(r.newRecord, isTrue);
      expect(r.xpGained, 52);
      expect(r.newWords, 2);
      expect(p.totalGames, 1);
      expect(p.totalWords, 3);
      expect(book.entries['KAR']!.count, 2);
      expect(book.mostBuilt, 'KAR');
      expect(book.longest, 'ELMA');
    });

    test('daily completion updates streak and result once', () {
      final p = PlayerProfile();
      const day = DayKey(2026, 11, 13);
      final r = Progression.applyGameEnd(p, Wordbook(), _game(mode: GameMode.daily, score: 200), day);
      expect(r.dailyResult!.score, 200);
      expect(p.streak.current, 1);
      expect(r.newRecord, isFalse, reason: 'daily never sets the classic record');
      final again = Progression.applyGameEnd(p, Wordbook(), _game(mode: GameMode.daily, score: 999), day);
      expect(again.dailyResult, isNull);
      expect(p.dailyFor(day)!.score, 200);
    });

    test('mission completion grants powerup + XP', () {
      final p = PlayerProfile();
      const day = DayKey(2026, 11, 13);
      Progression.ensureMissions(p, day);
      p.missions = [const Mission(type: MissionType.scoreInGame, tier: MissionTier.medium, target: 100)];
      final before = p.powerups[PowerupType.joker]!;
      final r = Progression.applyGameEnd(p, Wordbook(), _game(score: 150), day);
      expect(r.rewards.whereType<MissionReward>(), hasLength(1));
      expect(p.powerups[PowerupType.joker], before + 1);
      expect(p.totalXp, 15 + 80);
    });

    test('interstitial policy (spec 12)', () {
      final p = PlayerProfile()..sessions = 2;
      bool show(GameMode m) => Progression.shouldShowInterstitial(p, m, everyGames: 3, freeSessions: 3);
      expect(show(GameMode.classic), isFalse, reason: 'first 3 sessions are ad-free');
      p.sessions = 4;
      p.gamesSinceInterstitial = 1;
      expect(show(GameMode.classic), isFalse);
      p.gamesSinceInterstitial = 2;
      expect(show(GameMode.classic), isTrue);
      expect(show(GameMode.daily), isFalse, reason: 'never after the daily puzzle');
      p.adsRemoved = true;
      expect(show(GameMode.classic), isFalse);
    });
  });

  group('Persistence', () {
    test('profile, settings and wordbook JSON round-trip', () {
      final p = PlayerProfile()
        ..totalXp = 1234
        ..adsRemoved = true
        ..badges.add('streak_7')
        ..unlockedThemes.add('dawn');
      Progression.ensureMissions(p, const DayKey(2026, 11, 13));
      final p2 = PlayerProfile.fromJson(p.toJson());
      expect(p2.toJson(), p.toJson());

      const s = AppSettings(sound: false, themeMode: AppThemeMode.dark, colorBlind: true);
      expect(AppSettings.fromJson(s.toJson()).toJson(), s.toJson());

      final w = Wordbook()..add('KAR', 3, const DayKey(2026, 11, 13));
      expect(Wordbook.fromJson(w.toJson()).toJson(), w.toJson());
    });
    test('old profile without version loads with defaults (migration)', () {
      final p = PlayerProfile.fromJson({'xp': 10});
      expect(p.totalXp, 10);
      expect(p.unlockedThemes, contains('classic'));
      expect(p.powerups[PowerupType.hammer], 1);
    });
    test('future profile version is rejected', () {
      expect(() => PlayerProfile.fromJson({'v': 99}), throwsFormatException);
    });
  });
}

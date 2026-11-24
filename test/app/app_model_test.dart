// App-level flows that cross the profile, the saved game and the services:
// inventory while a classic game is running, and the rewarded extras.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harfblok/app/app_model.dart';
import 'package:harfblok/config/app_info.dart';
import 'package:harfblok/core/core.dart';
import 'package:harfblok/data/repositories.dart';
import 'package:harfblok/data/storage/json_store.dart';
import 'package:harfblok/data/storage/storage_backend.dart';
import 'package:harfblok/progress/calendar.dart';
import 'package:harfblok/progress/missions.dart';
import 'package:harfblok/progress/streak.dart';
import 'package:harfblok/progress/summaries.dart';
import 'package:harfblok/services/ads_service.dart';
import 'package:harfblok/services/analytics.dart';
import 'package:harfblok/services/audio_service.dart';
import 'package:harfblok/services/consent_service.dart';
import 'package:harfblok/services/crash_reporter.dart';
import 'package:harfblok/services/haptics_service.dart';
import 'package:harfblok/services/notification_service.dart';
import 'package:harfblok/services/purchase_service.dart';

// Tuesday 24 November 2026, noon in Istanbul.
final _now = DateTime.utc(2026, 11, 24, 9);

class _Rig {
  _Rig(this.model, this.ads, this.purchases, this.store);
  final AppModel model;
  final FakeAdsService ads;
  final FakePurchaseService purchases;
  final JsonStore store;
}

Future<_Rig> _rig() async {
  const crash = ConsoleCrashReporter();
  final store = JsonStore(MemoryBackend(), crash: crash);
  final ads = FakeAdsService();
  final purchases = FakePurchaseService();
  final m = AppModel(
    AppServices(
      games: GameRepository(store),
      profiles: ProfileRepository(store),
      audio: SilentAudioService(),
      haptics: NoHaptics(),
      analytics: MemoryAnalytics(),
      crash: crash,
      ads: ads,
      purchases: purchases,
      notifications: NoopNotifications(),
      consent: NoConsentNeeded(),
    ),
    clock: () => _now,
  );
  await m.init(rootBundle);
  return _Rig(m, ads, purchases, store);
}

/// Plays the first legal placement and saves, like the game screen does.
Future<GameState> _playOneMove(AppModel m) async {
  final s = m.savedClassic!;
  for (var p = 0; p < s.hand.length; p++) {
    final piece = s.hand[p];
    if (piece == null) continue;
    final pos = Placement.positions(s.grid, piece.shape);
    if (pos.isEmpty) continue;
    final next = m.engine!.apply(s, PlaceAction(p, pos.first.x, pos.first.y)).state;
    await m.saveGame(next, null);
    return next;
  }
  fail('no legal move');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('inventory while a classic game is in progress', () {
    test('powerups added from outside the game survive the next move and a replay', () async {
      final r = await _rig();
      final m = r.model;
      m.newClassicGame();
      expect(m.savedClassic!.powerup(PowerupType.hammer), 1);

      // Store reward / gift while the game is paused on the home screen.
      m.addPowerup(PowerupType.hammer, 5);
      expect(m.profile.powerups[PowerupType.hammer], 6);
      expect(m.savedClassic!.powerup(PowerupType.hammer), 6, reason: 'usable in the running game');

      final next = await _playOneMove(m);
      expect(m.profile.powerups[PowerupType.hammer], 6, reason: 'the save must not roll the inventory back');
      expect(next.actions.whereType<GrantAction>(), hasLength(1));

      // The saved game explains its own counts: replay and JSON agree.
      final replayed = m.engine!.replay(
        seed: next.seed,
        mode: next.mode,
        startedAt: next.startedAt,
        initialPowerups: next.initialPowerups,
        actions: next.actions,
      );
      expect(replayed.powerup(PowerupType.hammer), 6);
      final loaded = await r.store.read('game_classic', GameState.fromJson);
      expect(loaded!.powerup(PowerupType.hammer), 6);
      expect(m.summarize(next).moves, 1);
    });

    test('a purchased pack reaches the running game', () async {
      final r = await _rig();
      final m = r.model;
      m.newClassicGame();
      await r.purchases.buy(AppInfo.productPowerupsSmall);
      await Future<void>.delayed(Duration.zero);
      for (final t in PowerupType.values) {
        expect(m.profile.powerups[t], 1 + AppInfo.powerupsSmallAmount, reason: t.name);
        expect(m.savedClassic!.powerup(t), 1 + AppInfo.powerupsSmallAmount, reason: t.name);
      }
      await _playOneMove(m);
      for (final t in PowerupType.values) {
        expect(m.profile.powerups[t], 1 + AppInfo.powerupsSmallAmount, reason: 'after a move: ${t.name}');
      }
    });

    test('a mission reward earned mid-game is kept', () async {
      final r = await _rig();
      final m = r.model;
      m.newClassicGame();
      m.profile
        ..missionsDay = m.today.toString()
        ..missions = [
          const Mission(type: MissionType.wordsOfLength, tier: MissionTier.easy, target: 1, length: 3),
        ];
      final before = m.profile.powerups[PowerupType.refresh]!;
      final rec = m.recordMove(
        const MoveSummary(words: [WordResult('KAR', 3)], placedCells: 3, streakAfter: 1, clearedBoard: false),
      );
      expect(rec.missions, hasLength(1));
      expect(m.profile.powerups[PowerupType.refresh], before + 1);
      expect(m.savedClassic!.powerup(PowerupType.refresh), before + 1);
      await _playOneMove(m);
      expect(m.profile.powerups[PowerupType.refresh], before + 1);
    });

    test('without a running game the inventory is simply added to', () async {
      final r = await _rig();
      final m = r.model;
      expect(m.savedClassic, isNull);
      m.addPowerup(PowerupType.joker, 2);
      expect(m.profile.powerups[PowerupType.joker], 3);
      expect(m.newClassicGame().powerup(PowerupType.joker), 3);
    });
  });

  group('rewarded extras', () {
    test('daily gift: free once a day, a second one for an ad', () async {
      final r = await _rig();
      final m = r.model;
      expect(m.dailyGiftAvailable, isTrue);
      final t = m.dailyGiftType;
      final before = m.profile.powerups[t]!;
      expect(m.openDailyGift(), t);
      expect(r.ads.rewardedShown, 0, reason: 'opening is free');
      expect(m.profile.powerups[t], before + 1);
      expect(m.dailyGiftAvailable, isFalse);
      expect(m.openDailyGift(), isNull);
      expect(await m.doubleDailyGift(t), isTrue);
      expect(r.ads.rewardedShown, 1);
      expect(m.profile.powerups[t], before + 2);
    });

    test('the gift comes back the next day and rotates through the powerups', () async {
      final r = await _rig();
      final seen = {for (var d = 0; d < 3; d++) PowerupType.values[DayKey.istanbul(_now).addDays(d).dayIndex % 3]};
      expect(seen, PowerupType.values.toSet());
      r.model.openDailyGift();
      expect(r.model.profile.giftDay, r.model.today.toString());
    });

    test('streak repair: one ad brings a just-lost streak back; today continues it', () async {
      final r = await _rig();
      final m = r.model;
      final today = m.today;
      // Played up to three days ago; this month's shield is already spent.
      m.profile.streak = DailyStreak(
        current: 9,
        best: 9,
        lastPlayed: today.addDays(-3),
        shieldMonthUsed: today.monthKey,
      );
      expect(m.profile.streak.displayed(today), 0);
      expect(m.repairableStreak, 9);
      expect(await m.repairStreak(), isTrue);
      expect(r.ads.rewardedShown, 1);
      expect(m.profile.streak.displayed(today), 9);
      expect(m.repairableStreak, 0);
      final done = m.profile.streak.complete(today);
      expect(done.streak.current, 10);
      // Once a week at most.
      final lostAgain = DailyStreak(
        current: 10,
        best: 10,
        lastPlayed: today.addDays(-3),
        shieldMonthUsed: today.monthKey,
        repairWeek: done.streak.repairWeek,
      );
      expect(lostAgain.repairable(today), 0);
      expect(lostAgain.repairable(today.addDays(7)), 0, reason: 'too old by then');
    });

    test('streak repair is not offered for short, intact or long-gone streaks', () {
      final today = DayKey.istanbul(_now);
      DailyStreak s(int current, int daysAgo) =>
          DailyStreak(current: current, best: current, lastPlayed: today.addDays(-daysAgo), shieldMonthUsed: today.monthKey);
      expect(s(2, 3).repairable(today), 0, reason: 'too short to be worth an ad');
      expect(s(9, 1).repairable(today), 0, reason: 'not broken');
      expect(s(9, 2).repairable(today), 9, reason: 'missed yesterday, shield spent');
      expect(s(9, DailyStreak.repairMaxGap).repairable(today), 9);
      expect(s(9, DailyStreak.repairMaxGap + 1).repairable(today), 0);
      // With the monthly shield still available a single missed day is covered for free.
      expect(DailyStreak(current: 9, best: 9, lastPlayed: today.addDays(-2)).repairable(today), 0);
    });

    test('bonus XP levels up and its powerup reaches the running game', () async {
      final r = await _rig();
      final m = r.model;
      m.newClassicGame();
      final before = Map.of(m.profile.powerups);
      final ups = m.grantBonusXp(400); // level 1 -> 2, whose reward is a powerup
      expect(ups.map((u) => u.level), [2]);
      final t = ups.single.reward.powerup!;
      expect(m.profile.powerups[t], before[t]! + 1);
      expect(m.savedClassic!.powerup(t), before[t]! + 1);
    });
  });
}

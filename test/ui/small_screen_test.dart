// Layout guard: the busiest screens must fit a small phone with the largest
// text size the app allows (elle_test_listesi: 360 dp wide, scale 1.35).
// A RenderFlex overflow is an exception in tests, so pumping is the check.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harfblok/app/app.dart';
import 'package:harfblok/app/app_model.dart';
import 'package:harfblok/core/core.dart';
import 'package:harfblok/data/repositories.dart';
import 'package:harfblok/data/storage/json_store.dart';
import 'package:harfblok/data/storage/storage_backend.dart';
import 'package:harfblok/progress/streak.dart';
import 'package:harfblok/services/ads_service.dart';
import 'package:harfblok/services/analytics.dart';
import 'package:harfblok/services/audio_service.dart';
import 'package:harfblok/services/consent_service.dart';
import 'package:harfblok/services/crash_reporter.dart';
import 'package:harfblok/services/haptics_service.dart';
import 'package:harfblok/services/notification_service.dart';
import 'package:harfblok/services/purchase_service.dart';
import 'package:harfblok/ui/components/app_icon.dart';
import 'package:harfblok/ui/game/game_controller.dart';
import 'package:harfblok/ui/screens/daily_screen.dart';
import 'package:harfblok/ui/screens/game_screen.dart';
import 'package:harfblok/ui/screens/missions_screen.dart';
import 'package:harfblok/ui/screens/settings_screen.dart';
import 'package:harfblok/ui/screens/store_screen.dart';
import 'package:harfblok/ui/screens/wordbook_stats_screens.dart';
import 'package:material_ui/material_ui.dart';

final _now = DateTime.utc(2026, 11, 24, 9);

Future<AppModel> _model() async {
  const crash = ConsoleCrashReporter();
  final store = JsonStore(MemoryBackend(), crash: crash);
  final m = AppModel(
    AppServices(
      games: GameRepository(store),
      profiles: ProfileRepository(store),
      audio: SilentAudioService(),
      haptics: NoHaptics(),
      analytics: MemoryAnalytics(),
      crash: crash,
      ads: FakeAdsService(),
      purchases: FakePurchaseService(),
      notifications: NoopNotifications(),
      consent: NoConsentNeeded(),
    ),
    clock: () => _now,
  );
  await m.init(rootBundle);
  m.profile
    ..tutorialDone = true
    ..introSeen = true
    // A best score so the game-over sheet shows its record / next-goal lines.
    ..bestScore = 120;
  return m;
}

/// Plays a classic game to the end with a greedy bot.
GameState _finishedGame(AppModel m) {
  final e = m.engine!;
  var s = e.newGame(seed: 7, mode: GameMode.classic, startedAt: _now, powerups: Map.of(m.profile.powerups));
  while (!s.isOver) {
    PlaceAction? best;
    var bs = -1;
    for (var p = 0; p < 3; p++) {
      final piece = s.hand[p];
      if (piece == null) continue;
      for (final pos in Placement.positions(s.grid, piece.shape)) {
        final v = e.preview(s, p, pos.x, pos.y)!.score.total;
        if (v > bs) {
          bs = v;
          best = PlaceAction(p, pos.x, pos.y);
        }
      }
    }
    if (best == null) {
      s = e.apply(s, const EndAction()).state;
      break;
    }
    s = e.apply(s, best).state;
  }
  return s;
}

void main() {
  setUpAll(() async {
    // The shipped typeface: the test font's square glyphs would overflow on their own.
    final loader = FontLoader('AppFont');
    for (final f in Directory('assets/fonts').listSync().whereType<File>().where((f) => f.path.endsWith('.ttf'))) {
      loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
    await loader.load();
    await AssetIndex.load();
    var fakeMs = 1e9;
    GameController.debugNow = () => fakeMs += 1000;
  });
  tearDownAll(() => GameController.debugNow = null);

  for (final size in const [Size(360, 640), Size(375, 667)]) {
    testWidgets('no overflow at ${size.width.round()}x${size.height.round()} with the largest text', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2; // the app clamps this to 1.35
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final m = (await tester.runAsync(_model))!;
      await tester.pumpWidget(HarfBlokApp(model: m, locale: const Locale('tr')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
      expect(tester.takeException(), isNull, reason: 'home');

      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      Future<void> open(Widget w, String name) async {
        nav.push(MaterialPageRoute<void>(builder: (_) => w));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(tester.takeException(), isNull, reason: name);
        nav.pop();
        await tester.pump(const Duration(milliseconds: 700));
      }

      // Daily gift sheet from the home chip.
      await tester.tap(find.text('Hediye'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
      expect(tester.takeException(), isNull, reason: 'gift sheet');
      nav.pop();
      await tester.pump(const Duration(milliseconds: 700));

      // Game over with a record, rewards, the 2x XP pill, next goal and "Devam Et".
      nav.push(GameScreen.route(_finishedGame(m)));
      await tester.pump();
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.text('2× XP'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'game over');
      nav.pop();
      await tester.pump(const Duration(milliseconds: 700));
      tester.takeException(); // leaving a finished game may show the fake interstitial path; not layout

      // A broken streak: the rewarded repair banner on the daily screen.
      m.profile.streak = DailyStreak(
        current: 9,
        best: 9,
        lastPlayed: m.today.addDays(-3),
        shieldMonthUsed: m.today.monthKey,
      );
      await open(const DailyScreen(), 'daily with streak repair');
      await open(const MissionsScreen(), 'missions');
      await open(const StatsScreen(), 'stats');
      await open(const SettingsScreen(), 'settings');
      await open(const StoreScreen(), 'store');
      m.dispose();
    });
  }
}

// Renders every main screen to PNG (docs/screenshots/) for visual review.
//
//   flutter test test_screens
//
// Not part of the default `flutter test` run (lives outside test/).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harfblok/app/app.dart';
import 'package:harfblok/app/app_model.dart';
import 'package:harfblok/core/core.dart';
import 'package:harfblok/data/repositories.dart';
import 'package:harfblok/data/storage/json_store.dart';
import 'package:harfblok/data/storage/storage_backend.dart';
import 'package:harfblok/progress/profile.dart';
import 'package:harfblok/progress/progression.dart';
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
import 'package:harfblok/config/asset_paths.dart';
import 'package:harfblok/ui/components/app_icon.dart';
import 'package:harfblok/ui/components/sprite_anim.dart';
import 'package:harfblok/ui/game/board_art.dart';
import 'package:harfblok/ui/game/fx_art.dart';
import 'package:harfblok/ui/game/game_controller.dart';
import 'package:harfblok/ui/game/tile_art.dart';
import 'package:harfblok/ui/screens/daily_screen.dart';
import 'package:harfblok/ui/screens/game_screen.dart';
import 'package:harfblok/ui/screens/intro_screen.dart';
import 'package:harfblok/ui/screens/missions_screen.dart';
import 'package:harfblok/ui/screens/settings_screen.dart';
import 'package:harfblok/ui/screens/store_screen.dart';
import 'package:harfblok/ui/screens/wordbook_stats_screens.dart';
import 'package:material_ui/material_ui.dart';

final _now = DateTime.utc(2026, 11, 13, 9, 30);
const _outDir = 'docs/screenshots';

Future<void> _loadFont() async {
  // Real glyphs instead of test boxes: a system font with Turkish coverage.
  for (final path in [
    '/System/Library/Fonts/Supplemental/Arial.ttf',
    '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
  ]) {
    final f = File(path);
    if (!f.existsSync()) continue;
    final loader = FontLoader('AppFont')..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    await loader.load();
  }
}

Future<AppModel> _model(Directory dir, {required bool dark}) async {
  const crash = ConsoleCrashReporter();
  final store = JsonStore(MemoryBackend(), crash: crash);
  final services = AppServices(
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
  );
  final m = AppModel(services, clock: () => _now);
  await m.init(rootBundle);
  m.settings = AppSettings(themeMode: dark ? AppThemeMode.dark : AppThemeMode.light);
  // Some history so screens are not empty.
  final today = m.today;
  m.profile.tutorialDone = true;
  m.profile.introSeen = true;
  for (var i = 1; i <= 9; i++) {
    final d = today.addDays(-i);
    m.profile.daily[d.toString()] = DailyResult(
      score: 150 + i * 23,
      words: 8 + i,
      longestLength: 4 + i % 3,
      streakAfter: 10 - i,
    );
  }
  m.profile.streak = m.profile.streak.complete(today.addDays(-2)).streak.complete(today.addDays(-1)).streak;
  for (final w in ['KAR', 'ELMA', 'KALEM', 'ARABA', 'NAR', 'TAŞ', 'KİTAP', 'DENİZ', 'SALI', 'ÇAY', 'İNEK', 'ERİK']) {
    m.wordbook.add(w, w.length * 2, today.addDays(-3));
  }
  Progression.applyGameEnd(
    m.profile,
    m.wordbook,
    GameSummary(
      mode: GameMode.classic,
      score: 640,
      moves: 70,
      duration: const Duration(minutes: 4),
      words: const [WordResult('KAR', 3), WordResult('ARABA', 14)],
      usedPowerups: false,
      bestStreak: 6,
      boardClears: 0,
      continued: false,
    ),
    today,
  );
  return m;
}

/// A mid-game classic state built by a greedy bot.
GameState _midGame(AppModel m, int moves) {
  final e = m.engine!;
  var s = e.newGame(seed: 42, mode: GameMode.classic, startedAt: _now, powerups: Map.of(m.profile.powerups));
  for (var i = 0; i < moves && !s.isOver; i++) {
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
      if (s.status == GameStatus.stuck) s = e.apply(s, const EndAction()).state;
      break;
    }
    s = e.apply(s, best).state;
  }
  return s;
}

// ignore_for_file: invalid_use_of_visible_for_testing_member
void main() {
  setUpAll(() async {
    // All entrance animations finished.
    var fakeMs = 1e9;
    GameController.debugNow = () => fakeMs += 1000;
    await _loadFont();
    await AssetIndex.load();
    await TileArt.load();
    await FxArt.load();
    await BoardArt.load();
    Directory(_outDir).createSync(recursive: true);
  });

  Future<void> shot(WidgetTester tester, GlobalKey key, String name) async {
    await tester.pump(const Duration(milliseconds: 1500));
    final images = find.byType(Image).evaluate();
    await tester.runAsync(() async {
      await Future.wait([
        for (final element in images)
          if ((element.widget as Image).image is AssetImage)
            precacheImage((element.widget as Image).image, element),
      ]);
    });
    await tester.pump();
    await tester.runAsync(() async {
      final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 2);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$_outDir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('screens $mode', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final dir = Directory.systemTemp.createTempSync('hb');
      final m = (await tester.runAsync(() => _model(dir, dark: dark)))!;
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: HarfBlokApp(model: m, locale: const Locale('tr')),
        ),
      );
      await tester.pump();
      await shot(tester, key, '01_home_$mode');

      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);

      // Daily gift: the chip on the home screen opens the sheet.
      await tester.tap(find.text('Hediye'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1400));
      await shot(tester, key, '14_daily_gift_$mode');
      nav.pop();
      await tester.pump(const Duration(milliseconds: 600));

      Future<void> open(Widget w, String name) async {
        nav.push(MaterialPageRoute(builder: (_) => w));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await shot(tester, key, name);
        nav.pop();
        await tester.pump(const Duration(milliseconds: 600));
      }

      final g = _midGame(m, 14);
      nav.push(GameScreen.route(g));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await shot(tester, key, '02_game_$mode');

      // Board sprite effects frozen mid-flight (tile pop, dust puff, hammer,
      // joker, combo) over the real board.
      final c = (tester.state(find.byType(GameScreen)) as dynamic).c as GameController;
      final geo = c.geometry!;
      final clock = GameController.debugNow;
      const t = 5e9;
      GameController.debugNow = () => t;
      c.boardFx
        ..add(BoardFx(FxArt.sheet(FxArt.tilePop)!, geo.cellRect(1, 5).center, geo.cell * 2.6, t - 200))
        ..add(BoardFx(FxArt.sheet(FxArt.hammer)!, geo.cellRect(6, 1).center, geo.cell * 3.2, t - 300))
        ..add(BoardFx(FxArt.sheet(FxArt.joker)!, geo.cellRect(3, 3).center, geo.cell * 3.0, t - 230));
      c.comboFx = ComboFx(3, Offset(geo.rect.width * 0.66, geo.rect.height * 0.80), t - 330);
      c.frame.value++;
      await shot(tester, key, '11_board_fx_$mode');
      c.boardFx.clear();
      c.comboFx = null;
      GameController.debugNow = clock;

      // Board surface styles (level rewards).
      m.profile.unlockedBoardStyles.addAll(BoardArt.styles);
      for (final id in BoardArt.styles.skip(1)) {
        await tester.runAsync(() => m.updateSettings(m.settings.copyWith(boardStyleId: id)));
        await tester.pump();
        await shot(tester, key, '12_board_${id}_$mode');
      }
      await tester.runAsync(() => m.updateSettings(m.settings.copyWith(boardStyleId: 'plain')));
      await tester.pump();
      nav.pop();
      await tester.pump(const Duration(milliseconds: 600));

      final over = _midGame(m, 400);
      nav.push(GameScreen.route(over));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await shot(tester, key, '03_game_over_$mode');
      nav.pop();
      await tester.pump(const Duration(milliseconds: 600));

      // First-run intro, pages 1 and 3.
      nav.push(IntroScreen.route(firstRun: true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await shot(tester, key, '00_intro1_$mode');
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pump(const Duration(milliseconds: 600));
      await shot(tester, key, '00_intro3_$mode');
      nav.pop();
      await tester.pump(const Duration(milliseconds: 600));

      await open(const DailyScreen(), '04_daily_$mode');

      // A streak lost three days ago (shield spent): the rewarded repair offer.
      final streak = m.profile.streak;
      m.profile.streak = DailyStreak(
        current: 9,
        best: 9,
        lastPlayed: m.today.addDays(-3),
        shieldMonthUsed: m.today.monthKey,
      );
      await open(const DailyScreen(), '13_streak_repair_$mode');
      m.profile.streak = streak;
      await open(const MissionsScreen(), '05_missions_$mode');
      await open(const WordbookScreen(), '06_wordbook_$mode');
      await open(const SettingsScreen(), '07_settings_$mode');
      await open(const StatsScreen(), '08_stats_$mode');
      await open(const StoreScreen(), '09_store_$mode');
      m.dispose();
    });
  }

  // Mid-flight frames of the celebration sprite sheets on the dark board colour.
  testWidgets('celebrations', (tester) async {
    tester.view.physicalSize = const Size(340 * 3 * 2, 340 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: const ColoredBox(
            color: Color(0xFF16203A),
            child: Row(
              children: [
                SpriteAnim(AssetPaths.fxBoardClear, size: 340),
                SpriteAnim(AssetPaths.fxNewRecord, size: 340),
                SpriteAnim(AssetPaths.fxLevelUp, size: 340),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1500)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 520));
    await tester.runAsync(() async {
      final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 2);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$_outDir/10_celebrations.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    await tester.pump(const Duration(seconds: 2));
  });

  // The real resolve timeline, stepped with a fake clock: a combo move, the
  // hammer and the joker, one PNG per step in build/fx_frames (not committed).
  // Lets the effects be judged in motion without a device.
  testWidgets('effect timelines', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('hb');
    final m = (await tester.runAsync(() => _model(dir, dark: false)))!;
    final out = Directory('build/fx_frames')..createSync(recursive: true);
    final clock = GameController.debugNow;
    var now = 7e9;
    GameController.debugNow = () => now;
    addTearDown(() => GameController.debugNow = clock);

    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: key, child: HarfBlokApp(model: m, locale: const Locale('tr'))));
    await tester.pump();
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    final (start, move) = _comboMove(m);
    nav.push(GameScreen.route(start));
    await tester.pump();
    now += 2000;
    await tester.pump(const Duration(seconds: 2));
    final c = (tester.state(find.byType(GameScreen)) as dynamic).c as GameController;

    Future<void> frames(String name, int count, int stepMs) async {
      for (var i = 0; i < count; i++) {
        await tester.runAsync(() async {
          final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final img = await b.toImage(pixelRatio: 1);
          final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
          File('${out.path}/${name}_${i.toString().padLeft(2, '0')}.png').writeAsBytesSync(bytes!.buffer.asUint8List());
        });
        now += stepMs;
        await tester.pump(Duration(milliseconds: stepMs));
      }
    }

    Future<void> settle() async {
      now += 3000;
      await tester.pump(const Duration(seconds: 3));
    }

    // 1. A placement that explodes two words at once.
    final first = start.hand[move.pieceIndex]!.shape.cells.first;
    c
      ..tapPiece(move.pieceIndex)
      ..tapCell(Grid.indexOf(move.x + first.dx, move.y + first.dy));
    await tester.pump();
    await frames('word', 18, 80);
    await settle();

    // 2. Hammer on a filled cell.
    final filled = [
      for (var i = 0; i < 64; i++)
        if (c.state.grid.isFilled(i)) i,
    ];
    if (filled.isNotEmpty && c.state.powerup(PowerupType.hammer) > 0) {
      c
        ..tapPowerup(PowerupType.hammer)
        ..tapCell(filled[filled.length ~/ 2]);
      await tester.pump();
      await frames('hammer', 12, 70);
      await settle();
    }

    // 3. Joker on an empty cell.
    final empty = [
      for (var i = 0; i < 64; i++)
        if (!c.state.grid.isFilled(i)) i,
    ];
    if (empty.isNotEmpty && c.state.powerup(PowerupType.joker) > 0) {
      // Straight to the letter choice: going through tapCell would open the picker sheet over the board.
      c
        ..jokerCell = empty[empty.length ~/ 2]
        ..chooseJokerLetter('A');
      await tester.pump();
      await frames('joker', 10, 70);
      await settle();
    }
    GameController.debugNow = clock;
    m.dispose();
  });
}

/// A classic position (reached by a greedy bot) and a placement in it that
/// explodes at least two words.
(GameState, PlaceAction) _comboMove(AppModel m) {
  final e = m.engine!;
  for (var seed = 1; seed < 400; seed++) {
    var s = e.newGame(seed: seed, mode: GameMode.classic, startedAt: _now, powerups: Map.of(m.profile.powerups));
    for (var i = 0; i < 60 && !s.isOver; i++) {
      PlaceAction? best;
      var bs = -1;
      for (var p = 0; p < 3; p++) {
        final piece = s.hand[p];
        if (piece == null) continue;
        for (final pos in Placement.positions(s.grid, piece.shape)) {
          final pv = e.preview(s, p, pos.x, pos.y)!;
          if (pv.hits.length >= 2) return (s, PlaceAction(p, pos.x, pos.y));
          if (pv.score.total > bs) {
            bs = pv.score.total;
            best = PlaceAction(p, pos.x, pos.y);
          }
        }
      }
      if (best == null) break;
      s = e.apply(s, best).state;
    }
  }
  throw StateError('no combo position found');
}

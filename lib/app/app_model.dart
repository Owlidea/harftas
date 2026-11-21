import 'dart:async';

import 'package:flutter/widgets.dart';

import '../config/app_info.dart';
import '../core/core.dart';
import '../data/dictionary/dictionary_loader.dart';
import '../data/repositories.dart';
import '../progress/calendar.dart';
import '../progress/missions.dart';
import '../progress/profile.dart';
import '../progress/progression.dart';
import '../progress/summaries.dart';
import '../progress/wordbook.dart';
import '../services/ads_service.dart';
import '../services/analytics.dart';
import '../services/audio_service.dart';
import '../services/consent_service.dart';
import '../services/crash_reporter.dart';
import '../services/haptics_service.dart';
import '../services/notification_service.dart';
import '../services/purchase_service.dart';

class AppServices {
  AppServices({
    required this.games,
    required this.profiles,
    required this.audio,
    required this.haptics,
    required this.analytics,
    required this.crash,
    required this.ads,
    required this.purchases,
    required this.notifications,
    required this.consent,
  });

  final GameRepository games;
  final ProfileRepository profiles;
  final AudioService audio;
  final HapticsService haptics;
  final Analytics analytics;
  final CrashReporter crash;
  final AdsService ads;
  final PurchaseService purchases;
  final NotificationService notifications;
  final ConsentService consent;
}

/// Texts needed for scheduling reminders (keeps l10n out of this class).
class ReminderTexts {
  const ReminderTexts({
    required this.dailyTitle,
    required this.dailyBody,
    required this.streakTitle,
    required this.streakBody,
  });
  final String dailyTitle;
  final String dailyBody;
  final String streakTitle;
  final String Function(int days) streakBody;
}

/// App-wide state: settings, profile, wordbook, dictionary, saved games.
class AppModel extends ChangeNotifier {
  AppModel(this.services, {DateTime Function()? clock}) : clock = clock ?? DateTime.now;

  final AppServices services;
  final DateTime Function() clock;

  AppSettings settings = const AppSettings();
  PlayerProfile profile = PlayerProfile();
  Wordbook wordbook = Wordbook();
  GameState? savedClassic;
  LoadedData? data;
  Object? loadError;
  GameEngine? engine;
  StreamSubscription<PurchaseGrant>? _purchaseSub;

  /// Games that ended while unrecorded (e.g. app closed on game-over) are
  /// recorded on next launch; their results are kept for one toast.
  GameEndResult? recoveredResult;

  /// True once settings/profile are read from storage.
  bool profileLoaded = false;

  DayKey get today => DayKey.istanbul(clock());
  bool get ready => engine != null;

  Future<void> init(AssetBundle bundle) async {
    settings = await services.profiles.loadSettings();
    profile = await services.profiles.loadProfile();
    wordbook = await services.profiles.loadWordbook();
    profile.sessions++;
    Progression.ensureMissions(profile, today);
    await services.profiles.saveProfile(profile);
    profileLoaded = true;
    _applySettings();
    notifyListeners();
    services.analytics.log(AnalyticsEvent.appOpen, {'session': profile.sessions});

    _purchaseSub = services.purchases.grants.listen(_onPurchase);
    unawaited(services.purchases.init());
    unawaited(services.audio.init().then((_) => _applySettings()));
    unawaited(services.notifications.init());
    unawaited(_initAds());
    await loadData(bundle);
  }

  Future<void> _initAds() async {
    try {
      final allowed = await services.consent.gather();
      if (allowed) await services.ads.init();
    } on Object catch (e, st) {
      services.crash.record(e, st, reason: 'consent/ads');
    }
  }

  Future<void> loadData(AssetBundle bundle) async {
    loadError = null;
    notifyListeners();
    try {
      final d = await DataLoader.load(bundle);
      data = d;
      engine = GameEngine(config: d.config, dictionary: d.words, common: d.common);
      final saved = await services.games.loadClassic();
      if (saved != null && saved.isOver) {
        recoveredResult = await recordGameEnd(saved);
        await services.games.clearClassic();
      } else {
        savedClassic = saved == null ? null : engine!.revalidate(saved);
      }
    } on Object catch (e, st) {
      loadError = e;
      services.crash.record(e, st, reason: 'data load');
    }
    notifyListeners();
  }

  // ------------------------------------------------------------ settings

  Future<void> updateSettings(AppSettings s, {String? key}) async {
    settings = s;
    _applySettings();
    notifyListeners();
    await services.profiles.saveSettings(s);
    if (key != null) services.analytics.log(AnalyticsEvent.settingsChanged, {'key': key});
  }

  void _applySettings() {
    services.audio
      ..soundEnabled = settings.sound
      ..musicEnabled = settings.music;
    services.haptics.enabled = settings.haptics;
  }

  // ------------------------------------------------------------- profile

  Future<void> saveProfile() async {
    notifyListeners();
    await services.profiles.saveProfile(profile);
  }

  void _onPurchase(PurchaseGrant g) {
    switch (g.productId) {
      case AppInfo.productRemoveAds:
        profile.adsRemoved = true;
      case AppInfo.productPowerupsSmall:
        _addAllPowerups(AppInfo.powerupsSmallAmount);
      case AppInfo.productPowerupsLarge:
        _addAllPowerups(AppInfo.powerupsLargeAmount);
    }
    if (!g.restored) services.analytics.log(AnalyticsEvent.purchase, {'product': g.productId});
    unawaited(saveProfile());
  }

  void _addAllPowerups(int n) {
    for (final t in PowerupType.values) {
      profile.powerups[t] = (profile.powerups[t] ?? 0) + n;
    }
  }

  void addPowerup(PowerupType t, [int n = 1]) {
    profile.powerups[t] = (profile.powerups[t] ?? 0) + n;
    unawaited(saveProfile());
  }

  /// Rewarded ad (or free when ads are removed). Returns true on reward.
  Future<bool> watchRewarded(RewardPlacement placement) async {
    if (profile.adsRemoved) return true;
    final ok = await services.ads.showRewarded(placement);
    services.analytics.log(AnalyticsEvent.adShown, {'type': 'rewarded', 'placement': placement.name});
    if (ok) services.analytics.log(AnalyticsEvent.adRewarded, {'placement': placement.name});
    return ok;
  }

  /// Spec 12 interstitial policy; call when leaving a finished game.
  Future<void> maybeInterstitial(GameMode mode) async {
    if (mode == GameMode.daily) return;
    if (Progression.shouldShowInterstitial(
      profile,
      mode,
      everyGames: AdConfig.interstitialEveryGames,
      freeSessions: AdConfig.interstitialFreeSessions,
    )) {
      profile.gamesSinceInterstitial = 0;
      unawaited(saveProfile());
      services.analytics.log(AnalyticsEvent.adShown, {'type': 'interstitial'});
      await services.ads.showInterstitial();
    } else {
      profile.gamesSinceInterstitial++;
      unawaited(saveProfile());
    }
  }

  // --------------------------------------------------------------- games

  /// Starts a classic game. Inventory powerups are moved into the game.
  GameState newClassicGame() {
    final e = engine!;
    final seed = Rng.mix(clock().microsecondsSinceEpoch & 0x7FFFFFFF, profile.totalGames);
    final s = e.newGame(seed: seed, mode: GameMode.classic, startedAt: clock(), powerups: Map.of(profile.powerups));
    savedClassic = s;
    services.analytics.log(AnalyticsEvent.gameStart, {'mode': 'classic'});
    unawaited(services.games.saveClassic(s));
    return s;
  }

  Future<GameState> dailyGame() async {
    final e = engine!;
    final d = today;
    final saved = await services.games.loadDaily(d);
    if (saved != null) return e.revalidate(saved);
    final s = e.newGame(seed: Rng.dailySeed(d.year, d.month, d.day), mode: GameMode.daily, startedAt: clock());
    services.analytics.log(AnalyticsEvent.gameStart, {'mode': 'daily'});
    await services.games.saveDaily(d, s);
    return s;
  }

  bool get dailyDoneToday => profile.dailyFor(today) != null;

  /// Persists an in-progress game and syncs the classic powerup inventory.
  Future<void> saveGame(GameState s, DayKey? dailyDay) async {
    if (s.mode == GameMode.classic) {
      savedClassic = s.isOver ? null : s;
      for (final t in PowerupType.values) {
        profile.powerups[t] = s.powerup(t);
      }
      unawaited(services.profiles.saveProfile(profile));
    }
    await services.games.save(s, dailyDay);
  }

  /// Missions progress after each action.
  ({List<Mission> missions, List<LevelUpReward> levelUps}) recordMove(MoveSummary m) {
    final r = Progression.applyMove(profile, m, today);
    for (final mission in r.missions) {
      services.analytics.log(AnalyticsEvent.missionCompleted, {'id': mission.type.name, 'tier': mission.tier.name});
    }
    for (final l in r.levelUps) {
      services.analytics.log(AnalyticsEvent.levelUp, {'level': l.level});
    }
    if (r.missions.isNotEmpty || r.levelUps.isNotEmpty) unawaited(saveProfile());
    return r;
  }

  /// Replays a finished game to build its summary (exact, also for games
  /// resumed from storage).
  GameSummary summarize(GameState s) {
    final e = engine!;
    var st = e.newGame(seed: s.seed, mode: s.mode, startedAt: s.startedAt, powerups: s.initialPowerups);
    final words = <WordResult>[];
    var usedPowerups = false;
    var clears = 0;
    for (final a in s.actions) {
      final r = e.apply(st, a);
      final m = MoveSummary.fromEvents(a, r.events);
      words.addAll(m.words);
      if (m.powerup != null) usedPowerups = true;
      if (m.clearedBoard) clears++;
      st = r.state;
    }
    var duration = clock().difference(s.startedAt);
    if (duration.isNegative || duration > const Duration(hours: 3)) duration = Duration.zero;
    return GameSummary(
      mode: s.mode,
      score: s.score,
      moves: s.actions.whereType<PlaceAction>().length,
      duration: duration,
      words: words,
      usedPowerups: usedPowerups,
      bestStreak: s.bestStreak,
      boardClears: clears,
      continued: s.continueUsed,
    );
  }

  /// What [recordGameEnd] would award, without changing anything.
  GameEndResult previewGameEnd(GameState s) {
    final p = PlayerProfile.fromJson(profile.toJson());
    final w = Wordbook.fromJson(wordbook.toJson());
    return Progression.applyGameEnd(p, w, summarize(s), today);
  }

  Future<GameEndResult> recordGameEnd(GameState s) async {
    final g = summarize(s);
    final r = Progression.applyGameEnd(profile, wordbook, g, today);
    services.analytics.log(AnalyticsEvent.gameOver, {
      'mode': g.mode.name,
      'score': g.score,
      'moves': g.moves,
      'duration': g.duration.inSeconds,
      'words': g.wordCount,
      'longest': g.longestLength,
    });
    if (r.dailyResult != null) {
      services.analytics.log(AnalyticsEvent.dailyCompleted, {'score': g.score, 'streak': profile.streak.current});
    }
    for (final reward in r.rewards) {
      if (reward is LevelUpReward) services.analytics.log(AnalyticsEvent.levelUp, {'level': reward.level});
    }
    if (s.mode == GameMode.classic) {
      savedClassic = null;
      await services.games.clearClassic();
    }
    await services.profiles.saveWordbook(wordbook);
    await saveProfile();
    return r;
  }

  // ------------------------------------------------------- notifications

  Future<bool> enableNotifications(ReminderTexts texts) async {
    profile.notificationAsked = true;
    unawaited(saveProfile());
    final granted = await services.notifications.requestPermission();
    await updateSettings(settings.copyWith(notifications: granted), key: 'notifications');
    if (granted) await rescheduleReminder(texts);
    return granted;
  }

  /// At most one reminder per day (spec 8): "streak at risk" this evening if
  /// today's daily is not done, otherwise "new puzzle" tomorrow morning.
  Future<void> rescheduleReminder(ReminderTexts t) async {
    if (!settings.notifications) {
      await services.notifications.cancelAll();
      return;
    }
    final now = clock().toUtc();
    final d = today;
    final eveningUtc = DateTime.utc(d.year, d.month, d.day, 20).subtract(DayKey.istanbulOffset);
    final shown = profile.streak.displayed(d);
    if (!dailyDoneToday && shown > 0 && eveningUtc.isAfter(now)) {
      await services.notifications.scheduleOnce(atUtc: eveningUtc, title: t.streakTitle, body: t.streakBody(shown));
    } else {
      final tomorrow = d.addDays(1);
      final morningUtc = DateTime.utc(tomorrow.year, tomorrow.month, tomorrow.day, 9).subtract(DayKey.istanbulOffset);
      await services.notifications.scheduleOnce(atUtc: morningUtc, title: t.dailyTitle, body: t.dailyBody);
    }
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    services.audio.dispose();
    super.dispose();
  }
}

/// Lets widgets reach the [AppModel].
class AppScope extends InheritedNotifier<AppModel> {
  const AppScope({super.key, required AppModel model, required super.child}) : super(notifier: model);

  static AppModel of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  static AppModel read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

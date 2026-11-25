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
  GameState? savedClassic;
  Object? loadError;
  StreamSubscription<PurchaseGrant>? _purchaseSub;

  // Per word language (karar 29), loaded on first use.
  final Map<String, LoadedData> _data = {};
  final Map<String, GameEngine> _engines = {};
  final Map<String, Wordbook> _wordbooks = {};
  AssetBundle? _bundle;

  /// Language of new games and of the daily puzzle, Kelime Defteri and
  /// records shown. Players from before karar 29 have none set: Turkish.
  WordLanguage get wordLanguage => WordLanguage.byCode(settings.wordLanguage) ?? WordLanguage.turkish;

  /// Data and engine of [wordLanguage] (null while loading).
  LoadedData? get data => _data[wordLanguage.code];
  GameEngine? get engine => _engines[wordLanguage.code];

  /// A game is always played by the engine of its own language.
  GameEngine? engineFor(String language) => _engines[language];
  LoadedData? dataFor(String language) => _data[language];

  /// Kelime Defteri of [wordLanguage].
  Wordbook get wordbook => wordbookFor(wordLanguage.code);
  Wordbook wordbookFor(String language) => _wordbooks.putIfAbsent(language, Wordbook.new);

  /// Word language to suggest on first start: Turkish in Turkey or on a
  /// Turkish device, else the device language when it is playable, else
  /// English.
  static WordLanguage suggestedLanguage(Locale locale) {
    if (locale.countryCode == 'TR' || locale.languageCode == 'tr') return WordLanguage.turkish;
    return WordLanguage.byCode(locale.languageCode) ?? WordLanguage.english;
  }

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
    Progression.syncLevelUnlocks(profile);
    _wordbooks[wordLanguage.code] = await services.profiles.loadWordbook(wordLanguage.code);
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
    _bundle = bundle;
    loadError = null;
    notifyListeners();
    try {
      await _ensureLanguage(wordLanguage);
      // The saved classic game may be in another language than new games.
      final saved = await services.games.loadClassic();
      final savedLanguage = WordLanguage.byCode(saved?.language);
      if (saved == null) {
        savedClassic = null;
      } else if (savedLanguage == null) {
        await services.games.clearClassic(); // a language this version cannot play
      } else {
        final e = await _ensureLanguage(savedLanguage);
        if (saved.isOver) {
          recoveredResult = await recordGameEnd(saved);
          await services.games.clearClassic();
        } else {
          savedClassic = e.revalidate(saved);
        }
      }
    } on Object catch (e, st) {
      loadError = e;
      services.crash.record(e, st, reason: 'data load');
    }
    notifyListeners();
  }

  /// Loads the dictionaries, engine and Kelime Defteri of [language] once.
  Future<GameEngine> _ensureLanguage(WordLanguage language) async {
    final have = _engines[language.code];
    if (have != null) return have;
    final d = await DataLoader.load(_bundle!, language);
    _wordbooks[language.code] ??= await services.profiles.loadWordbook(language.code);
    _data[language.code] = d;
    return _engines[language.code] = GameEngine(config: d.config, dictionary: d.words, common: d.common);
  }

  /// Switches the language of new games, the daily puzzle and the Kelime
  /// Defteri shown. A classic game in progress keeps its own language.
  Future<void> setWordLanguage(WordLanguage language) async {
    if (language == wordLanguage && settings.wordLanguage != null) return;
    await updateSettings(settings.copyWith(wordLanguage: language.code), key: 'wordLanguage');
    if (_bundle == null) return; // init() has not loaded data yet; it will
    try {
      await _ensureLanguage(language);
    } on Object catch (e, st) {
      loadError = e;
      services.crash.record(e, st, reason: 'language load');
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

  void _addAllPowerups(int n) => _inventory(() {
    for (final t in PowerupType.values) {
      profile.powerups[t] = (profile.powerups[t] ?? 0) + n;
    }
  });

  void addPowerup(PowerupType t, [int n = 1]) {
    _inventory(() => profile.powerups[t] = (profile.powerups[t] ?? 0) + n);
    unawaited(saveProfile());
  }

  /// Runs [change], which may add powerups to the profile, then records
  /// whatever it added in the classic game in progress. That game owns the
  /// counts while it runs ([saveGame] copies them back after every move), so
  /// without this a reward or purchase would vanish on the next move.
  T _inventory<T>(T Function() change) {
    final before = Map.of(profile.powerups);
    final out = change();
    final running = savedClassic;
    final e = running == null ? null : _engines[running.language];
    if (running == null || running.isOver || e == null) return out;
    final added = {
      for (final t in PowerupType.values)
        if ((profile.powerups[t] ?? 0) > (before[t] ?? 0)) t: (profile.powerups[t] ?? 0) - (before[t] ?? 0),
    };
    if (added.isEmpty) return out;
    final next = e.apply(running, GrantAction(added)).state;
    savedClassic = next;
    unawaited(services.games.saveClassic(next));
    return out;
  }

  /// XP earned outside a game result (rewarded "2x XP", gifts). Returns the
  /// level-ups it caused.
  List<LevelUpReward> grantBonusXp(int xp) {
    final ups = _inventory(() => Progression.addXp(profile, xp));
    for (final l in ups) {
      services.analytics.log(AnalyticsEvent.levelUp, {'level': l.level});
    }
    unawaited(saveProfile());
    return ups;
  }

  // ------------------------------------------------------ rewarded extras

  /// The daily streak that was just lost and can still be repaired, or 0.
  int get repairableStreak => profileLoaded ? profile.streak.repairable(today) : 0;

  /// Rewarded "seri kurtarma": brings a just-broken daily streak back so
  /// today's puzzle continues it.
  Future<bool> repairStreak() async {
    if (repairableStreak == 0) return false;
    if (!await watchRewarded(RewardPlacement.streakRepair)) return false;
    profile.streak = profile.streak.repair(today);
    services.analytics.log(AnalyticsEvent.streakRepaired, {'streak': profile.streak.current});
    await saveProfile();
    return true;
  }

  bool get dailyGiftAvailable => profileLoaded && profile.giftDay != today.toString();

  /// Today's gift: one powerup, a different kind each day.
  PowerupType get dailyGiftType => PowerupType.values[today.dayIndex % PowerupType.values.length];

  /// Opens today's gift (free, once per Istanbul day). Returns what was in
  /// it, or null when it was already taken.
  PowerupType? openDailyGift() {
    if (!dailyGiftAvailable) return null;
    final t = dailyGiftType;
    profile.giftDay = today.toString();
    services.analytics.log(AnalyticsEvent.dailyGift, {'type': t.name});
    addPowerup(t);
    return t;
  }

  /// Rewarded: a second one of today's gift.
  Future<bool> doubleDailyGift(PowerupType t) async {
    if (!await watchRewarded(RewardPlacement.dailyGift)) return false;
    addPowerup(t);
    return true;
  }

  /// Rewarded ad (or free when ads are removed). Returns true on reward.
  Future<bool> watchRewarded(RewardPlacement placement) async {
    if (profile.adsRemoved) return true;
    final ok = await services.ads.showRewarded(placement);
    services.analytics.log(AnalyticsEvent.adShown, {'type': 'rewarded', 'placement': placement.name});
    if (ok) {
      _lastRewardedAt = clock();
      services.analytics.log(AnalyticsEvent.adRewarded, {'placement': placement.name});
    }
    return ok;
  }

  /// When the player last sat through a rewarded ad (this session).
  DateTime? _lastRewardedAt;

  /// Spec 12 interstitial policy; call when leaving a finished game.
  Future<void> maybeInterstitial(GameMode mode) async {
    if (mode == GameMode.daily) return;
    final last = _lastRewardedAt;
    final justWatched = last != null && clock().difference(last) < AdConfig.interstitialAfterRewarded;
    if (!justWatched &&
        Progression.shouldShowInterstitial(
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
    final language = wordLanguage.code;
    final d = today;
    final saved = await services.games.loadDaily(d, language);
    if (saved != null) return e.revalidate(saved);
    final s = e.newGame(
      seed: Rng.dailySeedFor(d.year, d.month, d.day, language),
      mode: GameMode.daily,
      startedAt: clock(),
    );
    services.analytics.log(AnalyticsEvent.gameStart, {'mode': 'daily'});
    await services.games.saveDaily(d, s);
    return s;
  }

  bool get dailyDoneToday => profile.dailyFor(today, wordLanguage.code) != null;

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
  ({List<Mission> missions, WeeklyGoal? weekly, List<LevelUpReward> levelUps}) recordMove(MoveSummary m) {
    final r = _inventory(() => Progression.applyMove(profile, m, today));
    for (final mission in r.missions) {
      services.analytics.log(AnalyticsEvent.missionCompleted, {'id': mission.type.name, 'tier': mission.tier.name});
    }
    for (final l in r.levelUps) {
      services.analytics.log(AnalyticsEvent.levelUp, {'level': l.level});
    }
    if (r.weekly != null) {
      services.analytics.log(AnalyticsEvent.missionCompleted, {'id': r.weekly!.mission.type.name, 'tier': 'weekly'});
    }
    if (r.missions.isNotEmpty || r.weekly != null || r.levelUps.isNotEmpty) unawaited(saveProfile());
    return r;
  }

  /// Replays a finished game to build its summary (exact, also for games
  /// resumed from storage).
  GameSummary summarize(GameState s) {
    final e = _engines[s.language]!;
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
      language: s.language,
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
    final w = Wordbook.fromJson(wordbookFor(s.language).toJson());
    return Progression.applyGameEnd(p, w, summarize(s), today);
  }

  Future<GameEndResult> recordGameEnd(GameState s) async {
    final g = summarize(s);
    // A classic game may be paused while the daily puzzle pays out rewards.
    final book = wordbookFor(s.language);
    final r = _inventory(() => Progression.applyGameEnd(profile, book, g, today));
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
    await services.profiles.saveWordbook(book, s.language);
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

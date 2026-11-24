import 'dart:async';
import 'dart:io' show Platform;

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_info.dart';
import 'crash_reporter.dart';

enum RewardPlacement { continueGame, earnPowerup, doubleXp, streakRepair, dailyGift }

/// Ads behind an interface (spec 12). Never shown during play.
abstract interface class AdsService {
  Future<void> init();

  /// Shows a rewarded ad; completes with true when the reward was earned.
  Future<bool> showRewarded(RewardPlacement placement);
  Future<void> showInterstitial();
  bool get rewardedAvailable;

  /// False where the platform has no ads at all (web release): rewarded
  /// entry points are hidden instead of failing.
  bool get supported;
}

/// Web / desktop release: no ads. Rewarded actions are hidden in the UI.
class NoAdsService implements AdsService {
  @override
  Future<void> init() async {}
  @override
  bool get rewardedAvailable => false;
  @override
  bool get supported => false;
  @override
  Future<bool> showRewarded(RewardPlacement placement) async => false;
  @override
  Future<void> showInterstitial() async {}
}

/// Development / test implementation: rewards are granted instantly.
class FakeAdsService implements AdsService {
  int rewardedShown = 0;
  int interstitialsShown = 0;

  @override
  Future<void> init() async {}

  @override
  bool get rewardedAvailable => true;
  @override
  bool get supported => true;

  @override
  Future<bool> showRewarded(RewardPlacement placement) async {
    rewardedShown++;
    return true;
  }

  @override
  Future<void> showInterstitial() async => interstitialsShown++;
}

/// Google AdMob. Call [init] only after consent (ConsentService) allows ads.
class AdMobAdsService implements AdsService {
  AdMobAdsService({required this.crash});

  final CrashReporter crash;
  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  bool _initialized = false;

  String get _rewardedId => Platform.isIOS ? AdConfig.iosRewarded : AdConfig.androidRewarded;
  String get _interstitialId => Platform.isIOS ? AdConfig.iosInterstitial : AdConfig.androidInterstitial;

  @override
  Future<void> init() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadRewarded();
      _loadInterstitial();
    } on Object catch (e, st) {
      crash.record(e, st, reason: 'ads init');
    }
  }

  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (e) {
          _rewarded = null;
          crash.log('rewarded load failed: ${e.message}');
        },
      ),
    );
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (e) {
          _interstitial = null;
          crash.log('interstitial load failed: ${e.message}');
        },
      ),
    );
  }

  @override
  bool get rewardedAvailable => _rewarded != null;
  @override
  bool get supported => true;

  @override
  Future<bool> showRewarded(RewardPlacement placement) {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return Future.value(false);
    }
    _rewarded = null;
    final done = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadRewarded();
        if (!done.isCompleted) done.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        _loadRewarded();
        if (!done.isCompleted) done.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (_, _) => earned = true);
    return done.future;
  }

  @override
  Future<void> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadInterstitial();
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        _loadInterstitial();
        if (!done.isCompleted) done.complete();
      },
    );
    await ad.show();
    return done.future;
  }
}

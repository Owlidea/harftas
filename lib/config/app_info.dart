/// App identity and product configuration.
abstract final class AppInfo {
  /// Build-time switch: `--dart-define=TEST_TOOLS=true` adds a "Test araçları"
  /// section to Settings (unlock every look, replay celebrations). Never set
  /// for store builds.
  static const bool testTools = bool.fromEnvironment('TEST_TOOLS');

  /// Chosen 2026-11-13 (karar 1), renamed to "Harf Kombo" 2026-11-21 (karar: ad
  /// iki mağazada da benzersiz). Hosted pages keep the owlidea.github.io/harftas
  /// URL, which the stores already link to. Native labels: AndroidManifest
  /// `android:label`, iOS `CFBundleDisplayName`, web index.html/manifest.
  static const String displayName = 'Harf Kombo';

  /// Logo placeholder lines (tile rows) until the SVG logo is delivered.
  static const List<String> logoLines = ['HARF', 'KOMBO'];

  /// Store / landing page shown in share texts. Set SHARE_URL in
  /// config/prod.json (docs/yayin_rehberi.md).
  static const String shareUrl = String.fromEnvironment('SHARE_URL', defaultValue: 'https://owlidea.github.io/harftas/');

  /// Hosted privacy policy (web/gizlilik.html once the web build is deployed).
  static const String privacyUrl = String.fromEnvironment(
    'PRIVACY_URL',
    defaultValue: 'https://owlidea.github.io/harftas/gizlilik.html',
  );
  static const String supportEmail = String.fromEnvironment('SUPPORT_EMAIL', defaultValue: 'support@owlidea.com');
  static const String version = '1.0.0';

  // In-app purchase product ids (create the same ids in App Store Connect /
  // Play Console).
  static const String productRemoveAds = 'remove_ads';
  static const String productPowerupsSmall = 'powerups_small';
  static const String productPowerupsLarge = 'powerups_large';

  /// Powerups granted per pack (each of the three types).
  static const int powerupsSmallAmount = 3;
  static const int powerupsLargeAmount = 10;
}

/// RevenueCat public SDK keys (Project settings -> API keys). They are meant
/// to ship inside the app; set them in config/prod.json. Empty = store hidden.
abstract final class RevenueCatConfig {
  static const String appleApiKey = String.fromEnvironment('REVENUECAT_APPLE_KEY');
  static const String googleApiKey = String.fromEnvironment('REVENUECAT_GOOGLE_KEY');

  /// Entitlement unlocked by `remove_ads` (create it in the dashboard).
  static const String premiumEntitlement = 'premium';
}

/// Ad configuration. Real AdMob ids come from config/prod.json
/// (`--dart-define-from-file`); without it Google's public TEST ids are used,
/// so a development build can never show live ads by accident.
abstract final class AdConfig {
  static const String androidRewarded = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  );
  static const String androidInterstitial = String.fromEnvironment(
    'ADMOB_ANDROID_INTERSTITIAL',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  );
  static const String iosRewarded = String.fromEnvironment(
    'ADMOB_IOS_REWARDED',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313',
  );
  static const String iosInterstitial = String.fromEnvironment(
    'ADMOB_IOS_INTERSTITIAL',
    defaultValue: 'ca-app-pub-3940256099942544/4411468910',
  );

  /// True while any unit id is still one of Google's test ids.
  static bool get usingTestIds =>
      [androidRewarded, androidInterstitial, iosRewarded, iosInterstitial].any((id) => id.startsWith(_testPublisher));
  static const String _testPublisher = 'ca-app-pub-3940256099942544/';

  /// Spec 12: interstitial at most every N games, never in the first N
  /// sessions, never after the daily puzzle.
  static const int interstitialEveryGames = 3;
  static const int interstitialFreeSessions = 3;

  /// No interstitial this soon after the player chose to watch a rewarded ad
  /// ("2x XP" or "Devam Et" at game over would otherwise be followed by a
  /// second, forced ad on the way out). The skipped one comes a game later.
  static const Duration interstitialAfterRewarded = Duration(minutes: 2);
}

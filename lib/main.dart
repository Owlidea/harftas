import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'app/app_model.dart';
import 'config/app_info.dart';
import 'data/repositories.dart';
import 'data/storage/json_store.dart';
import 'data/storage/storage_backend.dart';
import 'services/ads_service.dart';
import 'services/analytics.dart';
import 'services/audio_service.dart';
import 'services/consent_service.dart';
import 'services/crash_reporter.dart';
import 'services/haptics_service.dart';
import 'services/notification_service.dart';
import 'services/purchase_service.dart';
import 'ui/components/app_icon.dart';
import 'ui/theme/app_theme.dart';

/// Build-time switch: `--dart-define=FAKE_SERVICES=true` uses the fake ads
/// and purchases (development, screenshots, tests).
const bool _fakeServices = bool.fromEnvironment('FAKE_SERVICES');

/// RevenueCat on phones with a key for this platform; otherwise no store
/// (the store screen then shows its "unavailable" state).
PurchaseService _storePurchases(bool mobile, CrashReporter crash) {
  if (!mobile) return NoPurchaseService();
  final key = defaultTargetPlatform == TargetPlatform.iOS ? RevenueCatConfig.appleApiKey : RevenueCatConfig.googleApiKey;
  if (key.isEmpty) {
    crash.log('RevenueCat key missing: build with --dart-define-from-file=config/prod.json');
    return NoPurchaseService();
  }
  return RevenueCatPurchaseService(apiKey: key, crash: crash);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const crash = ConsoleCrashReporter();
  FlutterError.onError = (d) => crash.record(d.exception, d.stack, reason: d.context?.toDescription(), fatal: true);
  PlatformDispatcher.instance.onError = (e, st) {
    crash.record(e, st, fatal: true);
    return true;
  };

  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/config/ZEMBEREK_LICENSE.txt');
    yield LicenseEntryWithLineBreaks(['Zemberek-NLP (sözlük verisi)'], text);
    final font = await rootBundle.loadString('assets/fonts/Nunito-OFL.txt');
    yield LicenseEntryWithLineBreaks(['Nunito (yazı tipi)'], font);
  });

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
  await Future.wait([loadAppFonts(), AssetIndex.load()]);

  final store = JsonStore(await createStorageBackend(), crash: crash);
  // Web / desktop: real ads, purchases, notifications and audio are not
  // available; the fake / silent implementations keep the game fully playable.
  final mobile =
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  final services = AppServices(
    games: GameRepository(store),
    profiles: ProfileRepository(store),
    audio: kIsWeb ? SilentAudioService() : SoloudAudioService(crash: crash),
    haptics: SystemHaptics(),
    analytics: const ConsoleAnalytics(),
    crash: crash,
    // Web release has no ads or store: those entry points are hidden.
    ads: _fakeServices ? FakeAdsService() : (mobile ? AdMobAdsService(crash: crash) : NoAdsService()),
    purchases: _fakeServices ? FakePurchaseService() : _storePurchases(mobile, crash),
    notifications: mobile ? LocalNotifications(crash: crash) : NoopNotifications(),
    consent: _fakeServices || !mobile ? NoConsentNeeded() : UmpConsentService(crash: crash),
  );

  if (kReleaseMode && mobile && !_fakeServices && AdConfig.usingTestIds) {
    crash.log('Release build uses AdMob TEST ids: build with --dart-define-from-file=config/prod.json');
  }

  final model = AppModel(services);
  runApp(HarfBlokApp(model: model));
  // Data loads after the first frame so startup is never blocked (spec 3).
  unawaited(model.init(rootBundle));
}

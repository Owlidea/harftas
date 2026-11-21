import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'crash_reporter.dart';

/// KVKK/GDPR consent (Google UMP) and iOS App Tracking Transparency
/// (spec 16, Aşama 5). Order: UMP form (if required) -> ATT prompt (iOS) ->
/// ads may initialise.
abstract interface class ConsentService {
  /// Returns whether ads may be requested.
  Future<bool> gather();
  Future<bool> get privacyOptionsRequired;
  Future<void> showPrivacyOptions();
}

class NoConsentNeeded implements ConsentService {
  @override
  Future<bool> gather() async => true;
  @override
  Future<bool> get privacyOptionsRequired async => false;
  @override
  Future<void> showPrivacyOptions() async {}
}

class UmpConsentService implements ConsentService {
  UmpConsentService({required this.crash});
  final CrashReporter crash;

  @override
  Future<bool> gather() async {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) crash.log('consent form: ${error.message}');
        });
        if (!done.isCompleted) done.complete();
      },
      (error) {
        crash.log('consent update: ${error.message}');
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future;
    if (Platform.isIOS) {
      try {
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      } on Object catch (e, st) {
        crash.record(e, st, reason: 'ATT');
      }
    }
    return ConsentInformation.instance.canRequestAds();
  }

  @override
  Future<bool> get privacyOptionsRequired async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;

  @override
  Future<void> showPrivacyOptions() => ConsentForm.showPrivacyOptionsForm((error) {
    if (error != null) crash.log('privacy options: ${error.message}');
  });
}

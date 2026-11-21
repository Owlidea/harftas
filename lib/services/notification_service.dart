import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'crash_reporter.dart';

/// Local reminders (spec 8): at most one per day, only with permission.
abstract interface class NotificationService {
  Future<void> init();
  Future<bool> requestPermission();

  /// Replaces any pending reminder with a single one at [atUtc].
  Future<void> scheduleOnce({required DateTime atUtc, required String title, required String body});
  Future<void> cancelAll();
}

class NoopNotifications implements NotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> scheduleOnce({required DateTime atUtc, required String title, required String body}) async {}
  @override
  Future<void> cancelAll() async {}
}

class LocalNotifications implements NotificationService {
  LocalNotifications({required this.crash});
  final CrashReporter crash;
  final _plugin = FlutterLocalNotificationsPlugin();
  static const _id = 1;

  @override
  Future<void> init() async {
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    try {
      if (Platform.isIOS) {
        return await _plugin
                .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(alert: true, sound: true) ??
            false;
      }
      return await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    } on Object catch (e, st) {
      crash.record(e, st, reason: 'notification permission');
      return false;
    }
  }

  @override
  Future<void> scheduleOnce({required DateTime atUtc, required String title, required String body}) async {
    try {
      await _plugin.cancelAll();
      await _plugin.zonedSchedule(
        id: _id,
        scheduledDate: tz.TZDateTime.from(atUtc, tz.UTC),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily',
            'Günlük bulmaca',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
      );
    } on Object catch (e, st) {
      crash.record(e, st, reason: 'schedule notification');
    }
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}

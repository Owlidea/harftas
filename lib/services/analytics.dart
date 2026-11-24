import 'package:flutter/foundation.dart';

/// Analytics events (spec 15). No personal data: only game facts.
abstract interface class Analytics {
  void log(String event, [Map<String, Object?> params = const {}]);
}

abstract final class AnalyticsEvent {
  static const appOpen = 'app_open';
  static const tutorialStep = 'tutorial_step';
  static const tutorialSkip = 'tutorial_skip';
  static const gameStart = 'game_start';
  static const move = 'move';
  static const wordFormed = 'word_formed';
  static const combo = 'combo';
  static const powerupUsed = 'powerup_used';
  static const gameOver = 'game_over';
  static const continueUsed = 'continue_used';
  static const dailyCompleted = 'daily_completed';
  static const shareTapped = 'share_tapped';
  static const missionCompleted = 'mission_completed';
  static const levelUp = 'level_up';
  static const adShown = 'ad_shown';
  static const adRewarded = 'ad_rewarded';
  static const purchase = 'purchase';
  static const settingsChanged = 'settings_changed';
  static const xpDoubled = 'xp_doubled';
  static const streakRepaired = 'streak_repaired';
  static const dailyGift = 'daily_gift';
}

class ConsoleAnalytics implements Analytics {
  const ConsoleAnalytics();
  @override
  void log(String event, [Map<String, Object?> params = const {}]) {
    if (kDebugMode) debugPrint('[analytics] $event $params');
  }
}

/// Records events in memory (tests).
class MemoryAnalytics implements Analytics {
  final List<(String, Map<String, Object?>)> events = [];
  @override
  void log(String event, [Map<String, Object?> params = const {}]) => events.add((event, params));
}

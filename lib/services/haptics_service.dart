import 'package:flutter/services.dart';

enum HapticKind { place, word, combo, invalid, button }

/// Spec 10: place = light, word = medium, combo = heavy, invalid = warning.
abstract interface class HapticsService {
  set enabled(bool v);
  void play(HapticKind kind);
}

class SystemHaptics implements HapticsService {
  bool _enabled = true;

  @override
  set enabled(bool v) => _enabled = v;

  @override
  void play(HapticKind kind) {
    if (!_enabled) return;
    switch (kind) {
      case HapticKind.place:
        HapticFeedback.lightImpact();
      case HapticKind.word:
        HapticFeedback.mediumImpact();
      case HapticKind.combo:
        HapticFeedback.heavyImpact();
      case HapticKind.invalid:
        HapticFeedback.vibrate();
      case HapticKind.button:
        HapticFeedback.selectionClick();
    }
  }
}

class NoHaptics implements HapticsService {
  @override
  set enabled(bool v) {}
  @override
  void play(HapticKind kind) {}
}

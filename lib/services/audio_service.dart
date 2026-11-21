import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../config/asset_paths.dart';
import 'crash_reporter.dart';

/// Sound effects + optional music (spec 10).
abstract interface class AudioService {
  Future<void> init();
  /// [pitch] is a playback-speed multiplier (1 = original; 2^(n/12) = n semitones up).
  void play(SoundId id, {double volume = 1, double pitch = 1});
  set soundEnabled(bool v);
  set musicEnabled(bool v);
  void dispose();
}

class SilentAudioService implements AudioService {
  @override
  Future<void> init() async {}
  @override
  void play(SoundId id, {double volume = 1, double pitch = 1}) {}
  @override
  set soundEnabled(bool v) {}
  @override
  set musicEnabled(bool v) {}
  @override
  void dispose() {}
}

/// SoLoud-backed audio. Missing files (not delivered yet) are skipped
/// silently, so placeholders need no audio data.
///
/// Premium touches (spec 10): frequent sounds have up to 4 recorded variants
/// (`drop.ogg`, `drop_2.ogg` …) picked at random without immediate repeats,
/// callers can raise the pitch musically (streaks), and big moments briefly
/// duck the music so the reward sound stands out.
class SoloudAudioService implements AudioService {
  SoloudAudioService({required this.crash});

  final CrashReporter crash;
  final Map<SoundId, List<AudioSource>> _sources = {};
  final Map<SoundId, int> _lastVariant = {};
  final Map<SoundId, int> _lastPlayedMs = {};
  final math.Random _random = math.Random();
  bool _sound = true;
  bool _music = false;
  bool _ready = false;
  SoundHandle? _musicHandle;

  /// Relative volume per sound (spec 13 "göreli ses düzeyi").
  static const Map<SoundId, double> _gain = {
    SoundId.pick: 0.35,
    SoundId.drop: 0.5,
    SoundId.invalid: 0.4,
    SoundId.button: 0.25,
    SoundId.streakUp: 0.4,
    SoundId.boardClear: 0.9,
    SoundId.newRecord: 0.9,
    SoundId.musicLoop: 0.2,
  };

  @override
  Future<void> init() async {
    try {
      await SoLoud.instance.init();
      _ready = true;
    } on Object catch (e, st) {
      crash.record(e, st, reason: 'audio init');
      return;
    }
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final available = manifest.listAssets().toSet();
    for (final id in SoundId.values) {
      for (final path in AssetPaths.soundVariants(id)) {
        if (!available.contains(path)) continue;
        try {
          (_sources[id] ??= []).add(await SoLoud.instance.loadAsset(path));
        } on Object catch (e, st) {
          crash.record(e, st, reason: 'audio load $path');
        }
      }
    }
    if (_music) _startMusic();
  }

  @override
  void play(SoundId id, {double volume = 1, double pitch = 1}) {
    if (!_ready || !_sound) return;
    final list = _sources[id];
    if (list == null || list.isEmpty) return;
    var i = list.length == 1 ? 0 : _random.nextInt(list.length);
    if (list.length > 1 && i == _lastVariant[id]) i = (i + 1) % list.length;
    _lastVariant[id] = i;
    final h = SoLoud.instance.play(list[i], volume: volume * (_gain[id] ?? 0.7));
    // Same sound repeated quickly: vary pitch ±4% on top (spec 10).
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastPlayedMs[id];
    _lastPlayedMs[id] = now;
    final jitter = last != null && now - last < 600 ? 0.96 + _random.nextDouble() * 0.08 : 1.0;
    if (pitch != 1 || jitter != 1) SoLoud.instance.setRelativePlaySpeed(h, pitch * jitter);
    if (_duck.contains(id)) _duckMusic();
  }

  static const Set<SoundId> _duck = {SoundId.boardClear, SoundId.newRecord, SoundId.levelUp, SoundId.combo3};

  void _duckMusic() {
    final m = _musicHandle;
    if (m == null) return;
    final full = _gain[SoundId.musicLoop]!;
    SoLoud.instance.fadeVolume(m, full * 0.35, const Duration(milliseconds: 120));
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (_musicHandle == m) SoLoud.instance.fadeVolume(m, full, const Duration(milliseconds: 700));
    });
  }

  @override
  set soundEnabled(bool v) => _sound = v;

  @override
  set musicEnabled(bool v) {
    _music = v;
    if (!_ready) return;
    if (v) {
      _startMusic();
    } else if (_musicHandle != null) {
      SoLoud.instance.stop(_musicHandle!);
      _musicHandle = null;
    }
  }

  void _startMusic() {
    final src = _sources[SoundId.musicLoop]?.first;
    if (src == null || _musicHandle != null) return;
    _musicHandle = SoLoud.instance.play(src, looping: true, volume: _gain[SoundId.musicLoop]!);
  }

  @override
  void dispose() {
    if (_ready) SoLoud.instance.deinit();
  }
}

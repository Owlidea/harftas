import '../core/core.dart';
import '../progress/calendar.dart';
import '../progress/profile.dart';
import '../progress/wordbook.dart';
import 'storage/json_store.dart';

/// Saved in-progress games: one classic game + one per daily date.
class GameRepository {
  GameRepository(this._store);
  final JsonStore _store;

  static const _classic = 'game_classic';
  static String _daily(DayKey d) => 'game_daily_$d';

  Future<GameState?> loadClassic() => _store.read(_classic, GameState.fromJson);
  Future<void> saveClassic(GameState s) => _store.write(_classic, s.toJson());
  Future<void> clearClassic() => _store.delete(_classic);

  Future<GameState?> loadDaily(DayKey d) => _store.read(_daily(d), GameState.fromJson);
  Future<void> saveDaily(DayKey d, GameState s) => _store.write(_daily(d), s.toJson());

  Future<void> save(GameState s, DayKey? daily) => s.mode == GameMode.daily ? saveDaily(daily!, s) : saveClassic(s);
}

class ProfileRepository {
  ProfileRepository(this._store);
  final JsonStore _store;

  Future<PlayerProfile> loadProfile() async => await _store.read('profile', PlayerProfile.fromJson) ?? PlayerProfile();
  Future<void> saveProfile(PlayerProfile p) => _store.write('profile', p.toJson());

  Future<AppSettings> loadSettings() async =>
      await _store.read('settings', AppSettings.fromJson) ?? const AppSettings();
  Future<void> saveSettings(AppSettings s) => _store.write('settings', s.toJson());

  Future<Wordbook> loadWordbook() async => await _store.read('wordbook', Wordbook.fromJson) ?? Wordbook();
  Future<void> saveWordbook(Wordbook w) => _store.write('wordbook', w.toJson());
}

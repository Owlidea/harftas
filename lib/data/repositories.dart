import '../core/core.dart';
import '../progress/calendar.dart';
import '../progress/profile.dart';
import '../progress/wordbook.dart';
import 'storage/json_store.dart';

/// Saved in-progress games: one classic game + one per daily date and word
/// language (Turkish keeps its pre-karar-29 document names).
class GameRepository {
  GameRepository(this._store);
  final JsonStore _store;

  static const _classic = 'game_classic';
  static String _daily(DayKey d, String language) => language == 'tr' ? 'game_daily_$d' : 'game_daily_${language}_$d';

  Future<GameState?> loadClassic() => _store.read(_classic, GameState.fromJson);
  Future<void> saveClassic(GameState s) => _store.write(_classic, s.toJson());
  Future<void> clearClassic() => _store.delete(_classic);

  Future<GameState?> loadDaily(DayKey d, [String language = 'tr']) =>
      _store.read(_daily(d, language), GameState.fromJson);
  Future<void> saveDaily(DayKey d, GameState s) => _store.write(_daily(d, s.language), s.toJson());

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

  /// One Kelime Defteri per word language; Turkish keeps `wordbook`.
  static String _wordbook(String language) => language == 'tr' ? 'wordbook' : 'wordbook_$language';

  Future<Wordbook> loadWordbook([String language = 'tr']) async =>
      await _store.read(_wordbook(language), Wordbook.fromJson) ?? Wordbook();
  Future<void> saveWordbook(Wordbook w, [String language = 'tr']) => _store.write(_wordbook(language), w.toJson());
}

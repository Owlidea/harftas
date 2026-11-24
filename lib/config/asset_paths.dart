/// Every asset path in one place (spec 13). Files are delivered by the
/// designer; until then the app uses code-drawn placeholders, and dropping the
/// real file at the same path requires no code change. Status: ASSETS.md.
abstract final class AssetPaths {
  // Data
  static const String balanceConfig = 'assets/config/balance.json';
  static const String dictionary = 'assets/dict/words.bin';
  static const String commonWords = 'assets/dict/common.bin';

  // Fonts: every .ttf/.otf in this folder is loaded into one family.
  static const String fontsDir = 'assets/fonts/';

  // Brand
  static const String logoLight = 'assets/images/brand/logo_light.svg';
  static const String logoDark = 'assets/images/brand/logo_dark.svg';

  // Icons (single-colour SVG, tinted in code)
  static String icon(AppIconName name) => 'assets/images/icons/ic_${name.fileName}.svg';

  static String powerupArtwork(AppIconName name) =>
      'assets/images/icons/ic_${name.fileName}.png';

  /// Full-colour 3D artwork for hero spots (store, streak, lock). Optional:
  /// [ArtIcon] falls back to the tinted line icon.
  static String artwork(AppIconName name) => 'assets/images/art/${name.fileName}.png';

  // Badges
  // Streak medals are 3D renders (tool/blender/render_icons.py).
  static String streakBadge(int days) => 'assets/images/badges/streak_$days.png';
  static String levelBadge(int level) => 'assets/images/badges/level_$level.svg';

  // Theme previews
  static String themePreview(String themeId) => 'assets/images/themes/preview_$themeId.png';

  // Empty states
  static const String emptyWordbook = 'assets/images/empty/wordbook.svg';
  static const String emptyCalendar = 'assets/images/empty/calendar.svg';
  static const String emptyMissions = 'assets/images/empty/missions.svg';

  // Tutorial
  static const String tutorialHand = 'assets/images/tutorial/hand.svg';

  // Lottie (optional — code fallbacks exist)
  static const String animNewRecord = 'assets/anim/new_record.json';
  static const String animBoardClear = 'assets/anim/board_clear.json';
  static const String animLevelUp = 'assets/anim/level_up.json';

  // Sprite-sheet celebrations (Blender renders; see SpriteAnim)
  static const String fxNewRecord = 'assets/anim/new_record.webp';
  static const String fxBoardClear = 'assets/anim/board_clear.webp';
  static const String fxLevelUp = 'assets/anim/level_up.webp';

  // Audio
  static String sound(SoundId id) => 'assets/audio/${id.fileName}.ogg';

  /// Base file plus optional recorded variants (`drop_2.ogg` … `drop_4.ogg`).
  static List<String> soundVariants(SoundId id) => [
    sound(id),
    for (var i = 2; i <= 4; i++) 'assets/audio/${id.fileName}_$i.ogg',
  ];
}

enum AppIconName {
  pause,
  settings,
  book,
  missions,
  calendar,
  stats,
  share,
  sound,
  music,
  haptic,
  back,
  home,
  close,
  lock,
  check,
  store,
  info,
  powerupRefresh('powerup_refresh'),
  powerupJoker('powerup_joker'),
  powerupHammer('powerup_hammer'),
  streak,
  crown,
  gift,
  star,
  palette,
  tiles;

  const AppIconName([this._file]);
  final String? _file;
  String get fileName => _file ?? name;
}

enum SoundId {
  pick,
  drop,
  invalid,
  wordS('word_s'),
  wordM('word_m'),
  wordL('word_l'),
  combo1('combo_1'),
  combo2('combo_2'),
  combo3('combo_3'),
  streakUp('streak_up'),
  boardClear('board_clear'),
  newRecord('new_record'),
  gameOver('game_over'),
  button,
  levelUp('level_up'),
  missionDone('mission_done'),
  puRefresh('pu_refresh'),
  puJoker('pu_joker'),
  puHammer('pu_hammer'),
  musicLoop('music_loop');

  const SoundId([this._file]);
  final String? _file;
  String get fileName => _file ?? name;
}

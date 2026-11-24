import '../core/model/game_state.dart';
import 'calendar.dart';
import 'missions.dart';
import 'streak.dart';

class DailyResult {
  const DailyResult({required this.score, required this.words, required this.longestLength, required this.streakAfter});

  factory DailyResult.fromJson(Map<String, dynamic> j) => DailyResult(
    score: j['score'] as int,
    words: j['words'] as int,
    longestLength: j['longest'] as int,
    streakAfter: j['streak'] as int? ?? 0,
  );

  final int score;
  final int words;
  final int longestLength;
  final int streakAfter;

  Map<String, dynamic> toJson() => {'score': score, 'words': words, 'longest': longestLength, 'streak': streakAfter};
}

/// Everything persistent about the player except the wordbook and saved games.
class PlayerProfile {
  PlayerProfile({
    this.totalXp = 0,
    Map<PowerupType, int>? powerups,
    this.adsRemoved = false,
    this.sessions = 0,
    this.gamesSinceInterstitial = 0,
    this.tutorialDone = false,
    this.introSeen = false,
    this.notificationAsked = false,
    this.bestScore = 0,
    this.totalGames = 0,
    this.totalWords = 0,
    this.totalLetters = 0,
    this.bestMoveStreak = 0,
    this.streak = const DailyStreak(),
    Map<String, DailyResult>? daily,
    Set<String>? badges,
    Set<String>? unlockedThemes,
    Set<String>? unlockedTileStyles,
    Set<String>? unlockedBoardStyles,
    this.missionsDay,
    List<Mission>? missions,
    this.weekly,
    this.bestCombo = 0,
    this.boardClears = 0,
    Set<String>? achievements,
  }) : powerups = powerups ?? {for (final t in PowerupType.values) t: 1},
       daily = daily ?? {},
       badges = badges ?? {},
       unlockedThemes = unlockedThemes ?? {'classic'},
       unlockedTileStyles = unlockedTileStyles ?? {'classic'},
       unlockedBoardStyles = unlockedBoardStyles ?? {'plain'},
       achievements = achievements ?? {},
       missions = missions ?? [];

  factory PlayerProfile.fromJson(Map<String, dynamic> j) {
    final v = j['v'] as int? ?? 0;
    if (v > schemaVersion) throw FormatException('profile version $v');
    Set<String> strings(Object? o) => {for (final s in (o as List? ?? const [])) s as String};
    return PlayerProfile(
      totalXp: j['xp'] as int? ?? 0,
      powerups: {for (final t in PowerupType.values) t: ((j['powerups'] as Map?)?[t.name] as int?) ?? 1},
      adsRemoved: j['adsRemoved'] as bool? ?? false,
      sessions: j['sessions'] as int? ?? 0,
      gamesSinceInterstitial: j['gamesSinceAd'] as int? ?? 0,
      tutorialDone: j['tutorialDone'] as bool? ?? false,
      // Older saves: players who finished the tutorial already know the rules.
      introSeen: j['introSeen'] as bool? ?? (j['tutorialDone'] as bool? ?? false),
      notificationAsked: j['notifAsked'] as bool? ?? false,
      bestScore: j['bestScore'] as int? ?? 0,
      totalGames: j['games'] as int? ?? 0,
      totalWords: j['words'] as int? ?? 0,
      totalLetters: j['letters'] as int? ?? 0,
      bestMoveStreak: j['bestMoveStreak'] as int? ?? 0,
      streak: j['streak'] == null ? const DailyStreak() : DailyStreak.fromJson(j['streak'] as Map<String, dynamic>),
      daily: {
        for (final e in ((j['daily'] as Map<String, dynamic>?) ?? const {}).entries)
          e.key: DailyResult.fromJson(e.value as Map<String, dynamic>),
      },
      badges: strings(j['badges']),
      unlockedThemes: {'classic', ...strings(j['themes'])},
      unlockedTileStyles: {'classic', ...strings(j['tileStyles'])},
      unlockedBoardStyles: {'plain', ...strings(j['boardStyles'])},
      missionsDay: j['missionsDay'] as String?,
      missions: [for (final m in (j['missions'] as List? ?? const [])) Mission.fromJson(m as Map<String, dynamic>)],
      weekly: j['weekly'] == null ? null : WeeklyGoal.fromJson(j['weekly'] as Map<String, dynamic>),
      bestCombo: j['bestCombo'] as int? ?? 0,
      boardClears: j['boardClears'] as int? ?? 0,
      achievements: strings(j['achievements']),
    );
  }

  /// v1: initial. Older files (v0 = no field) are read with defaults.
  static const int schemaVersion = 1;

  int totalXp;
  final Map<PowerupType, int> powerups;
  bool adsRemoved;
  int sessions;
  int gamesSinceInterstitial;
  bool tutorialDone;

  /// First-run "how to play" intro shown.
  bool introSeen;
  bool notificationAsked;
  int bestScore;
  int totalGames;
  int totalWords;
  int totalLetters;
  int bestMoveStreak;
  DailyStreak streak;
  final Map<String, DailyResult> daily;
  final Set<String> badges;
  final Set<String> unlockedThemes;
  final Set<String> unlockedTileStyles;
  final Set<String> unlockedBoardStyles;
  String? missionsDay;
  List<Mission> missions;

  /// This week's goal (null until the first move after an update).
  WeeklyGoal? weekly;

  /// Most words exploded by a single move, ever.
  int bestCombo;

  /// Times the board was emptied, in total.
  int boardClears;

  /// Ids of achievements already earned and rewarded.
  final Set<String> achievements;

  double get averageWordLength => totalWords == 0 ? 0 : totalLetters / totalWords;

  DailyResult? dailyFor(DayKey d) => daily[d.toString()];

  Map<String, dynamic> toJson() => {
    'v': schemaVersion,
    'xp': totalXp,
    'powerups': {for (final e in powerups.entries) e.key.name: e.value},
    'adsRemoved': adsRemoved,
    'sessions': sessions,
    'gamesSinceAd': gamesSinceInterstitial,
    'tutorialDone': tutorialDone,
    'introSeen': introSeen,
    'notifAsked': notificationAsked,
    'bestScore': bestScore,
    'games': totalGames,
    'words': totalWords,
    'letters': totalLetters,
    'bestMoveStreak': bestMoveStreak,
    'streak': streak.toJson(),
    'daily': {for (final e in daily.entries) e.key: e.value.toJson()},
    'badges': badges.toList()..sort(),
    'themes': unlockedThemes.toList()..sort(),
    'tileStyles': unlockedTileStyles.toList()..sort(),
    'boardStyles': unlockedBoardStyles.toList()..sort(),
    'missionsDay': missionsDay,
    'missions': [for (final m in missions) m.toJson()],
    'weekly': weekly?.toJson(),
    'bestCombo': bestCombo,
    'boardClears': boardClears,
    'achievements': achievements.toList()..sort(),
  };
}

enum AppThemeMode { system, light, dark }

class AppSettings {
  const AppSettings({
    this.sound = true,
    this.music = false,
    this.haptics = true,
    this.themeMode = AppThemeMode.system,
    this.themeId = 'classic',
    this.tileStyleId = 'classic',
    this.boardStyleId = 'plain',
    this.colorBlind = false,
    this.leftHanded = false,
    this.notifications = false,
  });

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    sound: j['sound'] as bool? ?? true,
    music: j['music'] as bool? ?? false,
    haptics: j['haptics'] as bool? ?? true,
    themeMode: AppThemeMode.values.asNameMap()[j['themeMode']] ?? AppThemeMode.system,
    themeId: j['themeId'] as String? ?? 'classic',
    tileStyleId: j['tileStyleId'] as String? ?? 'classic',
    boardStyleId: j['boardStyleId'] as String? ?? 'plain',
    colorBlind: j['colorBlind'] as bool? ?? false,
    leftHanded: j['leftHanded'] as bool? ?? false,
    notifications: j['notifications'] as bool? ?? false,
  );

  final bool sound;
  final bool music;
  final bool haptics;
  final AppThemeMode themeMode;
  final String themeId;
  final String tileStyleId;
  final String boardStyleId;
  final bool colorBlind;
  final bool leftHanded;
  final bool notifications;

  AppSettings copyWith({
    bool? sound,
    bool? music,
    bool? haptics,
    AppThemeMode? themeMode,
    String? themeId,
    String? tileStyleId,
    String? boardStyleId,
    bool? colorBlind,
    bool? leftHanded,
    bool? notifications,
  }) => AppSettings(
    sound: sound ?? this.sound,
    music: music ?? this.music,
    haptics: haptics ?? this.haptics,
    themeMode: themeMode ?? this.themeMode,
    themeId: themeId ?? this.themeId,
    tileStyleId: tileStyleId ?? this.tileStyleId,
    boardStyleId: boardStyleId ?? this.boardStyleId,
    colorBlind: colorBlind ?? this.colorBlind,
    leftHanded: leftHanded ?? this.leftHanded,
    notifications: notifications ?? this.notifications,
  );

  Map<String, dynamic> toJson() => {
    'v': 1,
    'sound': sound,
    'music': music,
    'haptics': haptics,
    'themeMode': themeMode.name,
    'themeId': themeId,
    'tileStyleId': tileStyleId,
    'boardStyleId': boardStyleId,
    'colorBlind': colorBlind,
    'leftHanded': leftHanded,
    'notifications': notifications,
  };
}

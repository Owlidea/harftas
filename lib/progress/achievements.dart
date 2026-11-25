import 'profile.dart';
import 'wordbook.dart';

enum AchievementKind {
  /// Words built in total.
  words,

  /// Distinct words in the wordbook.
  unique,

  /// Longest word ever built (letters).
  length,

  /// Most words exploded by one move.
  combo,

  /// Best classic score.
  score,

  /// Longest move streak in a game.
  moveStreak,

  /// Board emptied, in total.
  clears,

  /// Games finished.
  games,

  /// Words containing one of the language's rarest letters (Turkish J or Ğ).
  rare,

  /// Daily puzzles finished.
  daily,
}

/// A permanent badge with XP attached. Progress is derived from lifetime
/// stats, so nothing but the earned ids needs storing.
class Achievement {
  const Achievement(this.kind, this.target, this.tier);

  final AchievementKind kind;
  final int target;

  /// 1..3; decides the XP and the roman numeral in the title.
  final int tier;

  String get id => '${kind.name}_$target';
  int get rewardXp => const [100, 200, 400][tier - 1];
}

abstract final class Achievements {
  static const List<Achievement> all = [
    Achievement(AchievementKind.words, 100, 1),
    Achievement(AchievementKind.words, 500, 2),
    Achievement(AchievementKind.words, 2000, 3),
    Achievement(AchievementKind.unique, 50, 1),
    Achievement(AchievementKind.unique, 200, 2),
    Achievement(AchievementKind.unique, 500, 3),
    Achievement(AchievementKind.length, 5, 1),
    Achievement(AchievementKind.length, 6, 2),
    Achievement(AchievementKind.length, 7, 3),
    Achievement(AchievementKind.combo, 2, 1),
    Achievement(AchievementKind.combo, 3, 2),
    Achievement(AchievementKind.combo, 4, 3),
    Achievement(AchievementKind.score, 500, 1),
    Achievement(AchievementKind.score, 1000, 2),
    Achievement(AchievementKind.score, 2000, 3),
    Achievement(AchievementKind.moveStreak, 5, 1),
    Achievement(AchievementKind.moveStreak, 10, 2),
    Achievement(AchievementKind.clears, 1, 1),
    Achievement(AchievementKind.clears, 10, 2),
    Achievement(AchievementKind.games, 10, 1),
    Achievement(AchievementKind.games, 100, 2),
    Achievement(AchievementKind.rare, 1, 2),
    Achievement(AchievementKind.daily, 10, 1),
    Achievement(AchievementKind.daily, 50, 2),
  ];

  /// Letters that make a word count for [AchievementKind.rare], per word
  /// language (karar 29).
  static const Map<String, List<String>> rareLetters = {
    'tr': ['J', 'Ğ'],
    'en': ['Q', 'X', 'Z', 'J'],
  };

  /// Lifetime value the achievement measures (may exceed its target).
  /// [book] is the Kelime Defteri of [language].
  static int progress(Achievement a, PlayerProfile p, Wordbook book, [String language = 'tr']) => switch (a.kind) {
    AchievementKind.words => p.totalWords,
    AchievementKind.unique => book.uniqueCount,
    AchievementKind.length => book.entries.keys.fold(0, (m, w) => w.length > m ? w.length : m),
    AchievementKind.combo => p.bestCombo,
    AchievementKind.score => p.bestScoreAnyLanguage,
    AchievementKind.moveStreak => p.bestMoveStreak,
    AchievementKind.clears => p.boardClears,
    AchievementKind.games => p.totalGames,
    AchievementKind.rare => book.entries.keys.where((w) => (rareLetters[language] ?? const []).any(w.contains)).length,
    AchievementKind.daily => p.daily.length,
  };

  static bool reached(Achievement a, PlayerProfile p, Wordbook book, [String language = 'tr']) =>
      progress(a, p, book, language) >= a.target;

  static int earnedCount(PlayerProfile p) => all.where((a) => p.achievements.contains(a.id)).length;
}

// Progress across word languages (karar 29): one profile, per-language
// records, daily results and Kelime Defteri; one daily streak; shared
// missions whose letters fold into the language played.
import 'package:flutter_test/flutter_test.dart';
import 'package:harfblok/core/core.dart';
import 'package:harfblok/progress/achievements.dart';
import 'package:harfblok/progress/calendar.dart';
import 'package:harfblok/progress/missions.dart';
import 'package:harfblok/progress/profile.dart';
import 'package:harfblok/progress/progression.dart';
import 'package:harfblok/progress/summaries.dart';
import 'package:harfblok/progress/wordbook.dart';

final _day = DayKey(2026, 11, 25);

GameSummary _game(String language, GameMode mode, int score, List<String> words) => GameSummary(
  language: language,
  mode: mode,
  score: score,
  moves: 30,
  duration: const Duration(minutes: 3),
  words: [for (final w in words) WordResult(w, w.length)],
  usedPowerups: false,
  bestStreak: 2,
  boardClears: 0,
  continued: false,
);

void main() {
  test('classic records are kept per language; the old field stays Turkish', () {
    final p = PlayerProfile();
    final r1 = Progression.applyGameEnd(p, Wordbook(), _game('tr', GameMode.classic, 500, ['KAR']), _day);
    final r2 = Progression.applyGameEnd(p, Wordbook(), _game('en', GameMode.classic, 300, ['CAT']), _day);
    final r3 = Progression.applyGameEnd(p, Wordbook(), _game('en', GameMode.classic, 200, ['DOG']), _day);
    expect([r1.newRecord, r2.newRecord, r3.newRecord], [true, true, false]);
    expect(p.bestScore, 500);
    expect(p.bestScoreFor('en'), 300);
    expect(p.bestScoreAnyLanguage, 500);
    final back = PlayerProfile.fromJson(p.toJson());
    expect(back.bestScoreFor('en'), 300);
    expect(back.bestScoreFor('tr'), 500);
  });

  test('each language has its own daily result; the streak moves once a day', () {
    final p = PlayerProfile();
    Progression.applyGameEnd(p, Wordbook(), _game('tr', GameMode.daily, 400, ['KAR']), _day);
    expect(p.streak.current, 1);
    final en = Progression.applyGameEnd(p, Wordbook(), _game('en', GameMode.daily, 350, ['CAT']), _day);
    expect(en.dailyResult, isNotNull);
    expect(p.streak.current, 1); // not 2
    expect(p.dailyFor(_day)!.score, 400); // Turkish key unchanged: '2026-11-25'
    expect(p.dailyFor(_day, 'en')!.score, 350);
    expect(p.daily.keys, containsAll(['2026-11-25', 'en:2026-11-25']));
    expect(p.dailyResultsOf('en').keys, [_day]);
    expect(p.dailyResultsOf('tr').keys, [_day]);
    // A second English daily the same day does not replace the first.
    Progression.applyGameEnd(p, Wordbook(), _game('en', GameMode.daily, 999, ['DOG']), _day);
    expect(p.dailyFor(_day, 'en')!.score, 350);
  });

  test('a letter mission counts the letter of the language played (Ş -> S)', () {
    const m = Mission(type: MissionType.wordWithLetter, tier: MissionTier.medium, target: 2, letter: 'Ş');
    MoveSummary move(String language, List<String> words) => MoveSummary(
      language: language,
      words: [for (final w in words) WordResult(w, 3)],
      placedCells: 1,
      streakAfter: 1,
      clearedBoard: false,
    );
    expect(MissionPool.applyMove(m, move('en', ['SEA', 'TEA'])).progress, 1);
    expect(MissionPool.applyMove(m, move('tr', ['ŞEF', 'SES'])).progress, 1);
    expect(WordLanguage.english.normalize('Ç'), 'C');
    expect(WordLanguage.english.normalize('Ü'), 'U');
  });

  test('the rare-letter achievement reads the letters of the Kelime Defteri language', () {
    const a = Achievement(AchievementKind.rare, 1, 2);
    final p = PlayerProfile();
    final en = Wordbook()..add('QUIZ', 22, _day);
    final tr = Wordbook()..add('KAR', 3, _day);
    expect(Achievements.reached(a, p, en, 'en'), isTrue);
    expect(Achievements.reached(a, p, en), isFalse); // Turkish rules: J or Ğ only
    expect(Achievements.reached(a, p, tr, 'en'), isFalse);
  });

  test('daily seeds: Turkish unchanged, every other language its own', () {
    expect(Rng.dailySeedFor(2026, 11, 25, 'tr'), Rng.dailySeed(2026, 11, 25));
    expect(Rng.dailySeedFor(2026, 11, 25, 'en'), isNot(Rng.dailySeed(2026, 11, 25)));
    expect(Rng.dailySeedFor(2026, 11, 25, 'en'), Rng.dailySeedFor(2026, 11, 25, 'en'));
    expect(Rng.dailySeedFor(2026, 11, 26, 'en'), isNot(Rng.dailySeedFor(2026, 11, 25, 'en')));
  });
}

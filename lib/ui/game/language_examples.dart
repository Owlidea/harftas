import '../../core/core.dart';

/// Example words and boards the intro and the tutorial show, per word
/// language (karar 29). Every example word must be in that language's
/// dictionary (test/ui/language_examples_test.dart checks it), and the other
/// rows must not spell a word by accident.
class LanguageExamples {
  const LanguageExamples({
    required this.goal,
    required this.readingRows,
    required this.across,
    required this.down,
    required this.scoreWord,
    required this.stuckRows,
    required this.tutorialBoards,
    required this.tutorialLetters,
    required this.tutorialWords,
    required this.firstStart,
  });

  /// Intro page 1: a 3-letter word in the middle row of a 5×3 board.
  final String goal;

  /// Intro page 2: [down] in column 2 and [across] in row 2, sharing a letter.
  final List<String> readingRows;
  final String across;
  final String down;

  /// Intro page 3: a 5-letter word and how it scores.
  final String scoreWord;

  /// Intro page 4: a crowded board with no word on it.
  final List<String> stuckRows;

  /// Tutorial: the board of each of the 4 steps (8 rows) and the letter of
  /// the single-cell piece to place. Step 4 needs the hammer first.
  final List<List<String>> tutorialBoards;
  final List<String> tutorialLetters;

  /// Words the tutorial builds (step 3 builds two at once).
  final List<String> tutorialWords;

  /// Step 1 hint: “[firstStart]” + “letter” = [firstWord].
  final String firstStart;
  String get firstWord => firstStart + tutorialLetters.first;

  static LanguageExamples of(WordLanguage language) => switch (language) {
    TurkishLanguage() => turkish,
    EnglishLanguage() => english,
  };

  static const turkish = LanguageExamples(
    goal: 'KAR',
    readingRows: ['..K..', '..A..', 'NAR..', '.....'],
    across: 'NAR',
    down: 'KAR',
    scoreWord: 'KALEM',
    stuckRows: ['ZTB.Y', 'ÇUPSH', 'L.ŞGD', 'MFNÖJ'],
    tutorialBoards: [
      ['........', '........', '........', '..KA....', '........', '........', '........', '........'],
      ['........', '........', '...T....', '...A....', '........', '........', '........', '........'],
      ['..K.....', '..A.....', 'NA......', '........', '........', '........', '........', '........'],
      ['........', '........', '........', '..KAJ...', '........', '........', '........', '........'],
    ],
    tutorialLetters: ['R', 'Ş', 'R', 'R'],
    tutorialWords: ['KAR', 'TAŞ', 'KAR', 'NAR'],
    firstStart: 'KA',
  );

  static const english = LanguageExamples(
    goal: 'SUN',
    readingRows: ['..S..', '..U..', 'RUN..', '.....'],
    across: 'RUN',
    down: 'SUN',
    scoreWord: 'LEMON',
    stuckRows: ['ZTB.Y', 'QWPKH', 'L.XGD', 'MFVJC'],
    tutorialBoards: [
      ['........', '........', '........', '..SU....', '........', '........', '........', '........'],
      ['........', '........', '...T....', '...E....', '........', '........', '........', '........'],
      ['..S.....', '..U.....', 'RU......', '........', '........', '........', '........', '........'],
      ['........', '........', '........', '..SUQ...', '........', '........', '........', '........'],
    ],
    tutorialLetters: ['N', 'N', 'N', 'N'],
    tutorialWords: ['SUN', 'TEN', 'SUN', 'RUN'],
    firstStart: 'SU',
  );
}

/// "1 + 1 + 3 + 1 + 1 = 7" and "7 × 3 = 21" for [word] under [config].
({String sum, String total}) scoreLines(String word, BalanceConfig config) {
  final parts = [for (var i = 0; i < word.length; i++) config.scoreOf(word[i])];
  final base = parts.fold(0, (a, b) => a + b);
  final mult = (config.lengthMultiplierX10[word.length] ?? 10) ~/ 10;
  return (sum: '${parts.join(' + ')} = $base', total: '$base × $mult = ${base * mult}');
}

/// Points of a word built alone (letters × length multiplier).
int wordPoints(String word, BalanceConfig config) {
  var base = 0;
  for (var i = 0; i < word.length; i++) {
    base += config.scoreOf(word[i]);
  }
  return base * (config.lengthMultiplierX10[word.length] ?? 10) ~/ 10;
}

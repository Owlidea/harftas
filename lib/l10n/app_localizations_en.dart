// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get play => 'Play';

  @override
  String get continueGame => 'Continue';

  @override
  String get daily => 'Daily Puzzle';

  @override
  String dailyStreakChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days', one: '1 day');
    return '$_temp0';
  }

  @override
  String get dailyDoneChip => 'Done for today';

  @override
  String get wordbook => 'Word Book';

  @override
  String get missions => 'Missions';

  @override
  String get settings => 'Settings';

  @override
  String get stats => 'Stats';

  @override
  String get store => 'Shop';

  @override
  String get loading => 'Getting the dictionary ready…';

  @override
  String get loadError => 'Couldn\'t load the dictionary.';

  @override
  String get retry => 'Try again';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get dash => '—';

  @override
  String get score => 'Score';

  @override
  String get best => 'Best';

  @override
  String streakMultiplier(String mult) {
    return 'Streak ×$mult';
  }

  @override
  String handOf(int n, int total) {
    return 'Hand $n/$total';
  }

  @override
  String get pause => 'Pause';

  @override
  String get powerupRefresh => 'Refresh';

  @override
  String get powerupJoker => 'Joker';

  @override
  String get powerupHammer => 'Hammer';

  @override
  String get powerupRefreshDesc => 'Swaps the blocks in your hand for a new hand.';

  @override
  String get powerupJokerDesc => 'Puts any letter you want in an empty cell (0 points).';

  @override
  String get powerupHammerDesc => 'Clears one cell of your choice.';

  @override
  String get dailyNoPowerups => 'No power-ups in the Daily Puzzle — it\'s fair for everyone.';

  @override
  String get jokerPickCell => 'Tap an empty cell for the Joker';

  @override
  String get jokerPickLetter => 'Pick a letter';

  @override
  String get hammerPickCell => 'Tap a filled cell to clear it';

  @override
  String get noPowerupLeft => 'You\'re out of this power-up';

  @override
  String get stuckTitle => 'No room left';

  @override
  String get stuckBody => 'Use a power-up to keep going.';

  @override
  String get endGame => 'End game';

  @override
  String wordPoints(int points) {
    return '+$points';
  }

  @override
  String comboLabel(int n) {
    return 'Combo ×$n';
  }

  @override
  String get boardCleared => 'Grid cleared! +100';

  @override
  String get paused => 'Paused';

  @override
  String get resume => 'Resume';

  @override
  String get restart => 'Restart';

  @override
  String get restartConfirmTitle => 'Restart the game?';

  @override
  String get restartConfirmBody => 'You\'ll lose your score in this game.';

  @override
  String get mainMenu => 'Main menu';

  @override
  String get sound => 'Sound';

  @override
  String get music => 'Music';

  @override
  String get haptics => 'Vibration';

  @override
  String get gameOver => 'Game over';

  @override
  String get dailyComplete => 'Today\'s puzzle complete';

  @override
  String get newRecord => 'New best score!';

  @override
  String get wordsBuilt => 'Words';

  @override
  String get bestWord => 'Best word';

  @override
  String xpGained(int xp) {
    return '+$xp XP';
  }

  @override
  String get playAgain => 'Play again';

  @override
  String get continueWithAd => 'Continue · watch an ad';

  @override
  String get continueFree => 'Continue';

  @override
  String get continueHint => 'Clears the 2 fullest rows. Once per game.';

  @override
  String get share => 'Share';

  @override
  String levelUp(int level) {
    return 'Level $level!';
  }

  @override
  String newWordsAdded(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n new words added to your Word Book',
      one: '1 new word added to your Word Book',
    );
    return '$_temp0';
  }

  @override
  String get missionCompleted => 'Mission complete';

  @override
  String unlockedTheme(String name) {
    return 'New theme unlocked: $name';
  }

  @override
  String unlockedTileStyle(String name) {
    return 'New tile style: $name';
  }

  @override
  String earnedPowerup(String name) {
    return '+1 $name';
  }

  @override
  String streakBadge(int days) {
    return '$days-day streak badge!';
  }

  @override
  String get shieldUsedToast => 'Your streak shield was used, so your streak continues.';

  @override
  String get moves => 'Moves';

  @override
  String get today => 'Today';

  @override
  String get startDaily => 'Start';

  @override
  String get continueDaily => 'Continue where you left off';

  @override
  String get dailyRules => 'Everyone gets the same blocks. One try a day, no power-ups.';

  @override
  String todayResult(int score, int words) {
    String _temp0 = intl.Intl.pluralLogic(words, locale: localeName, other: '$words words', one: '1 word');
    return '$score points · $_temp0';
  }

  @override
  String nextPuzzleIn(int hours, int minutes) {
    return 'New puzzle in ${hours}h ${minutes}m';
  }

  @override
  String get streakCurrent => 'Streak';

  @override
  String get streakBest => 'Best';

  @override
  String daysUnit(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n days', one: '1 day');
    return '$_temp0';
  }

  @override
  String get shieldAvailable => 'You have 1 streak shield this month.';

  @override
  String get shieldUsed => 'This month\'s streak shield has been used.';

  @override
  String nextBadge(int n) {
    return 'Next badge: $n-day streak';
  }

  @override
  String get calendarEmpty => 'You haven\'t solved a Daily Puzzle yet. Your first result will show up here.';

  @override
  String get weekdaysShort => 'Mon,Tue,Wed,Thu,Fri,Sat,Sun';

  @override
  String get monthNames => 'January,February,March,April,May,June,July,August,September,October,November,December';

  @override
  String shareText(String app, String date, int score, int words, int longest, int streak, String url) {
    String _temp0 = intl.Intl.pluralLogic(words, locale: localeName, other: '$words words', one: '1 word');
    String _temp1 = intl.Intl.pluralLogic(streak, locale: localeName, other: '$streak days', one: '1 day');
    return '$app · $date\nScore $score · $_temp0 · longest word: $longest letters\nStreak: $_temp1\n$url';
  }

  @override
  String get shareCardLongest => 'Longest word';

  @override
  String lettersUnit(int n) {
    return '$n letters';
  }

  @override
  String get wordbookTitle => 'Word Book';

  @override
  String wordbookTotal(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n unique words', one: '1 unique word');
    return '$_temp0';
  }

  @override
  String lettersGroup(int n) {
    return '$n letters';
  }

  @override
  String timesBuilt(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n times', one: 'once');
    return '$_temp0';
  }

  @override
  String firstBuilt(String date) {
    return 'First: $date';
  }

  @override
  String get recordLongest => 'Longest';

  @override
  String get recordHighest => 'Highest scoring';

  @override
  String get wordbookEmpty => 'Your Word Book is empty. Every word you make is collected here.';

  @override
  String get missionsTitle => 'Missions';

  @override
  String levelN(int n) {
    return 'Level $n';
  }

  @override
  String xpProgress(int a, int b) {
    return '$a / $b XP';
  }

  @override
  String missionWordsOfLength(int length, int target) {
    return 'Make $target words with $length+ letters';
  }

  @override
  String missionCombo(int target) {
    String _temp0 = intl.Intl.pluralLogic(
      target,
      locale: localeName,
      other: 'Pop 2 words in one move · $target times',
      one: 'Pop 2 words in one move',
    );
    return '$_temp0';
  }

  @override
  String missionLetter(String letter, int target) {
    return 'Make $target words containing $letter';
  }

  @override
  String missionScore(int target) {
    return 'Score $target points in one game';
  }

  @override
  String missionStreak(int target) {
    return 'Reach a streak of $target moves';
  }

  @override
  String get missionClear => 'Clear the whole grid';

  @override
  String missionNoPowerups(int target) {
    return 'Score $target points without power-ups';
  }

  @override
  String missionDistinct(int target) {
    return 'Make $target different words in one game';
  }

  @override
  String missionReward(int xp, String powerup) {
    return '+$xp XP · 1 $powerup';
  }

  @override
  String get missionsReset => 'Missions renew every night at midnight.';

  @override
  String get done => 'Done';

  @override
  String get levelRewardsTitle => 'Level rewards';

  @override
  String get statsTitle => 'Stats';

  @override
  String get statBestScore => 'Best score';

  @override
  String get statGames => 'Games played';

  @override
  String get statWords => 'Total words';

  @override
  String get statAvgLength => 'Average word length';

  @override
  String get statBestStreak => 'Best move streak';

  @override
  String get statMostBuilt => 'Most frequent word';

  @override
  String get statDailyBest => 'Longest daily streak';

  @override
  String get statLevel => 'Level';

  @override
  String get statsEmpty => 'Your stats will show up here after your first game.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionSound => 'Sound & feel';

  @override
  String get sectionLook => 'Appearance';

  @override
  String get sectionPlay => 'Gameplay';

  @override
  String get sectionAbout => 'Support & about';

  @override
  String get theme => 'Theme';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get appearance => 'Light or dark';

  @override
  String get tileStyle => 'Tile style';

  @override
  String get colorBlind => 'Color-blind palette';

  @override
  String get colorBlindDesc => 'Blue–orange highlights; info is also shown with shapes.';

  @override
  String get leftHanded => 'Left-handed layout';

  @override
  String get leftHandedDesc => 'Moves the power-ups and the pause button to the left.';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsDesc => 'At most 1 reminder a day.';

  @override
  String get howToPlay => 'How to play';

  @override
  String get replayTutorial => 'Replay tutorial';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get restoreDone => 'Your purchases have been checked.';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyOptions => 'Ad consent options';

  @override
  String get privacyBody =>
      'You don\'t need an account; your game data is stored on this device. Google AdMob (for ads) and RevenueCat (for purchases) process limited data. You can change your ad consent here at any time.';

  @override
  String get about => 'About & licenses';

  @override
  String get locked => 'Locked';

  @override
  String unlockAtLevel(int n) {
    return 'Unlocks at level $n';
  }

  @override
  String unlockAtStreak(int n) {
    return 'Unlocks: $n-day streak';
  }

  @override
  String get themeClassic => 'Classic';

  @override
  String get themeOlive => 'Olive';

  @override
  String get themeLavender => 'Lavender';

  @override
  String get themeAmber => 'Amber';

  @override
  String get themeDawn => 'Dawn';

  @override
  String get themeSea => 'Sea';

  @override
  String get themeMidnight => 'Midnight';

  @override
  String get tileClassic => 'Classic';

  @override
  String get tileSoft => 'Soft';

  @override
  String get tileSharp => 'Sharp';

  @override
  String get tileGrain => 'Wood grain';

  @override
  String get tileMarble => 'Marble';

  @override
  String get aboutTitle => 'About';

  @override
  String aboutVersion(String v) {
    return 'Version $v';
  }

  @override
  String get aboutDictionary =>
      'Turkish dictionary: derived from Zemberek-NLP dictionary data (Apache License 2.0, © Ahmet A. Akın, Mehmet D. Akın). The common-word list is taken from the Zemberek-NLP frequency list.';

  @override
  String get aboutLicenses => 'Open-source licenses';

  @override
  String get storeTitle => 'Shop';

  @override
  String get removeAds => 'Remove ads';

  @override
  String get removeAdsDesc => 'One-time purchase. No more end-of-game ads, and ad rewards are given without the ad.';

  @override
  String get packSmall => 'Small power-up pack';

  @override
  String get packLarge => 'Large power-up pack';

  @override
  String packDesc(int n) {
    return '$n of each power-up';
  }

  @override
  String get buy => 'Buy';

  @override
  String get owned => 'Owned';

  @override
  String get storeUnavailable => 'The shop isn\'t available right now. Try again later.';

  @override
  String get earnWithAd => 'Watch an ad, get 1 power-up';

  @override
  String get earnFree => 'Get 1 power-up';

  @override
  String get purchaseThanks => 'Thank you!';

  @override
  String get yourPowerups => 'Your power-ups';

  @override
  String tutorialStep1(String start, String letter, String word) {
    return 'Drag the block into the gap: “$start” + “$letter” = $word';
  }

  @override
  String get tutorialStep2 => 'Words read top to bottom too.';

  @override
  String get tutorialStep3 => 'Make two words in one move — combo!';

  @override
  String get tutorialStep4 => 'Power-ups help when you\'re stuck. Use the Hammer to clear the marked cell.';

  @override
  String tutorialStepOf(int n) {
    return '$n/4';
  }

  @override
  String get tutorialSkip => 'Skip';

  @override
  String get tutorialGreat => 'Great!';

  @override
  String get tutorialDone => 'You\'re ready!';

  @override
  String get tutorialStart => 'Start playing';

  @override
  String get notifAskTitle => 'Don\'t miss the Daily Puzzle';

  @override
  String get notifAskBody =>
      'Can we let you know, at most once a day, when a new puzzle is ready or your streak is about to end?';

  @override
  String get notifAllow => 'Notify me';

  @override
  String get notifDeny => 'Not now';

  @override
  String get notifDailyTitle => 'The Daily Puzzle is ready';

  @override
  String get notifDailyBody => 'Today\'s blocks are waiting for you.';

  @override
  String get notifStreakTitle => 'Your streak is about to end';

  @override
  String notifStreakBody(int n) {
    return 'Solve today\'s puzzle to keep your $n-day streak.';
  }

  @override
  String a11yCell(int row, int col, String letter) {
    return 'Row $row, column $col: $letter';
  }

  @override
  String a11yEmptyCell(int row, int col) {
    return 'Row $row, column $col: empty';
  }

  @override
  String a11yBoard(int filled) {
    String _temp0 = intl.Intl.pluralLogic(
      filled,
      locale: localeName,
      other: '$filled filled cells',
      one: '1 filled cell',
    );
    return 'Game grid, $_temp0';
  }

  @override
  String a11yPiece(int n, String letters) {
    return '$n-cell block: $letters. Drag it onto the grid.';
  }

  @override
  String get a11yPlaced => 'Placed';

  @override
  String a11yPowerup(String name, int count) {
    return '$name, $count left';
  }

  @override
  String a11yScore(int score) {
    return 'Score $score';
  }

  @override
  String get genericError => 'Something went wrong.';

  @override
  String get emptyHand => 'New hand coming…';

  @override
  String get introNext => 'Next';

  @override
  String get introStart => 'Start tutorial';

  @override
  String get introGotIt => 'Got it';

  @override
  String get introSkip => 'Skip';

  @override
  String introPage(int n, int total) {
    return 'Page $n of $total';
  }

  @override
  String get introHelp => 'How to play';

  @override
  String get intro1Title => 'Goal: make words, pop them';

  @override
  String get intro1Body =>
      'Place the letter blocks from below onto the 8×8 grid. As soon as they spell a word, its letters pop and you score points. The game goes on as long as you keep room on the grid — aim for the highest score.';

  @override
  String get intro2Title => 'How are words read?';

  @override
  String get intro2Body =>
      'Letters are read only left to right and top to bottom, and a word needs at least 3 letters. A word across and a word down can share a letter.';

  @override
  String get dictNoteTr =>
      'The Turkish dictionary has base forms only, like KALEM, ARABA and GELMEK — inflected forms like EVLER or GELDİ don\'t count.';

  @override
  String get dictNoteEn =>
      'In the English dictionary, plurals and other inflected forms count too, like CATS and WALKED.';

  @override
  String get intro3Title => 'Points and multipliers';

  @override
  String get intro3Body =>
      'Each letter\'s points are shown in the corner of its tile. Longer words get a multiplier: 4 letters ×2, 5 letters ×3, 6 letters ×4… 8 letters ×6. Several words in one move make a combo, and making words move after move grows your streak multiplier. Clear the whole grid for +100.';

  @override
  String get intro4Title => 'When does the game end?';

  @override
  String get intro4Body =>
      'You always have 3 blocks in your hand, and blocks can\'t be rotated. If none of them fit on the grid, the game ends — so think ahead as you place them. If you get stuck, the Refresh, Joker and Hammer power-ups can help. A Daily Puzzle, the same for everyone, is also waiting for you every day.';

  @override
  String get homeTagline => 'Place blocks, pop words';

  @override
  String get playSubNew => 'New game';

  @override
  String playSubContinue(int score) {
    return 'Score $score · where you left off';
  }

  @override
  String get dailyReadySub => 'Today\'s puzzle is ready';

  @override
  String dailyDoneSub(int score) {
    return 'Done · $score points';
  }

  @override
  String bestChip(int n) {
    return 'Best $n';
  }

  @override
  String nextGoalRecord(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n points to your best score',
      one: '1 point to your best score',
    );
    return '$_temp0';
  }

  @override
  String nextGoalLevel(int n, int xp) {
    return '$xp XP to level $n';
  }

  @override
  String nextGoalMission(String text) {
    return 'Mission: $text';
  }

  @override
  String get monthShort => 'JAN,FEB,MAR,APR,MAY,JUN,JUL,AUG,SEP,OCT,NOV,DEC';

  @override
  String get selected => 'Selected';

  @override
  String get dailyTodayTitle => 'Today\'s puzzle';

  @override
  String timeLeft(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get ruleSame => 'Same for everyone';

  @override
  String get ruleOnce => 'One try';

  @override
  String get ruleNoPowerups => 'No power-ups';

  @override
  String dailyProgress(int n, int total, int score) {
    return 'Hand $n/$total · $score points';
  }

  @override
  String get dailyStartSub => 'About 3 minutes';

  @override
  String get dailyContinueSub => 'Pick up where you left off';

  @override
  String streakToNext(int days, int left) {
    String _temp0 = intl.Intl.pluralLogic(left, locale: localeName, other: '$left days', one: '1 day');
    return '$_temp0 to the $days-day badge';
  }

  @override
  String get allBadges => 'All streak badges unlocked!';

  @override
  String get lastSevenDays => 'Last 7 days';

  @override
  String get streakTitle => 'Your streak';

  @override
  String get calendarHint => 'Days you solve are colored in here.';

  @override
  String get storeHeroTitle => 'Play ad-free';

  @override
  String get storeHeroSub => 'One-time purchase';

  @override
  String get storeBenefit1 => 'No more end-of-game ads';

  @override
  String get storeBenefit2 => 'Continues and gifts without ads';

  @override
  String get storeBenefit3 => 'Pay once, yours forever';

  @override
  String get storeOwnedTitle => 'You\'re playing ad-free';

  @override
  String get storeOwnedSub => 'Thanks for your support.';

  @override
  String get packSmallShort => 'Small pack';

  @override
  String get packLargeShort => 'Large pack';

  @override
  String packTotal(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n power-ups', one: '1 power-up');
    return '$_temp0';
  }

  @override
  String packEachShort(int n) {
    return '$n of each';
  }

  @override
  String get packLargestTag => 'Biggest';

  @override
  String get packsTitle => 'Power-up packs';

  @override
  String get freeTitle => 'Free power-up';

  @override
  String get freeSubAd => 'Watch a short ad, earn 1';

  @override
  String get freeSubNoAds => 'A gift for ad-free players';

  @override
  String get storeFootnote =>
      'Payments are made through your App Store / Google Play account. There are no subscriptions; all purchases are one-time.';

  @override
  String get storeMobileOnly =>
      'Purchases and earning power-ups with ads are available in the Harf Kombo app for iOS and Android. On the web, the whole game is free to play.';

  @override
  String get privacyFullPolicy => 'Full privacy policy';

  @override
  String get privacyHeadline => 'What we use and why';

  @override
  String get privacyIntro =>
      'You don\'t need an account. Your game data stays on your device; limited data is processed for ads and purchases.';

  @override
  String get privacyFactAccountTitle => 'No account';

  @override
  String get privacyFactAccountBody => 'We don\'t ask for your name, email, phone number or location.';

  @override
  String get privacyFactLocalTitle => 'Only on this device';

  @override
  String get privacyFactLocalBody => 'Your scores, progress and Word Book are stored on this device.';

  @override
  String get privacyFactAdsTitle => 'Ads';

  @override
  String get privacyFactAdsBody =>
      'Google AdMob may process your advertising ID and device info to show ads. You can opt out of personalized ads.';

  @override
  String get privacyFactPurchasesTitle => 'Purchases';

  @override
  String get privacyFactPurchasesBody =>
      'Apple or Google handles the payment; we don\'t see your payment details. RevenueCat verifies your purchase and stores it with an anonymous ID.';

  @override
  String get privacyManage => 'Manage';

  @override
  String get privacyOptionsSub => 'View or change your consent';

  @override
  String get privacyFullPolicySub => 'Opens in your browser';

  @override
  String get supportTitle => 'Contact support';

  @override
  String get contactSupport => 'Support: write to us';

  @override
  String get ruleSameSub => 'Everyone solves the same puzzle';

  @override
  String get ruleOnceSub => 'Play once a day';

  @override
  String get ruleNoPowerupsSub => 'No power-ups allowed';

  @override
  String get storePremium => 'Premium';

  @override
  String get freeCta => 'Watch';

  @override
  String get freeCtaNoAds => 'Get';

  @override
  String get missionsToday => 'Today\'s missions';

  @override
  String missionsDoneCount(int a, int b) {
    return '$a/$b done';
  }

  @override
  String missionsRenewIn(String time) {
    return 'New missions in $time';
  }

  @override
  String get nextReward => 'Next reward';

  @override
  String rewardThemeShort(String name) {
    return '$name theme';
  }

  @override
  String rewardTileShort(String name) {
    return '$name tiles';
  }

  @override
  String xpToNext(int xp) {
    return '$xp XP to next level';
  }

  @override
  String get ruleSameTitle => 'Same letters';

  @override
  String get ruleSkillTitle => 'Pure skill';

  @override
  String missionScoreTotal(int target) {
    return 'Score $target points in total';
  }

  @override
  String missionDailyPuzzles(int target) {
    return 'Complete $target Daily Puzzles';
  }

  @override
  String get weeklyTitle => 'Weekly goal';

  @override
  String weeklyDaysLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n days left', one: '1 day left');
    return '$_temp0';
  }

  @override
  String get weeklyLastDay => 'Last day';

  @override
  String weeklyReward(int xp, int n) {
    return '+$xp XP · $n of each power-up';
  }

  @override
  String get weeklyDone => 'Weekly goal complete';

  @override
  String rewardBoardShort(String name) {
    return '$name finish';
  }

  @override
  String get boardStyle => 'Board finish';

  @override
  String get boardPlain => 'Plain';

  @override
  String get boardFelt => 'Felt';

  @override
  String get boardGrain => 'Wood';

  @override
  String get boardMarble => 'Marble';

  @override
  String levelUpUnlock(int level, String reward) {
    return 'Level $level · $reward unlocked';
  }

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String achievementsCount(int a, int b) {
    return '$a/$b';
  }

  @override
  String achievementUnlocked(String name) {
    return 'Achievement: $name';
  }

  @override
  String get achWords => 'Word Master';

  @override
  String get achUnique => 'Collector';

  @override
  String get achLength => 'Long Haul';

  @override
  String get achCombo => 'Combo Artist';

  @override
  String get achScore => 'Score Hunter';

  @override
  String get achMoveStreak => 'Streak Master';

  @override
  String get achClears => 'Spotless';

  @override
  String get achGames => 'Regular';

  @override
  String get achRare => 'Rare Letter';

  @override
  String get achDaily => 'Daily Devotee';

  @override
  String achWordsDesc(int n) {
    return 'Make $n words';
  }

  @override
  String achUniqueDesc(int n) {
    return 'Find $n different words';
  }

  @override
  String achLengthDesc(int n) {
    return 'Make a word with $n letters';
  }

  @override
  String achComboDesc(int n) {
    return 'Pop $n words in one move';
  }

  @override
  String achScoreDesc(int n) {
    return 'Score $n points in one game';
  }

  @override
  String achMoveStreakDesc(int n) {
    return 'Reach a streak of $n moves';
  }

  @override
  String achClearsDesc(int n) {
    return 'Clear the whole grid $n times';
  }

  @override
  String achGamesDesc(int n) {
    return 'Finish $n games';
  }

  @override
  String achRareDesc(String letters) {
    return 'Make a word with $letters';
  }

  @override
  String achDailyDesc(int n) {
    return 'Complete $n Daily Puzzles';
  }

  @override
  String get doubleXp => '2× XP';

  @override
  String get doubleXpA11y => 'Double your XP';

  @override
  String get doubleXpA11yAd => 'Watch an ad to double your XP';

  @override
  String get xpDoubledLabel => 'XP ×2';

  @override
  String streakLostTitle(int n) {
    return 'Your $n-day streak ended';
  }

  @override
  String get streakLostBody => 'You can get it back before you play today\'s puzzle.';

  @override
  String get streakRepairAd => 'Watch an ad, repair your streak';

  @override
  String get streakRepairFree => 'Repair your streak';

  @override
  String streakRepaired(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n days', one: '1 day');
    return 'Your streak is back: $_temp0';
  }

  @override
  String get giftChip => 'Gift';

  @override
  String get giftTitle => 'Daily gift';

  @override
  String giftGot(int n, String name) {
    return '+$n $name';
  }

  @override
  String get giftDoubleAd => 'Watch an ad, get one more';

  @override
  String get giftDoubleFree => 'Get one more';

  @override
  String get giftTomorrow => 'A new gift will be waiting for you tomorrow.';

  @override
  String get wordLanguage => 'Word language';

  @override
  String get wordLanguageDesc =>
      'Letters, dictionary, Daily Puzzle and Word Book all use this language. A game in progress finishes in its own language.';

  @override
  String get introLanguage => 'Which language should words be in?';

  @override
  String get orWord => 'or';

  @override
  String get aboutDictionaryEn =>
      'English dictionary: derived from the SCOWL (© Kevin Atkinson) and 12dicts (Alan Beale) word lists. Details on the licenses page.';

  @override
  String unlockStreakDays(int n) {
    return '$n-day streak';
  }
}

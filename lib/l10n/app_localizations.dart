import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('tr')];

  /// No description provided for @play.
  ///
  /// In tr, this message translates to:
  /// **'Oyna'**
  String get play;

  /// No description provided for @continueGame.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get continueGame;

  /// No description provided for @daily.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Bulmaca'**
  String get daily;

  /// No description provided for @dailyStreakChip.
  ///
  /// In tr, this message translates to:
  /// **'{count} gün'**
  String dailyStreakChip(int count);

  /// No description provided for @dailyDoneChip.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü tamam'**
  String get dailyDoneChip;

  /// No description provided for @wordbook.
  ///
  /// In tr, this message translates to:
  /// **'Defter'**
  String get wordbook;

  /// No description provided for @missions.
  ///
  /// In tr, this message translates to:
  /// **'Görevler'**
  String get missions;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @stats.
  ///
  /// In tr, this message translates to:
  /// **'İstatistikler'**
  String get stats;

  /// No description provided for @store.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza'**
  String get store;

  /// No description provided for @loading.
  ///
  /// In tr, this message translates to:
  /// **'Sözlük hazırlanıyor…'**
  String get loading;

  /// No description provided for @loadError.
  ///
  /// In tr, this message translates to:
  /// **'Sözlük yüklenemedi.'**
  String get loadError;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get back;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get ok;

  /// No description provided for @dash.
  ///
  /// In tr, this message translates to:
  /// **'—'**
  String get dash;

  /// No description provided for @score.
  ///
  /// In tr, this message translates to:
  /// **'Skor'**
  String get score;

  /// No description provided for @best.
  ///
  /// In tr, this message translates to:
  /// **'En iyi'**
  String get best;

  /// No description provided for @streakMultiplier.
  ///
  /// In tr, this message translates to:
  /// **'Seri ×{mult}'**
  String streakMultiplier(String mult);

  /// No description provided for @handOf.
  ///
  /// In tr, this message translates to:
  /// **'El {n}/{total}'**
  String handOf(int n, int total);

  /// No description provided for @pause.
  ///
  /// In tr, this message translates to:
  /// **'Duraklat'**
  String get pause;

  /// No description provided for @powerupRefresh.
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get powerupRefresh;

  /// No description provided for @powerupJoker.
  ///
  /// In tr, this message translates to:
  /// **'Joker'**
  String get powerupJoker;

  /// No description provided for @powerupHammer.
  ///
  /// In tr, this message translates to:
  /// **'Çekiç'**
  String get powerupHammer;

  /// No description provided for @powerupRefreshDesc.
  ///
  /// In tr, this message translates to:
  /// **'Eldeki blokları yeni bir elle değiştirir.'**
  String get powerupRefreshDesc;

  /// No description provided for @powerupJokerDesc.
  ///
  /// In tr, this message translates to:
  /// **'Boş bir hücreye istediğin harfi koyar (0 puan).'**
  String get powerupJokerDesc;

  /// No description provided for @powerupHammerDesc.
  ///
  /// In tr, this message translates to:
  /// **'Seçtiğin tek hücreyi siler.'**
  String get powerupHammerDesc;

  /// No description provided for @dailyNoPowerups.
  ///
  /// In tr, this message translates to:
  /// **'Günlük bulmacada güçlendirici yok — herkes için adil.'**
  String get dailyNoPowerups;

  /// No description provided for @jokerPickCell.
  ///
  /// In tr, this message translates to:
  /// **'Joker için boş bir hücreye dokun'**
  String get jokerPickCell;

  /// No description provided for @jokerPickLetter.
  ///
  /// In tr, this message translates to:
  /// **'Harf seç'**
  String get jokerPickLetter;

  /// No description provided for @hammerPickCell.
  ///
  /// In tr, this message translates to:
  /// **'Silmek için dolu bir hücreye dokun'**
  String get hammerPickCell;

  /// No description provided for @noPowerupLeft.
  ///
  /// In tr, this message translates to:
  /// **'Bu güçlendiriciden kalmadı'**
  String get noPowerupLeft;

  /// No description provided for @stuckTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yer kalmadı'**
  String get stuckTitle;

  /// No description provided for @stuckBody.
  ///
  /// In tr, this message translates to:
  /// **'Bir güçlendirici kullanarak devam edebilirsin.'**
  String get stuckBody;

  /// No description provided for @endGame.
  ///
  /// In tr, this message translates to:
  /// **'Oyunu bitir'**
  String get endGame;

  /// No description provided for @wordPoints.
  ///
  /// In tr, this message translates to:
  /// **'+{points}'**
  String wordPoints(int points);

  /// No description provided for @comboLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kombo ×{n}'**
  String comboLabel(int n);

  /// No description provided for @boardCleared.
  ///
  /// In tr, this message translates to:
  /// **'Izgara temiz! +100'**
  String get boardCleared;

  /// No description provided for @paused.
  ///
  /// In tr, this message translates to:
  /// **'Duraklatıldı'**
  String get paused;

  /// No description provided for @resume.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get resume;

  /// No description provided for @restart.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden başlat'**
  String get restart;

  /// No description provided for @restartConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden başlatılsın mı?'**
  String get restartConfirmTitle;

  /// No description provided for @restartConfirmBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu oyundaki skorun kaybolacak.'**
  String get restartConfirmBody;

  /// No description provided for @mainMenu.
  ///
  /// In tr, this message translates to:
  /// **'Ana menü'**
  String get mainMenu;

  /// No description provided for @sound.
  ///
  /// In tr, this message translates to:
  /// **'Ses'**
  String get sound;

  /// No description provided for @music.
  ///
  /// In tr, this message translates to:
  /// **'Müzik'**
  String get music;

  /// No description provided for @haptics.
  ///
  /// In tr, this message translates to:
  /// **'Titreşim'**
  String get haptics;

  /// No description provided for @gameOver.
  ///
  /// In tr, this message translates to:
  /// **'Oyun bitti'**
  String get gameOver;

  /// No description provided for @dailyComplete.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü bulmaca tamam'**
  String get dailyComplete;

  /// No description provided for @newRecord.
  ///
  /// In tr, this message translates to:
  /// **'Yeni rekor!'**
  String get newRecord;

  /// No description provided for @wordsBuilt.
  ///
  /// In tr, this message translates to:
  /// **'Kelime'**
  String get wordsBuilt;

  /// No description provided for @bestWord.
  ///
  /// In tr, this message translates to:
  /// **'En iyi kelime'**
  String get bestWord;

  /// No description provided for @xpGained.
  ///
  /// In tr, this message translates to:
  /// **'+{xp} XP'**
  String xpGained(int xp);

  /// No description provided for @playAgain.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Oyna'**
  String get playAgain;

  /// No description provided for @continueWithAd.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et · reklam izle'**
  String get continueWithAd;

  /// No description provided for @continueFree.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get continueFree;

  /// No description provided for @continueHint.
  ///
  /// In tr, this message translates to:
  /// **'En dolu 2 satır temizlenir. Oyun başına bir kez.'**
  String get continueHint;

  /// No description provided for @share.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get share;

  /// No description provided for @levelUp.
  ///
  /// In tr, this message translates to:
  /// **'Seviye {level}!'**
  String levelUp(int level);

  /// No description provided for @newWordsAdded.
  ///
  /// In tr, this message translates to:
  /// **'{n} yeni kelime deftere eklendi'**
  String newWordsAdded(int n);

  /// No description provided for @missionCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Görev tamam'**
  String get missionCompleted;

  /// No description provided for @unlockedTheme.
  ///
  /// In tr, this message translates to:
  /// **'Yeni tema açıldı: {name}'**
  String unlockedTheme(String name);

  /// No description provided for @unlockedTileStyle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni karo stili: {name}'**
  String unlockedTileStyle(String name);

  /// No description provided for @earnedPowerup.
  ///
  /// In tr, this message translates to:
  /// **'+1 {name}'**
  String earnedPowerup(String name);

  /// No description provided for @streakBadge.
  ///
  /// In tr, this message translates to:
  /// **'{days} günlük seri rozeti!'**
  String streakBadge(int days);

  /// No description provided for @shieldUsedToast.
  ///
  /// In tr, this message translates to:
  /// **'Seri koruman kullanıldı, serin devam ediyor.'**
  String get shieldUsedToast;

  /// No description provided for @moves.
  ///
  /// In tr, this message translates to:
  /// **'Hamle'**
  String get moves;

  /// No description provided for @today.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get today;

  /// No description provided for @startDaily.
  ///
  /// In tr, this message translates to:
  /// **'Başla'**
  String get startDaily;

  /// No description provided for @continueDaily.
  ///
  /// In tr, this message translates to:
  /// **'Kaldığın yerden devam et'**
  String get continueDaily;

  /// No description provided for @dailyRules.
  ///
  /// In tr, this message translates to:
  /// **'Herkes aynı blokları görür. Günde tek deneme, güçlendirici yok.'**
  String get dailyRules;

  /// No description provided for @todayResult.
  ///
  /// In tr, this message translates to:
  /// **'{score} puan · {words} kelime'**
  String todayResult(int score, int words);

  /// No description provided for @nextPuzzleIn.
  ///
  /// In tr, this message translates to:
  /// **'Yeni bulmaca {hours} sa {minutes} dk sonra'**
  String nextPuzzleIn(int hours, int minutes);

  /// No description provided for @streakCurrent.
  ///
  /// In tr, this message translates to:
  /// **'Seri'**
  String get streakCurrent;

  /// No description provided for @streakBest.
  ///
  /// In tr, this message translates to:
  /// **'En iyi'**
  String get streakBest;

  /// No description provided for @daysUnit.
  ///
  /// In tr, this message translates to:
  /// **'{n} gün'**
  String daysUnit(int n);

  /// No description provided for @shieldAvailable.
  ///
  /// In tr, this message translates to:
  /// **'Bu ay 1 seri koruma hakkın var.'**
  String get shieldAvailable;

  /// No description provided for @shieldUsed.
  ///
  /// In tr, this message translates to:
  /// **'Bu ayın seri koruması kullanıldı.'**
  String get shieldUsed;

  /// No description provided for @nextBadge.
  ///
  /// In tr, this message translates to:
  /// **'Sıradaki rozet: {n} gün'**
  String nextBadge(int n);

  /// No description provided for @calendarEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz günlük bulmaca çözmedin. İlk sonucun burada görünecek.'**
  String get calendarEmpty;

  /// No description provided for @weekdaysShort.
  ///
  /// In tr, this message translates to:
  /// **'Pzt,Sal,Çar,Per,Cum,Cmt,Paz'**
  String get weekdaysShort;

  /// No description provided for @monthNames.
  ///
  /// In tr, this message translates to:
  /// **'Ocak,Şubat,Mart,Nisan,Mayıs,Haziran,Temmuz,Ağustos,Eylül,Ekim,Kasım,Aralık'**
  String get monthNames;

  /// No description provided for @shareText.
  ///
  /// In tr, this message translates to:
  /// **'{app} · {date}\nSkor {score} · {words} kelime · en uzun {longest} harf\nSeri: {streak} gün\n{url}'**
  String shareText(String app, String date, int score, int words, int longest, int streak, String url);

  /// No description provided for @shareCardLongest.
  ///
  /// In tr, this message translates to:
  /// **'En uzun kelime'**
  String get shareCardLongest;

  /// No description provided for @lettersUnit.
  ///
  /// In tr, this message translates to:
  /// **'{n} harf'**
  String lettersUnit(int n);

  /// No description provided for @wordbookTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kelime Defteri'**
  String get wordbookTitle;

  /// No description provided for @wordbookTotal.
  ///
  /// In tr, this message translates to:
  /// **'{n} farklı kelime'**
  String wordbookTotal(int n);

  /// No description provided for @lettersGroup.
  ///
  /// In tr, this message translates to:
  /// **'{n} harfli'**
  String lettersGroup(int n);

  /// No description provided for @timesBuilt.
  ///
  /// In tr, this message translates to:
  /// **'{n} kez'**
  String timesBuilt(int n);

  /// No description provided for @firstBuilt.
  ///
  /// In tr, this message translates to:
  /// **'İlk: {date}'**
  String firstBuilt(String date);

  /// No description provided for @recordLongest.
  ///
  /// In tr, this message translates to:
  /// **'En uzun'**
  String get recordLongest;

  /// No description provided for @recordHighest.
  ///
  /// In tr, this message translates to:
  /// **'En yüksek puanlı'**
  String get recordHighest;

  /// No description provided for @wordbookEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Defterin boş. Kurduğun her kelime burada toplanır.'**
  String get wordbookEmpty;

  /// No description provided for @missionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Görevler'**
  String get missionsTitle;

  /// No description provided for @levelN.
  ///
  /// In tr, this message translates to:
  /// **'Seviye {n}'**
  String levelN(int n);

  /// No description provided for @xpProgress.
  ///
  /// In tr, this message translates to:
  /// **'{a} / {b} XP'**
  String xpProgress(int a, int b);

  /// No description provided for @missionWordsOfLength.
  ///
  /// In tr, this message translates to:
  /// **'En az {length} harfli {target} kelime kur'**
  String missionWordsOfLength(int length, int target);

  /// No description provided for @missionCombo.
  ///
  /// In tr, this message translates to:
  /// **'Tek hamlede 2 kelime patlat · {target} kez'**
  String missionCombo(int target);

  /// No description provided for @missionLetter.
  ///
  /// In tr, this message translates to:
  /// **'İçinde {letter} geçen {target} kelime kur'**
  String missionLetter(String letter, int target);

  /// No description provided for @missionScore.
  ///
  /// In tr, this message translates to:
  /// **'Tek oyunda {target} puan yap'**
  String missionScore(int target);

  /// No description provided for @missionStreak.
  ///
  /// In tr, this message translates to:
  /// **'{target} hamlelik seri yap'**
  String missionStreak(int target);

  /// No description provided for @missionClear.
  ///
  /// In tr, this message translates to:
  /// **'Izgarayı tamamen boşalt'**
  String get missionClear;

  /// No description provided for @missionNoPowerups.
  ///
  /// In tr, this message translates to:
  /// **'Güçlendirici kullanmadan {target} puan yap'**
  String missionNoPowerups(int target);

  /// No description provided for @missionDistinct.
  ///
  /// In tr, this message translates to:
  /// **'Bir oyunda {target} farklı kelime kur'**
  String missionDistinct(int target);

  /// No description provided for @missionReward.
  ///
  /// In tr, this message translates to:
  /// **'+{xp} XP · 1 {powerup}'**
  String missionReward(int xp, String powerup);

  /// No description provided for @missionsReset.
  ///
  /// In tr, this message translates to:
  /// **'Görevler her gece yarısı yenilenir.'**
  String get missionsReset;

  /// No description provided for @done.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get done;

  /// No description provided for @levelRewardsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Seviye ödülleri'**
  String get levelRewardsTitle;

  /// No description provided for @statsTitle.
  ///
  /// In tr, this message translates to:
  /// **'İstatistikler'**
  String get statsTitle;

  /// No description provided for @statBestScore.
  ///
  /// In tr, this message translates to:
  /// **'En yüksek skor'**
  String get statBestScore;

  /// No description provided for @statGames.
  ///
  /// In tr, this message translates to:
  /// **'Toplam oyun'**
  String get statGames;

  /// No description provided for @statWords.
  ///
  /// In tr, this message translates to:
  /// **'Toplam kelime'**
  String get statWords;

  /// No description provided for @statAvgLength.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama kelime uzunluğu'**
  String get statAvgLength;

  /// No description provided for @statBestStreak.
  ///
  /// In tr, this message translates to:
  /// **'En iyi hamle serisi'**
  String get statBestStreak;

  /// No description provided for @statMostBuilt.
  ///
  /// In tr, this message translates to:
  /// **'En çok kurulan kelime'**
  String get statMostBuilt;

  /// No description provided for @statDailyBest.
  ///
  /// In tr, this message translates to:
  /// **'En uzun günlük seri'**
  String get statDailyBest;

  /// No description provided for @statLevel.
  ///
  /// In tr, this message translates to:
  /// **'Seviye'**
  String get statLevel;

  /// No description provided for @statsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'İlk oyunundan sonra istatistiklerin burada.'**
  String get statsEmpty;

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// No description provided for @sectionSound.
  ///
  /// In tr, this message translates to:
  /// **'Ses ve his'**
  String get sectionSound;

  /// No description provided for @sectionLook.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get sectionLook;

  /// No description provided for @sectionPlay.
  ///
  /// In tr, this message translates to:
  /// **'Oynanış'**
  String get sectionPlay;

  /// No description provided for @sectionAbout.
  ///
  /// In tr, this message translates to:
  /// **'Destek ve hakkında'**
  String get sectionAbout;

  /// No description provided for @theme.
  ///
  /// In tr, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @themeModeSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get themeModeDark;

  /// No description provided for @appearance.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm modu'**
  String get appearance;

  /// No description provided for @tileStyle.
  ///
  /// In tr, this message translates to:
  /// **'Karo stili'**
  String get tileStyle;

  /// No description provided for @colorBlind.
  ///
  /// In tr, this message translates to:
  /// **'Renk körlüğü paleti'**
  String get colorBlind;

  /// No description provided for @colorBlindDesc.
  ///
  /// In tr, this message translates to:
  /// **'Mavi–turuncu vurgu; bilgi ayrıca şekille de verilir.'**
  String get colorBlindDesc;

  /// No description provided for @leftHanded.
  ///
  /// In tr, this message translates to:
  /// **'Sol el düzeni'**
  String get leftHanded;

  /// No description provided for @leftHandedDesc.
  ///
  /// In tr, this message translates to:
  /// **'Güçlendiriciler ve duraklat düğmesi sola alınır.'**
  String get leftHandedDesc;

  /// No description provided for @notifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notifications;

  /// No description provided for @notificationsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Günde en fazla 1 hatırlatma.'**
  String get notificationsDesc;

  /// No description provided for @howToPlay.
  ///
  /// In tr, this message translates to:
  /// **'Nasıl oynanır'**
  String get howToPlay;

  /// No description provided for @replayTutorial.
  ///
  /// In tr, this message translates to:
  /// **'Öğreticiyi tekrar oyna'**
  String get replayTutorial;

  /// No description provided for @restorePurchases.
  ///
  /// In tr, this message translates to:
  /// **'Satın almaları geri yükle'**
  String get restorePurchases;

  /// No description provided for @restoreDone.
  ///
  /// In tr, this message translates to:
  /// **'Satın almalar kontrol edildi.'**
  String get restoreDone;

  /// No description provided for @privacy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik'**
  String get privacy;

  /// No description provided for @privacyOptions.
  ///
  /// In tr, this message translates to:
  /// **'Reklam izin tercihleri'**
  String get privacyOptions;

  /// No description provided for @privacyBody.
  ///
  /// In tr, this message translates to:
  /// **'Hesap açman gerekmez; oyun verilerin bu cihazda saklanır. Reklamlar için Google AdMob, satın almalar için RevenueCat sınırlı veri işler. Reklam izinlerini istediğin zaman buradan değiştirebilirsin.'**
  String get privacyBody;

  /// No description provided for @about.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında ve lisanslar'**
  String get about;

  /// No description provided for @locked.
  ///
  /// In tr, this message translates to:
  /// **'Kilitli'**
  String get locked;

  /// No description provided for @unlockAtLevel.
  ///
  /// In tr, this message translates to:
  /// **'Açılır: Seviye {n}'**
  String unlockAtLevel(int n);

  /// No description provided for @unlockAtStreak.
  ///
  /// In tr, this message translates to:
  /// **'Açılır: {n} günlük seri'**
  String unlockAtStreak(int n);

  /// No description provided for @themeClassic.
  ///
  /// In tr, this message translates to:
  /// **'Klasik'**
  String get themeClassic;

  /// No description provided for @themeOlive.
  ///
  /// In tr, this message translates to:
  /// **'Zeytin'**
  String get themeOlive;

  /// No description provided for @themeLavender.
  ///
  /// In tr, this message translates to:
  /// **'Lavanta'**
  String get themeLavender;

  /// No description provided for @themeAmber.
  ///
  /// In tr, this message translates to:
  /// **'Kehribar'**
  String get themeAmber;

  /// No description provided for @themeDawn.
  ///
  /// In tr, this message translates to:
  /// **'Şafak'**
  String get themeDawn;

  /// No description provided for @themeSea.
  ///
  /// In tr, this message translates to:
  /// **'Deniz'**
  String get themeSea;

  /// No description provided for @themeMidnight.
  ///
  /// In tr, this message translates to:
  /// **'Gece Yarısı'**
  String get themeMidnight;

  /// No description provided for @tileClassic.
  ///
  /// In tr, this message translates to:
  /// **'Klasik'**
  String get tileClassic;

  /// No description provided for @tileSoft.
  ///
  /// In tr, this message translates to:
  /// **'Yumuşak'**
  String get tileSoft;

  /// No description provided for @tileSharp.
  ///
  /// In tr, this message translates to:
  /// **'Keskin'**
  String get tileSharp;

  /// No description provided for @tileGrain.
  ///
  /// In tr, this message translates to:
  /// **'Ahşap damar'**
  String get tileGrain;

  /// No description provided for @tileMarble.
  ///
  /// In tr, this message translates to:
  /// **'Mermer'**
  String get tileMarble;

  /// No description provided for @aboutTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hakkında'**
  String get aboutTitle;

  /// No description provided for @aboutVersion.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm {v}'**
  String aboutVersion(String v);

  /// No description provided for @aboutDictionary.
  ///
  /// In tr, this message translates to:
  /// **'Sözlük: Zemberek-NLP sözlük verisinden türetildi (Apache License 2.0, © Ahmet A. Akın, Mehmet D. Akın). Yaygın kelime listesi Zemberek-NLP frekans listesinden alındı.'**
  String get aboutDictionary;

  /// No description provided for @aboutLicenses.
  ///
  /// In tr, this message translates to:
  /// **'Açık kaynak lisansları'**
  String get aboutLicenses;

  /// No description provided for @storeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza'**
  String get storeTitle;

  /// No description provided for @removeAds.
  ///
  /// In tr, this message translates to:
  /// **'Reklamları kaldır'**
  String get removeAds;

  /// No description provided for @removeAdsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Tek seferlik. Oyun sonu reklamları kalkar; ödüllü reklam ödülleri reklamsız verilir.'**
  String get removeAdsDesc;

  /// No description provided for @packSmall.
  ///
  /// In tr, this message translates to:
  /// **'Küçük güçlendirici paketi'**
  String get packSmall;

  /// No description provided for @packLarge.
  ///
  /// In tr, this message translates to:
  /// **'Büyük güçlendirici paketi'**
  String get packLarge;

  /// No description provided for @packDesc.
  ///
  /// In tr, this message translates to:
  /// **'Her güçlendiriciden {n} adet'**
  String packDesc(int n);

  /// No description provided for @buy.
  ///
  /// In tr, this message translates to:
  /// **'Satın al'**
  String get buy;

  /// No description provided for @owned.
  ///
  /// In tr, this message translates to:
  /// **'Sahipsin'**
  String get owned;

  /// No description provided for @storeUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza şu an kullanılamıyor. Daha sonra tekrar dene.'**
  String get storeUnavailable;

  /// No description provided for @earnWithAd.
  ///
  /// In tr, this message translates to:
  /// **'Reklam izle, 1 güçlendirici kazan'**
  String get earnWithAd;

  /// No description provided for @earnFree.
  ///
  /// In tr, this message translates to:
  /// **'1 güçlendirici al'**
  String get earnFree;

  /// No description provided for @purchaseThanks.
  ///
  /// In tr, this message translates to:
  /// **'Teşekkürler!'**
  String get purchaseThanks;

  /// No description provided for @yourPowerups.
  ///
  /// In tr, this message translates to:
  /// **'Güçlendiricilerin'**
  String get yourPowerups;

  /// No description provided for @tutorialStep1.
  ///
  /// In tr, this message translates to:
  /// **'Bloğu sürükle ve boşluğa bırak: “KA” + “R” = KAR'**
  String get tutorialStep1;

  /// No description provided for @tutorialStep2.
  ///
  /// In tr, this message translates to:
  /// **'Kelimeler yukarıdan aşağıya da okunur.'**
  String get tutorialStep2;

  /// No description provided for @tutorialStep3.
  ///
  /// In tr, this message translates to:
  /// **'Tek hamlede iki kelime kur — kombo!'**
  String get tutorialStep3;

  /// No description provided for @tutorialStep4.
  ///
  /// In tr, this message translates to:
  /// **'Takıldığında güçlendiriciler yardım eder. Çekiç ile işaretli hücreyi sil.'**
  String get tutorialStep4;

  /// No description provided for @tutorialStepOf.
  ///
  /// In tr, this message translates to:
  /// **'{n}/4'**
  String tutorialStepOf(int n);

  /// No description provided for @tutorialSkip.
  ///
  /// In tr, this message translates to:
  /// **'Atla'**
  String get tutorialSkip;

  /// No description provided for @tutorialGreat.
  ///
  /// In tr, this message translates to:
  /// **'Harika!'**
  String get tutorialGreat;

  /// No description provided for @tutorialDone.
  ///
  /// In tr, this message translates to:
  /// **'Hazırsın!'**
  String get tutorialDone;

  /// No description provided for @tutorialStart.
  ///
  /// In tr, this message translates to:
  /// **'Oynamaya başla'**
  String get tutorialStart;

  /// No description provided for @notifAskTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük bulmacayı kaçırma'**
  String get notifAskTitle;

  /// No description provided for @notifAskBody.
  ///
  /// In tr, this message translates to:
  /// **'Yeni bulmaca hazır olduğunda ya da serin bozulmak üzereyken günde en fazla bir kez haber verelim mi?'**
  String get notifAskBody;

  /// No description provided for @notifAllow.
  ///
  /// In tr, this message translates to:
  /// **'Haber ver'**
  String get notifAllow;

  /// No description provided for @notifDeny.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi değil'**
  String get notifDeny;

  /// No description provided for @notifDailyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük bulmaca hazır'**
  String get notifDailyTitle;

  /// No description provided for @notifDailyBody.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün blokları seni bekliyor.'**
  String get notifDailyBody;

  /// No description provided for @notifStreakTitle.
  ///
  /// In tr, this message translates to:
  /// **'Serin bozulmak üzere'**
  String get notifStreakTitle;

  /// No description provided for @notifStreakBody.
  ///
  /// In tr, this message translates to:
  /// **'{n} günlük serini korumak için bugünkü bulmacayı çöz.'**
  String notifStreakBody(int n);

  /// No description provided for @a11yCell.
  ///
  /// In tr, this message translates to:
  /// **'Satır {row}, sütun {col}: {letter}'**
  String a11yCell(int row, int col, String letter);

  /// No description provided for @a11yEmptyCell.
  ///
  /// In tr, this message translates to:
  /// **'Satır {row}, sütun {col}: boş'**
  String a11yEmptyCell(int row, int col);

  /// No description provided for @a11yBoard.
  ///
  /// In tr, this message translates to:
  /// **'Oyun ızgarası, {filled} dolu hücre'**
  String a11yBoard(int filled);

  /// No description provided for @a11yPiece.
  ///
  /// In tr, this message translates to:
  /// **'{n} hücreli blok: {letters}. Sürükleyip ızgaraya bırak.'**
  String a11yPiece(int n, String letters);

  /// No description provided for @a11yPlaced.
  ///
  /// In tr, this message translates to:
  /// **'Yerleştirildi'**
  String get a11yPlaced;

  /// No description provided for @a11yPowerup.
  ///
  /// In tr, this message translates to:
  /// **'{name}, {count} adet'**
  String a11yPowerup(String name, int count);

  /// No description provided for @a11yScore.
  ///
  /// In tr, this message translates to:
  /// **'Skor {score}'**
  String a11yScore(int score);

  /// No description provided for @genericError.
  ///
  /// In tr, this message translates to:
  /// **'Bir şeyler ters gitti.'**
  String get genericError;

  /// No description provided for @emptyHand.
  ///
  /// In tr, this message translates to:
  /// **'Yeni el geliyor…'**
  String get emptyHand;

  /// No description provided for @introNext.
  ///
  /// In tr, this message translates to:
  /// **'İleri'**
  String get introNext;

  /// No description provided for @introStart.
  ///
  /// In tr, this message translates to:
  /// **'Öğreticiyle başla'**
  String get introStart;

  /// No description provided for @introGotIt.
  ///
  /// In tr, this message translates to:
  /// **'Anladım'**
  String get introGotIt;

  /// No description provided for @introSkip.
  ///
  /// In tr, this message translates to:
  /// **'Atla'**
  String get introSkip;

  /// No description provided for @introPage.
  ///
  /// In tr, this message translates to:
  /// **'Sayfa {n} / {total}'**
  String introPage(int n, int total);

  /// No description provided for @introHelp.
  ///
  /// In tr, this message translates to:
  /// **'Nasıl oynanır'**
  String get introHelp;

  /// No description provided for @intro1Title.
  ///
  /// In tr, this message translates to:
  /// **'Amaç: kelime kur, patlat'**
  String get intro1Title;

  /// No description provided for @intro1Body.
  ///
  /// In tr, this message translates to:
  /// **'Alttan gelen harfli blokları 8×8 ızgaraya yerleştir. Bir kelime oluştuğu anda harfleri patlar ve puan kazanırsın. Izgarada yer açık tuttukça oyun sürer — hedefin en yüksek skoru yapmak.'**
  String get intro1Body;

  /// No description provided for @intro2Title.
  ///
  /// In tr, this message translates to:
  /// **'Kelimeler nasıl okunur?'**
  String get intro2Title;

  /// No description provided for @intro2Body.
  ///
  /// In tr, this message translates to:
  /// **'Harfler yalnızca soldan sağa ve yukarıdan aşağıya okunur; en az 3 harf gerekir. Yatay ve dikey iki kelime aynı harfi paylaşabilir. Sözlükte temel biçimler var: KALEM, ARABA, GELMEK gibi — EVLER ya da GELDİ gibi çekimli hâller sayılmaz.'**
  String get intro2Body;

  /// No description provided for @intro3Title.
  ///
  /// In tr, this message translates to:
  /// **'Puan ve çarpanlar'**
  String get intro3Title;

  /// No description provided for @intro3Body.
  ///
  /// In tr, this message translates to:
  /// **'Her harfin puanı karonun köşesinde yazar. Uzun kelimeler katlanır: 4 harf ×2, 5 harf ×3, 6 harf ×4… 8 harf ×6. Tek hamlede birden çok kelime kombo yapar; art arda kelime kurarsan seri çarpanın büyür. Izgarayı tamamen boşaltırsan +100.'**
  String get intro3Body;

  /// No description provided for @intro4Title.
  ///
  /// In tr, this message translates to:
  /// **'Oyun ne zaman biter?'**
  String get intro4Title;

  /// No description provided for @intro4Body.
  ///
  /// In tr, this message translates to:
  /// **'Elinde her seferinde 3 blok olur ve bloklar döndürülemez. Hiçbiri ızgaraya sığmazsa oyun biter — o yüzden yerleştirirken ileriyi düşün. Takılırsan Yenile, Joker ve Çekiç güçlendiricileri yardım eder. Her gün herkes için aynı olan bir Günlük Bulmaca da seni bekler.'**
  String get intro4Body;

  /// No description provided for @homeTagline.
  ///
  /// In tr, this message translates to:
  /// **'Blokları diz, kelimeyi patlat'**
  String get homeTagline;

  /// No description provided for @playSubNew.
  ///
  /// In tr, this message translates to:
  /// **'Yeni oyun'**
  String get playSubNew;

  /// No description provided for @playSubContinue.
  ///
  /// In tr, this message translates to:
  /// **'Skor {score} · kaldığın yerden'**
  String playSubContinue(int score);

  /// No description provided for @dailyReadySub.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün bulmacası hazır'**
  String get dailyReadySub;

  /// No description provided for @dailyDoneSub.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı · {score} puan'**
  String dailyDoneSub(int score);

  /// No description provided for @bestChip.
  ///
  /// In tr, this message translates to:
  /// **'En iyi {n}'**
  String bestChip(int n);

  /// No description provided for @nextGoalRecord.
  ///
  /// In tr, this message translates to:
  /// **'Rekora {n} puan kaldı'**
  String nextGoalRecord(int n);

  /// No description provided for @nextGoalLevel.
  ///
  /// In tr, this message translates to:
  /// **'Seviye {n} için {xp} XP kaldı'**
  String nextGoalLevel(int n, int xp);

  /// No description provided for @nextGoalMission.
  ///
  /// In tr, this message translates to:
  /// **'Görev: {text}'**
  String nextGoalMission(String text);

  /// No description provided for @monthShort.
  ///
  /// In tr, this message translates to:
  /// **'OCA,ŞUB,MAR,NİS,MAY,HAZ,TEM,AĞU,EYL,EKİ,KAS,ARA'**
  String get monthShort;

  /// No description provided for @selected.
  ///
  /// In tr, this message translates to:
  /// **'Seçili'**
  String get selected;

  /// No description provided for @dailyTodayTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün bulmacası'**
  String get dailyTodayTitle;

  /// No description provided for @timeLeft.
  ///
  /// In tr, this message translates to:
  /// **'{hours} sa {minutes} dk'**
  String timeLeft(int hours, int minutes);

  /// No description provided for @ruleSame.
  ///
  /// In tr, this message translates to:
  /// **'Herkese aynı'**
  String get ruleSame;

  /// No description provided for @ruleOnce.
  ///
  /// In tr, this message translates to:
  /// **'Tek deneme'**
  String get ruleOnce;

  /// No description provided for @ruleNoPowerups.
  ///
  /// In tr, this message translates to:
  /// **'Güçlendirici yok'**
  String get ruleNoPowerups;

  /// No description provided for @dailyProgress.
  ///
  /// In tr, this message translates to:
  /// **'El {n}/{total} · {score} puan'**
  String dailyProgress(int n, int total, int score);

  /// No description provided for @dailyStartSub.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşık 3 dakika'**
  String get dailyStartSub;

  /// No description provided for @dailyContinueSub.
  ///
  /// In tr, this message translates to:
  /// **'Kaldığın yerden'**
  String get dailyContinueSub;

  /// No description provided for @streakToNext.
  ///
  /// In tr, this message translates to:
  /// **'{days} günlük rozete {left} gün kaldı'**
  String streakToNext(int days, int left);

  /// No description provided for @allBadges.
  ///
  /// In tr, this message translates to:
  /// **'Tüm seri rozetleri açıldı!'**
  String get allBadges;

  /// No description provided for @lastSevenDays.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 gün'**
  String get lastSevenDays;

  /// No description provided for @streakTitle.
  ///
  /// In tr, this message translates to:
  /// **'Serin'**
  String get streakTitle;

  /// No description provided for @calendarHint.
  ///
  /// In tr, this message translates to:
  /// **'Çözdüğün günler burada renklenir.'**
  String get calendarHint;

  /// No description provided for @storeHeroTitle.
  ///
  /// In tr, this message translates to:
  /// **'Reklamsız oyna'**
  String get storeHeroTitle;

  /// No description provided for @storeHeroSub.
  ///
  /// In tr, this message translates to:
  /// **'Tek seferlik satın alma'**
  String get storeHeroSub;

  /// No description provided for @storeBenefit1.
  ///
  /// In tr, this message translates to:
  /// **'Oyun sonu reklamları kalkar'**
  String get storeBenefit1;

  /// No description provided for @storeBenefit2.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et ve hediyeler reklamsız'**
  String get storeBenefit2;

  /// No description provided for @storeBenefit3.
  ///
  /// In tr, this message translates to:
  /// **'Bir kez öde, hep senin'**
  String get storeBenefit3;

  /// No description provided for @storeOwnedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Reklamsız sürümdesin'**
  String get storeOwnedTitle;

  /// No description provided for @storeOwnedSub.
  ///
  /// In tr, this message translates to:
  /// **'Desteğin için teşekkürler.'**
  String get storeOwnedSub;

  /// No description provided for @packSmallShort.
  ///
  /// In tr, this message translates to:
  /// **'Küçük paket'**
  String get packSmallShort;

  /// No description provided for @packLargeShort.
  ///
  /// In tr, this message translates to:
  /// **'Büyük paket'**
  String get packLargeShort;

  /// No description provided for @packTotal.
  ///
  /// In tr, this message translates to:
  /// **'{n} güçlendirici'**
  String packTotal(int n);

  /// No description provided for @packEachShort.
  ///
  /// In tr, this message translates to:
  /// **'her birinden {n}'**
  String packEachShort(int n);

  /// No description provided for @packLargestTag.
  ///
  /// In tr, this message translates to:
  /// **'En büyük'**
  String get packLargestTag;

  /// No description provided for @packsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Güçlendirici paketleri'**
  String get packsTitle;

  /// No description provided for @freeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz güçlendirici'**
  String get freeTitle;

  /// No description provided for @freeSubAd.
  ///
  /// In tr, this message translates to:
  /// **'Kısa bir reklam izle, 1 tane kazan'**
  String get freeSubAd;

  /// No description provided for @freeSubNoAds.
  ///
  /// In tr, this message translates to:
  /// **'Reklamsız sürüme hediye'**
  String get freeSubNoAds;

  /// No description provided for @storeFootnote.
  ///
  /// In tr, this message translates to:
  /// **'Ödemeler App Store / Google Play hesabın üzerinden alınır. Abonelik yoktur; tüm satın almalar tek seferliktir.'**
  String get storeFootnote;

  /// No description provided for @storeMobileOnly.
  ///
  /// In tr, this message translates to:
  /// **'Satın almalar ve reklamla güç kazanma Harf Kombo\'nun iOS ve Android uygulamasında. Web sürümünde oyunun tamamı ücretsiz oynanır.'**
  String get storeMobileOnly;

  /// No description provided for @privacyFullPolicy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik politikasının tamamı'**
  String get privacyFullPolicy;

  /// No description provided for @privacyHeadline.
  ///
  /// In tr, this message translates to:
  /// **'Neyi neden kullanıyoruz'**
  String get privacyHeadline;

  /// No description provided for @privacyIntro.
  ///
  /// In tr, this message translates to:
  /// **'Hesap açman gerekmez. Oyun verilerin cihazında kalır; reklam ve satın almalar için sınırlı veri işlenir.'**
  String get privacyIntro;

  /// No description provided for @privacyFactAccountTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap yok'**
  String get privacyFactAccountTitle;

  /// No description provided for @privacyFactAccountBody.
  ///
  /// In tr, this message translates to:
  /// **'Ad, e-posta, telefon numarası ya da konum istenmez.'**
  String get privacyFactAccountBody;

  /// No description provided for @privacyFactLocalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yalnızca bu cihazda'**
  String get privacyFactLocalTitle;

  /// No description provided for @privacyFactLocalBody.
  ///
  /// In tr, this message translates to:
  /// **'Skorların, ilerlemen ve kelime defterin bu cihazda saklanır.'**
  String get privacyFactLocalBody;

  /// No description provided for @privacyFactAdsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Reklamlar'**
  String get privacyFactAdsTitle;

  /// No description provided for @privacyFactAdsBody.
  ///
  /// In tr, this message translates to:
  /// **'Google AdMob, reklam göstermek için reklam kimliğini ve cihaz bilgisini işleyebilir. Kişiselleştirilmiş reklamı reddedebilirsin.'**
  String get privacyFactAdsBody;

  /// No description provided for @privacyFactPurchasesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Satın almalar'**
  String get privacyFactPurchasesTitle;

  /// No description provided for @privacyFactPurchasesBody.
  ///
  /// In tr, this message translates to:
  /// **'Ödemeyi Apple veya Google alır; ödeme bilgini görmeyiz. RevenueCat satın almanı doğrular ve anonim bir kimlikle saklar.'**
  String get privacyFactPurchasesBody;

  /// No description provided for @privacyManage.
  ///
  /// In tr, this message translates to:
  /// **'Yönet'**
  String get privacyManage;

  /// No description provided for @privacyOptionsSub.
  ///
  /// In tr, this message translates to:
  /// **'İzinleri gör ya da değiştir'**
  String get privacyOptionsSub;

  /// No description provided for @privacyFullPolicySub.
  ///
  /// In tr, this message translates to:
  /// **'Tarayıcıda açılır'**
  String get privacyFullPolicySub;

  /// No description provided for @supportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Destek ekibine yaz'**
  String get supportTitle;

  /// No description provided for @contactSupport.
  ///
  /// In tr, this message translates to:
  /// **'Destek: bize yazın'**
  String get contactSupport;

  /// No description provided for @ruleSameSub.
  ///
  /// In tr, this message translates to:
  /// **'Herkes aynı bulmacayı çözer'**
  String get ruleSameSub;

  /// No description provided for @ruleOnceSub.
  ///
  /// In tr, this message translates to:
  /// **'Günde bir kez oynanır'**
  String get ruleOnceSub;

  /// No description provided for @ruleNoPowerupsSub.
  ///
  /// In tr, this message translates to:
  /// **'Güçlendirici kullanılmaz'**
  String get ruleNoPowerupsSub;

  /// No description provided for @storePremium.
  ///
  /// In tr, this message translates to:
  /// **'Premium'**
  String get storePremium;

  /// No description provided for @freeCta.
  ///
  /// In tr, this message translates to:
  /// **'İzle'**
  String get freeCta;

  /// No description provided for @freeCtaNoAds.
  ///
  /// In tr, this message translates to:
  /// **'Al'**
  String get freeCtaNoAds;

  /// No description provided for @missionsToday.
  ///
  /// In tr, this message translates to:
  /// **'Günün görevleri'**
  String get missionsToday;

  /// No description provided for @missionsDoneCount.
  ///
  /// In tr, this message translates to:
  /// **'{a}/{b} tamamlandı'**
  String missionsDoneCount(int a, int b);

  /// No description provided for @missionsRenewIn.
  ///
  /// In tr, this message translates to:
  /// **'{time} sonra yenilenir'**
  String missionsRenewIn(String time);

  /// No description provided for @nextReward.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki ödül'**
  String get nextReward;

  /// No description provided for @rewardThemeShort.
  ///
  /// In tr, this message translates to:
  /// **'{name} teması'**
  String rewardThemeShort(String name);

  /// No description provided for @rewardTileShort.
  ///
  /// In tr, this message translates to:
  /// **'{name} karolar'**
  String rewardTileShort(String name);

  /// No description provided for @xpToNext.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki seviyeye {xp} XP'**
  String xpToNext(int xp);

  /// No description provided for @ruleSameTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aynı harfler'**
  String get ruleSameTitle;

  /// No description provided for @ruleSkillTitle.
  ///
  /// In tr, this message translates to:
  /// **'Saf beceri'**
  String get ruleSkillTitle;

  /// No description provided for @missionScoreTotal.
  ///
  /// In tr, this message translates to:
  /// **'Toplam {target} puan topla'**
  String missionScoreTotal(int target);

  /// No description provided for @missionDailyPuzzles.
  ///
  /// In tr, this message translates to:
  /// **'{target} günlük bulmaca tamamla'**
  String missionDailyPuzzles(int target);

  /// No description provided for @weeklyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık hedef'**
  String get weeklyTitle;

  /// No description provided for @weeklyDaysLeft.
  ///
  /// In tr, this message translates to:
  /// **'{n} gün kaldı'**
  String weeklyDaysLeft(int n);

  /// No description provided for @weeklyLastDay.
  ///
  /// In tr, this message translates to:
  /// **'Son gün'**
  String get weeklyLastDay;

  /// No description provided for @weeklyReward.
  ///
  /// In tr, this message translates to:
  /// **'+{xp} XP · her güçlendiriciden {n}'**
  String weeklyReward(int xp, int n);

  /// No description provided for @weeklyDone.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık hedef tamam'**
  String get weeklyDone;

  /// No description provided for @rewardBoardShort.
  ///
  /// In tr, this message translates to:
  /// **'{name} zemin'**
  String rewardBoardShort(String name);

  /// No description provided for @boardStyle.
  ///
  /// In tr, this message translates to:
  /// **'Tahta zemini'**
  String get boardStyle;

  /// No description provided for @boardPlain.
  ///
  /// In tr, this message translates to:
  /// **'Düz'**
  String get boardPlain;

  /// No description provided for @boardFelt.
  ///
  /// In tr, this message translates to:
  /// **'Keçe'**
  String get boardFelt;

  /// No description provided for @boardGrain.
  ///
  /// In tr, this message translates to:
  /// **'Ahşap'**
  String get boardGrain;

  /// No description provided for @boardMarble.
  ///
  /// In tr, this message translates to:
  /// **'Mermer'**
  String get boardMarble;

  /// No description provided for @levelUpUnlock.
  ///
  /// In tr, this message translates to:
  /// **'Seviye {level} · {reward} açıldı'**
  String levelUpUnlock(int level, String reward);

  /// No description provided for @achievementsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Başarımlar'**
  String get achievementsTitle;

  /// No description provided for @achievementsCount.
  ///
  /// In tr, this message translates to:
  /// **'{a}/{b}'**
  String achievementsCount(int a, int b);

  /// No description provided for @achievementUnlocked.
  ///
  /// In tr, this message translates to:
  /// **'Başarım: {name}'**
  String achievementUnlocked(String name);

  /// No description provided for @achWords.
  ///
  /// In tr, this message translates to:
  /// **'Kelime Ustası'**
  String get achWords;

  /// No description provided for @achUnique.
  ///
  /// In tr, this message translates to:
  /// **'Koleksiyoncu'**
  String get achUnique;

  /// No description provided for @achLength.
  ///
  /// In tr, this message translates to:
  /// **'Uzun Soluk'**
  String get achLength;

  /// No description provided for @achCombo.
  ///
  /// In tr, this message translates to:
  /// **'Kombocu'**
  String get achCombo;

  /// No description provided for @achScore.
  ///
  /// In tr, this message translates to:
  /// **'Skor Avcısı'**
  String get achScore;

  /// No description provided for @achMoveStreak.
  ///
  /// In tr, this message translates to:
  /// **'Seri Ustası'**
  String get achMoveStreak;

  /// No description provided for @achClears.
  ///
  /// In tr, this message translates to:
  /// **'Tertemiz'**
  String get achClears;

  /// No description provided for @achGames.
  ///
  /// In tr, this message translates to:
  /// **'Müdavim'**
  String get achGames;

  /// No description provided for @achRare.
  ///
  /// In tr, this message translates to:
  /// **'Nadir Harf'**
  String get achRare;

  /// No description provided for @achDaily.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Sadık'**
  String get achDaily;

  /// No description provided for @achWordsDesc.
  ///
  /// In tr, this message translates to:
  /// **'{n} kelime kur'**
  String achWordsDesc(int n);

  /// No description provided for @achUniqueDesc.
  ///
  /// In tr, this message translates to:
  /// **'{n} farklı kelime bul'**
  String achUniqueDesc(int n);

  /// No description provided for @achLengthDesc.
  ///
  /// In tr, this message translates to:
  /// **'{n} harfli bir kelime kur'**
  String achLengthDesc(int n);

  /// No description provided for @achComboDesc.
  ///
  /// In tr, this message translates to:
  /// **'Tek hamlede {n} kelime patlat'**
  String achComboDesc(int n);

  /// No description provided for @achScoreDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bir oyunda {n} puan yap'**
  String achScoreDesc(int n);

  /// No description provided for @achMoveStreakDesc.
  ///
  /// In tr, this message translates to:
  /// **'{n} hamlelik seri yap'**
  String achMoveStreakDesc(int n);

  /// No description provided for @achClearsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Izgarayı {n} kez tamamen boşalt'**
  String achClearsDesc(int n);

  /// No description provided for @achGamesDesc.
  ///
  /// In tr, this message translates to:
  /// **'{n} oyun bitir'**
  String achGamesDesc(int n);

  /// No description provided for @achRareDesc.
  ///
  /// In tr, this message translates to:
  /// **'J veya Ğ içeren bir kelime kur'**
  String get achRareDesc;

  /// No description provided for @achDailyDesc.
  ///
  /// In tr, this message translates to:
  /// **'{n} günlük bulmaca tamamla'**
  String achDailyDesc(int n);

  /// No description provided for @doubleXp.
  ///
  /// In tr, this message translates to:
  /// **'2× XP'**
  String get doubleXp;

  /// No description provided for @doubleXpA11y.
  ///
  /// In tr, this message translates to:
  /// **'XP\'yi ikiye katla'**
  String get doubleXpA11y;

  /// No description provided for @doubleXpA11yAd.
  ///
  /// In tr, this message translates to:
  /// **'Reklam izleyerek XP\'yi ikiye katla'**
  String get doubleXpA11yAd;

  /// No description provided for @xpDoubledLabel.
  ///
  /// In tr, this message translates to:
  /// **'XP ×2'**
  String get xpDoubledLabel;

  /// No description provided for @streakLostTitle.
  ///
  /// In tr, this message translates to:
  /// **'{n} günlük serin bozuldu'**
  String streakLostTitle(int n);

  /// No description provided for @streakLostBody.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün bulmacasını oynamadan önce geri alabilirsin.'**
  String get streakLostBody;

  /// No description provided for @streakRepairAd.
  ///
  /// In tr, this message translates to:
  /// **'Reklam izle, seriyi kurtar'**
  String get streakRepairAd;

  /// No description provided for @streakRepairFree.
  ///
  /// In tr, this message translates to:
  /// **'Seriyi kurtar'**
  String get streakRepairFree;

  /// No description provided for @streakRepaired.
  ///
  /// In tr, this message translates to:
  /// **'Serin geri geldi: {n} gün'**
  String streakRepaired(int n);

  /// No description provided for @giftChip.
  ///
  /// In tr, this message translates to:
  /// **'Hediye'**
  String get giftChip;

  /// No description provided for @giftTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük hediye'**
  String get giftTitle;

  /// No description provided for @giftGot.
  ///
  /// In tr, this message translates to:
  /// **'+{n} {name}'**
  String giftGot(int n, String name);

  /// No description provided for @giftDoubleAd.
  ///
  /// In tr, this message translates to:
  /// **'Reklam izle, bir tane daha al'**
  String get giftDoubleAd;

  /// No description provided for @giftDoubleFree.
  ///
  /// In tr, this message translates to:
  /// **'Bir tane daha al'**
  String get giftDoubleFree;

  /// No description provided for @giftTomorrow.
  ///
  /// In tr, this message translates to:
  /// **'Yarın yeni bir hediye seni bekliyor.'**
  String get giftTomorrow;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'tr':
      return L10nTr();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

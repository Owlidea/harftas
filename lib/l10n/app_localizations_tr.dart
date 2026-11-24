// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class L10nTr extends L10n {
  L10nTr([String locale = 'tr']) : super(locale);

  @override
  String get play => 'Oyna';

  @override
  String get continueGame => 'Devam Et';

  @override
  String get daily => 'Günlük Bulmaca';

  @override
  String dailyStreakChip(int count) {
    return '$count gün';
  }

  @override
  String get dailyDoneChip => 'Bugünkü tamam';

  @override
  String get wordbook => 'Defter';

  @override
  String get missions => 'Görevler';

  @override
  String get settings => 'Ayarlar';

  @override
  String get stats => 'İstatistikler';

  @override
  String get store => 'Mağaza';

  @override
  String get loading => 'Sözlük hazırlanıyor…';

  @override
  String get loadError => 'Sözlük yüklenemedi.';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get back => 'Geri';

  @override
  String get close => 'Kapat';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get ok => 'Tamam';

  @override
  String get dash => '—';

  @override
  String get score => 'Skor';

  @override
  String get best => 'En iyi';

  @override
  String streakMultiplier(String mult) {
    return 'Seri ×$mult';
  }

  @override
  String handOf(int n, int total) {
    return 'El $n/$total';
  }

  @override
  String get pause => 'Duraklat';

  @override
  String get powerupRefresh => 'Yenile';

  @override
  String get powerupJoker => 'Joker';

  @override
  String get powerupHammer => 'Çekiç';

  @override
  String get powerupRefreshDesc => 'Eldeki blokları yeni bir elle değiştirir.';

  @override
  String get powerupJokerDesc => 'Boş bir hücreye istediğin harfi koyar (0 puan).';

  @override
  String get powerupHammerDesc => 'Seçtiğin tek hücreyi siler.';

  @override
  String get dailyNoPowerups => 'Günlük bulmacada güçlendirici yok — herkes için adil.';

  @override
  String get jokerPickCell => 'Joker için boş bir hücreye dokun';

  @override
  String get jokerPickLetter => 'Harf seç';

  @override
  String get hammerPickCell => 'Silmek için dolu bir hücreye dokun';

  @override
  String get noPowerupLeft => 'Bu güçlendiriciden kalmadı';

  @override
  String get stuckTitle => 'Yer kalmadı';

  @override
  String get stuckBody => 'Bir güçlendirici kullanarak devam edebilirsin.';

  @override
  String get endGame => 'Oyunu bitir';

  @override
  String wordPoints(int points) {
    return '+$points';
  }

  @override
  String comboLabel(int n) {
    return 'Kombo ×$n';
  }

  @override
  String get boardCleared => 'Izgara temiz! +100';

  @override
  String get paused => 'Duraklatıldı';

  @override
  String get resume => 'Devam';

  @override
  String get restart => 'Yeniden başlat';

  @override
  String get restartConfirmTitle => 'Yeniden başlatılsın mı?';

  @override
  String get restartConfirmBody => 'Bu oyundaki skorun kaybolacak.';

  @override
  String get mainMenu => 'Ana menü';

  @override
  String get sound => 'Ses';

  @override
  String get music => 'Müzik';

  @override
  String get haptics => 'Titreşim';

  @override
  String get gameOver => 'Oyun bitti';

  @override
  String get dailyComplete => 'Bugünkü bulmaca tamam';

  @override
  String get newRecord => 'Yeni rekor!';

  @override
  String get wordsBuilt => 'Kelime';

  @override
  String get bestWord => 'En iyi kelime';

  @override
  String xpGained(int xp) {
    return '+$xp XP';
  }

  @override
  String get playAgain => 'Tekrar Oyna';

  @override
  String get continueWithAd => 'Devam Et · reklam izle';

  @override
  String get continueFree => 'Devam Et';

  @override
  String get continueHint => 'En dolu 2 satır temizlenir. Oyun başına bir kez.';

  @override
  String get share => 'Paylaş';

  @override
  String levelUp(int level) {
    return 'Seviye $level!';
  }

  @override
  String newWordsAdded(int n) {
    return '$n yeni kelime deftere eklendi';
  }

  @override
  String get missionCompleted => 'Görev tamam';

  @override
  String unlockedTheme(String name) {
    return 'Yeni tema açıldı: $name';
  }

  @override
  String unlockedTileStyle(String name) {
    return 'Yeni karo stili: $name';
  }

  @override
  String earnedPowerup(String name) {
    return '+1 $name';
  }

  @override
  String streakBadge(int days) {
    return '$days günlük seri rozeti!';
  }

  @override
  String get shieldUsedToast => 'Seri koruman kullanıldı, serin devam ediyor.';

  @override
  String get moves => 'Hamle';

  @override
  String get today => 'Bugün';

  @override
  String get startDaily => 'Başla';

  @override
  String get continueDaily => 'Kaldığın yerden devam et';

  @override
  String get dailyRules => 'Herkes aynı blokları görür. Günde tek deneme, güçlendirici yok.';

  @override
  String todayResult(int score, int words) {
    return '$score puan · $words kelime';
  }

  @override
  String nextPuzzleIn(int hours, int minutes) {
    return 'Yeni bulmaca $hours sa $minutes dk sonra';
  }

  @override
  String get streakCurrent => 'Seri';

  @override
  String get streakBest => 'En iyi';

  @override
  String daysUnit(int n) {
    return '$n gün';
  }

  @override
  String get shieldAvailable => 'Bu ay 1 seri koruma hakkın var.';

  @override
  String get shieldUsed => 'Bu ayın seri koruması kullanıldı.';

  @override
  String nextBadge(int n) {
    return 'Sıradaki rozet: $n gün';
  }

  @override
  String get calendarEmpty => 'Henüz günlük bulmaca çözmedin. İlk sonucun burada görünecek.';

  @override
  String get weekdaysShort => 'Pzt,Sal,Çar,Per,Cum,Cmt,Paz';

  @override
  String get monthNames => 'Ocak,Şubat,Mart,Nisan,Mayıs,Haziran,Temmuz,Ağustos,Eylül,Ekim,Kasım,Aralık';

  @override
  String shareText(String app, String date, int score, int words, int longest, int streak, String url) {
    return '$app · $date\nSkor $score · $words kelime · en uzun $longest harf\nSeri: $streak gün\n$url';
  }

  @override
  String get shareCardLongest => 'En uzun kelime';

  @override
  String lettersUnit(int n) {
    return '$n harf';
  }

  @override
  String get wordbookTitle => 'Kelime Defteri';

  @override
  String wordbookTotal(int n) {
    return '$n farklı kelime';
  }

  @override
  String lettersGroup(int n) {
    return '$n harfli';
  }

  @override
  String timesBuilt(int n) {
    return '$n kez';
  }

  @override
  String firstBuilt(String date) {
    return 'İlk: $date';
  }

  @override
  String get recordLongest => 'En uzun';

  @override
  String get recordHighest => 'En yüksek puanlı';

  @override
  String get wordbookEmpty => 'Defterin boş. Kurduğun her kelime burada toplanır.';

  @override
  String get missionsTitle => 'Görevler';

  @override
  String levelN(int n) {
    return 'Seviye $n';
  }

  @override
  String xpProgress(int a, int b) {
    return '$a / $b XP';
  }

  @override
  String missionWordsOfLength(int length, int target) {
    return 'En az $length harfli $target kelime kur';
  }

  @override
  String missionCombo(int target) {
    return 'Tek hamlede 2 kelime patlat · $target kez';
  }

  @override
  String missionLetter(String letter, int target) {
    return 'İçinde $letter geçen $target kelime kur';
  }

  @override
  String missionScore(int target) {
    return 'Tek oyunda $target puan yap';
  }

  @override
  String missionStreak(int target) {
    return '$target hamlelik seri yap';
  }

  @override
  String get missionClear => 'Izgarayı tamamen boşalt';

  @override
  String missionNoPowerups(int target) {
    return 'Güçlendirici kullanmadan $target puan yap';
  }

  @override
  String missionDistinct(int target) {
    return 'Bir oyunda $target farklı kelime kur';
  }

  @override
  String missionReward(int xp, String powerup) {
    return '+$xp XP · 1 $powerup';
  }

  @override
  String get missionsReset => 'Görevler her gece yarısı yenilenir.';

  @override
  String get done => 'Tamam';

  @override
  String get levelRewardsTitle => 'Seviye ödülleri';

  @override
  String get statsTitle => 'İstatistikler';

  @override
  String get statBestScore => 'En yüksek skor';

  @override
  String get statGames => 'Toplam oyun';

  @override
  String get statWords => 'Toplam kelime';

  @override
  String get statAvgLength => 'Ortalama kelime uzunluğu';

  @override
  String get statBestStreak => 'En iyi hamle serisi';

  @override
  String get statMostBuilt => 'En çok kurulan kelime';

  @override
  String get statDailyBest => 'En uzun günlük seri';

  @override
  String get statLevel => 'Seviye';

  @override
  String get statsEmpty => 'İlk oyunundan sonra istatistiklerin burada.';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get sectionSound => 'Ses ve his';

  @override
  String get sectionLook => 'Görünüm';

  @override
  String get sectionPlay => 'Oynanış';

  @override
  String get sectionAbout => 'Destek ve hakkında';

  @override
  String get theme => 'Tema';

  @override
  String get themeModeSystem => 'Sistem';

  @override
  String get themeModeLight => 'Açık';

  @override
  String get themeModeDark => 'Koyu';

  @override
  String get appearance => 'Görünüm modu';

  @override
  String get tileStyle => 'Karo stili';

  @override
  String get colorBlind => 'Renk körlüğü paleti';

  @override
  String get colorBlindDesc => 'Mavi–turuncu vurgu; bilgi ayrıca şekille de verilir.';

  @override
  String get leftHanded => 'Sol el düzeni';

  @override
  String get leftHandedDesc => 'Güçlendiriciler ve duraklat düğmesi sola alınır.';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get notificationsDesc => 'Günde en fazla 1 hatırlatma.';

  @override
  String get howToPlay => 'Nasıl oynanır';

  @override
  String get replayTutorial => 'Öğreticiyi tekrar oyna';

  @override
  String get restorePurchases => 'Satın almaları geri yükle';

  @override
  String get restoreDone => 'Satın almalar kontrol edildi.';

  @override
  String get privacy => 'Gizlilik';

  @override
  String get privacyOptions => 'Reklam izin tercihleri';

  @override
  String get privacyBody =>
      'Hesap açman gerekmez; oyun verilerin bu cihazda saklanır. Reklamlar için Google AdMob, satın almalar için RevenueCat sınırlı veri işler. Reklam izinlerini istediğin zaman buradan değiştirebilirsin.';

  @override
  String get about => 'Hakkında ve lisanslar';

  @override
  String get locked => 'Kilitli';

  @override
  String unlockAtLevel(int n) {
    return 'Açılır: Seviye $n';
  }

  @override
  String unlockAtStreak(int n) {
    return 'Açılır: $n günlük seri';
  }

  @override
  String get themeClassic => 'Klasik';

  @override
  String get themeOlive => 'Zeytin';

  @override
  String get themeLavender => 'Lavanta';

  @override
  String get themeAmber => 'Kehribar';

  @override
  String get themeDawn => 'Şafak';

  @override
  String get themeSea => 'Deniz';

  @override
  String get themeMidnight => 'Gece Yarısı';

  @override
  String get tileClassic => 'Klasik';

  @override
  String get tileSoft => 'Yumuşak';

  @override
  String get tileSharp => 'Keskin';

  @override
  String get tileGrain => 'Ahşap damar';

  @override
  String get tileMarble => 'Mermer';

  @override
  String get aboutTitle => 'Hakkında';

  @override
  String aboutVersion(String v) {
    return 'Sürüm $v';
  }

  @override
  String get aboutDictionary =>
      'Sözlük: Zemberek-NLP sözlük verisinden türetildi (Apache License 2.0, © Ahmet A. Akın, Mehmet D. Akın). Yaygın kelime listesi Zemberek-NLP frekans listesinden alındı.';

  @override
  String get aboutLicenses => 'Açık kaynak lisansları';

  @override
  String get storeTitle => 'Mağaza';

  @override
  String get removeAds => 'Reklamları kaldır';

  @override
  String get removeAdsDesc => 'Tek seferlik. Oyun sonu reklamları kalkar; ödüllü reklam ödülleri reklamsız verilir.';

  @override
  String get packSmall => 'Küçük güçlendirici paketi';

  @override
  String get packLarge => 'Büyük güçlendirici paketi';

  @override
  String packDesc(int n) {
    return 'Her güçlendiriciden $n adet';
  }

  @override
  String get buy => 'Satın al';

  @override
  String get owned => 'Sahipsin';

  @override
  String get storeUnavailable => 'Mağaza şu an kullanılamıyor. Daha sonra tekrar dene.';

  @override
  String get earnWithAd => 'Reklam izle, 1 güçlendirici kazan';

  @override
  String get earnFree => '1 güçlendirici al';

  @override
  String get purchaseThanks => 'Teşekkürler!';

  @override
  String get yourPowerups => 'Güçlendiricilerin';

  @override
  String get tutorialStep1 => 'Bloğu sürükle ve boşluğa bırak: “KA” + “R” = KAR';

  @override
  String get tutorialStep2 => 'Kelimeler yukarıdan aşağıya da okunur.';

  @override
  String get tutorialStep3 => 'Tek hamlede iki kelime kur — kombo!';

  @override
  String get tutorialStep4 => 'Takıldığında güçlendiriciler yardım eder. Çekiç ile işaretli hücreyi sil.';

  @override
  String tutorialStepOf(int n) {
    return '$n/4';
  }

  @override
  String get tutorialSkip => 'Atla';

  @override
  String get tutorialGreat => 'Harika!';

  @override
  String get tutorialDone => 'Hazırsın!';

  @override
  String get tutorialStart => 'Oynamaya başla';

  @override
  String get notifAskTitle => 'Günlük bulmacayı kaçırma';

  @override
  String get notifAskBody =>
      'Yeni bulmaca hazır olduğunda ya da serin bozulmak üzereyken günde en fazla bir kez haber verelim mi?';

  @override
  String get notifAllow => 'Haber ver';

  @override
  String get notifDeny => 'Şimdi değil';

  @override
  String get notifDailyTitle => 'Günlük bulmaca hazır';

  @override
  String get notifDailyBody => 'Bugünün blokları seni bekliyor.';

  @override
  String get notifStreakTitle => 'Serin bozulmak üzere';

  @override
  String notifStreakBody(int n) {
    return '$n günlük serini korumak için bugünkü bulmacayı çöz.';
  }

  @override
  String a11yCell(int row, int col, String letter) {
    return 'Satır $row, sütun $col: $letter';
  }

  @override
  String a11yEmptyCell(int row, int col) {
    return 'Satır $row, sütun $col: boş';
  }

  @override
  String a11yBoard(int filled) {
    return 'Oyun ızgarası, $filled dolu hücre';
  }

  @override
  String a11yPiece(int n, String letters) {
    return '$n hücreli blok: $letters. Sürükleyip ızgaraya bırak.';
  }

  @override
  String get a11yPlaced => 'Yerleştirildi';

  @override
  String a11yPowerup(String name, int count) {
    return '$name, $count adet';
  }

  @override
  String a11yScore(int score) {
    return 'Skor $score';
  }

  @override
  String get genericError => 'Bir şeyler ters gitti.';

  @override
  String get emptyHand => 'Yeni el geliyor…';

  @override
  String get introNext => 'İleri';

  @override
  String get introStart => 'Öğreticiyle başla';

  @override
  String get introGotIt => 'Anladım';

  @override
  String get introSkip => 'Atla';

  @override
  String introPage(int n, int total) {
    return 'Sayfa $n / $total';
  }

  @override
  String get introHelp => 'Nasıl oynanır';

  @override
  String get intro1Title => 'Amaç: kelime kur, patlat';

  @override
  String get intro1Body =>
      'Alttan gelen harfli blokları 8×8 ızgaraya yerleştir. Bir kelime oluştuğu anda harfleri patlar ve puan kazanırsın. Izgarada yer açık tuttukça oyun sürer — hedefin en yüksek skoru yapmak.';

  @override
  String get intro2Title => 'Kelimeler nasıl okunur?';

  @override
  String get intro2Body =>
      'Harfler yalnızca soldan sağa ve yukarıdan aşağıya okunur; en az 3 harf gerekir. Yatay ve dikey iki kelime aynı harfi paylaşabilir. Sözlükte temel biçimler var: KALEM, ARABA, GELMEK gibi — EVLER ya da GELDİ gibi çekimli hâller sayılmaz.';

  @override
  String get intro3Title => 'Puan ve çarpanlar';

  @override
  String get intro3Body =>
      'Her harfin puanı karonun köşesinde yazar. Uzun kelimeler katlanır: 5 harf ×2, 6 harf ×3, 8 harf ×6. Tek hamlede birden çok kelime kombo yapar; art arda kelime kurarsan seri çarpanın büyür. Izgarayı tamamen boşaltırsan +100.';

  @override
  String get intro4Title => 'Oyun ne zaman biter?';

  @override
  String get intro4Body =>
      'Elinde her seferinde 3 blok olur ve bloklar döndürülemez. Hiçbiri ızgaraya sığmazsa oyun biter — o yüzden yerleştirirken ileriyi düşün. Takılırsan Yenile, Joker ve Çekiç güçlendiricileri yardım eder. Her gün herkes için aynı olan bir Günlük Bulmaca da seni bekler.';

  @override
  String get homeTagline => 'Blokları diz, kelimeyi patlat';

  @override
  String get playSubNew => 'Yeni oyun';

  @override
  String playSubContinue(int score) {
    return 'Skor $score · kaldığın yerden';
  }

  @override
  String get dailyReadySub => 'Bugünün bulmacası hazır';

  @override
  String dailyDoneSub(int score) {
    return 'Tamamlandı · $score puan';
  }

  @override
  String bestChip(int n) {
    return 'En iyi $n';
  }

  @override
  String get monthShort => 'OCA,ŞUB,MAR,NİS,MAY,HAZ,TEM,AĞU,EYL,EKİ,KAS,ARA';

  @override
  String get selected => 'Seçili';

  @override
  String get dailyTodayTitle => 'Bugünün bulmacası';

  @override
  String timeLeft(int hours, int minutes) {
    return '$hours sa $minutes dk';
  }

  @override
  String get ruleSame => 'Herkese aynı';

  @override
  String get ruleOnce => 'Tek deneme';

  @override
  String get ruleNoPowerups => 'Güçlendirici yok';

  @override
  String dailyProgress(int n, int total, int score) {
    return 'El $n/$total · $score puan';
  }

  @override
  String get dailyStartSub => 'Yaklaşık 3 dakika';

  @override
  String get dailyContinueSub => 'Kaldığın yerden';

  @override
  String streakToNext(int days, int left) {
    return '$days günlük rozete $left gün kaldı';
  }

  @override
  String get allBadges => 'Tüm seri rozetleri açıldı!';

  @override
  String get lastSevenDays => 'Son 7 gün';

  @override
  String get streakTitle => 'Serin';

  @override
  String get calendarHint => 'Çözdüğün günler burada renklenir.';

  @override
  String get storeHeroTitle => 'Reklamsız oyna';

  @override
  String get storeHeroSub => 'Tek seferlik satın alma';

  @override
  String get storeBenefit1 => 'Oyun sonu reklamları kalkar';

  @override
  String get storeBenefit2 => 'Devam Et ve hediyeler reklamsız';

  @override
  String get storeBenefit3 => 'Bir kez öde, hep senin';

  @override
  String get storeOwnedTitle => 'Reklamsız sürümdesin';

  @override
  String get storeOwnedSub => 'Desteğin için teşekkürler.';

  @override
  String get packSmallShort => 'Küçük paket';

  @override
  String get packLargeShort => 'Büyük paket';

  @override
  String packTotal(int n) {
    return '$n güçlendirici';
  }

  @override
  String packEachShort(int n) {
    return 'her birinden $n';
  }

  @override
  String get packLargestTag => 'En büyük';

  @override
  String get packsTitle => 'Güçlendirici paketleri';

  @override
  String get freeTitle => 'Ücretsiz güçlendirici';

  @override
  String get freeSubAd => 'Kısa bir reklam izle, 1 tane kazan';

  @override
  String get freeSubNoAds => 'Reklamsız sürüme hediye';

  @override
  String get storeFootnote =>
      'Ödemeler App Store / Google Play hesabın üzerinden alınır. Abonelik yoktur; tüm satın almalar tek seferliktir.';

  @override
  String get storeMobileOnly =>
      'Satın almalar ve reklamla güç kazanma Harf Kombo\'nun iOS ve Android uygulamasında. Web sürümünde oyunun tamamı ücretsiz oynanır.';

  @override
  String get privacyFullPolicy => 'Gizlilik politikasının tamamı';

  @override
  String get privacyHeadline => 'Neyi neden kullanıyoruz';

  @override
  String get privacyIntro =>
      'Hesap açman gerekmez. Oyun verilerin cihazında kalır; reklam ve satın almalar için sınırlı veri işlenir.';

  @override
  String get privacyFactAccountTitle => 'Hesap yok';

  @override
  String get privacyFactAccountBody => 'Ad, e-posta, telefon numarası ya da konum istenmez.';

  @override
  String get privacyFactLocalTitle => 'Yalnızca bu cihazda';

  @override
  String get privacyFactLocalBody => 'Skorların, ilerlemen ve kelime defterin bu cihazda saklanır.';

  @override
  String get privacyFactAdsTitle => 'Reklamlar';

  @override
  String get privacyFactAdsBody =>
      'Google AdMob, reklam göstermek için reklam kimliğini ve cihaz bilgisini işleyebilir. Kişiselleştirilmiş reklamı reddedebilirsin.';

  @override
  String get privacyFactPurchasesTitle => 'Satın almalar';

  @override
  String get privacyFactPurchasesBody =>
      'Ödemeyi Apple veya Google alır; ödeme bilgini görmeyiz. RevenueCat satın almanı doğrular ve anonim bir kimlikle saklar.';

  @override
  String get privacyManage => 'Yönet';

  @override
  String get privacyOptionsSub => 'İzinleri gör ya da değiştir';

  @override
  String get privacyFullPolicySub => 'Tarayıcıda açılır';

  @override
  String get supportTitle => 'Destek ekibine yaz';

  @override
  String get contactSupport => 'Destek: bize yazın';

  @override
  String get ruleSameSub => 'Herkes aynı bulmacayı çözer';

  @override
  String get ruleOnceSub => 'Günde bir kez oynanır';

  @override
  String get ruleNoPowerupsSub => 'Güçlendirici kullanılmaz';

  @override
  String get storePremium => 'Premium';

  @override
  String get freeCta => 'İzle';

  @override
  String get freeCtaNoAds => 'Al';

  @override
  String get missionsToday => 'Günün görevleri';

  @override
  String missionsDoneCount(int a, int b) {
    return '$a/$b tamamlandı';
  }

  @override
  String missionsRenewIn(String time) {
    return '$time sonra yenilenir';
  }

  @override
  String get nextReward => 'Sonraki ödül';

  @override
  String rewardThemeShort(String name) {
    return '$name teması';
  }

  @override
  String rewardTileShort(String name) {
    return '$name karolar';
  }

  @override
  String xpToNext(int xp) {
    return 'Sonraki seviyeye $xp XP';
  }

  @override
  String get ruleSameTitle => 'Aynı harfler';

  @override
  String get ruleSkillTitle => 'Saf beceri';
}

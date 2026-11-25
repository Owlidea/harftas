# Aşama 5 — Mağaza metni, anahtar kelimeler, ekran görüntüleri, gizlilik beyanları

## 1. Mağaza metni (Türkçe)

**Ad (30):** Harf Kombo: Kelime Bulmaca (21 Kasım 2026; eski ad Harftaş)
**Alt başlık / kısa açıklama (30 / 80):**
- iOS alt başlık: `Blokları diz, kelimeyi patlat`
- Google Play kısa açıklama: `Harfli blokları ızgaraya yerleştir, Türkçe kelimeler kur, kombo ve seri yap!`

**Açıklama:**

> Harfli blokları 8×8 ızgaraya sürükle. Soldan sağa ya da yukarıdan aşağıya bir Türkçe kelime
> oluştuğu anda harfler patlar, puanlar yağar.
>
> • Kısa kelimeyi şimdi mi alacaksın, yoksa uzun kelimeyi mi kovalayacaksın? 8 harfli bir kelime
>   tam 6 kat puan getirir.
> • Tek hamlede birden fazla kelime: kombo! Art arda kelimeler: seri çarpanı!
> • Her gün yeni bir Günlük Bulmaca: herkes aynı blokları görür, sonucu spoiler vermeden paylaş.
> • Günlük görevler, haftalık hedef ve başarımlar; seviye atladıkça açılan temalar, karo stilleri ve
>   tahta zeminleri.
> • Kelime Defteri: kurduğun her kelime, kaç kez ve ilk ne zaman kurduğunla birlikte kaydedilir.
> • İnternetsiz oynanır, hesap açman gerekmez.
> • Oyun sırasında asla reklam yok.
> • Renk körlüğü paleti, sol el düzeni, hareketi azalt ve dinamik yazı boyutu desteği.
>
> Sözlük: Zemberek-NLP sözlük verisinden türetilmiştir (Apache 2.0).

**Kategori:** Oyunlar › Kelime (birincil), Bulmaca (ikincil).
**İçerik derecelendirmesi:** 4+ (App Store) / PEGI 3 · Herkes (Play) — içerik çocuklara uygun.
**Hedef kitle (Play):** yalnızca 18 yaş ve üzeri (16 Kasım 2026). 13–17 seçilince Google bazı ülkelerde
Aile politikasını uyguluyor; bunun için yaş kontrolü ve çocuklara uygun reklam ayarı gerekir (§6).
Bu ikisi farklı şeyler: derecelendirme içeriği, hedef kitle kimin için yapıldığını anlatır.

## 2. Anahtar kelimeler

- **iOS anahtar kelime alanı (100 karakter, virgülle, boşluksuz):**
  `kelime,bulmaca,harf,türkçe,blok,kelimeoyunu,zeka,sözcük,oyunu,günlük,çevrimdışı,kombo,ızgara,beyin`
  ("kelimelik" bir rakip oyunun adı olduğu için çıkarıldı.)
- **Play açıklamada doğal geçmesi gerekenler:** kelime oyunu, harf bulmaca, Türkçe kelime, blok
  bulmaca, günlük bulmaca, internetsiz oyun, zeka oyunu.
- Rakip oyun adları **kullanılmaz** (mağaza politikası + spesifikasyon §11).

## 3. Ekran görüntüsü planı (5 kare, dikey)

Ölçüler: iPhone 6,9″ **1320×2868**, iPad 13″ **2064×2752**, Android telefon **1080×1920** (min),
Play öne çıkan görsel **1024×500**. Ham görüntüler `flutter test test_screens` ile üretilir
(`docs/screenshots/`), çerçeve ve başlık şablonu sizden.

| # | Ekran | Başlık metni |
|---|---|---|
| 1 | Oyun, önizlemede 5 harfli kelime vurgulu | Blokları diz, kelimeyi patlat |
| 2 | Kombo anı (×2 etiketi, parçacıklar) | Tek hamlede iki kelime: kombo! |
| 3 | Günlük bulmaca kartı + takvim | Her gün yeni bulmaca |
| 4 | Kelime Defteri | Kurduğun her kelime defterinde |
| 5 | Ayarlar: temalar + erişilebilirlik | Sana uyan tema, rahat oyun |

## 4. Tanıtım videosu (15–30 sn, iOS App Preview 886×1920)

1. 0–3 sn: logo, boş ızgara.
2. 3–8 sn: blok sürüklenir, önizlemede "KALEM" vurgulanır, bırakınca harfler sırayla patlar.
3. 8–13 sn: yatay + dikey iki kelime aynı anda, "×2", hafif sarsıntı.
4. 13–18 sn: 7 harfli kelime, büyük puan etiketi.
5. 18–23 sn: günlük bulmaca kartı, seri takvimi.
6. 23–27 sn: Kelime Defteri kaydırma.
7. 27–30 sn: logo + "Ücretsiz indir".

## 5. Gizlilik beyanları

Uygulamanın kendi kodu kişisel veri toplamaz; analitik v1'de yalnızca cihaz konsoluna yazar.
Beyanlar iki SDK nedeniyle gereklidir: **Google Mobile Ads** (reklam) ve **RevenueCat**
(satın alma doğrulama; anonim uygulama kullanıcı kimliğiyle satın alma geçmişi).

### App Store — App Privacy ("nutrition label")
**App Store Connect'te yayınlandı (16 Kasım 2026).** Google'ın AdMob için önerdiği App Store beyanlarıyla uyumlu 8 veri türü:

| Veri türü | Amaç | Kimlikle ilişkili | İzleme |
|---|---|---|---|
| Konum → Kaba konum (IP tabanlı, Google SDK) | Üçüncü taraf reklam, analiz | Hayır | Evet |
| Tanımlayıcılar → Cihaz kimliği (IDFA, yalnızca ATT izniyle) | Üçüncü taraf reklam, analiz | Hayır | Evet |
| Satın almalar → Satın alma geçmişi (RevenueCat) | Uygulama işlevselliği | Hayır (anonim kimlik) | Hayır |
| Kullanım verisi → Ürün etkileşimi | Üçüncü taraf reklam, analiz | Hayır | Evet |
| Kullanım verisi → Reklam verisi | Üçüncü taraf reklam, analiz | Hayır | Evet |
| Tanılama → Çökme verisi | Uygulama işlevselliği, analiz | Hayır | Hayır |
| Tanılama → Performans verisi | Uygulama işlevselliği, analiz | Hayır | Hayır |
| Tanılama → Diğer tanılama verisi | Uygulama işlevselliği, analiz | Hayır | Hayır |

Ayrıca: Google Mobile Ads ve RevenueCat kendi `PrivacyInfo.xcprivacy` bildirimleriyle gelir.
Uygulamanın kendi bildirimi `ios/Runner/PrivacyInfo.xcprivacy`'de (izleme yok, toplanan veri
yok; `UserDefaults` CA92.1 ve `FileTimestamp` C617.1 nedenleri beyan edildi). Xcode'da
**Product → Archive → Generate Privacy Report** ile birleşik raporu kontrol et.

### Google Play — Data safety
| Veri | Toplanır | Paylaşılır | Amaç | İsteğe bağlı |
|---|---|---|---|---|
| Cihaz veya diğer kimlikler (reklam kimliği) | Evet | Evet (Google) | Reklam | Hayır |
| Uygulama etkileşimleri | Evet | Evet (Google) | Reklam, analiz | Hayır |
| Çökme günlükleri, tanılama | Evet | Evet (Google) | Analiz | Hayır |
| Kaba konum | Evet | Evet (Google) | Reklam | Hayır |
| Finansal bilgi → Satın alma geçmişi | Evet | Hayır (RevenueCat hizmet sağlayıcıdır, "paylaşım" sayılmaz) | Uygulama işlevselliği | Hayır |
- Veri aktarımda şifrelenir: Evet.
- Kullanıcı veri silme isteyebilir: Evet — oyun verisi cihazda kalır (uygulamayı silmek siler);
  satın alma kayıtları için destek e-postasına sipariş numarasıyla yazılır (RevenueCat'ten silinir);
  reklam kimliği cihaz ayarlarından sıfırlanır.
- Hedef kitle: yalnızca 18+ (Play beyanı). "Aileler" programına **katılmayın** (reklam kısıtları).

### KVKK / GDPR
- AB/EEA/BK kullanıcıları için Google UMP onay formu ilk açılışta gösterilir; Ayarlar → Gizlilik →
  "Reklam izin tercihleri" ile tekrar açılır.
- Türkiye (KVKK): gizlilik politikasında veri sorumlusu, işleme amacı (reklam), aktarım (Google,
  yurtdışı) ve başvuru yolu belirtilmelidir. Uygulama içi metin: Ayarlar → Gizlilik.
- Gizlilik politikası URL'si (zorunlu) — `AppInfo.shareUrl` alanıyla aynı alan adında yayınlanmalı.

## 6. Mağaza formları — hazır yanıtlar

### Google Play → Uygulama içeriği
| Form | Yanıt |
|---|---|
| Gizlilik politikası | `https://owlidea.github.io/harftas/gizlilik.html` (Play ve App Store'a girildi) |
| Uygulama erişimi | Tüm işlevler giriş yapmadan kullanılabilir |
| Reklamlar | Evet, reklam içerir |
| İçerik derecelendirmesi | Aşağıdaki anket → beklenen sonuç PEGI 3 / Herkes |
| Hedef kitle ve içerik | **Yalnızca 18+** (girildi). 13–17 eklemek için önce yaş kontrolü + AdMob çocuklara uygun reklam ayarı |
| Haber uygulaması | Hayır |
| Veri güvenliği | §5 "Google Play — Data safety" tablosu |
| Devlet uygulaması / finans / sağlık özellikleri | Hayır |

### İçerik derecelendirme anketi (IARC, Play) ve yaş derecelendirmesi (App Store)
| Soru | Yanıt |
|---|---|
| Kategori | Oyun |
| Şiddet, kan, korku | Yok |
| Cinsel içerik, çıplaklık | Yok |
| Küfür / kaba dil | Yok — sözlük engel listesinden geçiriliyor (`tool/dict/blocklist_tr.txt`) |
| Alkol, tütün, uyuşturucu | Yok |
| Kumar / şans oyunu, gerçek para | Yok (güçlendiriciler ve ödüllü reklam şans unsuru içermez) |
| Kullanıcılar arası etkileşim, sohbet, kullanıcı içeriği | Yok (yalnızca sistem paylaşım sayfasıyla sonuç paylaşımı) |
| Konum paylaşımı | Yok |
| Dijital satın alma | Var (uygulama içi satın alma) |
| Reklam | Var |
| Sınırsız web erişimi | Yok |
| **Beklenen sonuç** | App Store 4+ · PEGI 3 · ESRB Everyone |

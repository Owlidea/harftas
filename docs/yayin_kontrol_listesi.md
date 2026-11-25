# Yayın yapılacaklar listesi

Son güncelleme: 25 Kasım 2026

**Otomatik kontrol:** `dart tool/release_check.dart` (kod kontrolleriyle birlikte: `--tests`).
Hiçbir şey derlemez, yalnızca okur; `✗` = yayın engeli, `!` = öneri. Aşağıda **[oto]** işaretli
maddeleri bu script doğrular; **[elle]** olanlar panelde/cihazda kontrol edilir.

Kim: **Sen** = senin hesabın, şifren, kararın ya da dosyan · **Claude** = kodda/panelde ben
yaparım · **Birlikte** = sen hesabı açarsın, ben doldururum.

---

> **Ad değişikliği (21 Kasım 2026):** Harftaş → **Harf Kombo**. Uygulama, platform adları ve web sayfaları güncellendi; GitHub Pages'teki gizlilik ve destek sayfaları yeni adı gösteriyor (25 Kasım 2026'da kontrol edildi). ✓ Mağaza adı iki mağazada da **"Harf Kombo: Kelime Bulmaca"** (25 Kasım 2026; Play'de taslak, görseller yüklenince tam kaydolur).
>
> **Sizden beklenenler (25 Kasım 2026):** A4 anahtar şifresi · Xcode → Settings → Accounts'a Apple ID (C3) · App Review iletişim bilgisi (C7) · ekran görüntüleri (D2) · dosya yüklemelerinin yolu (sürükle-bırak ya da Claude in Chrome).

## A. Şimdi — birbirini beklemeyen yayın engelleri

| # | İş | Kim | Kontrol |
|---|---|---|---|
| A1 | ✓ **Web sayfaları** GitHub Pages'te (16 Kasım 2026): `https://owlidea.github.io/harftas/gizlilik.html` ve `destek.html` (depo `Owlidea/harftas`; `web/` değişince oradaki dosyalar da güncellenmeli). Kendi alan adı istenirse sonra taşınır | Claude ✓ | [oto] |
| A2 | ✓ **Destek e-postası** `support@owlidea.com` (Slingshire ile aynı; sayfalar, `config/prod.json`, `AppInfo`) | Claude ✓ | [oto] |
| A3 | ✓ **Veri sorumlusu**: "Owlidea Bilişim Teknolojileri Ltd. Şti." (Slingshire gibi adres yok; KVKK için açık adres eklemek istersen ver, eklerim) | Claude ✓ | [oto] |
| A4 | **Android yükleme anahtarı**: `tool/create_upload_key.sh` çalıştır (şifreyi sen girersin; .jks ve şifreyi parola yöneticisinde sakla) | Sen | [oto] |
| A5 | ✓ **Android sürüm derlemesi** (25 Kasım 2026): `flutter build appbundle --release --obfuscate --split-debug-info` temiz geçti (Flutter 3.50.1, NDK 28.2), 73,6 MB AAB. "failed to strip debug symbols" hatası çıkmadı; paketteki `libapp.so`'da hata ayıklama bölümü ve okunur sınıf adı yok (derlemedeki "unobfuscated DWARF" uyarısı ara dosyaya ait). Yükleme anahtarı olmadan derlendiği için bu paket Play'e yüklenemez; A4 + A14 sonrası `tool/release.sh android` | Claude ✓ | [elle] |
| A6 | ✓ **AdMob** (25 Kasım 2026): Android + iOS uygulamaları ve 4 reklam birimi (ödüllü + geçiş × 2 platform); kimlikler `config/prod.json` ve `ios/Runner/Info.plist`'te. `app-ads.txt` yayında (`owlidea.github.io/app-ads.txt`) | Claude ✓ | [oto] |
| A7 | ✓ **AdMob gizlilik mesajları** yayınlandı: GDPR ("Harf Kombo GDPR", Türkçe, "İzin verme" düğmeli) + IDFA açıklaması ("Harf Kombo IDFA", Türkçe). ABD eyalet mesajı isteğe bağlı, eklenmedi | Claude ✓ | [elle] |
| A8 | ✓ **Yazı tipi** Nunito (OFL 1.1), 5 ağırlık; Türkçe karakterler tam, rakamlar eşit genişlikte | Claude ✓ | [oto] |
| A9 | ✓ **Logo**: oyunun 3B karolarından çiziliyor (ana ekran); mağaza için `docs/magaza-gorselleri-v6/logo.png`. SVG isteğe bağlı | Claude ✓ | [oto] |
| A10 | ✓ **Seri rozetleri** Blender'da üretildi: `assets/images/badges/streak_{7,30,100}.png` | Claude ✓ | [oto] |
| A11 | ✓ **Sesler**: 19 efekt + 41 sn müzik döngüsü koddan sentezlendi (`tool/sfx/`), sık sesler 4 varyasyonlu, seri sesi pentatonik yükselir, büyük anlarda müzik kısılır. Telefonda dinleyip onayla | Claude ✓ / Sen dinle | [oto] |
| A12 | Uygulama simgesi ve açılış görseli Blender'dan üretildi (24 Kasım 2026, `tool/blender/render_brand.py`): **onayın gerekiyor** | Sen | [elle] |
| A13 | ✓ **iOS için Xcode** kurulu (Xcode 27.1, 25 Kasım 2026); simülatör derlemesi çalışıyor | Sen ✓ | [elle] |
| A14 | ✓ **`config/prod.json`** oluşturuldu (25 Kasım 2026; git'e girmez, izin 600): AdMob kimlikleri, RevenueCat anahtarları (`appl_…`, `goog_…`), paylaşım/gizlilik adresleri, destek e-postası. Dosyayı parola yöneticisine de yedekle | Claude ✓ | [oto] |

## B. İlk Android sürümünden sonra (A4 + A5 gerekli)

| # | İş | Kim | Kontrol |
|---|---|---|---|
| B1 | AAB'yi Play Console → Harftaş → **Dahili test** kanalına yükle | Birlikte | [elle] |
| B2 | Play **tek seferlik ürünler**: `remove_ads`, `powerups_small`, `powerups_large` (şu an Play "önce FATURALANDIRMA izinli sürüm yükleyin" diyor) | Claude (panelde) | [elle] |
| B3 | RevenueCat → Harftaş (Play Store) → **Check again** (şu an "package name not found") | Claude | [elle] |
| B4 | Play **lisans testi** hesabıyla satın alma + geri yükleme denemesi | Birlikte | [elle] |

## C. iOS (A13 gerekli)

| # | İş | Kim | Kontrol |
|---|---|---|---|
| C1 | ✓ App Store Connect kaydı **"Harf Kombo: Kelime Bulmaca"** (25 Kasım 2026'da yeniden adlandırıldı; Apple ID 6835361847, ekip 7ULGPGPVQ3, bundle `com.owlidea.harftas`), kategori Oyunlar › Kelime + Bulmaca, yaş derecelendirmesi **4+** (yeni sorular da yanıtlandı: konum paylaşımı yok, flört yok; "Çocuklar için" seçilmedi) | Claude ✓ | [elle] |
| C2 | ✓ Uygulama içi ürünler: `harftas.remove_ads` ₺49,99/$3,99 · `harftas.powerups_small` ₺19,99/$1,99 · `harftas.powerups_large` ₺49,99/$3,99 (baz ABD, Türkiye sabit) (Türkçe ad, tüm ülkeler; RevenueCat'e bağlandı, RevenueCat'te In-App Purchase anahtarı geçerli). **Kalan:** üç ürüne de inceleme ekran görüntüsü yüklenmesi — hazır: `docs/magaza-gorselleri-v6/iap-inceleme-ios.png` (1320×2868, simülatörden; üç ürün aynı ekranda) — ve ilk derleme gelince sürüme eklenmeleri | Claude ✓ / Birlikte | [elle] |
| C3 | Arşiv hazır (`build/ios/archive/Runner.xcarchive`, 1.0.0 (1), gerçek AdMob/RevenueCat kimlikleriyle, 25 Kasım 2026). Dışa aktarma "No Accounts" ile duruyor: **Xcode → Settings → Accounts → + → Apple ID** (ekip 7ULGPGPVQ3). Sonra `xcodebuild -exportArchive … -allowProvisioningUpdates` ile yükleme → TestFlight; **Sandbox** hesabıyla satın alma + geri yükleme | Sen → Claude | [elle] |
| C4 | ✓ App Store **App Privacy** yayınlandı (8 veri türü, gizlilik URL'si GitHub Pages) | Claude ✓ | [elle] |
| C5 | ✓ App Store: alt başlık, açıklama (25 Kasım 2026'da haftalık hedef/başarım/zemin satırıyla güncellendi), tanıtım metni, anahtar kelimeler (rakip adı "kelimelik" çıkarıldı → "kelimeoyunu"), destek ve pazarlama URL'si, telif, sürüm 1.0.0, İçerik Hakları (üçüncü taraf içerik var, haklar mevcut: Zemberek Apache 2.0) | Claude ✓ | [elle] |
| C6 | ✓ Fiyat **Ücretsiz**; erişim **174 ülke** — Çin anakarası hariç (orada Güvenlik Değerlendirmesi + AIGC beyanı isteniyor). Ücretli Uygulamalar ve Ücretsiz Uygulamalar sözleşmeleri, banka hesabı, vergi formları ve AB DSA tacir kaydı **Active** (25 Kasım 2026) | Claude ✓ | [elle] |
| C7 | App Review bilgileri: "Oturum açma gerekli" kaldırıldı, İngilizce inceleme notu yazıldı (satın almalar, reklam kuralları, UMP → ATT sırası), yayın **elle** (onaydan sonra "Release" ile). **Kalan:** inceleme iletişim kişisi (ad, soyad, telefon, e-posta) — App Store Connect → sürüm sayfası → App Review Information | Sen | [elle] |

## D. Mağaza kayıtları (paralel yürür)

| # | İş | Kim | Kontrol |
|---|---|---|---|
| D1 | ✓ Mağaza metinleri girildi: App Store (kayıtlı) ve Play varsayılan mağaza girişi (yeni ad ve güncel açıklamayla 25 Kasım 2026; **taslak** — Play, simge + öne çıkan görsel + ekran görüntüleri yüklenmeden tam kaydetmiyor; Play kontrol panelinde yalnızca bu madde eksik, içerik beyanları 11/11). Play mağaza ayarları: kategori Kelime, e-posta `support@owlidea.com`, web `owlidea.github.io/harftas/destek.html` | Claude ✓ | [elle] |
| D2 | Hazır (`docs/magaza-gorselleri-v6/`): Play simgesi `play-simge-512.png` (512×512), öne çıkan görsel `one-cikan-gorsel.png` (1024×500, "HARF KOMBO"), tanıtım videosu. **Ekran görüntüleri** yeni adla ve yeni görünümle yeniden çekilmeli (eski setler "Harftaş" adını taşıyor). Ölçüler: Play telefon 2–8 adet (9:16, en az 1080×1920) · iPhone 6,9″ 1320×2868 (1–10) · iPad 13″ 2064×2752 (1–10; uygulama iPad'i desteklediği için zorunlu) | Sen | [elle] |
| D3 | ✓ Play **Veri güvenliği** kaydedildi (16 Kasım 2026; önceki sürüm yalnızca taslaktı): 6 veri türünün kullanım soruları dolduruldu, veri silme bağlantısı `gizlilik.html#veri-silme`. Apple App Privacy yayınlandı | Claude ✓ | [elle] |
| D4 | ✓ Play beyanları tamam: içerik derecelendirmesi (IARC: PEGI 3, ESRB Herkes, IARC 3+; iletişim `support@owlidea.com`), **hedef kitle yalnızca 18+** (13–17 seçilince Google bazı ülkelerde Aile politikasını uyguluyor; uygulamada yaş kontrolü ve çocuklara uygun reklam ayarı olmadığı için), satıcı (tacir) durumu onaylandı | Claude ✓ | [elle] |
| D5 | **Zemberek** sözlük lisansının (Apache 2.0) hukukçuya teyidi; engel listesinin gözden geçirilmesi (`tool/dict/blocklist_tr.txt`) | Sen | [elle] |

## E. Son kontrol

| # | İş | Kim | Kontrol |
|---|---|---|---|
| E1 | `dart tool/release_check.dart --tests` → **0 engel** | Claude | [oto] |
| E2 | Gerçek cihazda elle test listesi (`docs/elle_test_listesi.md`) iki platformda | Sen | [elle] |
| E3 | Gerçek cihazda performans (60 FPS) ve soğuk açılış (< 2 sn) | Birlikte | [elle] |

## F. Önerilen (yayını engellemez)

| # | İş | Kim |
|---|---|---|
| F3 | Çökme raporlama (Crashlytics/Sentry): şu an çökmeler yalnızca konsola yazılıyor | Karar Sen, kurulum Claude |
| F4 | 26 arayüz ikonu SVG (şu an kodla çizilen yer tutucu) ve müzik | Sen |
| F5 | RevenueCat → Google developer notifications ("Connect to Google") | Claude |

---

## Tamamlananlar

- [x] Kod: `flutter analyze` temiz, 158 birim testi ve ekran testleri geçiyor (25 Kasım 2026)
- [x] Mobil oyun düzeni, ekran yeniden tasarımları, uygulama içi bildirim/onay panelleri
- [x] Gizlilik metinleri (uygulama içi + `web/gizlilik.html`) AdMob ve RevenueCat'i doğru anlatıyor
- [x] RevenueCat: Harftaş projesi, iOS/Android uygulamaları, 6 ürün, `premium` yetkisi, `default` teklifi, SDK anahtarları `config/prod.json`'da (`docs/revenuecat.md`)
- [x] Play Console: Harftaş uygulaması (`com.owlidea.harftas`, Türkçe, Oyun, Ücretsiz)
- [x] Play servis hesabı RevenueCat'e bağlandı (hesap düzeyi izinler; anahtar kuralı geri açıldı)
- [x] Sürüm: `pubspec.yaml` 1.0.0+1 = `AppInfo.version`
- [x] `SKAdNetworkItems`: Google'ın güncel 50 kimliği (`ios/Runner/Info.plist`, kaynak: AdMob 3p-skadnetworks, 30 Ocak 2026)
- [x] `ios/Runner/PrivacyInfo.xcprivacy` eklendi ve Xcode projesine kaydedildi (Xcode olmadığı için derlemeyle doğrulanmadı — ilk iOS arşivinde Privacy Report'a bak)
- [x] Mağaza belgesi güncellendi: açıklamadaki "kişisel veri yok" kaldırıldı, derecelendirme (4+/PEGI 3) ile hedef kitle (13+) ayrıştırıldı, RevenueCat beyanları ve form yanıtları eklendi

# Yayın yapılacaklar listesi

Son güncelleme: 16 Kasım 2026

**Otomatik kontrol:** `dart tool/release_check.dart` (kod kontrolleriyle birlikte: `--tests`).
Hiçbir şey derlemez, yalnızca okur; `✗` = yayın engeli, `!` = öneri. Aşağıda **[oto]** işaretli
maddeleri bu script doğrular; **[elle]** olanlar panelde/cihazda kontrol edilir.

Kim: **Sen** = senin hesabın, şifren, kararın ya da dosyan · **Claude** = kodda/panelde ben
yaparım · **Birlikte** = sen hesabı açarsın, ben doldururum.

---

> **Ad değişikliği (21 Kasım 2026):** Harftaş → **Harf Kombo**. Uygulama, platform adları ve web sayfaları güncellendi. **Bekleyen:** GitHub Pages'e yeni sayfaların yüklenmesi, App Store Connect ve Play Console'da adın "Harf Kombo: Kelime Bulmaca" yapılması (oturum açılınca Claude yapar).

## A. Şimdi — birbirini beklemeyen yayın engelleri

| # | İş | Kim | Kontrol |
|---|---|---|---|
| A1 | ✓ **Web sayfaları** GitHub Pages'te (16 Kasım 2026): `https://owlidea.github.io/harftas/gizlilik.html` ve `destek.html` (depo `Owlidea/harftas`; `web/` değişince oradaki dosyalar da güncellenmeli). Kendi alan adı istenirse sonra taşınır | Claude ✓ | [oto] |
| A2 | ✓ **Destek e-postası** `support@owlidea.com` (Slingshire ile aynı; sayfalar, `config/prod.json`, `AppInfo`) | Claude ✓ | [oto] |
| A3 | ✓ **Veri sorumlusu**: "Owlidea Bilişim Teknolojileri Ltd. Şti." (Slingshire gibi adres yok; KVKK için açık adres eklemek istersen ver, eklerim) | Claude ✓ | [oto] |
| A4 | **Android yükleme anahtarı**: `tool/create_upload_key.sh` çalıştır (şifreyi sen girersin; .jks ve şifreyi parola yöneticisinde sakla) | Sen | [oto] |
| A5 | **Android sürüm derlemesi**: son denemede "failed to strip debug symbols" hatası. NDK/araç zinciri düzeltilecek, `tool/release.sh android` temiz geçecek | Claude | [elle] |
| A6 | **AdMob**: Android + iOS uygulamaları ve 4 reklam birimi (ödüllü + geçiş × 2 platform) oluştur, kimlikleri bana ver → `config/prod.json` + `ios/Runner/Info.plist` | Sen → Claude | [oto] |
| A7 | **AdMob gizlilik mesajları**: GDPR mesajı + IDFA açıklama mesajı (AdMob → Gizlilik ve mesajlaşma) | Birlikte | [elle] |
| A8 | ✓ **Yazı tipi** Nunito (OFL 1.1), 5 ağırlık; Türkçe karakterler tam, rakamlar eşit genişlikte | Claude ✓ | [oto] |
| A9 | **Logo** `logo_light.svg`, `logo_dark.svg` → `assets/images/brand/` | Sen | [oto] |
| A10 | **Seri rozetleri** `streak_7/30/100.svg` → `assets/images/badges/` | Sen | [oto] |
| A11 | ✓ **Sesler**: 19 efekt + 41 sn müzik döngüsü koddan sentezlendi (`tool/sfx/`), sık sesler 4 varyasyonlu, seri sesi pentatonik yükselir, büyük anlarda müzik kısılır. Telefonda dinleyip onayla | Claude ✓ / Sen dinle | [oto] |
| A12 | Uygulama simgesi ve açılış görseli **son hali mi?** (`assets/branding/` dosyaları var; geçiciyse değiştir) | Sen | [elle] |
| A13 | **iOS için Xcode**: bu Mac'te Xcode yok; iOS derlemesi ve App Store yüklemesi için kurulmalı | Sen | [elle] |

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
| C1 | ✓ App Store Connect kaydı **"Harftaş: Kelime Bulmaca"** (Apple ID 6835361847, ekip 7ULGPGPVQ3, bundle `com.owlidea.harftas` kaydedildi), kategori Oyunlar › Kelime + Bulmaca, yaş derecelendirmesi **4+** | Claude ✓ | [elle] |
| C2 | ✓ Uygulama içi ürünler: `harftas.remove_ads` ₺49,99/$3,99 · `harftas.powerups_small` ₺19,99/$1,99 · `harftas.powerups_large` ₺49,99/$3,99 (baz ABD, Türkiye sabit) (Türkçe ad, tüm ülkeler; RevenueCat'e bağlandı). **Kalan:** her ürüne inceleme ekran görüntüsü (iOS derlemesinden sonra) | Claude ✓ / Birlikte | [elle] |
| C3 | `flutter build ipa` → TestFlight; **Sandbox** hesabıyla satın alma + geri yükleme | Birlikte | [elle] |
| C4 | ✓ App Store **App Privacy** yayınlandı (8 veri türü, gizlilik URL'si GitHub Pages) | Claude ✓ | [elle] |
| C5 | ✓ App Store: alt başlık, açıklama, anahtar kelimeler (rakip adı "kelimelik" çıkarıldı → "kelimeoyunu"), destek URL'si, telif, sürüm 1.0.0, İçerik Hakları (üçüncü taraf içerik var, haklar mevcut: Zemberek Apache 2.0) | Claude ✓ | [elle] |

## D. Mağaza kayıtları (paralel yürür)

| # | İş | Kim | Kontrol |
|---|---|---|---|
| D1 | ✓ Mağaza metinleri girildi: App Store (kayıtlı) ve Play varsayılan mağaza girişi (**taslak** — Play, simge + öne çıkan görsel + ekran görüntüleri yüklenmeden tam kaydetmiyor). Play mağaza ayarları: kategori Kelime, e-posta `support@owlidea.com`, web `owlidea.github.io/harftas/destek.html` | Claude ✓ | [elle] |
| D2 | Ekran görüntüleri ve Play öne çıkan görsel (taslaklar: `docs/magaza-gorselleri*`) | Birlikte | [elle] |
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

- [x] Kod: `flutter analyze` temiz, 126 birim + 2 ekran testi geçiyor
- [x] Mobil oyun düzeni, ekran yeniden tasarımları, uygulama içi bildirim/onay panelleri
- [x] Gizlilik metinleri (uygulama içi + `web/gizlilik.html`) AdMob ve RevenueCat'i doğru anlatıyor
- [x] RevenueCat: Harftaş projesi, iOS/Android uygulamaları, 6 ürün, `premium` yetkisi, `default` teklifi, SDK anahtarları `config/prod.json`'da (`docs/revenuecat.md`)
- [x] Play Console: Harftaş uygulaması (`com.owlidea.harftas`, Türkçe, Oyun, Ücretsiz)
- [x] Play servis hesabı RevenueCat'e bağlandı (hesap düzeyi izinler; anahtar kuralı geri açıldı)
- [x] Sürüm: `pubspec.yaml` 1.0.0+1 = `AppInfo.version`
- [x] `SKAdNetworkItems`: Google'ın güncel 50 kimliği (`ios/Runner/Info.plist`, kaynak: AdMob 3p-skadnetworks, 30 Ocak 2026)
- [x] `ios/Runner/PrivacyInfo.xcprivacy` eklendi ve Xcode projesine kaydedildi (Xcode olmadığı için derlemeyle doğrulanmadı — ilk iOS arşivinde Privacy Report'a bak)
- [x] Mağaza belgesi güncellendi: açıklamadaki "kişisel veri yok" kaldırıldı, derecelendirme (4+/PEGI 3) ile hedef kitle (13+) ayrıştırıldı, RevenueCat beyanları ve form yanıtları eklendi

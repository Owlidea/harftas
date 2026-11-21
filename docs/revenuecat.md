# RevenueCat kurulumu

## Durum (15 Kasım 2026)

RevenueCat tarafı kuruldu (proje **Harftaş**, `app.revenuecat.com/projects/3eeee9c9`):

- [x] App Store uygulaması `com.owlidea.harftas` (mevcut In-App Purchase anahtarı G5FDTX56AQ bağlı)
- [x] Play Store uygulaması `com.owlidea.harftas`
- [x] 6 ürün (her mağazada `remove_ads` tüketilmeyen, `powerups_small` / `powerups_large` tüketilen)
- [x] `premium` yetkisi → iki `remove_ads` ürününe bağlı
- [x] `default` teklifi (geçerli/default) → 3 özel paket, her biri iki mağazadaki ürüne bağlı
- [x] Public SDK anahtarları `config/prod.json` içinde

Google Play (15 Kasım 2026):

- [x] Play Console'da **Harftaş** uygulaması oluşturuldu (Owlidea hesabı, `com.owlidea.harftas`,
      Türkçe, Oyun, Ücretsiz; uygulama kimliği 4972005814906714878).
- [x] Servis hesabı hazır: `revenuecat@project-3d457fde-d233-4d9d-bbf.iam.gserviceaccount.com`
      hesap düzeyinde (tüm uygulamalar) uygulama bilgisi + finansal veri + sipariş yönetimi izinlerine
      sahip; Harftaş'ı otomatik kapsar.

Kalanlar (sizin hesabınızda):

- [x] Servis hesabı JSON anahtarı RevenueCat'e yüklendi ve kaydedildi. Doğrulama şu an
      "package name was not found" diyor: Play'e henüz hiç sürüm yüklenmediği için beklenen durum.
      İlk dahili test sürümü yüklenince RevenueCat → Harftaş (Play Store) → **Check again**.
      (Not: Owlidea kurumunda `iam.disableServiceAccountKeyCreation` açık; anahtar için My First
      Project'te geçici olarak kapatıldı → iş bitince **Inherit parent's policy** ile geri açılmalı.)
- [ ] (İsteğe bağlı) Google developer notifications → "Connect to Google" (gerçek zamanlı olaylar).
- [ ] **Play ürünleri:** Play Console, ilk imzalı sürüm (FATURALANDIRMA izinli AAB) bir test
      kanalına yüklenmeden tek seferlik ürün oluşturmaya izin vermiyor. İlk dahili test sürümünden
      sonra `remove_ads`, `powerups_small`, `powerups_large` eklenecek.
- [x] **App Store Connect ürünleri** (16 Kasım 2026): uygulama kaydı "Harftaş: Kelime Bulmaca"
      (Apple ID 6835361847, ekip 7ULGPGPVQ3). Apple ürün kimlikleri **hesap genelinde** benzersiz
      olduğundan (`remove_ads` başka bir uygulamada kullanılıyor) iOS kimlikleri önekli:
      `harftas.remove_ads` (tüketilmeyen, ₺49,99 / $3,99), `harftas.powerups_small` (tüketilen,
      ₺19,99 / $1,99), `harftas.powerups_large` (tüketilen, ₺49,99 / $3,99). Türkçe ad/açıklama girildi, tüm ülkeler açık.
      RevenueCat'te bu üç ürün oluşturuldu, `premium` yetkisine ve `default` teklifinin paketlerine
      bağlandı. Paket kimlikleri (`remove_ads` …) değişmedi; kod paket kimliğiyle eşleştirdiği için
      uygulama değişikliği gerekmez. Eski önek'siz App Store ürünleri RevenueCat'te kullanılmıyor
      (silinebilir; eski `remove_ads` App Store ürünü hâlâ `premium`'a bağlı, zararsız).
- [ ] App Store ürünleri için **inceleme ekran görüntüsü** (her üründe zorunlu) — ilk iOS
      derlemesinden sonra mağaza ekranının görüntüsü yüklenecek; ilk ürünler uygulama sürümüyle
      birlikte incelemeye gönderilir.
- [ ] Sandbox / lisans testi (§5).

Uygulama tarafı hazır (`RevenueCatPurchaseService`, `lib/services/purchase_service.dart`).
Aşağıdaki adımlar mağaza konsollarında ve RevenueCat panelinde **sizin hesabınızla** yapılır.
Kimlikler koddakiyle birebir aynı olmalı.

## 1. Mağaza ürünleri

| Paket / Play kimliği | App Store kimliği | Tür | Ne verir | Fiyat (TR / ABD) |
|---|---|---|---|---|
| `remove_ads` | `harftas.remove_ads` | Tüketilmeyen (Non-Consumable / tek seferlik) | Reklamsız oyun (kalıcı) | ₺49,99 / $3,99 |
| `powerups_small` | `harftas.powerups_small` | Tüketilen (Consumable) | Her güçlendiriciden 3 | ₺19,99 / $1,99 |
| `powerups_large` | `harftas.powerups_large` | Tüketilen (Consumable) | Her güçlendiriciden 10 | ₺49,99 / $3,99 |

App Store'da önek zorunlu: Apple ürün kimlikleri geliştirici hesabındaki tüm uygulamalar arasında
benzersiz olmalı. App Store fiyatlandırması: baz ülke ABD, Türkiye elle sabit; diğer ülkeleri Apple
ABD fiyatından hesaplar (ör. €1,99/€3,99, £1,99/£3,99). Play'de ürünler oluşturulunca aynı ABD
fiyatları baz alınmalı.

- **App Store Connect** → Uygulama → Monetization → In-App Purchases → `+`.
  Türleri yukarıdaki gibi seç, Türkçe görünen ad + açıklama ve inceleme ekran görüntüsü ekle.
- **Google Play Console** → Monetize → Products → In-app products → Create product.
  Play'de ürün türü ayrımı yok; tüketilme kodda yapılıyor (RevenueCat paneline türünü bildireceksin).
  Play ürünleri oluşturmak için uygulamanın en az bir kez bir test kanalına (internal testing)
  faturalandırma izniyle yüklenmiş olması gerekir.

## 2. RevenueCat projesi

1. app.revenuecat.com → **Create project** → "Harftaş".
2. **Apps** → `+ App Store` → Bundle ID `com.owlidea.harftas`.
   App Store Connect'ten **In-App Purchase Key** (.p8) oluşturup yükle (makbuz doğrulama için).
3. **Apps** → `+ Play Store` → Package `com.owlidea.harftas`.
   Google Cloud'da servis hesabı oluşturup Play Console'da finans izniyle davet et, JSON'u yükle.
   (İzinlerin geçerli olması 24–36 saat sürebilir.)

## 3. Ürünler, yetki (entitlement), teklif (offering), paketler

**Products** sekmesi → her iki uygulama için 3 ürünü içe aktar (Import) veya elle ekle:
Play'de `remove_ads`, `powerups_small`, `powerups_large`; App Store'da aynı adlar `harftas.`
önekiyle. Play ürünlerinde türü **Consumable /
Non-consumable** olarak işaretle.

**Entitlements** → `+ New`:
| Kimlik | Bağlı ürünler |
|---|---|
| `premium` | `remove_ads` (App Store) + `remove_ads` (Play Store) |

Güçlendirici paketleri yetkiye bağlanmaz; tüketilen ürünlerdir.

**Offerings** → `+ New` → kimlik `default` → **Make current** (geçerli teklif olmalı).
İçine 3 **Custom** paket ekle; paket kimliği ürün kimliğiyle aynı olmalı:

| Paket kimliği (Custom) | App Store ürünü | Play Store ürünü |
|---|---|---|
| `remove_ads` | `harftas.remove_ads` | `remove_ads` |
| `powerups_small` | `harftas.powerups_small` | `powerups_small` |
| `powerups_large` | `harftas.powerups_large` | `powerups_large` |

## 4. Anahtarları uygulamaya ver

RevenueCat → Project settings → **API keys** → her uygulamanın **Public SDK key**'i
(`appl_…`, `goog_…`). Bunlar uygulamanın içinde yayımlanmak için tasarlanmıştır; gizli
(secret, `sk_…`) anahtarı **asla** uygulamaya koyma.

`config/prod.json` (git'e girmez; `prod.example.json`'dan kopyala):

```json
"REVENUECAT_APPLE_KEY": "appl_…",
"REVENUECAT_GOOGLE_KEY": "goog_…"
```

Derleme: `flutter build ipa --release --dart-define-from-file=config/prod.json`
(Android: `flutter build appbundle --release --dart-define-from-file=config/prod.json`).
Anahtar yoksa mağaza ekranı "şu an kullanılamıyor" durumunu gösterir; oyun çalışmaya devam eder.

## 5. Test

- iOS: App Store Connect → Users and Access → **Sandbox testers**; cihazda Ayarlar → App Store →
  Sandbox hesabı.
- Android: Play Console → **License testing** listesine Gmail adresini ekle; uygulamayı internal
  testing kanalından yükle.
- Kontrol et: üç ürün fiyatıyla görünüyor; `remove_ads` alınca reklamlar kalkıyor; uygulamayı
  silip kurunca Ayarlar → **Satın almaları geri yükle** reklamsızlığı geri getiriyor;
  güçlendirici paketleri her alımda sayıları artırıyor. RevenueCat → Customers'ta işlemler görünüyor.

## 6. Gizlilik beyanları

RevenueCat satın alma geçmişini ve anonim uygulama kullanıcı kimliğini işler. Gizlilik politikasına
(`web/gizlilik.html`) RevenueCat'i alt işleyen olarak ekle; App Store "App Privacy" ve Play
"Data safety" formlarında **Purchases / Purchase history** verisini "uygulama işlevi" amacıyla
beyan et.

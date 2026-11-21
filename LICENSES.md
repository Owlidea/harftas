# Lisanslar

## Veri

| Kaynak | Kullanım | Lisans |
|---|---|---|
| [Zemberek-NLP](https://github.com/ahmetaa/zemberek-nlp) `morphology/src/main/resources/tr/master-dictionary.dict` | Oyun sözlüğü (süzülmüş) | Apache License 2.0 — © 2018 Ahmet A. Akın, Mehmet D. Akın |
| Zemberek-NLP `first-10K` | "Yaygın kelimeler" listesi | Apache License 2.0 |

Ham dosyalar ve lisans metni: `tool/dict/source/`. Lisans metni uygulamada
Ayarlar → Hakkında → Açık kaynak lisansları altında gösterilir (`assets/config/ZEMBEREK_LICENSE.txt`).

> Not: Zemberek deposunun README'si "kod Apache 2.0" der; sözlük dosyaları aynı depoda, ayrı bir
> lisans belirtilmeden dağıtılır ve depo kökündeki Apache 2.0 lisansı kapsamındadır. Yayın öncesi
> bir hukuk danışmanına teyit ettirmeniz önerilir (bkz. `docs/yayin_kontrol_listesi.md`).

## Yazı tipi

| Kaynak | Kullanım | Lisans |
|---|---|---|
| [Nunito](https://github.com/googlefonts/nunito) (Vernon Adams, Cyreal, Jacques Le Bailly) | Uygulamanın tek yazı tipi; `assets/fonts/Nunito-{Regular,Medium,SemiBold,Bold,ExtraBold}.ttf` | SIL Open Font License 1.1 (`assets/fonts/Nunito-OFL.txt`) |

Sabit ağırlıklar Google Fonts'taki değişken `Nunito[wght].ttf` dosyasından `fontTools varLib.instancer`
ile üretildi (OFL türev çalışmaya izin verir; ad "Nunito" ayrılmış ad değildir). Lisans metni
uygulamada Açık kaynak lisansları ekranında gösterilir.

## Kütüphaneler (doğrudan bağımlılıklar)

| Paket | Neden | Lisans |
|---|---|---|
| Flutter SDK, flutter_localizations, material_ui | Çatı, arayüz, yerelleştirme | BSD-3-Clause |
| intl | Yerelleştirme | BSD-3-Clause |
| path_provider | Kayıt dosyası konumu | BSD-3-Clause |
| flutter_svg | Teslim edilen SVG simge/logo/rozetler | MIT |
| lottie | Teslim edilirse kutlama animasyonları | MIT |
| flutter_soloud | Düşük gecikmeli ses, perde değişimi | MIT |
| share_plus | Paylaşım kartı | BSD-3-Clause |
| flutter_local_notifications | Günlük hatırlatma | BSD-3-Clause |
| timezone | Bildirim zamanlama (TZDateTime) | BSD-2-Clause |
| google_mobile_ads | Ödüllü/geçiş reklamı + UMP onay formu | Apache License 2.0 |
| purchases_flutter (RevenueCat) | Satın almalar, makbuz doğrulama, premium yetkisi | MIT |
| app_tracking_transparency | iOS izleme izni (ATT) | MIT |

Geçişli bağımlılıkların tam listesi uygulama içindeki lisans sayfasında otomatik üretilir.

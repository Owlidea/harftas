# Harftaş

Türkçe harfli blok bulmaca — Flutter (iOS, Android, web).

## Çalıştırma

```bash
flutter pub get
```

**Webde dene (en hızlı):**
```bash
flutter run -d chrome --dart-define=FAKE_SERVICES=true
```
Webde reklam, satın alma, bildirim ve ses yerine sahte/sessiz uygulamalar çalışır; kayıtlar
tarayıcının localStorage'ında tutulur. Telefon görünümü için tarayıcıyı dar bir pencereye alın.

Derlenmiş web sürümünü yerel sunucuda açmak:
```bash
flutter build web --release && python3 -m http.server 8765 --directory build/web
```
→ http://localhost:8765

**Android:** `flutter run` (emülatör ya da cihaz). Sahte reklam/satın almayla:
`flutter run --dart-define=FAKE_SERVICES=true`.
**iOS:** tam Xcode kurulumu gerekir (bu makinede yok).

## Testler ve araçlar

| Komut | Ne yapar |
|---|---|
| `flutter test` | 126 birim testi: Türkçe harf, tespit, puan, RNG, üretim, motor, replay, ilerleme, kontrast |
| `flutter test test_screens` | Tüm ekranların açık/koyu PNG görüntüleri → `docs/screenshots/` |
| `dart run tool/build_dictionary.dart` | Zemberek'ten sözlüğü yeniden üretir (bayt bayt aynı çıktı) |
| `dart run tool/simulate.dart --games 1000 --bot common` | Denge simülatörü (`--min 4`, `--mode daily`, `--tiers ...`) |
| `dart run tool/export_balance.dart` | Varsayılan dengeyi `assets/config/balance.json`'a yazar |

## Yapı

```
lib/core/       saf oyun mantığı (Flutter yok): metin, RNG, üretim, kurallar, motor
lib/progress/   saf ilerleme: takvim, seri, görevler, XP, defter, profil
lib/data/       kalıcılık (dosya / localStorage), sözlük yükleyici
lib/services/   ses, dokunsal, reklam, satın alma, bildirim, onay, analitik (arayüz + uygulama)
lib/ui/         tema (tokens), bileşenler, oyun çizimi, ekranlar
lib/config/     varlık yolları, uygulama/reklam kimlikleri
tool/           sözlük betiği, simülatör
docs/           kararlar, algoritma, denge raporu, mağaza/yayın belgeleri, ekran görüntüleri
```

Belgeler: `docs/KARARLAR.md`, `docs/algoritma.md`, `docs/denge_raporu.md`,
`docs/magaza_ve_yayin.md`, `docs/yayin_kontrol_listesi.md`, `docs/elle_test_listesi.md`,
`ASSETS.md`, `LICENSES.md`.

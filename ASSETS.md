# Varlık durumu (ASSETS.md)

Tüm yollar `lib/config/asset_paths.dart` içinde tanımlıdır. Bir dosyayı aşağıdaki yola koymanız
yeterlidir: **kod değişikliği gerekmez** (klasörler pubspec'te tanımlı; uygulama açılışta dosyanın
varlığını kontrol edip yer tutucu yerine gerçek dosyayı kullanır). Ayrıntılı ölçüler: `docs/VARLIKLAR.md`.

Durum: ⏳ bekleniyor · ✅ teslim edildi · 🧩 kodla yapıldı

## Kodla yapılanlar (sizden istenmiyor)
| Öğe | Durum |
|---|---|
| Izgara, sürükleme önizlemesi, kelime vurgusu, karo harf ve puanları | 🧩 |
| Karo gövdeleri (5 stil): `assets/images/tiles/tile_{classic,soft,sharp,grain,marble}.png` + `tiles.json`, Blender render'ı; kod tema rengiyle boyar. Dosya yoksa kodla çizilen karoya düşer | ✅ Blender |
| Patlama parçacıkları, puan etiketleri, kombo sarsıntısı, sayaçlar | 🧩 |
| Tema paletleri (7 tema × açık/koyu) ve renk körlüğü paleti | 🧩 |
| Takvim, ilerleme çubukları, rozet yer tutucuları, paylaşım kartı yerleşimi | 🧩 |
| Yeni rekor / ızgara boşaldı / seviye kutlamaları (Lottie gelene kadar) | 🧩 |
| Harf karolarından oluşan geçici logo | 🧩 (yer tutucu) |
| 20 arayüz simgesinin çizgi yer tutucuları | 🧩 (yer tutucu) |

## Görsel ve animasyon
| # | Yol | Durum | Öncelik | Aşama |
|---|---|---|---|---|
| 1 | `assets/fonts/Nunito-{Regular,Medium,SemiBold,Bold,ExtraBold}.ttf` (+ `Nunito-OFL.txt`) | ✓ | Zorunlu | 3 |
| 2 | `assets/images/brand/logo_light.svg`, `logo_dark.svg` | ⏳ | Zorunlu | 3 |
| 3 | `assets/images/icons/ic_{pause,settings,book,missions,calendar,stats,share,sound,music,haptic,back,home,close,lock,check,store,info,powerup_refresh,powerup_joker,powerup_hammer,streak,crown,gift,star,palette,tiles}.svg` | ⏳ | Zorunlu | 3 |
| 4 | `assets/branding/app_icon_ios_1024.png` (Blender: H ve K karoları; `tool/blender/render_brand.py`) | ✅ | Zorunlu | 5 |
| 5 | `assets/branding/android_{fg,bg}.png` (Blender), `android_mono.png` (kodla, düz) → `android/app/src/main/res/mipmap-anydpi-v26/` | ✅ | Zorunlu | 5 |
| 6 | `assets/branding/splash_mark.png` (Blender) | ✅ | Zorunlu | 3 |
| 7 | `assets/images/badges/streak_{7,30,100}.png` (512 px, Blender) | ✅ | Zorunlu | 4 |
| 7b | `assets/images/art/{star,flame,crown,lock,gift}.png` (512 px 3B ikonlar; `ArtIcon` yoksa çizgi simgeye düşer) | ✅ | Olursa iyi | 4 |
| 8 | `assets/images/badges/level_*.svg` | ⏳ | Olursa iyi | 4 |
| 9 | `assets/images/themes/preview_<tema>.png` (classic, olive, lavender, amber, dawn, sea, midnight) | ⏳ | Olursa iyi (canlı önizleme var) | 4 |
| 10 | `assets/images/empty/{wordbook,calendar,missions}.svg` | ⏳ | Olursa iyi | 3–4 |
| 11 | `assets/images/tutorial/hand.svg` | ⏳ | Olursa iyi | 3 |
| 12 | `assets/anim/new_record.webp` (Blender kare dizisi, 6×6 kare, 30 fps; Lottie `.json` de hâlâ desteklenir) | ✅ | Olursa iyi | 3 |
| 13 | `assets/anim/board_clear.webp`, `assets/anim/level_up.webp` (Blender kare dizisi) | ✅ | Olursa iyi | 3–4 |
| 13b | Tahta efektleri: `assets/anim/{tile_pop,hammer,joker,combo_burst,combo_nums}.webp` (tahta ressamı çizer), `refresh.webp`, `gift_open.webp`, `sparkle_burst.webp`, `flame_loop.webp`; ızgara bilgisi `anims.json` | ✅ | Olursa iyi | 4 |
| 13c | Tahta zeminleri: `assets/images/boards/board_{felt,grain,marble}.webp` (gri tonlu, tema rengiyle çarpılır) | ✅ | Olursa iyi | 4 |

Not: Uygulama simgesi ve açılış ekranı yerel proje dosyalarına girer (Flutter varlığı değildir).
Teslim ettiğinizde `docs/yayin_kontrol_listesi.md` §3'teki adımı uygulayacağım.

Blender varlıkları `tool/blender/build.sh` ile yeniden üretilir (Blender 5.x; betikler: `render_tiles.py`,
`render_icons.py`, `render_anims.py`, `render_boards.py`, `render_brand.py`, `render_video.py`; animasyonlar ve
zeminler için `brew install webp`). Aynı anda tek Blender işi çalıştırın (iki GPU render'ı belleği taşırır). Önizleme için `preview_tiles.py` ve `contact_sheet.py`.

Sizden beklenen görsel ve sesler için hazır üretim promptları: `docs/GORSEL_PROMPTLARI.md`.

## Ses (`assets/audio/`, 44,1 kHz OGG Vorbis; efektler mono, müzik stereo)
| Dosya | Durum | Öncelik |
|---|---|---|
| `pick.ogg`, `drop.ogg`, `invalid.ogg` (+ `pick_2..4`, `drop_2..4`) | ✓ sentez | Zorunlu |
| `word_s.ogg`, `word_m.ogg`, `word_l.ogg` | ✓ sentez | Zorunlu |
| `combo_1.ogg`, `combo_2.ogg`, `combo_3.ogg` | ✓ sentez | Zorunlu |
| `streak_up.ogg`, `board_clear.ogg`, `new_record.ogg`, `game_over.ogg` | ✓ sentez | Zorunlu |
| `button.ogg` (+ `button_2..4`), `level_up.ogg`, `mission_done.ogg` | ✓ sentez | Zorunlu |
| `pu_refresh.ogg`, `pu_joker.ogg`, `pu_hammer.ogg` | ✓ sentez | Zorunlu |
| `music_loop.ogg` (41 sn döngü) | ✓ sentez | Olursa iyi |

Tüm sesler `tool/sfx/synth.py` ile koddan sentezlenir (lisans gerektirmez); yeniden üretmek için
`tool/sfx/build.sh` (python3 + numpy/scipy, `brew install vorbis-tools`). `_2.._4` dosyaları
rastgele çalınan varyasyonlardır. Ses dosyası yokken oyun sessiz çalışır; dokunsal geri bildirim bağımsızdır.

## Mağaza
| Öğe | Durum |
|---|---|
| Ekran görüntüsü çerçeve/başlık şablonu (1320×2868, 2064×2752, 1080×1920) | ⏳ |
| Google Play öne çıkan görsel 1024×500: `docs/magaza-gorselleri-v6/one-cikan-gorsel.png`, logo: `logo.png` (Blender) | ✅ |
| Tanıtım videosu: `docs/magaza-gorselleri-v6/tanitim.mp4` (8 sn, 1080×1920, sessiz; `tool/blender/render_video.py`) | ✅ |
| Tanıtım videosu müziği (isteğe bağlı) | ⏳ |

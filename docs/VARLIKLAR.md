# İlk varlık talep tablosu

Varlık yolları `lib/config/asset_paths.dart` dosyasında tanımlanacak. Nihai varlıklar gelene kadar ilgili aşamalarda aynı yollarda yer tutucular kullanılacak. Yazı tipi için sistem fontu kullanılacak. Ses yer tutucuları sessiz olacak.

Karolar, harf ve puan yerleşimi, ızgara, gölgeler, gradyanlar, sürükleme önizlemesi, kelime vurgusu, patlama parçacıkları, puan etiketleri, ekran sarsıntısı, konfeti, temel kutlamalar, ilerleme çubukları, takvim hücreleri, paylaşım kartı yerleşimi, tema renkleri ve renk körlüğü paleti kodla yapılacak. Paylaşım kartında kullanılacak logo aşağıdaki varlık teslimine dahil.

## Görsel ve animasyon

| # | Yol | Kullanım | Teslim özellikleri | Öncelik | Aşama |
| --- | --- | --- | --- | --- | --- |
| 1 | `assets/fonts/<Aile>-{Regular,Medium,SemiBold,Bold}.ttf` | Tüm metinler ve karo harfleri | TTF veya OTF ve lisans dosyası. Dört ağırlıkta büyük `İ` ve `I` ayırt edilebilmeli. | Zorunlu | 1'de sistem fontu, 3'te teslim |
| 2 | `assets/images/brand/logo_light.svg`, `assets/images/brand/logo_dark.svg` | Ana menü, paylaşım kartı ve Hakkında | Şeffaf SVG, yaklaşık 3:1 `viewBox`, açık ve koyu tema sürümleri | Zorunlu | 3 |
| 3 | `assets/images/icons/ic_*.svg` | Tüm ekranlar | Şeffaf SVG, 24×24 ızgara, 2 px çizgi. Kodda renklendirilecek tek renkli, tek sürüm. | Zorunlu | 3 |
| 4 | `assets/branding/app_icon_ios_1024.png` | iOS simgesi | 1024×1024 PNG, opak zemin ve düz köşeler | Zorunlu | 1'de yer tutucu, 5'te teslim |
| 5 | `assets/branding/android_fg.png`, `assets/branding/android_bg.png`, `assets/branding/android_mono.png` | Android uyarlanabilir simgesi | Her katman 432×432 PNG (108 dp @xxxhdpi). Güvenli alan ortadaki 264 px çaplı daire. Ön plan ve mono katman şeffaf. Mono katman Android 13 temalı simge için. | Zorunlu | 5 |
| 6 | `assets/branding/splash_mark.png` | Açılış ekranı | Şeffaf 1152×1152 PNG. Android 12 için işaret 768 px çaplı daireye sığmalı. Açık ve koyu zemin rengi koddan uygulanacak. | Zorunlu | 3 |
| 7 | `assets/images/badges/streak_{7,30,100}.svg` | Seri rozetleri | Şeffaf SVG, 1:1, `viewBox="0 0 256 256"`, rozet başına tek sürüm | Zorunlu | 4 |
| 8 | `assets/images/badges/level_*.svg` | Seviye ödül rozetleri | Şeffaf 1:1 SVG. Rozet sayısı daha sonra belirlenecek. | Olursa iyi | 4 |
| 9 | `assets/images/themes/preview_<tema>.png` | Ayarlar → Tema seçimi | Tema başına bir opak 9:16 önizleme, 180×320 pt. PNG boyutları @2x için 360×640 px, @3x için 540×960 px. Canlı önizleme kodla da yapılabilir. | Zorunlu | 4 |
| 10 | `assets/images/empty/{wordbook,calendar,missions}.svg` | Boş durumlar | Şeffaf SVG, yaklaşık 4:3. Açık ve koyu tema sürümleri veya tek renk. | Olursa iyi | 3–4 |
| 11 | `assets/images/tutorial/hand.svg` | Öğretici işaret eli | Şeffaf 1:1 SVG, tek sürüm. Hareket kodla uygulanacak. | Olursa iyi | 3 |
| 12 | `assets/anim/new_record.json` | Yeni rekor kutlaması | Şeffaf 1:1 Lottie, 30 fps, yaklaşık 1,5 sn. Rekor kırılınca bir kez oynatılır. Boş kareyle başlar ve biter. Tek renk paleti, mümkünse renkler kodla değiştirilebilir. | Olursa iyi, kodla da yapılabilir | 3 |
| 13 | `assets/anim/board_clear.json`, `assets/anim/level_up.json` | Izgara boşaldığında ve seviye atlandığında | Şeffaf 1:1 Lottie, 30 fps, 1–1,5 sn, tek oynatım | Olursa iyi | 3–4 |

Simge dosyaları `ic_` öneki ve `.svg` uzantısı ile adlandırılır. Adlar `pause`, `settings`, `book`, `missions`, `calendar`, `stats`, `share`, `sound`, `music`, `haptic`, `back`, `close`, `lock`, `check`, `store`, `info`, `powerup_refresh`, `powerup_joker`, `powerup_hammer` ve `streak`.

## Ses

Kaynak dosyalar 48 kHz, 24 bit WAV. Uygulama dosyaları `assets/audio/` altında 44,1 kHz OGG Vorbis olarak teslim edilir. Efektler mono, müzik stereo.

| Dosya | Olay | Süre | Karakter | Göreli düzey | Öncelik |
| --- | --- | --- | --- | --- | --- |
| `pick.ogg` | Blok alma | 60–100 ms | Yumuşak ahşap veya kâğıt tıkı | Düşük (−18 dB) | Zorunlu |
| `drop.ogg` | Bırakma | 100–150 ms | Tok oturma sesi | Orta-düşük | Zorunlu |
| `invalid.ogg` | Geçersiz bırakma | 150 ms | Kısa, yumuşak geri dönüş sesi | Düşük | Zorunlu |
| `word_s.ogg`, `word_m.ogg`, `word_l.ogg` | Sırasıyla 3–4, 5–6 ve 7–8 harfli kelime | 300, 450, 650 ms | Parlak, melodik ve yükselen | Ortadan orta-yükseğe | Zorunlu |
| `combo_1.ogg`, `combo_2.ogg`, `combo_3.ogg` | Sırasıyla ×2, ×3 ve ×4+ | 400–700 ms | Aynı motif, artan perde ve katman | Orta-yüksek | Zorunlu |
| `streak_up.ogg` | Seri artışı | 250 ms | Hafif tık ve yükseliş | Düşük | Zorunlu |
| `board_clear.ogg` | Izgara boşaldı | 1–1,5 sn | Ferah kutlama | Yüksek | Zorunlu |
| `new_record.ogg` | Yeni rekor | 1–1,5 sn | Zafer motifi | Yüksek | Zorunlu |
| `game_over.ogg` | Oyun sonu | 800 ms | Sakin kapanış | Orta | Zorunlu |
| `button.ogg` | Düğme | 40–60 ms | Çok hafif tık | Çok düşük | Zorunlu |
| `level_up.ogg`, `mission_done.ogg` | Seviye atlama ve görev tamamlama | 700 ms | Ödül hissi | Orta | Zorunlu |
| `pu_refresh.ogg`, `pu_joker.ogg`, `pu_hammer.ogg` | Güçlendiriciler | 300–500 ms | Sırasıyla karıştırma, büyülü dokunuş ve tok vuruş | Orta | Zorunlu |
| `music_loop.ogg` | Arka plan müziği | 60–120 sn, kesintisiz döngü | Sakin, akustik veya lo-fi | Çok düşük | Olursa iyi |

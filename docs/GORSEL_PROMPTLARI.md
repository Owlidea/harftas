# Görsel ve ses üretim promptları

Bu dosyadaki promptlar yapay zekâ görsel/ses araçlarına (Midjourney, DALL·E, Ideogram, Firefly,
Suno, ElevenLabs SFX vb.) yapıştırmak içindir. Promptlar İngilizce yazıldı; araçlar İngilizcede daha
tutarlı sonuç verir. Her maddenin altında **teslim** satırı dosyanın nereye, hangi ölçüde konacağını söyler.

Ortak renkler: fildişi `#FCF8EE`, bej kenar `#D9CDB2`, lacivert mürekkep `#17213A`,
camgöbeği `#0E6F6B`, açık camgöbeği `#4CC3BA`, açık zemin `#F6F3EC`, koyu zemin `#0F1729`.

Genel kural: arka plan **şeffaf ya da düz tek renk** olsun, görselde **yazı olmasın** (yazıyı ben eklerim),
tek nesne ortada ve kenarlardan boşluklu dursun.

---

## 1. Logo — "Harf Kombo" (en acil)

Vektör çıktı veren bir araç (Ideogram, Recraft, Illustrator + Firefly) tercih edin.

```
Minimal wordmark logo for a Turkish word puzzle game called "Harf Kombo". Two stacked rows of rounded
square letter tiles: top row spells HARF on ivory tiles (#FCF8EE) with deep navy letters (#17213A),
bottom row spells KOMBO on teal tiles (#0E6F6B) with white letters. Each tile has a tiny point number
in its bottom-right corner. Soft 3D depth, thin beige base edge under each tile, friendly rounded
geometric sans-serif (similar to Nunito ExtraBold). Flat vector style, clean edges, no gradients
except a subtle top highlight, transparent background, centered, generous padding.
```

Yatay sürüm için sonuna ekleyin: `single horizontal row, 3:1 aspect ratio`.

**Teslim:** `assets/images/brand/logo_light.svg` ve `logo_dark.svg` (koyu zeminde okunacak sürüm),
yaklaşık 3:1. SVG çıkmıyorsa 3000 px genişlikte şeffaf PNG verin, ben vektöre çeviririm.

## 2. Uygulama simgesi

```
Mobile app icon for a word puzzle game. One chunky ivory letter tile (#FCF8EE) with a bold navy
letter "K" (#17213A) and a small number "1" in the bottom-right corner, sitting slightly tilted on a
rich teal background (#0E6F6B) with a faint grid pattern. A second teal tile peeks out from behind it.
Soft studio lighting, glossy ceramic material, subtle drop shadow, 3D render, centered composition,
no text other than the letter, square 1:1, no rounded corners, no border.
```

**Teslim:** `assets/branding/app_icon_ios_1024.png`, 1024×1024, opak, köşeler düz.
Bunu vermezseniz logoyu aldıktan sonra Blender'da kendi karolarımızla ben üretirim (önerim bu:
oyundaki karoyla birebir aynı olur).

## 3. Öğretici eli

```
A friendly cartoon hand with the index finger pointing down and slightly to the left, as if tapping a
touchscreen. Soft 3D clay render, smooth rounded shapes, light neutral skin tone with a subtle teal
(#0E6F6B) sleeve cuff at the wrist, soft studio lighting, gentle shadow under the fingertip only,
transparent background, centered, square 1:1, no text.
```

**Teslim:** `assets/images/tutorial/hand.png`, 512×512, şeffaf. Parmak ucu görselin sol üst
çeyreğinde olursa hizalaması kolay olur.

## 4. Maskot (isteğe bağlı)

```
Cute mascot character for a Turkish word puzzle game: a small rounded ivory letter tile (#FCF8EE)
with big friendly eyes, tiny arms and legs, wearing a teal (#0E6F6B) scarf. Bold navy letter "H" on its
belly. Soft 3D clay render, glossy ceramic material, warm studio lighting, front three-quarter view,
neutral standing pose, transparent background, character sheet with 4 expressions: happy, surprised,
thinking, celebrating.
```

**Teslim:** her ifade ayrı şeffaf PNG, 1024×1024. Bir 3B model (`.glb` / `.fbx`) üretebilirseniz
(Meshy, Tripo, Rodin) onu verin; Blender'da canlandırırım.

## 5. Boş durum çizimleri

Üçü de aynı üslupta olsun diye aynı gövdeyi kullanın, yalnızca konu satırını değiştirin.

```
Small friendly spot illustration, soft 3D clay render, ivory (#FCF8EE) and teal (#0E6F6B) palette with
navy (#17213A) accents, soft studio lighting, minimal, lots of empty space, transparent background,
4:3, no text. Subject: <KONU>
```

- Kelime defteri: `an open empty notebook with a pencil resting on it and two letter tiles beside it`
- Takvim: `a desk calendar with blank pages and a single letter tile leaning against it`
- Görevler: `an empty checklist clipboard with a small gold star next to it`

**Teslim:** `assets/images/empty/{wordbook,calendar,missions}.png`, 800×600, şeffaf.

## 6. Premium karo kaplamaları için doku

Kaplamaları Blender'da ben üretiyorum; isterseniz gerçek doku fotoğrafı/görseli verebilirsiniz.

```
Seamless tileable texture, top-down, evenly lit, no shadows, no objects, 2048x2048. Material: <MALZEME>
```

- `polished light oak wood with fine straight grain`
- `white Carrara marble with soft grey veins`
- `mother of pearl with subtle iridescent swirls`
- `hand-glazed ceramic with tiny speckles, off-white`

**Teslim:** `tool/blender/textures/<ad>.png`.

## 7. Mağaza arka planı ve öne çıkan görsel

```
Wide promotional banner for a word puzzle game, deep teal to dark green gradient background (#0E6F6B
to #0B3D3A), scattered glossy ivory letter tiles floating with depth of field blur at the edges, empty
calm space in the center for a logo, soft volumetric light from top left, 3D render, cinematic, no
text, 1024x500.
```

**Teslim:** `docs/magaza-gorselleri-v6/arka-plan.png`. Logoyu ve yazıyı ben yerleştiririm.

## 8. Ses efektleri

Ses üretim aracına (ElevenLabs Sound Effects, Stable Audio) tek tek verin. Kuru, yankısız, kısa.

| Dosya | Prompt |
|---|---|
| `pick.ogg` | `soft wooden game tile picked up from a table, single short click, dry, close mic, 80 ms` |
| `drop.ogg` | `wooden game tile placed firmly on a wooden board, short solid thock, dry, 120 ms` |
| `invalid.ogg` | `soft muted rubber bump, gentle error feedback, not harsh, 150 ms` |
| `word_s.ogg` | `bright short marimba arpeggio of three rising notes, cheerful, clean, 300 ms` |
| `word_m.ogg` | `bright marimba arpeggio of four rising notes with a light bell on top, 450 ms` |
| `word_l.ogg` | `sparkling marimba and glockenspiel run of five rising notes ending on a shimmer, 650 ms` |
| `combo_1/2/3.ogg` | `same rising marimba motif, each version one step higher and with one more layer (bell, then chime), 400-700 ms` |
| `board_clear.ogg` | `airy celebratory chime sweep with soft whoosh, fresh and open, 1.2 s` |
| `new_record.ogg` | `short triumphant fanfare on marimba and soft brass, uplifting, 1.3 s` |
| `level_up.ogg` | `warm rewarding two-note chime with a soft sparkle tail, 700 ms` |
| `game_over.ogg` | `calm descending two-note marimba, gentle, not sad, 800 ms` |
| `button.ogg` | `very soft ui tick, tiny, 50 ms` |

**Teslim:** `assets/audio/` altına aynı adlarla, 44,1 kHz OGG Vorbis, efektler mono.
WAV verirseniz dönüştürmeyi ben yaparım.

## 9. Müzik döngüsü

```
Calm lo-fi acoustic background loop for a relaxing word puzzle game. Soft felt piano, nylon guitar,
light brushed percussion, warm upright bass, 80 bpm, major key, no vocals, no sudden changes,
seamless loop, 90 seconds.
```

**Teslim:** `assets/audio/music_loop.ogg`, stereo, baş ve son kesintisiz birleşmeli.

---

## Sanat yönü için soru

Aşağıdakilerden hangisi istediğiniz hisse daha yakın? Tek kelimelik cevap yeter; kaplamaları,
tanıtım videosunu ve mağaza görsellerini ona göre ayarlarım.

1. **Mat fildişi / seramik** (şu anki hâl): sakin, sade, "premium bulmaca".
2. **Ahşap masa oyunu**: sıcak, nostaljik, dokulu.
3. **Parlak şeker / oyuncak**: canlı, renkli, daha genç kitle.

# Aşama 2 — Denge Raporu (2026-11-13)

Simülatör: `dart run tool/simulate.dart --games 1000 --min 3 --bot common [--mode daily]`
Sözlük: 19.535 kelime (yaygın: 2.222). Güçlendirici ve "devam" kullanılmadı.
VARSAYIM: insan hamle başına ortalama 4 sn harcar.

İki bot:
- **full** — 19.535 kelimenin hepsini bilen açgözlü bot (usta oyuncunun üst sınırı).
- **common** — yalnızca 2.222 yaygın kelimeyi "bilir"; motor yine tüm kelimeleri patlatır
  (rastlantısal kelimeler dahil). **Ortalama insan için en iyi yaklaşık.**

## MIN_WORD_LEN 3 ve 4 karşılaştırması (Klasik, son ayarlarla)

| Ölçüt | MIN 3 · common | MIN 3 · full | MIN 4 · common |
|---|---|---|---|
| Ortalama hamle | 61.6 | 122.5 | 35.7 |
| Tahmini süre | **4.1 dk** | 8.2 dk | 2.4 dk |
| Ortalama skor | 404 | 1015 | 169 |
| Kelimesiz hamle | %48.8 | %32.6 | **%76.7** |
| Kelime uzunluğu (3/4/5/6+) | 29352 / 4331 / 261 / 4 | 76347 / 12384 / 529 / 11 | – / 7833 / 555 / 18 |

**Karar: MIN_WORD_LEN = 3 kalsın.** MIN 4'te dört hamlenin üçü kelimesiz geçiyor; oyun
"harf bulmacası" yerine "blok dizme" hissi veriyor ve 2,4 dk ile hedefin altında.
MIN 3 ortalama oyuncu için 3–6 dk hedefinin ortasında; her iki hamleden biri kelimeli
(karar gerilimi sütunu karşılanıyor).

## Zorluk eğrisi (uygulandı)

| Skor ≥ | 1 / 2 / 3 / 4 hücre |
|---|---|
| 0 | 15 / 35 / 35 / 15 (spesifikasyon) |
| 300 | 12 / 33 / 37 / 18 |
| 700 | 9 / 29 / 39 / 23 |
| 1200 | 6 / 25 / 41 / 28 |

Eski eşikler (1500/4000/8000) neredeyse hiç devreye girmiyordu. Yeni eğri usta oyununu
10,7 → 8,2 dk kısalttı, ortalama oyuncuyu etkilemedi (4,3 → 4,1 dk).

## Günlük bulmaca

| Ölçüt | Değer |
|---|---|
| Ortalama hamle | 41.1 (%10: 31, %90: 53) |
| Tahmini süre | 2.7 dk |
| Ortalama skor | 219 |
| Kelimesiz hamle | %62.0 |
| Bitiş nedeni | yer kalmadı %96 · 20 el sınırı %4 |

Günlükte ızgaraya bakan kolaylaştırıcı kapalı (karar 5, herkes aynı eli görsün). Yerine
ızgaradan bağımsız "harf kolaylaştırıcısı" eklendi: el, harfleriyle en az bir yaygın 3–4 harfli
kelime yazılabilecek biçimde seçilir. Etkisi küçük (eller zaten çoğunlukla bu şartı sağlıyor).
Sonuç: günlük bulmaca kısa (≈3 dk) ve klasikten zor. 20 el sınırı pratikte nadiren devreye giriyor.

## Öneriler (onayınıza bağlı, uygulanmadı)

1. **Günlük için ayrı sesli oranı:** günlükte %45–65 sesli denenebilir; kelimesiz hamle oranını
   düşürür, adaleti bozmaz. Simülatörde 5 dakikalık iş.
2. **Gerçek oyuncu verisi:** Bot 4 sn/hamle varsayıyor. Aşama 5'te `game_over(duration, moves)`
   analitiğiyle gerçek süre ölçülüp eşikler yeniden ayarlanmalı.
3. **3 harfli kelime baskınlığı:** Kelimelerin ~%85'i 3 harfli. Uzun kelime kovalamayı teşvik
   için 4 harf çarpanı 1.5 → 2 denenebilir (puan gerilimi artar, süre değişmez).

## Ek (2026-11-24): uzunluk çarpanı merdiveni

Öneri 3 uygulandı ve genişletildi (karar 20): 4 ×2, 5 ×3, 6 ×4, 7 ×5, 8 ×6.
`dart run tool/simulate.dart --games 1000 --bot common --mult 4:15,5:20,6:30,7:40` eski değerleri verir.

| Ölçüt | Eski · common | Yeni · common | Eski · full | Yeni · full |
|---|---|---|---|---|
| Ortalama hamle | 62.4 | 62.4 | 122.8 | 121.4 |
| Ortalama skor | 382 | 401 | 989 | 1028 |
| Kelimesiz hamle | %49.1 | %49.0 | %32.9 | %33.0 |

Açgözlü bot uzun kelime "kovalamadığı" için uzunluk dağılımı değişmiyor; gerçek oyuncudaki etki
analitik bağlandıktan sonra ölçülmeli.

## Ek (2026-11-25): İngilizce (karar 30)

Sözlük: SCOWL boyut ≤ 60, 40.814 kelime; yaygın kelimeler 12dicts sıklık sınıfı 1–12 ve çekimleri,
10.207 kelime (`tool/build_dictionary_en.dart`). İlk tahmin tablolarla (Türkçe gibi %40–60 sesli,
20 kolaylaştırma denemesi) İngilizce oyunlar çok uzundu: yaygın-kelime botu 95 hamle, tam bot 262
hamle. İngilizce eller kelimeyi Türkçeden çok daha kolay kuruyor; sözlüğü küçültmek oyuncuya
"bu kelime neden sayılmadı" dedirteceği için görünmeyen iki ayar değişti: sesli oranı %30–45,
kolaylaştırma denemesi 1 (yani yok). Tarama (150 oyun, yaygın-kelime botu / tam bot hamle):

| Sesli | Deneme | Yaygın bot | Tam bot |
|---|---|---|---|
| %40–60 | 20 | 95.2 | 262.5 |
| %30–45 | 20 | 88.7 | 183.5 |
| %30–45 | 5 | 87.3 | 177.6 |
| %30–45 | 2 | 82.5 | 166.5 |
| **%30–45** | **1** | **63.2** | **132.5** |
| %25–40 | 1 | 61.0 | 112.7 |

Son ayarla Türkçe ve İngilizce (`--games 1000 --bot common` / `--games 500`, tohum 1):

| Ölçüt | TR · common | EN · common | TR · full | EN · full |
|---|---|---|---|---|
| Ortalama hamle | 62.4 | 63.8 | 121.8 | 129.4 |
| Ortalama skor | 401 | 429 | 1027 | 1130 |
| Hamle başına kelime | 0.55 | 0.56 | 0.72 | 0.73 |
| Kelimesiz hamle | %49.0 | %49.3 | %33.1 | %33.3 |

İngilizce günlük bulmaca yaygın-kelime botuyla 55 hamle sürüyor (Türkçe 41): biraz daha kolay;
karşılaştırma yalnız aynı dili oynayanlar arasında olduğu için bırakıldı. Gerçek oyuncu verisi
geldikçe yeniden ayarlanmalı. Yeniden üretmek için: `dart run tool/simulate.dart --lang en ...`
(`--vowels min:max`, `--easing N` seçenekleriyle).

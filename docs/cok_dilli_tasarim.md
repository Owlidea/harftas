# Çok dilli kelime desteği — tasarım taslağı

Tarih: 25 Kasım 2026 · Dal: `cok-dilli` · Durum: **onay bekliyor** (sondaki kararlar)

## Amaç

Oyuncu bölgesini (kelime dilini) seçer; ızgarada o dilin harfleri çıkar, kelimeler o dilin
sözlüğüyle doğrulanır. Türkçe deneyim birebir aynı kalır: aynı harf kodları, aynı sözlük, aynı
günlük bulmaca, eski kayıtlar ve tekrar oynatmalar bozulmaz.

## Bugün Türkçeye bağlı olan yerler

| Yer | Ne yapıyor |
|---|---|
| `lib/core/text/alphabet.dart` | `TrAlphabet`: sabit 29 harf, harf kodu 1–29 |
| `lib/core/text/word_key.dart` | Kelimeyi tek sayıya paketler: harf başına 5 bit → **en çok 31 harflik alfabe**, en çok 8 harf |
| `lib/core/text/turkish_text.dart` | İ/ı büyük-küçük harf, şapkalı harfler, ayrışık (NFD) girişleri birleştirme |
| `lib/core/gen/letter_generator.dart`, `hand_generator.dart`, `model/shape.dart` | Sesli oranı (karar 7), nadir harf sınırı (karar 8), Ğ yerleşim kuralı (karar 9) |
| `lib/core/config/balance_config.dart`, `assets/config/balance.json` | Harf puanları, harf ağırlıkları, nadir harfler |
| `lib/core/model/grid.dart`, `rules/word_detector.dart`, `engine/game_engine.dart` | Hücre harf kodları, kelime çözümleme, joker harfinin doğrulanması |
| `assets/dict/words.bin`, `common.bin` | `tool/build_dictionary.dart` (Zemberek, yalın kök: 19.535 kelime, 2.222 yaygın) |
| `lib/app/app.dart`, `lib/l10n/app_tr.arb` | Arayüz yalnızca Türkçe, yerel ayar `tr`'ye sabit (~420 metin) |
| `lib/ui/screens/game_screen.dart`, `wordbook_stats_screens.dart` | Joker harf seçici ve Kelime Defteri sıralaması Türk alfabesini kullanıyor |
| `lib/core/rng/rng.dart` | Günlük bulmaca tohumu yalnızca tarihten: `Rng.dailySeed(yıl, ay, gün)` |

Toplam ~30 çağrı noktası; dil bağımlılığı birkaç dosyada toplanmış.

**İyi haberler:** Karo görselleri harfsiz, harfi `TileRenderer` yazıyor → yeni harfler (Q, W, X, Ä, Ñ…)
için Blender'da yeniden çizim gerekmez. Nunito yazı tipi Q W X Ä Ö Ü ẞ Ñ Ç ve Fransızca/İspanyolca/
Portekizce aksanlı büyük harflerin hepsini içeriyor (25 Kasım 2026'da CoreText ile doğrulandı).

## Mimari önerisi

1. **`WordLanguage` (çekirdek):** kod (`tr`, `en`, `de`, …), sıralı alfabe (≤ 31 harf), sesliler,
   büyük harfe çevirme + normalleştirme kuralları (ör. Fransızca/İspanyolca aksanların atılması,
   Almanca ß → SS ya da ẞ), dile özel yerleşim kuralları (Türkçe Ğ), kelime uzunluk sınırları.
   `TrAlphabet` ve `TurkishText` bunun Türkçe örneğinin arkasına geçer; Türkçe harf sırası ve kodları
   değişmez.
2. **Dil başına varlıklar:** `assets/dict/<dil>/words.bin` + `common.bin`; `balance.json` içinde
   dil başına harf tabloları (puan, ağırlık, nadir harf, sesli oranı); `tool/dict/<dil>/` altında
   kaynak, engel listesi, lisans dosyası ve rapor. `tool/build_dictionary.dart --lang <dil>`.
3. **Oyun durumu:** `GameState.language` (eski kayıtlarda yoksa `tr`). Süren oyun kendi dilinde
   biter; dil değişince yeni oyun yeni dille başlar.
4. **Günlük bulmaca dil başına:** Türkçe tohum aynen kalır; diğer diller tohuma dil kodunu karıştırır.
   Aynı dili seçen herkes aynı bulmacayı görür; paylaşım metnine dil eklenir.
5. **İlerleme:** XP, seviye, görevler, haftalık hedef, başarımlar ve envanter **ortak**; rekorlar,
   Kelime Defteri ve kelime istatistikleri **dil başına**; günlük seri herhangi bir dildeki günlük
   bulmacayla sürer.
6. **Bölge / kelime dili seçimi:** ilk açılışta cihazın bölgesinden (TR → Türkçe, DE/AT/CH →
   Almanca, US/GB/AU/CA… → İngilizce, …), desteklenmeyen bölgede İngilizce; Ayarlar → "Kelime dili"
   ile değişir; ilk açılış tanıtımında da gösterilir.
7. **Arayüz dili** kelime dilinden bağımsız: cihaz dili çevrilmişse o, değilse İngilizce (Türkçe
   cihaz → Türkçe arayüz). Böylece ör. Türkçe öğrenen biri İngilizce arayüzle Türkçe oynayabilir.
8. **Mağaza:** marka "Harf Kombo" her yerde aynı, alt ad yerelleşir ("Harf Kombo: Word Puzzle",
   "Harf Kombo: Wortspiel", …). Her dilin açıklaması ve anahtar kelimeleri ayrı; **ekran
   görüntüleri dil başına** gerekir (ızgarada o dilin harfleri ve kelimeleri görünür).

## Aşamalar

| Aşama | İçerik | Bitti sayılır |
|---|---|---|
| Ç1 Çekirdek | `WordLanguage`, Türkçe onun arkasında, kayıtlarda dil alanı | 158 test + tekrar oynatma ve günlük bulmaca testleri değişmeden geçer |
| Ç2 İngilizce pilot | Sözlük (lisanslı kaynak), engel listesi, denge simülasyonu, `app_en.arb`, kelime dili seçici, dil başına günlük/defter/rekor | `tool/simulate.dart --lang en`: ortalama oyun süresi ve skor Türkçeye yakın; elle test |
| Ç3 Diğer diller | Almanca, Fransızca, İspanyolca, … teker teker: sözlük + denge + çeviri | Her dil için aynı ölçütler |
| Mağaza | Dil başına metin, ekran görüntüleri (sizden), mağaza dilleri | İki mağazada her dil sayfası dolu |

**Yayın önerisi:** 1.0 Türkçe olarak şimdi çıkar (hazırlığı bitmek üzere); çok dilli sürüm 1.1
olarak gelir. 1.0'ı beklemek inceleme riskini ve gecikmeyi büyütür, Türkiye'deki tutunma verisini
de geciktirir.

## Kaynaklar ve lisanslar

<!-- LİSANS-ARAŞTIRMASI -->

## Onay bekleyen kararlar

1. **İlk diller ve sıra** — öneri: İngilizce pilot, ardından Almanca (en büyük Türk diasporası da
   orada), sonra Fransızca ve İspanyolca.
2. **Kelime biçimleri** — Türkçede yalın kök (karar 12) sürer. İngilizce ve diğer dillerde çoğul ve
   çekimli hâller de geçerli olsun (o dillerdeki kelime oyunlarının alışkanlığı); sözlük büyüklüğü
   simülatörle dengelenir.
3. **İlerlemenin paylaşımı** — yukarıdaki 5. madde.
4. **1.0'ın beklememesi** — yukarıdaki yayın önerisi.

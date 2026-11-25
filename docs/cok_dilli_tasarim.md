# Çok dilli kelime desteği — tasarım taslağı

Tarih: 25 Kasım 2026 · Dal: `cok-dilli` · Durum: **Türkçe + İngilizce uygulandı** (karar 29, 30); diğer diller sırada

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

Kaynak sayfalarında doğrulandı (25 Kasım 2026). "Paketlenebilir" = kapalı kaynak ticari uygulamada
lisans notuyla dağıtılabilir; "liste yayımlanmalı" = türetilen kelime listesi aynı lisansla ayrıca
yayımlanırsa (ör. web sitesinde) paketlenebilir. Uygulama kodu kapalı kalır.

| Dil | Geçerli kelimeler | Sıklık ("yaygın" kelimeler) | Durum |
|---|---|---|---|
| İngilizce | SCOWL (Kevin Atkinson; MIT benzeri, bildirim yeterli; ABD/İngiltere yazımları ayrı; 2026 sürümü ESDB adıyla) | 12dicts (kamu malı) ya da Google Books Ngram (CC BY 3.0) | Paketlenebilir |
| Almanca | enz/german-wordlist (CC0, kelime oyunu kurallarıyla) | Google Books Almanca (CC BY 3.0) | Paketlenebilir; anadili konuşanın gözden geçirmesi gerekir |
| Fransızca | Grammalecte 7.7 sözlüğü (MPL 2.0) | Sözlüğün kendi sıklık dizini | Liste yayımlanmalı |
| İspanyolca | RLA-ES (MPL 2.0 seçeneğiyle; es_ES / es_MX) | Google Books İspanyolca | Liste yayımlanmalı |
| İtalyanca | Morph-it! (CC BY-SA 2.0) | Google Books İtalyanca | Liste yayımlanmalı (CC BY-SA 4.0) |
| Portekizce (BR) | VERO (LGPL + MPL; yalnız MPL kullanımı yazara teyit ettirilmeli) | hermitdave pt_br (CC BY-SA 4.0) | Liste yayımlanmalı, teyit gerekli |

**Kaçınılacaklar:** wordfreq verisi (CC BY-SA, CSV çıkarımı lisansa uymuyor), google-10000-english
(LDC verisi), AOSP klavye listeleri (Lexiteria izni), resmî Scrabble listeleri (NWL, Collins, ODS,
FISE: yayıncıya ait), GPL'li Hunspell sözlükleri (de_DE frami, it_IT), DeReWo ve RAE listeleri
(ticari kullanım yasak). Leipzig korpusları: CC BY görünse de ticari kullanım için yazılı izin iste.

**Uygunsuz kelime süzgeci:** LDNOOBW (CC BY 4.0), words/cuss (MIT), SCOWL/ESDB'nin işaretleri. Yalnızca
derleme sırasında kullanılıp uygulamaya konmazsa lisans yükümlülüğü doğmaz; İngilizce için kendi engel
listemiz (`tool/dict/en/blocklist_en.txt`) yazılır.

**Lisanslar sayfası (İngilizce için):** "English word list derived from SCOWL, Copyright 2000-2020 by
Kevin Atkinson" + SCOWL'un izin metninin aynısı; 12dicts kamu malı olduğu için not gerekmez (2of12inf
için AGID notu eklenir). Uygulama Zemberek için olduğu gibi `LicenseRegistry`'ye ekler.

## Kararlar

1. **İlk dil İngilizce** (sahibinin onayıyla, 25 Kasım 2026). Sırada Almanca, Fransızca, İspanyolca.
2. **Kelime biçimleri** — Türkçede yalın kök (karar 12) sürer; İngilizcede çoğul ve çekimli hâller
   geçerli (karar 30).
3. **İlerleme** — 5. maddedeki gibi uygulandı: rekor, günlük sonuç ve Kelime Defteri dil başına; seri,
   XP, seviye, görev ve başarımlar ortak; harf görevleri oynanan dile katlanır.
4. **Yayın** — öneri: 1.0 Türkçe çıksın, çok dilli sürüm 1.1 olsun (karar sahibinin).

## Yeni bir dil eklemek

1. `WordLanguage`'a sınıf ekle (alfabe ≤ 63 harf toplamda `Letters`'a sona eklenir, sesliler,
   normalleştirme, kendi adı); `BalanceConfig.defaultsFor` ve `LanguageExamples.of`'a ekle.
2. Sözlük aracı (`tool/build_dictionary_<dil>.dart`), kaynaklar ve lisans notu (`tool/dict/<dil>/`),
   engel listesi; Lisanslar sayfası ve Hakkında künyesi.
3. `tool/simulate.dart --lang <dil>` ile Türkçe ölçütlere ayarla (`--vowels`, `--easing`).
4. Tanıtım ve öğretici örnekleri (`test/ui/language_examples_test.dart` doğrular), nadir harf
   başarımı harfleri, gerekirse arayüz çevirisi (`lib/l10n/app_<dil>.arb`).
5. Mağaza metni ve o dilde ekran görüntüleri.

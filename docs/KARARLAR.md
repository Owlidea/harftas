# Onaylanan Kararlar (2026-11-13)

Kaynak: ana spesifikasyon + başlangıç soruları 1–18 ("hepsi önerin gibi").

1. Oyunun adı **Harftaş** (2026-11-13). Paket/proje kimliği teknik olarak `harfblok` kalıyor (kullanıcıya görünmez); görünen ad `AppInfo.displayName`.
2. Teknoloji: Flutter (Dart), Flame yok. Oyun ekranı CustomPainter + Ticker.
3. Yazı tipi kullanıcıdan gelecek (OFL vb., 4 ağırlık). Gelene kadar sistem fontu.
4. Arayüz simgelerini kullanıcı verecek; o zamana kadar kodla çizilmiş yer tutucular.
5. Günlük bulmaca: el dizisi yalnızca `(tarih, elNo)` ile belirlenir, ızgaradan bağımsız.
   Kolaylaştırıcı yalnızca Klasik modda. Her el için ayrı RNG akışı: `hash(seed, handNo)`.
6. Günlük bulmacada sabit hamle sınırı (varsayılan 20 el = 60 blok), ayar dosyasında.
7. Sesli oranı: alt sınır `floor(0.4·n)`, üst sınır `ceil(0.6·n)`, en az 1 sesli.
8. "Nadir harf" = seyrek grup: G Ç H C P V Ö F Ğ J.
9. Ğ yalnızca solunda VE üstünde aynı bloktan hücre bulunan hücreye konur; tekli blokta Ğ yok.
10. Çakışma çözümü açgözlü: (uzunluk ↓, harf puanı ↓, konum ↑) sırala, çakışmayanları al.
11. Uzun geçersiz segment içindeki kelimeler sayılır; simülatör sonrası yeniden değerlendirilir.
12. v1 yalnızca yalın kökler; öğretici ve "Nasıl oynanır"da açıkça belirtilir. Çekimler Aşama 2 sonrası değerlendirilir.
13. Seri: ilk kelimeli hamle ×1.0, sonra her biri +0.1, üst sınır ×2.0. Yenile/Çekiç seriyi değiştirmez;
    Joker kelime kurarsa kelimeli hamle, kurmazsa nötr.
14. XP eşiği seviye başına: N → N+1 için `round(500 · N^1.5)`.
15. Günlük bulmacada ödüllü "Devam Et" yok.
16. Şekil seçimi: hücre sayısı (%15/35/35/15) → aile (eşit) → yön (eşit).
17. Sözlük: Zemberek-NLP (Apache-2.0, Aşama 1'de doğrulanacak). Yaygın liste frekans kaynağından
    otomatik çıkarılıp kullanıcı tarafından elle gözden geçirilecek; kaynak lisansı seçilirken bildirilecek.
18. Sol el düzeni: güçlendirici çubuğu ve duraklat aynalanır, sürükleme ofseti hafif sağa kayar.
19. Uygulama adı 21 Kasım 2026'da **Harftaş → Harf Kombo** oldu (kısa adların çoğu en az bir mağazada
    alınmıştı; "Harf Kombo" iki mağazada da boştu). Mağaza adı "Harf Kombo: Kelime Bulmaca". Paket
    kimliği `com.owlidea.harftas`, ürün kimlikleri ve barındırılan sayfa adresleri
    (`owlidea.github.io/harftas/…`) değişmedi; kullanıcıya görünmezler ve mağazalar bu adresleri tutuyor.

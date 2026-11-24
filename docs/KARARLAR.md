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
20. Uzunluk çarpanı 24 Kasım 2026'da sadeleşti: **her fazladan harf +1 çarpan** (3 harf ×1, 4 ×2, 5 ×3,
    6 ×4, 7 ×5, 8 ×6; eski değerler 4 ×1,5 · 5 ×2 · 6 ×3 · 7 ×4). Amaç 3 harfli kelime baskınlığına
    karşı uzun kelimeyi daha ödüllü kılmak. Simülatör (1000 oyun): oyun süresi değişmedi (62,4 hamle),
    ortalama skor yaygın-kelime botunda 382 → 401, tam-sözlük botunda 989 → 1028.
21. Seviye eğrisi 24 Kasım 2026'da değişti (karar 14'ün yerine): N → N+1 için **250 + 150·N** XP.
    Eski `round(500·N^1.5)` eğrisinde günde ~300 XP kazanan (3 oyun + günlük görevler) bir oyuncu
    5. seviyeye ~1 ayda, 10. seviyeye ~6 ayda, 20. seviyeye ~3 yılda ulaşıyordu; tema ve karo ödüllerinin
    çoğu pratikte hiç açılmıyordu. Yeni eğride aynı oyuncu: seviye 3 → 3. gün, 5 → 8. gün, 10 → 30. gün,
    15 → 2 ay, 20 → 3,5 ay. Mevcut profiller toplam XP'den yeniden hesaplanır; atlanan seviyelerin
    tema/karo/zemin ödülleri açılışta verilir (`Progression.syncLevelUnlocks`), güçlendiriciler verilmez.
22. Seviye ödülleri: 3 Yumuşak karo · 4 Keçe zemin · 5 Zeytin teması · 7 Ahşap zemin · 8 Keskin karo ·
    10 Lavanta teması · 12 Ahşap damar karo · 14 Mermer zemin · 15 Kehribar teması · 20 Mermer karo;
    diğer seviyeler güçlendirici. Tahta zeminleri gri tonlu dokudur, tema rengiyle çarpılır.
23. Haftalık hedef: Pazartesi–Pazar (İstanbul), herkese aynı, 7 hedeflik döngü; ödül 300 XP + her
    güçlendiriciden 1. Günlük görevlerden ayrı tutulur ve hafta bitince sıfırlanır.
24. Başarımlar: 10 tür, 24 kademe; ilerleme kalıcı istatistiklerden türetilir, yalnızca kazanılan
    kimlikler saklanır. Oyun sonunda verilir; ödül 100 / 200 / 400 XP (kademe I / II / III).
25. Ödüllü reklam yerleri (24 Kasım 2026). İlke: zorunlu reklam sayısı artmaz; yeni yerlerin hepsi
    oyuncunun kendi isteğiyle izlediği reklamlardır ve "Reklamsız oyna" sahiplerinde reklamsız çalışır.
    - **2× XP:** oyun sonunda XP rakamının altında küçük düğme; oyun başına bir kez, en az 10 XP varsa.
    - **Seri kurtarma:** en az 3 günlük seri bozulduysa, son oyundan en çok 4 gün geçtiyse ve bugünün
      bulmacası oynanmadıysa; haftada en fazla bir kez. Ayda bir ücretsiz koruma hakkı aynen duruyor.
    - **Günlük hediye:** günde bir güçlendirici **ücretsiz** (tür her gün değişir); reklam izlenirse
      ikincisi verilir. Ana ekranda "Hediye" çipi, alınınca kaybolur.
26. Envanter kuralı: klasik oyun sürerken güçlendirici sayılarının sahibi oyundur. Oyun dışından gelen
    her güçlendirici (görev, seviye, haftalık ödül, satın alma, hediye) oyuna `GrantAction` olarak
    kaydedilir. Önceden bu ödüller bir sonraki hamlede oyunun eski sayılarıyla eziliyor, satın alınan
    paketler de süren oyuna devam edilince kayboluyordu.
27. Dosya kayıtları belge başına sıraya alınır (`FileBackend`). Üst üste binen iki yazma aynı geçici
    dosyayı paylaşıyor ve bozuk kayıt (dolayısıyla profil sıfırlanması) üretebiliyordu.

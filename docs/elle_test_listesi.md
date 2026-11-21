# Elle test listesi (spec 17)

Her maddeyi iOS ve Android'de; küçük telefon (iPhone SE / 360 dp), büyük telefon
(6,9″) ve tablette; açık ve koyu temada deneyin.

## Ekranlar
- [ ] Ana menü: süren oyun varken birincil düğme "Devam Et" ve skor gösterir.
- [ ] İlk "Oyna": öğretici açılır; 4 adım oynanarak geçilir; "Atla" çalışır; sonra oyun başlar.
- [ ] Oyun: sürükle–bırak, parmağın ~60 pt üstünde büyümüş blok, ızgarada yarı saydam önizleme,
      kelime vurgusu ve "+N" etiketi; geçersiz bırakmada blok yay hareketiyle geri döner.
- [ ] Bloğa dokun → seçili halka; ızgaraya dokun → yerleşir (erişilebilir yol).
- [ ] Kelime patlaması: harfler sırayla patlar, puan süzülür, skor sayarak artar.
- [ ] Kombo ×2/×3: ayrı ses, daha çok parçacık, ×3'te hafif sarsıntı.
- [ ] Izgara tamamen boşalınca +100 etiketi ve ses.
- [ ] Yenile / Joker (hücre + harf seçici) / Çekiç; sayılar düşer; günlükte uyarı.
- [ ] Yer kalmayınca "Yer kalmadı" paneli; güçlendirici yoksa doğrudan oyun sonu.
- [ ] Oyun sonu: skor, yeni rekor, kelime sayısı, en iyi kelime, XP, görev ilerlemesi;
      "Devam Et" (oyun başına 1), "Tekrar Oyna", "Paylaş".
- [ ] Duraklat: devam, yeniden başlat (onaylı), ses/müzik/titreşim, ana menü.
- [ ] Günlük: kart, takvim (önceki aylara geçiş), seri, koruma hakkı, rozetler; bitince paylaşım
      kartında kelimeler yok, yalnızca en uzun kelimenin harf sayısı var.
- [ ] İlk günlük bitince bildirim izni bağlamıyla sorulur (ilk açılışta değil).
- [ ] Görevler, Kelime Defteri, İstatistikler, Ayarlar, Mağaza, Hakkında/Lisanslar.
- [ ] Boş durumlar: yeni kurulumda Defter ve İstatistikler.

## Erişilebilirlik
- [ ] VoiceOver / TalkBack: ızgara hücreleri, bloklar, güçlendiriciler, skor okunuyor.
- [ ] Sistem yazı boyutu en büyük: metin taşmıyor (ölçek 1,35'te sınırlanır).
- [ ] Hareketi azalt açık: sarsıntı ve parçacık yok, geçişler solma.
- [ ] Renk körlüğü paleti: vurgu turuncu + çerçeve + alt çizgi (yalnızca renk değil).
- [ ] Sol el düzeni: duraklat sola, güçlendiriciler sola.

## Kesintiler
- [ ] Oyun sırasında arama gelmesi / bildirim merkezi / arka plana alma → dönüşte aynı durum.
- [ ] Sürükleme sırasında uygulamayı arka plana al → blok güvenle eline döner.
- [ ] Hamleden hemen sonra uygulamayı öldür → yeniden açınca hamle kayıtlı.
- [ ] Oyun sonu ekranındayken uygulamayı öldür → yeniden açınca sonuç istatistiklere işlenmiş.
- [ ] Günlük bulmacayı yarıda bırak → "Kaldığın yerden devam et".
- [ ] Saat dilimi: cihaz saatini 23:59 → 00:01 (İstanbul) ilerlet → yeni günlük bulmaca, görevler yenilenir.
- [ ] Uçak modu: oyun tamamen çalışır; reklam yoksa "Devam Et" sessizce başarısız olur.
- [ ] Kayıt dosyasını boz (`profile.json`) → uygulama çökmeden sıfırlanır.

# Yayın rehberi (canlıya çıkış)

Kod tarafı hazır. Aşağıdaki adımlar **sizin hesaplarınız/kararlarınız** gerektirdiği için sizde.
Hiçbir komut kendiliğinden çalışmaz; sırası geldiğinde siz çalıştırırsınız.

## 1. Kimlik
- Paket kimliği: `com.owlidea.harftas` (Android `applicationId`, iOS bundle id). VARSAYIM —
  ilk mağaza yüklemesinden sonra **değiştirilemez**; değiştirmek isterseniz şimdi söyleyin.
- Sürüm: `pubspec.yaml` → `version: 1.0.0+1` (her yüklemede `+N` artmalı).

## 2. Android imza anahtarı
```
tool/create_upload_key.sh
```
`~/harftas-upload-keystore.jks` ve `android/key.properties` oluşur (ikisi de .gitignore'da).
Dosyayı ve parolayı parola yöneticinize saklayın. Play Console'da "Play App Signing" açık kalsın.
Anahtar yoksa sürüm derlemesi debug anahtarıyla imzalanır ve Play kabul etmez.

## 3. Üretim kimlikleri
`config/prod.example.json` → `config/prod.json` kopyalayın, doldurun (AdMob uygulama ve birim
kimlikleri, paylaşım/gizlilik URL'si, destek e-postası). Dosya yoksa reklamlar Google'ın **test**
kimlikleriyle çalışır — yanlışlıkla gerçek reklam gösterilmez.
- iOS AdMob uygulama kimliği: `ios/Runner/Info.plist` → `GADApplicationIdentifier` elle.

## 4. Web sitesi ve gizlilik
- `web/gizlilik.html` ve `web/destek.html` hazır. **Şirket unvanı/adres** alanını doldurun.
- Alan adı VARSAYIM: `harftas.app`, e-posta `destek@harftas.app`. Farklıysa `config/prod.json`
  ve iki HTML dosyasındaki adresleri değiştirin.
- Web sürümü canlıda reklamsız ve satın almasızdır (mağazada "mobil uygulamada" notu çıkar).
  `build/web` klasörü herhangi bir statik barındırmaya (Netlify, Cloudflare Pages, Firebase
  Hosting, GitHub Pages) yüklenebilir. Gizlilik sayfası adresi: `<alan adı>/gizlilik.html`.

## 5. Derleme (siz istediğinizde)
```
tool/release.sh android   # .aab → Play Console
tool/release.sh web       # build/web → barındırma
tool/release.sh ios       # tam Xcode gerekir
```
Betik önce `flutter analyze` + `flutter test` çalıştırır, eksik anahtar/kimlik varsa durur.
Bu makinede Android `cmdline-tools` eksik: Android Studio → SDK Manager → "Command-line Tools"
kurun ve `flutter doctor --android-licenses` çalıştırın (yoksa yerel semboller ayıklanamaz).

## 6. Mağaza
Play Console / App Store Connect: ürünler (`remove_ads`, `powerups_small`, `powerups_large`),
veri güvenliği formları, ekran görüntüleri — ayrıntı `docs/magaza_ve_yayin.md` ve
`docs/yayin_kontrol_listesi.md`.

## 7. Simge ve açılış ekranı
Geçici simge `tool/icon/render_icon_test.dart` ile çizildi. Kendi tasarımınız gelince aynı adlarla
`assets/branding/` altına koyup `dart run flutter_launcher_icons` ve
`dart run flutter_native_splash:create` çalıştırın.

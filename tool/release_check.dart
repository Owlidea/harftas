// Yayın hazırlık kontrolü. Hiçbir şey derlemez veya değiştirmez; yalnızca okur.
//
//   dart tool/release_check.dart            # yapılandırma, varlıklar, alan adı
//   dart tool/release_check.dart --tests    # + flutter analyze ve flutter test
// (`dart run` yerine doğrudan `dart`: bağımlılıkların yerel derleme adımlarını tetiklemez.)
//
// Çıkış kodu: 0 = engel yok, 1 = en az bir yayın engeli var.
// Elle yapılan maddeler (mağaza hesapları, ürünler, formlar) docs/yayin_kontrol_listesi.md'de.
import 'dart:convert';
import 'dart:io';

enum Level { blocker, recommended }

class Result {
  Result(this.group, this.title, this.ok, this.level, {this.detail = '', this.owner = 'Sen'});
  final String group;
  final String title;
  final bool ok;
  final Level level;
  final String detail;
  final String owner;
}

final results = <Result>[];

void check(
  String group,
  String title,
  bool ok, {
  Level level = Level.blocker,
  String detail = '',
  String owner = 'Sen',
}) => results.add(Result(group, title, ok, level, detail: detail, owner: owner));

String read(String path) => File(path).existsSync() ? File(path).readAsStringSync() : '';

/// Enum entries of `enum <name> { ... }` in asset_paths.dart, as file names
/// (the string argument when given, otherwise the entry name).
List<String> enumFileNames(String source, String enumName) {
  final m = RegExp('enum $enumName \\{([\\s\\S]*?);').firstMatch(source);
  if (m == null) return const [];
  return [
    for (final e in RegExp(r"(\w+)(?:\('([\w]+)'\))?\s*[,;]?").allMatches(m.group(1)!))
      if (e.group(1) != null && e.group(1)!.isNotEmpty) e.group(2) ?? e.group(1)!,
  ];
}

const testPublisher = '3940256099942544';

Future<void> main(List<String> args) async {
  final root = File.fromUri(Platform.script).parent.parent.path;
  Directory.current = root;

  // ---------------------------------------------------------------- config
  const g1 = 'Yapılandırma';
  final prodRaw = read('config/prod.json');
  Map<String, dynamic> prod = {};
  try {
    if (prodRaw.isNotEmpty) prod = jsonDecode(prodRaw) as Map<String, dynamic>;
  } on FormatException {
    // reported below
  }
  check(g1, 'config/prod.json var ve geçerli JSON', prod.isNotEmpty, owner: 'Claude');

  String v(String k) => (prod[k] ?? '').toString();
  bool real(String s) => s.isNotEmpty && !s.contains('XXXX') && !s.contains(testPublisher);

  check(
    g1,
    'RevenueCat anahtarları (appl_ / goog_)',
    v('REVENUECAT_APPLE_KEY').startsWith('appl_') && v('REVENUECAT_GOOGLE_KEY').startsWith('goog_'),
    owner: 'Claude',
  );
  const adKeys = [
    'ADMOB_APP_ID_ANDROID',
    'ADMOB_ANDROID_REWARDED',
    'ADMOB_ANDROID_INTERSTITIAL',
    'ADMOB_IOS_REWARDED',
    'ADMOB_IOS_INTERSTITIAL',
  ];
  final missingAds = [for (final k in adKeys) if (!real(v(k))) k];
  check(
    g1,
    'Gerçek AdMob kimlikleri (Android uygulama + 4 reklam birimi)',
    missingAds.isEmpty,
    detail: missingAds.isEmpty ? '' : 'eksik/test: ${missingAds.join(', ')}',
  );

  final plist = read('ios/Runner/Info.plist');
  final gad = RegExp(r'<key>GADApplicationIdentifier</key>\s*<string>([^<]*)</string>').firstMatch(plist)?.group(1) ?? '';
  check(g1, 'iOS AdMob uygulama kimliği (Info.plist) test değil', real(gad), detail: gad.isEmpty ? 'yok' : '');
  final skan = RegExp('SKAdNetworkIdentifier').allMatches(plist).length;
  check(
    g1,
    'SKAdNetworkItems Google\'ın güncel listesiyle dolu',
    skan >= 10,
    level: Level.recommended,
    detail: '$skan kimlik var',
    owner: 'Claude',
  );

  final keyProps = read('android/key.properties');
  final storeFile = RegExp(r'storeFile=(.+)').firstMatch(keyProps)?.group(1)?.trim() ?? '';
  check(
    g1,
    'Android yükleme anahtarı (android/key.properties + .jks)',
    keyProps.isNotEmpty && storeFile.isNotEmpty && File(storeFile).existsSync(),
    detail: keyProps.isEmpty ? 'tool/create_upload_key.sh ile oluştur' : (storeFile.isEmpty ? 'storeFile yok' : ''),
  );

  final pubVer = RegExp(r'^version:\s*([\d.]+)\+(\d+)', multiLine: true).firstMatch(read('pubspec.yaml'));
  final appVer = RegExp(r"version = '([\d.]+)'").firstMatch(read('lib/config/app_info.dart'))?.group(1);
  check(
    g1,
    'Sürüm numarası pubspec ile AppInfo.version aynı',
    pubVer != null && pubVer.group(1) == appVer,
    detail: 'pubspec ${pubVer?.group(1)}+${pubVer?.group(2)}, AppInfo $appVer',
    owner: 'Claude',
  );
  check(
    g1,
    'iOS gizlilik bildirimi (ios/Runner/PrivacyInfo.xcprivacy)',
    File('ios/Runner/PrivacyInfo.xcprivacy').existsSync(),
    level: Level.recommended,
    owner: 'Claude',
  );

  // ------------------------------------------------------- web & legal
  const g2 = 'Alan adı ve hukuk';
  final privacyUrl = v('PRIVACY_URL').isNotEmpty ? v('PRIVACY_URL') : 'https://owlidea.github.io/harftas/gizlilik.html';
  final host = Uri.parse(privacyUrl).host;
  var resolves = false;
  try {
    resolves = (await InternetAddress.lookup(host).timeout(const Duration(seconds: 6))).isNotEmpty;
  } on Object {
    resolves = false;
  }
  check(g2, 'Alan adı çözülüyor ($host)', resolves, detail: resolves ? '' : 'alan adı kayıtlı değil / DNS yok');

  var status = 0;
  if (resolves) {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(Uri.parse(privacyUrl));
      status = (await req.close().timeout(const Duration(seconds: 8))).statusCode;
    } on Object {
      status = 0;
    } finally {
      client.close(force: true);
    }
  }
  check(g2, 'Gizlilik politikası yayında ($privacyUrl)', status == 200, detail: status == 0 ? 'erişilemedi' : 'HTTP $status');

  final policy = read('web/gizlilik.html');
  check(
    g2,
    'Gizlilik politikasında veri sorumlusu (şirket unvanı, adres) dolu',
    policy.isNotEmpty && !policy.contains('[Şirket'),
    detail: policy.contains('[Şirket') ? 'web/gizlilik.html içinde "[Şirket / geliştirici unvanı], [adres]" duruyor' : '',
  );
  final support = v('SUPPORT_EMAIL');
  check(
    g2,
    'Destek e-postası alan adı çözülüyor',
    support.contains('@') && (support.split('@').last == host ? resolves : true),
    detail: support,
  );

  // --------------------------------------------------------- assets
  const g3 = 'Görsel ve ses';
  final assetSrc = read('lib/config/asset_paths.dart');
  final fonts = Directory('assets/fonts').existsSync()
      ? Directory('assets/fonts').listSync().whereType<File>().where((f) => RegExp(r'\.(ttf|otf)$').hasMatch(f.path)).toList()
      : <File>[];
  check(g3, 'Yazı tipi dosyaları (assets/fonts, + lisans)', fonts.isNotEmpty, detail: '${fonts.length} dosya');

  final logos = ['assets/images/brand/logo_light.svg', 'assets/images/brand/logo_dark.svg'];
  final missingLogos = [for (final p in logos) if (!File(p).existsSync()) p.split('/').last];
  check(g3, 'Logo SVG (açık + koyu)', missingLogos.isEmpty, detail: missingLogos.join(', '));

  final icons = enumFileNames(assetSrc, 'AppIconName');
  final missingIcons = [for (final n in icons) if (!File('assets/images/icons/ic_$n.svg').existsSync()) n];
  check(
    g3,
    'Arayüz ikonları (${icons.length} SVG)',
    icons.isNotEmpty && missingIcons.isEmpty,
    level: Level.recommended,
    detail: missingIcons.isEmpty ? '' : '${missingIcons.length} eksik (kodla çizilen yer tutucu kullanılıyor)',
  );

  final badges = [7, 30, 100];
  final missingBadges = [for (final d in badges) if (!File('assets/images/badges/streak_$d.svg').existsSync()) d];
  check(g3, 'Seri rozetleri (7/30/100)', missingBadges.isEmpty, detail: missingBadges.isEmpty ? '' : 'eksik: $missingBadges');

  final sounds = enumFileNames(assetSrc, 'SoundId');
  final required = sounds.where((s) => s != 'music_loop').toList();
  final missingSounds = [for (final s in required) if (!File('assets/audio/$s.ogg').existsSync()) s];
  check(
    g3,
    'Ses efektleri (${required.length} OGG)',
    required.isNotEmpty && missingSounds.isEmpty,
    detail: missingSounds.isEmpty ? '' : '${missingSounds.length} eksik — oyun sessiz',
  );
  check(
    g3,
    'Müzik (music_loop.ogg)',
    File('assets/audio/music_loop.ogg').existsSync(),
    level: Level.recommended,
  );
  for (final p in ['assets/branding/app_icon_ios_1024.png', 'assets/branding/splash_mark.png']) {
    check(g3, 'Marka dosyası ${p.split('/').last}', File(p).existsSync(), detail: 'son hali olduğunu elle doğrula');
  }

  // ---------------------------------------------------------- code
  if (args.contains('--tests')) {
    const g4 = 'Kod';
    for (final cmd in [
      ['analyze'],
      ['test'],
      ['test', 'test_screens'],
    ]) {
      final r = await Process.run('flutter', cmd, runInShell: true);
      check(g4, 'flutter ${cmd.join(' ')}', r.exitCode == 0, owner: 'Claude');
    }
  }

  // --------------------------------------------------------- report
  final blockers = results.where((r) => !r.ok && r.level == Level.blocker).length;
  final recs = results.where((r) => !r.ok && r.level == Level.recommended).length;
  String? last;
  for (final r in results) {
    if (r.group != last) {
      stdout.writeln('\n${r.group}');
      last = r.group;
    }
    final mark = r.ok ? '✓' : (r.level == Level.blocker ? '✗' : '!');
    final who = r.ok ? '' : '  [${r.owner}]';
    final det = r.detail.isEmpty ? '' : '  — ${r.detail}';
    stdout.writeln('  $mark ${r.title}$det$who');
  }
  stdout.writeln(
    '\n${results.where((r) => r.ok).length}/${results.length} tamam · $blockers yayın engeli · $recs öneri'
    '${args.contains('--tests') ? '' : '  (kod kontrolleri için: --tests)'}',
  );
  stdout.writeln('Elle yapılacaklar: docs/yayin_kontrol_listesi.md');
  exit(blockers > 0 ? 1 : 0);
}

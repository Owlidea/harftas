// Renders the placeholder app icon / splash mark PNGs into assets/branding/.
//
//   flutter test tool/icon/render_icon_test.dart
//   dart run flutter_launcher_icons && dart run flutter_native_splash:create
//
// When the designer's icon is delivered, drop it over these files (same
// names, ASSETS.md #4–6) and run only the second line.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

const _out = 'assets/branding';
const _teal = Color(0xFF0E6F6B);
const _tealDeep = Color(0xFF0A4F4C);
const _ivory = Color(0xFFFCF8EE);
const _ivoryEdge = Color(0xFFD9CDB2);
const _navy = Color(0xFF17213A);

Future<void> _font() async {
  final f = File('/System/Library/Fonts/Supplemental/Arial Bold.ttf');
  final loader = FontLoader('IconFont')..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
  await loader.load();
}

void _background(Canvas c, double s) {
  final r = Offset.zero & Size(s, s);
  c.drawRect(
    r,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF13827D), _teal, _tealDeep],
      ).createShader(r),
  );
  // Faint 8x8 board grid.
  final grid = Paint()
    ..color = const Color(0x14FFFFFF)
    ..strokeWidth = s * 0.004;
  for (var i = 1; i < 8; i++) {
    final v = s * i / 8;
    c.drawLine(Offset(v, 0), Offset(v, s), grid);
    c.drawLine(Offset(0, v), Offset(s, v), grid);
  }
}

/// Ivory letter tile "H" with its score, centred, [frac] of the canvas.
void _tile(Canvas c, double s, double frac, {bool mono = false}) {
  final w = s * frac;
  final rect = Rect.fromCenter(center: Offset(s / 2, s / 2), width: w, height: w);
  final rr = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.18));
  if (mono) {
    // Monochrome (Android 13 themed icon): white tile, letter knocked out.
    c.saveLayer(Offset.zero & Size(s, s), Paint());
    c.drawRRect(rr, Paint()..color = Colors.white);
    _letters(c, rect, w, const Color(0xFF000000), BlendMode.clear);
    c.restore();
    return;
  }
  c.drawRRect(
    rr.shift(Offset(0, w * 0.045)),
    Paint()
      ..color = const Color(0x55000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.04),
  );
  c.drawRRect(rr.shift(Offset(0, w * 0.035)), Paint()..color = _ivoryEdge);
  c.drawRRect(rr, Paint()..color = _ivory);
  _letters(c, rect, w, _navy, BlendMode.srcOver);
}

void _letters(Canvas c, Rect rect, double w, Color color, BlendMode mode) {
  void text(String t, double size, Offset Function(Size) at) {
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
          fontFamily: 'IconFont',
          fontSize: size,
          fontWeight: FontWeight.w700,
          height: 1,
          foreground: Paint()
            ..color = color
            ..blendMode = mode,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, at(tp.size));
  }

  text('H', w * 0.62, (z) => Offset(rect.center.dx - z.width / 2, rect.center.dy - z.height / 2));
  text('5', w * 0.2, (z) => Offset(rect.right - z.width - w * 0.1, rect.bottom - z.height - w * 0.08));
}

Future<void> _png(String name, double s, void Function(Canvas) paint) async {
  final rec = ui.PictureRecorder();
  paint(Canvas(rec));
  final img = await rec.endRecording().toImage(s.toInt(), s.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File('$_out/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('render app icon', (tester) async {
    await tester.runAsync(() async {
      await _font();
      const s = 1024.0;
      // iOS / store / web: full bleed, no transparency.
      await _png('app_icon_ios_1024.png', s, (c) {
        _background(c, s);
        _tile(c, s, 0.6);
      });
      // Android adaptive layers: content inside the 66% safe zone.
      await _png('android_bg.png', s, (c) => _background(c, s));
      await _png('android_fg.png', s, (c) => _tile(c, s, 0.42));
      await _png('android_mono.png', s, (c) => _tile(c, s, 0.42, mono: true));
      // Splash mark (Android 12 masks it to a circle of 2/3 the size).
      await _png('splash_mark.png', s, (c) => _tile(c, s, 0.44));
    });
  });
}

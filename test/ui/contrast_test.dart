import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:harfblok/ui/theme/tokens.dart';

double _lum(Color c) {
  double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Spec 11: text contrast >= 4.5:1 for every theme / mode / CVD palette.
void main() {
  for (final t in ThemeDef.all) {
    for (final dark in [false, true]) {
      for (final cb in [false, true]) {
        test('${t.id} dark=$dark colorBlind=$cb', () {
          final p = t.resolve(dark: dark, colorBlind: cb);
          final pairs = <String, (Color, Color)>{
            'ink/background': (p.ink, p.background),
            'ink/surface': (p.ink, p.surface),
            'muted/background': (p.inkMuted, p.background),
            'muted/surface': (p.inkMuted, p.surface),
            'onAccent/accent': (p.onAccent, p.accent),
            'tileInk/tile': (p.tileInk, p.tile),
            'tileScore/tile': (p.tileScore, p.tile),
            'tileInk/joker': (p.tileInk, p.joker),
          };
          for (final e in pairs.entries) {
            expect(contrast(e.value.$1, e.value.$2), greaterThanOrEqualTo(4.5), reason: e.key);
          }
        });
      }
    }
  }
}

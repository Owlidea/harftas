import 'dart:ui';

/// Design tokens (spec 11). Screens never hard-code colours, sizes or
/// durations: everything comes from here via `context.palette` etc.

/// 4 pt spacing scale.
abstract final class Space {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;

  /// Minimum touch target (spec 16).
  static const double touch = 44;
  static const double screenGutter = s4;
  static const double maxContentWidth = 560;
}

abstract final class Radii {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}

/// Animation durations (spec 10).
abstract final class Motion {
  static const pick = Duration(milliseconds: 120);
  static const settle = Duration(milliseconds: 180);
  static const wordHighlight = Duration(milliseconds: 200);
  static const popPerLetter = Duration(milliseconds: 50);
  static const pop = Duration(milliseconds: 250);
  static const scoreFloat = Duration(milliseconds: 600);
  static const counter = Duration(milliseconds: 400);
  static const handIn = Duration(milliseconds: 250);
  static const handStagger = Duration(milliseconds: 60);
  static const screen = Duration(milliseconds: 300);
  static const returnToHand = Duration(milliseconds: 260);

  /// Finger offset while dragging (spec 10: ~60 pt above the finger).
  static const double dragLift = 60;
  static const double dragScale = 1.06;
}

/// Colour palette of one theme in one brightness.
class Palette {
  const Palette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.inkMuted,
    required this.onAccent,
    required this.accent,
    required this.accentSoft,
    required this.board,
    required this.cellEmpty,
    required this.tile,
    required this.tileEdge,
    required this.tileInk,
    required this.tileScore,
    required this.joker,
    required this.preview,
    required this.highlight,
    required this.invalid,
    required this.success,
    required this.warning,
    required this.shadow,
    required this.divider,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color ink;
  final Color inkMuted;
  final Color onAccent;
  final Color accent;
  final Color accentSoft;
  final Color board;
  final Color cellEmpty;
  final Color tile;
  final Color tileEdge;
  final Color tileInk;
  final Color tileScore;
  final Color joker;
  final Color preview;

  /// Word highlight. Always paired with an outline + underline (never colour only).
  final Color highlight;
  final Color invalid;
  final Color success;
  final Color warning;
  final Color shadow;
  final Color divider;

  Palette copyWith({
    Color? background,
    Color? board,
    Color? accent,
    Color? accentSoft,
    Color? highlight,
    Color? preview,
    Color? tile,
    Color? tileEdge,
    Color? tileInk,
    Color? tileScore,
  }) => Palette(
    background: background ?? this.background,
    surface: surface,
    surfaceAlt: surfaceAlt,
    ink: ink,
    inkMuted: inkMuted,
    onAccent: onAccent,
    accent: accent ?? this.accent,
    accentSoft: accentSoft ?? this.accentSoft,
    board: board ?? this.board,
    cellEmpty: cellEmpty,
    tile: tile ?? this.tile,
    tileEdge: tileEdge ?? this.tileEdge,
    tileInk: tileInk ?? this.tileInk,
    tileScore: tileScore ?? this.tileScore,
    joker: joker,
    preview: preview ?? this.preview,
    highlight: highlight ?? this.highlight,
    invalid: invalid,
    success: success,
    warning: warning,
    shadow: shadow,
    divider: divider,
  );
}

extension PaletteTiles on Palette {
  /// Same palette with accent-coloured tiles (logo "TAŞ" row, previews).
  Palette get accentTiles => copyWith(
    tile: accent,
    tileEdge: Color.lerp(accent, const Color(0xFF000000), 0.35),
    tileInk: onAccent,
    tileScore: onAccent.withValues(alpha: 0.75),
  );
}

/// Base palettes. Light: off-white ground, deep navy ink, ivory tiles, one
/// accent (teal). Dark: deep navy ground, soft light tiles. Text pairs meet
/// >= 4.5:1 (test/ui/contrast_test.dart).
abstract final class Palettes {
  static const light = Palette(
    background: Color(0xFFF6F3EC),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEFEADF),
    ink: Color(0xFF17213A),
    inkMuted: Color(0xFF555E73),
    onAccent: Color(0xFFFFFFFF),
    accent: Color(0xFF0E6F6B),
    accentSoft: Color(0xFFD5ECEA),
    board: Color(0xFFE9E3D6),
    cellEmpty: Color(0xFFDDD5C5),
    tile: Color(0xFFFCF8EE),
    tileEdge: Color(0xFFD9CDB2),
    tileInk: Color(0xFF17213A),
    tileScore: Color(0xFF5C6377),
    joker: Color(0xFFF1E4FA),
    preview: Color(0x8C0E6F6B),
    highlight: Color(0xFF0E6F6B),
    invalid: Color(0xFFB3261E),
    success: Color(0xFF1E7A3A),
    warning: Color(0xFF8A5A00),
    shadow: Color(0x2617213A),
    divider: Color(0xFFDDD6C8),
  );

  static const dark = Palette(
    background: Color(0xFF0F1729),
    surface: Color(0xFF18223A),
    surfaceAlt: Color(0xFF212C47),
    ink: Color(0xFFEDF0F7),
    inkMuted: Color(0xFFA9B1C6),
    onAccent: Color(0xFF0F1729),
    accent: Color(0xFF4CC3BA),
    accentSoft: Color(0xFF1C3B45),
    board: Color(0xFF16203A),
    cellEmpty: Color(0xFF222D4A),
    tile: Color(0xFFEAE5D8),
    tileEdge: Color(0xFFB9B19D),
    tileInk: Color(0xFF17213A),
    tileScore: Color(0xFF4E566B),
    joker: Color(0xFFE2D3F0),
    preview: Color(0x994CC3BA),
    highlight: Color(0xFF4CC3BA),
    invalid: Color(0xFFFF8A80),
    success: Color(0xFF7FD69A),
    warning: Color(0xFFF2C14E),
    shadow: Color(0x66000000),
    divider: Color(0xFF2A3654),
  );
}

/// Unlockable themes (spec 8). Each tints the base palettes.
class ThemeDef {
  const ThemeDef(
    this.id, {
    this.lightAccent,
    this.darkAccent,
    this.lightBg,
    this.lightBoard,
    this.darkBg,
    this.darkBoard,
  });

  final String id;
  final Color? lightAccent;
  final Color? darkAccent;
  final Color? lightBg;
  final Color? lightBoard;
  final Color? darkBg;
  final Color? darkBoard;

  static const all = <ThemeDef>[
    ThemeDef('classic'),
    ThemeDef(
      'olive',
      lightAccent: Color(0xFF4A6419),
      darkAccent: Color(0xFFA9C46A),
      lightBg: Color(0xFFF3F2E8),
      lightBoard: Color(0xFFE3E2D0),
    ),
    ThemeDef(
      'lavender',
      lightAccent: Color(0xFF5B4B9A),
      darkAccent: Color(0xFFB7A8F0),
      lightBg: Color(0xFFF4F2F8),
      lightBoard: Color(0xFFE4E0EE),
    ),
    ThemeDef(
      'amber',
      lightAccent: Color(0xFF8A4B00),
      darkAccent: Color(0xFFF2B35B),
      lightBg: Color(0xFFF8F2E8),
      lightBoard: Color(0xFFEDE0CB),
    ),
    ThemeDef(
      'dawn',
      lightAccent: Color(0xFF9E3448),
      darkAccent: Color(0xFFF08DA0),
      lightBg: Color(0xFFF9F1EE),
      lightBoard: Color(0xFFEFDFDA),
    ),
    ThemeDef(
      'sea',
      lightAccent: Color(0xFF0B5A8C),
      darkAccent: Color(0xFF6CC0F0),
      lightBg: Color(0xFFEEF3F6),
      lightBoard: Color(0xFFDCE6EC),
    ),
    ThemeDef(
      'midnight',
      lightAccent: Color(0xFF26346B),
      darkAccent: Color(0xFF9BB0FF),
      darkBg: Color(0xFF080D1A),
      darkBoard: Color(0xFF0E1527),
    ),
  ];

  static ThemeDef byId(String id) => all.firstWhere((t) => t.id == id, orElse: () => all.first);

  Palette resolve({required bool dark, required bool colorBlind}) {
    var p = dark ? Palettes.dark : Palettes.light;
    final a = dark ? darkAccent : lightAccent;
    if (a != null) {
      p = p.copyWith(
        accent: a,
        accentSoft: Color.lerp(p.surface, a, 0.18),
        highlight: a,
        preview: a.withValues(alpha: 0.55),
      );
    }
    final bg = dark ? darkBg : lightBg;
    final bd = dark ? darkBoard : lightBoard;
    if (bg != null && bd != null) p = p.copyWith(background: bg, board: bd);
    if (colorBlind) {
      // Okabe–Ito blue / orange: distinguishable for common colour-vision types.
      p = dark
          ? p.copyWith(
              accent: const Color(0xFF56B4E9),
              accentSoft: const Color(0xFF173A4F),
              highlight: const Color(0xFFE69F00),
              preview: const Color(0x9956B4E9),
            )
          : p.copyWith(
              accent: const Color(0xFF005A96),
              accentSoft: const Color(0xFFD8E8F4),
              highlight: const Color(0xFFB86E00),
              preview: const Color(0x8C005A96),
            );
    }
    return p;
  }
}

/// Tile looks (unlockable via levels).
class TileStyle {
  const TileStyle(this.id, {required this.radiusFactor, required this.bevel, required this.border});
  final String id;

  /// Corner radius as a fraction of the tile size.
  final double radiusFactor;
  final bool bevel;
  final bool border;

  static const all = <TileStyle>[
    TileStyle('classic', radiusFactor: 0.18, bevel: true, border: false),
    TileStyle('soft', radiusFactor: 0.32, bevel: false, border: false),
    TileStyle('sharp', radiusFactor: 0.06, bevel: false, border: true),
    // Premium looks: surface detail lives in the rendered art (TileArt); the
    // code-drawn fallback is a plain bevelled tile.
    TileStyle('grain', radiusFactor: 0.18, bevel: true, border: false),
    TileStyle('marble', radiusFactor: 0.12, bevel: true, border: false),
  ];

  static TileStyle byId(String id) => all.firstWhere((t) => t.id == id, orElse: () => all.first);
}

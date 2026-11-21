import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../config/asset_paths.dart';
import 'tokens.dart';

/// Single font family for the whole app (spec 11). Every font file dropped
/// into assets/fonts/ is registered under this name at startup; until then
/// the platform font is used.
const String appFontFamily = 'AppFont';

Future<void> loadAppFonts() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final files = manifest
      .listAssets()
      .where((a) => a.startsWith(AssetPaths.fontsDir) && (a.endsWith('.ttf') || a.endsWith('.otf')))
      .toList();
  if (files.isEmpty) return;
  final loader = FontLoader(appFontFamily);
  for (final f in files) {
    loader.addFont(rootBundle.load(f));
  }
  await loader.load();
}

/// Type scale (sizes in logical px, scaled by the system text size).
abstract final class TypeScale {
  static const display = TextStyle(fontSize: 40, height: 1.1, fontWeight: FontWeight.w700, letterSpacing: -0.5);
  static const title = TextStyle(fontSize: 26, height: 1.2, fontWeight: FontWeight.w700, letterSpacing: -0.2);
  static const headline = TextStyle(fontSize: 20, height: 1.25, fontWeight: FontWeight.w600);
  static const body = TextStyle(fontSize: 16, height: 1.4, fontWeight: FontWeight.w400);
  static const label = TextStyle(fontSize: 15, height: 1.2, fontWeight: FontWeight.w600, letterSpacing: 0.2);
  static const caption = TextStyle(fontSize: 13, height: 1.3, fontWeight: FontWeight.w500);
  static const score = TextStyle(
    fontSize: 34,
    height: 1,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// Theme extension carrying our tokens.
class AppTheme extends ThemeExtension<AppTheme> {
  const AppTheme({required this.palette, required this.tileStyle, required this.reduceMotion});

  final Palette palette;
  final TileStyle tileStyle;
  final bool reduceMotion;

  @override
  AppTheme copyWith({Palette? palette, TileStyle? tileStyle, bool? reduceMotion}) => AppTheme(
    palette: palette ?? this.palette,
    tileStyle: tileStyle ?? this.tileStyle,
    reduceMotion: reduceMotion ?? this.reduceMotion,
  );

  @override
  AppTheme lerp(covariant AppTheme? other, double t) => t < 0.5 || other == null ? this : other;

  static ThemeData build({
    required Palette palette,
    required Brightness brightness,
    required TileStyle tileStyle,
    required bool reduceMotion,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: palette.accent,
      onPrimary: palette.onAccent,
      secondary: palette.accent,
      onSecondary: palette.onAccent,
      error: palette.invalid,
      onError: palette.surface,
      surface: palette.surface,
      onSurface: palette.ink,
    );
    TextStyle c(TextStyle s, [Color? color]) => s.copyWith(color: color ?? palette.ink, fontFamily: appFontFamily);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
      fontFamily: appFontFamily,
      splashFactory: InkSparkle.splashFactory,
      textTheme: TextTheme(
        displayLarge: c(TypeScale.display),
        titleLarge: c(TypeScale.title),
        headlineSmall: c(TypeScale.headline),
        bodyLarge: c(TypeScale.body),
        bodyMedium: c(TypeScale.body),
        labelLarge: c(TypeScale.label),
        bodySmall: c(TypeScale.caption, palette.inkMuted),
      ),
      dividerColor: palette.divider,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final p in TargetPlatform.values)
            p: reduceMotion
                ? const _FadePageTransitionsBuilder()
                // iOS players expect the edge swipe-back gesture.
                : p == TargetPlatform.iOS
                ? const CupertinoPageTransitionsBuilder()
                : const FadeForwardsPageTransitionsBuilder(),
        },
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? palette.onAccent : palette.inkMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? palette.accent : palette.surfaceAlt,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.ink,
        contentTextStyle: c(TypeScale.body, palette.background),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl))),
        showDragHandle: true,
        dragHandleColor: palette.divider,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.xl)),
      ),
      extensions: [AppTheme(palette: palette, tileStyle: tileStyle, reduceMotion: reduceMotion)],
    );
  }
}

extension ThemeX on BuildContext {
  AppTheme get appTheme => Theme.of(this).extension<AppTheme>()!;
  Palette get palette => appTheme.palette;
  TextTheme get text => Theme.of(this).textTheme;

  /// Honour the system "reduce motion" setting (spec 10).
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? appTheme.reduceMotion;
}

/// Plain cross-fade used when the system asks to reduce motion.
class _FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(opacity: animation, child: child);
}

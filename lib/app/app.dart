import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../config/app_info.dart';
import '../l10n/app_localizations.dart';
import '../progress/profile.dart';
import '../ui/screens/home_screen.dart';
import '../ui/theme/app_theme.dart';
import '../ui/theme/tokens.dart';
import 'app_model.dart';

class HarfBlokApp extends StatelessWidget {
  const HarfBlokApp({super.key, required this.model, this.locale});
  final AppModel model;

  /// Fixed UI language (tests, screenshots); null follows the device.
  final Locale? locale;

  /// The device's first preferred language that has a translation; else
  /// English when it exists, else Turkish (karar 29).
  static Locale resolveLocale(List<Locale>? preferred, Iterable<Locale> supported) {
    final codes = {for (final l in supported) l.languageCode};
    for (final p in preferred ?? const <Locale>[]) {
      if (codes.contains(p.languageCode)) return Locale(p.languageCode);
    }
    return Locale(codes.contains('en') ? 'en' : 'tr');
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      model: model,
      child: ListenableBuilder(
        listenable: model,
        builder: (context, _) {
          final s = model.settings;
          final theme = ThemeDef.byId(model.profile.unlockedThemes.contains(s.themeId) ? s.themeId : 'classic');
          final tile = TileStyle.byId(
            model.profile.unlockedTileStyles.contains(s.tileStyleId) ? s.tileStyleId : 'classic',
          );
          final reduce = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
          ThemeData build(Brightness b) => AppTheme.build(
            palette: theme.resolve(dark: b == Brightness.dark, colorBlind: s.colorBlind),
            brightness: b,
            tileStyle: tile,
            reduceMotion: reduce,
          );
          return MaterialApp(
            title: AppInfo.displayName,
            debugShowCheckedModeBanner: false,
            scrollBehavior: const _GameScrollBehavior(),
            locale: locale,
            localeListResolutionCallback: resolveLocale,
            supportedLocales: L10n.supportedLocales,
            localizationsDelegates: const [L10n.delegate, ...GlobalMaterialLocalizations.delegates],
            theme: build(Brightness.light),
            darkTheme: build(Brightness.dark),
            themeMode: switch (s.themeMode) {
              AppThemeMode.system => ThemeMode.system,
              AppThemeMode.light => ThemeMode.light,
              AppThemeMode.dark => ThemeMode.dark,
            },
            // Respect system text size, within a range the layout supports.
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              final theme = Theme.of(context);
              final dark = theme.brightness == Brightness.dark;
              final bg = theme.scaffoldBackgroundColor;
              // Edge-to-edge: status / navigation bars take the screen colour
              // and their icons follow the theme.
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
                  statusBarBrightness: dark ? Brightness.dark : Brightness.light,
                  systemNavigationBarColor: bg,
                  systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
                  systemNavigationBarDividerColor: bg,
                ),
                child: MediaQuery(
                  data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.35)),
                  child: child!,
                ),
              );
            },
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}

/// Phone-like scrolling everywhere: bouncy overscroll, no scrollbars, and
/// mouse drags scroll too (so the web build behaves like a touch screen).
class _GameScrollBehavior extends MaterialScrollBehavior {
  const _GameScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => PointerDeviceKind.values.toSet();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child;

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}

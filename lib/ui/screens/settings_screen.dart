import 'dart:math' as math;
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../components/sprite_anim.dart';
import '../../app/app_model.dart';
import '../../config/app_info.dart';
import '../../config/asset_paths.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/levels.dart';
import '../../progress/profile.dart';
import '../../progress/progression.dart';
import '../components/app_icon.dart';
import '../../core/config/balance_config.dart';
import '../../core/text/word_language.dart';
import '../components/overlays.dart';
import '../components/segmented.dart';
import '../components/widgets.dart';
import '../game/board_art.dart';
import '../game/tile_renderer.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'info_screens.dart';
import 'intro_screen.dart';
import 'tutorial_screen.dart';

String themeName(L10n l, String id) => switch (id) {
  'olive' => l.themeOlive,
  'lavender' => l.themeLavender,
  'amber' => l.themeAmber,
  'dawn' => l.themeDawn,
  'sea' => l.themeSea,
  'midnight' => l.themeMidnight,
  _ => l.themeClassic,
};

String tileStyleName(L10n l, String id) => switch (id) {
  'soft' => l.tileSoft,
  'sharp' => l.tileSharp,
  'grain' => l.tileGrain,
  'marble' => l.tileMarble,
  _ => l.tileClassic,
};

String boardStyleName(L10n l, String id) => switch (id) {
  'felt' => l.boardFelt,
  'grain' => l.boardGrain,
  'marble' => l.boardMarble,
  _ => l.boardPlain,
};

/// Where a theme / tile style / board style unlocks (for the locked label).
String? unlockHint(L10n l, {String? themeId, String? tileStyleId, String? boardStyleId}) {
  for (var n = 2; n <= 30; n++) {
    final r = Levels.rewardFor(n);
    if ((themeId != null && r.themeId == themeId) ||
        (tileStyleId != null && r.tileStyleId == tileStyleId) ||
        (boardStyleId != null && r.boardStyleId == boardStyleId)) {
      return l.levelN(n);
    }
  }
  for (final e in Progression.streakThemes.entries) {
    if (e.value == themeId) return l.unlockStreakDays(e.key);
  }
  return null;
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = AppScope.of(context);
    final s = app.settings;

    void set(AppSettings n, String key) => unawaited(app.updateSettings(n, key: key));

    Widget sw(String title, AppIconName icon, bool v, AppSettings Function(bool) f, String key, {String? sub}) =>
        ListRow(
          icon: icon,
          title: title,
          subtitle: sub,
          trailing: Switch(value: v, onChanged: (nv) => set(f(nv), key)),
          onTap: () => set(f(!v), key),
        );

    return AppScaffold(
      title: l.settingsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(l.sectionSound),
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: Space.s1),
            child: Column(
              children: [
                sw(l.sound, AppIconName.sound, s.sound, (v) => s.copyWith(sound: v), 'sound'),
                sw(l.music, AppIconName.music, s.music, (v) => s.copyWith(music: v), 'music'),
                sw(l.haptics, AppIconName.haptic, s.haptics, (v) => s.copyWith(haptics: v), 'haptics'),
              ],
            ),
          ),
          SectionHeader(l.sectionLook),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.appearance, style: context.text.labelLarge),
                const SizedBox(height: Space.s3),
                Segmented<AppThemeMode>(
                  values: AppThemeMode.values,
                  current: s.themeMode,
                  label: (m) => switch (m) {
                    AppThemeMode.system => l.themeModeSystem,
                    AppThemeMode.light => l.themeModeLight,
                    AppThemeMode.dark => l.themeModeDark,
                  },
                  onChanged: (m) => set(s.copyWith(themeMode: m), 'themeMode'),
                ),
                const SizedBox(height: Space.s5),
                Text(l.theme, style: context.text.labelLarge),
                const SizedBox(height: Space.s3),
                _OptionSlider(
                  selected: ThemeDef.all.indexWhere((t) => t.id == s.themeId),
                  children: [
                    for (final t in ThemeDef.all)
                      Builder(
                        builder: (context) {
                          final unlocked = app.profile.unlockedThemes.contains(t.id);
                          return _OptionCard(
                            name: themeName(l, t.id),
                            selected: s.themeId == t.id,
                            lockedHint: unlocked ? null : unlockHint(l, themeId: t.id),
                            onTap: unlocked ? () => set(s.copyWith(themeId: t.id), 'themeId') : null,
                            child: AssetIndex.has(AssetPaths.themePreview(t.id))
                                ? Image.asset(AssetPaths.themePreview(t.id), fit: BoxFit.cover)
                                : _ThemeSwatch(
                                    palette: t.resolve(
                                      dark: Theme.of(context).brightness == Brightness.dark,
                                      colorBlind: s.colorBlind,
                                    ),
                                  ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: Space.s5),
                Text(l.tileStyle, style: context.text.labelLarge),
                const SizedBox(height: Space.s3),
                _OptionGrid(
                  children: [
                    for (final t in TileStyle.all)
                      Builder(
                        builder: (context) {
                          final unlocked = app.profile.unlockedTileStyles.contains(t.id);
                          return _OptionCard(
                            name: tileStyleName(l, t.id),
                            selected: s.tileStyleId == t.id,
                            lockedHint: unlocked ? null : unlockHint(l, tileStyleId: t.id),
                            onTap: unlocked ? () => set(s.copyWith(tileStyleId: t.id), 'tileStyleId') : null,
                            child: _TileSwatch(style: t),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: Space.s5),
                Text(l.boardStyle, style: context.text.labelLarge),
                const SizedBox(height: Space.s3),
                _OptionGrid(
                  children: [
                    for (final id in BoardArt.styles)
                      Builder(
                        builder: (context) {
                          final unlocked = app.profile.unlockedBoardStyles.contains(id);
                          return _OptionCard(
                            name: boardStyleName(l, id),
                            selected: s.boardStyleId == id,
                            lockedHint: unlocked ? null : unlockHint(l, boardStyleId: id),
                            onTap: unlocked ? () => set(s.copyWith(boardStyleId: id), 'boardStyleId') : null,
                            child: _BoardSwatch(style: id),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.s3),
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: Space.s1),
            child: Column(
              children: [
                sw(
                  l.colorBlind,
                  AppIconName.info,
                  s.colorBlind,
                  (v) => s.copyWith(colorBlind: v),
                  'colorBlind',
                  sub: l.colorBlindDesc,
                ),
                sw(
                  l.leftHanded,
                  AppIconName.haptic,
                  s.leftHanded,
                  (v) => s.copyWith(leftHanded: v),
                  'leftHanded',
                  sub: l.leftHandedDesc,
                ),
              ],
            ),
          ),
          SectionHeader(l.sectionPlay),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.wordLanguage, style: context.text.labelLarge),
                const SizedBox(height: Space.s3),
                Segmented<WordLanguage>(
                  values: WordLanguage.values,
                  current: app.wordLanguage,
                  label: (w) => w.nativeName,
                  onChanged: (w) => unawaited(app.setWordLanguage(w)),
                ),
                const SizedBox(height: Space.s3),
                Text(l.wordLanguageDesc, style: context.text.bodySmall!.copyWith(color: context.palette.inkMuted)),
              ],
            ),
          ),
          const SizedBox(height: Space.s3),
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: Space.s1),
            child: Column(
              children: [
                ListRow(
                  icon: AppIconName.calendar,
                  title: l.notifications,
                  subtitle: l.notificationsDesc,
                  trailing: Switch(
                    value: s.notifications,
                    onChanged: (v) async {
                      final texts = ReminderTexts(
                        dailyTitle: l.notifDailyTitle,
                        dailyBody: l.notifDailyBody,
                        streakTitle: l.notifStreakTitle,
                        streakBody: l.notifStreakBody,
                      );
                      if (v) {
                        await app.enableNotifications(texts);
                      } else {
                        await app.updateSettings(s.copyWith(notifications: false), key: 'notifications');
                        await app.rescheduleReminder(texts);
                      }
                    },
                  ),
                ),
                ListRow(
                  icon: AppIconName.info,
                  title: l.howToPlay,
                  onTap: () => Navigator.of(context).push(IntroScreen.route()),
                ),
                ListRow(
                  icon: AppIconName.missions,
                  title: l.replayTutorial,
                  onTap: () => Navigator.of(context).push(TutorialScreen.route()),
                ),
              ],
            ),
          ),
          if (AppInfo.testTools) ...[
            // Developer-only (TEST_TOOLS build flag); intentionally not localised.
            const SectionHeader('Test araçları'),
            Panel(
              padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: Space.s1),
              child: Column(
                children: [
                  ListRow(
                    icon: AppIconName.palette,
                    title: 'Tüm tema ve karo stillerini aç',
                    onTap: () {
                      app.profile.unlockedThemes.addAll(ThemeDef.all.map((t) => t.id));
                      app.profile.unlockedTileStyles.addAll(TileStyle.all.map((t) => t.id));
                      app.profile.unlockedBoardStyles.addAll(BoardArt.styles);
                      unawaited(app.saveProfile());
                    },
                  ),
                  ListRow(
                    icon: AppIconName.missions,
                    title: '+500 XP ekle (seviye ödüllerini dene)',
                    onTap: () {
                      app.grantBonusXp(500);
                    },
                  ),
                  for (final (title, asset) in const [
                    ('Yeni rekor animasyonu', AssetPaths.fxNewRecord),
                    ('Izgara boşaldı animasyonu', AssetPaths.fxBoardClear),
                    ('Seviye atlama animasyonu', AssetPaths.fxLevelUp),
                    ('Ödül kutusu animasyonu', AssetPaths.fxGiftOpen),
                    ('Parıltı patlaması', AssetPaths.fxSparkle),
                    ('Yenile animasyonu', AssetPaths.fxRefresh),
                  ])
                    ListRow(
                      icon: AppIconName.star,
                      title: title,
                      onTap: () => showGeneralDialog<void>(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: title,
                        barrierColor: const Color(0x99000000),
                        pageBuilder: (dialogContext, _, _) => Center(
                          child: SpriteAnim(asset, size: 340, onDone: () => Navigator.of(dialogContext).maybePop()),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          SectionHeader(l.sectionAbout),
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: Space.s2, vertical: Space.s1),
            child: Column(
              children: [
                if (app.services.purchases.supported)
                  ListRow(
                    icon: AppIconName.store,
                    title: l.restorePurchases,
                    onTap: () async {
                      await app.services.purchases.restore();
                      if (context.mounted) {
                        showGameToast(context, l.restoreDone);
                      }
                    },
                  ),
                ListRow(
                  icon: AppIconName.lock,
                  title: l.privacy,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyScreen())),
                ),
                ListRow(
                  icon: AppIconName.book,
                  title: l.about,
                  subtitle: l.aboutVersion(AppInfo.version),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill segmented control with a sliding thumb.
/// Horizontal snap-free slider of option cards. Cards are clipped by the
/// panel (a half-visible card on the right says "swipe"), and the selected
/// one is scrolled into view on open.
class _OptionSlider extends StatefulWidget {
  const _OptionSlider({required this.children, required this.selected});
  final List<Widget> children;
  final int selected;

  @override
  State<_OptionSlider> createState() => _OptionSliderState();
}

class _OptionSliderState extends State<_OptionSlider> {
  final _controller = ScrollController();
  bool _positioned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      const gap = Space.s3;
      // ~2.6 cards visible: whole ones plus a peek of the next.
      final w = (c.maxWidth - gap * 2) / 2.6;
      final scale = MediaQuery.textScalerOf(context).scale(1);
      final h = (w - 10) / 1.1 + 10 + 50 * scale;
      if (!_positioned) {
        _positioned = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_controller.hasClients || widget.selected <= 0) return;
          final target = widget.selected * (w + gap) - (c.maxWidth - w) / 2;
          _controller.jumpTo(target.clamp(0, _controller.position.maxScrollExtent));
        });
      }
      return SizedBox(
        height: h,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.lg + 2),
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            itemCount: widget.children.length,
            separatorBuilder: (_, _) => const SizedBox(width: gap),
            itemBuilder: (_, i) => SizedBox(width: w, child: widget.children[i]),
          ),
        ),
      );
    },
  );
}

/// Three equal columns that wrap; never scrolls sideways or bleeds out of the panel.
class _OptionGrid extends StatelessWidget {
  const _OptionGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      const gap = Space.s3;
      final w = (c.maxWidth - gap * 2) / 3;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final child in children) SizedBox(width: w, child: child)],
      );
    },
  );
}

/// Selectable option: preview on top, name + status underneath.
/// Locked options stay readable (dimmed preview, lock + hint below), never covered.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.name,
    required this.selected,
    required this.lockedHint,
    required this.onTap,
    required this.child,
  });
  final String name;
  final bool selected;
  final String? lockedHint;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final p = context.palette;
    final locked = lockedHint != null;
    final statusStyle = context.text.labelSmall!.copyWith(fontSize: 11, height: 1.2);
    return Semantics(
      button: true,
      selected: selected,
      enabled: !locked,
      label: locked ? '$name, ${l.locked}. $lockedHint' : (selected ? '$name, ${l.selected}' : name),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null
            ? null
            : () {
                tapFeedback(context);
                onTap!();
              },
        child: AnimatedContainer(
          duration: Motion.settle,
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: selected ? p.accentSoft : p.surfaceAlt.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(Radii.lg + 2),
            border: Border.all(color: selected ? p.accent : p.divider, width: selected ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1.1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.md),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedOpacity(
                        duration: Motion.settle,
                        opacity: locked ? 0.32 : 1,
                        child: locked
                            ? ColorFiltered(colorFilter: const ColorFilter.matrix(_greyscale), child: child)
                            : child,
                      ),
                      if (selected)
                        Positioned(
                          right: 5,
                          top: 5,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: p.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: p.surface, width: 1.5),
                            ),
                            child: Center(child: AppIcon(AppIconName.check, size: 12, color: p.onAccent)),
                          ),
                        ),
                      if (locked) Center(child: AppIcon(AppIconName.lock, size: 24, color: p.ink)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(2, Space.s2, 2, 2),
                child: Column(
                  children: [
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelMedium!.copyWith(
                        color: locked ? p.inkMuted : p.ink,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locked ? lockedHint! : (selected ? l.selected : ' '),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: statusStyle.copyWith(color: selected ? p.accent : p.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _greyscale = <double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0,
];

/// Code-drawn theme preview: ground, board, a short word in tiles, accent bar.
class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.palette});
  final Palette palette;
  @override
  Widget build(BuildContext context) {
    final scores = BalanceConfig.defaults.letterScores;
    final style = context.appTheme.tileStyle;
    return CustomPaint(
      painter: _ThemeSwatchPainter(
        palette,
        TileRenderer(palette: palette, style: style, scores: scores),
        TileRenderer(palette: palette.accentTiles, style: style, scores: scores),
      ),
    );
  }
}

class _ThemeSwatchPainter extends CustomPainter {
  _ThemeSwatchPainter(this.p, this.tiles, this.accent);
  final Palette p;
  final TileRenderer tiles;
  final TileRenderer accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = p.background);
    final board = Rect.fromLTWH(w * 0.1, h * 0.14, w * 0.8, h * 0.56);
    canvas.drawRRect(RRect.fromRectAndRadius(board, Radius.circular(w * 0.07)), Paint()..color = p.board);
    final gap = w * 0.03;
    final cell = math.min((board.width - gap * 4) / 3, board.height * 0.62);
    final rowW = cell * 3 + gap * 2;
    final top = board.center.dy - cell / 2;
    const letters = ['K', 'A', 'R'];
    for (var i = 0; i < 3; i++) {
      final r = Rect.fromLTWH(board.center.dx - rowW / 2 + i * (cell + gap), top, cell, cell);
      (i == 2 ? accent : tiles).draw(canvas, r, letter: letters[i]);
    }
    // Accent bar: the theme's signature colour, like a primary button.
    final bar = Rect.fromLTWH(w * 0.22, h * 0.78, w * 0.56, h * 0.09);
    canvas.drawRRect(RRect.fromRectAndRadius(bar, Radius.circular(bar.height / 2)), Paint()..color = p.accent);
  }

  @override
  bool shouldRepaint(_ThemeSwatchPainter old) => old.p != p || old.tiles != tiles;
}

/// Mini board in the given surface style.
class _BoardSwatch extends StatelessWidget {
  const _BoardSwatch({required this.style});
  final String style;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _BoardSwatchPainter(style, context.palette), child: const SizedBox.expand());
}

class _BoardSwatchPainter extends CustomPainter {
  _BoardSwatchPainter(this.style, this.p);
  final String style;
  final Palette p;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = p.background);
    final side = math.min(size.width, size.height) * 0.82;
    final rect = Rect.fromCenter(center: size.center(Offset.zero), width: side, height: side);
    final board = RRect.fromRectAndRadius(rect, Radius.circular(side * 0.08));
    final textured = BoardArt.paint(canvas, board, style, p.board);
    if (!textured) canvas.drawRRect(board, Paint()..color = p.board);
    const n = 3;
    final pad = side * 0.07;
    final gap = side * 0.045;
    final cell = (side - 2 * pad - (n - 1) * gap) / n;
    final paint = Paint()..color = textured ? p.cellEmpty.withValues(alpha: 0.7) : p.cellEmpty;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(rect.left + pad + x * (cell + gap), rect.top + pad + y * (cell + gap), cell, cell),
            Radius.circular(cell * 0.16),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BoardSwatchPainter old) => old.style != style || old.p != p;
}

class _TileSwatch extends StatelessWidget {
  const _TileSwatch({required this.style});
  final TileStyle style;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ColoredBox(
      color: p.board,
      child: LayoutBuilder(
        builder: (context, c) {
          final side = math.min(c.maxWidth, c.maxHeight) * 0.56;
          return Center(
            child: CustomPaint(
              size: Size.square(side),
              painter: _OneTile(TileRenderer(palette: p, style: style, scores: BalanceConfig.defaults.letterScores)),
            ),
          );
        },
      ),
    );
  }
}

class _OneTile extends CustomPainter {
  _OneTile(this.r);
  final TileRenderer r;
  @override
  void paint(Canvas canvas, Size size) => r.draw(canvas, Offset.zero & size, letter: 'Ş');
  @override
  bool shouldRepaint(_OneTile old) => old.r != r;
}

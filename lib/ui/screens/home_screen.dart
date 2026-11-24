import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app/app_model.dart';
import '../../config/asset_paths.dart';
import '../../l10n/app_localizations.dart';
import '../components/app_icon.dart';
import '../../core/config/balance_config.dart';
import '../../progress/calendar.dart';
import '../../progress/levels.dart';
import '../components/hero.dart';
import '../components/widgets.dart';
import '../game/tile_renderer.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'daily_gift_sheet.dart';
import 'daily_screen.dart';
import 'game_screen.dart';
import 'intro_screen.dart';
import 'missions_screen.dart';
import 'settings_screen.dart';
import 'store_screen.dart';
import 'tutorial_screen.dart';
import 'wordbook_stats_screens.dart';

/// Main menu (spec 9): one primary action, daily with streak, three
/// secondary destinations.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _scheduled = false;
  bool _introShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    // First launch: explain the goal before anything else.
    if (app.profileLoaded && !app.profile.introSeen && !_introShown) {
      _introShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).push(IntroScreen.route(firstRun: true));
      });
    }
    if (app.ready && !_scheduled) {
      _scheduled = true;
      final l = L10n.of(context);
      unawaited(
        app.rescheduleReminder(
          ReminderTexts(
            dailyTitle: l.notifDailyTitle,
            dailyBody: l.notifDailyBody,
            streakTitle: l.notifStreakTitle,
            streakBody: l.notifStreakBody,
          ),
        ),
      );
    }
  }

  Future<void> _push(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

  Future<void> _play() async {
    final app = AppScope.read(context);
    if (!app.profile.tutorialDone) {
      await Navigator.of(context).push(TutorialScreen.route(thenPlay: true));
    } else {
      final s = app.savedClassic ?? app.newClassicGame();
      await Navigator.of(context).push(GameScreen.route(s));
    }
    if (mounted) setState(() {});
  }

  Future<void> _openDaily() async {
    await _push(const DailyScreen());
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = AppScope.of(context);
    final p = context.palette;
    final today = app.today;
    final streak = app.profile.streak.displayed(today);
    final level = Levels.fromTotalXp(app.profile.totalXp).level;

    final Widget actions;
    if (app.loadError != null) {
      actions = Column(
        children: [
          Text(l.loadError, style: context.text.bodyLarge),
          const SizedBox(height: Space.s3),
          SecondaryButton(label: l.retry, onPressed: () => app.loadData(DefaultAssetBundle.of(context))),
        ],
      );
    } else if (!app.ready) {
      actions = SizedBox(
        height: 164,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: p.accent)),
            const SizedBox(height: Space.s3),
            Text(l.loading, style: context.text.bodySmall),
          ],
        ),
      );
    } else {
      final saved = app.savedClassic;
      final daily = app.profile.dailyFor(today);
      actions = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroButton(
            title: saved != null ? l.continueGame : l.play,
            subtitle: saved != null && saved.score > 0 ? l.playSubContinue(saved.score) : l.playSubNew,
            onTap: _play,
          ),
          const SizedBox(height: Space.s3),
          _DailyCard(
            day: today,
            subtitle: daily != null ? l.dailyDoneSub(daily.score) : l.dailyReadySub,
            done: daily != null,
            streak: streak,
            atRisk: app.profile.streak.atRisk(today),
            onTap: _openDaily,
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _HomeBackground()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.s5),
                  child: Column(
                    children: [
                      const SizedBox(height: Space.s2),
                      Row(
                        children: [
                          _RoundIcon(icon: AppIconName.stats, label: l.stats, onTap: () => _push(const StatsScreen())),
                          const Spacer(),
                          _RoundIcon(
                            icon: AppIconName.info,
                            label: l.introHelp,
                            onTap: () => Navigator.of(context).push(IntroScreen.route()),
                          ),
                          const SizedBox(width: Space.s2),
                          _RoundIcon(icon: AppIconName.store, label: l.store, onTap: () => _push(const StoreScreen())),
                        ],
                      ),
                      const Spacer(flex: 3),
                      const Logo(height: 112, animate: true),
                      const SizedBox(height: Space.s4),
                      Text(
                        l.homeTagline,
                        textAlign: TextAlign.center,
                        style: context.text.bodyLarge!.copyWith(color: p.inkMuted, letterSpacing: 0.2),
                      ),
                      const SizedBox(height: Space.s4),
                      if (app.profileLoaded)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: Space.s2,
                          runSpacing: Space.s2,
                          children: [
                            // Today's free gift, until it is opened.
                            if (app.dailyGiftAvailable)
                              Semantics(
                                button: true,
                                label: l.giftTitle,
                                excludeSemantics: true,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    tapFeedback(context);
                                    showDailyGiftSheet(context);
                                  },
                                  child: InfoChip(icon: AppIconName.gift, text: l.giftChip, highlight: true),
                                ),
                              ),
                            InfoChip(icon: AppIconName.missions, text: l.levelN(level)),
                            if (streak > 0)
                              InfoChip(
                                icon: AppIconName.streak,
                                text: l.dailyStreakChip(streak),
                                highlight: app.profile.streak.atRisk(today),
                              ),
                            if (app.profile.bestScore > 0)
                              InfoChip(icon: AppIconName.stats, text: l.bestChip(app.profile.bestScore)),
                          ],
                        ),
                      const Spacer(flex: 3),
                      AnimatedSwitcher(
                        duration: Motion.screen,
                        child: KeyedSubtree(key: ValueKey(app.ready), child: actions),
                      ),
                      const Spacer(flex: 2),
                      _BottomNav(
                        items: [
                          (AppIconName.book, l.wordbook, () => _push(const WordbookScreen())),
                          (AppIconName.missions, l.missions, () => _push(const MissionsScreen())),
                          (AppIconName.settings, l.settings, () => _push(const SettingsScreen())),
                        ],
                      ),
                      const SizedBox(height: Space.s3),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft glow behind the logo + a few faint, tilted letter tiles near the
/// edges. Static: painted once.
class _HomeBackground extends StatelessWidget {
  const _HomeBackground();
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return RepaintBoundary(
      child: CustomPaint(
        painter: _BackgroundPainter(
          palette: p,
          dark: Theme.of(context).brightness == Brightness.dark,
          renderer: TileRenderer(
            palette: p,
            style: context.appTheme.tileStyle,
            scores: BalanceConfig.defaults.letterScores,
          ),
          accentRenderer: TileRenderer(
            palette: p.accentTiles,
            style: context.appTheme.tileStyle,
            scores: BalanceConfig.defaults.letterScores,
          ),
        ),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter({required this.palette, required this.dark, required this.renderer, required this.accentRenderer});
  final Palette palette;
  final bool dark;
  final TileRenderer renderer;
  final TileRenderer accentRenderer;

  // (x, y) as fractions, size in px, rotation in radians, letter, accent?
  static const _tiles = <(double, double, double, double, String, bool)>[
    (0.08, 0.17, 44, -0.28, 'K', false),
    (0.90, 0.13, 36, 0.22, 'E', true),
    (0.93, 0.36, 30, -0.15, 'L', false),
    (0.06, 0.52, 34, 0.18, 'İ', true),
    (0.12, 0.86, 38, -0.20, 'E', false),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.accent.withValues(alpha: dark ? 0.20 : 0.13),
          palette.accent.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width / 2, size.height * 0.33), radius: size.width * 0.75));
    canvas.drawRect(Offset.zero & size, glow);
    for (final (x, y, s, r, letter, accent) in _tiles) {
      canvas.save();
      canvas.translate(size.width * x, size.height * y);
      canvas.rotate(r);
      (accent ? accentRenderer : renderer).draw(
        canvas,
        Rect.fromCenter(center: Offset.zero, width: s, height: s),
        letter: letter,
        opacity: dark ? 0.10 : 0.16,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.palette != palette || old.dark != dark;
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.label, required this.onTap});
  final AppIconName icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IconBtn(icon: icon, label: label, onPressed: onTap, color: p.ink);
  }
}

/// Daily puzzle card with a calendar-leaf date badge.
class _DailyCard extends StatelessWidget {
  const _DailyCard({
    required this.day,
    required this.subtitle,
    required this.done,
    required this.streak,
    required this.atRisk,
    required this.onTap,
  });
  final DayKey day;
  final String subtitle;
  final bool done;
  final int streak;
  final bool atRisk;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final p = context.palette;
    return Semantics(
      button: true,
      label: '${l.daily}. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.xl),
          onTap: () {
            tapFeedback(context);
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.all(Space.s3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.xl),
              border: Border.all(color: p.divider),
            ),
            child: Row(
              children: [
                CalendarLeaf(day: day),
                const SizedBox(width: Space.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.daily, style: context.text.headlineSmall!.copyWith(fontSize: 18)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: context.text.bodySmall),
                    ],
                  ),
                ),
                if (done)
                  AppIcon(AppIconName.check, size: 24, color: p.accent)
                else if (streak > 0)
                  InfoChip(icon: AppIconName.streak, text: '$streak', highlight: atRisk)
                else
                  Transform.flip(flipX: true, child: AppIcon(AppIconName.back, color: p.inkMuted, size: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating bottom navigation panel.
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.items});
  final List<(AppIconName, String, VoidCallback)> items;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Space.s1),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: p.divider),
      ),
      child: Row(
        children: [
          for (final (icon, label, onTap) in items)
            Expanded(
              child: Semantics(
                button: true,
                label: label,
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(Radii.lg),
                  onTap: () {
                    tapFeedback(context);
                    onTap();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.s2),
                    child: Column(
                      children: [
                        AppIcon(icon, color: p.ink, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: context.text.bodySmall!.copyWith(color: p.ink, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

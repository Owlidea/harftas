import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app/app_model.dart';
import '../../config/asset_paths.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/calendar.dart';
import '../../progress/progression.dart';
import '../components/app_icon.dart';
import '../components/overlays.dart';
import '../components/sprite_anim.dart';
import '../components/hero.dart';
import '../components/widgets.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'game_screen.dart';
import 'share_card.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});
  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  final _shareKey = GlobalKey();
  late DayKey _month;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    final t = AppScope.read(context).today;
    _month = DayKey(t.year, t.month, 1);
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _play() async {
    final app = AppScope.read(context);
    final s = await app.dailyGame();
    if (!mounted) return;
    await Navigator.of(context).push(GameScreen.route(s, dailyDay: app.today));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = AppScope.of(context);
    final p = context.palette;
    final today = app.today;
    final result = app.profile.dailyFor(today);
    final left = today.nextMidnightUtc.difference(app.clock().toUtc());
    final limit = app.data?.config.dailyHandLimit ?? 20;

    return AppScaffold(
      title: l.daily,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Space.s4),
          // ---------------------------------------------------------- today
          Panel(
            padding: const EdgeInsets.all(Space.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CalendarLeaf(day: today, width: 58, height: 64),
                    const SizedBox(width: Space.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.today, style: context.text.headlineSmall),
                          const SizedBox(height: 2),
                          Text(formatDay(l, today), style: context.text.bodySmall),
                        ],
                      ),
                    ),
                    _Countdown(text: l.timeLeft(left.inHours, left.inMinutes % 60)),
                  ],
                ),
                const SizedBox(height: Space.s4),
                if (result != null) ...[
                  RepaintBoundary(
                    key: _shareKey,
                    child: DailyShareCard(day: today, result: result),
                  ),
                  const SizedBox(height: Space.s4),
                  HeroButton(
                    title: l.share,
                    subtitle: l.dailyDoneSub(result.score),
                    onTap: () => Sharing.shareDaily(context, _shareKey, today, result),
                  ),
                ] else ...[
                  _RuleStrip(
                    rules: [
                      (AppIconName.calendar, l.ruleSameTitle, l.ruleSameSub),
                      (AppIconName.check, l.ruleOnce, l.ruleOnceSub),
                      (AppIconName.star, l.ruleSkillTitle, l.ruleNoPowerupsSub),
                    ],
                  ),
                  const SizedBox(height: Space.s4),
                  FutureBuilder(
                    future: app.services.games.loadDaily(today),
                    builder: (context, snap) {
                      final saved = snap.data;
                      final hands = saved == null ? 0 : saved.handCounter.clamp(0, limit);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (saved != null) ...[
                            Row(
                              children: [
                                Text(l.dailyProgress(hands, limit, saved.score), style: context.text.labelLarge),
                              ],
                            ),
                            const SizedBox(height: Space.s2),
                            ProgressBar(value: hands / limit, height: 8),
                            const SizedBox(height: Space.s4),
                          ],
                          HeroButton(
                            title: saved != null ? l.continueGame : l.startDaily,
                            subtitle: saved != null ? l.dailyContinueSub : l.dailyStartSub,
                            onTap: app.ready ? _play : () {},
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          // --------------------------------------------------------- streak
          SectionHeader(l.streakTitle),
          Panel(
            padding: const EdgeInsets.all(Space.s4),
            child: _StreakPanel(today: today),
          ),
          // ------------------------------------------------------- calendar
          const SizedBox(height: Space.s5),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Calendar(month: _month, onMonth: (m) => setState(() => _month = m)),
                if (app.profile.daily.isEmpty) ...[
                  const SizedBox(height: Space.s3),
                  Text(
                    l.calendarHint,
                    textAlign: TextAlign.center,
                    style: context.text.bodySmall!.copyWith(color: p.inkMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.s3, vertical: Space.s2),
      decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(Radii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(size: const Size.square(14), painter: _ClockMark(p.inkMuted)),
          const SizedBox(width: 6),
          Text(
            text,
            style: context.text.bodySmall!.copyWith(color: p.ink, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ClockMark extends CustomPainter {
  _ClockMark(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, size.width / 2 - 1, p);
    canvas.drawLine(c, c + Offset(0, -size.height * 0.28), p);
    canvas.drawLine(c, c + Offset(size.width * 0.22, 0), p);
  }

  @override
  bool shouldRepaint(_ClockMark old) => old.color != color;
}

/// The three daily rules as one calm spec strip: icon, short title and a
/// one-line explanation per column, hairline dividers between.
class _RuleStrip extends StatelessWidget {
  const _RuleStrip({required this.rules});
  final List<(AppIconName, String, String)> rules;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Space.s4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: p.divider),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < rules.length; i++) ...[
              if (i > 0) VerticalDivider(width: 1, thickness: 1, color: p.divider),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.s2),
                  child: Column(
                    children: [
                      AppIcon(rules[i].$1, size: 24, color: p.accent),
                      const SizedBox(height: Space.s2),
                      Text(
                        rules[i].$2,
                        textAlign: TextAlign.center,
                        style: context.text.labelLarge!.copyWith(fontSize: 13, height: 1.2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rules[i].$3,
                        textAlign: TextAlign.center,
                        style: context.text.bodySmall!.copyWith(fontSize: 11.5, color: p.inkMuted, height: 1.25),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shown when a streak worth keeping was just lost: one rewarded ad (free
/// without ads) brings it back, as long as today's puzzle is still unplayed.
class _StreakRepair extends StatefulWidget {
  const _StreakRepair({required this.days});
  final int days;
  @override
  State<_StreakRepair> createState() => _StreakRepairState();
}

class _StreakRepairState extends State<_StreakRepair> {
  bool _busy = false;

  Future<void> _repair() async {
    if (_busy) return;
    setState(() => _busy = true);
    final app = AppScope.read(context);
    final l = L10n.of(context);
    final ok = await app.repairStreak();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) showGameToast(context, l.streakRepaired(app.profile.streak.current), icon: AppIconName.streak);
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final p = context.palette;
    final app = AppScope.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: Space.s4),
      padding: const EdgeInsets.all(Space.s4),
      decoration: BoxDecoration(
        color: p.accentSoft,
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: p.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.streakLostTitle(widget.days), style: context.text.labelLarge!.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(l.streakLostBody, style: context.text.bodySmall!.copyWith(color: p.inkMuted)),
          const SizedBox(height: Space.s3),
          PrimaryButton(
            label: app.profile.adsRemoved ? l.streakRepairFree : l.streakRepairAd,
            icon: AppIconName.streak,
            onPressed: _busy ? null : _repair,
          ),
        ],
      ),
    );
  }
}

/// Big flame count, best streak, last-7-days strip and badge track.
class _StreakPanel extends StatelessWidget {
  const _StreakPanel({required this.today});
  final DayKey today;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = AppScope.of(context);
    final p = context.palette;
    final streak = app.profile.streak;
    final current = streak.displayed(today);
    final next = streak.nextMilestone;
    final weekdays = l.weekdaysShort.split(',');
    final repairable = app.dailyDoneToday ? 0 : app.repairableStreak;
    final canWatch = app.services.ads.supported || app.profile.adsRemoved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (repairable > 0 && canWatch) _StreakRepair(days: repairable),
        Row(
          children: [
            SizedBox(
              width: 48,
              height: 64,
              child: Center(
                // A live streak burns: the flame is a looping render.
                child: current > 0
                    ? (SpriteAnim.available(AssetPaths.fxFlame)
                          ? const OverflowBox(
                              maxWidth: 56,
                              maxHeight: 56,
                              child: SpriteAnim(
                                AssetPaths.fxFlame,
                                size: 56,
                                loop: true,
                                placeholder: ArtIcon(AppIconName.streak, size: 40, artScale: 1.25),
                              ),
                            )
                          : const ArtIcon(AppIconName.streak, size: 40, artScale: 1.25))
                    : AppIcon(AppIconName.streak, size: 40, color: p.inkMuted),
              ),
            ),
            const SizedBox(width: Space.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.daysUnit(current),
                    style: TypeScale.display.copyWith(color: p.ink, fontSize: 32, fontFamily: appFontFamily),
                  ),
                  Text('${l.streakBest}: ${l.daysUnit(streak.best)}', style: context.text.bodySmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.s5),
        Text(l.lastSevenDays, style: context.text.bodySmall!.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: Space.s2),
        Row(
          children: [
            for (var i = 6; i >= 0; i--)
              Expanded(
                child: Builder(
                  builder: (context) {
                    final d = today.addDays(-i);
                    final played = app.profile.dailyFor(d) != null;
                    final isToday = i == 0;
                    return Column(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: played ? p.accent : p.surfaceAlt,
                            border: isToday ? Border.all(color: played ? p.accent : p.ink, width: 2) : null,
                          ),
                          child: Center(
                            child: played
                                ? AppIcon(AppIconName.check, size: 16, color: p.onAccent)
                                : Text(
                                    '${d.day}',
                                    textScaler: TextScaler.noScaling,
                                    style: context.text.bodySmall!.copyWith(
                                      color: p.inkMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          weekdays[d.weekday - 1],
                          textScaler: TextScaler.noScaling,
                          style: context.text.bodySmall!.copyWith(
                            fontSize: 11,
                            color: isToday ? p.ink : p.inkMuted,
                            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.s5),
        _BadgeTrack(current: current),
        const SizedBox(height: Space.s3),
        Text(
          next > 0 ? l.streakToNext(next, next - current) : l.allBadges,
          textAlign: TextAlign.center,
          style: context.text.bodySmall!.copyWith(color: p.ink, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          streak.shieldAvailable(today) ? l.shieldAvailable : l.shieldUsed,
          textAlign: TextAlign.center,
          style: context.text.bodySmall,
        ),
      ],
    );
  }
}

/// 0 -> 7 -> 30 -> 100 track with badge nodes.
class _BadgeTrack extends StatelessWidget {
  const _BadgeTrack({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = context.palette;
    const stops = [7, 30, 100];
    // Each segment gets equal width (0-7, 7-30, 30-100).
    double fill() {
      var prev = 0;
      for (var i = 0; i < stops.length; i++) {
        if (current < stops[i]) return (i + (current - prev) / (stops[i] - prev)) / stops.length;
        prev = stops[i];
      }
      return 1;
    }

    return SizedBox(
      height: 52,
      child: LayoutBuilder(
        builder: (context, box) {
          const node = 44.0;
          final w = box.maxWidth - node;
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Positioned(
                left: node / 2,
                right: node / 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.pill),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      children: [
                        Container(color: p.surfaceAlt),
                        FractionallySizedBox(
                          widthFactor: fill().clamp(0, 1),
                          child: Container(color: p.accent),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < stops.length; i++)
                Positioned(
                  left: w * (i + 1) / stops.length,
                  child: Builder(
                    builder: (context) {
                      final got = app.profile.badges.contains('streak_${stops[i]}');
                      final asset = AssetPaths.streakBadge(stops[i]);
                      return Semantics(
                        label: L10n.of(context).streakBadge(stops[i]),
                        child: AssetIndex.has(asset)
                            ? Opacity(
                                opacity: got ? 1 : 0.35,
                                child: Image.asset(
                                  asset,
                                  width: node,
                                  height: node,
                                  filterQuality: FilterQuality.medium,
                                  excludeFromSemantics: true,
                                ),
                              )
                            : Container(
                                width: node,
                                height: node,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: got ? p.accent : p.surface,
                                  border: Border.all(color: got ? p.accent : p.divider, width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    '${stops[i]}',
                                    textScaler: TextScaler.noScaling,
                                    style: context.text.labelLarge!.copyWith(
                                      color: got ? p.onAccent : p.inkMuted,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({required this.month, required this.onMonth});
  final DayKey month;
  final ValueChanged<DayKey> onMonth;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = AppScope.of(context);
    final p = context.palette;
    final days = DayKey.daysInMonth(month.year, month.month);
    final offset = month.weekday - 1;
    final today = app.today;
    final prev = DayKey(month.month == 1 ? month.year - 1 : month.year, month.month == 1 ? 12 : month.month - 1, 1);
    final next = DayKey(month.month == 12 ? month.year + 1 : month.year, month.month == 12 ? 1 : month.month + 1, 1);
    final canNext = next.compareTo(DayKey(today.year, today.month, 1)) <= 0;

    return Column(
      children: [
        Row(
          children: [
            IconBtn(icon: AppIconName.back, label: l.back, onPressed: () => onMonth(prev)),
            Expanded(
              child: Text(
                '${l.monthNames.split(',')[month.month - 1]} ${month.year}',
                textAlign: TextAlign.center,
                style: context.text.headlineSmall,
              ),
            ),
            Opacity(
              opacity: canNext ? 1 : 0.3,
              child: Transform.flip(
                flipX: true,
                child: IconBtn(icon: AppIconName.back, label: l.back, onPressed: canNext ? () => onMonth(next) : null),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.s2),
        Row(
          children: [
            for (final w in l.weekdaysShort.split(','))
              Expanded(
                child: Text(w, textAlign: TextAlign.center, style: context.text.bodySmall),
              ),
          ],
        ),
        const SizedBox(height: Space.s1),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: Space.s1,
          crossAxisSpacing: Space.s1,
          childAspectRatio: 0.82,
          children: [
            for (var i = 0; i < offset; i++) const SizedBox.shrink(),
            for (var d = 1; d <= days; d++)
              Builder(
                builder: (context) {
                  final key = DayKey(month.year, month.month, d);
                  final r = app.profile.dailyFor(key);
                  final isToday = key == today;
                  return Semantics(
                    label: '${formatDay(l, key)}${r == null ? '' : ', ${l.todayResult(r.score, r.words)}'}',
                    excludeSemantics: true,
                    child: Container(
                      decoration: BoxDecoration(
                        color: r != null ? p.accent : p.surfaceAlt,
                        borderRadius: BorderRadius.circular(Radii.sm),
                        border: isToday ? Border.all(color: p.ink, width: 2) : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$d',
                            style: context.text.bodySmall!.copyWith(
                              color: r != null ? p.onAccent : p.inkMuted,
                              fontWeight: FontWeight.w700,
                            ),
                            textScaler: TextScaler.noScaling,
                          ),
                          if (r != null)
                            Text(
                              '${r.score}',
                              style: context.text.bodySmall!.copyWith(color: p.onAccent, fontSize: 10),
                              textScaler: TextScaler.noScaling,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../app/app_model.dart';
import '../../config/asset_paths.dart';
import '../../core/text/word_language.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/levels.dart';
import '../../progress/missions.dart';
import '../../progress/progression.dart';
import '../components/app_icon.dart';
import '../components/widgets.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'settings_screen.dart' show boardStyleName, themeName, tileStyleName;

/// [language]: the word language the mission is played in; a letter it
/// does not have shows as that language's own letter (Ş -> S in English).
String missionText(L10n l, Mission m, {WordLanguage language = WordLanguage.turkish}) => switch (m.type) {
  MissionType.wordsOfLength => l.missionWordsOfLength(m.length!, m.target),
  MissionType.comboTwo => l.missionCombo(m.target),
  MissionType.wordWithLetter => l.missionLetter(language.normalize(m.letter!), m.target),
  MissionType.scoreInGame => l.missionScore(m.target),
  MissionType.reachStreak => l.missionStreak(m.target),
  MissionType.clearBoard => l.missionClear,
  MissionType.scoreNoPowerups => l.missionNoPowerups(m.target),
  MissionType.distinctWordsInGame => l.missionDistinct(m.target),
  MissionType.scoreTotal => l.missionScoreTotal(m.target),
  MissionType.dailyPuzzles => l.missionDailyPuzzles(m.target),
};

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = AppScope.of(context);
    final p = context.palette;
    Progression.ensureMissions(app.profile, app.today);
    Progression.ensureWeekly(app.profile, app.today);
    final weekly = app.profile.weekly!;
    final daysLeft = WeeklyGoal.daysLeft(app.today);
    final lv = Levels.fromTotalXp(app.profile.totalXp);
    final missions = app.profile.missions;
    final doneCount = missions.where((m) => m.done).length;
    final left = app.today.nextMidnightUtc.difference(app.clock().toUtc());
    final upcoming = [for (var n = lv.level + 1; n <= lv.level + 4; n++) (n, Levels.rewardFor(n))];

    return AppScaffold(
      title: l.missionsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Space.s4),
          _LevelCard(level: lv.level, into: lv.intoLevel, needed: lv.needed),
          const SizedBox(height: Space.s8),

          // ------------------------------------------------ this week's goal
          _SectionTitle(
            title: l.weeklyTitle,
            trailing: _Pill(
              text: weekly.mission.done
                  ? l.missionCompleted
                  : (daysLeft == 1 ? l.weeklyLastDay : l.weeklyDaysLeft(daysLeft)),
              strong: weekly.mission.done,
            ),
          ),
          const SizedBox(height: Space.s3),
          _Group(
            children: [
              _MissionRow(
                mission: weekly.mission,
                reward: l.weeklyReward(WeeklyGoal.rewardXp, WeeklyGoal.rewardPowerups),
              ),
            ],
          ),
          const SizedBox(height: Space.s8),

          // ------------------------------------------------ today's missions
          _SectionTitle(
            title: l.missionsToday,
            trailing: _Pill(
              text: l.missionsDoneCount(doneCount, missions.length),
              strong: doneCount == missions.length,
            ),
          ),
          const SizedBox(height: Space.s1),
          Text(
            l.missionsRenewIn(l.timeLeft(left.inHours, left.inMinutes % 60)),
            style: context.text.bodySmall!.copyWith(color: p.inkMuted),
          ),
          const SizedBox(height: Space.s3),
          _Group(children: [for (final m in missions) _MissionRow(mission: m)]),
          const SizedBox(height: Space.s8),

          // ------------------------------------------------ next rewards
          _SectionTitle(title: l.levelRewardsTitle),
          const SizedBox(height: Space.s3),
          _Group(
            children: [
              for (var i = 0; i < upcoming.length; i++)
                _RewardRow(level: upcoming[i].$1, reward: upcoming[i].$2, next: i == 0),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Zeytin teması", "Yumuşak karolar", "Ahşap zemin" or the powerup line.
String levelRewardText(L10n l, LevelReward r) => r.themeId != null
    ? l.rewardThemeShort(themeName(l, r.themeId!))
    : r.tileStyleId != null
    ? l.rewardTileShort(tileStyleName(l, r.tileStyleId!))
    : r.boardStyleId != null
    ? l.rewardBoardShort(boardStyleName(l, r.boardStyleId!))
    : l.earnedPowerup(powerupName(l, r.powerup!));

/// Level-up line: names the look when the level unlocked one.
String levelUpText(L10n l, int level, LevelReward r) =>
    r.powerup != null ? l.levelUp(level) : l.levelUpUnlock(level, levelRewardText(l, r));

AppIconName _rewardIcon(LevelReward r) => r.themeId != null
    ? AppIconName.palette
    : r.tileStyleId != null || r.boardStyleId != null
    ? AppIconName.tiles
    : powerupIcon(r.powerup!);

Color _rewardColor(BuildContext context, LevelReward r) =>
    r.powerup != null ? powerupColor(context, r.powerup!) : context.palette.accent;

/// Quiet level summary: tile badge, title, XP line and a slim bar.
class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level, required this.into, required this.needed});
  final int level;
  final int into;
  final int needed;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final p = context.palette;
    final f = (into / needed).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(Space.s5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.xl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(p.surface, p.accent, 0.10)!, p.surface],
        ),
        border: Border.all(color: p.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.tile,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(bottom: BorderSide(color: p.tileEdge, width: 3.5)),
                ),
                child: Text(
                  '$level',
                  style: context.text.titleLarge!.copyWith(
                    color: p.tileInk,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: Space.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.levelN(level), style: context.text.titleLarge!.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(l.xpToNext(needed - into), style: context.text.bodySmall!.copyWith(color: p.inkMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.s5),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.pill),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      children: [
                        Container(color: p.surfaceAlt),
                        FractionallySizedBox(
                          widthFactor: f,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [p.accent.withValues(alpha: 0.7), p.accent]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Space.s3),
              Text(
                l.xpProgress(into, needed),
                style: context.text.labelSmall!.copyWith(
                  color: p.inkMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: context.text.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
      ),
      ?trailing,
    ],
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.strong = false});
  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.s3, vertical: 4),
      decoration: BoxDecoration(
        color: strong ? p.accent : p.accentSoft,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        text,
        style: context.text.labelSmall!.copyWith(color: strong ? p.onAccent : p.accent, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// One surface holding rows split by hairlines.
class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: p.divider),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, indent: 72, color: p.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({required this.mission, this.reward});
  final Mission mission;

  /// Reward line; defaults to the daily mission's XP + powerup.
  final String? reward;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final p = context.palette;
    final m = mission;
    final muted = context.text.labelSmall!.copyWith(color: p.inkMuted, fontWeight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s4),
      child: Row(
        children: [
          _Ring(value: m.fraction, done: m.done),
          const SizedBox(width: Space.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  missionText(l, m, language: AppScope.of(context).wordLanguage),
                  style: context.text.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: m.done ? p.inkMuted : p.ink,
                    decoration: m.done ? TextDecoration.lineThrough : null,
                    decorationColor: p.inkMuted,
                  ),
                ),
                const SizedBox(height: Space.s1),
                Row(
                  children: [
                    if (!m.done) ...[
                      Text(
                        '${m.progress}/${m.target}',
                        style: muted.copyWith(color: p.accent, fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                      Text('  ·  ', style: muted),
                    ],
                    Flexible(
                      child: Text(
                        reward ?? '${l.xpGained(m.rewardXp)}  ·  +1 ${powerupName(l, m.rewardPowerup)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin progress ring; a filled accent disc with a check when done.
class _Ring extends StatelessWidget {
  const _Ring({required this.value, required this.done});
  final double value;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox.square(
      dimension: 40,
      child: CustomPaint(
        painter: _RingPainter(value: done ? 1 : value, track: p.surfaceAlt, fill: p.accent, solid: done),
        child: done ? Center(child: AppIcon(AppIconName.check, size: 18, color: p.onAccent)) : null,
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.level, required this.reward, required this.next});
  final int level;
  final LevelReward reward;
  final bool next;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final p = context.palette;
    final c = _rewardColor(context, reward);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Center(child: AppIcon(_rewardIcon(reward), size: 24, color: c)),
          ),
          const SizedBox(width: Space.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(levelRewardText(l, reward), style: context.text.bodyMedium!.copyWith(fontWeight: FontWeight.w600)),
                Text(l.levelN(level), style: context.text.labelSmall!.copyWith(color: p.inkMuted)),
              ],
            ),
          ),
          if (next) _Pill(text: l.nextReward),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.track, required this.fill, required this.solid});
  final double value;
  final Color track;
  final Color fill;
  final bool solid;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 2;
    if (solid) {
      canvas.drawCircle(c, r + 2, Paint()..color = fill);
      return;
    }
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, stroke..color = track);
    if (value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * value.clamp(0, 1),
        false,
        stroke..color = fill,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.fill != fill || old.solid != solid;
}

import 'package:material_ui/material_ui.dart';

import '../../app/app_model.dart';
import '../../config/asset_paths.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/achievements.dart';
import '../components/app_icon.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

const _roman = ['I', 'II', 'III'];

List<Achievement> _tiersOf(AchievementKind k) => [
  for (final a in Achievements.all)
    if (a.kind == k) a,
];

/// "Kelime Ustası II": the kind's name plus its tier (when it has several).
String achievementName(L10n l, Achievement a) {
  final base = switch (a.kind) {
    AchievementKind.words => l.achWords,
    AchievementKind.unique => l.achUnique,
    AchievementKind.length => l.achLength,
    AchievementKind.combo => l.achCombo,
    AchievementKind.score => l.achScore,
    AchievementKind.moveStreak => l.achMoveStreak,
    AchievementKind.clears => l.achClears,
    AchievementKind.games => l.achGames,
    AchievementKind.rare => l.achRare,
    AchievementKind.daily => l.achDaily,
  };
  final tiers = _tiersOf(a.kind);
  return tiers.length == 1 ? base : '$base ${_roman[tiers.indexOf(a)]}';
}

String achievementDesc(L10n l, Achievement a) => switch (a.kind) {
  AchievementKind.words => l.achWordsDesc(a.target),
  AchievementKind.unique => l.achUniqueDesc(a.target),
  AchievementKind.length => l.achLengthDesc(a.target),
  AchievementKind.combo => l.achComboDesc(a.target),
  AchievementKind.score => l.achScoreDesc(a.target),
  AchievementKind.moveStreak => l.achMoveStreakDesc(a.target),
  AchievementKind.clears => a.target == 1 ? l.missionClear : l.achClearsDesc(a.target),
  AchievementKind.games => l.achGamesDesc(a.target),
  AchievementKind.rare => l.achRareDesc,
  AchievementKind.daily => l.achDailyDesc(a.target),
};

/// Permanent badges, one row per kind showing the tier being worked on.
class AchievementsSection extends StatelessWidget {
  const AchievementsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final p = context.palette;
    final app = AppScope.of(context);
    final earned = Achievements.earnedCount(app.profile);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l.achievementsTitle, style: context.text.titleMedium!.copyWith(fontWeight: FontWeight.w800)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Space.s3, vertical: 4),
              decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(Radii.pill)),
              child: Text(
                l.achievementsCount(earned, Achievements.all.length),
                style: context.text.labelSmall!.copyWith(color: p.accent, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.s3),
        Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(Radii.xl),
            border: Border.all(color: p.divider),
          ),
          child: Column(
            children: [
              for (final (i, k) in AchievementKind.values.indexed) ...[
                if (i > 0) Divider(height: 1, thickness: 1, indent: 72, color: p.divider),
                _KindRow(kind: k),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _KindRow extends StatelessWidget {
  const _KindRow({required this.kind});
  final AchievementKind kind;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final p = context.palette;
    final app = AppScope.of(context);
    final tiers = _tiersOf(kind);
    final done = tiers.where((a) => app.profile.achievements.contains(a.id)).length;
    final complete = done == tiers.length;
    // The tier being worked on (or the last one once all are earned).
    final current = tiers[complete ? tiers.length - 1 : done];
    final value = Achievements.progress(current, app.profile, app.wordbook, app.wordLanguage.code);
    final fraction = complete ? 1.0 : (value / current.target).clamp(0.0, 1.0);
    final muted = context.text.labelSmall!.copyWith(color: p.inkMuted, fontWeight: FontWeight.w700);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.s4, vertical: Space.s3),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: done > 0 ? p.accentSoft : p.surfaceAlt, shape: BoxShape.circle),
            child: Opacity(
              opacity: done > 0 ? 1 : 0.45,
              child: done > 0
                  ? const ArtIcon(AppIconName.star, size: 24, artScale: 1.15)
                  : AppIcon(AppIconName.star, size: 20, color: p.inkMuted),
            ),
          ),
          const SizedBox(width: Space.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        achievementName(l, current),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium!.copyWith(fontWeight: FontWeight.w700, height: 1.3),
                      ),
                    ),
                    if (tiers.length > 1) ...[
                      const SizedBox(width: Space.s2),
                      // One pip per tier, filled when earned.
                      for (var t = 0; t < tiers.length; t++)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: t < done ? p.accent : p.surfaceAlt,
                            border: Border.all(color: t < done ? p.accent : p.divider),
                          ),
                        ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(achievementDesc(l, current), style: context.text.bodySmall!.copyWith(color: p.inkMuted)),
                const SizedBox(height: Space.s2),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Radii.pill),
                        child: SizedBox(
                          height: 5,
                          child: Stack(
                            children: [
                              Container(color: p.surfaceAlt),
                              FractionallySizedBox(
                                widthFactor: fraction,
                                child: Container(color: p.accent),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Space.s3),
                    if (complete)
                      AppIcon(AppIconName.check, size: 14, color: p.accent)
                    else
                      Text(
                        '${value > current.target ? current.target : value}/${current.target}',
                        style: muted.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
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

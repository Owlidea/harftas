import 'package:material_ui/material_ui.dart';

import '../../app/app_model.dart';
import '../../config/asset_paths.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/levels.dart';
import '../components/widgets.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'achievements_section.dart';
import 'game_screen.dart';
import 'share_card.dart';
import 'tutorial_screen.dart';

/// "Oyna" from an empty screen: straight into a game (or the tutorial first).
Widget _playAction(BuildContext context) => PrimaryButton(
  label: L10n.of(context).play,
  onPressed: () {
    final app = AppScope.read(context);
    final nav = Navigator.of(context);
    if (!app.profile.tutorialDone) {
      nav.pushReplacement(TutorialScreen.route(thenPlay: true));
    } else {
      nav.pushReplacement(GameScreen.route(app.savedClassic ?? app.newClassicGame()));
    }
  },
);

class WordbookScreen extends StatefulWidget {
  const WordbookScreen({super.key});
  @override
  State<WordbookScreen> createState() => _WordbookScreenState();
}

class _WordbookScreenState extends State<WordbookScreen> {
  int? _length;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = AppScope.of(context);
    final book = app.wordbook;
    final p = context.palette;
    if (book.uniqueCount == 0) {
      return AppScaffold(
        title: l.wordbookTitle,
        scroll: false,
        child: Center(
          child: EmptyState(
            text: l.wordbookEmpty,
            asset: AssetPaths.emptyWordbook,
            icon: AppIconName.book,
            action: _playAction(context),
          ),
        ),
      );
    }
    final groups = book.byLength(app.wordLanguage.compare); // Turkish: Ç after C, İ after I
    final lengths = groups.keys.toList()..sort();
    final shown = _length ?? lengths.first;
    final words = groups[shown] ?? const <String>[];

    return AppScaffold(
      title: l.wordbookTitle,
      scroll: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: Space.s3),
                Text(l.wordbookTotal(book.uniqueCount), textAlign: TextAlign.center, style: context.text.titleLarge),
                const SizedBox(height: Space.s4),
                Row(
                  children: [
                    _Record(label: l.recordLongest, word: book.longest),
                    const SizedBox(width: Space.s3),
                    _Record(label: l.recordHighest, word: book.highestScoring),
                  ],
                ),
                const SizedBox(height: Space.s4),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final n in lengths)
                        Padding(
                          padding: const EdgeInsets.only(right: Space.s2),
                          child: ChoiceChip(
                            label: Text('${l.lettersGroup(n)} · ${groups[n]!.length}'),
                            selected: n == shown,
                            onSelected: (_) => setState(() => _length = n),
                            selectedColor: p.accent,
                            labelStyle: TextStyle(color: n == shown ? p.onAccent : p.ink),
                            showCheckmark: false,
                            side: BorderSide(color: p.divider),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.s3),
              ],
            ),
          ),
          SliverList.builder(
            itemCount: words.length,
            itemBuilder: (context, i) {
              final w = words[i];
              final e = book.entries[w]!;
              return Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: p.divider)),
                ),
                padding: const EdgeInsets.symmetric(vertical: Space.s3, horizontal: Space.s1),
                child: Row(
                  children: [
                    Expanded(child: Text(w, style: context.text.headlineSmall!.copyWith(letterSpacing: 1.5))),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(l.timesBuilt(e.count), style: context.text.labelLarge),
                        Text(l.firstBuilt(formatDay(l, e.first)), style: context.text.bodySmall),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Space.s8)),
        ],
      ),
    );
  }
}

class _Record extends StatelessWidget {
  const _Record({required this.label, required this.word});
  final String label;
  final String? word;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Panel(
      child: Column(
        children: [
          Text(
            word ?? L10n.of(context).dash,
            style: context.text.headlineSmall!.copyWith(color: context.palette.accent),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: context.text.bodySmall),
        ],
      ),
    ),
  );
}

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final app = AppScope.of(context);
    final pr = app.profile;
    if (pr.totalGames == 0) {
      return AppScaffold(
        title: l.statsTitle,
        scroll: false,
        child: Center(
          child: EmptyState(text: l.statsEmpty, icon: AppIconName.stats, action: _playAction(context)),
        ),
      );
    }
    final items = <(String, String)>[
      (l.statBestScore, '${pr.bestScoreFor(app.wordLanguage.code)}'),
      (l.statGames, '${pr.totalGames}'),
      (l.statWords, '${pr.totalWords}'),
      (l.statAvgLength, pr.averageWordLength.toStringAsFixed(1).replaceAll('.', ',')),
      (l.statBestStreak, '${pr.bestMoveStreak}'),
      (l.statDailyBest, l.daysUnit(pr.streak.best)),
      (l.statMostBuilt, app.wordbook.mostBuilt ?? l.dash),
      (l.statLevel, '${Levels.fromTotalXp(pr.totalXp).level}'),
    ];
    return AppScaffold(
      title: l.statsTitle,
      child: Padding(
        padding: const EdgeInsets.only(top: Space.s4),
        child: LayoutBuilder(
          builder: (context, box) {
            final cols = box.maxWidth > 420 ? 3 : 2;
            final w = (box.maxWidth - (cols - 1) * Space.s3) / cols;
            final tiles = Wrap(
              spacing: Space.s3,
              runSpacing: Space.s3,
              children: [
                for (final (label, value) in items)
                  SizedBox(
                    width: w,
                    child: Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(value, style: context.text.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: Space.s1),
                          Text(label, style: context.text.bodySmall),
                        ],
                      ),
                    ),
                  ),
              ],
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                tiles,
                const SizedBox(height: Space.s8),
                const AchievementsSection(),
              ],
            );
          },
        ),
      ),
    );
  }
}

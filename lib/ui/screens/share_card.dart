import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/app_model.dart';
import '../../config/app_info.dart';
import '../../config/asset_paths.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/calendar.dart';
import '../../progress/profile.dart';
import '../../services/analytics.dart';
import '../components/app_icon.dart';
import '../components/widgets.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';

String formatDay(L10n l, DayKey d) => '${d.day} ${l.monthNames.split(',')[d.month - 1]} ${d.year}';

/// Daily share card (spec 7.2): name, date, score, word count, longest word
/// LENGTH only (no spoilers) and the streak. Drawn in code; the delivered
/// logo is used when present.
class DailyShareCard extends StatelessWidget {
  const DailyShareCard({super.key, required this.day, required this.result});
  final DayKey day;
  final DailyResult result;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final p = context.palette;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(Space.s6),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(Radii.xl),
          border: Border.all(color: p.divider),
        ),
        child: Column(
          children: [
            const Logo(height: 44),
            const SizedBox(height: Space.s2),
            Text(formatDay(l, day), style: context.text.bodySmall),
            const Spacer(),
            Text(
              '${result.score}',
              style: TypeScale.display.copyWith(color: p.ink, fontSize: 64, fontFamily: appFontFamily),
            ),
            Text(l.score, style: context.text.bodySmall),
            const Spacer(),
            Row(
              children: [
                _Stat(value: '${result.words}', label: l.wordsBuilt),
                _Stat(value: l.lettersUnit(result.longestLength), label: l.shareCardLongest),
                _Stat(value: l.daysUnit(result.streakAfter), label: l.streakCurrent, icon: AppIconName.streak),
              ],
            ),
            const SizedBox(height: Space.s2),
            // Five-cell length bar: shows how long the best word was, not the word.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 3; i <= 8; i++)
                  Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: i <= result.longestLength ? p.accent : p.surfaceAlt,
                      borderRadius: BorderRadius.circular(Radii.xs),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.icon});
  final String value;
  final String label;
  final AppIconName? icon;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[AppIcon(icon!, size: 18, color: context.palette.accent), const SizedBox(width: 2)],
            Flexible(
              child: Text(value, style: context.text.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        Text(label, style: context.text.bodySmall, textAlign: TextAlign.center),
      ],
    ),
  );
}

abstract final class Sharing {
  static Future<void> shareDaily(BuildContext context, GlobalKey cardKey, DayKey day, DailyResult r) async {
    final l = L10n.of(context);
    final app = AppScope.read(context);
    app.services.analytics.log(AnalyticsEvent.shareTapped, {'mode': 'daily'});
    final text = l.shareText(
      AppInfo.displayName,
      formatDay(l, day),
      r.score,
      r.words,
      r.longestLength,
      r.streakAfter,
      AppInfo.shareUrl,
    );
    final files = <XFile>[];
    try {
      final boundary = cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        files.add(XFile.fromData(bytes!.buffer.asUint8List(), mimeType: 'image/png', name: 'gunluk_$day.png'));
      }
    } on Object catch (e, st) {
      app.services.crash.record(e, st, reason: 'share card render');
    }
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        files: files.isEmpty ? null : files,
        fileNameOverrides: files.isEmpty ? null : ['gunluk_$day.png'],
      ),
    );
  }

  static Future<void> shareScore(BuildContext context, int score, int words) async {
    final app = AppScope.read(context);
    app.services.analytics.log(AnalyticsEvent.shareTapped, {'mode': 'classic'});
    final l = L10n.of(context);
    await SharePlus.instance.share(
      ShareParams(
        text: '${AppInfo.displayName} · ${l.score} $score · $words ${l.wordsBuilt.toLowerCase()}\n${AppInfo.shareUrl}',
      ),
    );
  }
}

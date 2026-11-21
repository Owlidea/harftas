import 'package:material_ui/material_ui.dart';

import '../../config/asset_paths.dart';
import '../../l10n/app_localizations.dart';
import '../../progress/calendar.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'app_icon.dart';
import 'widgets.dart';

/// Primary action: big accent card with a play mark.
class HeroButton extends StatefulWidget {
  const HeroButton({super.key, required this.title, required this.subtitle, required this.onTap});
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  State<HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<HeroButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: '${widget.title}. ${widget.subtitle}',
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          tapFeedback(context);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down && !context.reduceMotion ? 0.97 : 1,
          duration: Motion.pick,
          child: Container(
            padding: const EdgeInsets.fromLTRB(Space.s4, Space.s4, Space.s5, Space.s4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.xl),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(p.accent, Colors.white, 0.10)!,
                  Color.lerp(p.accent, Colors.black, dark ? 0.10 : 0.18)!,
                ],
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 40, height: 52, child: CustomPaint(painter: _PlayMark(p.onAccent))),
                const SizedBox(width: Space.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: context.text.titleLarge!.copyWith(color: p.onAccent, fontSize: 24, height: 1.1),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: context.text.bodyLarge!.copyWith(
                          color: p.onAccent.withValues(alpha: 0.82),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.flip(
                  flipX: true,
                  child: AppIcon(AppIconName.back, color: p.onAccent.withValues(alpha: 0.8), size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayMark extends CustomPainter {
  _PlayMark(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.2;
    final path = Path()
      ..moveTo(c.dx - r * 0.7, c.dy - r)
      ..lineTo(c.dx + r * 1.05, c.dy)
      ..lineTo(c.dx - r * 0.7, c.dy + r)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = r * 0.35
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_PlayMark old) => old.color != color;
}

/// Calendar-leaf date badge (month band + day number).
class CalendarLeaf extends StatelessWidget {
  const CalendarLeaf({super.key, required this.day, this.width = 52, this.height = 58});
  final DayKey day;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = L10n.of(context);
    final band = height * 0.31;
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: p.divider),
      ),
      child: Column(
        children: [
          Container(
            height: band,
            width: double.infinity,
            color: p.accent,
            alignment: Alignment.center,
            child: Text(
              l.monthShort.split(',')[day.month - 1],
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: appFontFamily,
                fontSize: band * 0.55,
                fontWeight: FontWeight.w800,
                color: p.onAccent,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '${day.day}',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontFamily: appFontFamily,
                  fontSize: height * 0.38,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

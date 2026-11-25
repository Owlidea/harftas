import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'widgets.dart';

/// Pill-shaped segmented control; the selected segment slides under the
/// labels (appearance in Settings, word language in Settings and the intro).
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.values,
    required this.current,
    required this.label,
    required this.onChanged,
  });
  final List<T> values;
  final T current;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final index = values.indexOf(current);
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(Radii.pill)),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: context.reduceMotion ? Duration.zero : Motion.settle,
            curve: Curves.easeOutCubic,
            alignment: Alignment(values.length == 1 ? 0 : -1 + 2 * index / (values.length - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / values.length,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(Radii.pill)),
              ),
            ),
          ),
          Row(
            children: [
              for (final v in values)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: v == current,
                    label: label(v),
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        tapFeedback(context);
                        onChanged(v);
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Motion.pick,
                          style: context.text.labelLarge!.copyWith(color: v == current ? p.onAccent : p.inkMuted),
                          child: Text(label(v)),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

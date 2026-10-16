// step_header.dart
//
// _StepHeader — heading of a PolygonWizardSheet step: the step title
// (w700, cs.onSurface) above its hint (12, cs.onSurfaceVariant), start
// aligned or centred.

part of "../index.dart";

final class _StepHeader extends StatelessWidget {
  final PolygonWizardStep step;
  final bool centered;
  final double titleSize;

  const _StepHeader({
    required this.step,
    this.centered = false,
    this.titleSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final TextAlign align = centered ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            step.title,
            textAlign: align,
            style: theme.textTheme.titleSmall?.copyWith(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ),
        const SizedBox(height: kDefaultPadding / 2),
        Text(
          step.hint,
          textAlign: align,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

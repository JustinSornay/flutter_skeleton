// gauge_bar.dart
//
// Private gauge of StateMessageView: a caption row (left caption, right
// caption in the tone colour) above a rounded determinate bar. Row and bar
// form one semantics node (label = left caption, value = right caption)
// whose children are excluded, so the status is announced once, as a value.

part of "../index.dart";

final class _GaugeBar extends StatelessWidget {
  /// Captions and fill ratio.
  final StateMessageGauge gauge;

  /// Tone foreground: right caption and bar fill.
  final Color color;

  const _GaugeBar({required this.gauge, required this.color});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final TextStyle? captionStyle = theme.textTheme.labelSmall;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
      child: Semantics(
        container: true,
        excludeSemantics: true,
        label: gauge.leftCaption,
        value: gauge.rightCaption,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    gauge.leftCaption,
                    style: captionStyle?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: kDefaultPadding),
                Text(
                  gauge.rightCaption,
                  style: captionStyle?.copyWith(fontWeight: FontWeight.w600, color: color),
                ),
              ],
            ),
            const SizedBox(height: kDefaultPadding / 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: gauge.value.clamp(0.0, 1.0),
                minHeight: kDefaultPadding,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

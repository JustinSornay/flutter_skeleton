// legend_entry.dart
//
// Private part of DistributionBar: one legend entry, a decorative colour dot
// followed by the entry text (which wraps rather than overflowing on narrow
// widths).

part of "../index.dart";

/// Diameter of the legend dot.
const double _dotSize = kDefaultPadding;

/// Dot + text of one segment.
final class _LegendEntry extends StatelessWidget {
  /// Slice colour of the segment.
  final Color color;

  /// Label and share, as shown and read by screen readers.
  final String text;

  const _LegendEntry({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ExcludeSemantics(
          child: SizedBox.square(
            dimension: _dotSize,
            child: DecoratedBox(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
        const SizedBox(width: kDefaultPadding * 0.75),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}

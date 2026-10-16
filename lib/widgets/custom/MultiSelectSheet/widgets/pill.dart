// pill.dart
//
// _Pill — small neutral tag shared by the counter (radius 999) and the row
// badge (radius 4) of MultiSelectSheet: `cs.surfaceContainerHighest` fill,
// 1 dp `cs.outlineVariant` border (so it stays visible on an AppModal card,
// whose fill is the same token) and one line of `cs.onSurfaceVariant` text.
// Its width is capped at half of the enclosing row so a long text (large
// text scale, long translation) ellipsizes instead of overflowing.

part of "../index.dart";

/// Counter pill corner radius.
const double _counterRadius = 999;

/// Row badge corner radius.
const double _badgeRadius = 4;

/// Share of the enclosing row a pill may take at most.
const double _pillMaxWidthFactor = 0.5;

final class _Pill extends StatelessWidget {
  final String text;
  final double radius;
  final EdgeInsetsGeometry padding;
  final TextStyle? style;

  /// Width of the enclosing row; the pill takes at most half of it.
  final double rowWidth;

  const _Pill({
    required this.text,
    required this.radius,
    required this.padding,
    required this.style,
    required this.rowWidth,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: rowWidth * _pillMaxWidthFactor),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Padding(
          padding: padding,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

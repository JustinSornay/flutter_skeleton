// axis_header.dart
//
// _AxisHeader — the optional header row of ClusteredValueAxis: an optional
// icon in a cs.primaryContainer disc, the title (ellipsised), the point
// count and, when best highlighting is on, a cs.tertiary star with the best
// value text.

part of "../index.dart";

final class _AxisHeader extends StatelessWidget {
  /// Title, already localised.
  final String title;

  /// Point count text.
  final String countText;

  /// Leading icon; null draws no disc.
  final IconData? icon;

  /// Best value text; null hides the star and the text.
  final String? bestText;

  const _AxisHeader({required this.title, required this.countText, this.icon, this.bestText});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final TextStyle? base = theme.textTheme.labelSmall;
    final TextStyle? meta = base?.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3);

    return Row(
      children: <Widget>[
        if (icon case final IconData leading) ...<Widget>[
          SizedBox.square(
            dimension: 18,
            child: DecoratedBox(
              decoration: BoxDecoration(color: cs.primaryContainer, shape: BoxShape.circle),
              child: Icon(leading, size: 11, color: cs.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: kDefaultPadding / 2),
        ],
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: base?.copyWith(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.2, color: cs.onSurface),
          ),
        ),
        Text(countText, style: meta?.copyWith(color: cs.onSurfaceVariant)),
        if (bestText case final String best) ...<Widget>[
          Text(" · ", style: meta?.copyWith(color: cs.onSurfaceVariant)),
          Icon(Icons.star_rounded, size: 12, color: cs.tertiary),
          const SizedBox(width: 2),
          Text(best, style: meta?.copyWith(color: cs.onSurface)),
        ],
      ],
    );
  }
}

// cluster_pill.dart
//
// _ClusterPill — "N items" pill of merged points: two dots, the
// custom.clustered_value_axis.cluster label and, when it holds the best
// value, a star. Outlined cs.primary on cs.surface; filled cs.primary with
// cs.onPrimary content when open or when a member is selected.

part of "../index.dart";

final class _ClusterPill extends StatelessWidget {
  /// Number of members.
  final int count;

  /// Filled (open or holding the selection).
  final bool filled;

  /// A member is the selection.
  final bool selected;

  /// Best value text when a member is the best; null hides the star.
  final String? bestText;

  final _PillAnchor anchor;

  const _ClusterPill({
    required this.count,
    required this.filled,
    required this.selected,
    required this.anchor,
    this.bestText,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Color foreground = filled ? cs.onPrimary : cs.primary;
    final Map<String, String> args = <String, String>{"count": "$count"};
    final String text = "custom.clustered_value_axis.cluster".tr(namedArgs: args);

    return _PillShell(
      anchor: anchor,
      selected: selected,
      decoration: BoxDecoration(
        color: filled ? cs.primary : cs.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.primary, width: 2.5),
        boxShadow: <BoxShadow>[
          BoxShadow(color: cs.primary.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      semanticsLabel: <String>[text, ?bestText].join(", "),
      semanticsHint: "custom.clustered_value_axis.open_group".tr(namedArgs: args),
      content: <Widget>[
        _dot(foreground),
        const SizedBox(width: 1.5),
        _dot(foreground),
        const SizedBox(width: kDefaultPadding / 2),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: foreground,
            ),
          ),
        ),
        if (bestText != null) ...<Widget>[
          const SizedBox(width: kDefaultPadding / 2),
          Icon(Icons.star_rounded, size: 12, color: filled ? cs.onPrimary : cs.tertiary),
        ],
      ],
    );
  }

  Widget _dot(Color color) {
    return SizedBox.square(
      dimension: 5,
      child: DecoratedBox(decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    );
  }
}

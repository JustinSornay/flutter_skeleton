// reference_pill.dart
//
// _ReferencePill — the reference fused with the members it overlapped: a
// cs.inverseSurface stadium with the reference icon, the
// custom.clustered_value_axis.reference_group label and, when it holds the
// best value, a cs.inversePrimary star. A cs.primary ring shows while it is
// open or holds the selection (the reference or a member).

part of "../index.dart";

final class _ReferencePill extends StatelessWidget {
  /// Number of absorbed members.
  final int count;

  final IconData icon;

  /// Reference name, prefixed to the semantics label.
  final String referenceLabel;

  /// Draws the selection ring.
  final bool ring;

  /// The reference or a member is the selection.
  final bool selected;

  /// Best value text when a member is the best; null hides the star.
  final String? bestText;

  final _PillAnchor anchor;

  const _ReferencePill({
    required this.count,
    required this.icon,
    required this.referenceLabel,
    required this.ring,
    required this.selected,
    required this.anchor,
    this.bestText,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String text = "custom.clustered_value_axis.reference_group".tr(
      namedArgs: <String, String>{"count": "$count"},
    );

    return _PillShell(
      anchor: anchor,
      selected: selected,
      decoration: BoxDecoration(
        color: cs.inverseSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.inverseSurface, width: 2.5),
        boxShadow: <BoxShadow>[
          BoxShadow(color: cs.shadow.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
          if (ring) BoxShadow(color: cs.primary.withValues(alpha: 0.5), spreadRadius: 3),
        ],
      ),
      semanticsLabel: <String>[referenceLabel, text, ?bestText].join(", "),
      // The popover lists the reference row plus the members.
      semanticsHint: "custom.clustered_value_axis.open_group".tr(
        namedArgs: <String, String>{"count": "${count + 1}"},
      ),
      content: <Widget>[
        Icon(icon, size: 14, color: cs.onInverseSurface),
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
              color: cs.onInverseSurface,
            ),
          ),
        ),
        if (bestText != null) ...<Widget>[
          const SizedBox(width: kDefaultPadding / 2),
          Icon(Icons.star_rounded, size: 12, color: cs.inversePrimary),
        ],
      ],
    );
  }
}

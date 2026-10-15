// feature_row.dart
//
// Private row of an expanded CollapsedGateGroup: decorative icon, label and
// an optional dense PillBadge (lock icon, cs.onPrimary on cs.primary). The
// label and the pill share a Wrap: the pill sits at the row end when both
// fit on one line, else it moves under the label, so neither is squeezed at
// narrow widths or large text scales. The row is not interactive and is read
// as one merged semantics node.

part of "../index.dart";

/// Leading icon size.
const double _rowIconSize = 16;

final class _FeatureRow extends StatelessWidget {
  final GatedFeatureEntry entry;

  /// Resolved pill label (entry override or group default).
  final String? badgeLabel;

  const _FeatureRow({required this.entry, required this.badgeLabel});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? badge = badgeLabel;

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding * 2,
          vertical: kDefaultPadding,
        ),
        child: Row(
          children: <Widget>[
            Icon(entry.icon, size: _rowIconSize, color: cs.onSurfaceVariant),
            const SizedBox(width: kDefaultPadding * 1.5),
            // A Wrap instead of Expanded label + trailing pill: a trailing
            // non-flex pill takes its full width first and squeezes the label
            // to nothing (or overflows) on narrow rows.
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: kDefaultPadding,
                runSpacing: kDefaultPadding / 2,
                children: <Widget>[
                  Text(
                    entry.label,
                    style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                  ),
                  if (badge != null && badge.isNotEmpty)
                    PillBadge(
                      label: badge,
                      icon: Icons.lock_outline_rounded,
                      dense: true,
                      color: cs.onPrimary,
                      backgroundColor: cs.primary,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

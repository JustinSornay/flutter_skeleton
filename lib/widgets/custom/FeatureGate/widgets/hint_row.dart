// hint_row.dart
//
// Private compact hint of FeatureGate (GateDisplayMode.hint): one row with
// a small lock icon, the locked label (one line, ellipsis) and the lock
// badge, at least 48 dp tall. The row calls onUnlock when it is set.

part of "../index.dart";

/// Lock icon size in the hint row.
const double _hintIconSize = kDefaultPadding * 1.5;

/// Opacity of the hint lock icon.
const double _hintIconAlpha = 0.6;

final class _HintRow extends StatelessWidget {
  final String label;

  /// The lock badge, at the end of the row.
  final Widget badge;

  final VoidCallback? onUnlock;

  const _HintRow({
    required this.label,
    required this.badge,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onUnlock,
        borderRadius: BorderRadius.circular(kDefaultPadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding * 1.5,
              vertical: kDefaultPadding,
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.lock_outline_rounded,
                  size: _hintIconSize,
                  color: cs.onSurfaceVariant.withValues(alpha: _hintIconAlpha),
                ),
                const SizedBox(width: kDefaultPadding),
                Expanded(
                  child: ExcludeSemantics(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ),
                const SizedBox(width: kDefaultPadding),
                badge,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

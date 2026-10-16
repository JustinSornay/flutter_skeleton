// expand_toggle.dart
//
// _ExpandToggle — "Show all / Show less" link of RankedBadgeList: underlined
// cs.primary text and a chevron, in an InkWell at least kMinTapTarget high.
// One button semantics node carrying the expanded state.

part of "../index.dart";

/// Size of the chevron icon.
const double _chevronSize = 16;

/// Gap between the text and the chevron (4 dp).
const double _chevronGap = kDefaultPadding / 2;

final class _ExpandToggle extends StatelessWidget {
  /// Visible text, already resolved for the current state.
  final String label;

  /// Whether the list is expanded (chevron up, expanded semantics).
  final bool isExpanded;

  final VoidCallback onTap;

  const _ExpandToggle({
    required this.label,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = theme.colorScheme.primary;
    final TextStyle baseStyle = theme.textTheme.labelMedium ?? const TextStyle(fontSize: 12);

    return Semantics(
      container: true,
      button: true,
      expanded: isExpanded,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kDefaultPadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: Text(
                    label,
                    style: baseStyle.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: color,
                    ),
                  ),
                ),
                const SizedBox(width: _chevronGap),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: _chevronSize,
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

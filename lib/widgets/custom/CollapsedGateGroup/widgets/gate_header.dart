// gate_header.dart
//
// Private header of CollapsedGateGroup: lock icon, summary text and an
// up / down chevron. One button semantics node with an expanded state and a
// localised hint (Semantics.hint, read on every platform); at least
// kMinTapTarget tall.

part of "../index.dart";

/// Lock icon size.
const double _lockIconSize = 16;

/// Chevron size.
const double _chevronSize = 18;

final class _GateHeader extends StatelessWidget {
  final String summary;

  final bool isExpanded;

  final VoidCallback onToggle;

  const _GateHeader({
    required this.summary,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String hint = isExpanded
        ? "custom.collapsed_gate_group.collapse".tr()
        : "custom.collapsed_gate_group.expand".tr();

    return Semantics(
      container: true,
      button: true,
      expanded: isExpanded,
      hint: hint,
      child: InkWell(
        onTap: onToggle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding * 2,
              vertical: kDefaultPadding,
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.lock_outline_rounded, size: _lockIconSize, color: cs.onSurfaceVariant),
                const SizedBox(width: kDefaultPadding * 1.5),
                Expanded(
                  child: Text(
                    summary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: kDefaultPadding),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: _chevronSize,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

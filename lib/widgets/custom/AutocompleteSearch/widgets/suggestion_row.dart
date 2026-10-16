// suggestion_row.dart
//
// _SuggestionRow — the tappable frame around one host-built suggestion: a
// single button semantics node, at least kMinTapTarget tall, with the
// dropdown's default text style (13, cs.onSurface, 2 lines) and icon theme
// (16, cs.primary) so a plain Text or Icon matches the dropdown.

part of "../index.dart";

final class _SuggestionRow extends StatelessWidget {
  /// Called when the row is tapped.
  final VoidCallback onTap;

  /// Row content built by the host.
  final Widget child;

  const _SuggestionRow({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTapTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding * 1.5,
                vertical: kDefaultPadding,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                heightFactor: 1,
                child: IconTheme.merge(
                  data: IconThemeData(size: 16, color: cs.primary),
                  child: DefaultTextStyle.merge(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: cs.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

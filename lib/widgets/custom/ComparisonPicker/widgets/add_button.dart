// add_button.dart
//
// Outlined add button at the top of ComparisonPicker's secondary section:
// cs.primary border, icon and label, at least kMinTapTarget tall.

part of "../index.dart";

/// Size of the leading add icon.
const double _addIconSize = 16;

final class _AddButton extends StatelessWidget {
  /// Button text, already localised.
  final String label;

  final VoidCallback onPressed;

  const _AddButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: _rowGap),
      child: Semantics(
        container: true,
        button: true,
        child: Material(
          color: cs.surface,
          animationDuration: Duration.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_rowRadius),
            side: BorderSide(color: cs.primary),
          ),
          child: InkWell(
            onTap: onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kMinTapTarget),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.add_circle_outline, size: _addIconSize, color: cs.primary),
                    const SizedBox(width: kDefaultPadding),
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// edit_chip.dart
//
// Private trailing "✏ Edit" chip of EditableValueRow. It is not interactive
// itself (the host owns the gesture): it only exposes a button semantics
// label and hides its visible text from semantics to avoid a double read.

part of "../index.dart";

final class _EditChip extends StatelessWidget {
  /// Value the chip edits; fills `{value}` in the default semantics label.
  final String title;

  /// Visible text; null → `custom.editable_value_row.edit`.
  final String? editLabel;

  /// Accessible label; null → `custom.editable_value_row.edit_semantics`.
  final String? semanticsLabel;

  const _EditChip({
    required this.title,
    required this.editLabel,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String action = editLabel ?? "custom.editable_value_row.edit".tr();
    final String label = semanticsLabel ??
        "custom.editable_value_row.edit_semantics".tr(
          namedArgs: <String, String>{"action": action, "value": title},
        );

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.edit_rounded, size: 14, color: cs.primary),
            const SizedBox(width: kDefaultPadding / 2),
            Text(
              action,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

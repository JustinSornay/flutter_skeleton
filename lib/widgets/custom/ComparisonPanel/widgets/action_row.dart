// action_row.dart
//
// _ActionRow — the decision buttons under a ComparisonPanel card: an
// outlined Cancel button (flex 1) and a filled `cs.tertiary` Confirm button
// (flex 2), both kMinTapTarget tall.

part of "../index.dart";

/// Corner radius of both buttons.
const double _buttonRadius = 10;

final class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.onCancel,
    required this.onConfirm,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.confirmIcon,
  });

  final VoidCallback onCancel;

  /// Null disables Confirm.
  final VoidCallback? onConfirm;

  final String cancelLabel;

  final String confirmLabel;

  final IconData confirmIcon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    const TextStyle labelStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w700);
    final OutlinedBorder shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(_buttonRadius));
    const EdgeInsets padding = EdgeInsets.symmetric(horizontal: kDefaultPadding);

    return Row(
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: kMinTapTarget,
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close, size: 16),
              label: Text(cancelLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.onSurfaceVariant,
                side: BorderSide(color: cs.outline),
                shape: shape,
                padding: padding,
                textStyle: labelStyle,
              ),
            ),
          ),
        ),
        const SizedBox(width: kDefaultPadding),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: kMinTapTarget,
            child: FilledButton.icon(
              onPressed: onConfirm,
              icon: Icon(confirmIcon, size: 16),
              label: Text(confirmLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
              style: FilledButton.styleFrom(
                backgroundColor: cs.tertiary,
                foregroundColor: cs.onTertiary,
                shape: shape,
                padding: padding,
                textStyle: labelStyle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

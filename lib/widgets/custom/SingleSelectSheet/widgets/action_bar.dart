// action_bar.dart
//
// _ActionBar — cancel (outlined, flex 1) and confirm (filled, flex 2)
// buttons of SingleSelectSheet, 48 dp tall with radius 10. A null onConfirm
// disables the confirm button.

part of "../index.dart";

/// Button corner radius.
const double _buttonRadius = 10;

final class _ActionBar extends StatelessWidget {
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;

  const _ActionBar({
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    const OutlinedBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(_buttonRadius)),
    );
    const Size minimumSize = Size.fromHeight(kMinTapTarget);
    final TextStyle? labelStyle = theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _sideInset,
        vertical: kDefaultPadding * 2,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: cs.onSurfaceVariant,
                minimumSize: minimumSize,
                shape: shape,
                textStyle: labelStyle,
              ),
              child: Text(cancelLabel),
            ),
          ),
          const SizedBox(width: kDefaultPadding),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: onConfirm,
              style: FilledButton.styleFrom(
                minimumSize: minimumSize,
                shape: shape,
                textStyle: labelStyle,
              ),
              child: Text(confirmLabel),
            ),
          ),
        ],
      ),
    );
  }
}

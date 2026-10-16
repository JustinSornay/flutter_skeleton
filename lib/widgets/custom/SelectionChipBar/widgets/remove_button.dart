// remove_button.dart
//
// Private 48 dp close button ending a removable SelectionChipBar chip. One
// button semantics node labelled "custom.selection_chip_bar.remove"; the
// same text is shown as a Tooltip (needs an Overlay ancestor).

part of "../index.dart";

/// Close icon size.
const double _removeIconSize = 16;

final class _RemoveButton extends StatelessWidget {
  /// Visible label of the chip, substituted for `{label}`.
  final String label;

  final Color color;

  /// Null disables the button.
  final VoidCallback? onPressed;

  const _RemoveButton({required this.label, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final String message = "custom.selection_chip_bar.remove".tr(
      namedArgs: <String, String>{"label": label},
    );

    // The tooltip text is the semantics label; it is not announced twice.
    return Semantics(
      container: true,
      button: true,
      enabled: onPressed != null,
      label: message,
      child: Tooltip(
        message: message,
        excludeFromSemantics: true,
        child: InkResponse(
          onTap: onPressed,
          radius: kMinTapTarget / 2,
          child: SizedBox.square(
            dimension: kMinTapTarget,
            child: Icon(Icons.close, size: _removeIconSize, color: color),
          ),
        ),
      ),
    );
  }
}

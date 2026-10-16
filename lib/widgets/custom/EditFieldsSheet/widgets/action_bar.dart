// action_bar.dart
//
// _ActionBar — cancel (outlined) and save (filled) buttons of
// EditFieldsSheet, equal widths, 48 dp tall with radius 10. A null callback
// disables its button; while busy the save button shows a Loader.

part of "../index.dart";

/// Button corner radius.
const double _buttonRadius = 10;

/// Diameter of the Loader inside the save button.
const double _loaderSize = 18;

final class _ActionBar extends StatelessWidget {
  final String cancelLabel;
  final String submitLabel;
  final bool busy;
  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;

  const _ActionBar({
    required this.cancelLabel,
    required this.submitLabel,
    required this.busy,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    const OutlinedBorder shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(_buttonRadius)),
    );
    const Size minimumSize = Size.fromHeight(kMinTapTarget);
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(minimumSize: minimumSize, shape: shape),
            child: Text(cancelLabel),
          ),
        ),
        const SizedBox(width: kDefaultPadding * 1.5),
        Expanded(
          child: FilledButton(
            onPressed: onSubmit,
            style: FilledButton.styleFrom(minimumSize: minimumSize, shape: shape),
            child: busy ? const Loader(size: _loaderSize) : Text(submitLabel),
          ),
        ),
      ],
    );
  }
}

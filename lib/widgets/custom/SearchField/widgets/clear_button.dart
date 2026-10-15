// clear_button.dart
//
// _ClearButton — the trailing × of SearchField: a kMinTapTarget square with a
// circular ink response, announced as a button labelled
// custom.search_field.clear. A transparent Material makes the ink visible
// above the field's filled background.

part of "../index.dart";

final class _ClearButton extends StatelessWidget {
  /// Called on tap; the host clears the controller.
  final VoidCallback onTap;

  const _ClearButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      button: true,
      label: "custom.search_field.clear".tr(),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: kMinTapTarget,
            child: Icon(Icons.close_rounded, size: 16, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

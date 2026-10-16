// submit_button.dart
//
// _SubmitButton — full-width 52 dp filled submit button of PolygonFormSheet
// (radius 12, 16 / w600). A null onPressed disables it; while busy it shows
// a Loader instead of the label, and the label stays the button's accessible
// name.

part of "../index.dart";

/// Submit button height.
const double _kSubmitHeight = 52;

/// Button corner radius.
const double _kSubmitRadius = 12;

/// Diameter of the Loader inside the button.
const double _kSubmitLoaderSize = 20;

final class _SubmitButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  const _SubmitButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(_kSubmitHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kSubmitRadius),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      child: busy
          ? Semantics(
              label: label,
              child: const ExcludeSemantics(
                child: Loader(size: _kSubmitLoaderSize),
              ),
            )
          : Text(label),
    );
  }
}

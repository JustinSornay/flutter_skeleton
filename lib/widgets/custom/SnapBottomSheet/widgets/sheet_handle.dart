// sheet_handle.dart
//
// _SheetHandle — the top handle of SnapBottomSheet: a full-width,
// kMinTapTarget-tall InkWell (focusable, activated by tap, Enter or Space)
// holding a 40 × 4 pill (cs.onSurfaceVariant at 40 %). It is announced as a
// button labelled custom.snap_bottom_sheet.handle, with an expand hint
// (collapse at full height) that follows the controller.

part of "../index.dart";

const double _kPillWidth = 40;
const double _kPillHeight = 4;

final class _SheetHandle extends StatelessWidget {
  /// Read for the tap hint only.
  final SnapBottomSheetController controller;

  /// Cycles the height.
  final VoidCallback onTap;

  const _SheetHandle({required this.controller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (BuildContext context, Widget? child) {
        final String hint = controller.snap == SheetSnap.full
            ? "custom.snap_bottom_sheet.collapse"
            : "custom.snap_bottom_sheet.expand";
        return Semantics(
          container: true,
          button: true,
          label: "custom.snap_bottom_sheet.handle".tr(),
          onTapHint: hint.tr(),
          child: child,
        );
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: _kSheetRadius,
        child: SizedBox(
          width: double.infinity,
          height: kMinTapTarget,
          child: Center(
            child: SizedBox(
              width: _kPillWidth,
              height: _kPillHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(_kPillHeight / 2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// progress_line.dart
//
// _ProgressLine — the 2 dp activity line of PolygonWizardSheet (suggestions
// loading, a pick resolving), labelled "custom.polygon_wizard_sheet.loading".
// Indeterminate LinearProgressIndicator normally; a static cs.primary line
// under reduced motion, so nothing repeats.

part of "../index.dart";

/// Thickness of the line.
const double _kProgressHeight = 2;

final class _ProgressLine extends StatelessWidget {
  final Color? backgroundColor;

  const _ProgressLine({this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final String label = "custom.polygon_wizard_sheet.loading".tr();
    if (!MediaQuery.disableAnimationsOf(context)) {
      return LinearProgressIndicator(
        minHeight: _kProgressHeight,
        backgroundColor: backgroundColor,
        semanticsLabel: label,
      );
    }
    return Semantics(
      label: label,
      child: SizedBox(
        height: _kProgressHeight,
        child: ColoredBox(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

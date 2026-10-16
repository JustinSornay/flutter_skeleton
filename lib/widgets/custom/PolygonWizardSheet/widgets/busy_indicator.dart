// busy_indicator.dart
//
// _BusyIndicator — the activity indicator of PolygonWizardSheet (a
// single-mode pick resolving, the submit button while onSubmit runs): the
// shared Loader normally; under reduced motion a static cs.primary
// hourglass labelled "custom.polygon_wizard_sheet.loading", so nothing
// repeats.

part of "../index.dart";

final class _BusyIndicator extends StatelessWidget {
  final double size;

  const _BusyIndicator({this.size = 32});

  @override
  Widget build(BuildContext context) {
    if (!MediaQuery.disableAnimationsOf(context)) return Loader(size: size);
    return Icon(
      Icons.hourglass_empty_rounded,
      size: size,
      color: Theme.of(context).colorScheme.primary,
      semanticLabel: "custom.polygon_wizard_sheet.loading".tr(),
    );
  }
}

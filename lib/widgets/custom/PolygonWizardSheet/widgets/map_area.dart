// map_area.dart
//
// _MapArea — the drawing map of PolygonWizardSheet: a MapPolygonEditor
// clipped to radius 12 with a live vertex counter (PillBadge, dense) in the
// bottom-end corner: cs.inverseSurface below a valid shape, cs.primary plus
// a check icon once the shape is valid. The counter lets taps through.
// Vertical drags that start on the map never reach the hosting sheet. While
// the sheet is locked the editor ignores every pointer.

part of "../index.dart";

/// Map corner radius.
const double _kMapRadius = 12;

final class _MapArea extends StatelessWidget {
  final MapPolygonEditorController controller;
  final bool shapeValid;
  final bool locked;
  final TileLayer tileLayer;
  final LatLng initialCenter;
  final double initialZoom;
  final Widget? attribution;

  const _MapArea({
    required this.controller,
    required this.shapeValid,
    required this.locked,
    required this.tileLayer,
    required this.initialCenter,
    required this.initialZoom,
    required this.attribution,
  });

  /// Claims vertical drags that start on the map. A vertex drag switches the
  /// map's own drag recognizers off, so without this a modal sheet's
  /// drag-to-dismiss would win the drag. Map pans are unaffected: the map's
  /// recognizers sit deeper and accept first.
  static void _absorbVerticalDrag(DragUpdateDetails details) {}

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      excludeFromSemantics: true,
      onVerticalDragUpdate: _absorbVerticalDrag,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kMapRadius),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: IgnorePointer(
                ignoring: locked,
                child: MapPolygonEditor(
                  controller: controller,
                  tileLayer: tileLayer,
                  initialCenter: initialCenter,
                  initialZoom: initialZoom,
                  minZoom: _kMinZoom,
                  maxZoom: _kMaxZoom,
                  attribution: attribution,
                ),
              ),
            ),
            PositionedDirectional(
              end: kDefaultPadding,
              bottom: kDefaultPadding,
              child: IgnorePointer(child: _counter(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _counter(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      container: true,
      child: PillBadge(
        dense: true,
        label: "custom.polygon_wizard_sheet.points_placed".tr(
          namedArgs: <String, String>{"count": "${controller.length}"},
        ),
        icon: shapeValid ? Icons.check_rounded : null,
        color: shapeValid ? cs.onPrimary : cs.onInverseSurface,
        backgroundColor: shapeValid ? cs.primary : cs.inverseSurface,
      ),
    );
  }
}

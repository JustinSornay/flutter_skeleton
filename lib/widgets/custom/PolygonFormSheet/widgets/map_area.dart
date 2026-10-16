// map_area.dart
//
// _MapArea — the 280 dp drawing map of PolygonFormSheet: a MapPolygonEditor
// clipped to radius 12, with a hint pill (cs.inverseSurface) while the
// polygon is empty and a point counter afterwards (cs.primary plus a check
// icon once the shape is valid). Both overlays let taps through to the map.
// Vertical drags that start on the map never reach the scrolling form.

part of "../index.dart";

/// Map height.
const double _kMapHeight = 280;

/// Map corner radius.
const double _kMapRadius = 12;

/// Counter corner radius.
const double _kCounterRadius = 8;

final class _MapArea extends StatelessWidget {
  final MapPolygonEditorController controller;
  final bool shapeValid;
  final TileLayer tileLayer;
  final LatLng initialCenter;
  final double initialZoom;
  final Widget? attribution;

  const _MapArea({
    required this.controller,
    required this.shapeValid,
    required this.tileLayer,
    required this.initialCenter,
    required this.initialZoom,
    required this.attribution,
  });

  /// Claims vertical drags that start on the map. A vertex drag switches the
  /// map's own drag recognizers off, so without this the enclosing list (or
  /// sheet) would win the drag and scroll the map away from the finger. Map
  /// pans are unaffected: the map's recognizers sit deeper and accept first.
  static void _absorbVerticalDrag(DragUpdateDetails details) {}

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      excludeFromSemantics: true,
      onVerticalDragUpdate: _absorbVerticalDrag,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kMapRadius),
        child: SizedBox(height: _kMapHeight, child: _layers(context)),
      ),
    );
  }

  Widget _layers(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
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
        if (controller.isEmpty)
          Positioned(
            top: kDefaultPadding,
            left: kDefaultPadding,
            right: kDefaultPadding,
            child: IgnorePointer(child: Center(child: _hint(context))),
          )
        else
          Positioned(
            left: kDefaultPadding,
            right: kDefaultPadding,
            bottom: kDefaultPadding,
            child: IgnorePointer(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _counter(context),
              ),
            ),
          ),
      ],
    );
  }

  Widget _hint(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.inverseSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding * 2,
          vertical: kDefaultPadding,
        ),
        child: Text(
          "custom.polygon_form_sheet.draw_hint".tr(),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: cs.onInverseSurface,
          ),
        ),
      ),
    );
  }

  Widget _counter(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Color foreground = shapeValid ? cs.onPrimary : cs.onInverseSurface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: shapeValid ? cs.primary : cs.inverseSurface,
        borderRadius: BorderRadius.circular(_kCounterRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding,
          vertical: kDefaultPadding / 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (shapeValid) ...<Widget>[
              Icon(Icons.check_rounded, size: 14, color: foreground),
              const SizedBox(width: kDefaultPadding / 2),
            ],
            Flexible(
              child: Text(
                "custom.polygon_form_sheet.point_count".tr(
                  namedArgs: <String, String>{"count": "${controller.length}"},
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

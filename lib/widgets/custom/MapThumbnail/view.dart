// view.dart
//
// Tree of MapThumbnail: one image semantics node over a pointer-absorbing,
// rounded box stacking a gesture-free FlutterMap (host TileLayer) and the
// centred pin (MapPin by default), tip on the centre. Colours come from the
// ColorScheme only.

part of "index.dart";

/// Coordinates in the default label: at most 4 decimals (about 11 m),
/// trailing zeros dropped.
const String _kCoordinatePattern = "0.####";

/// Moves the centred pin up by half its height, so its bottom centre (the
/// tip) sits on the viewport centre.
const Offset _kPinAnchorShift = Offset(0, -0.5);

mixin _ViewMixin {
  Widget render(BuildContext context, MapThumbnail widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      image: true,
      label: widget.semanticLabel ?? _defaultLabel(context, widget),
      child: ExcludeSemantics(
        child: AbsorbPointer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _map(cs, widget),
                  Center(
                    child: FractionalTranslation(
                      translation: _kPinAnchorShift,
                      child: widget.pin ?? const MapPin(size: MapThumbnail.defaultPinSize),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The camera is only read on first build, so the key recreates the map
  /// when the centre or zoom changes. The old map then disposes the
  /// TileProvider of the TileLayer it last received, hence the "one
  /// TileLayer per build" rule in the class dartdoc.
  Widget _map(ColorScheme cs, MapThumbnail widget) {
    return FlutterMap(
      key: ValueKey<(double, double, double)>((widget.lat, widget.lon, widget.zoom)),
      options: MapOptions(
        initialCenter: LatLng(widget.lat, widget.lon),
        initialZoom: widget.zoom,
        backgroundColor: widget.backgroundColor ?? cs.surfaceContainerHighest,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
      ),
      children: <Widget>[widget.tileLayer],
    );
  }

  String _defaultLabel(BuildContext context, MapThumbnail widget) {
    final String? locale = numberLocaleOf(context);
    final NumberFormat format = NumberFormat(_kCoordinatePattern, locale);
    return "custom.map_thumbnail.semantics".tr(
      namedArgs: <String, String>{
        "lat": format.format(widget.lat),
        "lon": format.format(widget.lon),
      },
    );
  }
}

// index.dart
//
// MapThumbnail — a small, gesture-free map preview for list rows, cards and
// headers: host tiles centred on a coordinate at a fixed zoom, inside a
// rounded box, with a MapPin (lib/widgets/custom/MapPin) whose tip marks the
// coordinate. Stateless; the tree lives in view.dart.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_skeleton/utils/formatters/intl_locale.dart";
import "package:flutter_skeleton/widgets/custom/MapPin/index.dart";
import "package:latlong2/latlong.dart";

part "view.dart";

/// Static map preview centred on ([lat], [lon]).
///
/// - Tiles come from [tileLayer]: the host owns the tile URL, the user agent
///   the tile policy requires, caching and the optional `errorTileCallback`
///   (a failed tile throws nothing and leaves [backgroundColor] visible).
///   Tests pass a `TileLayer` with an in-memory `TileProvider`.
/// - Build [tileLayer] in the host's `build` (a new instance per build is
///   fine) and never share one instance between thumbnails or keep it in a
///   field: flutter_map disposes a layer's `TileProvider` when its map
///   unmounts, which happens when the thumbnail leaves the tree and when
///   [lat], [lon] or [zoom] change. To share an HTTP client, hand it to each
///   provider (`NetworkTileProvider(httpClient: client)` leaves it open).
/// - The camera is fixed at [zoom]; every map gesture is off and the preview
///   absorbs pointers before they reach the map, so a host `InkWell` /
///   `GestureDetector` around it receives taps and a scrolling parent keeps
///   scrolling. Changing [lat], [lon] or [zoom] recentres the camera (the map
///   is remounted).
/// - The pin sits at the viewport centre (not geo-projected, which is exact
///   because the camera is centred on the coordinate). Its box is anchored by
///   its bottom centre, so the tip of the default [MapPin] (sized
///   [defaultPinSize]) touches the coordinate. [pin] replaces it and is
///   anchored the same way; `const SizedBox.shrink()` hides it. Because the
///   tip is on the centre, the whole pin sits in the upper half of the box:
///   keep [height] a few dp above twice the pin height (2 × 17 = 34 dp for
///   the default pin), or the box clips the top of the head and its outline.
///
/// Accessibility: a single image semantics node labelled [semanticLabel],
/// else `"custom.map_thumbnail.semantics".tr()` with the coordinates as
/// `lat` / `lon` named args (up to 4 decimals, ambient locale). The map
/// internals and the pin are excluded from the semantics tree. The preview
/// is not interactive, so the 48 dp tap-target rule applies to the host's
/// tappable wrapper, not to this widget.
///
/// Uses no Tooltip or other overlay: it needs no `Overlay` ancestor.
final class MapThumbnail extends StatelessWidget with _ViewMixin {
  /// Size of the default [MapPin] (head Ø 12 dp, 17 dp tall): with the tip
  /// on the centre of the 40 dp default box, the head keeps a 3 dp margin
  /// from the top edge.
  static const Size defaultPinSize = Size(12, 17);

  /// Latitude of the centre (WGS84, degrees).
  final double lat;

  /// Longitude of the centre (WGS84, degrees).
  final double lon;

  /// Base map tiles (the only map layer). One instance per thumbnail, built
  /// by the host on each build (see the class dartdoc).
  final TileLayer tileLayer;

  /// Box width. Defaults to 48.
  final double width;

  /// Box height. Defaults to 40.
  final double height;

  /// Corner radius of the box. Defaults to 6.
  final double borderRadius;

  /// Map zoom level. Defaults to 11 (neighbourhood scale).
  final double zoom;

  /// Shown under the tiles while they load or after one fails. Defaults to
  /// `cs.surfaceContainerHighest`.
  final Color? backgroundColor;

  /// Replaces the default [MapPin]; anchored by its bottom centre on the
  /// coordinate.
  final Widget? pin;

  /// Screen-reader label, already localised by the host. Defaults to
  /// `"custom.map_thumbnail.semantics".tr()` with `lat` / `lon` named args.
  final String? semanticLabel;

  /// Compact preview (48 × 40, radius 6) for list rows.
  const MapThumbnail({
    super.key,
    required this.lat,
    required this.lon,
    required this.tileLayer,
    this.width = 48,
    this.height = 40,
    this.borderRadius = 6,
    this.zoom = 11,
    this.backgroundColor,
    this.pin,
    this.semanticLabel,
  });

  /// Larger square preview (56 × 56, radius 8) for cards.
  const MapThumbnail.large({
    super.key,
    required this.lat,
    required this.lon,
    required this.tileLayer,
    this.zoom = 11,
    this.backgroundColor,
    this.pin,
    this.semanticLabel,
  }) : width = 56,
       height = 56,
       borderRadius = 8;

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

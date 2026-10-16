// geojson.dart
//
// GeoJSON (RFC 7946) polygon codec over latlong2 LatLng: encodes a ring as a
// Polygon geometry map for a request body, and decodes the outer ring(s) of a
// Polygon, MultiPolygon, Feature or FeatureCollection read from a response or
// a user file. GeoJSON positions are [lon, lat] while LatLng is (lat, lon):
// the flip happens here and nowhere else.
//
// Decoded rings are open (first vertex not repeated), the shape that
// flutter_map `Polygon(points:)`, polygon_area.dart and polygon_shape.dart
// take as is.

import "package:latlong2/latlong.dart";

/// Encodes [ring] as a GeoJSON Polygon geometry:
/// `{"type": "Polygon", "coordinates": [[[lon, lat], ...]]}`.
///
/// The ring is closed exactly once: the first vertex is repeated at the end,
/// after dropping any trailing copies of it (exact equality) the caller
/// already added. The vertex order (winding) is kept as given; [ring] is not
/// modified.
///
/// Throws [ArgumentError] when [ring] has fewer than 3 vertices, closing
/// copies not counted (no GeoJSON Polygon can hold it), or a vertex outside
/// longitude [-180, 180] / latitude [-90, 90], NaN and infinity included
/// (normalise wrapped map longitudes first). Every ring it accepts comes
/// back from [geoJsonOuterRings].
Map<String, Object> polygonToGeoJson(List<LatLng> ring) {
  final List<LatLng> open = _openRing(ring);
  if (open.length < 3) {
    throw ArgumentError.value(ring, "ring", "a polygon needs at least 3 vertices (closing vertex not counted)");
  }
  for (final LatLng point in open) {
    if (!_inRange(point.longitude, point.latitude)) {
      throw ArgumentError.value(ring, "ring", "vertex $point is outside longitude [-180, 180] / latitude [-90, 90]");
    }
  }

  final List<List<double>> positions = <List<double>>[
    for (final LatLng point in open) <double>[point.longitude, point.latitude],
    <double>[open.first.longitude, open.first.latitude],
  ];
  return <String, Object>{
    "type": "Polygon",
    "coordinates": <List<List<double>>>[positions],
  };
}

/// Outer rings of the polygons in [geoJson], a decoded GeoJSON value (what
/// `jsonDecode` returns, or an equivalent map built in Dart).
///
/// Accepts a Polygon or MultiPolygon geometry, a Feature carrying one, or a
/// FeatureCollection of such Features (other geometries are skipped). Returns
/// one ring per polygon in document order; holes (interior rings) are
/// ignored. Each ring is open: trailing vertices equal to the first are
/// dropped. Numbers may be int or double; an altitude is ignored.
///
/// Tolerant, never throws: null, a non-map value, an unknown or missing
/// `type` and malformed members give no ring. A polygon is dropped (the
/// others are kept) when its outer ring has fewer than 3 vertices or a
/// position that is not a pair of numbers with longitude in [-180, 180] and
/// latitude in [-90, 90] (NaN, infinity, a projected CRS in metres).
List<List<LatLng>> geoJsonOuterRings(Object? geoJson) {
  return switch (geoJson) {
    <Object?, Object?>{"type": "FeatureCollection", "features": final List<Object?> features} => <List<LatLng>>[
      for (final Object? feature in features) ..._featureRings(feature),
    ],
    <Object?, Object?>{"type": "Feature"} => _featureRings(geoJson),
    _ => _geometryRings(geoJson),
  };
}

/// Rings of a Feature's geometry; none for anything else.
List<List<LatLng>> _featureRings(Object? feature) {
  return switch (feature) {
    <Object?, Object?>{"type": "Feature", "geometry": final Object? geometry} => _geometryRings(geometry),
    _ => <List<LatLng>>[],
  };
}

/// Rings of a Polygon or MultiPolygon geometry; none for anything else.
List<List<LatLng>> _geometryRings(Object? geometry) {
  final List<Object?> polygons = switch (geometry) {
    <Object?, Object?>{"type": "Polygon", "coordinates": final List<Object?> rings} => <Object?>[rings],
    <Object?, Object?>{"type": "MultiPolygon", "coordinates": final List<Object?> members} => members,
    _ => const <Object?>[],
  };
  return <List<LatLng>>[
    for (final Object? polygon in polygons)
      if (_outerRing(polygon) case final List<LatLng> ring) ring,
  ];
}

/// The open outer ring of one polygon's coordinates (a list of rings), or
/// null when it is malformed or has fewer than 3 vertices.
List<LatLng>? _outerRing(Object? polygon) {
  if (polygon case <Object?>[final List<Object?> outer, ...]) {
    final List<LatLng> points = <LatLng>[];
    for (final Object? position in outer) {
      final LatLng? point = _position(position);
      if (point == null) return null;
      points.add(point);
    }
    final List<LatLng> open = _openRing(points);
    return open.length < 3 ? null : open;
  }
  return null;
}

/// A `[lon, lat, ...]` position as a LatLng, or null when malformed or out
/// of range (the range test also rejects NaN and infinity).
LatLng? _position(Object? position) {
  if (position case <Object?>[final num lon, final num lat, ...] when _inRange(lon, lat)) {
    return LatLng(lat.toDouble(), lon.toDouble());
  }
  return null;
}

/// Whether a position lies in the WGS 84 range; false for NaN and infinity.
bool _inRange(num lon, num lat) => lon.abs() <= 180 && lat.abs() <= 90;

/// [ring] without the trailing vertices that repeat its first one.
List<LatLng> _openRing(List<LatLng> ring) {
  int end = ring.length;
  while (end > 1 && ring[end - 1] == ring.first) {
    end--;
  }
  return end == ring.length ? ring : ring.sublist(0, end);
}

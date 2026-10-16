// polygon_area.dart
//
// Geodesic polygon area on the WGS84 sphere, in hectares. Spherical-excess
// formula: within ~0.3 % of PostGIS `ST_Area(geography)`, so a client-side
// area matches a server-side total. Never approximate an area with a lat/lon
// bounding box — that over-estimates any non-rectangular or diagonal shape.

import "dart:math" as math;

import "package:latlong2/latlong.dart";

/// WGS84 equatorial radius in metres (the radius PostGIS `geography` uses).
const double _earthRadiusMeters = 6378137.0;

/// Returns the geodesic area, in hectares, of the polygon ring [ring].
///
/// The ring need not repeat its first vertex at the end: the edge from the
/// last vertex back to the first is always included. Returns 0 for fewer
/// than 3 vertices. Longitude deltas are normalised to (-180°, 180°], so a
/// polygon crossing the antimeridian is measured correctly.
double geodesicAreaHectares(List<LatLng> ring) {
  if (ring.length < 3) return 0;

  double total = 0;
  for (int i = 0; i < ring.length; i++) {
    final LatLng a = ring[i];
    final LatLng b = ring[(i + 1) % ring.length];
    final double lat1 = a.latitude * math.pi / 180;
    final double lat2 = b.latitude * math.pi / 180;
    final double dLon = _normalizedDeltaDegrees(b.longitude - a.longitude) * math.pi / 180;
    total += dLon * (2 + math.sin(lat1) + math.sin(lat2));
  }

  final double areaSquareMeters = (total * _earthRadiusMeters * _earthRadiusMeters / 2).abs();
  return areaSquareMeters / 10000.0;
}

/// [degrees] brought into (-180, 180].
double _normalizedDeltaDegrees(double degrees) {
  double value = degrees;
  while (value > 180) {
    value -= 360;
  }
  while (value <= -180) {
    value += 360;
  }
  return value;
}

// polygon_shape.dart
//
// Planar shape check of a polygon ring: whether two of its edges cross or
// touch exactly (a bow-tie, a figure eight, a vertex dropped on another
// edge, a vertex visited twice; no tolerance). Used by PolygonFormSheet and
// PolygonWizardSheet to gate their submit on every vertex change. The area
// lives next door in polygon_area.dart.

import "dart:math" as math;

import "package:latlong2/latlong.dart";

/// Whether two non-adjacent edges of the closed polygon through [ring] (last
/// vertex joined back to the first) cross or touch.
///
/// Planar coordinates: longitude as x, latitude as y, as the vertices
/// describe the shape (no antimeridian handling). Touching is exact, with no
/// tolerance: a vertex a floating-point hair off a non-adjacent edge neither
/// crosses nor touches it. Adjacent edges sharing a vertex are never
/// compared, so a vertex inserted on a straight edge is fine; any vertex
/// visited twice touches, so do not repeat the first vertex at the end.
/// Fewer than 4 vertices have no non-adjacent edges and return false.
bool hasCrossingEdges(List<LatLng> ring) {
  final int count = ring.length;
  for (int i = 0; i < count; i++) {
    // Edge i + 1 shares a vertex with edge i; so does the closing edge
    // (count - 1) with edge 0.
    for (int j = i + 2; j < count; j++) {
      if (i == 0 && j == count - 1) continue;
      if (_segmentsTouch(
        ring[i],
        ring[i + 1],
        ring[j],
        ring[(j + 1) % count],
      )) {
        return true;
      }
    }
  }
  return false;
}

/// Whether the segments [a]–[b] and [c]–[d] cross or share a point.
bool _segmentsTouch(LatLng a, LatLng b, LatLng c, LatLng d) {
  final bool crossing =
      _side(c, d, a).sign * _side(c, d, b).sign < 0 &&
      _side(a, b, c).sign * _side(a, b, d).sign < 0;
  return crossing ||
      _liesOn(a, c, d) ||
      _liesOn(b, c, d) ||
      _liesOn(c, a, b) ||
      _liesOn(d, a, b);
}

/// Cross product of [b] − [a] and [p] − [a]: positive when [p] is left of the
/// line [a] → [b], negative when right, zero when on it.
double _side(LatLng a, LatLng b, LatLng p) {
  return (b.longitude - a.longitude) * (p.latitude - a.latitude) -
      (b.latitude - a.latitude) * (p.longitude - a.longitude);
}

/// Whether [p] lies on the segment [a]–[b].
bool _liesOn(LatLng p, LatLng a, LatLng b) {
  return _side(a, b, p) == 0 &&
      p.longitude >= math.min(a.longitude, b.longitude) &&
      p.longitude <= math.max(a.longitude, b.longitude) &&
      p.latitude >= math.min(a.latitude, b.latitude) &&
      p.latitude <= math.max(a.latitude, b.latitude);
}

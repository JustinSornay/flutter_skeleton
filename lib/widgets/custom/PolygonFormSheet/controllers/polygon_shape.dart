// polygon_shape.dart
//
// PolygonFormShape — pure shape check of PolygonFormSheet: whether two edges
// of the closed polygon cross or touch (a bow-tie, a figure eight, a vertex
// dropped on another edge). The view model runs it on every vertex change to
// gate the submit button and show the crossing hint. No widgets, so it is
// unit-tested on its own.

part of "../index.dart";

/// Shape checks on polygon vertices, in planar coordinates (longitude as x,
/// latitude as y), as the submitted points describe the shape.
@visibleForTesting
abstract final class PolygonFormShape {
  /// Whether two non-adjacent edges of the closed polygon through [points]
  /// (last vertex joined back to the first) cross or touch.
  ///
  /// Fewer than 4 points have no non-adjacent edges and return false.
  static bool hasCrossingEdges(List<LatLng> points) {
    final int count = points.length;
    for (int i = 0; i < count; i++) {
      // Edge j = i + 1 shares a vertex with edge i; so does the closing edge
      // (count - 1) with edge 0.
      for (int j = i + 2; j < count; j++) {
        if (i == 0 && j == count - 1) continue;
        if (_segmentsTouch(
          points[i],
          points[i + 1],
          points[j],
          points[(j + 1) % count],
        )) {
          return true;
        }
      }
    }
    return false;
  }

  /// Whether the segments [a]–[b] and [c]–[d] cross or share a point.
  static bool _segmentsTouch(LatLng a, LatLng b, LatLng c, LatLng d) {
    final bool crossing =
        _side(c, d, a).sign * _side(c, d, b).sign < 0 &&
        _side(a, b, c).sign * _side(a, b, d).sign < 0;
    return crossing ||
        _liesOn(a, c, d) ||
        _liesOn(b, c, d) ||
        _liesOn(c, a, b) ||
        _liesOn(d, a, b);
  }

  /// Cross product of [b] − [a] and [p] − [a]: positive when [p] is left of
  /// the line [a] → [b], negative when right, zero when on it.
  static double _side(LatLng a, LatLng b, LatLng p) {
    return (b.longitude - a.longitude) * (p.latitude - a.latitude) -
        (b.latitude - a.latitude) * (p.longitude - a.longitude);
  }

  /// Whether [p] lies on the segment [a]–[b].
  static bool _liesOn(LatLng p, LatLng a, LatLng b) {
    return _side(a, b, p) == 0 &&
        p.longitude >= math.min(a.longitude, b.longitude) &&
        p.longitude <= math.max(a.longitude, b.longitude) &&
        p.latitude >= math.min(a.latitude, b.latitude) &&
        p.latitude <= math.max(a.latitude, b.latitude);
  }
}

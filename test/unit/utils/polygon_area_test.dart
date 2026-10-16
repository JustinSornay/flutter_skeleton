// polygon_area_test.dart
//
// Unit tests for geodesicAreaHectares: degenerate rings, a 1 km square,
// a reference polygon checked against PostGIS, open vs closed rings, the
// antimeridian and vertex order.

import "dart:math" as math;

import "package:flutter_skeleton/utils/geo/polygon_area.dart";
import "package:flutter_test/flutter_test.dart";
import "package:latlong2/latlong.dart";

void main() {
  test("returns 0 for degenerate rings (< 3 vertices)", () {
    expect(geodesicAreaHectares(<LatLng>[]), 0);
    expect(geodesicAreaHectares(<LatLng>[const LatLng(47.0, 5.0), const LatLng(47.0, 5.01)]), 0);
  });

  test("a 1 km square near 47°N measures ~100 ha (±1 %)", () {
    const double lat0 = 47.0;
    const double lon0 = 5.0;
    const double dLat = 1000 / 111320.0;
    const double dLon = 1000 / (111320.0 * 0.6819983601); // cos(47°)

    final double ha = geodesicAreaHectares(<LatLng>[
      const LatLng(lat0, lon0),
      const LatLng(lat0, lon0 + dLon),
      const LatLng(lat0 + dLat, lon0 + dLon),
      const LatLng(lat0 + dLat, lon0),
    ]);

    expect(ha, closeTo(100, 1.0));
  });

  test("matches PostGIS ST_Area(geography) on a large reference polygon (±0.5 %)", () {
    // PostGIS sphere area of this rectangle: 41,359,460.9 ha.
    final double ha = geodesicAreaHectares(<LatLng>[
      const LatLng(49.69857995458366, -2.796140669098362),
      const LatLng(49.69857995458366, 6.712512042755883),
      const LatLng(44.5230626531739, 6.712512042755883),
      const LatLng(44.5230626531739, -2.796140669098362),
      const LatLng(49.69857995458366, -2.796140669098362),
    ]);

    expect(ha, closeTo(41359460.9, 41359460.9 * 0.005));
  });

  test("a closed ring (first == last vertex) equals the open ring", () {
    const List<LatLng> open = <LatLng>[LatLng(47.0, 5.0), LatLng(47.0, 5.01), LatLng(47.01, 5.01)];
    final List<LatLng> closed = <LatLng>[...open, const LatLng(47.0, 5.0)];

    expect(geodesicAreaHectares(closed), closeTo(geodesicAreaHectares(open), 1e-6));
  });

  test("measures a polygon crossing the antimeridian like its mirror", () {
    const List<LatLng> crossing = <LatLng>[
      LatLng(-17.0, 179.99),
      LatLng(-17.0, -179.99),
      LatLng(-16.99, -179.99),
      LatLng(-16.99, 179.99),
    ];
    const List<LatLng> mirror = <LatLng>[
      LatLng(-17.0, -0.01),
      LatLng(-17.0, 0.01),
      LatLng(-16.99, 0.01),
      LatLng(-16.99, -0.01),
    ];

    final double ha = geodesicAreaHectares(crossing);
    expect(ha, lessThan(1000));
    expect(ha, closeTo(geodesicAreaHectares(mirror), 1e-6));
  });

  test("does not depend on the winding order", () {
    const List<LatLng> ring = <LatLng>[LatLng(47.0, 5.0), LatLng(47.0, 5.01), LatLng(47.01, 5.01)];

    expect(geodesicAreaHectares(ring.reversed.toList()), closeTo(geodesicAreaHectares(ring), 1e-6));
  });

  test("a ring around a pole measures the polar cap, not the rest of the Earth", () {
    final List<LatLng> ring = <LatLng>[for (int lon = -180; lon < 180; lon += 5) LatLng(80, lon.toDouble())];
    // Spherical cap above 80°N: 2πR²(1 − sin 80°).
    const double r = 6378137.0;
    final double capHectares = 2 * math.pi * r * r * (1 - math.sin(80 * math.pi / 180)) / 10000;

    expect(geodesicAreaHectares(ring), closeTo(capHectares, capHectares * 0.01));
    expect(geodesicAreaHectares(ring.reversed.toList()), closeTo(capHectares, capHectares * 0.01));
  });
}

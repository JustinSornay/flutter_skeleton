// compass_point_test.dart
//
// Unit tests for CompassPoint (utils/geo/compass_point.dart): the stable
// names, centre bearings, every sector boundary, normalisation of negative
// and >= 360° bearings, exactness one ulp below each boundary, non-finite
// input, and between() on great-circle bearings and identical points.

import "dart:typed_data";

import "package:flutter_skeleton/utils/geo/compass_point.dart";
import "package:flutter_test/flutter_test.dart";
import "package:latlong2/latlong.dart";

/// Small enough to stay inside a sector, large enough to survive the
/// normalisation of bearings around 360.
const double _epsilon = 1e-9;

void main() {
  group("CompassPoint.fromBearing: sectors", _sectorTests);
  group("CompassPoint.fromBearing: normalisation", _normalisationTests);
  group("CompassPoint.between", _betweenTests);
}

/// The largest double below [x] (finite, non-zero).
double _nextBelow(double x) {
  final ByteData bytes = ByteData(8)..setFloat64(0, x);
  final int bits = bytes.getInt64(0);
  // Positive doubles order like their bit patterns, negative ones in reverse.
  bytes.setInt64(0, x > 0 ? bits - 1 : bits + 1);
  return bytes.getFloat64(0);
}

void _expectBearings(List<(double, CompassPoint)> rows) {
  for (final (double degrees, CompassPoint expected) in rows) {
    expect(CompassPoint.fromBearing(degrees), expected, reason: "$degrees°");
  }
}

void _sectorTests() {
  test("declares the 8 points clockwise from north, with stable names", () {
    expect(CompassPoint.values.map((CompassPoint point) => point.name), <String>[
      "north",
      "northEast",
      "east",
      "southEast",
      "south",
      "southWest",
      "west",
      "northWest",
    ]);
  });

  test("maps each centre bearing (0°, 45°, … 315°) to its point", () {
    for (final CompassPoint point in CompassPoint.values) {
      expect(CompassPoint.fromBearing(point.index * 45.0), point, reason: "${point.index * 45}°");
    }
  });

  test("each sector is [centre - 22.5°, centre + 22.5°)", () {
    for (final CompassPoint point in CompassPoint.values) {
      final double centre = point.index * 45.0;
      final CompassPoint previous = CompassPoint.values[(point.index + 7) % 8];
      final CompassPoint next = CompassPoint.values[(point.index + 1) % 8];

      expect(CompassPoint.fromBearing(centre - 22.5), point, reason: "lower boundary of ${point.name}");
      expect(CompassPoint.fromBearing(centre - 22.5 - _epsilon), previous, reason: "below ${point.name}");
      expect(CompassPoint.fromBearing(centre + 22.5 - _epsilon), point, reason: "top of ${point.name}");
      expect(CompassPoint.fromBearing(centre + 22.5), next, reason: "upper boundary of ${point.name}");
    }
  });

  test("a boundary bearing belongs to the point clockwise of it", () {
    _expectBearings(<(double, CompassPoint)>[
      (22.5, CompassPoint.northEast),
      (67.5, CompassPoint.east),
      (112.5, CompassPoint.southEast),
      (157.5, CompassPoint.south),
      (202.5, CompassPoint.southWest),
      (247.5, CompassPoint.west),
      (292.5, CompassPoint.northWest),
      (337.5, CompassPoint.north),
    ]);
  });

  test("is exact one ulp below every boundary, in any turn", () {
    expect(_nextBelow(22.5), 22.499999999999996);
    for (final CompassPoint point in CompassPoint.values) {
      final CompassPoint previous = CompassPoint.values[(point.index + 7) % 8];
      for (final double turn in <double>[-720, -360, 0, 360, 720]) {
        final double boundary = point.index * 45.0 - 22.5 + turn;
        expect(CompassPoint.fromBearing(boundary), point, reason: "$boundary°");
        expect(CompassPoint.fromBearing(_nextBelow(boundary)), previous, reason: "${_nextBelow(boundary)}°");
      }
    }
  });

  test("north spans 0°", () {
    _expectBearings(<(double, CompassPoint)>[
      (337.4999, CompassPoint.northWest),
      (337.5, CompassPoint.north),
      (359.9999, CompassPoint.north),
      (0, CompassPoint.north),
      (-0.0, CompassPoint.north),
      (22.4999, CompassPoint.north),
      (22.5, CompassPoint.northEast),
    ]);
  });
}

void _normalisationTests() {
  test("normalises negative bearings (latlong2 returns (-180°, 180°])", () {
    _expectBearings(<(double, CompassPoint)>[
      (-1e-15, CompassPoint.north), // rounds to 360 when normalised
      (-22.5, CompassPoint.north),
      (-22.5 - _epsilon, CompassPoint.northWest),
      (-45, CompassPoint.northWest),
      (-67.5, CompassPoint.northWest),
      (-90, CompassPoint.west),
      (-112.5, CompassPoint.west),
      (-135, CompassPoint.southWest),
      (-157.5, CompassPoint.southWest),
      (-157.6, CompassPoint.south),
      (-179.999, CompassPoint.south),
      (-180, CompassPoint.south),
      (-360, CompassPoint.north),
      (-405, CompassPoint.northWest),
      (-3690, CompassPoint.west),
    ]);
  });

  test("normalises bearings of 360° and more", () {
    _expectBearings(<(double, CompassPoint)>[
      (360, CompassPoint.north),
      (382.4999, CompassPoint.north),
      (382.5, CompassPoint.northEast),
      (405, CompassPoint.northEast),
      (450, CompassPoint.east),
      (540, CompassPoint.south),
      (719.99, CompassPoint.north),
      (967.5, CompassPoint.west),
      (36135, CompassPoint.southEast),
    ]);
  });

  test("throws ArgumentError for NaN and infinities", () {
    for (final double degrees in <double>[double.nan, double.infinity, double.negativeInfinity]) {
      expect(() => CompassPoint.fromBearing(degrees), throwsArgumentError, reason: "$degrees");
    }
  });
}

void _betweenTests() {
  test("the 8 directions from the origin", () {
    const LatLng origin = LatLng(0, 0);
    for (final (LatLng to, CompassPoint expected) in <(LatLng, CompassPoint)>[
      (const LatLng(10, 0), CompassPoint.north),
      (const LatLng(10, 10), CompassPoint.northEast),
      (const LatLng(0, 10), CompassPoint.east),
      (const LatLng(-10, 10), CompassPoint.southEast),
      (const LatLng(-10, 0), CompassPoint.south),
      (const LatLng(-10, -10), CompassPoint.southWest),
      (const LatLng(0, -10), CompassPoint.west),
      (const LatLng(10, -10), CompassPoint.northWest),
    ]) {
      expect(CompassPoint.between(origin, to), expected, reason: "$to");
    }
  });

  test("identical points give north at every latitude", () {
    // latlong2 alone rounds some of these to 180° (e.g. 46.6°N, 51.5°N).
    for (final (double lat, double lon) in <(double, double)>[(46.6, 2.35), (51.5, -0.12), (48.85, 2.35)]) {
      expect(CompassPoint.between(LatLng(lat, lon), LatLng(lat, lon)), CompassPoint.north, reason: "($lat, $lon)");
    }
    for (int tenth = -900; tenth <= 900; tenth++) {
      for (final double lon in <double>[-180, -73.5, 0, 2.35, 139.7, 180]) {
        final LatLng point = LatLng(tenth / 10, lon);
        expect(CompassPoint.between(point, LatLng(tenth / 10, lon)), CompassPoint.north, reason: "$point");
      }
    }
  });

  test("takes the short way across the antimeridian", () {
    expect(CompassPoint.between(const LatLng(0, 179.5), const LatLng(0, -179.5)), CompassPoint.east);
    expect(CompassPoint.between(const LatLng(0, -179.5), const LatLng(0, 179.5)), CompassPoint.west);
  });

  test("buckets the initial great-circle bearing, not the map angle", () {
    // Along the 60°N parallel the target is due east on a Mercator map, but
    // the great circle sets off at ~49°.
    expect(CompassPoint.between(const LatLng(60, 0), const LatLng(60, 90)), CompassPoint.northEast);
  });
}

// geojson_test.dart
//
// Unit tests for polygonToGeoJson and geoJsonOuterRings (utils/geo/geojson.dart):
// [lon, lat] order, closing-vertex handling, Polygon / MultiPolygon / Feature /
// FeatureCollection decoding, malformed and out-of-range input on both sides,
// round trips.

import "dart:convert";

import "package:flutter_skeleton/utils/geo/geojson.dart";
import "package:flutter_test/flutter_test.dart";
import "package:latlong2/latlong.dart";

const LatLng _a = LatLng(47.0, 5.0);
const LatLng _b = LatLng(47.0, 5.01);
const LatLng _c = LatLng(47.01, 5.01);
const List<LatLng> _triangle = <LatLng>[_a, _b, _c];

/// [_triangle] as closed GeoJSON positions.
const List<List<double>> _trianglePositions = <List<double>>[
  <double>[5.0, 47.0],
  <double>[5.01, 47.0],
  <double>[5.01, 47.01],
  <double>[5.0, 47.0],
];

const List<LatLng> _square = <LatLng>[LatLng(50, 10), LatLng(50, 11), LatLng(51, 11), LatLng(51, 10)];

/// [_square] as closed GeoJSON positions, written with ints.
const List<List<int>> _squarePositions = <List<int>>[
  <int>[10, 50],
  <int>[11, 50],
  <int>[11, 51],
  <int>[10, 51],
  <int>[10, 50],
];

/// A hole inside [_triangle]'s bounding box.
const List<List<double>> _holePositions = <List<double>>[
  <double>[5.002, 47.002],
  <double>[5.004, 47.002],
  <double>[5.004, 47.004],
  <double>[5.002, 47.002],
];

Map<String, Object?> _polygon(List<Object?> rings) => <String, Object?>{"type": "Polygon", "coordinates": rings};

Map<String, Object?> _multiPolygon(List<Object?> polygons) =>
    <String, Object?>{"type": "MultiPolygon", "coordinates": polygons};

Map<String, Object?> _feature(Object? geometry) =>
    <String, Object?>{"type": "Feature", "properties": <String, Object?>{"name": "a"}, "geometry": geometry};

/// The single ring of an encoded Polygon.
List<Object?> _encodedRing(Map<String, Object> geometry) {
  return (geometry["coordinates"]! as List<Object?>).single! as List<Object?>;
}

void main() {
  group("polygonToGeoJson", _encodeTests);
  group("geoJsonOuterRings: Polygon", _decodePolygonTests);
  group("geoJsonOuterRings: MultiPolygon, Feature, FeatureCollection", _decodeContainerTests);
  group("geoJsonOuterRings: malformed geometries", _malformedGeometryTests);
  group("geoJsonOuterRings: malformed positions", _malformedPositionTests);
  group("round trips", _roundTripTests);
}

void _encodeTests() {
  test("writes a Polygon geometry in [lon, lat] order, closing the ring", () {
    expect(polygonToGeoJson(_triangle), <String, Object>{
      "type": "Polygon",
      "coordinates": <Object>[_trianglePositions],
    });
  });

  test("does not repeat the closing vertex of an already closed ring", () {
    final Map<String, Object> encoded = polygonToGeoJson(<LatLng>[..._triangle, _a]);

    expect(encoded, polygonToGeoJson(_triangle));
    expect(_encodedRing(encoded), hasLength(4));
  });

  test("drops every trailing copy of the first vertex before closing once", () {
    final Map<String, Object> encoded = polygonToGeoJson(<LatLng>[..._triangle, _a, _a, _a]);

    expect(encoded, polygonToGeoJson(_triangle));
  });

  test("closes a ring whose last vertex only nearly equals the first", () {
    const LatLng nearA = LatLng(47.0, 5.0000001);
    final List<Object?> ring = _encodedRing(polygonToGeoJson(<LatLng>[..._triangle, nearA]));

    expect(ring, hasLength(5));
    expect(ring.last, <double>[5.0, 47.0]);
  });

  test("keeps the vertex order (winding) and negative coordinates", () {
    const List<LatLng> ring = <LatLng>[LatLng(-17.0, 179.99), LatLng(-17.0, -179.99), LatLng(-16.99, -179.99)];

    expect(_encodedRing(polygonToGeoJson(ring.reversed.toList())), <List<double>>[
      <double>[-179.99, -16.99],
      <double>[-179.99, -17.0],
      <double>[179.99, -17.0],
      <double>[-179.99, -16.99],
    ]);
  });

  test("does not modify the input ring", () {
    final List<LatLng> closed = <LatLng>[..._triangle, _a];
    final List<LatLng> open = List<LatLng>.of(_triangle);
    polygonToGeoJson(closed);
    polygonToGeoJson(open);

    expect(closed, <LatLng>[..._triangle, _a]);
    expect(open, _triangle);
  });

  test("is JSON-encodable as is", () {
    expect(jsonDecode(jsonEncode(polygonToGeoJson(_triangle))), _polygon(<Object?>[_trianglePositions]));
  });

  test("throws ArgumentError below 3 vertices, closing vertex not counted", () {
    for (final List<LatLng> ring in <List<LatLng>>[
      <LatLng>[],
      <LatLng>[_a],
      <LatLng>[_a, _a],
      <LatLng>[_a, _b],
      <LatLng>[_a, _b, _a],
      <LatLng>[_a, _b, _a, _a],
      <LatLng>[_a, _a, _a],
    ]) {
      expect(() => polygonToGeoJson(ring), throwsArgumentError, reason: "$ring");
    }
  });

  test("accepts the range bounds", () {
    const List<LatLng> world = <LatLng>[LatLng(-90, -180), LatLng(-90, 180), LatLng(90, 180), LatLng(90, -180)];

    expect(_encodedRing(polygonToGeoJson(world)), hasLength(5));
  });

  test("throws ArgumentError for a vertex out of range or not finite", () {
    for (final LatLng bad in <LatLng>[
      const LatLng(47.0, 180.0001),
      const LatLng(47.0, -190), // a wrapped map longitude
      const LatLng(90.5, 5.0),
      const LatLng(-91, 5.0),
      const LatLng(double.nan, 5.0),
      const LatLng(47.0, double.infinity),
      const LatLng(double.negativeInfinity, 0),
    ]) {
      expect(() => polygonToGeoJson(<LatLng>[..._triangle, bad]), throwsArgumentError, reason: "$bad");
      expect(() => polygonToGeoJson(<LatLng>[bad, ..._triangle, bad]), throwsArgumentError, reason: "closed on $bad");
    }
  });
}

void _decodePolygonTests() {
  test("reads the outer ring as LatLng (lat, lon) and drops the closing vertex", () {
    expect(geoJsonOuterRings(_polygon(<Object?>[_trianglePositions])), <List<LatLng>>[_triangle]);
  });

  test("accepts int and double numbers", () {
    final List<Object?> mixed = <Object?>[
      <Object?>[5, 47],
      <Object?>[6, 47.0],
      <Object?>[6.0, 48],
      <Object?>[5, 47],
    ];

    expect(geoJsonOuterRings(_polygon(<Object?>[mixed])), <List<LatLng>>[
      <LatLng>[const LatLng(47, 5), const LatLng(47, 6), const LatLng(48, 6)],
    ]);
  });

  test("drops every trailing copy of the first vertex", () {
    final List<Object?> twiceClosed = <Object?>[..._trianglePositions, _trianglePositions.first];

    expect(geoJsonOuterRings(_polygon(<Object?>[twiceClosed])), <List<LatLng>>[_triangle]);
  });

  test("keeps an unclosed ring whole", () {
    expect(geoJsonOuterRings(_polygon(<Object?>[_trianglePositions.sublist(0, 3)])), <List<LatLng>>[_triangle]);
  });

  test("ignores holes (interior rings)", () {
    expect(
      geoJsonOuterRings(_polygon(<Object?>[_trianglePositions, _holePositions])),
      <List<LatLng>>[_triangle],
    );
  });

  test("ignores an altitude", () {
    final List<Object?> withAltitude = <Object?>[
      <Object?>[5.0, 47.0, 312.5],
      <Object?>[5.01, 47.0, 300],
      <Object?>[5.01, 47.01, 290],
      <Object?>[5.0, 47.0, 312.5],
    ];

    expect(geoJsonOuterRings(_polygon(<Object?>[withAltitude])), <List<LatLng>>[_triangle]);
  });

  test("accepts the range bounds", () {
    final List<Object?> world = <Object?>[
      <Object?>[-180, -90],
      <Object?>[180, -90],
      <Object?>[180, 90],
      <Object?>[-180, 90],
    ];

    expect(geoJsonOuterRings(_polygon(<Object?>[world])), <List<LatLng>>[
      <LatLng>[const LatLng(-90, -180), const LatLng(-90, 180), const LatLng(90, 180), const LatLng(90, -180)],
    ]);
  });

  test("accepts any map type, not only Map<String, dynamic>", () {
    final Map<dynamic, dynamic> geometry = <dynamic, dynamic>{
      "type": "Polygon",
      "coordinates": <dynamic>[_trianglePositions],
    };

    expect(geoJsonOuterRings(geometry), <List<LatLng>>[_triangle]);
  });
}

void _decodeContainerTests() {
  test("MultiPolygon: one outer ring per polygon, in order, holes ignored", () {
    final Map<String, Object?> multi = _multiPolygon(<Object?>[
      <Object?>[_trianglePositions, _holePositions],
      <Object?>[_squarePositions],
    ]);

    expect(geoJsonOuterRings(multi), <List<LatLng>>[_triangle, _square]);
  });

  test("Feature: the rings of its Polygon or MultiPolygon geometry", () {
    expect(geoJsonOuterRings(_feature(_polygon(<Object?>[_trianglePositions]))), <List<LatLng>>[_triangle]);
    expect(
      geoJsonOuterRings(_feature(_multiPolygon(<Object?>[<Object?>[_squarePositions], <Object?>[_trianglePositions]]))),
      <List<LatLng>>[_square, _triangle],
    );
  });

  test("FeatureCollection: the rings of every polygon feature, in order", () {
    final Map<String, Object?> collection = <String, Object?>{
      "type": "FeatureCollection",
      "features": <Object?>[
        _feature(_polygon(<Object?>[_trianglePositions])),
        _feature(<String, Object?>{"type": "Point", "coordinates": <double>[5.0, 47.0]}),
        _feature(null),
        _polygon(<Object?>[_squarePositions]), // a bare geometry is not a Feature
        "not a feature",
        _feature(_multiPolygon(<Object?>[<Object?>[_squarePositions], <Object?>[_trianglePositions]])),
      ],
    };

    expect(geoJsonOuterRings(collection), <List<LatLng>>[_triangle, _square, _triangle]);
  });

  test("an empty FeatureCollection has no ring", () {
    expect(geoJsonOuterRings(<String, Object?>{"type": "FeatureCollection", "features": <Object?>[]}), isEmpty);
  });

  test("reads a document decoded by jsonDecode", () {
    final String text = jsonEncode(<String, Object?>{
      "type": "FeatureCollection",
      "features": <Object?>[
        _feature(_polygon(<Object?>[_squarePositions])),
        _feature(_polygon(<Object?>[_trianglePositions])),
      ],
    });

    expect(geoJsonOuterRings(jsonDecode(text)), <List<LatLng>>[_square, _triangle]);
  });
}

void _malformedGeometryTests() {
  test("null and non-map values have no ring", () {
    for (final Object? value in <Object?>[null, "", "Polygon", 42, true, <Object?>[], <Object?>[_trianglePositions]]) {
      expect(geoJsonOuterRings(value), isEmpty, reason: "$value");
    }
  });

  test("unknown, missing, non-string or miscased types have no ring", () {
    for (final Object? type in <Object?>[null, 1, "Point", "LineString", "MultiLineString", "polygon", "POLYGON"]) {
      expect(
        geoJsonOuterRings(<String, Object?>{"type": type, "coordinates": <Object?>[_trianglePositions]}),
        isEmpty,
        reason: "$type",
      );
    }
    expect(geoJsonOuterRings(<String, Object?>{"coordinates": <Object?>[_trianglePositions]}), isEmpty);
  });

  test("a GeometryCollection is not read", () {
    final Map<String, Object?> collection = <String, Object?>{
      "type": "GeometryCollection",
      "geometries": <Object?>[_polygon(<Object?>[_trianglePositions])],
    };

    expect(geoJsonOuterRings(collection), isEmpty);
  });

  test("missing or malformed Polygon coordinates have no ring", () {
    expect(geoJsonOuterRings(<String, Object?>{"type": "Polygon"}), isEmpty);
    for (final Object? coordinates in <Object?>[
      null,
      "x",
      1,
      <Object?>[],
      <Object?>[null],
      <Object?>["ring"],
      <Object?>[<Object?>[]],
      <String, Object?>{"outer": _trianglePositions},
      _trianglePositions, // one nesting level missing
    ]) {
      expect(
        geoJsonOuterRings(<String, Object?>{"type": "Polygon", "coordinates": coordinates}),
        isEmpty,
        reason: "$coordinates",
      );
    }
  });

  test("a MultiPolygon keeps its well-formed polygons only", () {
    final Map<String, Object?> multi = _multiPolygon(<Object?>[
      <Object?>[_trianglePositions],
      null,
      "x",
      <Object?>[],
      <Object?>[<Object?>[<Object?>[5.0, 47.0], <Object?>["5", "47"], <Object?>[5.1, 47.1]]],
      <Object?>[_squarePositions],
    ]);

    expect(geoJsonOuterRings(multi), <List<LatLng>>[_triangle, _square]);
    expect(geoJsonOuterRings(<String, Object?>{"type": "MultiPolygon", "coordinates": "x"}), isEmpty);
  });

  test("malformed Features and FeatureCollections have no ring", () {
    for (final Object? value in <Object?>[
      <String, Object?>{"type": "Feature"},
      <String, Object?>{"type": "Feature", "geometry": "x"},
      _feature(_feature(_polygon(<Object?>[_trianglePositions]))), // a Feature is not a geometry
      <String, Object?>{"type": "FeatureCollection"},
      <String, Object?>{"type": "FeatureCollection", "features": null},
      <String, Object?>{"type": "FeatureCollection", "features": _feature(_polygon(<Object?>[_trianglePositions]))},
      <String, Object?>{"type": "FeatureCollection", "features": <Object?>[null, 1, <String, Object?>{"type": "Feature"}]},
      <int, Object?>{1: "Polygon"},
      <Object?>{"Polygon"},
    ]) {
      expect(geoJsonOuterRings(value), isEmpty, reason: "$value");
    }
  });
}

void _malformedPositionTests() {
  /// A Polygon whose outer ring is the open [_triangle] followed by [extra].
  Map<String, Object?> withPosition(Object? extra) {
    return _polygon(<Object?>[
      <Object?>[..._trianglePositions.sublist(0, 3), extra],
    ]);
  }

  test("a polygon with a malformed position is dropped", () {
    for (final Object? bad in <Object?>[
      null,
      5.0,
      "5,47",
      <Object?>[],
      <Object?>[5.0],
      <Object?>["5", "47"],
      <Object?>[null, 47.0],
      <Object?>[5.0, null],
      <String, Object?>{"lon": 5.0, "lat": 47.0},
      <Object?>[<Object?>[5.0, 47.0]],
    ]) {
      expect(geoJsonOuterRings(withPosition(bad)), isEmpty, reason: "$bad");
    }
  });

  test("a polygon with a position out of range or not finite is dropped", () {
    for (final List<Object?> bad in <List<Object?>>[
      <Object?>[180.0001, 47.0],
      <Object?>[-181, 47],
      <Object?>[5.0, 90.5],
      <Object?>[5.0, -91],
      <Object?>[652000.0, 6862000.0], // a projected CRS, in metres
      <Object?>[double.nan, 47.0],
      <Object?>[5.0, double.infinity],
      <Object?>[double.negativeInfinity, 0],
    ]) {
      expect(geoJsonOuterRings(withPosition(bad)), isEmpty, reason: "$bad");
    }
  });

  test("a polygon with fewer than 3 vertices once opened is dropped", () {
    for (final List<Object?> ring in <List<Object?>>[
      <Object?>[],
      <Object?>[<Object?>[5.0, 47.0]],
      <Object?>[<Object?>[5.0, 47.0], <Object?>[5.01, 47.0]],
      <Object?>[<Object?>[5.0, 47.0], <Object?>[5.01, 47.0], <Object?>[5.0, 47.0]],
    ]) {
      expect(geoJsonOuterRings(_polygon(<Object?>[ring])), isEmpty, reason: "$ring");
    }
  });
}

void _roundTripTests() {
  test("decoding an encoded ring gives the open ring back", () {
    expect(geoJsonOuterRings(polygonToGeoJson(_triangle)), <List<LatLng>>[_triangle]);
    expect(geoJsonOuterRings(polygonToGeoJson(<LatLng>[..._triangle, _a])), <List<LatLng>>[_triangle]);
  });

  test("survives a JSON text round trip exactly", () {
    const List<LatLng> ring = <LatLng>[
      LatLng(-33.868820123456, 151.209295987654),
      LatLng(-16.99, -179.99),
      LatLng(0.1, 0.2),
      LatLng(89.999999, -0.000001),
    ];

    expect(geoJsonOuterRings(jsonDecode(jsonEncode(polygonToGeoJson(ring)))), <List<LatLng>>[ring]);
  });

  test("encoding a decoded polygon gives the closed polygon back", () {
    final Map<String, Object?> polygon = _polygon(<Object?>[_trianglePositions]);

    expect(polygonToGeoJson(geoJsonOuterRings(polygon).single), polygon);
  });
}

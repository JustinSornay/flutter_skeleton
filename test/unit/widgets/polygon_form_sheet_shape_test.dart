// polygon_form_sheet_shape_test.dart
//
// Unit tests for PolygonFormShape
// (lib/widgets/custom/PolygonFormSheet/controllers/polygon_shape.dart): the
// crossing-edge check that gates PolygonFormSheet's submit. Simple shapes
// (triangle, square in either winding, concave, a vertex inserted on an edge)
// pass; a bow-tie, a crossing on the closing edge, a star, a vertex dropped
// on a non-adjacent edge, a repeated vertex and overlapping collinear edges
// are caught; fewer than 4 points never cross.

import "package:flutter_skeleton/widgets/custom/PolygonFormSheet/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:latlong2/latlong.dart";

/// Builds vertices from (x, y) pairs: x is the longitude, y the latitude.
List<LatLng> _shape(List<(double, double)> xy) {
  return <LatLng>[for (final (double x, double y) in xy) LatLng(y, x)];
}

bool _crosses(List<(double, double)> xy) {
  return PolygonFormShape.hasCrossingEdges(_shape(xy));
}

void main() {
  group("simple shapes", () {
    test("fewer than 4 points never cross", () {
      expect(_crosses(<(double, double)>[]), isFalse);
      expect(_crosses(<(double, double)>[(0, 0), (1, 1)]), isFalse);
      expect(_crosses(<(double, double)>[(0, 0), (1, 0), (0, 1)]), isFalse);
    });

    test("a square in either winding", () {
      expect(
        _crosses(<(double, double)>[(0, 0), (1, 0), (1, 1), (0, 1)]),
        isFalse,
      );
      expect(
        _crosses(<(double, double)>[(0, 0), (0, 1), (1, 1), (1, 0)]),
        isFalse,
      );
    });

    test("a concave shape", () {
      expect(
        _crosses(<(double, double)>[(0, 0), (4, 0), (4, 4), (2, 1), (0, 4)]),
        isFalse,
      );
    });

    test("a vertex inserted on an edge (adjacent collinear edges)", () {
      expect(
        _crosses(<(double, double)>[(0, 0), (1, 0), (2, 0), (2, 2), (0, 2)]),
        isFalse,
      );
    });
  });

  group("crossing or touching edges", () {
    test("a bow-tie square", () {
      expect(
        _crosses(<(double, double)>[(0, 0), (1, 1), (0, 1), (1, 0)]),
        isTrue,
      );
    });

    test("a crossing on the closing edge (last vertex back to the first)", () {
      expect(
        _crosses(<(double, double)>[(1, 1), (0, 1), (1, 0), (0, 0)]),
        isTrue,
      );
    });

    test("a five-point star drawn point to point", () {
      expect(
        _crosses(<(double, double)>[
          (0, 3),
          (2, -3),
          (-3, 1),
          (3, 1),
          (-2, -3),
        ]),
        isTrue,
      );
    });

    test("a crossing far from the first edge", () {
      // Edges 2 and 4 cross; edge 0 touches nothing.
      expect(
        _crosses(<(double, double)>[
          (0, 0),
          (6, 0),
          (6, 4),
          (2, 2),
          (4, 2),
          (0, 4),
        ]),
        isTrue,
      );
    });

    test("a vertex lying on a non-adjacent edge", () {
      expect(
        _crosses(<(double, double)>[(0, 0), (2, 0), (2, 2), (1, 0), (0, 2)]),
        isTrue,
      );
    });

    test("a vertex visited twice", () {
      expect(
        _crosses(<(double, double)>[
          (0, 0),
          (2, 0),
          (1, 1),
          (2, 2),
          (0, 2),
          (1, 1),
        ]),
        isTrue,
      );
    });

    test("non-adjacent edges overlapping on one line", () {
      expect(
        _crosses(<(double, double)>[
          (0, 0),
          (3, 0),
          (3, 1),
          (2, 0),
          (1, 0),
          (0, 1),
        ]),
        isTrue,
      );
    });
  });
}

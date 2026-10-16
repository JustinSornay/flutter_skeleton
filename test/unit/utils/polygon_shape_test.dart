// polygon_shape_test.dart
//
// Unit tests for hasCrossingEdges (lib/utils/geo/polygon_shape.dart), the
// crossing-edge check that gates PolygonFormSheet's submit and
// PolygonWizardSheet's polygon step. Simple shapes (triangle, square in
// either winding, concave, a vertex inserted on a horizontal or vertical
// edge) pass; a bow-tie, a crossing on the closing edge, a star, a vertex
// dropped on a non-adjacent edge, an edge folding back onto a non-adjacent
// one (each of its endpoints), a repeated vertex (including the east-most)
// and overlapping collinear edges are caught; fewer than 4 points never
// cross.

import "package:flutter_skeleton/utils/geo/polygon_shape.dart";
import "package:flutter_test/flutter_test.dart";
import "package:latlong2/latlong.dart";

/// Builds vertices from (x, y) pairs: x is the longitude, y the latitude.
List<LatLng> _shape(List<(double, double)> xy) {
  return <LatLng>[for (final (double x, double y) in xy) LatLng(y, x)];
}

bool _crosses(List<(double, double)> xy) => hasCrossingEdges(_shape(xy));

void main() {
  _simpleShapeTests();
  _crossingTests();
  _touchingTests();
}

void _simpleShapeTests() {
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
      expect(
        _crosses(<(double, double)>[(0, 0), (2, 0), (2, 2), (1, 1), (0, 2)]),
        isFalse,
      );
    });

    test("a vertex inserted on an edge (adjacent collinear edges)", () {
      expect(
        _crosses(<(double, double)>[(0, 0), (1, 0), (2, 0), (2, 2), (0, 2)]),
        isFalse,
      );
    });

    test("a vertex inserted on a vertical edge", () {
      // (0, 0)–(2, 0) shares the line x = 0 with (0, 2)–(0, 1) only below
      // its latitude range: no touch.
      expect(
        _crosses(<(double, double)>[(0, 0), (2, 0), (2, 2), (0, 2), (0, 1)]),
        isFalse,
      );
    });
  });
}

void _crossingTests() {
  group("crossing edges", () {
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
      // The closing edge (3, 1) → (0, 0) cuts the edge (2, 0)–(2, 2).
      expect(
        _crosses(<(double, double)>[(0, 0), (2, 0), (2, 2), (3, 1)]),
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
  });
}

void _touchingTests() {
  group("touching edges", () {
    test("a vertex lying on a non-adjacent edge", () {
      expect(
        _crosses(<(double, double)>[(0, 0), (2, 0), (2, 2), (1, 0), (0, 2)]),
        isTrue,
      );
      expect(
        _crosses(<(double, double)>[(0, 0), (2, 0), (2, 2), (1, 0)]),
        isTrue,
      );
    });

    test("an edge folding back onto a non-adjacent edge", () {
      // A later edge's first vertex (1, 0) lands on the first edge.
      expect(
        _crosses(<(double, double)>[(0, 0), (2, 0), (1, 0), (0, 1)]),
        isTrue,
      );
      // The first edge's first vertex (1, 0) lands on a later edge.
      expect(
        _crosses(<(double, double)>[(1, 0), (1, 1), (2, 0), (0, 0)]),
        isTrue,
      );
      // The first edge's second vertex (1, 0) lands on a later edge.
      expect(
        _crosses(<(double, double)>[(0, 1), (1, 0), (2, 0), (0, 0), (0, 0.5)]),
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
      // The repeated vertex (2, 1) is the east-most point of every edge
      // through it.
      expect(
        _crosses(<(double, double)>[
          (2, 1),
          (0, 0),
          (1, 0),
          (2, 1),
          (1, 2),
          (0, 2),
        ]),
        isTrue,
      );
    });

    test("a ring repeating its first vertex at the end", () {
      expect(
        _crosses(<(double, double)>[(0, 0), (1, 0), (1, 1), (0, 1), (0, 0)]),
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

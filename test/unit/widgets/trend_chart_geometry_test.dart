// trend_chart_geometry_test.dart
//
// Unit tests for TrendChartGeometry
// (lib/widgets/custom/TrendChart/controllers/trend_geometry.dart): the
// plotted spots, segments without a threshold, the interpolated split at
// each side change, the adverse crossings for both polarities, values on the
// line, the fitted and explicit Y range (threshold included, zero spans
// widened, values and threshold asserted within explicit bounds), the room
// above a Y value and right of an X value, and the X label step.

import "package:fl_chart/fl_chart.dart";
import "package:flutter_skeleton/widgets/custom/TrendChart/index.dart";
import "package:flutter_test/flutter_test.dart";

TrendChartGeometry _compute(List<double> values, {TrendThreshold? threshold, double? minY, double? maxY}) {
  return TrendChartGeometry.compute(values, threshold: threshold, minY: minY, maxY: maxY);
}

void _expectSpot(FlSpot spot, double x, double y) {
  expect(spot.x, closeTo(x, 1e-9));
  expect(spot.y, closeTo(y, 1e-9));
}

const TrendThreshold _higher = TrendThreshold(value: 0.6);

const TrendThreshold _lower = TrendThreshold(value: 0.6, higherIsBetter: false);

void main() {
  test("spots hold every value at its index, with or without a threshold", () {
    const List<FlSpot> expected = <FlSpot>[FlSpot(0, 0.72), FlSpot(1, 0.5), FlSpot(2, 0.7)];

    expect(_compute(<double>[0.72, 0.5, 0.7]).spots, expected);
    expect(_compute(<double>[0.72, 0.5, 0.7], threshold: _higher).spots, expected);
  });

  group("segments without a threshold", () {
    test("one favourable segment holds every value at its index", () {
      final TrendChartGeometry geometry = _compute(<double>[0.2, 0.9, 0.4]);

      final TrendChartSegment segment = geometry.segments.single;
      expect(segment.favourable, isTrue);
      expect(segment.spots, const <FlSpot>[FlSpot(0, 0.2), FlSpot(1, 0.9), FlSpot(2, 0.4)]);
      expect(geometry.adverseCrossings, isEmpty);
    });

    test("no value gives no segment", () {
      expect(_compute(<double>[]).segments, isEmpty);
      expect(_compute(<double>[], threshold: _higher).segments, isEmpty);
    });
  });

  group("segments with a threshold", () {
    test("values all on the favourable side stay in one segment", () {
      final TrendChartGeometry geometry = _compute(<double>[0.62, 0.7, 0.9], threshold: _higher);

      expect(geometry.segments.single.favourable, isTrue);
      expect(geometry.segments.single.spots, hasLength(3));
      expect(geometry.adverseCrossings, isEmpty);
    });

    test("values all on the adverse side stay in one segment, with no crossing", () {
      final TrendChartGeometry geometry = _compute(<double>[0.5, 0.4, 0.3], threshold: _higher);

      expect(geometry.segments.single.favourable, isFalse);
      expect(geometry.adverseCrossings, isEmpty);
    });

    test("a downward crossing splits at the interpolated point shared by both segments", () {
      final TrendChartGeometry geometry = _compute(<double>[0.72, 0.68, 0.63, 0.59, 0.56], threshold: _higher);

      expect(geometry.segments, hasLength(2));
      final TrendChartSegment first = geometry.segments[0];
      final TrendChartSegment second = geometry.segments[1];
      expect(first.favourable, isTrue);
      expect(second.favourable, isFalse);
      expect(first.spots, hasLength(4));
      _expectSpot(first.spots.last, 2.75, 0.6);
      _expectSpot(second.spots.first, 2.75, 0.6);
      expect(second.spots.sublist(1), const <FlSpot>[FlSpot(3, 0.59), FlSpot(4, 0.56)]);
      expect(geometry.adverseCrossings.single, closeTo(2.75, 1e-9));
    });

    test("down then up gives three segments but marks only the downward crossing", () {
      final TrendChartGeometry geometry = _compute(<double>[0.8, 0.4, 0.8], threshold: _higher);

      expect(geometry.segments.map((TrendChartSegment s) => s.favourable), <bool>[true, false, true]);
      _expectSpot(geometry.segments[1].spots.first, 0.5, 0.6);
      _expectSpot(geometry.segments[1].spots.last, 1.5, 0.6);
      expect(geometry.adverseCrossings.single, closeTo(0.5, 1e-9));
    });

    test("lower-is-better inverts the sides and marks upward crossings", () {
      final TrendChartGeometry geometry = _compute(<double>[0.4, 0.8, 0.4], threshold: _lower);

      expect(geometry.segments.map((TrendChartSegment s) => s.favourable), <bool>[true, false, true]);
      expect(geometry.adverseCrossings.single, closeTo(0.5, 1e-9));
    });

    test("a value exactly on the line is favourable for both polarities", () {
      expect(_compute(<double>[0.6, 0.7, 0.8], threshold: _higher).segments.single.favourable, isTrue);
      expect(_compute(<double>[0.6, 0.5, 0.4], threshold: _lower).segments.single.favourable, isTrue);
    });

    test("leaving the line downwards crosses at the point on the line", () {
      final TrendChartGeometry geometry = _compute(<double>[0.7, 0.6, 0.5], threshold: _higher);

      expect(geometry.segments, hasLength(2));
      expect(geometry.adverseCrossings.single, closeTo(1, 1e-9));
    });
  });

  group("Y range", () {
    test("explicit bounds are kept", () {
      final TrendChartGeometry geometry = _compute(<double>[0.2, 0.4], threshold: _higher, minY: 0, maxY: 1);

      expect(geometry.minY, 0);
      expect(geometry.maxY, 1);
    });

    test("open bounds fit the values", () {
      final TrendChartGeometry geometry = _compute(<double>[3, 9, 5]);

      expect(geometry.minY, 3);
      expect(geometry.maxY, 9);
    });

    test("open bounds include the threshold so its line stays in view", () {
      final TrendChartGeometry above = _compute(<double>[0.7, 0.9], threshold: _higher);
      final TrendChartGeometry below = _compute(<double>[0.1, 0.3], threshold: _higher);

      expect((above.minY, above.maxY), (0.6, 0.9));
      expect((below.minY, below.maxY), (0.1, 0.6));
    });

    test("a flat series with open bounds is widened by 0.5 on each side", () {
      final TrendChartGeometry geometry = _compute(<double>[2, 2, 2]);

      expect(geometry.minY, 1.5);
      expect(geometry.maxY, 2.5);
    });

    test("data flat on a one-sided bound never gives a zero span", () {
      final TrendChartGeometry onlyMax = _compute(<double>[1, 1], maxY: 1);
      final TrendChartGeometry onlyMin = _compute(<double>[0, 0], minY: 0);

      expect((onlyMax.minY, onlyMax.maxY), (0.0, 1.0));
      expect((onlyMin.minY, onlyMin.maxY), (0.0, 1.0));
    });

    test("values and threshold on an explicit bound are accepted", () {
      final TrendChartGeometry geometry = _compute(
        <double>[0, 1],
        threshold: const TrendThreshold(value: 1),
        minY: 0,
        maxY: 1,
      );

      expect((geometry.minY, geometry.maxY), (0.0, 1.0));
    });

    test("a value outside an explicit bound is rejected", () {
      expect(() => _compute(<double>[0.5, 1.2], minY: 0, maxY: 1), throwsAssertionError);
      expect(() => _compute(<double>[-0.1, 0.5], minY: 0), throwsAssertionError);
    });

    test("a threshold outside an explicit bound is rejected", () {
      expect(() => _compute(<double>[0.2, 0.4], threshold: _higher, maxY: 0.5), throwsAssertionError);
      expect(() => _compute(<double>[0.7, 0.9], threshold: _higher, minY: 0.65), throwsAssertionError);
    });

    test("open bounds accept anything, and fit it", () {
      final TrendChartGeometry geometry = _compute(<double>[-3, 9], threshold: const TrendThreshold(value: 12));

      expect((geometry.minY, geometry.maxY), (-3.0, 12.0));
    });
  });

  group("room around the line labels", () {
    test("roomAbove scales the distance to maxY onto the plot height", () {
      final TrendChartGeometry geometry = _compute(<double>[0.2, 0.6], minY: 0, maxY: 1);

      expect(geometry.roomAbove(1, 150), 0);
      expect(geometry.roomAbove(0.6, 150), closeTo(60, 1e-9));
      expect(geometry.roomAbove(0, 150), 150);
    });

    test("roomRight scales the distance to the last spot onto the plot width", () {
      final TrendChartGeometry geometry = _compute(<double>[0.2, 0.6, 0.4, 0.8, 0.5]);

      expect(geometry.roomRight(4, 200), 0);
      expect(geometry.roomRight(3, 200), 50);
      expect(geometry.roomRight(0, 200), 200);
    });
  });

  group("xLabelInterval", () {
    test("steps by 1 up to 10 points, 5 up to 30, else 15", () {
      expect(TrendChartGeometry.xLabelInterval(3), 1);
      expect(TrendChartGeometry.xLabelInterval(10), 1);
      expect(TrendChartGeometry.xLabelInterval(11), 5);
      expect(TrendChartGeometry.xLabelInterval(30), 5);
      expect(TrendChartGeometry.xLabelInterval(31), 15);
      expect(TrendChartGeometry.xLabelInterval(90), 15);
    });
  });
}

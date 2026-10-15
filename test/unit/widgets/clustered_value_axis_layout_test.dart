// clustered_value_axis_layout_test.dart
//
// Unit tests for ValueAxisLayout
// (lib/widgets/custom/ClusteredValueAxis/controllers/axis_layout.dart): the
// zoomed range, the clipped band spans, the three clustering passes
// (threshold groups, pixel coalescing, reference fusion), the best flags,
// the display values, width estimates, slot clamping, the non-overlapping
// hit boxes and value ranks.

import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/ClusteredValueAxis/index.dart";
import "package:flutter_skeleton/widgets/custom/_base/value_band.dart";
import "package:flutter_test/flutter_test.dart";

int _nextId = 0;

/// A point at [value] with a fresh id (or [id]).
ValueAxisPoint<int> _pt(double value, {int? id}) {
  return ValueAxisPoint<int>(id: id ?? _nextId++, value: value, label: "p$value");
}

List<double> _values(List<ValueAxisPoint<int>> points) {
  return points.map((ValueAxisPoint<int> p) => p.value).toList(growable: false);
}

/// computeItems over [points] on the range computeRange gives for
/// [reference] and the points.
List<ValueAxisItem<int>> _items(
  List<ValueAxisPoint<int>> points, {
  required double width,
  double? reference,
  double? rangeReference,
  bool highlightBest = true,
}) {
  final (double mn, double mx) = ValueAxisLayout.computeRange(rangeReference ?? reference, _values(points));
  return ValueAxisLayout.computeItems<int>(
    points: points,
    axisMin: mn,
    axisMax: mx,
    axisWidthPx: width,
    reference: reference,
    highlightBest: highlightBest,
  );
}

void main() {
  group("computeRange", () {
    test("includes the reference and the points with 10 % padding", () {
      final (double mn, double mx) = ValueAxisLayout.computeRange(0.38, <double>[0.82, 0.76, 0.71, 0.68]);
      // span 0.44 → padding 0.044.
      expect(mn, closeTo(0.336, 1e-9));
      expect(mx, closeTo(0.864, 1e-9));
    });

    test("clamps the padding to its minimum for a narrow span", () {
      final (double mn, double mx) = ValueAxisLayout.computeRange(0.50, <double>[0.55]);
      expect(mx - mn, closeTo(0.080, 1e-9));
    });

    test("uses 10 % of a large span", () {
      final (double mn, double mx) = ValueAxisLayout.computeRange(0.30, <double>[0.45, 0.85]);
      expect(mn, closeTo(0.245, 1e-9));
      expect(mx, closeTo(0.905, 1e-9));
    });

    test("clamps the padding to its maximum for a very large span", () {
      final (double mn, double mx) = ValueAxisLayout.computeRange(null, <double>[0.20, 0.90]);
      expect(mn, closeTo(0.14, 1e-9));
      expect(mx, closeTo(0.96, 1e-9));
    });

    test("stays within [0, 1]", () {
      final (double mn, double mx) = ValueAxisLayout.computeRange(0.0, <double>[1.0]);
      expect(mn, 0.0);
      expect(mx, 1.0);
    });

    test("centres on the reference when there are no values", () {
      final (double mn, double mx) = ValueAxisLayout.computeRange(0.50, const <double>[]);
      expect(mn, closeTo(0.485, 1e-9));
      expect(mx, closeTo(0.515, 1e-9));
    });

    test("works without a reference", () {
      final (double mn, double mx) = ValueAxisLayout.computeRange(null, <double>[0.40, 0.60]);
      expect(mn, closeTo(0.38, 1e-9));
      expect(mx, closeTo(0.62, 1e-9));
    });

    test("extends left for a reference below every value", () {
      final (double mn, double mx) = ValueAxisLayout.computeRange(0.20, <double>[0.55, 0.70]);
      expect(mn, lessThan(0.20));
      expect(mx, greaterThanOrEqualTo(0.70));
    });

    test("falls back to the full axis with no data", () {
      expect(ValueAxisLayout.computeRange(null, const <double>[]), (0.0, 1.0));
    });
  });

  group("computeBandSpans", () {
    const List<ValueBand> bands = <ValueBand>[
      ValueBand(from: 0.0, to: 0.40, tone: StatusTone.danger),
      ValueBand(from: 0.40, to: 0.70, tone: StatusTone.warning),
      ValueBand(from: 0.70, to: 1.0, tone: StatusTone.success),
    ];

    test("covers the whole axis with contiguous bands", () {
      final List<(double, double)> spans = ValueAxisLayout.computeBandSpans(0.0, 1.0, bands);
      final double total = spans.fold(0.0, (double sum, (double, double) s) => sum + s.$2);
      expect(total, closeTo(100, 1e-9));
      expect(spans[1].$1, closeTo(40, 1e-9));
    });

    test("clips the bands to the visible range", () {
      final List<(double, double)> spans = ValueAxisLayout.computeBandSpans(0.30, 0.90, bands);
      expect(spans[0].$1, 0.0);
      expect(spans[0].$2, closeTo(16.67, 0.01));
      expect(spans[2].$1, closeTo(66.67, 0.01));
      expect(spans[2].$2, closeTo(33.33, 0.01));
    });

    test("gives zero width to bands outside the range", () {
      final List<(double, double)> spans = ValueAxisLayout.computeBandSpans(0.75, 0.95, bands);
      expect(spans[0], (0.0, 0.0));
      expect(spans[1], (0.0, 0.0));
      expect(spans[2].$2, closeTo(100, 1e-9));
    });

    test("keeps gaps between non-contiguous bands", () {
      final List<(double, double)> spans = ValueAxisLayout.computeBandSpans(0.0, 1.0, const <ValueBand>[
        ValueBand(from: 0.10, to: 0.20),
        ValueBand(from: 0.60, to: 0.80),
      ]);
      expect(spans[0].$1, closeTo(10, 1e-9));
      expect(spans[0].$2, closeTo(10, 1e-9));
      expect(spans[1].$1, closeTo(60, 1e-9));
      expect(spans[1].$2, closeTo(20, 1e-9));
    });

    test("returns nothing for no bands", () {
      expect(ValueAxisLayout.computeBandSpans(0.0, 1.0, const <ValueBand>[]), isEmpty);
    });
  });

  group("computeItems", () {
    test("returns nothing for no points or a zero width", () {
      expect(
        ValueAxisLayout.computeItems<int>(
          points: const <ValueAxisPoint<int>>[],
          axisMin: 0,
          axisMax: 1,
          axisWidthPx: 400,
        ),
        isEmpty,
      );
      expect(_items(<ValueAxisPoint<int>>[_pt(0.5)], width: 0), isEmpty);
    });

    test("pass 1 groups points closer than the threshold", () {
      // range 0.245–0.905 over 400 px → threshold ≈ 0.0545: 0.50/0.51 group,
      // the 0.14 and 0.20 gaps split.
      final List<ValueAxisItem<int>> items = _items(
        <ValueAxisPoint<int>>[_pt(0.85), _pt(0.65), _pt(0.51), _pt(0.50)],
        width: 400,
        rangeReference: 0.30,
      );
      expect(items, hasLength(3));
      final ValueAxisCluster<int> cluster = items.first as ValueAxisCluster<int>;
      expect(_values(cluster.points), <double>[0.51, 0.50]);
      expect(cluster.containsBest, isFalse);
      final ValueAxisSingle<int> last = items.last as ValueAxisSingle<int>;
      expect(last.point.value, 0.85);
      expect(last.isBest, isTrue);
    });

    test("pass 2 merges a pill with an overlapping bubble", () {
      // range 0.665–0.755 over 130 px → threshold ≈ 0.0228: {0.68, 0.69,
      // 0.70} and {0.74} split in pass 1, then the 116 px pill and the
      // bubble are 72 px apart (< 79 px) and merge.
      final List<ValueAxisItem<int>> items = _items(
        <ValueAxisPoint<int>>[_pt(0.70), _pt(0.69), _pt(0.68), _pt(0.74)],
        width: 130,
      );
      expect(items, hasLength(1));
      final ValueAxisCluster<int> cluster = items.single as ValueAxisCluster<int>;
      expect(_values(cluster.points), <double>[0.74, 0.70, 0.69, 0.68]);
      expect(cluster.center, closeTo(0.7025, 1e-9));
      expect(cluster.containsBest, isTrue);
    });

    test("keeps far-apart points as single bubbles", () {
      final List<ValueAxisItem<int>> items = _items(
        <ValueAxisPoint<int>>[_pt(0.85), _pt(0.65), _pt(0.45)],
        width: 444,
        rangeReference: 0.30,
      );
      expect(items.every((ValueAxisItem<int> i) => i is ValueAxisSingle<int>), isTrue);
    });

    test("merges close points into one cluster holding the best", () {
      final List<ValueAxisItem<int>> items = _items(
        <ValueAxisPoint<int>>[_pt(0.72), _pt(0.71), _pt(0.70)],
        width: 100,
        rangeReference: 0.40,
      );
      expect(items.single, isA<ValueAxisCluster<int>>());
      expect((items.single as ValueAxisCluster<int>).containsBest, isTrue);
    });

    test("flags nothing best when highlightBest is false", () {
      final List<ValueAxisItem<int>> items = _items(
        <ValueAxisPoint<int>>[_pt(0.85), _pt(0.45)],
        width: 444,
        highlightBest: false,
      );
      expect(items.whereType<ValueAxisSingle<int>>().any((ValueAxisSingle<int> s) => s.isBest), isFalse);
    });

    test("pass 3 fuses a nearby reference with the closest item", () {
      final List<ValueAxisItem<int>> items = _items(
        <ValueAxisPoint<int>>[_pt(0.20), _pt(0.50)],
        width: 200,
        reference: 0.18,
      );
      final ValueAxisReferenceCluster<int> fused = items.first as ValueAxisReferenceCluster<int>;
      expect(fused.reference, closeTo(0.18, 1e-9));
      expect(_values(fused.points), <double>[0.20]);
      expect(fused.center, closeTo(0.19, 1e-9));
      expect(fused.containsBest, isFalse);
      expect(items.last, isA<ValueAxisSingle<int>>());
    });

    test("pass 3 leaves a far reference apart", () {
      final List<ValueAxisItem<int>> items = _items(
        <ValueAxisPoint<int>>[_pt(0.70), _pt(0.85)],
        width: 400,
        reference: 0.20,
      );
      expect(items.any((ValueAxisItem<int> i) => i is ValueAxisReferenceCluster<int>), isFalse);
    });

    test("pass 3 ignores a reference outside the visible range", () {
      final List<ValueAxisPoint<int>> points = <ValueAxisPoint<int>>[_pt(0.70), _pt(0.71)];
      final List<ValueAxisItem<int>> items = ValueAxisLayout.computeItems<int>(
        points: points,
        axisMin: 0.65,
        axisMax: 0.75,
        axisWidthPx: 400,
        reference: 0.60,
      );
      expect(items.any((ValueAxisItem<int> i) => i is ValueAxisReferenceCluster<int>), isFalse);
    });

    test("does no fusion without a reference", () {
      final List<ValueAxisItem<int>> items = _items(
        <ValueAxisPoint<int>>[_pt(0.20), _pt(0.50)],
        width: 200,
        rangeReference: 0.18,
      );
      expect(items.any((ValueAxisItem<int> i) => i is ValueAxisReferenceCluster<int>), isFalse);
    });
  });

  group("item helpers", () {
    test("itemDisplayValue is the highest member or the reference", () {
      final ValueAxisPoint<int> low = _pt(0.40);
      final ValueAxisPoint<int> high = _pt(0.60);
      expect(ValueAxisLayout.itemDisplayValue(ValueAxisSingle<int>(low, isBest: false)), 0.40);
      expect(
        ValueAxisLayout.itemDisplayValue(
          ValueAxisCluster<int>(<ValueAxisPoint<int>>[high, low], center: 0.5, containsBest: true),
        ),
        0.60,
      );
      expect(
        ValueAxisLayout.itemDisplayValue(
          ValueAxisReferenceCluster<int>(
            reference: 0.70,
            points: <ValueAxisPoint<int>>[high],
            center: 0.65,
            containsBest: false,
          ),
        ),
        0.70,
      );
      expect(
        ValueAxisLayout.itemDisplayValue(
          ValueAxisReferenceCluster<int>(
            reference: 0.50,
            points: <ValueAxisPoint<int>>[high],
            center: 0.55,
            containsBest: false,
          ),
        ),
        0.60,
      );
    });

    test("itemRenderedWidth grows with the count digits and the star", () {
      final List<ValueAxisPoint<int>> two = <ValueAxisPoint<int>>[_pt(0.5), _pt(0.4)];
      final List<ValueAxisPoint<int>> twelve = List<ValueAxisPoint<int>>.generate(12, (int i) => _pt(0.4));
      expect(ValueAxisLayout.itemRenderedWidth(ValueAxisSingle<int>(_pt(0.5), isBest: true)), 30);
      expect(
        ValueAxisLayout.itemRenderedWidth(ValueAxisCluster<int>(two, center: 0.45, containsBest: false)),
        116,
      );
      expect(
        ValueAxisLayout.itemRenderedWidth(ValueAxisCluster<int>(twelve, center: 0.4, containsBest: true)),
        116 + 8 + 16,
      );
      expect(
        ValueAxisLayout.itemRenderedWidth(
          ValueAxisReferenceCluster<int>(reference: 0.5, points: two, center: 0.47, containsBest: false),
        ),
        134,
      );
    });

    test("membersOf lists the points of each kind", () {
      final ValueAxisPoint<int> a = _pt(0.5);
      expect(ValueAxisLayout.membersOf(ValueAxisSingle<int>(a, isBest: false)), <ValueAxisPoint<int>>[a]);
    });

    test("valueToPercent clamps to the axis and handles an empty range", () {
      expect(ValueAxisLayout.valueToPercent(0.5, 0.0, 1.0), closeTo(50, 1e-9));
      expect(ValueAxisLayout.valueToPercent(0.9, 0.2, 0.6), 100);
      expect(ValueAxisLayout.valueToPercent(0.5, 0.5, 0.5), 0);
    });

    test("slotLeft centres the slot and keeps it inside the axis", () {
      expect(ValueAxisLayout.slotLeft(200, 48, 400), 176);
      expect(ValueAxisLayout.slotLeft(10, 48, 400), 0);
      expect(ValueAxisLayout.slotLeft(395, 48, 400), 352);
      expect(ValueAxisLayout.slotLeft(395, 120, 400, rightMargin: 4), 276);
      expect(ValueAxisLayout.slotLeft(50, 120, 100), 0);
    });

    test("hitSlots gives far-apart elements full, centred boxes", () {
      expect(
        ValueAxisLayout.hitSlots(<(double, double)>[(100, 130), (300, 330)], 400),
        <(double, double)>[(91, 48), (291, 48)],
      );
      expect(ValueAxisLayout.hitSlots(<(double, double)>[], 400), isEmpty);
    });

    test("hitSlots keeps boxes inside the axis", () {
      expect(
        ValueAxisLayout.hitSlots(<(double, double)>[(0, 30), (370, 400)], 400),
        <(double, double)>[(0, 48), (352, 48)],
      );
    });

    test("hitSlots stops at the middle of the gap and pushes boxes apart", () {
      // Visible edges 130 and 137: the boundary is 133.5.
      expect(
        ValueAxisLayout.hitSlots(<(double, double)>[(100, 130), (137, 167)], 400),
        <(double, double)>[(85.5, 48), (133.5, 48)],
      );
    });

    test("hitSlots narrows a box squeezed between two neighbours", () {
      expect(
        ValueAxisLayout.hitSlots(<(double, double)>[(100, 130), (137, 167), (174, 204)], 400),
        <(double, double)>[(85.5, 48), (133.5, 37), (170.5, 48)],
      );
    });

    test("hitSlots accepts any order and answers in it", () {
      expect(
        ValueAxisLayout.hitSlots(<(double, double)>[(137, 167), (100, 130)], 400),
        <(double, double)>[(133.5, 48), (85.5, 48)],
      );
    });
  });

  group("ranksByValue", () {
    test("gives 1 to the highest value", () {
      final Map<int, int> ranks = ValueAxisLayout.ranksByValue<int>(<ValueAxisPoint<int>>[
        _pt(0.40, id: 1),
        _pt(0.90, id: 2),
        _pt(0.60, id: 3),
      ]);
      expect(ranks, <int, int>{2: 1, 3: 2, 1: 3});
    });

    test("lets equal values share a rank", () {
      final Map<int, int> ranks = ValueAxisLayout.ranksByValue<int>(<ValueAxisPoint<int>>[
        _pt(0.90, id: 1),
        _pt(0.60, id: 2),
        _pt(0.60, id: 3),
        _pt(0.40, id: 4),
      ]);
      expect(ranks, <int, int>{1: 1, 2: 2, 3: 2, 4: 4});
    });
  });
}

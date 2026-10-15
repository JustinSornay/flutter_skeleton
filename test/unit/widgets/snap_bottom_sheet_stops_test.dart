// snap_bottom_sheet_stops_test.dart
//
// Unit tests for SnapBottomSheetStops
// (lib/widgets/custom/SnapBottomSheet/controllers/snap_stops.dart): the
// collapsed fraction fitted to the grip (raised, capped half-way to mid,
// unbounded parent), the fraction of each snap, the stable sizes list, the
// snap a size rests at (within the tolerance), and where a released drag
// settles (nearest, tie, fling up and down, beyond the ends).

import "package:flutter_skeleton/widgets/custom/SnapBottomSheet/index.dart";
import "package:flutter_test/flutter_test.dart";

SnapBottomSheetStops _stops() => SnapBottomSheetStops(collapsed: 0.25, mid: 0.5, full: 0.75);

double _fit(double gripHeight, double parentHeight) {
  return SnapBottomSheetStops.fitCollapsed(
    collapsed: 0.1,
    mid: 0.5,
    gripHeight: gripHeight,
    parentHeight: parentHeight,
  );
}

void main() {
  group("fitCollapsed", () {
    test("keeps the fraction when the grip fits", () {
      expect(_fit(48, 800), 0.1);
      expect(_fit(80, 800), 0.1);
    });

    test("raises the fraction to the grip's height", () {
      expect(_fit(120, 800), moreOrLessEquals(0.15));
      expect(_fit(80, 640), moreOrLessEquals(0.125));
    });

    test("stops half-way to mid", () {
      expect(_fit(400, 800), moreOrLessEquals(0.3));
      expect(_fit(800, 800), moreOrLessEquals(0.3));
    });

    test("keeps the fraction for an unbounded or empty parent", () {
      expect(_fit(80, double.infinity), 0.1);
      expect(_fit(80, 0), 0.1);
    });
  });

  test("fractionOf maps each snap to its fraction", () {
    final SnapBottomSheetStops stops = _stops();

    expect(stops.fractionOf(SheetSnap.collapsed), 0.25);
    expect(stops.fractionOf(SheetSnap.mid), 0.5);
    expect(stops.fractionOf(SheetSnap.full), 0.75);
  });

  test("sizes lists the fractions in snap order, as one unmodifiable list", () {
    final SnapBottomSheetStops stops = _stops();

    expect(stops.sizes, <double>[0.25, 0.5, 0.75]);
    expect(identical(stops.sizes, stops.sizes), isTrue);
    expect(() => stops.sizes.add(1), throwsUnsupportedError);
  });

  test("snapAt finds the height within the tolerance, null between heights", () {
    final SnapBottomSheetStops stops = _stops();

    expect(stops.snapAt(0.25), SheetSnap.collapsed);
    expect(stops.snapAt(0.5 + SnapBottomSheetStops.tolerance / 2), SheetSnap.mid);
    expect(stops.snapAt(0.75 - SnapBottomSheetStops.tolerance / 2), SheetSnap.full);
    expect(stops.snapAt(0.5 + SnapBottomSheetStops.tolerance * 2), isNull);
    expect(stops.snapAt(0.4), isNull);
  });

  group("settle", () {
    test("without a direction, picks the nearest height (the higher one on a tie)", () {
      final SnapBottomSheetStops stops = _stops();

      expect(stops.settle(0.1), SheetSnap.collapsed);
      expect(stops.settle(0.3), SheetSnap.collapsed);
      expect(stops.settle(0.375), SheetSnap.mid);
      expect(stops.settle(0.45), SheetSnap.mid);
      expect(stops.settle(0.7), SheetSnap.full);
      expect(stops.settle(0.75), SheetSnap.full);
    });

    test("growing, picks the next height above (full at the top)", () {
      final SnapBottomSheetStops stops = _stops();

      expect(stops.settle(0.25, growing: true), SheetSnap.mid);
      expect(stops.settle(0.3, growing: true), SheetSnap.mid);
      expect(stops.settle(0.5, growing: true), SheetSnap.full);
      expect(stops.settle(0.75, growing: true), SheetSnap.full);
    });

    test("shrinking, picks the next height below (collapsed at the bottom)", () {
      final SnapBottomSheetStops stops = _stops();

      expect(stops.settle(0.75, growing: false), SheetSnap.mid);
      expect(stops.settle(0.7, growing: false), SheetSnap.mid);
      expect(stops.settle(0.5, growing: false), SheetSnap.collapsed);
      expect(stops.settle(0.25, growing: false), SheetSnap.collapsed);
    });
  });
}

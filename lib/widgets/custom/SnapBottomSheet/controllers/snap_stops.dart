// snap_stops.dart
//
// SnapBottomSheetStops — pure snap maths of SnapBottomSheet: the collapsed
// fraction that fits the grip, the fraction of each SheetSnap, the snap a
// sheet size rests at, and the height a released drag settles on. No
// widgets, so it is unit-tested on its own.

part of "../index.dart";

/// The three heights of a [SnapBottomSheet] as fractions of the parent
/// height, and the snap logic built on them.
@visibleForTesting
@immutable
final class SnapBottomSheetStops {
  SnapBottomSheetStops({required this.collapsed, required this.mid, required this.full})
    : sizes = List<double>.unmodifiable(<double>[collapsed, mid, full]);

  /// Largest gap between a size and a height for the size to rest there.
  static const double tolerance = 0.001;

  /// The collapsed fraction that shows a grip [gripHeight] tall in full in a
  /// parent [parentHeight] tall: [collapsed], raised to the grip's fraction
  /// but never above half-way to [mid] (a taller grip is clipped).
  /// [collapsed] as is when [parentHeight] is not a positive finite height.
  static double fitCollapsed({
    required double collapsed,
    required double mid,
    required double gripHeight,
    required double parentHeight,
  }) {
    if (!parentHeight.isFinite || parentHeight <= 0) return collapsed;
    return math.min(math.max(collapsed, gripHeight / parentHeight), (collapsed + mid) / 2);
  }

  /// Collapsed fraction.
  final double collapsed;

  /// Mid fraction.
  final double mid;

  /// Full fraction.
  final double full;

  /// [collapsed], [mid] and [full], in [SheetSnap] order. One list per
  /// instance: the sheet re-snaps whenever it receives a new list.
  final List<double> sizes;

  /// Fraction of [snap].
  double fractionOf(SheetSnap snap) => sizes[snap.index];

  /// The height [size] rests at (within [tolerance]), or null between two
  /// heights.
  SheetSnap? snapAt(double size) {
    for (final SheetSnap snap in SheetSnap.values) {
      if ((size - fractionOf(snap)).abs() < tolerance) return snap;
    }
    return null;
  }

  /// The height a drag released at [size] settles on: the next height above
  /// when [growing] is true (full at the top), the next height below when it
  /// is false (collapsed at the bottom), the nearest height when it is null
  /// (the higher one on a tie).
  SheetSnap settle(double size, {bool? growing}) {
    return switch (growing) {
      true => SheetSnap.values.firstWhere(
        (SheetSnap snap) => fractionOf(snap) > size + tolerance,
        orElse: () => SheetSnap.full,
      ),
      false => SheetSnap.values.lastWhere(
        (SheetSnap snap) => fractionOf(snap) < size - tolerance,
        orElse: () => SheetSnap.collapsed,
      ),
      null => _nearest(size),
    };
  }

  SheetSnap _nearest(double size) {
    SheetSnap nearest = SheetSnap.collapsed;
    for (final SheetSnap snap in SheetSnap.values) {
      if ((fractionOf(snap) - size).abs() <= (fractionOf(nearest) - size).abs()) nearest = snap;
    }
    return nearest;
  }
}

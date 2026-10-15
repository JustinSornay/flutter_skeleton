// axis_layout.dart
//
// ValueAxisLayout — pure layout maths of ClusteredValueAxis: the visible
// range zoomed on the data, the band spans clipped to it, the three-pass
// collision clustering (value threshold, pixel coalescing, reference
// fusion), the placement helpers, the non-overlapping hit boxes and the
// popover ranks. The sealed
// ValueAxisItem family describes what the axis renders. No widgets, so it
// is unit-tested on its own.

part of "../index.dart";

/// One element rendered on the axis of a [ClusteredValueAxis].
@visibleForTesting
sealed class ValueAxisItem<T extends Object> {
  const ValueAxisItem();
}

/// A point drawn as its own bubble.
@visibleForTesting
final class ValueAxisSingle<T extends Object> extends ValueAxisItem<T> {
  const ValueAxisSingle(this.point, {required this.isBest});

  final ValueAxisPoint<T> point;

  /// Whether the point holds the highest value (best highlighting on).
  final bool isBest;
}

/// Points merged into one "N items" pill because their bubbles would
/// overlap on screen.
@visibleForTesting
final class ValueAxisCluster<T extends Object> extends ValueAxisItem<T> {
  const ValueAxisCluster(this.points, {required this.center, required this.containsBest});

  /// Members, highest value first.
  final List<ValueAxisPoint<T>> points;

  /// Value used by the collision maths (members' mid-range, or their mean
  /// after a pixel merge).
  final double center;

  /// Whether a member holds the highest value (best highlighting on).
  final bool containsBest;
}

/// The reference fused with the item whose pill or bubble it overlapped.
/// Replaces both: the reference marker is not drawn separately.
@visibleForTesting
final class ValueAxisReferenceCluster<T extends Object> extends ValueAxisItem<T> {
  const ValueAxisReferenceCluster({
    required this.reference,
    required this.points,
    required this.center,
    required this.containsBest,
  });

  /// The reference value, kept verbatim.
  final double reference;

  /// Absorbed members (one or more), highest value first.
  final List<ValueAxisPoint<T>> points;

  /// Mean of the reference and the members.
  final double center;

  /// Whether a member holds the highest value (best highlighting on).
  final bool containsBest;
}

/// Converts axis values to pixels for an axis [width] wide showing
/// [min]..[max].
final class _AxisScale {
  const _AxisScale(this.min, this.max, this.width);

  final double min;
  final double max;
  final double width;

  /// Position of [value] as a percentage of the axis (0–100).
  double percent(double value) => ValueAxisLayout.valueToPercent(value, min, max);

  /// X of [value] on the axis, in logical pixels.
  double px(double value) => percent(value) / 100 * width;
}

/// Layout maths of [ClusteredValueAxis].
@visibleForTesting
abstract final class ValueAxisLayout {
  /// Diameter of a point bubble.
  static const double bubbleSize = 30;

  /// Side of the reference marker square.
  static const double referenceSize = 32;

  /// Pass-1 threshold slack over one bubble width.
  static const double _collisionMargin = 1.1;

  /// Minimum free space between two rendered items.
  static const double _pillPadding = 6;

  /// Edge padding as a fraction of the data span, clamped so a single
  /// point or a wide spread still zoom sensibly.
  static const double _edgePaddingFraction = 0.10;
  static const double _edgePaddingMin = 0.015;
  static const double _edgePaddingMax = 0.060;

  /// Estimated widths of a cluster pill and a reference pill for a
  /// one-digit count without a star. Generous on purpose: under-estimating
  /// lets a pill overflow the right edge, over-estimating only adds margin.
  static const double _clusterPillBase = 116;
  static const double _referencePillBase = 134;

  /// Visible range: the union of [reference] and [values] plus 10 % of
  /// the data span on each side (clamped to [0.015, 0.06]), within [0, 1].
  /// No data at all gives the full (0, 1) range.
  static (double, double) computeRange(double? reference, List<double> values) {
    final List<double> all = <double>[?reference, ...values];
    if (all.isEmpty) return (0.0, 1.0);
    final double dataMin = all.reduce(math.min);
    final double dataMax = all.reduce(math.max);
    final double padding = ((dataMax - dataMin) * _edgePaddingFraction).clamp(_edgePaddingMin, _edgePaddingMax);
    return ((dataMin - padding).clamp(0.0, 1.0), (dataMax + padding).clamp(0.0, 1.0));
  }

  /// `(leftPercent, widthPercent)` of each band, in the order of [bands],
  /// clipped to [axisMin]..[axisMax]. A band outside the range gets
  /// `(0, 0)`; gaps between bands stay empty.
  static List<(double, double)> computeBandSpans(double axisMin, double axisMax, List<ValueBand> bands) {
    return <(double, double)>[
      for (final ValueBand band in bands) _bandSpan(band, axisMin, axisMax),
    ];
  }

  static (double, double) _bandSpan(ValueBand band, double axisMin, double axisMax) {
    final double range = axisMax - axisMin;
    final double start = math.max(band.from, axisMin);
    final double end = math.min(band.to, axisMax);
    if (range <= 0 || end <= start) return (0.0, 0.0);
    return ((start - axisMin) / range * 100, (end - start) / range * 100);
  }

  /// Items to render for [points] on an axis [axisWidthPx] wide showing
  /// [axisMin]..[axisMax].
  ///
  /// 1. Points closer than one bubble (×1.1) in value are grouped.
  /// 2. Neighbouring items whose estimated rendered widths overlap in
  ///    pixels are merged into one cluster.
  /// 3. When [reference] is set, inside the range and overlapping an item,
  ///    the closest such item is fused with it.
  ///
  /// When [highlightBest] is false, no item is flagged best.
  static List<ValueAxisItem<T>> computeItems<T extends Object>({
    required List<ValueAxisPoint<T>> points,
    required double axisMin,
    required double axisMax,
    required double axisWidthPx,
    double? reference,
    bool highlightBest = true,
  }) {
    assert(axisWidthPx.isFinite, "axisWidthPx must be finite, got $axisWidthPx");
    final double range = axisMax - axisMin;
    if (points.isEmpty || axisWidthPx <= 0 || range <= 0) return <ValueAxisItem<T>>[];
    final _AxisScale scale = _AxisScale(axisMin, axisMax, axisWidthPx);
    final double? best = highlightBest ? points.map((ValueAxisPoint<T> p) => p.value).reduce(math.max) : null;
    final double threshold = bubbleSize / (axisWidthPx / range) * _collisionMargin;

    final List<ValueAxisItem<T>> firstPass = <ValueAxisItem<T>>[
      for (final List<ValueAxisPoint<T>> group in _groupByThreshold(points, threshold)) _itemOf(group, best),
    ];
    final List<ValueAxisItem<T>> secondPass = _coalesce(firstPass, scale, best);
    if (reference == null) return secondPass;
    return _absorbReference(secondPass, reference, scale, best);
  }

  /// Pass 1: runs of points (ascending) whose consecutive gaps are below
  /// [threshold].
  static List<List<ValueAxisPoint<T>>> _groupByThreshold<T extends Object>(
    List<ValueAxisPoint<T>> points,
    double threshold,
  ) {
    final List<ValueAxisPoint<T>> sorted = List<ValueAxisPoint<T>>.of(points)
      ..sort((ValueAxisPoint<T> a, ValueAxisPoint<T> b) => a.value.compareTo(b.value));
    final List<List<ValueAxisPoint<T>>> groups = <List<ValueAxisPoint<T>>>[];
    List<ValueAxisPoint<T>> current = <ValueAxisPoint<T>>[sorted.first];
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i].value - sorted[i - 1].value < threshold) {
        current.add(sorted[i]);
      } else {
        groups.add(current);
        current = <ValueAxisPoint<T>>[sorted[i]];
      }
    }
    groups.add(current);
    return groups;
  }

  static ValueAxisItem<T> _itemOf<T extends Object>(List<ValueAxisPoint<T>> ascending, double? best) {
    if (ascending.length == 1) {
      return ValueAxisSingle<T>(ascending.first, isBest: ascending.first.value == best);
    }
    return ValueAxisCluster<T>(
      ascending.reversed.toList(growable: false),
      center: (ascending.first.value + ascending.last.value) / 2,
      containsBest: _containsBest(ascending, best),
    );
  }

  /// Pass 2: merges neighbours whose rendered rects would overlap. Cluster
  /// pills are wider than the bubbles pass 1 assumed, so adjacent items can
  /// still collide on screen.
  static List<ValueAxisItem<T>> _coalesce<T extends Object>(
    List<ValueAxisItem<T>> items,
    _AxisScale scale,
    double? best,
  ) {
    if (items.length <= 1) return items;
    final List<ValueAxisItem<T>> sorted = List<ValueAxisItem<T>>.of(items)
      ..sort((ValueAxisItem<T> a, ValueAxisItem<T> b) => _center(a).compareTo(_center(b)));
    final List<ValueAxisItem<T>> result = <ValueAxisItem<T>>[];
    ValueAxisItem<T> current = sorted.first;
    for (final ValueAxisItem<T> next in sorted.skip(1)) {
      if (_overlaps(current, next, scale)) {
        current = _merge(current, next, best);
      } else {
        result.add(current);
        current = next;
      }
    }
    result.add(current);
    return result;
  }

  static bool _overlaps<T extends Object>(ValueAxisItem<T> a, ValueAxisItem<T> b, _AxisScale scale) {
    final double gap = (scale.px(_center(b)) - scale.px(_center(a))).abs();
    return gap < (itemRenderedWidth(a) + itemRenderedWidth(b)) / 2 + _pillPadding;
  }

  static ValueAxisCluster<T> _merge<T extends Object>(ValueAxisItem<T> a, ValueAxisItem<T> b, double? best) {
    final List<ValueAxisPoint<T>> merged = <ValueAxisPoint<T>>[...membersOf(a), ...membersOf(b)]
      ..sort((ValueAxisPoint<T> x, ValueAxisPoint<T> y) => y.value.compareTo(x.value));
    return ValueAxisCluster<T>(
      merged,
      center: _mean(merged.map((ValueAxisPoint<T> p) => p.value)),
      containsBest: _containsBest(merged, best),
    );
  }

  /// Pass 3: fuses [reference] with the closest item it overlaps in pixels.
  /// A reference outside the visible range is never fused.
  static List<ValueAxisItem<T>> _absorbReference<T extends Object>(
    List<ValueAxisItem<T>> items,
    double reference,
    _AxisScale scale,
    double? best,
  ) {
    if (items.isEmpty || reference < scale.min || reference > scale.max) return items;
    final double referencePx = scale.px(reference);
    int? overlapIndex;
    double closestGap = double.infinity;
    for (int i = 0; i < items.length; i++) {
      final double gap = (scale.px(_center(items[i])) - referencePx).abs();
      final double minDistance = (referenceSize + itemRenderedWidth(items[i])) / 2 + _pillPadding;
      if (gap < minDistance && gap < closestGap) {
        closestGap = gap;
        overlapIndex = i;
      }
    }
    if (overlapIndex == null) return items;
    final List<ValueAxisPoint<T>> absorbed = membersOf(items[overlapIndex]);
    final ValueAxisReferenceCluster<T> fused = ValueAxisReferenceCluster<T>(
      reference: reference,
      points: absorbed,
      center: _mean(<double>[reference, for (final ValueAxisPoint<T> p in absorbed) p.value]),
      containsBest: _containsBest(absorbed, best),
    );
    return <ValueAxisItem<T>>[...items.sublist(0, overlapIndex), fused, ...items.sublist(overlapIndex + 1)];
  }

  static bool _containsBest<T extends Object>(List<ValueAxisPoint<T>> points, double? best) {
    return points.any((ValueAxisPoint<T> p) => p.value == best);
  }

  static double _mean(Iterable<double> values) {
    return values.reduce((double a, double b) => a + b) / values.length;
  }

  /// Value driving the collision maths of [item].
  static double _center<T extends Object>(ValueAxisItem<T> item) => switch (item) {
    ValueAxisSingle<T>(:final ValueAxisPoint<T> point) => point.value,
    ValueAxisCluster<T>(:final double center) => center,
    ValueAxisReferenceCluster<T>(:final double center) => center,
  };

  /// Points held by [item] (a single bubble holds one).
  static List<ValueAxisPoint<T>> membersOf<T extends Object>(ValueAxisItem<T> item) => switch (item) {
    ValueAxisSingle<T>(:final ValueAxisPoint<T> point) => <ValueAxisPoint<T>>[point],
    ValueAxisCluster<T>(:final List<ValueAxisPoint<T>> points) => points,
    ValueAxisReferenceCluster<T>(:final List<ValueAxisPoint<T>> points) => points,
  };

  /// Value at which [item] is drawn: the point, the highest member of a
  /// cluster, or the highest of the reference and its members, so a pill
  /// sits where its best member would.
  static double itemDisplayValue<T extends Object>(ValueAxisItem<T> item) => switch (item) {
    ValueAxisSingle<T>(:final ValueAxisPoint<T> point) => point.value,
    ValueAxisCluster<T>(:final List<ValueAxisPoint<T>> points) => points.first.value,
    ValueAxisReferenceCluster<T>(:final double reference, :final List<ValueAxisPoint<T>> points) =>
      points.isEmpty ? reference : math.max(reference, points.first.value),
  };

  /// Estimated rendered width of [item]: a bubble, or a pill growing 8 dp
  /// per extra count digit and 16 dp for the star.
  static double itemRenderedWidth<T extends Object>(ValueAxisItem<T> item) => switch (item) {
    ValueAxisSingle<T>() => bubbleSize,
    ValueAxisCluster<T>(:final List<ValueAxisPoint<T>> points, :final bool containsBest) =>
      _pillWidth(_clusterPillBase, points.length, star: containsBest),
    ValueAxisReferenceCluster<T>(:final List<ValueAxisPoint<T>> points, :final bool containsBest) =>
      _pillWidth(_referencePillBase, points.length, star: containsBest),
  };

  static double _pillWidth(double base, int count, {required bool star}) {
    return base + ("$count".length - 1) * 8 + (star ? 16 : 0);
  }

  /// Position of [value] as a percentage (0–100) of [axisMin]..[axisMax],
  /// clamped to the axis. An empty range gives 0.
  static double valueToPercent(double value, double axisMin, double axisMax) {
    assert(axisMin <= axisMax, "axisMin ($axisMin) must be <= axisMax ($axisMax)");
    final double range = axisMax - axisMin;
    if (range <= 0) return 0.0;
    return ((value - axisMin) / range * 100).clamp(0.0, 100.0);
  }

  /// Left edge of a [width]-wide slot centred on [centerPx], kept inside an
  /// axis [axisWidthPx] wide with [rightMargin] spare on the right.
  static double slotLeft(double centerPx, double width, double axisWidthPx, {double rightMargin = 0}) {
    final double maxLeft = math.max(0.0, axisWidthPx - width - rightMargin);
    return (centerPx - width / 2).clamp(0.0, maxLeft);
  }

  /// Horizontal hit box `(left, width)` of each element whose visible
  /// `(left, right)` extent is in [extents] (any order; results follow it)
  /// on an axis [axisWidthPx] wide.
  ///
  /// A box never crosses the middle of the gap to a neighbour's visible
  /// edge, nor the axis ends, so a tap inside a visible element always
  /// reaches that element. Within that room it is [target] wide and centred
  /// on its element, pushed away from a close neighbour, or narrowed to the
  /// room left between two close neighbours.
  static List<(double, double)> hitSlots(
    List<(double, double)> extents,
    double axisWidthPx, {
    double target = kMinTapTarget,
  }) {
    double center(int i) => (extents[i].$1 + extents[i].$2) / 2;
    final List<int> order = List<int>.generate(extents.length, (int i) => i)
      ..sort((int a, int b) => center(a).compareTo(center(b)));
    final List<(double, double)> slots = List<(double, double)>.filled(extents.length, (0.0, 0.0));
    for (int k = 0; k < order.length; k++) {
      final (double left, double right) = extents[order[k]];
      final double minLeft = k == 0 ? 0.0 : (extents[order[k - 1]].$2 + left) / 2;
      final double maxRight = k == order.length - 1 ? axisWidthPx : (right + extents[order[k + 1]].$1) / 2;
      final double room = maxRight - minLeft;
      slots[order[k]] = room <= target
          ? (minLeft, math.max(0.0, room))
          : ((center(order[k]) - target / 2).clamp(minLeft, maxRight - target), target);
    }
    return slots;
  }

  /// Rank of each point by value, keyed by id: 1 = highest value; equal
  /// values share a rank (1, 2, 2, 4).
  static Map<T, int> ranksByValue<T extends Object>(List<ValueAxisPoint<T>> points) {
    final List<ValueAxisPoint<T>> sorted = List<ValueAxisPoint<T>>.of(points)
      ..sort((ValueAxisPoint<T> a, ValueAxisPoint<T> b) => b.value.compareTo(a.value));
    final Map<T, int> ranks = <T, int>{};
    int rank = 0;
    for (int i = 0; i < sorted.length; i++) {
      if (i == 0 || sorted[i].value != sorted[i - 1].value) rank = i + 1;
      ranks[sorted[i].id] = rank;
    }
    return ranks;
  }
}

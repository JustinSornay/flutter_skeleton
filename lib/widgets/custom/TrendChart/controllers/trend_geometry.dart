// trend_geometry.dart
//
// TrendChartGeometry — pure geometry of TrendChart: the plotted spots, the
// Y range, the colour runs (favourable / adverse) split at the interpolated
// threshold crossings, the x of every adverse crossing, the room left above
// a Y value or right of an X value, and the X label step. No widgets, so it
// is unit-tested on its own.

part of "../index.dart";

/// One continuous run of the line on a single side of the threshold.
@visibleForTesting
@immutable
final class TrendChartSegment {
  const TrendChartSegment({required this.spots, required this.favourable});

  /// Points of the run, crossing points included.
  final List<FlSpot> spots;

  /// Whether the run is on the favourable side (always true without a
  /// threshold).
  final bool favourable;
}

/// Geometry of a [TrendChart] series.
@visibleForTesting
@immutable
final class TrendChartGeometry {
  const TrendChartGeometry._({
    required this.spots,
    required this.segments,
    required this.adverseCrossings,
    required this.minY,
    required this.maxY,
  });

  /// Geometry of [values] (oldest first, plotted at `x = index`).
  ///
  /// Without [threshold]: one favourable segment holding every value and no
  /// crossing. With it: a new segment starts at each side change, and the
  /// crossing spot `(prevX + (t - prevY) / (y - prevY), t)` ends the old
  /// segment and starts the new one. Each favourable → adverse change adds
  /// its x to [adverseCrossings]. Empty [values]: no segment.
  ///
  /// [minY] / [maxY] are kept when given; an open bound is fitted to the
  /// values and the threshold. When the span is not positive, the open
  /// bound is widened: both open → ±0.5, only [minY] open → `max - 1`,
  /// otherwise `min + 1`. The values and the threshold must lie within the
  /// explicit bounds (asserted): the chart does not clip, and a reference
  /// line outside the plot would vanish with its label.
  factory TrendChartGeometry.compute(
    List<double> values, {
    TrendThreshold? threshold,
    double? minY,
    double? maxY,
  }) {
    assert(
      values.every((double v) => (minY == null || v >= minY) && (maxY == null || v <= maxY)),
      "values must lie within the explicit minY / maxY",
    );
    assert(
      threshold == null || ((minY == null || threshold.value >= minY) && (maxY == null || threshold.value <= maxY)),
      "threshold.value must lie within the explicit minY / maxY",
    );
    final List<FlSpot> spots = _spots(values);
    final ({List<TrendChartSegment> segments, List<double> crossings}) split = threshold == null
        ? (
            segments: <TrendChartSegment>[
              if (values.isNotEmpty) TrendChartSegment(spots: spots, favourable: true),
            ],
            crossings: const <double>[],
          )
        : _split(values, threshold);
    final ({double min, double max}) range = _yRange(
      <double>[...values, if (threshold != null) threshold.value],
      minY,
      maxY,
    );
    return TrendChartGeometry._(
      spots: spots,
      segments: split.segments,
      adverseCrossings: split.crossings,
      minY: range.min,
      maxY: range.max,
    );
  }

  /// Every value at `x = index`: the one path of the line.
  final List<FlSpot> spots;

  /// Colour runs of the line, in x order; the first spot of a run is the
  /// last spot of the previous one.
  final List<TrendChartSegment> segments;

  /// X of every favourable → adverse crossing, in x order.
  final List<double> adverseCrossings;

  /// Lower bound of the plotted Y range.
  final double minY;

  /// Upper bound of the plotted Y range.
  final double maxY;

  /// Distance between the top of a plot [plotHeight] tall and the
  /// horizontal line at [y], in the same unit as [plotHeight].
  double roomAbove(double y, double plotHeight) => (maxY - y) / (maxY - minY) * plotHeight;

  /// Distance between the vertical line at [x] and the right edge of a plot
  /// [plotWidth] wide spanning every spot (at least two), in the same unit
  /// as [plotWidth].
  double roomRight(double x, double plotWidth) => (spots.last.x - x) / spots.last.x * plotWidth;

  /// X label step for [count] points: 1 up to 10, 5 up to 30, else 15.
  static double xLabelInterval(int count) {
    if (count <= 10) return 1;
    if (count <= 30) return 5;
    return 15;
  }

  static List<FlSpot> _spots(List<double> values) {
    return <FlSpot>[for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])];
  }

  static bool _isFavourable(double value, TrendThreshold threshold) {
    return threshold.higherIsBetter ? value >= threshold.value : value <= threshold.value;
  }

  static ({List<TrendChartSegment> segments, List<double> crossings}) _split(
    List<double> values,
    TrendThreshold threshold,
  ) {
    final List<TrendChartSegment> segments = <TrendChartSegment>[];
    final List<double> crossings = <double>[];
    if (values.isEmpty) return (segments: segments, crossings: crossings);

    final double t = threshold.value;
    List<FlSpot> current = <FlSpot>[];
    bool favourable = _isFavourable(values.first, threshold);
    for (int i = 0; i < values.length; i++) {
      final double y = values[i];
      if (_isFavourable(y, threshold) != favourable) {
        final double prevY = values[i - 1];
        final FlSpot cross = FlSpot((i - 1) + (t - prevY) / (y - prevY), t);
        current.add(cross);
        segments.add(TrendChartSegment(spots: current, favourable: favourable));
        if (favourable) crossings.add(cross.x);
        current = <FlSpot>[cross];
        favourable = !favourable;
      }
      current.add(FlSpot(i.toDouble(), y));
    }
    segments.add(TrendChartSegment(spots: current, favourable: favourable));
    return (segments: segments, crossings: crossings);
  }

  static ({double min, double max}) _yRange(List<double> fitted, double? minY, double? maxY) {
    final double lo = minY ?? (fitted.isEmpty ? 0 : fitted.reduce(math.min));
    final double hi = maxY ?? (fitted.isEmpty ? 0 : fitted.reduce(math.max));
    if (hi > lo) return (min: lo, max: hi);
    if (minY == null && maxY == null) return (min: lo - 0.5, max: hi + 0.5);
    if (minY == null) return (min: hi - 1, max: hi);
    return (min: lo, max: lo + 1);
  }
}

// radar_series.dart
//
// RadarSeries — one set of values drawn as a polygon on a RadarChartCard,
// keyed by RadarAxis.key, with an optional stroke colour. No UI here.

part of "index.dart";

/// A set of values drawn as one polygon on a [RadarChartCard].
@immutable
final class RadarSeries {
  /// Values keyed by [RadarAxis.key]. A missing key is drawn as 0; values
  /// are clamped to `[0, RadarChartCard.maxValue]`.
  final Map<String, double> values;

  /// Stroke colour; the fill is the same colour at 20 % (main series) or
  /// 25 % (comparison). Null → `cs.primary` for the main series,
  /// `cs.tertiary` for the comparison.
  final Color? color;

  const RadarSeries({
    required this.values,
    this.color,
  });
}

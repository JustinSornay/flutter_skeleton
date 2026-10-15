// radar_axis.dart
//
// RadarAxis — one spoke of a RadarChartCard: the key used to look up values
// in a RadarSeries, its localised title and an optional weight shown as a
// percentage suffix. No UI here.

part of "index.dart";

/// One spoke of a [RadarChartCard].
@immutable
final class RadarAxis {
  /// Identifier used to look up the value in [RadarSeries.values].
  final String key;

  /// Axis title drawn next to the spoke, already localised.
  final String label;

  /// Optional relative weight in `[0, 1]`. When set, the title becomes
  /// `custom.radar_chart_card.axis_weight` (`{label}`, `{percent}`).
  final double? weight;

  const RadarAxis({
    required this.key,
    required this.label,
    this.weight,
  }) : assert(weight == null || (weight >= 0 && weight <= 1), "weight must be in [0, 1]");
}

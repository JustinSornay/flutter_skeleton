// trend_threshold.dart
//
// TrendThreshold — the optional reference line of a TrendChart: its value,
// labels, polarity (which side is favourable) and the tones of each side.

part of "index.dart";

/// Reference line of a [TrendChart].
///
/// Splits the series into favourable and adverse segments at the exact
/// interpolated crossing point and marks every favourable → adverse crossing
/// with a labelled dashed vertical line.
@immutable
final class TrendThreshold {
  const TrendThreshold({
    required this.value,
    this.label,
    this.crossingLabel,
    this.higherIsBetter = true,
    this.favourableTone = StatusTone.success,
    this.adverseTone = StatusTone.danger,
  });

  /// Y value of the reference line.
  final double value;

  /// Label on the reference line; null uses `custom.trend_chart.threshold`.
  final String? label;

  /// Label on each adverse-crossing marker; null uses
  /// `custom.trend_chart.threshold_crossed`.
  final String? crossingLabel;

  /// true: values `>= value` are favourable and downward crossings are
  /// marked. false: values `<= value` are favourable and upward crossings
  /// are marked. A value exactly on the line is favourable either way.
  final bool higherIsBetter;

  /// Tone of the favourable segments (its `foreground`).
  final StatusTone favourableTone;

  /// Tone of the adverse segments and crossing markers (its `foreground`).
  final StatusTone adverseTone;
}

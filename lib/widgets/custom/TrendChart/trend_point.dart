// trend_point.dart
//
// TrendPoint — one (date, value) sample of a TrendChart series. Hosts map
// their own records to it.

part of "index.dart";

/// One sample of a [TrendChart] series.
///
/// Points are plotted in list order at `x = index` (evenly spaced, not
/// proportional to [date]); [date] only feeds the X axis label.
@immutable
final class TrendPoint {
  const TrendPoint({required this.date, required this.value});

  /// Date shown under the point on the X axis.
  final DateTime date;

  /// Plotted value; must be finite.
  final double value;
}

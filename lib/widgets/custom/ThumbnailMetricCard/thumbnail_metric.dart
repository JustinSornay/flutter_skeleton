// thumbnail_metric.dart
//
// Value class of ThumbnailMetricCard: ThumbnailMetric, one labelled value
// column with an optional status tone and its spoken name. No UI here.

part of "index.dart";

/// One value column of a [ThumbnailMetricCard]: [label] over [value], with
/// an optional [tone] marker before the value.
@immutable
final class ThumbnailMetric {
  /// Caption of the column, already localised (e.g. "Before", "Today").
  final String label;

  /// Value, already formatted by the host (e.g. "0.87", "12 ms"). The card
  /// never formats numbers.
  final String value;

  /// Status of the value: draws its [StatusTone.icon] in the tone
  /// foreground before [value]. Null → no marker.
  final StatusTone? tone;

  /// Spoken name of [tone] (e.g. "Good"), read between [label] and [value].
  /// Null or empty → the marker is not announced.
  final String? toneLabel;

  const ThumbnailMetric({
    required this.label,
    required this.value,
    this.tone,
    this.toneLabel,
  });
}

// values.dart
//
// Value classes of WeightedScoreCard: WeightedScoreComponent (one weighted
// input), WeightedScoreResult (what the evaluator returns) and the
// WeightedScoreEvaluator seam the host injects. No UI here.

part of "index.dart";

/// Async seam that scores a weight mix.
///
/// [weights] holds every component id of the card with its weight in
/// `[0, 1]`; the weights add up to 1. The host turns them into percentages
/// or request parameters itself.
typedef WeightedScoreEvaluator = Future<WeightedScoreResult> Function(Map<String, double> weights);

/// One weighted input of a [WeightedScoreCard].
@immutable
final class WeightedScoreComponent {
  /// Key of the component in the weights map and in
  /// [WeightedScoreResult.breakdown].
  final String id;

  /// Visible label (slider row, legend, slider semantics), already localised.
  final String label;

  /// Initial relative weight, `>= 0`. The card normalises all defaults to add
  /// up to 1 (equal weights when they are all 0).
  final double defaultWeight;

  /// Tone whose foreground colours the slider, slice and legend dot when
  /// [color] is null.
  final StatusTone? tone;

  /// Explicit data-palette colour; wins over [tone].
  final Color? color;

  const WeightedScoreComponent({
    required this.id,
    required this.label,
    required this.defaultWeight,
    this.tone,
    this.color,
  }) : assert(defaultWeight >= 0, "defaultWeight must be >= 0");
}

/// Result of a [WeightedScoreEvaluator].
@immutable
final class WeightedScoreResult {
  /// Overall score in `[0, 1]` (asserted; the card reports a violation
  /// through `FlutterError.reportError`), higher is better.
  final double score;

  /// Component id → that component's own score in `[0, 1]`. A missing id
  /// counts as 0; values are clamped to `[0, 1]`.
  final Map<String, double> breakdown;

  const WeightedScoreResult({
    required this.score,
    required this.breakdown,
  }) : assert(score >= 0 && score <= 1, "score must be in [0, 1]");
}

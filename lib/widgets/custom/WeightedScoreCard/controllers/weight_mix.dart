// weight_mix.dart
//
// WeightedScoreMix — the pure weight maths of WeightedScoreCard: normalising
// the defaults, rebalancing the others when one weight moves, and the donut
// shares. Used by view_model.dart and view.dart; public only for unit tests.

part of "../index.dart";

/// Pure weight maths of a [WeightedScoreCard]. Every method returns a new
/// list and never mutates its arguments.
@visibleForTesting
abstract final class WeightedScoreMix {
  /// [weights] scaled to add up to 1. Negative weights count as 0; when the
  /// weights add up to 0, every weight gets an equal share.
  static List<double> normalise(List<double> weights) {
    final List<double> positive = <double>[
      for (final double weight in weights) weight > 0 ? weight : 0,
    ];
    final double total = positive.fold(0, (double sum, double weight) => sum + weight);
    if (total <= 0) {
      return List<double>.filled(positive.length, positive.isEmpty ? 0 : 1 / positive.length, growable: true);
    }
    return <double>[for (final double weight in positive) weight / total];
  }

  /// [weights] (adding up to 1) after the weight at [index] moved to [value]
  /// (clamped to `[0, 1]`).
  ///
  /// The opposite change is spread over the other weights in proportion to
  /// their size. When the others are all 0, the remainder `1 - value` is
  /// split equally between them. The result is normalised.
  static List<double> rebalance(List<double> weights, int index, double value) {
    final double target = value.clamp(0.0, 1.0);
    final List<double> next = List<double>.of(weights);
    final double delta = target - next[index];
    next[index] = target;

    double othersSum = 0;
    for (int i = 0; i < next.length; i++) {
      if (i != index) othersSum += next[i];
    }

    for (int i = 0; i < next.length; i++) {
      if (i == index) continue;
      next[i] = othersSum > 0
          ? (next[i] - delta * next[i] / othersSum).clamp(0.0, 1.0)
          : (1 - target) / (next.length - 1);
    }
    return normalise(next);
  }

  /// Share of each component in the overall score [total]:
  /// `weights[i] × scores[i] / total`, with each score clamped to `[0, 1]`.
  /// Falls back to the [weights] themselves when [total] is not positive or
  /// every share is 0.
  static List<double> shares(List<double> weights, List<double> scores, double total) {
    if (total > 0) {
      final List<double> contributions = <double>[
        for (int i = 0; i < weights.length; i++) weights[i] * scores[i].clamp(0.0, 1.0) / total,
      ];
      if (contributions.any((double share) => share > 0)) return contributions;
    }
    return List<double>.of(weights);
  }
}

// weighted_score_card_mix_test.dart
//
// Unit tests for WeightedScoreMix
// (lib/widgets/custom/WeightedScoreCard/controllers/weight_mix.dart):
// normalising default weights, proportional rebalancing (including the
// all-others-zero split), and the donut shares with their fallbacks.

import "package:flutter_skeleton/widgets/custom/WeightedScoreCard/index.dart";
import "package:flutter_test/flutter_test.dart";

const double _epsilon = 1e-9;

double _sum(List<double> values) => values.fold(0, (double sum, double value) => sum + value);

void _expectList(List<double> actual, List<double> expected) {
  expect(actual.length, expected.length);
  for (int i = 0; i < expected.length; i++) {
    expect(actual[i], closeTo(expected[i], _epsilon), reason: "index $i");
  }
}

void main() {
  group("normalise", () {
    test("scales the weights to add up to 1", () {
      _expectList(WeightedScoreMix.normalise(<double>[20, 50, 20, 10]), <double>[0.2, 0.5, 0.2, 0.1]);
    });

    test("keeps weights that already add up to 1", () {
      _expectList(WeightedScoreMix.normalise(<double>[0.25, 0.75]), <double>[0.25, 0.75]);
    });

    test("splits equally when every weight is 0", () {
      _expectList(WeightedScoreMix.normalise(<double>[0, 0, 0, 0]), <double>[0.25, 0.25, 0.25, 0.25]);
    });

    test("counts negative weights as 0", () {
      _expectList(WeightedScoreMix.normalise(<double>[-1, 1, 3]), <double>[0, 0.25, 0.75]);
    });

    test("returns an empty list for no weights", () {
      expect(WeightedScoreMix.normalise(<double>[]), isEmpty);
    });

    test("does not mutate its argument", () {
      final List<double> weights = <double>[2, 2];
      WeightedScoreMix.normalise(weights);
      expect(weights, <double>[2, 2]);
    });
  });

  group("rebalance", () {
    test("spreads the change over the others in proportion", () {
      final List<double> next = WeightedScoreMix.rebalance(<double>[0.2, 0.5, 0.2, 0.1], 1, 0.6);
      _expectList(next, <double>[0.16, 0.6, 0.16, 0.08]);
      expect(_sum(next), closeTo(1, 1e-6));
    });

    test("gives equal others equal shares", () {
      final List<double> next = WeightedScoreMix.rebalance(<double>[0.25, 0.25, 0.25, 0.25], 0, 0.6);
      _expectList(next, <double>[0.6, 0.4 / 3, 0.4 / 3, 0.4 / 3]);
    });

    test("gives the freed weight back in proportion when a weight drops", () {
      final List<double> next = WeightedScoreMix.rebalance(<double>[0.5, 0.3, 0.2], 0, 0);
      _expectList(next, <double>[0, 0.6, 0.4]);
    });

    test("splits the remainder equally when the others are all 0", () {
      final List<double> next = WeightedScoreMix.rebalance(<double>[1, 0, 0, 0], 0, 0.4);
      _expectList(next, <double>[0.4, 0.2, 0.2, 0.2]);
    });

    test("moving one weight to 1 zeroes the others", () {
      final List<double> next = WeightedScoreMix.rebalance(<double>[0.2, 0.5, 0.3], 2, 1);
      _expectList(next, <double>[0, 0, 1]);
    });

    test("clamps the new value to [0, 1]", () {
      _expectList(WeightedScoreMix.rebalance(<double>[0.5, 0.5], 0, 1.5), <double>[1, 0]);
      _expectList(WeightedScoreMix.rebalance(<double>[0.5, 0.5], 0, -0.5), <double>[0, 1]);
    });

    test("keeps the total at 1 over many moves", () {
      List<double> weights = <double>[0.2, 0.5, 0.2, 0.1];
      for (int step = 0; step < 50; step++) {
        weights = WeightedScoreMix.rebalance(weights, step % 4, (step * 37 % 100) / 100);
        expect(_sum(weights), closeTo(1, 1e-6), reason: "step $step");
        expect(weights.every((double weight) => weight >= 0 && weight <= 1), isTrue, reason: "step $step");
      }
    });

    test("does not mutate its argument", () {
      final List<double> weights = <double>[0.5, 0.5];
      WeightedScoreMix.rebalance(weights, 0, 0.8);
      expect(weights, <double>[0.5, 0.5]);
    });
  });

  group("shares", () {
    test("weights each score by its weight over the total", () {
      final List<double> shares = WeightedScoreMix.shares(
        <double>[0.2, 0.5, 0.2, 0.1],
        <double>[0.9, 0.7, 0.5, 0.3],
        0.68,
      );
      _expectList(shares, <double>[0.18 / 0.68, 0.35 / 0.68, 0.1 / 0.68, 0.03 / 0.68]);
    });

    test("clamps the component scores to [0, 1]", () {
      _expectList(WeightedScoreMix.shares(<double>[0.5, 0.5], <double>[2, -1], 0.5), <double>[1, 0]);
    });

    test("falls back to the weights when the total is 0", () {
      _expectList(WeightedScoreMix.shares(<double>[0.3, 0.7], <double>[0.9, 0.1], 0), <double>[0.3, 0.7]);
    });

    test("falls back to the weights when every share is 0", () {
      _expectList(WeightedScoreMix.shares(<double>[0.3, 0.7], <double>[0, 0], 0.5), <double>[0.3, 0.7]);
    });
  });
}

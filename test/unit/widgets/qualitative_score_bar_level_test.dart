// qualitative_score_bar_level_test.dart
//
// Unit tests for ScoreLevel.resolve (lib/widgets/custom/QualitativeScoreBar/
// score_level.dart): exact boundaries, unordered scales, values below every
// step, clamping, NaN, ties, the empty-scale error and the default tone.

import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/QualitativeScoreBar/index.dart";
import "package:flutter_test/flutter_test.dart";

const ScoreLevel _high = ScoreLevel(min: 0.7, label: "High", tone: StatusTone.success);
const ScoreLevel _mid = ScoreLevel(min: 0.6, label: "Mid", tone: StatusTone.warning);
const ScoreLevel _low = ScoreLevel(min: 0.2, label: "Low", tone: StatusTone.danger);

const List<ScoreLevel> _scale = <ScoreLevel>[_high, _mid, _low];

void main() {
  group("ScoreLevel.resolve", () {
    test("a value equal to a min resolves to that step", () {
      expect(ScoreLevel.resolve(_scale, 0.7), same(_high));
      expect(ScoreLevel.resolve(_scale, 0.6), same(_mid));
      expect(ScoreLevel.resolve(_scale, 0.2), same(_low));
    });

    test("a value just below a min resolves to the step below", () {
      expect(ScoreLevel.resolve(_scale, 0.6999), same(_mid));
      expect(ScoreLevel.resolve(_scale, 0.5999), same(_low));
    });

    test("the order of the steps does not matter", () {
      const List<ScoreLevel> shuffled = <ScoreLevel>[_low, _high, _mid];
      expect(ScoreLevel.resolve(shuffled, 0.9), same(_high));
      expect(ScoreLevel.resolve(shuffled, 0.65), same(_mid));
      expect(ScoreLevel.resolve(shuffled, 0.3), same(_low));
    });

    test("a value below every min resolves to the lowest step", () {
      expect(ScoreLevel.resolve(_scale, 0.1), same(_low));
      expect(ScoreLevel.resolve(const <ScoreLevel>[_mid, _low, _high], 0.0), same(_low));
    });

    test("values outside [0, 1] are clamped", () {
      expect(ScoreLevel.resolve(_scale, 1.5), same(_high));
      expect(ScoreLevel.resolve(_scale, -0.3), same(_low));
      expect(ScoreLevel.resolve(_scale, double.infinity), same(_high));
    });

    test("a step whose min is above 1 is never reached", () {
      const ScoreLevel unreachable = ScoreLevel(min: 1.2, label: "Above");
      expect(ScoreLevel.resolve(const <ScoreLevel>[unreachable, _high], 5), same(_high));
    });

    test("NaN counts as 0", () {
      const ScoreLevel zero = ScoreLevel(min: 0, label: "Zero");
      expect(ScoreLevel.resolve(const <ScoreLevel>[_high, zero], double.nan), same(zero));
      expect(ScoreLevel.resolve(_scale, double.nan), same(_low));
    });

    test("among steps with the same min, the first one wins", () {
      const ScoreLevel first = ScoreLevel(min: 0.5, label: "First");
      const ScoreLevel second = ScoreLevel(min: 0.5, label: "Second");
      expect(ScoreLevel.resolve(const <ScoreLevel>[first, second], 0.8), same(first));
      expect(ScoreLevel.resolve(const <ScoreLevel>[first, second], 0.1), same(first));
    });

    test("a single step always resolves to itself", () {
      expect(ScoreLevel.resolve(const <ScoreLevel>[_mid], 0.0), same(_mid));
      expect(ScoreLevel.resolve(const <ScoreLevel>[_mid], 1.0), same(_mid));
    });

    test("an empty scale throws an ArgumentError", () {
      expect(() => ScoreLevel.resolve(const <ScoreLevel>[], 0.5), throwsArgumentError);
    });
  });

  test("tone defaults to neutral", () {
    const ScoreLevel level = ScoreLevel(min: 0, label: "Any");
    expect(level.tone, StatusTone.neutral);
  });
}

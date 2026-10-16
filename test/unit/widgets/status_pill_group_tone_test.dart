// status_pill_group_tone_test.dart
//
// Unit tests for StatusPillGroupItem.toneFromThresholds: the inclusive
// higher-is-better boundaries (>=), the exclusive lower-is-better boundaries
// (<), the NaN → neutral rule and the threshold-order asserts.

import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/StatusPillGroup/index.dart";
import "package:flutter_test/flutter_test.dart";

StatusTone _higher(double value) {
  return StatusPillGroupItem.toneFromThresholds(value, success: 99.5, warning: 95);
}

StatusTone _lower(double value) {
  return StatusPillGroupItem.toneFromThresholds(value, success: 300, warning: 1000, higherIsBetter: false);
}

void main() {
  group("higherIsBetter (default)", () {
    test("value >= success is success", () {
      expect(_higher(99.5), StatusTone.success);
      expect(_higher(100), StatusTone.success);
      expect(_higher(double.infinity), StatusTone.success);
    });

    test("warning <= value < success is warning", () {
      expect(_higher(99.4), StatusTone.warning);
      expect(_higher(95), StatusTone.warning);
    });

    test("value < warning is danger", () {
      expect(_higher(94.9), StatusTone.danger);
      expect(_higher(0), StatusTone.danger);
      expect(_higher(double.negativeInfinity), StatusTone.danger);
    });
  });

  group("higherIsBetter: false", () {
    test("value < success is success", () {
      expect(_lower(0), StatusTone.success);
      expect(_lower(299), StatusTone.success);
    });

    test("success <= value < warning is warning", () {
      expect(_lower(300), StatusTone.warning);
      expect(_lower(999), StatusTone.warning);
    });

    test("value >= warning is danger", () {
      expect(_lower(1000), StatusTone.danger);
      expect(_lower(double.infinity), StatusTone.danger);
    });
  });

  test("NaN is neutral in both directions", () {
    expect(_higher(double.nan), StatusTone.neutral);
    expect(_lower(double.nan), StatusTone.neutral);
  });

  test("equal thresholds leave no warning band", () {
    expect(StatusPillGroupItem.toneFromThresholds(5, success: 5, warning: 5), StatusTone.success);
    expect(StatusPillGroupItem.toneFromThresholds(4, success: 5, warning: 5), StatusTone.danger);
  });

  test("asserts that success is the better threshold", () {
    expect(
      () => StatusPillGroupItem.toneFromThresholds(1, success: 95, warning: 99.5),
      throwsAssertionError,
    );
    expect(
      () => StatusPillGroupItem.toneFromThresholds(1, success: 1000, warning: 300, higherIsBetter: false),
      throwsAssertionError,
    );
  });
}

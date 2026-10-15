// step_range_chart_captions_test.dart
//
// Unit tests for StepRangeCaptions
// (lib/widgets/custom/StepRangeChart/controllers/caption_style.dart): the
// size, weight and ink of the gutter captions (band labels in the band tone,
// bounds in the label ink) and of the name / sublabel / value under a plain,
// selected, emphasized, valueless or locked column, and the skipped empty
// sublabel.

import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/custom/StepRangeChart/index.dart";
import "package:flutter_test/flutter_test.dart";

const StepRangeColumn _plain = StepRangeColumn(label: "A", sublabel: "a", value: 10);
const StepRangeColumn _emphasized = StepRangeColumn(label: "A", sublabel: "a", value: 10, emphasized: true);
const StepRangeColumn _valueless = StepRangeColumn(label: "A", sublabel: "a");
const StepRangeColumn _emphasizedValueless = StepRangeColumn(label: "A", emphasized: true);
const StepRangeColumn _locked = StepRangeColumn.locked(label: "A", sublabel: "a");

void main() {
  group("gutter", () {
    test("band labels: 7 / w700 in the band tone", () {
      expect(StepRangeCaptions.bandLabel, (fontSize: 7.0, fontWeight: FontWeight.w700, ink: StepRangeInk.tone));
    });

    test("axis bounds: 7 / w700 in the label ink", () {
      expect(StepRangeCaptions.bound, (fontSize: 7.0, fontWeight: FontWeight.w700, ink: StepRangeInk.label));
    });
  });

  group("name", () {
    test("plain and emphasized: 9 / w700, label ink", () {
      const StepRangeCaptionStyle expected = (fontSize: 9, fontWeight: FontWeight.w700, ink: StepRangeInk.label);
      expect(StepRangeCaptions.name(_plain, selected: false), expected);
      expect(StepRangeCaptions.name(_emphasized, selected: false), expected);
    });

    test("selected: 9 / w800, line ink", () {
      expect(
        StepRangeCaptions.name(_plain, selected: true),
        (fontSize: 9.0, fontWeight: FontWeight.w800, ink: StepRangeInk.line),
      );
    });

    test("valueless and locked: muted w700, even when selected", () {
      const StepRangeCaptionStyle expected = (fontSize: 9, fontWeight: FontWeight.w700, ink: StepRangeInk.muted);
      for (final StepRangeColumn column in <StepRangeColumn>[_valueless, _locked]) {
        expect(StepRangeCaptions.name(column, selected: false), expected);
        expect(StepRangeCaptions.name(column, selected: true), expected);
      }
    });
  });

  group("sublabel", () {
    test("7 / w600 in the name's ink", () {
      expect(
        StepRangeCaptions.sublabel(_plain, selected: false),
        (fontSize: 7.0, fontWeight: FontWeight.w600, ink: StepRangeInk.label),
      );
      expect(
        StepRangeCaptions.sublabel(_plain, selected: true),
        (fontSize: 7.0, fontWeight: FontWeight.w600, ink: StepRangeInk.line),
      );
      expect(
        StepRangeCaptions.sublabel(_valueless, selected: true),
        (fontSize: 7.0, fontWeight: FontWeight.w600, ink: StepRangeInk.muted),
      );
      expect(StepRangeCaptions.sublabel(_locked, selected: false)?.ink, StepRangeInk.muted);
    });

    test("no sublabel or an empty one: nothing to paint", () {
      expect(StepRangeCaptions.sublabel(const StepRangeColumn(label: "A", value: 1), selected: false), isNull);
      expect(
        StepRangeCaptions.sublabel(const StepRangeColumn(label: "A", sublabel: "", value: 1), selected: true),
        isNull,
      );
    });
  });

  group("value", () {
    test("plain: 10 / w800, label ink", () {
      expect(
        StepRangeCaptions.value(_plain, selected: false),
        (fontSize: 10.0, fontWeight: FontWeight.w800, ink: StepRangeInk.label),
      );
    });

    test("emphasized: 11, emphasized ink", () {
      expect(
        StepRangeCaptions.value(_emphasized, selected: false),
        (fontSize: 11.0, fontWeight: FontWeight.w800, ink: StepRangeInk.emphasized),
      );
    });

    test("selected: 11, line ink, also over emphasis", () {
      const StepRangeCaptionStyle expected = (fontSize: 11, fontWeight: FontWeight.w800, ink: StepRangeInk.line);
      expect(StepRangeCaptions.value(_plain, selected: true), expected);
      expect(StepRangeCaptions.value(_emphasized, selected: true), expected);
    });

    test("valueless and locked: muted at 10, even when selected", () {
      const StepRangeCaptionStyle expected = (fontSize: 10, fontWeight: FontWeight.w800, ink: StepRangeInk.muted);
      for (final StepRangeColumn column in <StepRangeColumn>[_valueless, _locked]) {
        expect(StepRangeCaptions.value(column, selected: false), expected);
        expect(StepRangeCaptions.value(column, selected: true), expected);
      }
    });

    test("an emphasized valueless column keeps the larger size, muted", () {
      expect(
        StepRangeCaptions.value(_emphasizedValueless, selected: false),
        (fontSize: 11.0, fontWeight: FontWeight.w800, ink: StepRangeInk.muted),
      );
    });
  });
}

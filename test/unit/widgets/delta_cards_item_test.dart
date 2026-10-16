// delta_cards_item_test.dart
//
// Unit tests for the value classes of DeltaCards
// (lib/widgets/custom/DeltaCards/item.dart): the DeltaTrend caption keys, the
// DeltaCardItem main constructor defaults, the numeric factory (delta,
// rounding, arrow and sign, unit, trend from the rounded delta, adverse
// direction and tone, no int overflow at high precision or with large ints)
// and the categorical factory (shift vs stable, adverse flag and tone).

import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/DeltaCards/index.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("DeltaTrend", _trendTests);
  group("DeltaCardItem()", _mainConstructorTests);
  group("DeltaCardItem.numeric", _numericTests);
  group("DeltaCardItem.numeric rounding", _roundingTests);
  group("DeltaCardItem.numeric large values", _largeValueTests);
  group("DeltaCardItem.categorical", _categoricalTests);
}

void _trendTests() {
  test("each trend names its caption key", () {
    expect(DeltaTrend.values.map((DeltaTrend trend) => trend.captionKey), <String>[
      "custom.delta_cards.increase",
      "custom.delta_cards.decrease",
      "custom.delta_cards.stable",
      "custom.delta_cards.shift",
    ]);
  });
}

void _mainConstructorTests() {
  test("defaults to a stable, neutral item and keeps the fields as given", () {
    const DeltaCardItem plain = DeltaCardItem(label: "Users", value: "318");
    expect(plain.label, "Users");
    expect(plain.value, "318");
    expect(plain.trend, DeltaTrend.stable);
    expect(plain.tone, StatusTone.neutral);
    expect(plain.trendLabel, isNull);

    const DeltaCardItem custom = DeltaCardItem(
      label: "Users",
      value: "+12",
      trend: DeltaTrend.increase,
      tone: StatusTone.info,
      trendLabel: "Growing",
    );
    expect(custom.trend, DeltaTrend.increase);
    expect(custom.tone, StatusTone.info);
    expect(custom.trendLabel, "Growing");
  });
}

void _numericTests() {
  test("an adverse rise: arrow up, plus sign, unit appended, danger", () {
    final DeltaCardItem item = DeltaCardItem.numeric(
      label: "Load",
      before: 12.5,
      after: 15.8,
      unit: "%",
      higherIsWorse: true,
    );
    expect(item.label, "Load");
    expect(item.value, "↑ +3.3%");
    expect(item.trend, DeltaTrend.increase);
    expect(item.tone, StatusTone.danger);
    expect(item.trendLabel, isNull);
  });

  test("an adverse drop with 0 digits and a warning tone", () {
    final DeltaCardItem item = DeltaCardItem.numeric(
      label: "Volume",
      before: 680,
      after: 635,
      unit: " u",
      fractionDigits: 0,
      adverseTone: StatusTone.warning,
    );
    expect(item.value, "↓ -45 u");
    expect(item.trend, DeltaTrend.decrease);
    expect(item.tone, StatusTone.warning);
  });

  test("a favourable change is success in either direction", () {
    final DeltaCardItem rise = DeltaCardItem.numeric(label: "A", before: 1, after: 2);
    expect(rise.trend, DeltaTrend.increase);
    expect(rise.tone, StatusTone.success);

    final DeltaCardItem drop = DeltaCardItem.numeric(label: "A", before: 2, after: 1, higherIsWorse: true);
    expect(drop.trend, DeltaTrend.decrease);
    expect(drop.tone, StatusTone.success);
  });

  test("adverseTone is ignored for a favourable change", () {
    final DeltaCardItem item = DeltaCardItem.numeric(
      label: "A",
      before: 1,
      after: 2,
      adverseTone: StatusTone.warning,
    );
    expect(item.tone, StatusTone.success);
  });

  test("an equal pair is stable, success, shown as \"= 0.0\"", () {
    final DeltaCardItem item = DeltaCardItem.numeric(label: "A", before: 4, after: 4, unit: " ms");
    expect(item.value, "= 0.0 ms");
    expect(item.trend, DeltaTrend.stable);
    expect(item.tone, StatusTone.success);
  });

  test("trendLabel is passed through", () {
    final DeltaCardItem item = DeltaCardItem.numeric(label: "A", before: 1, after: 2, trendLabel: "Up");
    expect(item.trendLabel, "Up");
  });

  test("out-of-range fractionDigits and non-finite values are rejected", () {
    expect(() => DeltaCardItem.numeric(label: "A", before: 1, after: 2, fractionDigits: -1), throwsAssertionError);
    expect(() => DeltaCardItem.numeric(label: "A", before: 1, after: 2, fractionDigits: 21), throwsAssertionError);
    expect(() => DeltaCardItem.numeric(label: "A", before: double.nan, after: 2), throwsAssertionError);
    expect(() => DeltaCardItem.numeric(label: "A", before: 1, after: double.infinity), throwsAssertionError);
  });
}

void _roundingTests() {
  test("a delta that rounds to zero is stable, never a rise or a drop", () {
    final DeltaCardItem up = DeltaCardItem.numeric(label: "A", before: 12.50, after: 12.54, higherIsWorse: true);
    expect(up.value, "= 0.0");
    expect(up.trend, DeltaTrend.stable);
    expect(up.tone, StatusTone.success);

    final DeltaCardItem down = DeltaCardItem.numeric(label: "A", before: 12.54, after: 12.50);
    expect(down.value, "= 0.0");
    expect(down.trend, DeltaTrend.stable);
  });

  test("rounds instead of truncating", () {
    expect(DeltaCardItem.numeric(label: "A", before: 0, after: 44.6, fractionDigits: 0).value, "↑ +45");
    expect(DeltaCardItem.numeric(label: "A", before: 44.6, after: 0, fractionDigits: 0).value, "↓ -45");
    expect(DeltaCardItem.numeric(label: "A", before: 0, after: 0.06).value, "↑ +0.1");
  });

  test("fractionDigits sets the decimals shown", () {
    expect(DeltaCardItem.numeric(label: "A", before: 1, after: 2.5, fractionDigits: 2).value, "↑ +1.50");
    expect(DeltaCardItem.numeric(label: "A", before: 10, after: 7, fractionDigits: 0).value, "↓ -3");
  });
}

void _largeValueTests() {
  test("fractionDigits 19 and 20 keep the sign, trend and tone of a rise", () {
    final DeltaCardItem nineteen = DeltaCardItem.numeric(label: "A", before: 1, after: 2, fractionDigits: 19);
    expect(nineteen.value, "↑ +1.0000000000000000000");
    expect(nineteen.trend, DeltaTrend.increase);
    expect(nineteen.tone, StatusTone.success);

    final DeltaCardItem twenty = DeltaCardItem.numeric(label: "A", before: 2, after: 1, fractionDigits: 20);
    expect(twenty.value, "↓ -1.00000000000000000000");
    expect(twenty.trend, DeltaTrend.decrease);
    expect(twenty.tone, StatusTone.danger);
  });

  test("large int deltas do not overflow", () {
    final DeltaCardItem rise = DeltaCardItem.numeric(
      label: "A",
      before: 0,
      after: 100000000000000000,
      fractionDigits: 2,
    );
    expect(rise.value, "↑ +100000000000000000.00");
    expect(rise.trend, DeltaTrend.increase);
    expect(rise.tone, StatusTone.success);

    final DeltaCardItem drop = DeltaCardItem.numeric(
      label: "A",
      before: 100000000000000000,
      after: 0,
      fractionDigits: 2,
    );
    expect(drop.value, "↓ -100000000000000000.00");
    expect(drop.trend, DeltaTrend.decrease);

    // after - before exceeds the 64-bit int range.
    final DeltaCardItem wide = DeltaCardItem.numeric(
      label: "A",
      before: -9000000000000000000,
      after: 9000000000000000000,
      fractionDigits: 0,
    );
    expect(wide.value, "↑ +18000000000000000000");
    expect(wide.trend, DeltaTrend.increase);
  });

  test("a magnitude of 1e21 or more is written in exponential notation", () {
    final DeltaCardItem item = DeltaCardItem.numeric(label: "A", before: 0, after: 1e22);
    expect(item.value, "↑ +1e+22");
    expect(item.trend, DeltaTrend.increase);
  });
}

void _categoricalTests() {
  test("equal values are stable and success; value passed through", () {
    final DeltaCardItem item = DeltaCardItem.categorical(label: "Mode", before: "a", after: "a", value: "A");
    expect(item.label, "Mode");
    expect(item.value, "A");
    expect(item.trend, DeltaTrend.stable);
    expect(item.tone, StatusTone.success);
  });

  test("a change is a shift with the adverse tone by default", () {
    final DeltaCardItem item = DeltaCardItem.categorical(label: "Mode", before: "a", after: "b", value: "B");
    expect(item.trend, DeltaTrend.shift);
    expect(item.tone, StatusTone.danger);
  });

  test("changeIsAdverse false keeps a change success", () {
    final DeltaCardItem item = DeltaCardItem.categorical(
      label: "Mode",
      before: 1,
      after: 2,
      value: "Two",
      changeIsAdverse: false,
    );
    expect(item.trend, DeltaTrend.shift);
    expect(item.tone, StatusTone.success);
  });

  test("adverseTone and trendLabel are respected", () {
    final DeltaCardItem item = DeltaCardItem.categorical(
      label: "Mode",
      before: null,
      after: "b",
      value: "B",
      adverseTone: StatusTone.warning,
      trendLabel: "New",
    );
    expect(item.trend, DeltaTrend.shift);
    expect(item.tone, StatusTone.warning);
    expect(item.trendLabel, "New");
  });
}

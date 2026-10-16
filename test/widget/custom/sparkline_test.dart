// sparkline_test.dart
//
// Tests for Sparkline: the pure Y-range rule (explicit, fitted, flat, empty
// and one-sided cases), the empty box for short series, the plotted spots and
// X range, the default and custom line colour (light and dark themes), the
// stroke width, the hidden chrome, clipping only on out-of-range data, the
// explicit Y range, rebuilds, the decorative vs labelled semantics and the
// bounds and finite-value asserts.

import "dart:ui" show SemanticsFlag;

import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart" show SemanticsNode;
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/custom/Sparkline/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

/// Twelve values, oldest first.
final List<double> _rising = <double>[0.42, 0.45, 0.50, 0.58, 0.63, 0.70, 0.74, 0.78, 0.80, 0.82, 0.84, 0.88];

final List<double> _falling = <double>[0.88, 0.70, 0.52, 0.30];

LineChart _lineChart(WidgetTester tester) => tester.widget<LineChart>(find.byType(LineChart));

LineChartData _data(WidgetTester tester) => _lineChart(tester).data;

LineChartBarData _bar(WidgetTester tester) => _data(tester).lineBarsData.single;

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(Sparkline))).colorScheme;

({double min, double max}) _range(List<double> values, {double? minY, double? maxY}) {
  return Sparkline(values: values, minY: minY, maxY: maxY).yRange;
}

void main() {
  group("yRange", () {
    test("explicit bounds are used as is", () {
      expect(_range(_rising, minY: 0, maxY: 1), (min: 0.0, max: 1.0));
    });

    test("open bounds are fitted to the data", () {
      expect(_range(<double>[0.8, 0.2, 0.5]), (min: 0.2, max: 0.8));
    });

    test("a flat series with open bounds sits in the middle of a unit span", () {
      final ({double min, double max}) range = _range(<double>[0.72, 0.72]);
      expect(range.min, closeTo(0.22, 1e-9));
      expect(range.max, closeTo(1.22, 1e-9));
    });

    test("only minY given and the data at that bound widens the top", () {
      expect(_range(<double>[0, 0, 0], minY: 0), (min: 0.0, max: 1.0));
    });

    test("only maxY given and the data at that bound widens the bottom", () {
      expect(_range(<double>[1, 1], maxY: 1), (min: 0.0, max: 1.0));
    });

    test("one-sided bound with the data inside keeps the data edge", () {
      expect(_range(<double>[2, 5, 3], minY: 0), (min: 0.0, max: 5.0));
      expect(_range(<double>[2, 5, 3], maxY: 10), (min: 2.0, max: 10.0));
    });

    test("data entirely beyond a one-sided bound never yields a zero span", () {
      expect(_range(<double>[5, 6], maxY: 1), (min: 0.0, max: 1.0));
      expect(_range(<double>[-3, -2], minY: 0), (min: 0.0, max: 1.0));
    });

    test("an empty series counts as 0", () {
      expect(_range(<double>[]), (min: -0.5, max: 0.5));
      expect(_range(<double>[], minY: 2), (min: 2.0, max: 3.0));
    });
  });

  group("short series", () {
    testWidgets("no value renders an empty box of the default size", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: Sparkline(values: <double>[])));

      expect(find.byType(LineChart), findsNothing);
      expect(tester.getSize(find.byType(Sparkline)), const Size(56, 24));
    });

    testWidgets("a single value renders an empty box of the given size", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: Sparkline(values: <double>[0.5], width: 120, height: 32)));

      expect(find.byType(LineChart), findsNothing);
      expect(tester.getSize(find.byType(Sparkline)), const Size(120, 32));
    });
  });

  group("chart", () {
    testWidgets("plots each value at its index, oldest first", (WidgetTester tester) async {
      await pumpApp(tester, Center(child: Sparkline(values: _rising)));

      expect(find.byType(LineChart), findsOneWidget);
      expect(tester.getSize(find.byType(Sparkline)), const Size(56, 24));
      final List<FlSpot> spots = _bar(tester).spots;
      expect(spots.map((FlSpot s) => s.x).toList(), <double>[for (int i = 0; i < 12; i++) i.toDouble()]);
      expect(spots.map((FlSpot s) => s.y).toList(), _rising);
      expect(_data(tester).minX, 0);
      expect(_data(tester).maxX, 11);
    });

    testWidgets("defaults to the primary colour and a 1.5 round-capped stroke", (WidgetTester tester) async {
      await pumpApp(tester, Center(child: Sparkline(values: _rising)));

      final LineChartBarData bar = _bar(tester);
      expect(bar.color, _scheme(tester).primary);
      expect(bar.barWidth, 1.5);
      expect(bar.isStrokeCapRound, isTrue);
    });

    testWidgets("passes a custom colour and stroke width through", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Center(
          child: Builder(
            builder: (BuildContext context) => Sparkline(
              values: _falling,
              color: Theme.of(context).colorScheme.error,
              strokeWidth: 3,
            ),
          ),
        ),
      );

      expect(_bar(tester).color, _scheme(tester).error);
      expect(_bar(tester).barWidth, 3);
    });

    testWidgets("hides every piece of chrome and does not animate", (WidgetTester tester) async {
      await pumpApp(tester, Center(child: Sparkline(values: _rising)));

      final LineChartData data = _data(tester);
      expect(data.titlesData.leftTitles.sideTitles.showTitles, isFalse);
      expect(data.titlesData.rightTitles.sideTitles.showTitles, isFalse);
      expect(data.titlesData.topTitles.sideTitles.showTitles, isFalse);
      expect(data.titlesData.bottomTitles.sideTitles.showTitles, isFalse);
      expect(data.gridData.show, isFalse);
      expect(data.borderData.show, isFalse);
      expect(data.lineTouchData.enabled, isFalse);
      expect(_bar(tester).dotData.show, isFalse);
      expect(_bar(tester).belowBarData.show, isFalse);
      expect(_lineChart(tester).duration, Duration.zero);
    });

    testWidgets("passes an explicit Y range through and does not clip data inside it", (WidgetTester tester) async {
      await pumpApp(tester, Center(child: Sparkline(values: _rising, minY: 0, maxY: 1)));

      final LineChartData data = _data(tester);
      expect(data.minY, 0);
      expect(data.maxY, 1);
      expect(data.clipData, const FlClipData.none());
    });

    testWidgets("fits the Y range to the data when no bound is given, without clipping", (WidgetTester tester) async {
      await pumpApp(tester, Center(child: Sparkline(values: _falling)));

      expect(_data(tester).minY, 0.30);
      expect(_data(tester).maxY, 0.88);
      expect(_data(tester).clipData, const FlClipData.none());
    });

    testWidgets("clips vertically when a value is outside the plotted range", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: Sparkline(values: <double>[0.2, 1.4, -0.3], minY: 0, maxY: 1)));

      expect(_data(tester).clipData, const FlClipData.vertical());

      await pumpApp(tester, const Center(child: Sparkline(values: <double>[5, 6], maxY: 1)));

      expect(_data(tester).clipData, const FlClipData.vertical());
    });

    testWidgets("rebuilds with a new series", (WidgetTester tester) async {
      await pumpApp(tester, Center(child: Sparkline(values: _rising)));
      await pumpApp(tester, Center(child: Sparkline(values: _falling)));

      expect(_bar(tester).spots.map((FlSpot s) => s.y).toList(), _falling);
      expect(_data(tester).maxX, 3);
    });

    testWidgets("dark theme: defaults to the dark primary colour", (WidgetTester tester) async {
      final ThemeData dark = AppTheme.dark();
      await pumpApp(tester, Center(child: Sparkline(values: _rising)), theme: dark);

      expect(_bar(tester).color, dark.colorScheme.primary);
      expect(tester.takeException(), isNull);
    });
  });

  group("semantics", () {
    testWidgets("is decorative without a label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, Center(child: Sparkline(values: _rising)));

      expect(find.semantics.byFlag(SemanticsFlag.isImage), findsNothing);
      final SemanticsNode node = tester.getSemantics(find.byType(Sparkline));
      expect(node, isNot(isSemantics(isImage: true)));
      expect(node.label, isEmpty);
      handle.dispose();
    });

    testWidgets("exposes one image node with the label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, Center(child: Sparkline(values: _rising, semanticsLabel: "Trend")));

      expect(find.bySemanticsLabel("Trend"), findsOneWidget);
      expect(tester.getSemantics(find.bySemanticsLabel("Trend")), isSemantics(label: "Trend", isImage: true));
      handle.dispose();
    });

    testWidgets("keeps the label on a series too short to draw", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const Center(child: Sparkline(values: <double>[0.5], semanticsLabel: "No data")));

      expect(find.byType(LineChart), findsNothing);
      expect(find.bySemanticsLabel("No data"), findsOneWidget);
      handle.dispose();
    });
  });

  test("asserts that an explicit minY is below maxY", () {
    expect(() => Sparkline(values: _rising, minY: 1, maxY: 0), throwsA(isA<AssertionError>()));
    expect(() => Sparkline(values: _rising, minY: 1, maxY: 1), throwsA(isA<AssertionError>()));
  });

  testWidgets("asserts that every value is finite", (WidgetTester tester) async {
    await pumpApp(tester, const Center(child: Sparkline(values: <double>[0.1, double.nan, 0.3])));
    expect(tester.takeException(), isA<AssertionError>());

    await pumpApp(tester, const Center(child: Sparkline(values: <double>[0.1, double.infinity])));
    expect(tester.takeException(), isA<AssertionError>());
  });
}

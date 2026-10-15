// severity_badge_test.dart
//
// Tests for SeverityBadge and SeverityLevel: the value-to-level mapping and
// its threshold assert, the level → tone / i18n key mapping, the composed
// StatusPill (text, icon, tone colours), content-hugging width, the empty
// state, single-node semantics with its default and override labels, and the
// dark theme for every level.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/SeverityBadge/index.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _label = "Response time";
const String _value = "−22 %";

Finder _inBadge(Finder matching) {
  return find.descendant(of: find.byType(SeverityBadge), matching: matching);
}

StatusPill _pill(WidgetTester tester) => tester.widget<StatusPill>(_inBadge(find.byType(StatusPill)));

Container _container(WidgetTester tester) => tester.widget<Container>(_inBadge(find.byType(Container)));

Text _text(WidgetTester tester, String text) => tester.widget<Text>(find.text(text));

ToneColors _colors(WidgetTester tester, StatusTone tone) {
  return StatusTones.colorsOf(tester.element(find.byType(SeverityBadge)), tone);
}

SeverityLevel _level(double value) => SeverityLevel.fromValue(value, mediumAt: 0.08, highAt: 0.15);

void main() {
  group("SeverityLevel", () {
    test("fromValue: low below mediumAt, medium from mediumAt, high from highAt", () {
      expect(_level(0.04), SeverityLevel.low);
      expect(_level(0.08), SeverityLevel.medium);
      expect(_level(0.10), SeverityLevel.medium);
      expect(_level(0.15), SeverityLevel.high);
      expect(_level(0.22), SeverityLevel.high);
      expect(_level(-1), SeverityLevel.low);
    });

    test("fromValue: NaN maps to low", () {
      expect(_level(double.nan), SeverityLevel.low);
    });

    test("fromValue: equal thresholds skip medium", () {
      expect(SeverityLevel.fromValue(0.49, mediumAt: 0.5, highAt: 0.5), SeverityLevel.low);
      expect(SeverityLevel.fromValue(0.5, mediumAt: 0.5, highAt: 0.5), SeverityLevel.high);
    });

    test("fromValue asserts when mediumAt exceeds highAt", () {
      expect(() => SeverityLevel.fromValue(0.1, mediumAt: 0.2, highAt: 0.1), throwsAssertionError);
    });

    test("levels map to success / warning / danger", () {
      expect(SeverityLevel.low.tone, StatusTone.success);
      expect(SeverityLevel.medium.tone, StatusTone.warning);
      expect(SeverityLevel.high.tone, StatusTone.danger);
    });

    test("semanticsKey is custom.severity_badge.<level>", () {
      for (final SeverityLevel level in SeverityLevel.values) {
        expect(level.semanticsKey, "custom.severity_badge.${level.name}");
      }
    });
  });

  group("pill", () {
    testWidgets("composes a StatusPill in the level tone with the tone icon", (WidgetTester tester) async {
      await pumpApp(tester, const SeverityBadge(label: _label, severity: SeverityLevel.medium));

      final StatusPill pill = _pill(tester);
      expect(pill.label, _label);
      expect(pill.tone, StatusTone.warning);
      expect(pill.icon, StatusTone.warning.icon);
      expect(find.text(_label), findsOneWidget);
      expect(_inBadge(find.byIcon(StatusTone.warning.icon)), findsOneWidget);
    });

    testWidgets("valueLabel is shown after the label", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const SeverityBadge(label: _label, severity: SeverityLevel.high, valueLabel: _value),
      );

      expect(find.text("$_label $_value"), findsOneWidget);
      expect(find.text(_label), findsNothing);
    });

    testWidgets("an empty valueLabel is left out", (WidgetTester tester) async {
      await pumpApp(tester, const SeverityBadge(label: _label, severity: SeverityLevel.high, valueLabel: ""));

      expect(find.text(_label), findsOneWidget);
    });

    testWidgets("an empty label still shows the value", (WidgetTester tester) async {
      await pumpApp(tester, const SeverityBadge(label: "", severity: SeverityLevel.low, valueLabel: _value));

      expect(find.text(_value), findsOneWidget);
    });

    testWidgets("every level paints onContainer on the tone container", (WidgetTester tester) async {
      for (final SeverityLevel level in SeverityLevel.values) {
        await pumpApp(tester, SeverityBadge(label: _label, severity: level));
        final ToneColors colors = _colors(tester, level.tone);

        expect((_container(tester).decoration! as BoxDecoration).color, colors.container, reason: "$level");
        expect(_text(tester, _label).style?.color, colors.onContainer, reason: "$level");
        expect(tester.widget<Icon>(_inBadge(find.byType(Icon))).color, colors.onContainer, reason: "$level");
      }
    });

    testWidgets("hugs its content inside a wide column", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[SeverityBadge(label: _label, severity: SeverityLevel.low)],
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(SeverityBadge)).width, lessThan(400));
    });

    testWidgets("a long text ellipsizes in a narrow parent", (WidgetTester tester) async {
      const String long = "Average response time over the last period";
      await pumpApp(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 120, child: SeverityBadge(label: long, severity: SeverityLevel.high)),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(SeverityBadge)).width, lessThanOrEqualTo(120));
      expect(_text(tester, long).overflow, TextOverflow.ellipsis);
    });

    testWidgets("an empty label without value renders nothing", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: SeverityBadge(label: "", severity: SeverityLevel.high)));

      expect(tester.getSize(find.byType(SeverityBadge)), Size.zero);
      expect(_inBadge(find.byType(Text)), findsNothing);
      expect(_inBadge(find.byType(Icon)), findsNothing);
    });
  });

  group("semantics", () {
    testWidgets("default label is label, value, level name — announced once", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const SeverityBadge(label: _label, severity: SeverityLevel.high, valueLabel: _value),
      );

      expect(find.bySemanticsLabel("$_label, $_value, custom.severity_badge.high"), findsOneWidget);
      expect(find.bySemanticsLabel("$_label $_value"), findsNothing);
      handle.dispose();
    });

    testWidgets("default label without value is label, level name", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      for (final SeverityLevel level in SeverityLevel.values) {
        await pumpApp(tester, SeverityBadge(label: _label, severity: level));

        expect(find.bySemanticsLabel("$_label, ${level.semanticsKey}"), findsOneWidget, reason: "$level");
        expect(find.bySemanticsLabel(_label), findsNothing, reason: "$level");
      }
      handle.dispose();
    });

    testWidgets("semanticsLabel overrides the default", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const SeverityBadge(
          label: _label,
          severity: SeverityLevel.medium,
          valueLabel: _value,
          semanticsLabel: "Slow responses",
        ),
      );

      expect(find.bySemanticsLabel("Slow responses"), findsOneWidget);
      expect(find.bySemanticsLabel("$_label, $_value, custom.severity_badge.medium"), findsNothing);
      handle.dispose();
    });

    testWidgets("an empty semanticsLabel falls back to the default", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const SeverityBadge(label: _label, severity: SeverityLevel.low, semanticsLabel: ""),
      );

      expect(find.bySemanticsLabel("$_label, custom.severity_badge.low"), findsOneWidget);
      handle.dispose();
    });
  });

  group("dark theme", () {
    testWidgets("every level renders with the dark tone colours", (WidgetTester tester) async {
      for (final SeverityLevel level in SeverityLevel.values) {
        await pumpApp(
          tester,
          SeverityBadge(label: _label, severity: level, valueLabel: _value),
          theme: AppTheme.dark(),
        );
        final ToneColors colors = _colors(tester, level.tone);

        expect(Theme.of(tester.element(find.byType(SeverityBadge))).colorScheme.brightness, Brightness.dark);
        expect(tester.takeException(), isNull, reason: "$level");
        expect((_container(tester).decoration! as BoxDecoration).color, colors.container, reason: "$level");
        expect(_text(tester, "$_label $_value").style?.color, colors.onContainer, reason: "$level");
      }
    });
  });
}

// metric_label_test.dart
//
// Widget tests for MetricLabel: upper-cased label, optional 12 dp icon with
// its 4 dp gap, ColorScheme typography tokens, single-node semantics in the
// original casing, wrapping onto several lines under narrow parents, text
// scaling, and the dark theme.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/MetricLabel/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _label = "Temperature";
const String _shown = "TEMPERATURE";

Finder _inLabel(Finder matching) {
  return find.descendant(of: find.byType(MetricLabel), matching: matching);
}

Text _text(WidgetTester tester) => tester.widget<Text>(find.text(_shown));

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(MetricLabel))).colorScheme;

void main() {
  group("structure", () {
    testWidgets("shows the label in upper case", (WidgetTester tester) async {
      await pumpApp(tester, const MetricLabel(label: _label));

      expect(find.text(_shown), findsOneWidget);
      expect(find.text(_label), findsNothing);
    });

    testWidgets("renders no icon by default", (WidgetTester tester) async {
      await pumpApp(tester, const MetricLabel(label: _label));

      expect(_inLabel(find.byType(Icon)), findsNothing);
    });

    testWidgets("renders a 12 dp leading icon followed by a 4 dp gap", (WidgetTester tester) async {
      await pumpApp(tester, const MetricLabel(label: _label, icon: Icons.speed));

      final Finder icon = find.byIcon(Icons.speed);
      expect(icon, findsOneWidget);
      expect(tester.widget<Icon>(icon).size, 12);

      final double gap = tester.getTopLeft(find.text(_shown)).dx - tester.getTopRight(icon).dx;
      expect(gap, kDefaultPadding / 2);
    });

    testWidgets("the label fills the remaining width", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Center(
          child: SizedBox(width: 200, child: MetricLabel(label: _label, icon: Icons.speed)),
        ),
      );

      expect(tester.getSize(find.text(_shown)).width, 200 - 12 - kDefaultPadding / 2);
    });
  });

  group("theme tokens", () {
    testWidgets("label is 10 / w600 / spacing 0.5 in onSurfaceVariant", (WidgetTester tester) async {
      await pumpApp(tester, const MetricLabel(label: _label));

      final TextStyle? style = _text(tester).style;
      expect(style?.fontSize, 10);
      expect(style?.fontWeight, FontWeight.w600);
      expect(style?.letterSpacing, 0.5);
      expect(style?.color, _scheme(tester).onSurfaceVariant);
    });

    testWidgets("icon uses onSurfaceVariant", (WidgetTester tester) async {
      await pumpApp(tester, const MetricLabel(label: _label, icon: Icons.speed));

      expect(tester.widget<Icon>(find.byIcon(Icons.speed)).color, _scheme(tester).onSurfaceVariant);
    });

    testWidgets("dark theme: colours follow the dark scheme", (WidgetTester tester) async {
      await pumpApp(tester, const MetricLabel(label: _label, icon: Icons.speed), theme: AppTheme.dark());

      final ColorScheme cs = _scheme(tester);
      expect(cs.brightness, Brightness.dark);
      expect(_text(tester).style?.color, cs.onSurfaceVariant);
      expect(tester.widget<Icon>(find.byIcon(Icons.speed)).color, cs.onSurfaceVariant);
      expect(tester.takeException(), isNull);
    });
  });

  group("semantics", () {
    testWidgets("exposes the original casing once", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const MetricLabel(label: _label, icon: Icons.speed));

      expect(find.bySemanticsLabel(_label), findsOneWidget);
      expect(find.bySemanticsLabel(_shown), findsNothing);
      handle.dispose();
    });

    testWidgets("two labels stay two separate nodes", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const Column(
          children: <Widget>[
            MetricLabel(label: "First"),
            MetricLabel(label: "Second"),
          ],
        ),
      );

      expect(find.bySemanticsLabel("First"), findsOneWidget);
      expect(find.bySemanticsLabel("Second"), findsOneWidget);
      handle.dispose();
    });
  });

  group("layout", () {
    testWidgets("a long label wraps onto several lines in a narrow parent without overflow", (
      WidgetTester tester,
    ) async {
      Future<Size> labelSize(String label) async {
        await pumpApp(
          tester,
          Center(
            child: SizedBox(width: 120, child: MetricLabel(label: label, icon: Icons.speed)),
          ),
        );
        expect(tester.takeException(), isNull);
        return tester.getSize(find.text(label.toUpperCase()));
      }

      final Size single = await labelSize("Ab");
      final Size long = await labelSize("Average value over the selected period and area");

      expect(long.width, lessThanOrEqualTo(120));
      expect(long.height, greaterThan(single.height * 1.5));
    });

    testWidgets("survives 2x text scaling", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: SizedBox(width: 160, child: MetricLabel(label: _label, icon: Icons.speed)),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_shown), findsOneWidget);
    });
  });
}

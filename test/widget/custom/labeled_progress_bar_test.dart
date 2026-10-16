// labeled_progress_bar_test.dart
//
// Widget tests for LabeledProgressBar: the label and the default percentage,
// clamping (above 1, below 0, NaN, infinity), the valueLabel override, the
// fill colour (tone default, other tones, colour override), the shared bar
// tokens (track, radius, thickness), the text styles and gaps, the single
// semantics node, the locale-aware percentage, a narrow layout with a long
// label, the tone icon paired with non-primary tones, rebuilds and the dark
// theme.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/LabeledProgressBar/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:intl/intl.dart";

import "../../helpers/widget_test_helpers.dart";

const String _label = "Completion";

Finder _inBar(Finder matching) {
  return find.descendant(of: find.byType(LabeledProgressBar), matching: matching);
}

LinearProgressIndicator _indicator(WidgetTester tester) {
  return tester.widget<LinearProgressIndicator>(_inBar(find.byType(LinearProgressIndicator)));
}

Color? _fill(WidgetTester tester) {
  final Animation<Color?>? valueColor = _indicator(tester).valueColor;
  return valueColor?.value;
}

Text _text(WidgetTester tester, String data) => tester.widget<Text>(_inBar(find.text(data)));

BuildContext _context(WidgetTester tester) => tester.element(find.byType(LabeledProgressBar));

ColorScheme _scheme(WidgetTester tester) => Theme.of(_context(tester)).colorScheme;

/// Pumps the bar; [tone] is forwarded only when set, so the widget's own
/// default is exercised otherwise.
Future<void> _pumpBar(
  WidgetTester tester, {
  required double value,
  StatusTone? tone,
  Color? color,
  String? valueLabel,
  ThemeData? theme,
}) {
  final LabeledProgressBar bar = tone == null
      ? LabeledProgressBar(label: _label, value: value, color: color, valueLabel: valueLabel)
      : LabeledProgressBar(label: _label, value: value, tone: tone, color: color, valueLabel: valueLabel);
  return pumpApp(
    tester,
    Padding(padding: const EdgeInsets.all(kDefaultPadding * 2), child: bar),
    theme: theme,
  );
}

void main() {
  group("LabeledProgressBar content", () {
    testWidgets("shows the label and the value as a percentage", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.73);

      expect(_inBar(find.text(_label)), findsOneWidget);
      expect(_inBar(find.text("73%")), findsOneWidget);
      expect(_indicator(tester).value, 0.73);
    });

    testWidgets("rounds the percentage to a whole number", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.456);

      expect(_inBar(find.text("46%")), findsOneWidget);
      expect(_indicator(tester).value, 0.456);
    });

    testWidgets("shows 0% and 100% at the bounds", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0);
      expect(_inBar(find.text("0%")), findsOneWidget);
      expect(_indicator(tester).value, 0.0);

      await _pumpBar(tester, value: 1);
      expect(_inBar(find.text("100%")), findsOneWidget);
      expect(_indicator(tester).value, 1.0);
    });

    testWidgets("valueLabel replaces the percentage", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.6, valueLabel: "3/5");

      expect(_inBar(find.text("3/5")), findsOneWidget);
      expect(_inBar(find.text("60%")), findsNothing);
      expect(_indicator(tester).value, 0.6);
    });

    testWidgets("updates the bar and the text on rebuild", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.2);
      expect(_inBar(find.text("20%")), findsOneWidget);

      await _pumpBar(tester, value: 0.9);
      expect(_inBar(find.text("90%")), findsOneWidget);
      expect(_inBar(find.text("20%")), findsNothing);
      expect(_indicator(tester).value, 0.9);
    });
  });

  group("LabeledProgressBar clamping", () {
    testWidgets("values above 1 are clamped to 1", (WidgetTester tester) async {
      await _pumpBar(tester, value: 1.4);

      expect(_indicator(tester).value, 1.0);
      expect(_inBar(find.text("100%")), findsOneWidget);
      expect(_inBar(find.text("140%")), findsNothing);
    });

    testWidgets("values below 0 are clamped to 0", (WidgetTester tester) async {
      await _pumpBar(tester, value: -0.2);

      expect(_indicator(tester).value, 0.0);
      expect(_inBar(find.text("0%")), findsOneWidget);
    });

    testWidgets("NaN renders as 0", (WidgetTester tester) async {
      await _pumpBar(tester, value: double.nan);

      expect(_indicator(tester).value, 0.0);
      expect(_inBar(find.text("0%")), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("infinities are clamped", (WidgetTester tester) async {
      await _pumpBar(tester, value: double.infinity);
      expect(_indicator(tester).value, 1.0);
      expect(_inBar(find.text("100%")), findsOneWidget);

      await _pumpBar(tester, value: double.negativeInfinity);
      expect(_indicator(tester).value, 0.0);
      expect(_inBar(find.text("0%")), findsOneWidget);
    });
  });

  group("LabeledProgressBar colours", () {
    testWidgets("fills with cs.primary by default, without a tone icon", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.5);

      expect(tester.widget<LabeledProgressBar>(find.byType(LabeledProgressBar)).tone, StatusTone.primary);
      expect(_fill(tester), _scheme(tester).primary);
      expect(_inBar(find.byType(Icon)), findsNothing);
    });

    for (final StatusTone tone in StatusTone.values) {
      testWidgets("fills with the ${tone.name} tone foreground", (WidgetTester tester) async {
        await _pumpBar(tester, value: 0.5, tone: tone);

        expect(_fill(tester), StatusTones.colorsOf(_context(tester), tone).foreground);
      });
    }

    for (final StatusTone tone in StatusTone.values.where((StatusTone t) => t != StatusTone.primary)) {
      testWidgets("pairs the ${tone.name} tone with its icon", (WidgetTester tester) async {
        await _pumpBar(tester, value: 0.5, tone: tone);

        final Finder iconFinder = _inBar(find.byIcon(tone.icon));
        expect(iconFinder, findsOneWidget);
        final Icon icon = tester.widget<Icon>(iconFinder);
        expect(icon.color, StatusTones.colorsOf(_context(tester), tone).foreground);
        expect(icon.size, kDefaultPadding * 2);
      });
    }

    testWidgets("tone icon sits just before the value text", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.5, tone: StatusTone.warning);

      final Rect widgetRect = tester.getRect(find.byType(LabeledProgressBar));
      final Rect iconRect = tester.getRect(_inBar(find.byIcon(StatusTone.warning.icon)));
      final Rect valueRect = tester.getRect(_inBar(find.text("50%")));
      expect(valueRect.right, widgetRect.right);
      expect(valueRect.left - iconRect.right, kDefaultPadding / 2);
    });

    testWidgets("colour override wins over the tone and drops the icon", (WidgetTester tester) async {
      final Color override = AppTheme.light().colorScheme.tertiary;
      await _pumpBar(tester, value: 0.5, tone: StatusTone.danger, color: override);

      expect(_fill(tester), override);
      expect(_fill(tester), isNot(StatusTones.colorsOf(_context(tester), StatusTone.danger).foreground));
      expect(_inBar(find.byType(Icon)), findsNothing);
    });

    testWidgets("uses the shared track token and the 999 radius", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.5);

      expect(_indicator(tester).backgroundColor, _scheme(tester).surfaceContainerHighest);
      final ClipRRect clip = tester.widget<ClipRRect>(_inBar(find.byType(ClipRRect)));
      expect(clip.borderRadius, BorderRadius.circular(999));
    });

    testWidgets("label and value text use cs.onSurface with w600 / w800", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.73);

      final ColorScheme cs = _scheme(tester);
      final Text label = _text(tester, _label);
      final Text value = _text(tester, "73%");
      expect(label.style?.color, cs.onSurface);
      expect(label.style?.fontWeight, FontWeight.w600);
      expect(value.style?.color, cs.onSurface);
      expect(value.style?.fontWeight, FontWeight.w800);
    });
  });

  group("LabeledProgressBar layout", () {
    testWidgets("bar is 12 dp thick, 12 dp below the header, full width", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.5);

      final Finder bar = _inBar(find.byType(LinearProgressIndicator));
      final Rect barRect = tester.getRect(bar);
      final Rect valueRect = tester.getRect(_inBar(find.text("50%")));
      final Rect widgetRect = tester.getRect(find.byType(LabeledProgressBar));

      expect(_indicator(tester).minHeight, kDefaultPadding * 1.5);
      expect(barRect.height, kDefaultPadding * 1.5);
      expect(barRect.top - valueRect.bottom, kDefaultPadding * 1.5);
      expect(barRect.width, widgetRect.width);
    });

    testWidgets("label sits left, value text sits right", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.5);

      final Rect widgetRect = tester.getRect(find.byType(LabeledProgressBar));
      final Rect labelRect = tester.getRect(_inBar(find.text(_label)));
      final Rect valueRect = tester.getRect(_inBar(find.text("50%")));
      expect(labelRect.left, widgetRect.left);
      expect(valueRect.right, widgetRect.right);
      expect(valueRect.left - labelRect.right, greaterThanOrEqualTo(kDefaultPadding * 1.5));
    });

    testWidgets("a long label wraps without overflow in a narrow box", (WidgetTester tester) async {
      const String longLabel = "A very long label that cannot possibly fit on a single line here";
      await pumpApp(
        tester,
        const LabeledProgressBar(label: longLabel, value: 0.42),
        surfaceSize: const Size(160, 400),
      );

      expect(tester.takeException(), isNull);
      expect(_inBar(find.text("42%")), findsOneWidget);
      final Rect valueRect = tester.getRect(_inBar(find.text("42%")));
      expect(valueRect.width, greaterThan(0));
      expect(valueRect.right, lessThanOrEqualTo(160));
    });

    testWidgets("a tone icon and a long label fit a narrow box", (WidgetTester tester) async {
      const String longLabel = "A very long label that cannot possibly fit on a single line here";
      await pumpApp(
        tester,
        const LabeledProgressBar(label: longLabel, value: 0.42, tone: StatusTone.danger),
        surfaceSize: const Size(160, 400),
      );

      expect(tester.takeException(), isNull);
      expect(_inBar(find.byIcon(StatusTone.danger.icon)), findsOneWidget);
      expect(tester.getRect(_inBar(find.text("42%"))).right, lessThanOrEqualTo(160));
    });
  });

  group("LabeledProgressBar semantics", () {
    testWidgets("exposes one node with label and percentage value", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBar(tester, value: 0.73);

      expect(
        tester.getSemantics(find.byType(LabeledProgressBar)),
        matchesSemantics(label: _label, value: "73%"),
      );
      expect(find.bySemanticsLabel("73%"), findsNothing);
      expect(find.bySemanticsLabel(_label), findsOneWidget);
      handle.dispose();
    });

    testWidgets("keeps one node when a tone icon is drawn", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBar(tester, value: 0.73, tone: StatusTone.danger);

      expect(_inBar(find.byIcon(StatusTone.danger.icon)), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(LabeledProgressBar)),
        matchesSemantics(label: _label, value: "73%"),
      );
      handle.dispose();
    });

    testWidgets("announces valueLabel as the value", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBar(tester, value: 0.6, valueLabel: "3/5");

      expect(
        tester.getSemantics(find.byType(LabeledProgressBar)),
        matchesSemantics(label: _label, value: "3/5"),
      );
      handle.dispose();
    });
  });

  group("LabeledProgressBar locale", () {
    testWidgets("formats the percentage for the ambient locale", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => Localizations.override(
            context: context,
            locale: const Locale("fr"),
            child: const LabeledProgressBar(label: _label, value: 0.73),
          ),
        ),
      );

      final String expected = NumberFormat.percentPattern("fr").format(0.73);
      expect(expected, isNot("73%"));
      expect(expected, contains("73"));
      expect(_inBar(find.text(expected)), findsOneWidget);
    });
  });

  group("LabeledProgressBar dark theme", () {
    testWidgets("reads the dark scheme and tones", (WidgetTester tester) async {
      final ThemeData dark = AppTheme.dark();
      await _pumpBar(tester, value: 0.73, tone: StatusTone.success, theme: dark);

      final ColorScheme cs = _scheme(tester);
      expect(cs.brightness, Brightness.dark);
      expect(_fill(tester), StatusTones.colorsOf(_context(tester), StatusTone.success).foreground);
      expect(_indicator(tester).backgroundColor, dark.colorScheme.surfaceContainerHighest);
      expect(_text(tester, _label).style?.color, dark.colorScheme.onSurface);
      expect(_text(tester, "73%").style?.color, dark.colorScheme.onSurface);
      final Icon icon = tester.widget<Icon>(_inBar(find.byIcon(StatusTone.success.icon)));
      expect(icon.color, StatusTones.colorsOf(_context(tester), StatusTone.success).foreground);
      expect(tester.takeException(), isNull);
    });
  });
}

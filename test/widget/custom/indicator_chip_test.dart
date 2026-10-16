// indicator_chip_test.dart
//
// Widget tests for IndicatorChip: label, optional icon and locale-formatted
// ratio, the ratio assert, tone and override colours with the derived fill
// and border, text contrast on its tint in both themes, the tap tooltip with
// its 48 dp hit area, own-node semantics, compact sizing, overflow in narrow
// parents and the dark theme.

import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/IndicatorChip/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:intl/intl.dart";

import "../../helpers/widget_test_helpers.dart";

const String _label = "Ref: Moderate";
const String _tip = "Compared with the reference dataset";

Finder _inChip(Finder matching) {
  return find.descendant(of: find.byType(IndicatorChip), matching: matching);
}

/// The chip Container (the only Container inside the widget).
Container _chip(WidgetTester tester) => tester.widget<Container>(_inChip(find.byType(Container)));

BoxDecoration _decoration(WidgetTester tester) => _chip(tester).decoration! as BoxDecoration;

Text _text(WidgetTester tester) => tester.widget<Text>(_inChip(find.byType(Text)));

String _visible(WidgetTester tester) => _text(tester).data ?? "";

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(IndicatorChip))).colorScheme;

Color _foreground(WidgetTester tester, StatusTone tone) {
  return StatusTones.colorsOf(tester.element(find.byType(IndicatorChip)), tone).foreground;
}

/// Hosts [chip] under the [locale] (overriding the app's en-US default).
Widget _withLocale(Locale locale, Widget chip) {
  return Builder(
    builder: (BuildContext context) => Localizations.override(context: context, locale: locale, child: chip),
  );
}

/// WCAG 2.x contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Future<void> _finishTooltipTimers(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

void main() {
  group("structure", _structureTests);
  group("ratio", _ratioTests);
  group("colours", _coloursTests);
  group("contrast", _contrastTests);
  group("tooltip", _tooltipTests);
  group("semantics", _semanticsTests);
  group("layout robustness", _layoutRobustnessTests);
  group("dark theme", _darkThemeTests);
}

void _structureTests() {
  testWidgets("renders the label alone by default, without an icon", (WidgetTester tester) async {
    await pumpApp(tester, const IndicatorChip(label: _label));

    expect(find.text(_label), findsOneWidget);
    expect(_inChip(find.byType(Icon)), findsNothing);
  });

  testWidgets("renders a 14 dp icon 6 dp before the text, in the text colour", (WidgetTester tester) async {
    await pumpApp(tester, const IndicatorChip(label: _label, icon: Icons.public));

    final Icon icon = tester.widget<Icon>(find.byIcon(Icons.public));
    expect(icon.size, 14);
    expect(icon.color, _text(tester).style?.color);
    expect(
      tester.getTopLeft(find.text(_label)).dx - tester.getTopRight(find.byIcon(Icons.public)).dx,
      6,
    );
  });

  testWidgets("text is labelMedium / w600 on one line with an ellipsis", (WidgetTester tester) async {
    await pumpApp(tester, const IndicatorChip(label: _label));
    final TextTheme textTheme = Theme.of(tester.element(find.byType(IndicatorChip))).textTheme;

    final Text text = _text(tester);
    expect(text.style?.fontSize, textTheme.labelMedium?.fontSize);
    expect(text.style?.fontWeight, FontWeight.w600);
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });
}

void _ratioTests() {
  testWidgets("en-US: appends the percentage in parentheses", (WidgetTester tester) async {
    await pumpApp(tester, const IndicatorChip(label: _label, ratio: 0.55));

    expect(_visible(tester), "$_label (55%)");
  });

  testWidgets("fr: uses the French percent format", (WidgetTester tester) async {
    await pumpApp(tester, _withLocale(const Locale("fr", "FR"), const IndicatorChip(label: _label, ratio: 0.55)));

    final String percent = NumberFormat.percentPattern("fr_FR").format(0.55);
    expect(percent, isNot("55%"));
    expect(_visible(tester), "$_label ($percent)");
  });

  testWidgets("bounds 0 and 1 format as 0% and 100%", (WidgetTester tester) async {
    await pumpApp(tester, const IndicatorChip(label: _label, ratio: 0));
    expect(_visible(tester), "$_label (0%)");

    await pumpApp(tester, const IndicatorChip(label: _label, ratio: 1));
    expect(_visible(tester), "$_label (100%)");
  });

  testWidgets("no ratio: no parentheses and no percent sign", (WidgetTester tester) async {
    await pumpApp(tester, const IndicatorChip(label: _label));

    expect(_visible(tester), _label);
    expect(_visible(tester), isNot(contains("%")));
    expect(_visible(tester), isNot(contains("(")));
  });

  test("asserts the ratio is in [0, 1]", () {
    IndicatorChip build(double ratio) => IndicatorChip(label: _label, ratio: ratio);

    expect(() => build(-0.1), throwsAssertionError);
    expect(() => build(1.2), throwsAssertionError);
    expect(() => build(double.nan), throwsAssertionError);
    expect(build(0).ratio, 0);
    expect(build(1).ratio, 1);
  });
}

void _coloursTests() {
  for (final StatusTone tone in StatusTone.values) {
    testWidgets("${tone.name}: text, icon, 6 % fill and 30 % border", (WidgetTester tester) async {
      await pumpApp(tester, IndicatorChip(label: _label, tone: tone, icon: tone.icon));

      final Color fg = _foreground(tester, tone);
      expect(_text(tester).style?.color, fg);
      expect(tester.widget<Icon>(find.byIcon(tone.icon)).color, fg);
      final BoxDecoration decoration = _decoration(tester);
      expect(decoration.color, fg.withValues(alpha: 0.06));
      expect(decoration.border, Border.all(color: fg.withValues(alpha: 0.30)));
      expect(decoration.borderRadius, BorderRadius.circular(8));
    });
  }

  testWidgets("neutral is onSurfaceVariant and primary is cs.primary", (WidgetTester tester) async {
    await pumpApp(tester, const IndicatorChip(label: _label));
    expect(_text(tester).style?.color, _scheme(tester).onSurfaceVariant);

    await pumpApp(tester, const IndicatorChip(label: _label, tone: StatusTone.primary));
    expect(_text(tester).style?.color, _scheme(tester).primary);
  });

  testWidgets("danger uses the StatusTones danger foreground", (WidgetTester tester) async {
    await pumpApp(tester, const IndicatorChip(label: _label, tone: StatusTone.danger));
    final StatusTones tones = StatusTones.of(tester.element(find.byType(IndicatorChip)));

    expect(_text(tester).style?.color, tones.danger.foreground);
  });

  testWidgets("color overrides the tone and drives fill and border", (WidgetTester tester) async {
    await pumpApp(tester, const IndicatorChip(label: _label));
    final Color override = _scheme(tester).tertiary;

    await pumpApp(
      tester,
      IndicatorChip(label: _label, tone: StatusTone.danger, icon: Icons.public, color: override),
    );

    expect(_text(tester).style?.color, override);
    expect(tester.widget<Icon>(find.byIcon(Icons.public)).color, override);
    expect(_decoration(tester).color, override.withValues(alpha: 0.06));
    expect(_decoration(tester).border, Border.all(color: override.withValues(alpha: 0.30)));
  });

  testWidgets("compact padding of 10 / 6 dp", (WidgetTester tester) async {
    await pumpApp(tester, const IndicatorChip(label: _label));

    expect(_chip(tester).padding, const EdgeInsets.symmetric(horizontal: 10, vertical: 6));
  });
}

void _contrastTests() {
  final Map<String, ThemeData> themes = <String, ThemeData>{
    "light": AppTheme.light(),
    "dark": AppTheme.dark(),
  };
  themes.forEach((String name, ThemeData theme) {
    testWidgets("$name: every tone's text is >= 4.5:1 on its tint over surface … surfaceContainerHighest",
        (WidgetTester tester) async {
      await pumpApp(
        tester,
        Column(
          children: <Widget>[
            for (final StatusTone tone in StatusTone.values) IndicatorChip(label: tone.name, tone: tone),
          ],
        ),
        theme: theme,
      );

      final ColorScheme cs = theme.colorScheme;
      final Map<String, Color> surfaces = <String, Color>{
        "surface": cs.surface,
        "surfaceContainerLowest": cs.surfaceContainerLowest,
        "surfaceContainerLow": cs.surfaceContainerLow,
        "surfaceContainer": cs.surfaceContainer,
        "surfaceContainerHigh": cs.surfaceContainerHigh,
        "surfaceContainerHighest": cs.surfaceContainerHighest,
      };
      for (final StatusTone tone in StatusTone.values) {
        final Finder chip = find.ancestor(of: find.text(tone.name), matching: find.byType(IndicatorChip));
        final Color text = tester.widget<Text>(find.text(tone.name)).style!.color!;
        final Container box = tester.widget<Container>(find.descendant(of: chip, matching: find.byType(Container)));
        final Color fill = (box.decoration! as BoxDecoration).color!;
        surfaces.forEach((String surfaceName, Color surface) {
          expect(
            _contrast(text, Color.alphaBlend(fill, surface)),
            greaterThanOrEqualTo(4.5),
            reason: "${tone.name} on $surfaceName",
          );
        });
      }
    });
  });
}

void _tooltipTests() {
  testWidgets("no tooltip: no Tooltip and the chip keeps its compact height", (WidgetTester tester) async {
    await pumpApp(tester, const Center(child: IndicatorChip(label: _label)));

    expect(find.byType(Tooltip), findsNothing);
    expect(tester.getSize(find.byType(IndicatorChip)).height, lessThan(kMinTapTarget));
  });

  testWidgets("an empty tooltip is treated as none", (WidgetTester tester) async {
    await pumpApp(tester, const Center(child: IndicatorChip(label: _label, tooltip: "")));

    expect(find.byType(Tooltip), findsNothing);
  });

  testWidgets("tap tooltip, no wait, 5 s, with a 48 dp hit area around the chip", (WidgetTester tester) async {
    await pumpApp(tester, const Center(child: IndicatorChip(label: "A", tooltip: _tip)));

    final Tooltip tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, _tip);
    expect(tooltip.triggerMode, TooltipTriggerMode.tap);
    expect(tooltip.waitDuration, Duration.zero);
    expect(tooltip.showDuration, const Duration(seconds: 5));

    final Size area = tester.getSize(find.byType(IndicatorChip));
    expect(area.width, greaterThanOrEqualTo(kMinTapTarget));
    expect(area.height, greaterThanOrEqualTo(kMinTapTarget));
    expect(tester.getSize(_inChip(find.byType(Container))).height, lessThan(kMinTapTarget));
    expect(
      tester.getCenter(_inChip(find.byType(Container))),
      tester.getCenter(find.byType(IndicatorChip)),
    );
  });

  testWidgets("tapping the chip shows the message", (WidgetTester tester) async {
    await pumpApp(tester, const Center(child: IndicatorChip(label: _label, tooltip: _tip)));

    expect(find.text(_tip), findsNothing);
    await tester.tap(find.text(_label));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(_tip), findsOneWidget);

    await _finishTooltipTimers(tester);
  });

  testWidgets("tapping the enlarged area outside the chip also shows the message", (WidgetTester tester) async {
    await pumpApp(tester, const Center(child: IndicatorChip(label: "A", tooltip: _tip)));

    final Rect area = tester.getRect(find.byType(IndicatorChip));
    final Rect chip = tester.getRect(_inChip(find.byType(Container)));
    final Offset outsideChip = Offset(area.center.dx, area.top + 2);
    expect(chip.contains(outsideChip), isFalse);

    await tester.tapAt(outsideChip);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(_tip), findsOneWidget);

    await _finishTooltipTimers(tester);
  });
}

void _semanticsTests() {
  testWidgets("without semanticsLabel the visible text is announced once", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpApp(tester, const IndicatorChip(label: _label, ratio: 0.55, icon: Icons.public));

    expect(find.bySemanticsLabel("$_label (55%)"), findsOneWidget);
    handle.dispose();
  });

  testWidgets("semanticsLabel replaces the visible text", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      const IndicatorChip(label: _label, ratio: 0.55, semanticsLabel: "Reference class: moderate"),
    );

    expect(find.bySemanticsLabel("Reference class: moderate"), findsOneWidget);
    expect(find.bySemanticsLabel("$_label (55%)"), findsNothing);
    handle.dispose();
  });

  testWidgets("two chips side by side keep separate labels", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      const Row(
        children: <Widget>[
          IndicatorChip(label: "First"),
          IndicatorChip(label: "Second"),
        ],
      ),
    );

    expect(find.bySemanticsLabel("First"), findsOneWidget);
    expect(find.bySemanticsLabel("Second"), findsOneWidget);
    handle.dispose();
  });

  for (final String? tip in <String?>[null, _tip]) {
    testWidgets("is its own node inside a labelled container (tooltip: ${tip != null})",
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        Semantics(
          container: true,
          label: "Card",
          child: Column(children: <Widget>[IndicatorChip(label: _label, tooltip: tip)]),
        ),
      );

      expect(find.bySemanticsLabel(_label), findsOneWidget);
      expect(find.bySemanticsLabel("Card"), findsOneWidget);
      final SemanticsNode chipNode = tester.getSemantics(find.bySemanticsLabel(_label));
      final SemanticsNode cardNode = tester.getSemantics(find.bySemanticsLabel("Card"));
      expect(chipNode.id, isNot(cardNode.id));
      expect(cardNode.label, "Card");
      expect(cardNode.tooltip, "");
      expect(chipNode.tooltip, tip ?? "");
      handle.dispose();
    });
  }

  testWidgets("a tooltip chip exposes its label and its tooltip", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpApp(tester, const Center(child: IndicatorChip(label: _label, tooltip: _tip)));

    expect(find.bySemanticsLabel(_label), findsOneWidget);
    expect(tester.getSemantics(find.bySemanticsLabel(_label)).tooltip, _tip);
    handle.dispose();
  });
}

void _layoutRobustnessTests() {
  testWidgets("ellipsizes a long label in a 120 dp parent without overflow", (WidgetTester tester) async {
    await pumpApp(
      tester,
      const Center(
        child: SizedBox(
          width: 120,
          child: IndicatorChip(
            label: "A rather long indicator label that cannot fit",
            ratio: 0.42,
            icon: Icons.public,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(IndicatorChip)).width, lessThanOrEqualTo(120));
  });

  testWidgets("stays compact and centred under a tight width, with or without a tooltip",
      (WidgetTester tester) async {
    final List<double> widths = <double>[];
    for (final String? tip in <String?>[null, _tip]) {
      await pumpApp(
        tester,
        Center(
          child: SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[IndicatorChip(label: "A", tooltip: tip)],
            ),
          ),
        ),
      );

      final Rect chip = tester.getRect(_inChip(find.byType(Container)));
      expect(chip.width, lessThan(kMinTapTarget * 2));
      expect(chip.center.dx, tester.getCenter(find.byType(IndicatorChip)).dx);
      widths.add(chip.width);
    }
    expect(widths.first, widths.last);
  });

  testWidgets("no overflow under 2x text scaling", (WidgetTester tester) async {
    await pumpApp(
      tester,
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Center(child: IndicatorChip(label: _label, ratio: 0.55, icon: Icons.public)),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets("sits directly in a Row (unbounded width) without error", (WidgetTester tester) async {
    await pumpApp(
      tester,
      const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[IndicatorChip(label: _label, icon: Icons.public)],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(_label), findsOneWidget);
  });
}

void _darkThemeTests() {
  testWidgets("smoke: every tone resolves from the dark StatusTones", (WidgetTester tester) async {
    await pumpApp(
      tester,
      Column(
        children: <Widget>[
          for (final StatusTone tone in StatusTone.values)
            IndicatorChip(label: tone.name, tone: tone, icon: tone.icon, ratio: 0.5),
        ],
      ),
      theme: AppTheme.dark(),
    );

    expect(tester.takeException(), isNull);
    final BuildContext context = tester.element(find.byType(IndicatorChip).first);
    expect(Theme.of(context).brightness, Brightness.dark);
    for (final StatusTone tone in StatusTone.values) {
      final Color expected = StatusTones.colorsOf(context, tone).foreground;
      final Text text = tester.widget<Text>(find.text("${tone.name} (50%)"));
      expect(text.style?.color, expected);
    }
    expect(
      tester.widget<Text>(find.text("danger (50%)")).style?.color,
      Theme.of(context).colorScheme.error,
    );
  });
}

// step_range_chart_test.dart
//
// Widget tests for StepRangeChart: StepRangeColumn asserts and value
// equality, the 420 / 180 aspect ratio and the viewport scale factor, the
// painted bands / grid / halo / envelopes / locked mask / step line / dots
// (colours, geometry and order), line breaks on locked and valueless
// columns, ignored selections, caption counts, sizes, positions and
// ellipsis (from the painted paragraph offsets), clamping, the colour
// override, the semantics summary (scale, band labels and columns; raw keys
// under pumpApp, real fr / en strings through EasyLocalization), repaint
// decisions, asserts and the dark theme. Caption weights and inks are
// unit-tested in test/unit/widgets/step_range_chart_captions_test.dart; the
// painter's ink → colour switch is not asserted here, since painted
// paragraphs are disposed and expose no style.

import "dart:convert";
import "dart:io";
import "dart:ui" show PathMetric;

import "package:easy_localization/easy_localization.dart" hide TextDirection;
// Localization.load is the only way to empty the translations singleton that
// EasyLocalization fills; see the "localized" group's tearDown.
// ignore: implementation_imports
import "package:easy_localization/src/localization.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/data/locales.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/StepRangeChart/index.dart";
import "package:flutter_skeleton/widgets/custom/_base/value_band.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _axisKey = "custom.step_range_chart.axis";
const String _bandKey = "custom.step_range_chart.band";
const String _valueKey = "custom.step_range_chart.value";
const String _rangeKey = "custom.step_range_chart.range";
const String _lockedKey = "custom.step_range_chart.locked";
const String _unavailableKey = "custom.step_range_chart.unavailable";
const String _selectedKey = "custom.step_range_chart.selected";

/// Width of the chart in every test unless stated otherwise: the design
/// viewport, so painted coordinates are viewport units (scale 1).
const double _width = 420;

/// Columns of 60 / 100 / 110 / 100 viewport units: 40–100, 100–200,
/// 200–310 and 310–410. Values are multiples of 12.5 so every y is exact:
/// y = 134 - value * 1.2.
const List<StepRangeColumn> _columns = <StepRangeColumn>[
  StepRangeColumn(label: "Now", sublabel: "ref", value: 50, flex: 6, emphasized: true),
  StepRangeColumn(label: "Q1", sublabel: "±1", value: 62.5, low: 50, high: 75, flex: 10),
  StepRangeColumn.locked(label: "Q2", flex: 11),
  StepRangeColumn(label: "Q3", value: 75, low: 37.5, high: 87.5, flex: 10),
];

/// Four bands with y edges 134 / 104 / 74 / 44 / 14.
const List<ValueBand> _bands = <ValueBand>[
  ValueBand(from: 0, to: 25, tone: StatusTone.danger, label: "Low"),
  ValueBand(from: 25, to: 50, tone: StatusTone.warning, label: "Fair"),
  ValueBand(from: 50, to: 75, label: "Good"),
  ValueBand(from: 75, to: 100, tone: StatusTone.success, label: "Top"),
];

/// Five bands of 20, as a typical good / ok / bad scale.
const List<ValueBand> _fiveBands = <ValueBand>[
  ValueBand(from: 0, to: 20, tone: StatusTone.danger, label: "E"),
  ValueBand(from: 20, to: 40, tone: StatusTone.warning, label: "D"),
  ValueBand(from: 40, to: 60, label: "C"),
  ValueBand(from: 60, to: 80, tone: StatusTone.info, label: "B"),
  ValueBand(from: 80, to: 100, tone: StatusTone.success, label: "A"),
];

Future<void> _pump(
  WidgetTester tester,
  StepRangeChart chart, {
  double width = _width,
  ThemeData? theme,
}) async {
  await pumpApp(
    tester,
    Center(child: SizedBox(width: width, child: chart)),
    surfaceSize: const Size(800, 600),
    theme: theme,
  );
}

Finder _inChart(Finder matching) {
  return find.descendant(of: find.byType(StepRangeChart), matching: matching);
}

/// The CustomPaint drawing the chart (the only one inside the widget).
Finder get _paint => _inChart(find.byType(CustomPaint));

BuildContext _context(WidgetTester tester) => tester.element(find.byType(StepRangeChart));

ColorScheme _scheme(WidgetTester tester) => Theme.of(_context(tester)).colorScheme;

ToneColors _tone(WidgetTester tester, StatusTone tone) => StatusTones.colorsOf(_context(tester), tone);

CustomPainter _painter(WidgetTester tester) => tester.renderObject<RenderCustomPaint>(_paint).painter!;

/// Lengths of the step line's contours, in drawing order.
List<double> _stepContours(WidgetTester tester) {
  Path? captured;
  expect(
    tester.renderObject(_paint),
    paints
      ..something((Symbol method, List<dynamic> arguments) {
        if (method != #drawPath) return false;
        captured = arguments[0] as Path;
        return true;
      }),
  );
  return <double>[for (final PathMetric metric in captured!.computeMetrics()) metric.length];
}

/// The semantics label of the chart node.
String _summary(WidgetTester tester) => tester.getSemantics(_paint).label;

/// Top-left offsets of the painted paragraphs, in drawing order. The
/// paragraphs themselves are disposed once painted; their offsets carry the
/// laid-out size of each caption.
List<Offset> _paragraphOffsets(WidgetTester tester) {
  final List<Offset> offsets = <Offset>[];
  expect(
    tester.renderObject(_paint),
    paints
      ..everything((Symbol method, List<dynamic> arguments) {
        if (method == #drawParagraph) offsets.add(arguments[1] as Offset);
        return true;
      }),
  );
  return offsets;
}

/// Unconstrained size of [text] in the chart's base style
/// (`textTheme.labelSmall`) at [fontSize].
Size _textSize(WidgetTester tester, String text, double fontSize) {
  final TextStyle base = Theme.of(_context(tester)).textTheme.labelSmall!;
  final TextPainter painter = TextPainter(
    text: TextSpan(text: text, style: base.copyWith(fontSize: fontSize)),
    textDirection: TextDirection.ltr,
  )..layout();
  final Size size = painter.size;
  painter.dispose();
  return size;
}

/// Where [text] at [fontSize] is painted when centred on [anchor].
Offset _centred(WidgetTester tester, String text, double fontSize, Offset anchor) {
  final Size size = _textSize(tester, text, fontSize);
  return Offset(anchor.dx - size.width / 2, anchor.dy - size.height / 2);
}

/// Where [text] at [fontSize] is painted when right-aligned on [anchor].
Offset _rightAligned(WidgetTester tester, String text, double fontSize, Offset anchor) {
  final Size size = _textSize(tester, text, fontSize);
  return Offset(anchor.dx - size.width, anchor.dy - size.height / 2);
}

/// Whether the canvas is scaled by [factor] on both axes.
bool Function(Symbol method, List<dynamic> arguments) _scaledBy(double factor) {
  return (Symbol method, List<dynamic> arguments) =>
      method == #scale && arguments[0] == factor && arguments[1] == factor;
}

StepRangeColumn _column({double? value, double? low, double? high, int flex = 1}) {
  return StepRangeColumn(label: "A", value: value, low: low, high: high, flex: flex);
}

StepRangeChart _chartWithAxis(double minValue, double maxValue) {
  return StepRangeChart(columns: _columns, minValue: minValue, maxValue: maxValue);
}

/// The widget's i18n fragment, served until the real translation files hold
/// `custom.step_range_chart`.
const Map<String, Map<String, String>> _fragment = <String, Map<String, String>>{
  "fr": <String, String>{
    "axis": "échelle de {min} à {max}",
    "band": "{label} : de {from} à {to}",
    "value": "{label} : {value}",
    "range": "plage de {low} à {high}",
    "locked": "{label} : verrouillé",
    "unavailable": "{label} : non disponible",
    "selected": "sélectionné",
  },
  "en": <String, String>{
    "axis": "scale {min} to {max}",
    "band": "{label}: {from} to {to}",
    "value": "{label}: {value}",
    "range": "range {low} to {high}",
    "locked": "{label}: locked",
    "unavailable": "{label}: not available",
    "selected": "selected",
  },
};

/// Reads the real `<path>/<lang>.json` once it holds
/// `custom.step_range_chart`, so the expectations below check the shipped
/// strings; until then it serves [_fragment]. Synchronous I/O, so it
/// completes under the test's fake async clock.
final class _TranslationsLoader extends AssetLoader {
  const _TranslationsLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final File file = File("$path/${locale.languageCode}.json");
    final Map<String, dynamic> assets = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final Object? custom = assets["custom"];
    if (custom is Map<String, dynamic> && custom.containsKey("step_range_chart")) return assets;
    return <String, dynamic>{
      "custom": <String, dynamic>{"step_range_chart": _fragment[locale.languageCode]},
    };
  }
}

Future<void> _pumpLocalized(WidgetTester tester, Locale locale, Widget child) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const <Locale>[Locale("fr"), Locale("en")],
      path: AppLocales.path,
      fallbackLocale: const Locale("fr"),
      startLocale: locale,
      saveLocale: false,
      assetLoader: const _TranslationsLoader(),
      child: Builder(
        builder: (BuildContext context) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.light(),
          home: Scaffold(body: Center(child: SizedBox(width: _width, child: child))),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group("StepRangeColumn", () {
    test("low and high must be set together", () {
      expect(() => _column(value: 1, low: 0), throwsAssertionError);
      expect(() => _column(value: 1, high: 2), throwsAssertionError);
      expect(_column(value: 1, low: 0, high: 2).high, 2);
    });

    test("flex must be positive", () {
      expect(() => _column(flex: 0), throwsAssertionError);
      final int flex = _column().flex - 1;
      expect(() => StepRangeColumn.locked(label: "A", flex: flex), throwsAssertionError);
    });

    test("locked columns carry no value, envelope or emphasis", () {
      const StepRangeColumn column = StepRangeColumn.locked(label: "A", sublabel: "b", flex: 3);
      expect(column.locked, isTrue);
      expect(column.value, isNull);
      expect(column.low, isNull);
      expect(column.high, isNull);
      expect(column.emphasized, isFalse);
      expect(column.flex, 3);
    });

    test("value equality over every field", () {
      final StepRangeColumn a = _column(value: 10, low: 5, high: 15);
      final StepRangeColumn b = _column(value: 10, low: 5, high: 15);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(_column(value: 10, low: 5, high: 16)));
      expect(_column(), isNot(const StepRangeColumn.locked(label: "A")));
      expect(_column(), isNot(const StepRangeColumn(label: "A", emphasized: true)));
    });
  });

  group("layout", () {
    testWidgets("renders columns and five bands with a single CustomPaint", (WidgetTester tester) async {
      await _pump(tester, const StepRangeChart(columns: _columns, selectedIndex: 1, bands: _fiveBands));

      expect(tester.takeException(), isNull);
      expect(_paint, findsOneWidget);
    });

    testWidgets("keeps the 420 / 180 aspect ratio", (WidgetTester tester) async {
      await _pump(tester, const StepRangeChart(columns: _columns));
      expect(tester.getSize(_paint), const Size(420, 180));

      await _pump(tester, const StepRangeChart(columns: _columns), width: 375);
      final Size size = tester.getSize(_paint);
      expect(size.width, 375);
      expect(size.height, moreOrLessEquals(375 * 180 / 420));
    });
  });

  group("painting", () {
    testWidgets("bands, grid, halo, envelopes, locked mask, line and dots in order", (WidgetTester tester) async {
      await _pump(tester, const StepRangeChart(columns: _columns, selectedIndex: 3, bands: _bands));
      final ColorScheme cs = _scheme(tester);

      expect(
        tester.renderObject(_paint),
        paints
          ..rect(rect: const Rect.fromLTRB(40, 104, 410, 134), color: _tone(tester, StatusTone.danger).container)
          ..rect(rect: const Rect.fromLTRB(40, 74, 410, 104), color: _tone(tester, StatusTone.warning).container)
          ..rect(rect: const Rect.fromLTRB(40, 44, 410, 74), color: _tone(tester, StatusTone.neutral).container)
          ..rect(rect: const Rect.fromLTRB(40, 14, 410, 44), color: _tone(tester, StatusTone.success).container)
          ..line(p1: const Offset(100, 14), p2: const Offset(100, 134), color: cs.outlineVariant, strokeWidth: 0.5)
          ..line(p1: const Offset(200, 14), p2: const Offset(200, 134))
          ..line(p1: const Offset(310, 14), p2: const Offset(310, 134))
          ..rect(rect: const Rect.fromLTRB(310, 14, 410, 134), color: cs.primary.withValues(alpha: 0.06))
          ..rect(rect: const Rect.fromLTRB(100, 44, 200, 74), color: cs.primary.withValues(alpha: 0.15))
          ..rect(
            rect: const Rect.fromLTRB(100, 44, 200, 74),
            color: cs.primary.withValues(alpha: 0.4),
            style: PaintingStyle.stroke,
            strokeWidth: 0.5,
          )
          ..rect(rect: const Rect.fromLTRB(310, 29, 410, 89), color: cs.primary.withValues(alpha: 0.15))
          ..rect(rect: const Rect.fromLTRB(310, 29, 410, 89), style: PaintingStyle.stroke)
          ..rect(rect: const Rect.fromLTRB(200, 14, 310, 134), color: cs.surfaceContainerHighest.withValues(alpha: 0.9))
          ..rect(rect: const Rect.fromLTRB(200, 14, 310, 134), color: cs.outlineVariant, style: PaintingStyle.stroke)
          ..paragraph()
          ..path(color: cs.primary, strokeWidth: 2.5, style: PaintingStyle.stroke)
          ..circle(x: 70, y: 74, radius: 3.5, color: cs.surface)
          ..circle(x: 70, y: 74, radius: 3.5, color: cs.primary, style: PaintingStyle.stroke, strokeWidth: 2)
          ..circle(x: 150, y: 59, radius: 3.5, color: cs.surface)
          ..circle(x: 150, y: 59, radius: 3.5, color: cs.primary, style: PaintingStyle.stroke)
          ..circle(x: 360, y: 44, radius: 4.5, color: cs.primary)
          ..circle(x: 360, y: 44, radius: 4.5, color: cs.surface, style: PaintingStyle.stroke, strokeWidth: 2.5),
      );
      // 4 bands + halo + 2 × 2 envelopes + 2 locked.
      expect(tester.renderObject(_paint), paintsExactlyCountTimes(#drawRect, 11));
      expect(tester.renderObject(_paint), paintsExactlyCountTimes(#drawCircle, 6));
    });

    testWidgets("the step line breaks on a locked column", (WidgetTester tester) async {
      await _pump(tester, const StepRangeChart(columns: _columns));

      // 40→100 at y 74, connector 74→59 at x 100, 100→200 at y 59; then
      // 310→410 alone.
      final List<double> contours = _stepContours(tester);
      expect(contours, hasLength(2));
      expect(contours[0], moreOrLessEquals(60 + 15 + 100));
      expect(contours[1], moreOrLessEquals(100));
    });

    testWidgets("a valueless column breaks the line without a mask or dot", (WidgetTester tester) async {
      await _pump(
        tester,
        const StepRangeChart(
          columns: <StepRangeColumn>[
            StepRangeColumn(label: "A", value: 25),
            StepRangeColumn(label: "B"),
            StepRangeColumn(label: "C", value: 75),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(_stepContours(tester), hasLength(2));
      expect(tester.renderObject(_paint), paintsExactlyCountTimes(#drawRect, 0));
      expect(tester.renderObject(_paint), paintsExactlyCountTimes(#drawCircle, 4));
    });

    testWidgets("adjacent valued columns form one contour", (WidgetTester tester) async {
      await _pump(
        tester,
        const StepRangeChart(
          columns: <StepRangeColumn>[
            StepRangeColumn(label: "A", value: 25),
            StepRangeColumn(label: "B", value: 75),
          ],
        ),
      );

      // Two columns of 185: 185 at y 104, connector of 60, 185 at y 44.
      final List<double> contours = _stepContours(tester);
      expect(contours, hasLength(1));
      expect(contours.single, moreOrLessEquals(185 + 60 + 185));
    });

    testWidgets("no selection: no halo and no selected dot", (WidgetTester tester) async {
      await _pump(tester, const StepRangeChart(columns: _columns, bands: _bands));

      expect(tester.renderObject(_paint), paintsExactlyCountTimes(#drawRect, 10));
      expect(tester.renderObject(_paint), isNot(paints..circle(radius: 4.5)));
    });

    testWidgets("a selection on a locked or valueless column is ignored", (WidgetTester tester) async {
      await _pump(tester, const StepRangeChart(columns: _columns, selectedIndex: 2));

      expect(tester.takeException(), isNull);
      expect(tester.renderObject(_paint), paintsExactlyCountTimes(#drawRect, 6));
      expect(tester.renderObject(_paint), isNot(paints..circle(radius: 4.5)));

      await _pump(
        tester,
        const StepRangeChart(
          columns: <StepRangeColumn>[StepRangeColumn(label: "A", value: 25), StepRangeColumn(label: "B")],
          selectedIndex: 1,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.renderObject(_paint), paintsExactlyCountTimes(#drawRect, 0));
    });

    testWidgets("captions: band labels, bounds and one name / sublabel / value per column", (WidgetTester tester) async {
      await _pump(tester, const StepRangeChart(columns: _columns, bands: _bands));

      // Lock glyph + 4 band labels + 2 bounds + (3 + 3 + 2 + 2) captions.
      expect(tester.renderObject(_paint), paintsExactlyCountTimes(#drawParagraph, 17));
    });

    testWidgets("captions: sizes and anchors in the gutter and under each column", (WidgetTester tester) async {
      await _pump(
        tester,
        const StepRangeChart(
          columns: <StepRangeColumn>[
            StepRangeColumn(label: "Ab", sublabel: "cd", value: 50, emphasized: true),
            StepRangeColumn(label: "Ab", sublabel: "cd", value: 50),
            StepRangeColumn(label: "Ab", value: 50),
            StepRangeColumn(label: "Ab", sublabel: ""),
          ],
          selectedIndex: 2,
          bands: <ValueBand>[ValueBand(from: 50, to: 100, tone: StatusTone.success, label: "Hi")],
        ),
      );

      // Four columns of 92.5: centres 86.25, 178.75, 271.25 and 363.75. The
      // empty sublabel is not painted.
      expect(_paragraphOffsets(tester), <Matcher>[
        // Band label centred in its band (y 14..74), then the bounds.
        offsetMoreOrLessEquals(_rightAligned(tester, "Hi", 7, const Offset(34, 44))),
        offsetMoreOrLessEquals(_rightAligned(tester, "100", 7, const Offset(34, 14))),
        offsetMoreOrLessEquals(_rightAligned(tester, "0", 7, const Offset(34, 134))),
        // Emphasized: value at 11.
        offsetMoreOrLessEquals(_centred(tester, "Ab", 9, const Offset(86.25, 148))),
        offsetMoreOrLessEquals(_centred(tester, "cd", 7, const Offset(86.25, 159))),
        offsetMoreOrLessEquals(_centred(tester, "50", 11, const Offset(86.25, 173))),
        // Plain: value at 10.
        offsetMoreOrLessEquals(_centred(tester, "Ab", 9, const Offset(178.75, 148))),
        offsetMoreOrLessEquals(_centred(tester, "cd", 7, const Offset(178.75, 159))),
        offsetMoreOrLessEquals(_centred(tester, "50", 10, const Offset(178.75, 173))),
        // Selected: value at 11.
        offsetMoreOrLessEquals(_centred(tester, "Ab", 9, const Offset(271.25, 148))),
        offsetMoreOrLessEquals(_centred(tester, "50", 11, const Offset(271.25, 173))),
        // Valueless: "—" at 10.
        offsetMoreOrLessEquals(_centred(tester, "Ab", 9, const Offset(363.75, 148))),
        offsetMoreOrLessEquals(_centred(tester, "—", 10, const Offset(363.75, 173))),
      ]);
      // The sizes above differ enough to be told apart.
      expect(_textSize(tester, "50", 11).height, isNot(moreOrLessEquals(_textSize(tester, "50", 10).height)));
    });

    testWidgets("captions are ellipsised to the column width", (WidgetTester tester) async {
      final String long = "W" * 40;
      await _pump(
        tester,
        StepRangeChart(
          columns: <StepRangeColumn>[
            StepRangeColumn(label: long, sublabel: long, value: 50),
            const StepRangeColumn(label: "B", value: 50),
          ],
        ),
      );

      // The first column spans 40..225 around x 132.5; unconstrained, the
      // name would start far left of the plot.
      expect(_centred(tester, long, 9, const Offset(132.5, 148)).dx, lessThan(40));
      final List<Offset> offsets = _paragraphOffsets(tester);
      expect(offsets, hasLength(2 + 3 + 2));
      for (final Offset offset in offsets.sublist(2, 4)) {
        expect(offset.dx, inInclusiveRange(40, 132.5));
      }
    });

    testWidgets("an empty band label is not painted", (WidgetTester tester) async {
      await _pump(
        tester,
        const StepRangeChart(
          columns: <StepRangeColumn>[StepRangeColumn(label: "A", value: 50)],
          bands: <ValueBand>[ValueBand(from: 0, to: 50, label: ""), ValueBand(from: 50, to: 100, label: "Hi")],
        ),
      );

      // 1 band label + 2 bounds + name + value.
      expect(tester.renderObject(_paint), paintsExactlyCountTimes(#drawParagraph, 5));
    });

    testWidgets("empty bands: plain plot, bounds still captioned", (WidgetTester tester) async {
      await _pump(
        tester,
        const StepRangeChart(columns: <StepRangeColumn>[StepRangeColumn(label: "A", value: 50)], selectedIndex: 0),
      );

      expect(tester.takeException(), isNull);
      // Halo only; no band, no grid line between columns.
      expect(tester.renderObject(_paint), paintsExactlyCountTimes(#drawRect, 1));
      expect(tester.renderObject(_paint), paintsExactlyCountTimes(#drawLine, 0));
      // 2 bounds + name + value.
      expect(tester.renderObject(_paint), paintsExactlyCountTimes(#drawParagraph, 4));
      expect(tester.renderObject(_paint), paints..circle(x: 225, y: 74, radius: 4.5));
    });

    testWidgets("values, envelopes and bands are clamped to the axis", (WidgetTester tester) async {
      await _pump(
        tester,
        const StepRangeChart(
          columns: <StepRangeColumn>[
            StepRangeColumn(label: "A", value: 150, low: -50, high: 200),
            StepRangeColumn(label: "B", value: -20),
          ],
          bands: <ValueBand>[ValueBand(from: -50, to: 25), ValueBand(from: 120, to: 150, label: "Out")],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.renderObject(_paint),
        paints
          ..rect(rect: const Rect.fromLTRB(40, 104, 410, 134))
          ..rect(rect: const Rect.fromLTRB(40, 14, 225, 134))
          ..circle(x: 132.5, y: 14)
          ..circle(x: 132.5, y: 14)
          ..circle(x: 317.5, y: 134),
      );
      // Band outside the axis: neither filled nor labelled.
      expect(tester.renderObject(_paint), paintsExactlyCountTimes(#drawRect, 3));
      expect(tester.renderObject(_paint), paintsExactlyCountTimes(#drawParagraph, 2 + 2 + 2));
    });

    testWidgets("minValue / maxValue map the value axis", (WidgetTester tester) async {
      await _pump(
        tester,
        const StepRangeChart(
          columns: <StepRangeColumn>[StepRangeColumn(label: "A", value: 15)],
          minValue: 10,
          maxValue: 30,
        ),
      );

      expect(tester.renderObject(_paint), paints..circle(x: 225, y: 104));
    });

    testWidgets("color overrides the line, dots, envelope and halo", (WidgetTester tester) async {
      final Color override = AppTheme.light().colorScheme.tertiary;
      await _pump(
        tester,
        StepRangeChart(
          columns: const <StepRangeColumn>[StepRangeColumn(label: "A", value: 50, low: 25, high: 75)],
          selectedIndex: 0,
          color: override,
        ),
      );

      expect(
        tester.renderObject(_paint),
        paints
          ..rect(color: override.withValues(alpha: 0.06))
          ..rect(color: override.withValues(alpha: 0.15))
          ..rect(color: override.withValues(alpha: 0.4))
          ..path(color: override)
          ..circle(color: override),
      );
    });

    testWidgets("scales the design viewport by width / 420", (WidgetTester tester) async {
      await _pump(tester, const StepRangeChart(columns: _columns), width: 210);

      expect(tester.takeException(), isNull);
      expect(tester.renderObject(_paint), paints..something(_scaledBy(0.5)));
      expect(tester.renderObject(_paint), isNot(paints..something(_scaledBy(1))));

      await _pump(tester, const StepRangeChart(columns: _columns));
      expect(tester.renderObject(_paint), paints..something(_scaledBy(1)));
    });
  });

  group("repaint", () {
    testWidgets("repaints when an envelope or the lock state changes", (WidgetTester tester) async {
      await _pump(tester, StepRangeChart(columns: <StepRangeColumn>[_column(value: 50, low: 40, high: 60)]));
      final CustomPainter first = _painter(tester);

      await _pump(tester, StepRangeChart(columns: <StepRangeColumn>[_column(value: 50, low: 40, high: 70)]));
      final CustomPainter second = _painter(tester);
      expect(second.shouldRepaint(first), isTrue);

      await _pump(tester, const StepRangeChart(columns: <StepRangeColumn>[StepRangeColumn.locked(label: "A")]));
      expect(_painter(tester).shouldRepaint(second), isTrue);
    });

    testWidgets("does not repaint for equal content", (WidgetTester tester) async {
      await _pump(tester, StepRangeChart(columns: List<StepRangeColumn>.of(_columns), bands: _bands));
      final CustomPainter first = _painter(tester);

      await _pump(tester, StepRangeChart(columns: List<StepRangeColumn>.of(_columns), bands: _bands));
      expect(_painter(tester).shouldRepaint(first), isFalse);
    });

    testWidgets("repaints when the selection changes", (WidgetTester tester) async {
      await _pump(tester, const StepRangeChart(columns: _columns, selectedIndex: 1));
      final CustomPainter first = _painter(tester);

      await _pump(tester, const StepRangeChart(columns: _columns, selectedIndex: 3));
      expect(_painter(tester).shouldRepaint(first), isTrue);
    });
  });

  group("semantics", () {
    testWidgets("one entry per column after the title (raw keys)", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, const StepRangeChart(columns: _columns, selectedIndex: 3, semanticLabel: "Trend"));

      expect(
        _summary(tester),
        "Trend. $_axisKey. $_valueKey. $_valueKey, $_rangeKey. $_lockedKey. $_valueKey, $_rangeKey, $_selectedKey",
      );
      handle.dispose();
    });

    testWidgets("without a title the summary starts with the scale", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(
        tester,
        const StepRangeChart(
          columns: <StepRangeColumn>[StepRangeColumn(label: "A", value: 1), StepRangeColumn(label: "B")],
        ),
      );

      expect(_summary(tester), "$_axisKey. $_valueKey. $_unavailableKey");
      handle.dispose();
    });

    testWidgets("an empty title is skipped", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(
        tester,
        const StepRangeChart(columns: <StepRangeColumn>[StepRangeColumn(label: "A", value: 1)], semanticLabel: ""),
      );

      expect(_summary(tester), "$_axisKey. $_valueKey");
      handle.dispose();
    });

    testWidgets("one entry per painted band label (raw keys)", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(
        tester,
        const StepRangeChart(
          columns: <StepRangeColumn>[StepRangeColumn(label: "A", value: 1)],
          bands: <ValueBand>[
            ValueBand(from: -50, to: 25, label: "Low"),
            ValueBand(from: 25, to: 50),
            ValueBand(from: 50, to: 75, label: ""),
            ValueBand(from: 75, to: 100, label: "Top"),
            ValueBand(from: 120, to: 150, label: "Out"),
          ],
        ),
      );

      // Unlabelled, empty-label and off-axis bands are skipped.
      expect(_summary(tester), "$_axisKey. $_bandKey. $_bandKey. $_valueKey");
      handle.dispose();
    });

    testWidgets("a selection on a locked column is not announced", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, const StepRangeChart(columns: _columns, selectedIndex: 2));

      expect(_summary(tester), isNot(contains(_selectedKey)));
      handle.dispose();
    });
  });

  group("asserts", () {
    test("minValue must be less than maxValue", () {
      expect(() => _chartWithAxis(10, 10), throwsAssertionError);
      expect(() => _chartWithAxis(20, 10), throwsAssertionError);
      expect(_chartWithAxis(0, 1).maxValue, 1);
    });

    testWidgets("empty columns throw at build time", (WidgetTester tester) async {
      await _pump(tester, const StepRangeChart(columns: <StepRangeColumn>[]));

      expect(tester.takeException(), isAssertionError);
    });

    testWidgets("selectedIndex must be within columns", (WidgetTester tester) async {
      await _pump(tester, const StepRangeChart(columns: _columns, selectedIndex: 4));
      expect(tester.takeException(), isAssertionError);

      await _pump(tester, const StepRangeChart(columns: _columns, selectedIndex: -1));
      expect(tester.takeException(), isAssertionError);
    });
  });

  group("theme", () {
    testWidgets("dark theme: palette and band fills from the dark scheme", (WidgetTester tester) async {
      await _pump(
        tester,
        const StepRangeChart(columns: _columns, selectedIndex: 1, bands: _fiveBands),
        theme: AppTheme.dark(),
      );
      final ColorScheme cs = _scheme(tester);

      expect(tester.takeException(), isNull);
      expect(cs.brightness, Brightness.dark);
      expect(
        tester.renderObject(_paint),
        paints
          ..rect(color: _tone(tester, StatusTone.danger).container)
          ..path(color: cs.primary)
          ..circle(color: cs.surface),
      );
    });
  });

  group("localized", () {
    // EasyLocalization keeps its translations in a singleton that outlives the
    // test; empty it so the raw-key tests pass in any order.
    tearDown(() {
      Localization.load(const Locale("fr"));
    });

    /// Off-axis parts are clamped; the unlabelled band is not announced.
    const List<ValueBand> bands = <ValueBand>[
      ValueBand(from: -10, to: 25, tone: StatusTone.danger, label: "Low"),
      ValueBand(from: 25, to: 75),
      ValueBand(from: 75, to: 120, tone: StatusTone.success, label: "Top"),
    ];

    const List<StepRangeColumn> columns = <StepRangeColumn>[
      StepRangeColumn(label: "Now", value: 67, emphasized: true),
      StepRangeColumn(label: "2030", sublabel: "±10 yr", value: 71, low: 68, high: 74),
      StepRangeColumn.locked(label: "2050"),
      StepRangeColumn(label: "2090"),
    ];

    testWidgets("reads the en summary", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(
        tester,
        const Locale("en"),
        const StepRangeChart(columns: columns, selectedIndex: 1, bands: bands, semanticLabel: "Trend"),
      );

      expect(
        _summary(tester),
        "Trend. scale 0 to 100. Low: 0 to 25. Top: 75 to 100. "
        "Now: 67. 2030 (±10 yr): 71, range 68 to 74, selected. 2050: locked. 2090: not available",
      );
      handle.dispose();
    });

    testWidgets("reads the fr summary", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(
        tester,
        const Locale("fr"),
        const StepRangeChart(columns: columns, selectedIndex: 1, bands: bands),
      );

      expect(
        _summary(tester),
        "échelle de 0 à 100. Low : de 0 à 25. Top : de 75 à 100. "
        "Now : 67. 2030 (±10 yr) : 71, plage de 68 à 74, sélectionné. 2050 : verrouillé. 2090 : non disponible",
      );
      handle.dispose();
    });

    testWidgets("valueFormatter formats the summary values and bounds", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(
        tester,
        const Locale("en"),
        StepRangeChart(
          columns: columns.sublist(1, 2),
          bands: const <ValueBand>[ValueBand(from: 25, to: 75, label: "Mid")],
          valueFormatter: (double v) => "${v.toStringAsFixed(1)} %",
        ),
      );

      expect(
        _summary(tester),
        "scale 0.0 % to 100.0 %. Mid: 25.0 % to 75.0 %. 2030 (±10 yr): 71.0 %, range 68.0 % to 74.0 %",
      );
      handle.dispose();
    });
  });
}

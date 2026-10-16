// status_strip_test.dart
//
// Widget tests for StatusStrip: one cell per period at several widths (down
// to near zero, exact cell widths), N != 12 periods, the category legend
// (only categories present, in the given order, no unknown entry, 8 dp below
// the strip, one-line entries with an ellipsis), showLegend, cell colours
// (tone container / explicit colour / outlined unknown layer distinct from
// the neutral tone, onContainer label, legend dot colours), comparison mode
// (split halves, two-entry legend, fallback names), agreement mode (corner
// dot, dashed outline, marker legend entries, 1 / 2 / 3 / 4 rows, markers
// kept inside narrow cells), asserts, cell semantics (raw keys and real
// French text with month labels), the monthLabels helper and a dark-theme
// smoke test. The French tests reset the easy_localization singleton, so the
// raw-key tests pass in any order.

import "package:easy_localization/easy_localization.dart";
// Localization.load is the only way to empty the translations singleton that
// EasyLocalization fills; see _pumpFrench.
// ignore: implementation_imports
import "package:easy_localization/src/localization.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/StatusStrip/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _cellKey = "custom.status_strip.cell";
const String _cellComparisonKey = "custom.status_strip.cell_comparison";
const String _cellMarkerKey = "custom.status_strip.cell_marker";
const String _partialKey = "custom.status_strip.partial_agreement";
const String _fullKey = "custom.status_strip.full_disagreement";
const String _referenceKey = "custom.status_strip.reference";
const String _comparisonKey = "custom.status_strip.comparison";
const String _referenceLabelledKey = "custom.status_strip.reference_labelled";
const String _comparisonLabelledKey = "custom.status_strip.comparison_labelled";

/// Width of the strip in every test unless stated otherwise.
const double _width = 360;

const List<String> _periods = <String>[
  "P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8", "P9", "P10", "P11", "P12",
];

const StatusStripCategory<String> _low = StatusStripCategory<String>(
  value: "low",
  label: "Low",
  tone: StatusTone.info,
);
const StatusStripCategory<String> _mid = StatusStripCategory<String>(
  value: "mid",
  label: "Mid",
  tone: StatusTone.success,
);
const StatusStripCategory<String> _high = StatusStripCategory<String>(
  value: "high",
  label: "High",
  tone: StatusTone.danger,
);
const StatusStripCategory<String> _unused = StatusStripCategory<String>(
  value: "unused",
  label: "Unused",
  tone: StatusTone.warning,
);

const List<StatusStripCategory<String>> _categories = <StatusStripCategory<String>>[_low, _mid, _high, _unused];

/// 12 values: [first] values given, then "low".
List<String> _values(List<String> first) {
  return <String>[...first, ...List<String>.filled(_periods.length - first.length, "low")];
}

StatusStrip<String> _strip({
  List<String> values = const <String>[],
  List<String> periods = _periods,
  List<StatusStripCategory<String>> categories = _categories,
  StatusStripSeries<String>? comparison,
  List<List<String>>? agreementSeries,
  bool showLegend = true,
}) {
  return StatusStrip<String>(
    periodLabels: periods,
    categories: categories,
    primary: StatusStripSeries<String>(
      values: periods.length == _periods.length ? _values(values) : values,
    ),
    comparison: comparison,
    agreementSeries: agreementSeries,
    showLegend: showLegend,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget strip, {
  double width = _width,
  ThemeData? theme,
}) async {
  await pumpApp(
    tester,
    Center(child: SizedBox(width: width, child: strip)),
    theme: theme,
  );
}

Finder _inStrip(Finder matching) {
  return find.descendant(of: find.byType(StatusStrip<String>), matching: matching);
}

/// The Stack of the cell showing [period].
Finder _cell(String period) {
  return find.ancestor(of: find.text(period), matching: find.byType(Stack)).first;
}

/// Fill colours of the cell showing [period], top to bottom (markers
/// excluded).
List<Color?> _fills(WidgetTester tester, String period) {
  return tester
      .widgetList<DecoratedBox>(find.descendant(of: _cell(period), matching: find.byType(DecoratedBox)))
      .map((DecoratedBox box) => box.decoration as BoxDecoration)
      .where((BoxDecoration decoration) => decoration.shape == BoxShape.rectangle)
      .map((BoxDecoration decoration) => decoration.color)
      .toList();
}

/// Border colours of the fill layers of the cell showing [period], top to
/// bottom (null = no border).
List<Color?> _borders(WidgetTester tester, String period) {
  return tester
      .widgetList<DecoratedBox>(find.descendant(of: _cell(period), matching: find.byType(DecoratedBox)))
      .map((DecoratedBox box) => box.decoration as BoxDecoration)
      .where((BoxDecoration decoration) => decoration.shape == BoxShape.rectangle)
      .map((BoxDecoration decoration) => (decoration.border as Border?)?.top.color)
      .toList();
}

/// Corner dots (circle DecoratedBoxes) inside [scope].
Finder _dots(Finder scope) {
  return find.descendant(
    of: scope,
    matching: find.byWidgetPredicate(
      (Widget widget) =>
          widget is DecoratedBox && (widget.decoration as BoxDecoration).shape == BoxShape.circle,
    ),
  );
}

/// Legend entry whose text ends with [label] (the glyph precedes it).
Finder _legend(String label) => find.textContaining(RegExp("${RegExp.escape(label)}\$"));

/// Expected width of each of the 12 cells in a strip [width] px wide: the
/// 11 gaps of 2 dp collapse when the width is smaller than them.
double _cellWidthAt(double width) {
  return width >= 11 * 2 ? (width - 11 * 2) / 12 : width / 12;
}

/// Matches a dash of the outline's top side: a horizontal line along y = 0.
bool _isTopDash(Symbol method, List<dynamic> arguments) {
  if (method != #drawLine) return false;
  final Offset start = arguments[0] as Offset;
  final Offset end = arguments[1] as Offset;
  return start.dy == 0 && end.dy == 0 && end.dx > start.dx;
}

BuildContext _context(WidgetTester tester) => tester.element(find.byType(StatusStrip<String>));

ColorScheme _scheme(WidgetTester tester) => Theme.of(_context(tester)).colorScheme;

ToneColors _tone(WidgetTester tester, StatusTone tone) => StatusTones.colorsOf(_context(tester), tone);

/// French strings of the keys, loaded by the localized tests.
const Map<String, dynamic> _fr = <String, dynamic>{
  "custom": <String, dynamic>{
    "status_strip": <String, String>{
      "reference": "Référence",
      "comparison": "Comparaison",
      "reference_labelled": "{label} (réf.)",
      "comparison_labelled": "{label} (test)",
      "partial_agreement": "Accord partiel",
      "full_disagreement": "Désaccord total",
      "unknown": "Inconnu",
      "cell": "{period} : {status}",
      "cell_comparison": "{period} : {primary} / {comparison}",
      "cell_marker": "{cell}, {marker}",
    },
  },
};

final class _FrLoader extends AssetLoader {
  const _FrLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async => _fr;
}

/// Pumps [builder] in a French app (EasyLocalization + localization
/// delegates, so the fr date symbols are loaded).
///
/// EasyLocalization keeps its translations in a process-wide singleton that
/// outlives the test; the tear-down empties it so every later `.tr()` returns
/// the raw key again, whatever the test order.
Future<void> _pumpFrench(WidgetTester tester, WidgetBuilder builder) async {
  addTearDown(() => Localization.load(const Locale("fr")));
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EasyLocalization.ensureInitialized();
  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[Locale("fr")],
        path: "unused",
        assetLoader: const _FrLoader(),
        fallbackLocale: const Locale("fr"),
        startLocale: const Locale("fr"),
        saveLocale: false,
        child: Builder(
          builder: (BuildContext context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            theme: AppTheme.light(),
            home: Scaffold(
              body: Center(child: SizedBox(width: _width, child: Builder(builder: builder))),
            ),
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await tester.pumpAndSettle();
}

void main() {
  group("cells", () {
    testWidgets("renders one cell per period, splitting the width evenly", (WidgetTester tester) async {
      await _pump(tester, _strip(values: <String>["low", "mid", "high"]));

      expect(tester.takeException(), isNull);
      for (final String period in _periods) {
        expect(find.text(period), findsOneWidget);
      }
      const double cellWidth = (_width - 11 * 2) / 12;
      expect(tester.getSize(_cell("P1")).width, moreOrLessEquals(cellWidth));
      expect(tester.getSize(_cell("P1")).height, 24);
      final double left = tester.getTopLeft(_cell("P1")).dx;
      expect(tester.getTopRight(_cell("P12")).dx - left, moreOrLessEquals(_width));
      expect(tester.getTopLeft(_cell("P2")).dx - tester.getTopRight(_cell("P1")).dx, moreOrLessEquals(2));
    });

    for (final double width in <double>[240, 8, 1]) {
      testWidgets("renders without exception at $width px", (WidgetTester tester) async {
        await _pump(
          tester,
          _strip(values: <String>["low", "mid", "high", "zzz"], agreementSeries: <List<String>>[
            _values(<String>["low", "low", "low"]),
            _values(<String>["low", "mid", "mid"]),
            _values(<String>["low", "mid", "high"]),
          ]),
          width: width,
        );

        expect(tester.takeException(), isNull);
        expect(tester.getSize(_cell("P1")).width, moreOrLessEquals(_cellWidthAt(width)));
        expect(tester.getTopRight(_cell("P12")).dx - tester.getTopLeft(_cell("P1")).dx, moreOrLessEquals(width));
      });
    }

    testWidgets("works with a number of periods other than 12", (WidgetTester tester) async {
      const List<String> days = <String>["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"];
      await _pump(
        tester,
        _strip(periods: days, values: <String>["low", "low", "mid", "mid", "high", "high", "low"]),
      );

      expect(tester.takeException(), isNull);
      for (final String day in days) {
        expect(find.text(day), findsOneWidget);
      }
      expect(tester.getSize(_cell("Mo")).width, moreOrLessEquals((_width - 6 * 2) / 7));
    });

    testWidgets("cellHeight sets the cell height", (WidgetTester tester) async {
      await _pump(
        tester,
        StatusStrip<String>(
          periodLabels: _periods,
          categories: _categories,
          primary: StatusStripSeries<String>(values: _values(<String>[])),
          cellHeight: 40,
        ),
      );

      expect(tester.getSize(_cell("P1")).height, 40);
    });
  });

  group("colours", () {
    testWidgets("fill is the tone container and the label the tone onContainer", (WidgetTester tester) async {
      await _pump(tester, _strip(values: <String>["low", "mid", "high"]));

      expect(_fills(tester, "P1"), <Color>[_tone(tester, StatusTone.info).container]);
      expect(_fills(tester, "P2"), <Color>[_tone(tester, StatusTone.success).container]);
      expect(_fills(tester, "P3"), <Color>[_tone(tester, StatusTone.danger).container]);
      expect(tester.widget<Text>(find.text("P1")).style?.color, _tone(tester, StatusTone.info).onContainer);
      expect(tester.widget<Text>(find.text("P3")).style?.color, _tone(tester, StatusTone.danger).onContainer);
      expect(tester.widget<Text>(find.text("P1")).style?.fontWeight, FontWeight.w700);
    });

    testWidgets("an explicit colour replaces the tone container", (WidgetTester tester) async {
      final Color explicit = AppTheme.light().colorScheme.tertiaryContainer;
      await _pump(
        tester,
        _strip(
          values: <String>["custom"],
          categories: <StatusStripCategory<String>>[
            _low,
            StatusStripCategory<String>(value: "custom", label: "Custom", tone: StatusTone.success, color: explicit),
          ],
        ),
      );

      expect(_fills(tester, "P1"), <Color>[explicit]);
      expect(tester.widget<Text>(find.text("P1")).style?.color, _tone(tester, StatusTone.success).onContainer);
      final Iterable<Color?> dotColours = tester
          .widgetList<DecoratedBox>(_dots(_inStrip(find.byType(Wrap))))
          .map((DecoratedBox box) => (box.decoration as BoxDecoration).color);
      expect(dotColours, <Color>[_tone(tester, StatusTone.info).container, explicit]);
    });

    testWidgets("an unknown value renders an outlined empty cell", (WidgetTester tester) async {
      await _pump(tester, _strip(values: <String>["zzz"]));

      expect(_fills(tester, "P1"), <Color>[_scheme(tester).surface]);
      expect(_borders(tester, "P1"), <Color?>[_scheme(tester).outlineVariant]);
      expect(_borders(tester, "P2"), <Color?>[null]);
      expect(tester.widget<Text>(find.text("P1")).style?.color, _scheme(tester).onSurfaceVariant);
    });

    testWidgets("a neutral category looks different from an unknown value", (WidgetTester tester) async {
      await _pump(
        tester,
        _strip(
          values: <String>["plain", "zzz"],
          categories: <StatusStripCategory<String>>[
            _low,
            const StatusStripCategory<String>(value: "plain", label: "Plain"),
          ],
        ),
      );

      expect(_fills(tester, "P1"), <Color>[_tone(tester, StatusTone.neutral).container]);
      expect(_borders(tester, "P1"), <Color?>[null]);
      expect(_fills(tester, "P2"), isNot(_fills(tester, "P1")));
      expect(_borders(tester, "P2"), <Color?>[_scheme(tester).outlineVariant]);
    });

    testWidgets("renders every mode under the dark theme", (WidgetTester tester) async {
      final ThemeData dark = AppTheme.dark();
      await _pump(
        tester,
        Column(
          children: <Widget>[
            _strip(values: <String>["low", "zzz"]),
            _strip(
              values: <String>["mid"],
              comparison: StatusStripSeries<String>(values: _values(<String>["high"])),
            ),
            _strip(agreementSeries: <List<String>>[
              _values(<String>["low", "low"]),
              _values(<String>["low", "mid"]),
              _values(<String>["mid", "high"]),
            ]),
          ],
        ),
        theme: dark,
      );

      expect(tester.takeException(), isNull);
      // First "P1" cell: the single-mode strip.
      expect(_fills(tester, "P1"), <Color>[StatusTones.fromScheme(dark.colorScheme).info.container]);
    });
  });

  group("legend", () {
    testWidgets("lists only the categories present, in the given order", (WidgetTester tester) async {
      await _pump(tester, _strip(values: <String>["high", "zzz", "mid", "high"]));

      expect(_legend("Low"), findsOneWidget);
      expect(_legend("Mid"), findsOneWidget);
      expect(_legend("High"), findsOneWidget);
      expect(_legend("Unused"), findsNothing);
      expect(find.textContaining("custom.status_strip.unknown"), findsNothing);
      final double low = tester.getTopLeft(_legend("Low")).dx;
      final double mid = tester.getTopLeft(_legend("Mid")).dx;
      final double high = tester.getTopLeft(_legend("High")).dx;
      expect(low, lessThan(mid));
      expect(mid, lessThan(high));
      expect(tester.widget<Text>(_legend("Low")).style?.color, _scheme(tester).onSurfaceVariant);
      expect(
        tester.getTopLeft(_inStrip(find.byType(Wrap))).dy,
        moreOrLessEquals(tester.getBottomLeft(_cell("P1")).dy + kDefaultPadding),
      );
    });

    testWidgets("a label wider than the strip stays on one line with an ellipsis", (WidgetTester tester) async {
      final String long = List<String>.filled(20, "Long").join(" ");
      await _pump(
        tester,
        _strip(
          values: <String>["wide"],
          categories: <StatusStripCategory<String>>[
            _low,
            StatusStripCategory<String>(value: "wide", label: long, tone: StatusTone.success),
          ],
        ),
        width: 120,
      );

      expect(tester.takeException(), isNull);
      final Text entry = tester.widget<Text>(_legend(long));
      expect(entry.maxLines, 1);
      expect(entry.overflow, TextOverflow.ellipsis);
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: _legend(long), matching: find.byType(RichText)),
      );
      expect(paragraph.didExceedMaxLines, isTrue);
      expect(tester.getSize(_legend(long)).width, lessThanOrEqualTo(120));
      expect(tester.getSize(_legend(long)).height, moreOrLessEquals(tester.getSize(_legend("Low")).height));
    });

    testWidgets("legend dots use the category fill", (WidgetTester tester) async {
      await _pump(tester, _strip(values: <String>["mid"]));

      final Iterable<Color?> dotColours = tester
          .widgetList<DecoratedBox>(_dots(_inStrip(find.byType(Wrap))))
          .map((DecoratedBox box) => (box.decoration as BoxDecoration).color);
      expect(dotColours, <Color>[_tone(tester, StatusTone.info).container, _tone(tester, StatusTone.success).container]);
    });

    testWidgets("showLegend: false hides every legend", (WidgetTester tester) async {
      await _pump(
        tester,
        _strip(
          values: <String>["mid"],
          comparison: StatusStripSeries<String>(values: _values(<String>["high"]), label: "B"),
          showLegend: false,
        ),
      );

      expect(_inStrip(find.byType(Wrap)), findsNothing);
      expect(_legend("Low"), findsNothing);
      expect(find.textContaining(_comparisonLabelledKey), findsNothing);
    });

    testWidgets("no legend when no category is present and no marker is shown", (WidgetTester tester) async {
      await _pump(tester, _strip(values: List<String>.filled(12, "zzz")));

      expect(_inStrip(find.byType(Wrap)), findsNothing);
    });
  });

  group("comparison", () {
    testWidgets("splits each cell: primary on top, comparison below", (WidgetTester tester) async {
      await _pump(
        tester,
        _strip(
          values: <String>["low", "mid"],
          comparison: StatusStripSeries<String>(values: _values(<String>["high", "zzz"]), label: "B"),
        ),
      );

      expect(_fills(tester, "P1"), <Color>[_tone(tester, StatusTone.info).container, _tone(tester, StatusTone.danger).container]);
      expect(_fills(tester, "P2"), <Color>[_tone(tester, StatusTone.success).container, _scheme(tester).surface]);
      expect(_borders(tester, "P2"), <Color?>[null, _scheme(tester).outlineVariant]);
      final Finder halves = find.descendant(of: _cell("P1"), matching: find.byType(DecoratedBox));
      expect(tester.getTopLeft(halves.first).dy, lessThan(tester.getTopLeft(halves.last).dy));
      expect(tester.getSize(halves.first).height, moreOrLessEquals(12));
      expect(tester.widget<Text>(find.text("P1")).style?.color, _tone(tester, StatusTone.info).onContainer);
      expect(_legend("High"), findsOneWidget);
    });

    testWidgets("shows the two-entry legend with the series names", (WidgetTester tester) async {
      await _pump(
        tester,
        StatusStrip<String>(
          periodLabels: _periods,
          categories: _categories,
          primary: StatusStripSeries<String>(values: _values(<String>[]), label: "A"),
          comparison: StatusStripSeries<String>(values: _values(<String>["high"]), label: "B"),
        ),
        // Wide enough for both raw keys on one legend line.
        width: 780,
      );

      expect(_legend(_referenceLabelledKey), findsOneWidget);
      expect(_legend(_comparisonLabelledKey), findsOneWidget);
      expect(tester.widget<Text>(_legend(_referenceLabelledKey)).style?.color, _scheme(tester).primary);
      expect(tester.widget<Text>(_legend(_comparisonLabelledKey)).style?.color, _scheme(tester).tertiary);
      expect(
        tester.getTopLeft(_legend(_referenceLabelledKey)).dx,
        lessThan(tester.getTopLeft(_legend(_comparisonLabelledKey)).dx),
      );
    });

    testWidgets("null series labels fall back to the built-in names", (WidgetTester tester) async {
      await _pump(
        tester,
        _strip(comparison: StatusStripSeries<String>(values: _values(<String>["high"]))),
      );

      expect(_legend(_referenceKey), findsOneWidget);
      expect(_legend(_comparisonKey), findsOneWidget);
      expect(find.textContaining(_referenceLabelledKey), findsNothing);
    });

    testWidgets("single and agreement modes show no comparison legend", (WidgetTester tester) async {
      await _pump(
        tester,
        Column(
          children: <Widget>[
            _strip(values: <String>["mid"]),
            _strip(agreementSeries: <List<String>>[_values(<String>["low"]), _values(<String>["mid"])]),
          ],
        ),
      );

      expect(find.textContaining(_referenceKey), findsNothing);
      expect(find.textContaining(_comparisonKey), findsNothing);
    });
  });

  group("agreement", () {
    // P1 all equal, P2 two of three agree, P3 all differ, P4–P12 all "low".
    final List<List<String>> threeRows = <List<String>>[
      _values(<String>["low", "low", "low"]),
      _values(<String>["low", "low", "mid"]),
      _values(<String>["low", "mid", "high"]),
    ];

    testWidgets("partial agreement draws a warning corner dot", (WidgetTester tester) async {
      await _pump(tester, _strip(agreementSeries: threeRows));

      expect(_dots(_cell("P1")), findsNothing);
      expect(_dots(_cell("P3")), findsNothing);
      expect(_dots(_cell("P2")), findsOneWidget);
      final BoxDecoration dot = tester.widget<DecoratedBox>(_dots(_cell("P2"))).decoration as BoxDecoration;
      expect(dot.color, _tone(tester, StatusTone.warning).foreground);
      expect(tester.getSize(_dots(_cell("P2"))), const Size(5, 5));
      expect(tester.getBottomRight(_dots(_cell("P2"))), tester.getBottomRight(_cell("P2")) - const Offset(2, 2));
      expect(_legend(_partialKey), findsOneWidget);
    });

    testWidgets("full disagreement draws a dashed error outline", (WidgetTester tester) async {
      await _pump(tester, _strip(agreementSeries: threeRows));

      final Finder outline = find.descendant(of: _cell("P3"), matching: find.byType(CustomPaint));
      expect(outline, findsOneWidget);
      expect(find.descendant(of: _cell("P1"), matching: find.byType(CustomPaint)), findsNothing);
      expect(find.descendant(of: _cell("P2"), matching: find.byType(CustomPaint)), findsNothing);
      expect(tester.renderObject(outline), paints..line(color: _scheme(tester).error, strokeWidth: 1.5));
      expect(_legend(_fullKey), findsOneWidget);
      // One outline in the cell, one glyph in the legend.
      expect(_inStrip(find.byType(CustomPaint)), findsNWidgets(2));
    });

    testWidgets("markers stay drawn and inside narrow cells", (WidgetTester tester) async {
      // 80 px / 12 periods → cells of about 4.8 × 24.
      await _pump(tester, _strip(agreementSeries: threeRows), width: 80);

      expect(tester.takeException(), isNull);
      final Rect cell = tester.getRect(_cell("P2"));
      expect(cell.width, lessThan(6));
      final Rect dot = tester.getRect(_dots(_cell("P2")));
      expect(dot.width, greaterThan(0));
      expect(dot.left, greaterThanOrEqualTo(cell.left));
      expect(dot.right, lessThanOrEqualTo(cell.right));
      expect(dot.top, greaterThanOrEqualTo(cell.top));
      expect(dot.bottom, lessThanOrEqualTo(cell.bottom));
      final Finder outline = find.descendant(of: _cell("P3"), matching: find.byType(CustomPaint));
      expect(tester.renderObject(outline), paints..line(color: _scheme(tester).error));
      expect(tester.renderObject(outline), paints..something(_isTopDash));
      expect(_legend(_partialKey), findsOneWidget);
      expect(_legend(_fullKey), findsOneWidget);
    });

    testWidgets("rows that all agree show no marker and no marker legend", (WidgetTester tester) async {
      await _pump(
        tester,
        _strip(agreementSeries: <List<String>>[_values(<String>[]), _values(<String>[]), _values(<String>[])]),
      );

      expect(_inStrip(find.byType(CustomPaint)), findsNothing);
      expect(_dots(_inStrip(find.byType(Row))), findsNothing);
      expect(_legend(_partialKey), findsNothing);
      expect(_legend(_fullKey), findsNothing);
    });

    testWidgets("two rows that differ are a full disagreement", (WidgetTester tester) async {
      await _pump(
        tester,
        _strip(agreementSeries: <List<String>>[_values(<String>["low"]), _values(<String>["mid"])]),
      );

      expect(find.descendant(of: _cell("P1"), matching: find.byType(CustomPaint)), findsOneWidget);
      expect(_legend(_partialKey), findsNothing);
    });

    testWidgets("a single row shows no marker", (WidgetTester tester) async {
      await _pump(tester, _strip(agreementSeries: <List<String>>[_values(<String>["mid"])]));

      expect(tester.takeException(), isNull);
      expect(_inStrip(find.byType(CustomPaint)), findsNothing);
      expect(_legend(_partialKey), findsNothing);
    });

    testWidgets("four rows with three distinct values are a partial agreement", (WidgetTester tester) async {
      await _pump(
        tester,
        _strip(agreementSeries: <List<String>>[
          _values(<String>["low"]),
          _values(<String>["low"]),
          _values(<String>["mid"]),
          _values(<String>["high"]),
        ]),
      );

      expect(_dots(_cell("P1")), findsOneWidget);
      expect(find.descendant(of: _cell("P1"), matching: find.byType(CustomPaint)), findsNothing);
    });

    testWidgets("the cell fill still comes from the primary series", (WidgetTester tester) async {
      await _pump(tester, _strip(values: <String>["high"], agreementSeries: threeRows));

      expect(_fills(tester, "P1"), <Color>[_tone(tester, StatusTone.danger).container]);
      expect(_legend("Mid"), findsNothing);
    });
  });

  group("asserts", () {
    testWidgets("primary length must match the periods", (WidgetTester tester) async {
      await _pump(
        tester,
        StatusStrip<String>(
          periodLabels: _periods,
          categories: _categories,
          primary: StatusStripSeries<String>(values: List<String>.filled(3, "low")),
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });

    test("comparison and agreementSeries are exclusive", () {
      final List<String> values = _values(<String>[]);
      expect(
        () => StatusStrip<String>(
          periodLabels: _periods,
          categories: _categories,
          primary: StatusStripSeries<String>(values: values),
          comparison: StatusStripSeries<String>(values: values),
          agreementSeries: <List<String>>[values, values],
        ),
        throwsAssertionError,
      );
    });
  });

  group("semantics", () {
    testWidgets("each cell is one node; markers are appended", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(
        tester,
        _strip(agreementSeries: <List<String>>[
          _values(<String>["low", "low", "low"]),
          _values(<String>["low", "low", "mid"]),
          _values(<String>["low", "mid", "high"]),
        ]),
      );

      expect(find.bySemanticsLabel(_cellKey), findsNWidgets(10));
      // Raw keys: the joined text is the cell_marker key itself.
      expect(find.bySemanticsLabel(_cellMarkerKey), findsNWidgets(2));
      handle.dispose();
    });

    testWidgets("comparison cells use the comparison label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _strip(comparison: StatusStripSeries<String>(values: _values(<String>[]))));

      expect(find.bySemanticsLabel(_cellComparisonKey), findsNWidgets(12));
      handle.dispose();
    });

    testWidgets("reads the full month name and the category in French", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpFrench(tester, (BuildContext context) {
        final String locale = context.locale.toLanguageTag();
        return StatusStrip<String>(
          periodLabels: StatusStrip.monthLabels(locale),
          periodSemanticLabels: StatusStrip.monthLabels(locale, abbreviated: false),
          categories: _categories,
          primary: StatusStripSeries<String>(values: _values(<String>["low", "low", "low", "zzz"])),
          agreementSeries: <List<String>>[
            _values(<String>["low", "low", "low"]),
            _values(<String>["low", "low", "mid"]),
            _values(<String>["low", "mid", "high"]),
          ],
        );
      });

      expect(find.text("janv."), findsOneWidget);
      expect(find.bySemanticsLabel("janvier : Low"), findsOneWidget);
      expect(find.bySemanticsLabel("février : Low, Accord partiel"), findsOneWidget);
      expect(find.bySemanticsLabel("mars : Low, Désaccord total"), findsOneWidget);
      expect(find.bySemanticsLabel("avril : Inconnu"), findsOneWidget);
      expect(_legend("Accord partiel"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("names the comparison series in French", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpFrench(tester, (BuildContext context) {
        return StatusStrip<String>(
          periodLabels: _periods,
          categories: _categories,
          primary: StatusStripSeries<String>(values: _values(<String>[]), label: "Série A"),
          comparison: StatusStripSeries<String>(values: _values(<String>["high"]), label: "Série B"),
        );
      });

      expect(_legend("Série A (réf.)"), findsOneWidget);
      expect(_legend("Série B (test)"), findsOneWidget);
      expect(find.bySemanticsLabel("P1 : Low / High"), findsOneWidget);
      handle.dispose();
    });
  });

  group("monthLabels", () {
    setUpAll(() => initializeDateFormatting("fr"));

    test("abbreviated English months", () {
      expect(
        StatusStrip.monthLabels("en"),
        <String>["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
      );
      expect(StatusStrip.monthLabels("en", abbreviated: false).first, "January");
    });

    test("French months", () {
      expect(StatusStrip.monthLabels("fr").first, "janv.");
      expect(StatusStrip.monthLabels("fr", abbreviated: false), hasLength(12));
      expect(StatusStrip.monthLabels("fr", abbreviated: false).last, "décembre");
    });
  });
}

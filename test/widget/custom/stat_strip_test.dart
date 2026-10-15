// stat_strip_test.dart
//
// Widget tests for StatStrip: one outlined MetricTile per item with every
// field forwarded, the empty strip, the row layout (equal widths and heights,
// gaps), the two-column grid sized from the parent width, the outer padding,
// value and caption tones, per-tile semantics, narrow widths and the dark
// theme.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/MetricTile/index.dart";
import "package:flutter_skeleton/widgets/custom/StatStrip/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

/// Four tiles: caption + unit, toned value + caption, toned value, bare value.
const List<StatStripItem> _items = <StatStripItem>[
  StatStripItem(label: "Requests", value: "12 400", icon: Icons.bar_chart, caption: "+8 % vs last week"),
  StatStripItem(
    label: "Latency",
    value: "650",
    unit: "ms",
    valueTone: StatusTone.success,
    caption: "Within target",
  ),
  StatStripItem(label: "Errors", value: "2.4", unit: "%", valueTone: StatusTone.warning),
  StatStripItem(label: "Users", value: "318"),
];

/// Strip without outer padding, so tile rects start at the strip edges.
const EdgeInsets _noPadding = EdgeInsets.zero;

Finder _tile(int index) => find.byType(MetricTile).at(index);

Rect _rect(WidgetTester tester, int index) => tester.getRect(_tile(index));

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(StatStrip))).colorScheme;

ToneColors _tone(WidgetTester tester, StatusTone tone) {
  return StatusTones.colorsOf(tester.element(find.byType(StatStrip)), tone);
}

BoxDecoration _decoration(WidgetTester tester, int index) {
  final Finder container = find.descendant(of: _tile(index), matching: find.byType(Container)).first;
  return tester.widget<Container>(container).decoration! as BoxDecoration;
}

/// Pumps [strip] at the top-left corner of an 800 dp-wide surface, inside a
/// box [width] dp wide.
Future<void> _pump(WidgetTester tester, StatStrip strip, {double width = 480, ThemeData? theme}) {
  return pumpApp(
    tester,
    Align(alignment: Alignment.topLeft, child: SizedBox(width: width, child: strip)),
    surfaceSize: const Size(800, 600),
    theme: theme,
  );
}

void main() {
  group("structure", _structureTests);
  group("row layout", _rowTests);
  group("grid layout", _gridTests);
  group("padding", _paddingTests);
  group("tones", _toneTests);
  group("semantics", _semanticsTests);
  group("narrow widths", _narrowTests);
  group("dark theme", _darkThemeTests);
}

void _structureTests() {
  testWidgets("renders one outlined MetricTile per item, in order", (WidgetTester tester) async {
    await _pump(tester, const StatStrip(items: _items));

    expect(find.byType(MetricTile), findsNWidgets(4));
    final List<MetricTile> tiles = tester.widgetList<MetricTile>(find.byType(MetricTile)).toList();
    expect(tiles.map((MetricTile tile) => tile.label), <String>["Requests", "Latency", "Errors", "Users"]);
    expect(tiles.every((MetricTile tile) => tile.outlined), isTrue);
  });

  testWidgets("forwards every item field to its MetricTile", (WidgetTester tester) async {
    await _pump(
      tester,
      const StatStrip(
        items: <StatStripItem>[
          StatStripItem(
            label: "Errors",
            value: "2.4",
            unit: "%",
            icon: Icons.bar_chart,
            valueTone: StatusTone.danger,
            caption: "Above target",
            captionTone: StatusTone.warning,
            semanticsLabel: "Errors above target",
          ),
        ],
      ),
    );

    final MetricTile tile = tester.widget<MetricTile>(find.byType(MetricTile));
    expect(tile.label, "Errors");
    expect(tile.value, "2.4");
    expect(tile.unit, "%");
    expect(tile.icon, Icons.bar_chart);
    expect(tile.valueTone, StatusTone.danger);
    expect(tile.caption, "Above target");
    expect(tile.captionTone, StatusTone.warning);
    expect(tile.semanticsLabel, "Errors above target");
  });

  testWidgets("item defaults: no value, neutral caption tone", (WidgetTester tester) async {
    await _pump(tester, const StatStrip(items: <StatStripItem>[StatStripItem(label: "Users")]));

    final MetricTile tile = tester.widget<MetricTile>(find.byType(MetricTile));
    expect(tile.value, isNull);
    expect(tile.unit, isNull);
    expect(tile.icon, isNull);
    expect(tile.valueTone, isNull);
    expect(tile.caption, isNull);
    expect(tile.captionTone, StatusTone.neutral);
    expect(tile.semanticsLabel, isNull);
    expect(find.text("—"), findsOneWidget);
  });

  testWidgets("an empty list renders nothing, padding included", (WidgetTester tester) async {
    await pumpApp(tester, const Align(alignment: Alignment.topLeft, child: StatStrip(items: <StatStripItem>[])));

    expect(find.byType(MetricTile), findsNothing);
    expect(find.descendant(of: find.byType(StatStrip), matching: find.byType(Padding)), findsNothing);
    expect(tester.getSize(find.byType(StatStrip)), Size.zero);
    expect(tester.takeException(), isNull);
  });
}

void _rowTests() {
  testWidgets("is the default: tiles share a top edge, a width and a height", (WidgetTester tester) async {
    await _pump(tester, const StatStrip(items: _items, padding: _noPadding));

    expect(const StatStrip(items: _items).layout, StatStripLayout.row);
    const double width = (480 - 3 * kDefaultPadding) / 4;
    for (int index = 0; index < 4; index++) {
      expect(_rect(tester, index).top, _rect(tester, 0).top);
      expect(_rect(tester, index).width, moreOrLessEquals(width));
      // Tiles 0 and 1 have a caption, 2 and 3 do not: still one height.
      expect(_rect(tester, index).height, moreOrLessEquals(_rect(tester, 0).height));
    }
  });

  testWidgets("tiles are kDefaultPadding apart and fill the width", (WidgetTester tester) async {
    await _pump(tester, const StatStrip(items: _items, padding: _noPadding));

    final Rect strip = tester.getRect(find.byType(StatStrip));
    expect(_rect(tester, 0).left, strip.left);
    expect(_rect(tester, 3).right, moreOrLessEquals(strip.right));
    for (int index = 1; index < 4; index++) {
      expect(_rect(tester, index).left - _rect(tester, index - 1).right, moreOrLessEquals(kDefaultPadding));
    }
  });

  testWidgets("the strip is as tall as its tallest tile", (WidgetTester tester) async {
    await _pump(tester, const StatStrip(items: _items, padding: _noPadding));

    expect(tester.getSize(find.byType(StatStrip)).height, moreOrLessEquals(_rect(tester, 0).height));
  });
}

void _gridTests() {
  testWidgets("4 items: two rows of two tiles sized from the parent width", (WidgetTester tester) async {
    await _pump(tester, const StatStrip(items: _items, layout: StatStripLayout.grid), width: 360);

    const double width = (360 - 2 * 2 * kDefaultPadding - kDefaultPadding) / 2;
    for (int index = 0; index < 4; index++) {
      expect(_rect(tester, index).width, moreOrLessEquals(width));
    }
    expect(_rect(tester, 1).top, _rect(tester, 0).top);
    expect(_rect(tester, 3).top, _rect(tester, 2).top);
    expect(_rect(tester, 2).top - _rect(tester, 0).bottom, moreOrLessEquals(kDefaultPadding));
    expect(_rect(tester, 1).left - _rect(tester, 0).right, moreOrLessEquals(kDefaultPadding));
    expect(_rect(tester, 2).left, _rect(tester, 0).left);
    expect(tester.takeException(), isNull);
  });

  testWidgets("3 items: the last tile wraps at half width on the start edge", (WidgetTester tester) async {
    await _pump(tester, StatStrip(items: _items.sublist(0, 3), layout: StatStripLayout.grid), width: 360);

    expect(find.byType(MetricTile), findsNWidgets(3));
    expect(_rect(tester, 2).width, moreOrLessEquals(_rect(tester, 0).width));
    expect(_rect(tester, 2).left, _rect(tester, 0).left);
    expect(_rect(tester, 2).top, greaterThan(_rect(tester, 0).bottom));
  });

  testWidgets("tiles of a row share its height", (WidgetTester tester) async {
    await _pump(
      tester,
      const StatStrip(
        layout: StatStripLayout.grid,
        items: <StatStripItem>[
          StatStripItem(label: "Users", value: "318"),
          StatStripItem(label: "Requests", value: "12 400", caption: "+8 % vs last week"),
        ],
      ),
      width: 360,
    );

    expect(_rect(tester, 0).height, moreOrLessEquals(_rect(tester, 1).height));
  });

  testWidgets("follows the parent width, not the screen width", (WidgetTester tester) async {
    await _pump(tester, const StatStrip(items: _items, layout: StatStripLayout.grid, padding: _noPadding), width: 300);

    expect(_rect(tester, 1).right, moreOrLessEquals(300));
    expect(_rect(tester, 0).width, moreOrLessEquals((300 - kDefaultPadding) / 2));
  });
}

void _paddingTests() {
  testWidgets("defaults to 16 × 8 dp around the strip", (WidgetTester tester) async {
    await _pump(tester, const StatStrip(items: _items));

    final Rect strip = tester.getRect(find.byType(StatStrip));
    expect(_rect(tester, 0).topLeft - strip.topLeft, const Offset(2 * kDefaultPadding, kDefaultPadding));
    expect(strip.right - _rect(tester, 3).right, moreOrLessEquals(2 * kDefaultPadding));
    expect(strip.bottom - _rect(tester, 0).bottom, moreOrLessEquals(kDefaultPadding));
  });

  testWidgets("a custom padding replaces the default", (WidgetTester tester) async {
    await _pump(
      tester,
      const StatStrip(items: _items, padding: EdgeInsets.fromLTRB(4, 12, 4, 0)),
    );

    final Rect strip = tester.getRect(find.byType(StatStrip));
    expect(_rect(tester, 0).topLeft - strip.topLeft, const Offset(4, 12));
    expect(strip.bottom, moreOrLessEquals(_rect(tester, 0).bottom));
  });
}

void _toneTests() {
  testWidgets("the value tone colours the value; no tone keeps cs.onSurface", (WidgetTester tester) async {
    await _pump(tester, const StatStrip(items: _items));

    expect(tester.widget<Text>(find.text("2.4")).style!.color, _tone(tester, StatusTone.warning).foreground);
    expect(tester.widget<Text>(find.text("650")).style!.color, _tone(tester, StatusTone.success).foreground);
    expect(tester.widget<Text>(find.text("318")).style!.color, _scheme(tester).onSurface);
    // A toned value is paired with its tone icon.
    expect(find.byIcon(StatusTone.warning.icon), findsOneWidget);
  });

  testWidgets("the caption tone colours the caption", (WidgetTester tester) async {
    await _pump(
      tester,
      const StatStrip(
        items: <StatStripItem>[
          StatStripItem(label: "Errors", value: "2.4", caption: "Above target", captionTone: StatusTone.danger),
          StatStripItem(label: "Users", value: "318", caption: "Stable"),
        ],
      ),
    );

    expect(tester.widget<Text>(find.text("Above target")).style!.color, _tone(tester, StatusTone.danger).foreground);
    expect(tester.widget<Text>(find.text("Stable")).style!.color, _scheme(tester).onSurfaceVariant);
  });
}

void _semanticsTests() {
  testWidgets("each tile is one node labelled \"label, value unit, caption\"", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await _pump(tester, const StatStrip(items: _items));

    expect(find.bySemanticsLabel("Latency, 650 ms, Within target"), findsOneWidget);
    expect(find.bySemanticsLabel("Errors, 2.4 %"), findsOneWidget);
    expect(find.bySemanticsLabel("Users, 318"), findsOneWidget);
    expect(find.bySemanticsLabel("650"), findsNothing);
    handle.dispose();
  });

  testWidgets("semanticsLabel replaces the default label", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await _pump(
      tester,
      const StatStrip(
        items: <StatStripItem>[StatStripItem(label: "Errors", value: "2.4", semanticsLabel: "Errors: 2.4 %, high")],
      ),
    );

    expect(find.bySemanticsLabel("Errors: 2.4 %, high"), findsOneWidget);
    expect(find.bySemanticsLabel("Errors, 2.4"), findsNothing);
    handle.dispose();
  });

  testWidgets("a missing value is announced with the no-value text", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await _pump(tester, const StatStrip(items: <StatStripItem>[StatStripItem(label: "Users")]));

    expect(find.bySemanticsLabel("Users, custom.metric_tile.no_value"), findsOneWidget);
    handle.dispose();
  });
}

void _narrowTests() {
  testWidgets("long labels wrap in a narrow row without overflow", (WidgetTester tester) async {
    await _pump(
      tester,
      const StatStrip(
        items: <StatStripItem>[
          StatStripItem(label: "Average response time of the service", value: "650"),
          StatStripItem(label: "Errors", value: "2"),
          StatStripItem(label: "Users", value: "318"),
          StatStripItem(label: "Requests", value: "12"),
        ],
      ),
      width: 320,
    );

    expect(tester.takeException(), isNull);
    expect(_rect(tester, 0).height, moreOrLessEquals(_rect(tester, 3).height));
  });

  testWidgets("a long value is ellipsized on one line", (WidgetTester tester) async {
    const String value = "123 456 789 012 345 678 901 234 567 890";
    await _pump(
      tester,
      const StatStrip(
        layout: StatStripLayout.grid,
        items: <StatStripItem>[
          StatStripItem(label: "Requests", value: value, unit: "/s"),
          StatStripItem(label: "Users", value: "318"),
        ],
      ),
      width: 320,
    );

    expect(tester.takeException(), isNull);
    final Text text = tester.widget<Text>(find.text(value));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(find.text("/s"), findsOneWidget);
  });
}

void _darkThemeTests() {
  testWidgets("renders under AppTheme.dark() with dark tokens and tones", (WidgetTester tester) async {
    await _pump(tester, const StatStrip(items: _items, layout: StatStripLayout.grid), theme: AppTheme.dark());

    expect(tester.takeException(), isNull);
    final ColorScheme cs = _scheme(tester);
    expect(cs.brightness, Brightness.dark);
    final BoxDecoration decoration = _decoration(tester, 0);
    expect(decoration.color, cs.surfaceContainerHighest);
    expect((decoration.border! as Border).top.color, cs.outlineVariant);
    final ToneColors warning = _tone(tester, StatusTone.warning);
    expect(tester.widget<Text>(find.text("2.4")).style!.color, warning.foreground);
    expect(warning.foreground, isNot(StatusTones.fromScheme(AppTheme.light().colorScheme).warning.foreground));
  });
}

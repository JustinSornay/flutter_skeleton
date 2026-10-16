// delta_cards_test.dart
//
// Widget tests for DeltaCards: the unpadded StatStrip row of outlined
// MetricTiles fed from DeltaCardItems, default and custom trend captions,
// caption tones, the factories rendered end to end, equal widths and
// heights, per-card semantics, the 2-to-4 item contract, narrow widths and
// the dark theme.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/DeltaCards/index.dart";
import "package:flutter_skeleton/widgets/custom/MetricTile/index.dart";
import "package:flutter_skeleton/widgets/custom/StatStrip/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

/// Three cards: adverse rise, warning drop, favourable categorical change
/// with a custom caption.
const List<DeltaCardItem> _items = <DeltaCardItem>[
  DeltaCardItem(label: "Latency", value: "↑ +12 ms", trend: DeltaTrend.increase, tone: StatusTone.danger),
  DeltaCardItem(label: "Throughput", value: "↓ -40 /s", trend: DeltaTrend.decrease, tone: StatusTone.warning),
  DeltaCardItem(
    label: "Plan",
    value: "Standard",
    trend: DeltaTrend.shift,
    tone: StatusTone.success,
    trendLabel: "Upgraded",
  ),
];

Finder _tile(int index) => find.byType(MetricTile).at(index);

Rect _rect(WidgetTester tester, int index) => tester.getRect(_tile(index));

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(DeltaCards))).colorScheme;

ToneColors _tone(WidgetTester tester, StatusTone tone) {
  return StatusTones.colorsOf(tester.element(find.byType(DeltaCards)), tone);
}

Color? _textColor(WidgetTester tester, String data) => tester.widget<Text>(find.text(data)).style!.color;

/// Pumps [cards] at the top-left corner of an 800 dp-wide surface, inside a
/// box [width] dp wide.
Future<void> _pump(WidgetTester tester, DeltaCards cards, {double width = 480, ThemeData? theme}) {
  return pumpApp(
    tester,
    Align(alignment: Alignment.topLeft, child: SizedBox(width: width, child: cards)),
    surfaceSize: const Size(800, 600),
    theme: theme,
  );
}

/// Matches the item-count assert of DeltaCards (not any other FlutterError,
/// which also implements AssertionError) for a list of [count] items.
Matcher _itemCountAssert(int count) {
  return isA<AssertionError>().having(
    (AssertionError error) => error.message,
    "message",
    "DeltaCards needs 2 to 4 items, got $count",
  );
}

/// [count] neutral cards labelled "Item 0", "Item 1"…
List<DeltaCardItem> _plainItems(int count) {
  return <DeltaCardItem>[
    for (int index = 0; index < count; index++) DeltaCardItem(label: "Item $index", value: "$index"),
  ];
}

void main() {
  group("structure", _structureTests);
  group("captions", _captionTests);
  group("tones", _toneTests);
  group("factories", _factoryTests);
  group("layout", _layoutTests);
  group("semantics", _semanticsTests);
  group("item count", _itemCountTests);
  group("narrow widths", _narrowTests);
  group("dark theme", _darkThemeTests);
}

void _structureTests() {
  testWidgets("renders an unpadded StatStrip row of outlined MetricTiles", (WidgetTester tester) async {
    await _pump(tester, const DeltaCards(items: _items));

    final StatStrip strip = tester.widget<StatStrip>(find.byType(StatStrip));
    expect(strip.layout, StatStripLayout.row);
    expect(strip.padding, EdgeInsets.zero);
    expect(find.byType(MetricTile), findsNWidgets(3));
    final List<MetricTile> tiles = tester.widgetList<MetricTile>(find.byType(MetricTile)).toList();
    expect(tiles.map((MetricTile tile) => tile.label), <String>["Latency", "Throughput", "Plan"]);
    expect(tiles.map((MetricTile tile) => tile.value), <String>["↑ +12 ms", "↓ -40 /s", "Standard"]);
    expect(tiles.every((MetricTile tile) => tile.outlined), isTrue);
  });

  testWidgets("shows each label upper-cased and each value as given", (WidgetTester tester) async {
    await _pump(tester, const DeltaCards(items: _items));

    expect(find.text("LATENCY"), findsOneWidget);
    expect(find.text("THROUGHPUT"), findsOneWidget);
    expect(find.text("PLAN"), findsOneWidget);
    expect(find.text("↑ +12 ms"), findsOneWidget);
    expect(find.text("↓ -40 /s"), findsOneWidget);
    expect(find.text("Standard"), findsOneWidget);
  });

  testWidgets("the value carries no tone: the meaning stays in the caption", (WidgetTester tester) async {
    await _pump(tester, const DeltaCards(items: _items));

    final List<MetricTile> tiles = tester.widgetList<MetricTile>(find.byType(MetricTile)).toList();
    expect(tiles.every((MetricTile tile) => tile.valueTone == null), isTrue);
    expect(_textColor(tester, "↑ +12 ms"), _scheme(tester).onSurface);
  });
}

void _captionTests() {
  testWidgets("a null trendLabel falls back to the trend's key", (WidgetTester tester) async {
    await _pump(tester, const DeltaCards(items: _items));

    expect(find.text("custom.delta_cards.increase"), findsOneWidget);
    expect(find.text("custom.delta_cards.decrease"), findsOneWidget);
  });

  testWidgets("a trendLabel replaces the default caption", (WidgetTester tester) async {
    await _pump(tester, const DeltaCards(items: _items));

    expect(find.text("Upgraded"), findsOneWidget);
    expect(find.text("custom.delta_cards.shift"), findsNothing);
  });

  testWidgets("an empty trendLabel and a stable trend use the default keys", (WidgetTester tester) async {
    await _pump(
      tester,
      const DeltaCards(
        items: <DeltaCardItem>[
          DeltaCardItem(label: "Mode", value: "B", trend: DeltaTrend.shift, trendLabel: ""),
          DeltaCardItem(label: "Users", value: "318"),
        ],
      ),
    );

    expect(find.text("custom.delta_cards.shift"), findsOneWidget);
    expect(find.text("custom.delta_cards.stable"), findsOneWidget);
  });
}

void _toneTests() {
  testWidgets("the item tone is forwarded as the caption tone", (WidgetTester tester) async {
    await _pump(tester, const DeltaCards(items: _items));

    final List<MetricTile> tiles = tester.widgetList<MetricTile>(find.byType(MetricTile)).toList();
    expect(
      tiles.map((MetricTile tile) => tile.captionTone),
      <StatusTone>[StatusTone.danger, StatusTone.warning, StatusTone.success],
    );
  });

  testWidgets("captions take the tone foreground; neutral is onSurfaceVariant", (WidgetTester tester) async {
    await _pump(
      tester,
      const DeltaCards(
        items: <DeltaCardItem>[
          DeltaCardItem(label: "A", value: "1", trendLabel: "Bad", tone: StatusTone.danger),
          DeltaCardItem(label: "B", value: "2", trendLabel: "Watch", tone: StatusTone.warning),
          DeltaCardItem(label: "C", value: "3", trendLabel: "Good", tone: StatusTone.success),
          DeltaCardItem(label: "D", value: "4", trendLabel: "Plain"),
        ],
      ),
    );

    expect(_textColor(tester, "Bad"), _tone(tester, StatusTone.danger).foreground);
    expect(_textColor(tester, "Watch"), _tone(tester, StatusTone.warning).foreground);
    expect(_textColor(tester, "Good"), _tone(tester, StatusTone.success).foreground);
    expect(_textColor(tester, "Plain"), _scheme(tester).onSurfaceVariant);
  });
}

void _factoryTests() {
  testWidgets("numeric and categorical items render their derived value, caption and tone", (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      DeltaCards(
        items: <DeltaCardItem>[
          DeltaCardItem.numeric(label: "Load", before: 12.5, after: 15.8, unit: " %", higherIsWorse: true),
          DeltaCardItem.numeric(
            label: "Volume",
            before: 680,
            after: 635,
            unit: " u",
            fractionDigits: 0,
            adverseTone: StatusTone.warning,
          ),
          DeltaCardItem.categorical(label: "Mode", before: "a", after: "b", value: "B"),
        ],
      ),
    );

    expect(find.text("↑ +3.3 %"), findsOneWidget);
    expect(find.text("↓ -45 u"), findsOneWidget);
    expect(find.text("B"), findsOneWidget);
    expect(_textColor(tester, "custom.delta_cards.increase"), _tone(tester, StatusTone.danger).foreground);
    expect(_textColor(tester, "custom.delta_cards.decrease"), _tone(tester, StatusTone.warning).foreground);
    expect(_textColor(tester, "custom.delta_cards.shift"), _tone(tester, StatusTone.danger).foreground);
  });
}

void _layoutTests() {
  testWidgets("cards share the width, a top edge and kDefaultPadding gaps", (WidgetTester tester) async {
    await _pump(tester, const DeltaCards(items: _items));

    final Rect strip = tester.getRect(find.byType(DeltaCards));
    const double width = (480 - 2 * kDefaultPadding) / 3;
    expect(_rect(tester, 0).left, strip.left);
    expect(_rect(tester, 2).right, moreOrLessEquals(strip.right));
    for (int index = 0; index < 3; index++) {
      expect(_rect(tester, index).top, strip.top);
      expect(_rect(tester, index).width, moreOrLessEquals(width));
    }
    expect(_rect(tester, 1).left - _rect(tester, 0).right, moreOrLessEquals(kDefaultPadding));
    expect(_rect(tester, 2).left - _rect(tester, 1).right, moreOrLessEquals(kDefaultPadding));
  });

  testWidgets("a wrapping label makes every card as tall as the tallest", (WidgetTester tester) async {
    await _pump(
      tester,
      const DeltaCards(
        items: <DeltaCardItem>[
          DeltaCardItem(label: "Average response time of every service in the pool", value: "↑ +12 ms"),
          DeltaCardItem(label: "Users", value: "318"),
          DeltaCardItem(label: "Mode", value: "B"),
        ],
      ),
      width: 360,
    );

    // The long label really wraps…
    final double longLabel = tester.getSize(find.text("AVERAGE RESPONSE TIME OF EVERY SERVICE IN THE POOL")).height;
    expect(longLabel, greaterThan(tester.getSize(find.text("USERS")).height));
    // …and the other cards stretch to its height.
    expect(_rect(tester, 1).height, moreOrLessEquals(_rect(tester, 0).height));
    expect(_rect(tester, 2).height, moreOrLessEquals(_rect(tester, 0).height));
    expect(tester.getSize(find.byType(DeltaCards)).height, moreOrLessEquals(_rect(tester, 0).height));
  });

  testWidgets("each card is at least kMinTapTarget tall", (WidgetTester tester) async {
    await _pump(tester, const DeltaCards(items: _items));

    for (int index = 0; index < 3; index++) {
      expect(_rect(tester, index).height, greaterThanOrEqualTo(kMinTapTarget));
    }
  });
}

void _semanticsTests() {
  testWidgets("each card is one node labelled \"label, value, caption\"", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await _pump(tester, const DeltaCards(items: _items));

    expect(find.bySemanticsLabel("Latency, ↑ +12 ms, custom.delta_cards.increase"), findsOneWidget);
    expect(find.bySemanticsLabel("Throughput, ↓ -40 /s, custom.delta_cards.decrease"), findsOneWidget);
    expect(find.bySemanticsLabel("Plan, Standard, Upgraded"), findsOneWidget);
    // The inner texts are not announced a second time.
    expect(find.bySemanticsLabel("Standard"), findsNothing);
    expect(find.bySemanticsLabel("Upgraded"), findsNothing);
    handle.dispose();
  });
}

void _itemCountTests() {
  testWidgets("2 and 4 items are accepted", (WidgetTester tester) async {
    await _pump(tester, DeltaCards(items: _plainItems(2)));
    expect(tester.takeException(), isNull);
    expect(find.byType(MetricTile), findsNWidgets(2));

    await _pump(tester, DeltaCards(items: _plainItems(4)));
    expect(tester.takeException(), isNull);
    expect(find.byType(MetricTile), findsNWidgets(4));
  });

  testWidgets("fewer than 2 items fail the assert", (WidgetTester tester) async {
    await _pump(tester, DeltaCards(items: _plainItems(1)));

    expect(tester.takeException(), _itemCountAssert(1));
  });

  testWidgets("more than 4 items fail the assert", (WidgetTester tester) async {
    await _pump(tester, DeltaCards(items: _plainItems(5)));

    expect(tester.takeException(), _itemCountAssert(5));
  });
}

void _narrowTests() {
  testWidgets("4 cards with long strings fit 320 dp without overflow", (WidgetTester tester) async {
    await _pump(
      tester,
      DeltaCards(
        items: <DeltaCardItem>[
          DeltaCardItem.numeric(
            label: "Average response time of the service",
            before: 1200.5,
            after: 98765.25,
            unit: " requests per second",
            higherIsWorse: true,
          ),
          const DeltaCardItem(label: "Errors", value: "↓ -2", trendLabel: "Much lower than last period"),
          DeltaCardItem.categorical(label: "Mode", before: 1, after: 2, value: "Extended configuration mode"),
          const DeltaCardItem(label: "Users", value: "318"),
        ],
      ),
      width: 320,
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(MetricTile), findsNWidgets(4));
    for (int index = 0; index < 4; index++) {
      expect(_rect(tester, index).height, greaterThanOrEqualTo(kMinTapTarget));
      expect(_rect(tester, index).height, moreOrLessEquals(_rect(tester, 0).height));
    }
  });
}

void _darkThemeTests() {
  testWidgets("renders under AppTheme.dark() with dark tones", (WidgetTester tester) async {
    await _pump(tester, const DeltaCards(items: _items), theme: AppTheme.dark());

    expect(tester.takeException(), isNull);
    final ColorScheme cs = _scheme(tester);
    expect(cs.brightness, Brightness.dark);
    final ToneColors danger = _tone(tester, StatusTone.danger);
    expect(_textColor(tester, "custom.delta_cards.increase"), danger.foreground);
    expect(_textColor(tester, "↑ +12 ms"), cs.onSurface);
    expect(danger.foreground, isNot(StatusTones.fromScheme(AppTheme.light().colorScheme).danger.foreground));
  });
}

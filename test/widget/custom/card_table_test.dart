// card_table_test.dart
//
// Widget tests for CardTable: the empty card (default key and custom
// message), the uppercased header with header semantics, one row per item,
// the built-in text cells (ellipsis, emphasis styles), flex / fixed column
// sizing and alignment, row taps, the 48 dp target, button semantics and the
// row summary, the detail slot (outside the row's tap target and semantics
// node), nested interactive cells, the clip inside the border, the
// constructor asserts, and the ColorScheme tokens under the light and dark
// themes.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/CardTable/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

@immutable
final class _Item {
  final String name;
  final String place;
  final int value;

  const _Item(this.name, this.place, this.value);
}

const List<_Item> _items = <_Item>[
  _Item("Alpha", "Paris", 74),
  _Item("Beta", "Lyon", 61),
  _Item("Gamma", "Nice", 48),
];

/// Four columns: strong text (flex 4), muted text (flex 4), a custom
/// end-aligned value cell (flex 3) and a centred muted text (flex 4).
List<CardTableColumn<_Item>> _columns() {
  return <CardTableColumn<_Item>>[
    CardTableColumn<_Item>.text(
      label: "Name",
      text: (_Item item) => item.name,
      emphasis: CardTableEmphasis.strong,
      flex: 4,
    ),
    CardTableColumn<_Item>.text(label: "Place", text: (_Item item) => item.place, flex: 4),
    CardTableColumn<_Item>(
      label: "Value",
      flex: 3,
      align: TextAlign.end,
      cellBuilder: (BuildContext context, _Item item) => Text("${item.value} %"),
    ),
    CardTableColumn<_Item>.text(
      label: "Code",
      text: (_Item item) => item.name.substring(0, 2).toUpperCase(),
      flex: 4,
      align: TextAlign.center,
    ),
  ];
}

CardTable<_Item> _table({
  List<_Item> rows = _items,
  List<CardTableColumn<_Item>>? columns,
  ValueChanged<_Item>? onRowTap,
  String Function(_Item row)? rowSemanticLabel,
  Widget? Function(BuildContext context, _Item row)? rowDetailBuilder,
  String? emptyMessage,
}) {
  return CardTable<_Item>(
    rows: rows,
    columns: columns ?? _columns(),
    onRowTap: onRowTap,
    rowSemanticLabel: rowSemanticLabel,
    rowDetailBuilder: rowDetailBuilder,
    emptyMessage: emptyMessage,
  );
}

Finder _inTable(Finder matching) {
  return find.descendant(of: find.byType(CardTable<_Item>), matching: matching);
}

/// The column slot (Align) holding [text].
Finder _slotOf(String text) {
  return find.ancestor(of: find.text(text), matching: find.byType(Align)).first;
}

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(CardTable<_Item>))).colorScheme;
}

BoxDecoration? _cardDecoration(WidgetTester tester) {
  return tester.widget<Container>(_inTable(find.byType(Container)).first).decoration as BoxDecoration?;
}

/// The body rows: the DecoratedBoxes drawing a cs.outlineVariant top border.
Finder _rowBoxes(WidgetTester tester) {
  final BoxDecoration rowBorder = BoxDecoration(border: Border(top: BorderSide(color: _scheme(tester).outlineVariant)));
  return _inTable(find.byWidgetPredicate((Widget widget) => widget is DecoratedBox && widget.decoration == rowBorder));
}

void main() {
  group("empty", _emptyTests);
  group("header", _headerTests);
  group("body", _bodyTests);
  group("sizing and alignment", _sizingTests);
  group("interaction", _interactionTests);
  group("semantics and detail", _semanticsAndDetailTests);
  group("asserts", _assertTests);
  group("theme", _themeTests);
}

void _emptyTests() {
  testWidgets("shows the default key and no header", (WidgetTester tester) async {
    await pumpApp(tester, _table(rows: const <_Item>[], onRowTap: (_Item _) {}));

    expect(find.text("custom.card_table.empty"), findsOneWidget);
    expect(find.text("NAME"), findsNothing);
    expect(_inTable(find.byType(InkWell)), findsNothing);
  });

  testWidgets("shows the custom message instead of the key", (WidgetTester tester) async {
    await pumpApp(tester, _table(rows: const <_Item>[], emptyMessage: "Nothing yet."));

    expect(find.text("Nothing yet."), findsOneWidget);
    expect(find.text("custom.card_table.empty"), findsNothing);
  });

  testWidgets("keeps the card frame", (WidgetTester tester) async {
    await pumpApp(tester, _table(rows: const <_Item>[]));
    final ColorScheme cs = _scheme(tester);

    final BoxDecoration? decoration = _cardDecoration(tester);
    expect(decoration?.color, cs.surfaceContainerLowest);
    expect(decoration?.border, Border.all(color: cs.outlineVariant));
    expect(decoration?.borderRadius, BorderRadius.circular(12));
    expect(tester.widget<Text>(find.text("custom.card_table.empty")).style?.color, cs.onSurfaceVariant);
  });
}

void _headerTests() {
  testWidgets("renders every label uppercased, in column order", (WidgetTester tester) async {
    await pumpApp(tester, _table(), surfaceSize: const Size(560, 400));

    final List<String> labels = <String>["NAME", "PLACE", "VALUE", "CODE"];
    for (final String label in labels) {
      expect(find.text(label), findsOneWidget);
    }
    final List<double> lefts = labels.map((String label) => tester.getTopLeft(_slotOf(label)).dx).toList();
    expect(lefts, orderedEquals(<double>[...lefts]..sort()));
    expect(tester.getTopLeft(find.text("NAME")).dy, lessThan(tester.getTopLeft(find.text("Alpha")).dy));
  });

  testWidgets("exposes each label as a semantic header", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpApp(tester, _table());

    expect(tester.getSemantics(find.text("NAME")), isSemantics(label: "Name", isHeader: true));
    expect(tester.getSemantics(find.text("VALUE")), isSemantics(label: "Value", isHeader: true));
    handle.dispose();
  });

  testWidgets("an empty label leaves the header cell blank", (WidgetTester tester) async {
    final List<CardTableColumn<_Item>> columns = <CardTableColumn<_Item>>[
      CardTableColumn<_Item>.text(label: "Name", text: (_Item item) => item.name),
      CardTableColumn<_Item>.text(label: "", text: (_Item item) => item.place),
    ];
    await pumpApp(tester, _table(columns: columns));

    expect(find.text("NAME"), findsOneWidget);
    expect(find.byWidgetPredicate((Widget widget) => widget is Text && widget.data == ""), findsNothing);
    expect(find.text("Paris"), findsOneWidget);
  });

  testWidgets("uses the micro-label style on cs.surfaceContainerHigh", (WidgetTester tester) async {
    await pumpApp(tester, _table());
    final ColorScheme cs = _scheme(tester);

    final TextStyle? style = tester.widget<Text>(find.text("NAME")).style;
    expect(style?.fontSize, 9);
    expect(style?.fontWeight, FontWeight.w700);
    expect(style?.letterSpacing, 0.6);
    expect(style?.color, cs.onSurfaceVariant);
    expect(tester.widget<ColoredBox>(_inTable(find.byType(ColoredBox)).first).color, cs.surfaceContainerHigh);
  });
}

void _bodyTests() {
  testWidgets("renders one row per item, in order", (WidgetTester tester) async {
    await pumpApp(tester, _table());

    for (final _Item item in _items) {
      expect(find.text(item.name), findsOneWidget);
      expect(find.text(item.place), findsOneWidget);
      expect(find.text("${item.value} %"), findsOneWidget);
    }
    final double alpha = tester.getTopLeft(find.text("Alpha")).dy;
    final double beta = tester.getTopLeft(find.text("Beta")).dy;
    final double gamma = tester.getTopLeft(find.text("Gamma")).dy;
    expect(alpha, lessThan(beta));
    expect(beta, lessThan(gamma));
  });

  testWidgets("text cells are one line with an ellipsis and never overflow", (WidgetTester tester) async {
    const _Item long = _Item("A very long item name that cannot fit in a narrow column", "Somewhere far", 5);
    await pumpApp(tester, _table(rows: const <_Item>[long]), surfaceSize: const Size(320, 400));

    final Text cell = tester.widget<Text>(find.text(long.name));
    expect(cell.maxLines, 1);
    expect(cell.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets("emphasis styles the built-in text cells", (WidgetTester tester) async {
    await pumpApp(tester, _table());
    final ColorScheme cs = _scheme(tester);

    final TextStyle? strong = tester.widget<Text>(find.text("Alpha")).style;
    expect(strong?.color, cs.onSurface);
    expect(strong?.fontWeight, FontWeight.w700);
    expect(strong?.fontSize, 12.5);

    final TextStyle? muted = tester.widget<Text>(find.text("Paris")).style;
    expect(muted?.color, cs.onSurfaceVariant);
    expect(muted?.fontWeight, FontWeight.w400);
    expect(muted?.fontSize, 11.5);
  });

  testWidgets("rows are separated by cs.outlineVariant top borders", (WidgetTester tester) async {
    await pumpApp(tester, _table());

    expect(_rowBoxes(tester), findsNWidgets(_items.length));
  });

  testWidgets("clips the content inside the border, not over it", (WidgetTester tester) async {
    await pumpApp(tester, _table(onRowTap: (_Item _) {}));

    // Outer radius 12 minus the 1 dp border: the header fill and the row ink
    // stop at the border's inner edge instead of covering its corner arcs.
    expect(tester.widget<Container>(_inTable(find.byType(Container)).first).clipBehavior, Clip.none);
    final Finder clip = _inTable(find.byType(ClipRRect));
    expect(clip, findsOneWidget);
    expect(tester.widget<ClipRRect>(clip).borderRadius, BorderRadius.circular(11));
    expect(find.descendant(of: clip, matching: find.text("NAME")), findsOneWidget);
    expect(find.descendant(of: clip, matching: find.byType(InkWell)), findsNWidgets(_items.length));
  });
}

void _sizingTests() {
  testWidgets("flex columns share the width proportionally", (WidgetTester tester) async {
    await pumpApp(tester, _table(), surfaceSize: const Size(560, 400));

    // 560 - 2 (border) - 32 (padding) - 3 × 8 (gaps) = 502 for 15 flex.
    const double perFlex = 502 / 15;
    expect(tester.getSize(_slotOf("Alpha")).width, closeTo(4 * perFlex, 1));
    expect(tester.getSize(_slotOf("Paris")).width, closeTo(4 * perFlex, 1));
    expect(tester.getSize(_slotOf("74 %")).width, closeTo(3 * perFlex, 1));
    expect(tester.getSize(_slotOf("AL")).width, closeTo(4 * perFlex, 1));
    expect(tester.getSize(_slotOf("NAME")).width, tester.getSize(_slotOf("Alpha")).width);
  });

  testWidgets("a fixed width overrides flex", (WidgetTester tester) async {
    final List<CardTableColumn<_Item>> columns = <CardTableColumn<_Item>>[
      CardTableColumn<_Item>.text(label: "Name", text: (_Item item) => item.name, flex: 3),
      CardTableColumn<_Item>.text(label: "Num", text: (_Item item) => "${item.value}", width: 48),
    ];
    await pumpApp(tester, _table(columns: columns), surfaceSize: const Size(560, 400));

    expect(tester.getSize(_slotOf("74")).width, 48);
    expect(tester.getSize(_slotOf("NUM")).width, 48);
    // 560 - 2 - 32 - 8 (gap) - 48 = 470 for the flex column.
    expect(tester.getSize(_slotOf("Alpha")).width, closeTo(470, 0.5));
  });

  testWidgets("align end and center place the header and the cell", (WidgetTester tester) async {
    await pumpApp(tester, _table(), surfaceSize: const Size(560, 400));

    for (final String text in <String>["VALUE", "74 %"]) {
      expect(tester.getTopRight(find.text(text)).dx, closeTo(tester.getTopRight(_slotOf(text)).dx, 0.5));
    }
    for (final String text in <String>["CODE", "AL"]) {
      expect(tester.getCenter(find.text(text)).dx, closeTo(tester.getCenter(_slotOf(text)).dx, 0.5));
    }
    expect(tester.getTopLeft(find.text("Alpha")).dx, closeTo(tester.getTopLeft(_slotOf("Alpha")).dx, 0.5));
  });
}

void _interactionTests() {
  testWidgets("tapping a row calls onRowTap once with its item", (WidgetTester tester) async {
    final List<_Item> tapped = <_Item>[];
    await pumpApp(tester, _table(onRowTap: tapped.add));

    await tester.tap(find.text("Lyon"));
    await tester.pump();

    expect(tapped, <_Item>[_items[1]]);
  });

  testWidgets("tappable rows are at least kMinTapTarget tall buttons", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpApp(tester, _table(onRowTap: (_Item _) {}));

    final Finder inkWells = _inTable(find.byType(InkWell));
    expect(inkWells, findsNWidgets(_items.length));
    for (final Element element in inkWells.evaluate()) {
      expect(element.size!.height, greaterThanOrEqualTo(kMinTapTarget));
    }
    expect(tester.getSemantics(find.text("Alpha")), isSemantics(isButton: true, hasTapAction: true));
    handle.dispose();
  });

  testWidgets("without onRowTap rows have no ink and no button semantics", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpApp(tester, _table());

    expect(_inTable(find.byType(InkWell)), findsNothing);
    expect(tester.getSemantics(find.text("Alpha")), isSemantics(isButton: false, hasTapAction: false));
    for (final Element element in _rowBoxes(tester).evaluate()) {
      expect(element.size!.height, lessThan(kMinTapTarget));
    }
    handle.dispose();
  });

  testWidgets("an interactive cell wins its tap over onRowTap", (WidgetTester tester) async {
    final List<_Item> tapped = <_Item>[];
    final List<_Item> pressed = <_Item>[];
    final List<CardTableColumn<_Item>> columns = <CardTableColumn<_Item>>[
      CardTableColumn<_Item>.text(label: "Name", text: (_Item item) => item.name),
      CardTableColumn<_Item>(
        label: "",
        width: kMinTapTarget,
        align: TextAlign.end,
        cellBuilder: (BuildContext context, _Item item) => IconButton(
          key: ValueKey<String>("edit-${item.name}"),
          onPressed: () => pressed.add(item),
          icon: const Icon(Icons.edit_outlined),
        ),
      ),
    ];
    await pumpApp(tester, _table(columns: columns, onRowTap: tapped.add));

    await tester.tap(find.byKey(const ValueKey<String>("edit-Gamma")));
    await tester.pump();

    expect(pressed, <_Item>[_items[2]]);
    expect(tapped, isEmpty);
  });
}

void _semanticsAndDetailTests() {
  testWidgets("rowSemanticLabel is read first on the row node", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      _table(rowSemanticLabel: (_Item item) => "Row ${_items.indexOf(item) + 1} of ${_items.length}."),
    );

    expect(find.bySemanticsLabel(RegExp(r"^Row 1 of 3\.\nAlpha\nParis")), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r"^Row 2 of 3\.\nBeta\nLyon")), findsOneWidget);
    handle.dispose();
  });

  testWidgets("rowDetailBuilder renders under its own row only", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final List<_Item> tapped = <_Item>[];
    await pumpApp(
      tester,
      _table(
        onRowTap: tapped.add,
        rowDetailBuilder: (BuildContext context, _Item item) =>
            item.name == "Beta" ? const Text("Detail of the second row") : null,
      ),
    );

    expect(find.text("Detail of the second row"), findsOneWidget);
    final double detailTop = tester.getTopLeft(find.text("Detail of the second row")).dy;
    expect(detailTop, greaterThan(tester.getBottomLeft(find.text("Beta")).dy));
    expect(detailTop, lessThan(tester.getTopLeft(find.text("Gamma")).dy));

    // The detail is outside the row's semantics node and tap target.
    expect(
      tester.getSemantics(find.text("Detail of the second row")).id,
      isNot(tester.getSemantics(find.text("Beta")).id),
    );
    await tester.tap(find.text("Detail of the second row"));
    await tester.pump();
    expect(tapped, isEmpty);
    handle.dispose();
  });

  testWidgets("a null detail adds nothing", (WidgetTester tester) async {
    await pumpApp(tester, _table());
    final double plain = tester.getSize(find.byType(CardTable<_Item>)).height;

    await pumpApp(tester, _table(rowDetailBuilder: (BuildContext context, _Item item) => null));

    expect(tester.getSize(find.byType(CardTable<_Item>)).height, plain);
  });
}

void _assertTests() {
  test("columns must not be empty", () {
    expect(() => CardTable<_Item>(rows: _items, columns: <CardTableColumn<_Item>>[]), throwsAssertionError);
  });

  test("flex and width must be positive", () {
    Widget cell(BuildContext context, _Item item) => const SizedBox.shrink();
    expect(() => CardTableColumn<_Item>(label: "A", cellBuilder: cell, flex: 0), throwsAssertionError);
    expect(() => CardTableColumn<_Item>(label: "A", cellBuilder: cell, width: 0), throwsAssertionError);
  });
}

void _themeTests() {
  testWidgets("light card uses the ColorScheme tokens", (WidgetTester tester) async {
    await pumpApp(tester, _table());
    final ColorScheme cs = _scheme(tester);

    final BoxDecoration? decoration = _cardDecoration(tester);
    expect(decoration?.color, cs.surfaceContainerLowest);
    expect(decoration?.border, Border.all(color: cs.outlineVariant));
    expect(tester.takeException(), isNull);
  });

  testWidgets("dark theme smoke test", (WidgetTester tester) async {
    final ThemeData dark = AppTheme.dark();
    await pumpApp(tester, _table(onRowTap: (_Item _) {}), theme: dark);

    expect(tester.takeException(), isNull);
    expect(_cardDecoration(tester)?.color, dark.colorScheme.surfaceContainerLowest);
    expect(tester.widget<Text>(find.text("Alpha")).style?.color, dark.colorScheme.onSurface);
    expect(tester.widget<Text>(find.text("Paris")).style?.color, dark.colorScheme.onSurfaceVariant);
  });
}

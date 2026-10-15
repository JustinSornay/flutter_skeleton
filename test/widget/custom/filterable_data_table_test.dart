// filterable_data_table_test.dart
//
// Widget tests for FilterableDataTable: the header (title, count, header
// semantics), the columns and cells, the filter chips ("all" first, toggle
// off, label override, hidden when empty), controlled sorting, the empty
// state, row taps without a checkbox column, the built-in delta column
// (tones, glyphs, spoken labels, custom format, threshold, zero, French
// locale), the const constructor and its build-time asserts, the rendered
// row heights, the 48 × 48 dp targets and accessibility guidelines, the
// header tooltip, the reduced-motion card, and the ColorScheme / StatusTones
// tokens under the light and dark themes.

import "package:easy_localization/easy_localization.dart";
// ignore: implementation_imports
import "package:easy_localization/src/localization.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/ChoiceChipRow/index.dart";
import "package:flutter_skeleton/widgets/custom/FilterableDataTable/index.dart";
import "package:flutter_skeleton/widgets/custom/_base/choice_option.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _allKey = "custom.filterable_data_table.all";
const String _emptyKey = "custom.filterable_data_table.empty";
const String _upKey = "custom.filterable_data_table.delta_up";
const String _downKey = "custom.filterable_data_table.delta_down";
const String _noneKey = "custom.filterable_data_table.delta_none";

enum _Group { first, second }

@immutable
final class _Item {
  final String name;
  final int value;
  final double change;
  final _Group group;

  const _Item(this.name, this.value, this.change, this.group);
}

const List<_Item> _items = <_Item>[
  _Item("Alpha", 74, 0.05, _Group.first),
  _Item("Beta", 61, -0.10, _Group.second),
  _Item("Gamma", 48, 0.01, _Group.first),
];

const List<ChoiceOption<_Group>> _filters = <ChoiceOption<_Group>>[
  ChoiceOption<_Group>(value: _Group.first, label: "First"),
  ChoiceOption<_Group>(value: _Group.second, label: "Second"),
];

/// Name (sortable), Value (numeric, sortable), Δ (delta, sortable) and Group
/// (not sortable).
List<DataTableColumnSpec<_Item>> _columns({String? deltaTooltip}) {
  return <DataTableColumnSpec<_Item>>[
    DataTableColumnSpec<_Item>(
      label: "Name",
      sortable: true,
      cellBuilder: (BuildContext context, _Item item) => Text(item.name),
    ),
    DataTableColumnSpec<_Item>(
      label: "Value",
      numeric: true,
      sortable: true,
      cellBuilder: (BuildContext context, _Item item) => Text("${item.value} %"),
    ),
    DataTableColumnSpec<_Item>.delta(
      label: "Δ",
      value: (_Item item) => item.change,
      tooltip: deltaTooltip,
    ),
    DataTableColumnSpec<_Item>(
      label: "Group",
      cellBuilder: (BuildContext context, _Item item) => Text("g-${item.group.name}"),
    ),
  ];
}

FilterableDataTable<_Item, _Group> _table({
  List<_Item> rows = _items,
  List<DataTableColumnSpec<_Item>>? columns,
  void Function(int columnIndex, bool ascending)? onSort,
  List<ChoiceOption<_Group>> filters = const <ChoiceOption<_Group>>[],
  _Group? selectedFilter,
  ValueChanged<_Group?>? onFilterChanged,
  ValueChanged<_Item>? onRowTap,
}) {
  return FilterableDataTable<_Item, _Group>(
    title: "TITLE",
    rows: rows,
    columns: columns ?? _columns(),
    sortColumnIndex: 1,
    sortAscending: false,
    onSort: onSort,
    filters: filters,
    selectedFilter: selectedFilter,
    onFilterChanged: onFilterChanged ?? (filters.isEmpty ? null : (_Group? _) {}),
    onRowTap: onRowTap,
  );
}

/// Pumps [table] scrollable, in a 800 × 900 surface.
Future<void> _pump(WidgetTester tester, Widget table, {ThemeData? theme}) {
  return pumpApp(
    tester,
    SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(kDefaultPadding * 2), child: table)),
    surfaceSize: const Size(800, 900),
    theme: theme,
  );
}

Color? _textColor(WidgetTester tester, String text) {
  final Finder paragraph = find.descendant(of: find.text(text), matching: find.byType(RichText));
  return tester.renderObject<RenderParagraph>(paragraph).text.style?.color;
}

ToneColors _tone(WidgetTester tester, StatusTone tone) {
  return StatusTones.colorsOf(tester.element(find.byType(DataTable)), tone);
}

/// Fill of the PillBadge container holding [text].
Color? _pillFill(WidgetTester tester, String text) {
  final Container pill = tester.widget<Container>(
    find.ancestor(of: find.text(text), matching: find.byType(Container)).first,
  );
  return (pill.decoration as BoxDecoration?)?.color;
}

/// Vertical distance between the centres of two texts in consecutive rows
/// (cells are vertically centred, so this is the row height when both rows
/// have the same height).
double _rowPitch(WidgetTester tester, String first, String second) {
  return tester.getCenter(find.text(second)).dy - tester.getCenter(find.text(first)).dy;
}

/// Top-level cell builder, so a column spec can be const.
Widget _intCell(BuildContext context, int row) => Text("$row");

/// In-memory translations matching the widget's i18n fragment, so the real
/// strings can be checked before the fragment is merged into assets.
final class _MemoryLoader extends AssetLoader {
  const _MemoryLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final bool fr = locale.languageCode == "fr";
    return <String, dynamic>{
      "custom": <String, dynamic>{
        "filterable_data_table": <String, dynamic>{
          "all": fr ? "Tous" : "All",
          "empty": fr ? "Aucune donnée disponible." : "No data available.",
          "delta_up": fr ? "Hausse de {value}" : "Up {value}",
          "delta_down": fr ? "Baisse de {value}" : "Down {value}",
          "delta_none": fr ? "Pas de variation" : "No change",
        },
      },
    };
  }
}

/// Pumps [child] under EasyLocalization (in-memory translations) and a
/// MaterialApp localised to [locale]. The tear-down empties the translation
/// singleton so every later `.tr()` returns the raw key again.
Future<void> _pumpLocalized(WidgetTester tester, Locale locale, Widget child) async {
  addTearDown(() => Localization.load(const Locale("fr")));
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const <Locale>[Locale("fr"), Locale("en")],
      path: "memory",
      fallbackLocale: const Locale("fr"),
      startLocale: locale,
      saveLocale: false,
      assetLoader: const _MemoryLoader(),
      child: Builder(
        builder: (BuildContext context) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.light(),
          home: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  _structureTests();
  _filterTests();
  _sortTests();
  _emptyAndRowTests();
  _deltaTests();
  _accessibilityTests();
  _themeTests();
}

void _structureTests() {
  group("structure", () {
    testWidgets("renders the title, the row count, the column labels and the cells", (WidgetTester tester) async {
      await _pump(tester, _table());

      expect(find.text("TITLE"), findsOneWidget);
      expect(find.text("3"), findsOneWidget);
      for (final String label in <String>["Name", "Value", "Δ", "Group"]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(tester.widget<DataTable>(find.byType(DataTable)).rows, hasLength(3));
      for (final String cell in <String>["Alpha", "Beta", "Gamma", "74 %", "61 %", "48 %", "g-first", "g-second"]) {
        expect(find.text(cell), findsWidgets);
      }
    });

    testWidgets("the header strip is one semantics header with the title and the count", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _table());

      expect(tester.getSemantics(find.text("TITLE")), isSemantics(label: "TITLE\n3", isHeader: true));
      handle.dispose();
    });

    testWidgets("columns map to DataColumns (numeric, sortable only with onSort)", (WidgetTester tester) async {
      await _pump(tester, _table(onSort: (int _, bool _) {}));

      final List<DataColumn> columns = tester.widget<DataTable>(find.byType(DataTable)).columns;
      expect(columns.map((DataColumn column) => column.numeric), <bool>[false, true, true, false]);
      expect(columns.map((DataColumn column) => column.onSort != null), <bool>[true, true, true, false]);
      expect(tester.widget<DataTable>(find.byType(DataTable)).showCheckboxColumn, isFalse);
    });

    testWidgets("the constructor is usable in a const expression", (WidgetTester tester) async {
      await _pump(
        tester,
        const FilterableDataTable<int, String>(
          title: "TITLE",
          rows: <int>[7],
          columns: <DataTableColumnSpec<int>>[DataTableColumnSpec<int>(label: "N", cellBuilder: _intCell)],
        ),
      );

      expect(find.text("7"), findsOneWidget);
      expect(find.text("1"), findsOneWidget);
    });

    testWidgets("asserts on empty columns and on filters without onFilterChanged", (WidgetTester tester) async {
      await _pump(
        tester,
        const FilterableDataTable<int, String>(title: "TITLE", rows: <int>[], columns: <DataTableColumnSpec<int>>[]),
      );
      expect(tester.takeException(), isA<AssertionError>());

      await _pump(
        tester,
        const FilterableDataTable<int, String>(
          title: "TITLE",
          rows: <int>[],
          columns: <DataTableColumnSpec<int>>[DataTableColumnSpec<int>(label: "N", cellBuilder: _intCell)],
          filters: <ChoiceOption<String>>[ChoiceOption<String>(value: "a", label: "A")],
        ),
      );
      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets("a column tooltip wraps its header in a Tooltip", (WidgetTester tester) async {
      await _pump(tester, _table(columns: _columns(deltaTooltip: "Change since last period")));

      expect(find.byType(Tooltip), findsOneWidget);
      expect(tester.widget<Tooltip>(find.byType(Tooltip)).message, "Change since last period");
    });
  });
}

void _filterTests() {
  group("filters", () {
    testWidgets("no filters hides the chip row", (WidgetTester tester) async {
      await _pump(tester, _table());

      expect(find.byType(ChoiceChipRow<_Group?>), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
    });

    testWidgets("shows the all chip first, then the options in order", (WidgetTester tester) async {
      await _pump(tester, _table(filters: _filters));

      final ChoiceChipRow<_Group?> row = tester.widget<ChoiceChipRow<_Group?>>(find.byType(ChoiceChipRow<_Group?>));
      expect(row.options.map((ChoiceOption<_Group?> option) => option.label), <String>[_allKey, "First", "Second"]);
      expect(row.options.first.value, isNull);
      expect(tester.getTopLeft(find.text(_allKey)).dx, lessThan(tester.getTopLeft(find.text("First")).dx));
      expect(tester.getTopLeft(find.text("First")).dx, lessThan(tester.getTopLeft(find.text("Second")).dx));
    });

    testWidgets("allFilterLabel replaces the default all label", (WidgetTester tester) async {
      await _pump(
        tester,
        FilterableDataTable<_Item, _Group>(
          title: "TITLE",
          rows: _items,
          columns: _columns(),
          filters: _filters,
          onFilterChanged: (_Group? _) {},
          allFilterLabel: "Every",
        ),
      );

      expect(find.text("Every"), findsOneWidget);
      expect(find.text(_allKey), findsNothing);
    });

    testWidgets("the all chip is selected when selectedFilter is null", (WidgetTester tester) async {
      await _pump(tester, _table(filters: _filters));

      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, _allKey)).selected, isTrue);
      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, "First")).selected, isFalse);
    });

    testWidgets("tapping an option reports it, the selected one or all reports null", (WidgetTester tester) async {
      final List<_Group?> changes = <_Group?>[];
      await _pump(tester, _table(filters: _filters, selectedFilter: _Group.second, onFilterChanged: changes.add));

      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, "Second")).selected, isTrue);
      await tester.tap(find.text("First"));
      await tester.tap(find.text("Second"));
      await tester.tap(find.text(_allKey));
      await tester.pump();

      expect(changes, <_Group?>[_Group.first, null, null]);
    });
  });
}

void _sortTests() {
  group("sorting", () {
    testWidgets("tapping a sortable header reports its index and the toggled direction", (WidgetTester tester) async {
      final List<(int, bool)> sorts = <(int, bool)>[];
      await _pump(tester, _table(onSort: (int index, bool ascending) => sorts.add((index, ascending))));

      await tester.tap(find.text("Name"));
      await tester.tap(find.text("Value"));
      await tester.tap(find.text("Δ"));
      await tester.tap(find.text("Group"));
      await tester.pump();

      // Value is the sorted column (descending), so its tap flips to ascending.
      expect(sorts, <(int, bool)>[(0, true), (1, true), (2, true)]);
    });

    testWidgets("passes the sort column and direction to the DataTable", (WidgetTester tester) async {
      await _pump(
        tester,
        FilterableDataTable<_Item, _Group>(
          title: "TITLE",
          rows: _items,
          columns: _columns(),
          sortColumnIndex: 2,
          sortAscending: true,
          onSort: (int _, bool _) {},
        ),
      );

      final DataTable table = tester.widget<DataTable>(find.byType(DataTable));
      expect(table.sortColumnIndex, 2);
      expect(table.sortAscending, isTrue);
    });

    testWidgets("without onSort no header is interactive", (WidgetTester tester) async {
      await _pump(tester, _table());

      final List<DataColumn> columns = tester.widget<DataTable>(find.byType(DataTable)).columns;
      expect(columns.every((DataColumn column) => column.onSort == null), isTrue);
      await tester.tap(find.text("Name"));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}

void _emptyAndRowTests() {
  group("empty state", () {
    testWidgets("shows the default message, keeps the chips and builds no table", (WidgetTester tester) async {
      await _pump(tester, _table(rows: const <_Item>[], filters: _filters, selectedFilter: _Group.second));

      expect(find.text(_emptyKey), findsOneWidget);
      expect(find.text("0"), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(3));
      expect(find.byType(DataTable), findsNothing);
    });

    testWidgets("emptyMessage replaces the default message", (WidgetTester tester) async {
      await _pump(
        tester,
        FilterableDataTable<_Item, _Group>(
          title: "TITLE",
          rows: const <_Item>[],
          columns: _columns(),
          emptyMessage: "Nothing here",
        ),
      );

      expect(find.text("Nothing here"), findsOneWidget);
      expect(find.text(_emptyKey), findsNothing);
    });
  });

  group("row taps", () {
    testWidgets("onRowTap receives the tapped item and no checkbox is shown", (WidgetTester tester) async {
      final List<_Item> taps = <_Item>[];
      await _pump(tester, _table(onRowTap: taps.add));

      await tester.tap(find.text("Beta"));
      await tester.tap(find.text("48 %"));
      await tester.pump();

      expect(taps, <_Item>[_items[1], _items[2]]);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets("without onRowTap rows are not interactive", (WidgetTester tester) async {
      await _pump(tester, _table());

      final DataTable table = tester.widget<DataTable>(find.byType(DataTable));
      expect(table.rows.every((DataRow row) => row.onSelectChanged == null), isTrue);
      await tester.tap(find.text("Beta"));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}

/// One-row table whose only column is a delta column over the row value.
FilterableDataTable<double, Never> _deltaTable(
  double value, {
  String Function(double absValue)? format,
  double neutralThreshold = 0.02,
}) {
  return FilterableDataTable<double, Never>(
    title: "TITLE",
    rows: <double>[value],
    columns: <DataTableColumnSpec<double>>[
      DataTableColumnSpec<double>.delta(
        label: "Δ",
        value: (double row) => row,
        format: format,
        neutralThreshold: neutralThreshold,
      ),
    ],
  );
}

void _deltaTests() {
  group("delta column", () {
    testWidgets("below the threshold renders a muted dash read as no change", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _deltaTable(0.01));

      expect(find.text("—"), findsOneWidget);
      expect(find.bySemanticsLabel(_noneKey), findsOneWidget);
      final BuildContext context = tester.element(find.text("—"));
      expect(_textColor(tester, "—"), Theme.of(context).colorScheme.onSurfaceVariant);
      handle.dispose();
    });

    testWidgets("a positive change is an up pill in the success tone", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _deltaTable(0.05));

      expect(find.text("▲ 5.0%"), findsOneWidget);
      expect(find.bySemanticsLabel(_upKey), findsOneWidget);
      final ToneColors success = _tone(tester, StatusTone.success);
      expect(_textColor(tester, "▲ 5.0%"), success.onContainer);
      expect(_pillFill(tester, "▲ 5.0%"), success.container);
      handle.dispose();
    });

    testWidgets("a negative change is a down pill in the danger tone", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _deltaTable(-0.10));

      expect(find.text("▼ 10.0%"), findsOneWidget);
      expect(find.bySemanticsLabel(_downKey), findsOneWidget);
      final ToneColors danger = _tone(tester, StatusTone.danger);
      expect(_textColor(tester, "▼ 10.0%"), danger.onContainer);
      expect(_pillFill(tester, "▼ 10.0%"), danger.container);
      handle.dispose();
    });

    testWidgets("uses a custom format with the absolute value", (WidgetTester tester) async {
      await _pump(tester, _deltaTable(-0.25, format: (double absValue) => "${(absValue * 100).round()} pts"));

      expect(find.text("▼ 25 pts"), findsOneWidget);
    });

    testWidgets("respects neutralThreshold, and NaN is neutral", (WidgetTester tester) async {
      await _pump(tester, _deltaTable(0.05, neutralThreshold: 0.06));
      expect(find.text("—"), findsOneWidget);

      await _pump(tester, _deltaTable(0.06, neutralThreshold: 0.06));
      expect(find.text("▲ 6.0%"), findsOneWidget);

      await _pump(tester, _deltaTable(double.nan));
      expect(find.text("—"), findsOneWidget);
    });

    testWidgets("zero is neutral even with a zero threshold", (WidgetTester tester) async {
      await _pump(tester, _deltaTable(0, neutralThreshold: 0));
      expect(find.text("—"), findsOneWidget);
      expect(find.textContaining("▼"), findsNothing);

      await _pump(tester, _deltaTable(-0.0, neutralThreshold: 0));
      expect(find.text("—"), findsOneWidget);

      await _pump(tester, _deltaTable(0.001, neutralThreshold: 0));
      expect(find.text("▲ 0.1%"), findsOneWidget);
    });

    testWidgets("formats and speaks the change for the French locale", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(
        tester,
        const Locale("fr"),
        FilterableDataTable<double, Never>(
          title: "TITLE",
          rows: const <double>[0.05, -0.10, 0],
          columns: <DataTableColumnSpec<double>>[
            DataTableColumnSpec<double>.delta(label: "Δ", value: (double row) => row),
          ],
        ),
      );

      // intl's French percent pattern puts a no-break space before "%".
      expect(find.text("▲ 5,0\u00a0%"), findsOneWidget);
      expect(find.text("▼ 10,0\u00a0%"), findsOneWidget);
      expect(find.bySemanticsLabel("Hausse de 5,0\u00a0%"), findsOneWidget);
      expect(find.bySemanticsLabel("Baisse de 10,0\u00a0%"), findsOneWidget);
      expect(find.bySemanticsLabel("Pas de variation"), findsOneWidget);
      handle.dispose();
    });
  });
}

void _accessibilityTests() {
  group("accessibility", () {
    testWidgets("sortable headers and tappable rows are at least 48 dp tall", (WidgetTester tester) async {
      await _pump(tester, _table(onSort: (int _, bool _) {}, onRowTap: (_Item _) {}));

      final DataTable table = tester.widget<DataTable>(find.byType(DataTable));
      expect(table.headingRowHeight, kMinTapTarget);
      expect(table.dataRowMinHeight, kMinTapTarget);
      // Heading and first row are both centred: half of each separates them.
      expect(_rowPitch(tester, "Name", "Alpha"), greaterThanOrEqualTo(kMinTapTarget));
      expect(_rowPitch(tester, "Alpha", "Beta"), greaterThanOrEqualTo(kMinTapTarget));
    });

    testWidgets("inert rows render 40 dp tall, tappable rows 48 dp", (WidgetTester tester) async {
      await _pump(tester, _table());

      expect(_rowPitch(tester, "Alpha", "Beta"), kDefaultPadding * 5);
      expect(_rowPitch(tester, "Beta", "Gamma"), kDefaultPadding * 5);
      // 40 dp heading + 3 × 40 dp rows.
      expect(tester.getSize(find.byType(Table)).height, kDefaultPadding * 5 * 4);

      await _pump(tester, _table(onRowTap: (_Item _) {}));

      expect(_rowPitch(tester, "Alpha", "Beta"), kMinTapTarget);
      expect(_rowPitch(tester, "Beta", "Gamma"), kMinTapTarget);
    });

    testWidgets("a one-glyph sortable middle column is a 48 × 48 dp header", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(
        tester,
        FilterableDataTable<_Item, _Group>(
          title: "TITLE",
          rows: const <_Item>[_Item("Alpha", 1, 0, _Group.first), _Item("Beta", 2, 0.01, _Group.second)],
          columns: <DataTableColumnSpec<_Item>>[
            _columns()[0],
            DataTableColumnSpec<_Item>.delta(label: "Δ", value: (_Item item) => item.change),
            _columns()[3],
          ],
          onSort: (int _, bool _) {},
        ),
      );

      expect(find.text("—"), findsNWidgets(2));
      final Size header = tester.getSize(find.ancestor(of: find.text("Δ"), matching: find.byType(InkWell)).first);
      expect(header.width, greaterThanOrEqualTo(kMinTapTarget));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets("a narrow middle column of tappable rows has 48 × 48 dp cells", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(
        tester,
        FilterableDataTable<_Item, _Group>(
          title: "TITLE",
          rows: const <_Item>[_Item("Alpha", 1, 0, _Group.first), _Item("Beta", 2, 0, _Group.second)],
          columns: <DataTableColumnSpec<_Item>>[
            _columns()[0],
            DataTableColumnSpec<_Item>(
              label: "#",
              cellBuilder: (BuildContext context, _Item item) => Text("${item.value}"),
            ),
            _columns()[3],
          ],
          onRowTap: (_Item _) {},
        ),
      );

      final Size cell = tester.getSize(find.ancestor(of: find.text("1"), matching: find.byType(TableRowInkWell)));
      expect(cell.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(cell.height, greaterThanOrEqualTo(kMinTapTarget));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets("meets the tap-target and contrast guidelines", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(
        tester,
        _table(
          onSort: (int _, bool _) {},
          onRowTap: (_Item _) {},
          filters: _filters,
          selectedFilter: _Group.first,
        ),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}

void _themeTests() {
  group("theme", () {
    testWidgets("light: card border outlineVariant, header surfaceContainerLow, selected chip onPrimary", (
      WidgetTester tester,
    ) async {
      await _pump(tester, _table(filters: _filters));

      final ColorScheme cs = Theme.of(tester.element(find.byType(DataTable))).colorScheme;
      final Material card = tester.widget<Material>(
        find.descendant(of: find.byType(FilterableDataTable<_Item, _Group>), matching: find.byType(Material)).first,
      );
      expect(card.color, cs.surface);
      expect((card.shape as RoundedRectangleBorder?)?.side.color, cs.outlineVariant);
      final DecoratedBox header = tester.widget<DecoratedBox>(
        find.ancestor(of: find.text("TITLE"), matching: find.byType(DecoratedBox)).first,
      );
      expect((header.decoration as BoxDecoration).color, cs.surfaceContainerLow);
      expect(_textColor(tester, "TITLE"), cs.onSurfaceVariant);
      expect(_textColor(tester, _allKey), cs.onPrimary);
      expect(_textColor(tester, "First"), cs.onSurface);
    });

    testWidgets("the card's implicit theme tween honours reduced motion", (WidgetTester tester) async {
      Material card() => tester.widget<Material>(
        find.descendant(of: find.byType(FilterableDataTable<_Item, _Group>), matching: find.byType(Material)).first,
      );

      await _pump(tester, _table());
      expect(card().animationDuration, kThemeChangeDuration);

      await _pump(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: _table(),
          ),
        ),
      );
      expect(card().animationDuration, Duration.zero);
    });

    testWidgets("dark: renders without errors with dark tokens and tones", (WidgetTester tester) async {
      await _pump(tester, _table(filters: _filters, onSort: (int _, bool _) {}), theme: AppTheme.dark());

      expect(tester.takeException(), isNull);
      final ColorScheme cs = Theme.of(tester.element(find.byType(DataTable))).colorScheme;
      expect(cs.brightness, Brightness.dark);
      expect(_textColor(tester, "Alpha"), cs.onSurface);
      expect(_textColor(tester, "▲ 5.0%"), _tone(tester, StatusTone.success).onContainer);
      expect(_textColor(tester, "▼ 10.0%"), _tone(tester, StatusTone.danger).onContainer);
      expect(_textColor(tester, _allKey), cs.onPrimary);
    });
  });
}

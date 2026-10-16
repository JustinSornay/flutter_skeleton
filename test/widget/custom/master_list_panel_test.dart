// master_list_panel_test.dart
//
// Widget tests for MasterListPanel: loading skeleton (Idle / Loading, reduced
// motion, narrow panel), error state (retry, hidden retry), empty state
// (default and custom texts), rows (archived filtering, subtitle line, tag
// pills + "+N" pill, long tags, selection border / background / semantics,
// pill fill on the selected row, long trailing text, 48 dp rows), the create
// button, tabs
// (filtering, counts, onTabChanged, per-tab labels, controller resizing and
// index clamping, reduced motion), the archive drawer (snap cycle and
// heights, chevron, tap outside, archived rows, empty archive, title
// overrides, showArchived, reduced motion, semantics, reset when the list
// reloads, short panels), a dark theme smoke test, and namedArgs
// substitution checked with in-memory fr / en strings (EasyLocalization).

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/utils/load_state.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/core/decorators/SkeletonPulse/index.dart";
import "package:flutter_skeleton/widgets/custom/MasterListPanel/index.dart";
import "package:flutter_skeleton/widgets/custom/PillBadge/index.dart";
import "package:flutter_skeleton/widgets/custom/SkeletonBlock/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

/// Without EasyLocalization in the tree, `.tr()` returns the raw key.
const String _createKey = "custom.master_list_panel.create";
const String _tabKey = "custom.master_list_panel.tab_label";
const String _loadingKey = "custom.master_list_panel.loading";
const String _errorKey = "custom.master_list_panel.error_title";
const String _hintKey = "custom.master_list_panel.error_hint";
const String _retryKey = "custom.master_list_panel.retry";
const String _emptyKey = "custom.master_list_panel.empty_title";
const String _pillKey = "custom.master_list_panel.archived_pill";
const String _archivedTitleKey = "custom.master_list_panel.archived_title";
const String _archivedEmptyKey = "custom.master_list_panel.archived_empty";
const String _moreKey = "custom.master_list_panel.more_tags";

/// Height of the host box around the panel.
const double _panelHeight = 500;

/// Default panel width and the horizontal padding of a row (16 dp each side).
const double _panelWidth = 296;
const double _rowInset = 16;

/// A trailing text far wider than its 40 % share of line 1.
const String _longTrailing = "1 234 567 Einträge insgesamt archiviert worden";

const MasterListItem _alpha = MasterListItem(
  id: "a",
  title: "Alpha",
  trailing: "3 items",
  subtitle: "North · 12.4 km",
  subtitleIcon: Icons.place_outlined,
  tags: <String>["One", "Two", "Three", "Four", "Five"],
  tabId: "open",
);
const MasterListItem _beta = MasterListItem(id: "b", title: "Beta", trailing: "1 item", tabId: "open");
const MasterListItem _gamma = MasterListItem(id: "c", title: "Gamma", tabId: "done");
const MasterListItem _delta = MasterListItem(
  id: "d",
  title: "Delta",
  trailing: "2 items",
  archived: true,
  archivedCaption: "Archived Oct 2025",
  tabId: "open",
);
const MasterListItem _epsilon = MasterListItem(id: "e", title: "Epsilon", archived: true, tabId: "done");

const List<MasterListItem> _items = <MasterListItem>[_alpha, _beta, _gamma, _delta, _epsilon];

const List<MasterListTab> _twoTabs = <MasterListTab>[
  MasterListTab(id: "open", label: "Open", createLabel: "New open", archivedTitle: "Archived open"),
  MasterListTab(id: "done", label: "Done"),
];

/// Records every callback of the panel.
final class _Calls {
  final List<String> selected = <String>[];
  final List<String?> created = <String?>[];
  final List<String> tabs = <String>[];
  int retries = 0;
}

MasterListPanel _panel(
  _Calls calls, {
  LoadState<List<MasterListItem>> state = const Loaded<List<MasterListItem>>(_items),
  String? selectedId,
  List<MasterListTab> tabs = const <MasterListTab>[],
  bool showArchived = true,
}) {
  return MasterListPanel(
    state: state,
    selectedId: selectedId,
    onSelect: calls.selected.add,
    onRetry: () => calls.retries++,
    onCreate: calls.created.add,
    tabs: tabs,
    onTabChanged: calls.tabs.add,
    showArchived: showArchived,
  );
}

/// Gives the panel a bounded height, anchored top-left.
Widget _host(Widget panel) {
  return Align(alignment: Alignment.topLeft, child: SizedBox(height: _panelHeight, child: panel));
}

/// Wraps [child] in the ambient MediaQuery with reduced motion turned on.
Widget _reducedMotion(Widget child) {
  return Builder(
    builder: (BuildContext context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child,
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget panel, {ThemeData? theme}) async {
  await pumpApp(tester, _host(panel), theme: theme);
}

/// The archive drawer's animated box.
Finder _drawerBox() {
  return find.descendant(of: find.byType(TapRegion), matching: find.byType(AnimatedContainer));
}

double _drawerHeight(WidgetTester tester) => tester.getSize(_drawerBox()).height;

/// Taps the drawer handle (top 48 dp of the drawer) and lets it settle.
Future<void> _tapHandle(WidgetTester tester) async {
  final Rect box = tester.getRect(_drawerBox());
  await tester.tapAt(Offset(box.center.dx, box.top + kMinTapTarget / 2));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// The Material holding the row titled [title].
Material _rowMaterial(WidgetTester tester, String title) {
  return tester.widget<Material>(find.ancestor(of: find.text(title), matching: find.byType(Material)).first);
}

/// The left border of the row titled [title].
BorderSide _rowIndicator(WidgetTester tester, String title) {
  final DecoratedBox box = tester.widget<DecoratedBox>(
    find.ancestor(of: find.text(title), matching: find.byType(DecoratedBox)).first,
  );
  final BoxDecoration decoration = box.decoration as BoxDecoration;
  return (decoration.border! as Border).left;
}

/// The row (InkWell) titled [title].
Finder _row(String title) => find.ancestor(of: find.text(title), matching: find.byType(InkWell)).first;

Finder _pillBadge(String label) {
  return find.byWidgetPredicate((Widget w) => w is PillBadge && w.label == label);
}

void main() {
  group("loading", () {
    testWidgets("Loading renders 5 pulsing skeleton rows and no item rows", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _panel(_Calls(), state: const Loading<List<MasterListItem>>()));

      expect(find.byType(SkeletonPulse), findsNWidgets(5));
      expect(find.byType(SkeletonBlock), findsNWidgets(30));
      expect(find.text("Alpha"), findsNothing);
      expect(find.bySemanticsLabel(_loadingKey), findsOneWidget);
      handle.dispose();
    });

    testWidgets("Idle renders the same skeleton", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls(), state: const Idle<List<MasterListItem>>()));

      expect(find.byType(SkeletonPulse), findsNWidgets(5));
      expect(find.text("Alpha"), findsNothing);
    });

    testWidgets("the skeleton pulses, and stays static under reduced motion", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls(), state: const Loading<List<MasterListItem>>()));
      await tester.pump(const Duration(milliseconds: 750));
      expect(find.descendant(of: find.byType(SkeletonPulse), matching: find.byType(Opacity)), findsNWidgets(5));

      await pumpApp(tester, _reducedMotion(_host(_panel(_Calls(), state: const Loading<List<MasterListItem>>()))));
      expect(find.descendant(of: find.byType(SkeletonPulse), matching: find.byType(Opacity)), findsNothing);
    });

    testWidgets("the skeleton bars shrink in a narrow panel instead of overflowing", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls(), state: const Loading<List<MasterListItem>>()));
      expect(tester.getSize(find.byType(SkeletonBlock).first).width, 140);

      await _pump(
        tester,
        MasterListPanel(
          state: const Loading<List<MasterListItem>>(),
          selectedId: null,
          onSelect: (String _) {},
          onCreate: (String? _) {},
          width: 160,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(SkeletonBlock).first).width, lessThan(140));
      expect(tester.getRect(find.byType(SkeletonBlock).at(1)).right, lessThanOrEqualTo(160 - _rowInset));
    });

    testWidgets("no archive drawer while loading", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls(), state: const Loading<List<MasterListItem>>()));

      expect(find.text(_pillKey), findsNothing);
      expect(_drawerBox(), findsNothing);
    });
  });

  group("error", () {
    testWidgets("shows title + hint, retry calls onRetry once", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pump(tester, _panel(calls, state: const LoadError<List<MasterListItem>>("boom")));

      expect(find.text(_errorKey), findsOneWidget);
      expect(find.text(_hintKey), findsOneWidget);
      expect(find.text("boom"), findsNothing);
      expect(_drawerBox(), findsNothing);

      final Size size = tester.getSize(find.byType(OutlinedButton));
      expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTapTarget));

      await tester.tap(find.text(_retryKey));
      await tester.pump();
      expect(calls.retries, 1);
    });

    testWidgets("error title uses cs.error", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls(), state: const LoadError<List<MasterListItem>>()));
      final ColorScheme cs = Theme.of(tester.element(find.text(_errorKey))).colorScheme;

      expect(tester.widget<Text>(find.text(_errorKey)).style?.color, cs.error);
    });

    testWidgets("no retry button without onRetry", (WidgetTester tester) async {
      await _pump(
        tester,
        MasterListPanel(
          state: const LoadError<List<MasterListItem>>(),
          selectedId: null,
          onSelect: (String _) {},
        ),
      );

      expect(find.text(_errorKey), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });

  group("empty", () {
    testWidgets("Loaded([]) shows the default title only", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls(), state: const Loaded<List<MasterListItem>>(<MasterListItem>[])));

      expect(find.text(_emptyKey), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets("custom emptyTitle and emptyMessage replace the default", (WidgetTester tester) async {
      await _pump(
        tester,
        MasterListPanel(
          state: const Loaded<List<MasterListItem>>(<MasterListItem>[]),
          selectedId: null,
          onSelect: (String _) {},
          emptyTitle: "No entries",
          emptyMessage: "Add the first one",
        ),
      );

      expect(find.text(_emptyKey), findsNothing);
      expect(find.text("No entries"), findsOneWidget);
      expect(find.text("Add the first one"), findsOneWidget);
    });

    testWidgets("only archived items → empty main list, drawer still shown", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls(), state: const Loaded<List<MasterListItem>>(<MasterListItem>[_delta])));

      expect(find.text(_emptyKey), findsOneWidget);
      expect(find.text(_pillKey), findsOneWidget);
    });

    testWidgets("a short panel does not overflow in the empty state", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            height: 160,
            child: MasterListPanel(
              state: const LoadError<List<MasterListItem>>(),
              selectedId: null,
              onSelect: (String _) {},
              onRetry: () {},
              onCreate: (String? _) {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group("rows", () {
    testWidgets("only non-archived items are listed, with title and trailing", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls()));

      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("3 items"), findsOneWidget);
      expect(find.text("Beta"), findsOneWidget);
      expect(find.text("1 item"), findsOneWidget);
      expect(find.text("Gamma"), findsOneWidget);
      expect(find.text("Delta"), findsNothing);
      expect(find.text("Epsilon"), findsNothing);
    });

    testWidgets("subtitle line and icon only when a subtitle is given", (WidgetTester tester) async {
      const MasterListItem iconOnly = MasterListItem(id: "x", title: "Iota", subtitleIcon: Icons.star_outline);
      await _pump(
        tester,
        _panel(_Calls(), state: const Loaded<List<MasterListItem>>(<MasterListItem>[_alpha, _beta, iconOnly])),
      );

      expect(find.text("North · 12.4 km"), findsOneWidget);
      expect(find.byIcon(Icons.place_outlined), findsOneWidget);
      expect(find.byIcon(Icons.star_outline), findsNothing);
    });

    testWidgets("5 tags with maxVisibleTags 3 → 3 pills + a '+2' pill", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls()));

      expect(_pillBadge("One"), findsOneWidget);
      expect(_pillBadge("Two"), findsOneWidget);
      expect(_pillBadge("Three"), findsOneWidget);
      expect(_pillBadge("Four"), findsNothing);
      expect(_pillBadge("+2"), findsOneWidget);
      expect(tester.widget<PillBadge>(_pillBadge("+2")).semanticsLabel, _moreKey);
      expect(tester.widget<PillBadge>(_pillBadge("One")).dense, isTrue);
      expect(find.byType(PillBadge), findsNWidgets(4));
    });

    testWidgets("maxVisibleTags is honoured", (WidgetTester tester) async {
      await _pump(
        tester,
        MasterListPanel(
          state: const Loaded<List<MasterListItem>>(<MasterListItem>[_alpha]),
          selectedId: null,
          onSelect: (String _) {},
          maxVisibleTags: 1,
        ),
      );

      expect(_pillBadge("One"), findsOneWidget);
      expect(_pillBadge("+4"), findsOneWidget);
      expect(find.byType(PillBadge), findsNWidgets(2));
    });

    testWidgets("no tags → no pill line", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls(), state: const Loaded<List<MasterListItem>>(<MasterListItem>[_beta])));

      expect(find.byType(PillBadge), findsNothing);
    });

    testWidgets("a tag wider than the row is ellipsised without overflow", (WidgetTester tester) async {
      const MasterListItem wide = MasterListItem(id: "w", title: "Omega", tags: <String>[_longTrailing, "Two"]);
      await _pump(tester, _panel(_Calls(), state: const Loaded<List<MasterListItem>>(<MasterListItem>[wide])));

      expect(tester.takeException(), isNull);
      expect(tester.getRect(_pillBadge(_longTrailing)).right, lessThanOrEqualTo(_panelWidth - _rowInset));
      expect(_pillBadge("Two"), findsOneWidget);
    });

    testWidgets("the selected row has the primary border and selected background", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls(), selectedId: "a"));
      final ColorScheme cs = Theme.of(tester.element(find.text("Alpha"))).colorScheme;

      expect(_rowMaterial(tester, "Alpha").color, cs.secondaryContainer);
      expect(_rowIndicator(tester, "Alpha").color, cs.primary);
      expect(_rowIndicator(tester, "Alpha").width, 3);
      expect(_rowMaterial(tester, "Beta").color, Colors.transparent);
      expect(_rowIndicator(tester, "Beta").color, Colors.transparent);
    });

    testWidgets("pills of the selected row switch to cs.surface", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls()));
      final ColorScheme cs = Theme.of(tester.element(find.text("Alpha"))).colorScheme;
      expect(tester.widget<PillBadge>(_pillBadge("One")).backgroundColor, cs.secondaryContainer);
      expect(tester.widget<PillBadge>(_pillBadge("+2")).backgroundColor, cs.surfaceContainerHighest);

      await _pump(tester, _panel(_Calls(), selectedId: "a"));
      expect(_rowMaterial(tester, "Alpha").color, cs.secondaryContainer);
      expect(tester.widget<PillBadge>(_pillBadge("One")).backgroundColor, cs.surface);
      expect(tester.widget<PillBadge>(_pillBadge("+2")).backgroundColor, cs.surface);
    });

    testWidgets("a long trailing is capped and ellipsised; a short one stays right-aligned", (
      WidgetTester tester,
    ) async {
      const MasterListItem long = MasterListItem(id: "l", title: "Lambda", trailing: _longTrailing);
      await _pump(tester, _panel(_Calls(), state: const Loaded<List<MasterListItem>>(<MasterListItem>[_alpha, long])));

      expect(tester.takeException(), isNull);
      final Text trailing = tester.widget<Text>(find.text(_longTrailing));
      expect(trailing.maxLines, 1);
      expect(trailing.overflow, TextOverflow.ellipsis);
      const double line = _panelWidth - 2 * _rowInset;
      expect(tester.getSize(find.text(_longTrailing)).width, lessThanOrEqualTo(line * 0.4));
      expect(tester.getSize(find.text("Lambda")).width, greaterThan(0));
      expect(tester.getRect(find.text(_longTrailing)).right, lessThanOrEqualTo(_panelWidth - _rowInset));
      expect(tester.getRect(find.text("3 items")).right, moreOrLessEquals(_panelWidth - _rowInset));
    });

    testWidgets("rows are buttons; the selected one reports selected", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _panel(_Calls(), selectedId: "a"));

      expect(
        tester.getSemantics(find.text("Alpha")),
        isSemantics(isButton: true, hasSelectedState: true, isSelected: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.text("Beta")),
        isSemantics(isButton: true, hasSelectedState: true, isSelected: false, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets("tapping a row calls onSelect with its id", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pump(tester, _panel(calls, selectedId: "a"));

      await tester.tap(find.text("Beta"));
      await tester.pump();
      expect(calls.selected, <String>["b"]);
    });

    testWidgets("every row is at least 48 dp tall", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls()));

      expect(tester.getSize(_row("Gamma")).height, greaterThanOrEqualTo(kMinTapTarget));
      expect(tester.getSize(_row("Beta")).height, greaterThanOrEqualTo(kMinTapTarget));
    });
  });

  group("create button", () {
    testWidgets("absent without onCreate", (WidgetTester tester) async {
      await _pump(
        tester,
        MasterListPanel(
          state: const Loaded<List<MasterListItem>>(_items),
          selectedId: null,
          onSelect: (String _) {},
        ),
      );

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets("default label, 48 dp, tap calls onCreate(null)", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pump(tester, _panel(calls));

      expect(find.text(_createKey), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(tester.getSize(find.byType(FilledButton)).height, greaterThanOrEqualTo(kMinTapTarget));

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(calls.created, <String?>[null]);
    });

    testWidgets("createLabel overrides the default", (WidgetTester tester) async {
      await _pump(
        tester,
        MasterListPanel(
          state: const Loaded<List<MasterListItem>>(_items),
          selectedId: null,
          onSelect: (String _) {},
          onCreate: (String? _) {},
          createLabel: "Add entry",
        ),
      );

      expect(find.text("Add entry"), findsOneWidget);
      expect(find.text(_createKey), findsNothing);
    });

    testWidgets("a long label is ellipsised without overflow", (WidgetTester tester) async {
      await _pump(
        tester,
        MasterListPanel(
          state: const Loaded<List<MasterListItem>>(_items),
          selectedId: null,
          onSelect: (String _) {},
          onCreate: (String? _) {},
          createLabel: "A very long create label that cannot fit in the sidebar width at all",
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group("tabs", () {
    testWidgets("0 or 1 tab → no tab bar, no filtering", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls()));
      expect(find.byType(TabBar), findsNothing);

      await _pump(tester, _panel(_Calls(), tabs: const <MasterListTab>[MasterListTab(id: "open", label: "Open")]));
      expect(find.byType(TabBar), findsNothing);
      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("Gamma"), findsOneWidget);
    });

    testWidgets("2 tabs render a tab bar and filter the list by tabId", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls(), tabs: _twoTabs));

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(2));
      expect(find.text(_tabKey), findsNWidgets(2));
      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("Beta"), findsOneWidget);
      expect(find.text("Gamma"), findsNothing);
    });

    testWidgets("switching tab filters, notifies and changes the create label", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pump(tester, _panel(calls, tabs: _twoTabs));
      expect(find.text("New open"), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(calls.created, <String?>["open"]);

      await tester.tap(find.byType(Tab).at(1));
      await tester.pump(const Duration(milliseconds: 400));
      expect(calls.tabs, <String>["done"]);
      expect(find.text("Gamma"), findsOneWidget);
      expect(find.text("Alpha"), findsNothing);
      expect(find.text(_createKey), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(calls.created, <String?>["open", "done"]);

      await tester.tap(find.byType(Tab).at(1));
      await tester.pump(const Duration(milliseconds: 400));
      expect(calls.tabs, <String>["done"]);
    });

    testWidgets("items whose tabId matches no tab are hidden while tabs show", (WidgetTester tester) async {
      const MasterListItem loose = MasterListItem(id: "z", title: "Zeta");
      await _pump(
        tester,
        _panel(_Calls(), tabs: _twoTabs, state: const Loaded<List<MasterListItem>>(<MasterListItem>[_alpha, loose])),
      );

      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("Zeta"), findsNothing);
    });

    testWidgets("tab count changes resize the controller and clamp the index", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      const List<MasterListTab> threeTabs = <MasterListTab>[
        MasterListTab(id: "open", label: "Open"),
        MasterListTab(id: "done", label: "Done"),
        MasterListTab(id: "later", label: "Later"),
      ];
      const MasterListItem later = MasterListItem(id: "l", title: "Lambda", tabId: "later");
      const Loaded<List<MasterListItem>> state = Loaded<List<MasterListItem>>(<MasterListItem>[_alpha, _gamma, later]);

      await _pump(tester, _panel(calls, tabs: _twoTabs, state: state));
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller?.length, 2);

      await _pump(tester, _panel(calls, tabs: threeTabs, state: state));
      expect(tester.takeException(), isNull);
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller?.length, 3);

      await tester.tap(find.byType(Tab).at(2));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text("Lambda"), findsOneWidget);

      await _pump(tester, _panel(calls, tabs: _twoTabs, state: state));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(tester.widget<TabBar>(find.byType(TabBar)).controller?.index, 1);
      expect(find.text("Gamma"), findsOneWidget);
      expect(find.text("Lambda"), findsNothing);

      await _pump(tester, _panel(calls, state: state));
      expect(tester.takeException(), isNull);
      expect(find.byType(TabBar), findsNothing);
      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("Gamma"), findsOneWidget);
      expect(find.text("Lambda"), findsOneWidget);
      expect(calls.tabs, <String>["later"]);
    });

    testWidgets("the tab controller follows the reduced-motion setting", (WidgetTester tester) async {
      Widget tree({required bool reduce}) {
        return Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
            child: _host(_panel(_Calls(), tabs: _twoTabs)),
          ),
        );
      }

      TabController controller() => tester.widget<TabBar>(find.byType(TabBar)).controller!;

      await pumpApp(tester, tree(reduce: false));
      expect(controller().animationDuration, kTabScrollDuration);
      await tester.tap(find.byType(Tab).at(1));
      await tester.pump(const Duration(milliseconds: 400));
      final TabController animated = controller();

      await pumpApp(tester, tree(reduce: true));
      expect(controller().animationDuration, Duration.zero);
      expect(controller(), isNot(same(animated)));
      expect(controller().index, 1);
      expect(find.text("Gamma"), findsOneWidget);

      await pumpApp(tester, tree(reduce: false));
      expect(controller().animationDuration, kTabScrollDuration);
      expect(tester.takeException(), isNull);
    });

    testWidgets("tabs get at least 48 dp", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls(), tabs: _twoTabs));

      expect(tester.getSize(find.byType(TabBar)).height, greaterThanOrEqualTo(kMinTapTarget));
    });
  });

  group("archive drawer", () {
    testWidgets("closed: a 48 dp pill pinned to the panel bottom", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls()));

      expect(find.text(_pillKey), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
      expect(_drawerHeight(tester), kMinTapTarget);
      expect(tester.getRect(_drawerBox()).bottom, _panelHeight);
      expect(find.text("Delta"), findsNothing);
    });

    testWidgets("handle cycles closed → 42 % → 80 % → closed", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls()));

      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);

      await _tapHandle(tester);
      expect(_drawerHeight(tester), moreOrLessEquals(_panelHeight * 0.42));
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up), findsNothing);
      expect(find.text(_archivedTitleKey), findsOneWidget);
      expect(find.text("Delta"), findsOneWidget);
      expect(find.text("Archived Oct 2025"), findsOneWidget);
      expect(find.text("Epsilon"), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _tapHandle(tester);
      expect(_drawerHeight(tester), moreOrLessEquals(_panelHeight * 0.80));

      await _tapHandle(tester);
      expect(_drawerHeight(tester), kMinTapTarget);
      expect(find.text(_pillKey), findsOneWidget);
      expect(find.text("Delta"), findsNothing);
    });

    testWidgets("no overflow while the drawer animates", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls()));

      final Rect box = tester.getRect(_drawerBox());
      await tester.tapAt(Offset(box.center.dx, box.top + kMinTapTarget / 2));
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets("tapping outside the drawer closes it", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pump(tester, _panel(calls));
      await _tapHandle(tester);
      expect(_drawerHeight(tester), greaterThan(kMinTapTarget));

      await tester.tap(find.text("Alpha"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(_drawerHeight(tester), kMinTapTarget);
      expect(calls.selected, <String>["a"]);
    });

    testWidgets("tapping an archived row calls onSelect with its id", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pump(tester, _panel(calls));
      await _tapHandle(tester);

      await tester.tap(find.text("Delta"));
      await tester.pump();
      expect(calls.selected, <String>["d"]);
      expect(tester.getSize(_row("Epsilon")).height, greaterThanOrEqualTo(kMinTapTarget));
    });

    testWidgets("a long trailing does not overflow an archived row", (WidgetTester tester) async {
      const MasterListItem long = MasterListItem(id: "l", title: "Lambda", trailing: _longTrailing, archived: true);
      await _pump(tester, _panel(_Calls(), state: const Loaded<List<MasterListItem>>(<MasterListItem>[_alpha, long])));
      await _tapHandle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(_longTrailing), findsOneWidget);
      expect(tester.getRect(find.text(_longTrailing)).right, lessThanOrEqualTo(_panelWidth - _rowInset));
    });

    testWidgets("a short Loaded panel opens the drawer without overflow", (WidgetTester tester) async {
      const double height = 160;
      Future<void> pumpShort(List<MasterListItem> items) async {
        await pumpApp(
          tester,
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: height,
              child: MasterListPanel(
                state: Loaded<List<MasterListItem>>(items),
                selectedId: null,
                onSelect: (String _) {},
                onCreate: (String? _) {},
              ),
            ),
          ),
        );
      }

      await pumpShort(_items);
      final Rect box = tester.getRect(_drawerBox());
      await tester.tapAt(Offset(box.center.dx, box.top + kMinTapTarget / 2));
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        expect(tester.takeException(), isNull);
      }
      expect(_drawerHeight(tester), moreOrLessEquals(height * 0.42));

      await _tapHandle(tester);
      expect(tester.takeException(), isNull);
      expect(_drawerHeight(tester), moreOrLessEquals(height * 0.80));

      // Only the handle is fixed: the title scrolls away with the rows.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text(_archivedTitleKey), findsNothing);
      expect(find.text("Epsilon"), findsOneWidget);

      // Same State, still Loaded: the drawer stays at the full snap.
      await pumpShort(const <MasterListItem>[_alpha]);
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(_drawerHeight(tester), moreOrLessEquals(height * 0.80));
      expect(find.text(_archivedEmptyKey), findsOneWidget);

      await _tapHandle(tester);
      await _tapHandle(tester);
      expect(tester.takeException(), isNull);
      expect(_drawerHeight(tester), moreOrLessEquals(height * 0.42));
      // ~19 dp of content at this snap: the empty text is reached by scrolling.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text(_archivedEmptyKey), findsOneWidget);
    });

    testWidgets("an empty archive shows the empty text", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls(), state: const Loaded<List<MasterListItem>>(<MasterListItem>[_alpha])));
      await _tapHandle(tester);

      expect(find.text(_archivedEmptyKey), findsOneWidget);
    });

    testWidgets("archived rows follow the active tab, with the tab's title", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls(), tabs: _twoTabs));
      await _tapHandle(tester);
      expect(find.text("Archived open"), findsOneWidget);
      expect(find.text("Delta"), findsOneWidget);
      expect(find.text("Epsilon"), findsNothing);

      await tester.tap(find.byType(Tab).at(1));
      await tester.pump(const Duration(milliseconds: 400));
      await _tapHandle(tester);
      expect(find.text(_archivedTitleKey), findsOneWidget);
      expect(find.text("Delta"), findsNothing);
      expect(find.text("Epsilon"), findsOneWidget);
    });

    testWidgets("archivedTitle overrides the default title", (WidgetTester tester) async {
      await _pump(
        tester,
        MasterListPanel(
          state: const Loaded<List<MasterListItem>>(_items),
          selectedId: null,
          onSelect: (String _) {},
          archivedTitle: "Old entries",
        ),
      );
      await _tapHandle(tester);

      expect(find.text("Old entries"), findsOneWidget);
      expect(find.text(_archivedTitleKey), findsNothing);
    });

    testWidgets("showArchived false: no drawer, the list fills the panel", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls(), showArchived: false));

      expect(find.text(_pillKey), findsNothing);
      expect(_drawerBox(), findsNothing);
      expect(tester.getRect(find.byType(ListView)).bottom, _panelHeight);
    });

    testWidgets("with the drawer, the list stops 48 dp above the bottom", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls()));

      expect(tester.getRect(find.byType(ListView).first).bottom, _panelHeight - kMinTapTarget);
    });

    testWidgets("reduced motion: one pump reaches the target height", (WidgetTester tester) async {
      await pumpApp(tester, _reducedMotion(_host(_panel(_Calls()))));

      final Rect box = tester.getRect(_drawerBox());
      await tester.tapAt(Offset(box.center.dx, box.top + kMinTapTarget / 2));
      await tester.pump();
      expect(_drawerHeight(tester), moreOrLessEquals(_panelHeight * 0.42));
    });

    testWidgets("the handle is a button with an expanded state", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _panel(_Calls()));

      expect(
        tester.getSemantics(find.bySemanticsLabel(_pillKey)),
        isSemantics(label: _pillKey, isButton: true, hasExpandedState: true, isExpanded: false, hasTapAction: true),
      );

      await _tapHandle(tester);
      expect(
        tester.getSemantics(find.bySemanticsLabel(_pillKey)),
        isSemantics(label: _pillKey, isButton: true, hasExpandedState: true, isExpanded: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets("an open drawer closes when the list reloads", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pump(tester, _panel(calls));
      await _tapHandle(tester);
      expect(_drawerHeight(tester), greaterThan(kMinTapTarget));

      await _pump(tester, _panel(calls, state: const Loading<List<MasterListItem>>()));
      expect(_drawerBox(), findsNothing);

      await _pump(tester, _panel(calls));
      expect(_drawerHeight(tester), kMinTapTarget);
    });
  });

  group("theme", () {
    testWidgets("dark theme: renders with scheme tokens", (WidgetTester tester) async {
      await _pump(tester, _panel(_Calls(), selectedId: "a", tabs: _twoTabs), theme: AppTheme.dark());
      await _tapHandle(tester);
      final ColorScheme cs = Theme.of(tester.element(find.text("Alpha"))).colorScheme;

      expect(tester.takeException(), isNull);
      expect(cs.brightness, Brightness.dark);
      expect(_rowMaterial(tester, "Alpha").color, cs.secondaryContainer);
      expect(_rowIndicator(tester, "Alpha").color, cs.primary);
      expect(
        tester.widget<Material>(find.ancestor(of: find.byType(TabBar), matching: find.byType(Material)).first).color,
        cs.surfaceContainerLow,
      );
      expect(tester.widget<PillBadge>(_pillBadge("One")).backgroundColor, cs.surface);
    });
  });

  // Last: EasyLocalization keeps the loaded translations in a singleton, so
  // pumpApp tests that follow would read them instead of the raw keys.
  group("translations", () {
    testWidgets("fr: tab counts, archive pill, create and +N label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(tester, const Locale("fr"), _host(_panel(_Calls(), tabs: _twoTabs)));

      expect(find.text("Open (2)"), findsOneWidget);
      expect(find.text("Done (1)"), findsOneWidget);
      expect(find.text("Archivés (1)"), findsOneWidget);
      expect(find.text("New open"), findsOneWidget);
      expect(tester.widget<PillBadge>(_pillBadge("+2")).semanticsLabel, "2 de plus");
      handle.dispose();
    });

    testWidgets("en: default create label, archive pill and empty title", (WidgetTester tester) async {
      await _pumpLocalized(
        tester,
        const Locale("en"),
        _host(_panel(_Calls(), state: const Loaded<List<MasterListItem>>(<MasterListItem>[_delta]))),
      );

      expect(find.text("New"), findsOneWidget);
      expect(find.text("Archived (1)"), findsOneWidget);
      expect(find.text("Nothing here yet"), findsOneWidget);
    });
  });
}

/// In-memory strings for the keys whose namedArgs substitution is checked
/// (create, tab_label, empty_title, archived_pill, more_tags). They are a
/// hand-copied subset of the widget's i18n fragment, not the shipped assets:
/// once the fragment is merged into assets/translations, load the real JSON
/// (or use pumpLocalizedRouter) instead.
final class _MemoryLoader extends AssetLoader {
  const _MemoryLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final bool fr = locale.languageCode == "fr";
    return <String, dynamic>{
      "custom": <String, dynamic>{
        "master_list_panel": <String, dynamic>{
          "create": fr ? "Nouveau" : "New",
          "tab_label": "{label} ({count})",
          "empty_title": fr ? "Rien pour le moment" : "Nothing here yet",
          "archived_pill": fr ? "Archivés ({count})" : "Archived ({count})",
          "more_tags": fr ? "{count} de plus" : "{count} more",
        },
      },
    };
  }
}

Future<void> _pumpLocalized(WidgetTester tester, Locale locale, Widget child) async {
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

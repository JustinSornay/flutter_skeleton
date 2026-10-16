// category_browser_test.dart
//
// Widget tests for CategoryBrowser: one ExpandableGroupTile per group with
// the icon fallback and kDefaultPadding gaps, the single-open accordion and
// its onOpenChanged reports, typed entry selection, direct (non-expandable)
// groups, initialOpenKey, the reveal scroll (position, wait for the resize,
// collapse of an open group above, reduced motion, a newer toggle
// superseding a pending reveal, cancellation on unmount and on a user drag,
// fling or wheel scroll), group updates (removal, reorder), the external /
// owned ScrollController, 48 dp targets and the dark theme.

import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/CategoryBrowser/index.dart";
import "package:flutter_skeleton/widgets/custom/ExpandableGroupTile/index.dart";
import "package:flutter_skeleton/widgets/custom/_base/choice_option.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

/// Height of the bounded box used by the scroll tests.
const double _viewport = 300;

/// Records the browser callbacks.
final class _Calls {
  final List<int> selected = <int>[];
  final List<String?> opened = <String?>[];
}

List<ChoiceOption<int>> _entries(int group, int count) {
  return List<ChoiceOption<int>>.generate(
    count,
    (int i) => ChoiceOption<int>(
      value: group * 100 + i,
      label: "Item $group.$i",
      description: "Detail $group.$i",
      trailing: "${i + 1}",
    ),
  );
}

CategoryBrowserGroup<int> _group(int i, {int entries = 2, bool expandable = true, String? subtitle, IconData? icon}) {
  return CategoryBrowserGroup<int>(
    key: "g$i",
    title: "Group $i",
    subtitle: subtitle ?? "Summary $i",
    icon: icon,
    entries: _entries(i, entries),
    expandable: expandable,
  );
}

List<CategoryBrowserGroup<int>> _groups(int count) {
  return List<CategoryBrowserGroup<int>>.generate(count, _group);
}

CategoryBrowser<int> _browser(
  _Calls calls,
  List<CategoryBrowserGroup<int>> groups, {
  String? initialOpenKey,
  ScrollController? controller,
}) {
  return CategoryBrowser<int>(
    groups: groups,
    onEntrySelected: calls.selected.add,
    onOpenChanged: calls.opened.add,
    initialOpenKey: initialOpenKey,
    scrollController: controller,
  );
}

/// The browser in a box [_viewport] tall.
Widget _bounded(Widget browser) => SizedBox(height: _viewport, child: browser);

/// Wraps [child] in the ambient MediaQuery with reduced motion set to
/// [reduced]. The tree shape does not depend on [reduced], so switching it
/// keeps the browser's state.
Widget _motion(Widget child, {required bool reduced}) {
  return Builder(
    builder: (BuildContext context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
      child: child,
    ),
  );
}

/// The tile titled [title], including tiles built in the list's cache area.
Finder _tileOf(String title) => find.widgetWithText(ExpandableGroupTile<int>, title, skipOffstage: false);

/// The InkWell holding [text] (group header or entry row).
Finder _inkWellOf(String text) {
  return find.ancestor(of: find.text(text), matching: find.byType(InkWell)).first;
}

double _offset(WidgetTester tester) {
  return tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
}

/// Top of the tile titled [title], relative to the top of the browser.
double _topInBrowser(WidgetTester tester, String title) {
  return tester.getTopLeft(_tileOf(title)).dy - tester.getTopLeft(find.byType(CategoryBrowser<int>)).dy;
}

/// Pumps 16 ms frames for about a second, well past the reveal's resize
/// wait, settle frames and scroll, and returns the list offset after each
/// one. Short frames keep the tapped tile built while the list moves.
Future<List<double>> _pumpPastReveal(WidgetTester tester) async {
  final List<double> offsets = <double>[];
  for (int i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    offsets.add(_offset(tester));
  }
  return offsets;
}

/// Checks that the tile titled [title] sits where `ensureVisible` with
/// alignment 0.1 puts it: a tenth of the free viewport space below the top.
void _expectRevealed(WidgetTester tester, String title) {
  final double height = tester.getSize(_tileOf(title)).height;
  expect(_topInBrowser(tester, title), moreOrLessEquals((_viewport - height) * 0.1, epsilon: 0.01));
}

void main() {
  group("structure", () {
    testWidgets("one tile per group with title, subtitle and icon, kDefaultPadding apart", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      final List<CategoryBrowserGroup<int>> groups = <CategoryBrowserGroup<int>>[
        _group(0, icon: Icons.folder_outlined),
        _group(1),
        _group(2),
      ];
      await pumpApp(tester, _browser(calls, groups));

      expect(find.byType(ExpandableGroupTile<int>), findsNWidgets(3));
      for (int i = 0; i < 3; i++) {
        expect(find.text("Group $i"), findsOneWidget);
        expect(find.text("Summary $i"), findsOneWidget);
      }
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
      expect(find.byIcon(Icons.category), findsNWidgets(2), reason: "a group without an icon falls back to Icons.category");
      final double gap = tester.getTopLeft(_tileOf("Group 1")).dy - tester.getBottomLeft(_tileOf("Group 0")).dy;
      expect(gap, kDefaultPadding);
    });

    testWidgets("every group starts closed", (WidgetTester tester) async {
      await pumpApp(tester, _browser(_Calls(), _groups(3)));

      expect(find.textContaining("Item "), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsNWidgets(3));
    });

    testWidgets("an empty group list renders an empty list", (WidgetTester tester) async {
      await pumpApp(tester, _browser(_Calls(), <CategoryBrowserGroup<int>>[]));

      expect(find.byType(ExpandableGroupTile<int>), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets("duplicate group keys are asserted", (WidgetTester tester) async {
      await pumpApp(tester, _browser(_Calls(), <CategoryBrowserGroup<int>>[_group(0), _group(0)]));

      expect(tester.takeException(), isAssertionError);
    });
  });

  group("accordion", () {
    testWidgets("tapping a group shows its entries, tapping it again hides them", (WidgetTester tester) async {
      await pumpApp(tester, _browser(_Calls(), _groups(3)));

      await tester.tap(find.text("Group 1"));
      await tester.pumpAndSettle();
      expect(find.text("Item 1.0"), findsOneWidget);
      expect(find.text("Detail 1.0"), findsOneWidget);
      expect(find.text("Item 1.1"), findsOneWidget);
      expect(find.text("2"), findsOneWidget, reason: "trailing text of the second entry");

      await tester.tap(find.text("Group 1"));
      await tester.pumpAndSettle();
      expect(find.text("Item 1.0"), findsNothing);
    });

    testWidgets("only one group is open at a time", (WidgetTester tester) async {
      await pumpApp(tester, _browser(_Calls(), _groups(3)));

      await tester.tap(find.text("Group 0"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Group 2"));
      await tester.pumpAndSettle();

      expect(find.text("Item 0.0"), findsNothing);
      expect(find.text("Item 2.0"), findsOneWidget);
      expect(tester.widget<ExpandableGroupTile<int>>(_tileOf("Group 0")).isOpen, isFalse);
      expect(tester.widget<ExpandableGroupTile<int>>(_tileOf("Group 2")).isOpen, isTrue);
    });

    testWidgets("tapping an entry hands back its typed value", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _browser(calls, _groups(3)));

      await tester.tap(find.text("Group 2"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Item 2.1"));
      await tester.pumpAndSettle();

      expect(calls.selected, <int>[201]);
      expect(find.text("Item 2.1"), findsOneWidget, reason: "selecting an entry keeps the group open");
    });

    testWidgets("onOpenChanged reports the opened key, then null on close", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _browser(calls, _groups(3)));

      await tester.tap(find.text("Group 1"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Group 0"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Group 0"));
      await tester.pumpAndSettle();

      expect(calls.opened, <String?>["g1", "g0", null]);
      expect(calls.selected, isEmpty);
    });

    testWidgets("initialOpenKey opens that group on the first frame, without a report", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _browser(calls, _groups(3), initialOpenKey: "g2"));

      expect(find.text("Item 2.0"), findsOneWidget);
      expect(calls.opened, isEmpty);

      await tester.tap(find.text("Group 2"));
      await tester.pumpAndSettle();
      expect(calls.opened, <String?>[null]);
      expect(find.text("Item 2.0"), findsNothing);
    });

    testWidgets("an unknown or non-expandable initialOpenKey opens nothing", (WidgetTester tester) async {
      final List<CategoryBrowserGroup<int>> groups = <CategoryBrowserGroup<int>>[
        _group(0),
        _group(1, expandable: false),
      ];
      await pumpApp(tester, _browser(_Calls(), groups, initialOpenKey: "missing"));
      expect(find.textContaining("Detail "), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpApp(tester, _browser(_Calls(), groups, initialOpenKey: "g1"));
      expect(find.textContaining("Detail "), findsNothing);

      // The same group becomes expandable: the dropped key leaves it closed.
      await pumpApp(tester, _browser(_Calls(), <CategoryBrowserGroup<int>>[_group(0), _group(1)], initialOpenKey: "g1"));
      expect(find.text("Item 1.0"), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group("direct groups", () {
    testWidgets("tapping a non-expandable group selects its first entry without opening", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      final List<CategoryBrowserGroup<int>> groups = <CategoryBrowserGroup<int>>[
        _group(0),
        _group(1, expandable: false, entries: 3),
      ];
      await pumpApp(tester, _browser(calls, groups));

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      await tester.tap(find.text("Group 1"));
      await tester.pumpAndSettle();

      expect(calls.selected, <int>[100]);
      expect(calls.opened, isEmpty);
      expect(find.text("Item 1.1"), findsNothing);
      expect(_offset(tester), 0);
    });

    testWidgets("a non-expandable group without subtitle shows its first entry's label", (WidgetTester tester) async {
      final List<CategoryBrowserGroup<int>> groups = <CategoryBrowserGroup<int>>[
        CategoryBrowserGroup<int>(key: "solo", title: "Solo", entries: _entries(7, 1), expandable: false),
      ];
      await pumpApp(tester, _browser(_Calls(), groups));

      expect(find.text("Item 7.0"), findsOneWidget);
    });

    testWidgets("a non-expandable group without entries is inert", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      final List<CategoryBrowserGroup<int>> groups = <CategoryBrowserGroup<int>>[
        const CategoryBrowserGroup<int>(key: "empty", title: "Empty", entries: <ChoiceOption<int>>[], expandable: false),
      ];
      await pumpApp(tester, _browser(calls, groups));

      await tester.tap(find.text("Empty"), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(calls.selected, isEmpty);
      expect(calls.opened, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });

  group("reveal scroll", () {
    testWidgets("a group tapped near the bottom is scrolled to 10 % from the top", (WidgetTester tester) async {
      await pumpApp(tester, _bounded(_browser(_Calls(), _groups(10))));
      expect(_offset(tester), 0);
      expect(_topInBrowser(tester, "Group 3"), greaterThan(_viewport / 2));

      await tester.tap(find.text("Group 3"));
      await tester.pumpAndSettle();

      expect(_offset(tester), greaterThan(0));
      _expectRevealed(tester, "Group 3");
      expect(find.text("Item 3.1"), findsOneWidget);
    });

    testWidgets("waits for the tiles to resize before scrolling", (WidgetTester tester) async {
      await pumpApp(tester, _bounded(_browser(_Calls(), _groups(10))));

      await tester.tap(find.text("Group 3"));
      await tester.pump();
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 60));
        expect(_offset(tester), 0, reason: "no scroll while the body is still growing");
      }

      await tester.pumpAndSettle();
      expect(_offset(tester), greaterThan(0));
    });

    testWidgets("a group opened below a long open group lands inside the viewport", (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);
      final List<CategoryBrowserGroup<int>> groups = <CategoryBrowserGroup<int>>[
        _group(0, entries: 8),
        for (int i = 1; i < 10; i++) _group(i),
      ];
      await pumpApp(tester, _bounded(_browser(_Calls(), groups, initialOpenKey: "g0", controller: controller)));

      // Scroll so the header of group 1 sits near the bottom, group 0's
      // entries above it.
      final double headerHeight = tester.getSize(_tileOf("Group 1")).height;
      final double group1Top = _topInBrowser(tester, "Group 1");
      controller.jumpTo(group1Top - (_viewport - headerHeight - kDefaultPadding));
      await tester.pump();
      expect(_topInBrowser(tester, "Group 1"), greaterThan(_viewport / 2));

      await tester.tap(find.text("Group 1"));
      await tester.pumpAndSettle();

      expect(find.text("Item 0.0"), findsNothing);
      _expectRevealed(tester, "Group 1");
    });

    testWidgets("under reduced motion the list jumps on the next frame", (WidgetTester tester) async {
      await pumpApp(tester, _motion(_bounded(_browser(_Calls(), _groups(10))), reduced: true));

      await tester.tap(find.text("Group 3"));
      await tester.pump();

      expect(_offset(tester), greaterThan(0));
      await tester.pump();
      _expectRevealed(tester, "Group 3");
    });

    testWidgets("a newer toggle supersedes a reveal still waiting for the layout", (WidgetTester tester) async {
      Widget host({required bool reduced}) => _motion(_bounded(_browser(_Calls(), _groups(10))), reduced: reduced);
      await pumpApp(tester, host(reduced: false));

      await tester.tap(find.text("Group 3"));
      await tester.pump();
      await tester.pump(kMotionShort - const Duration(milliseconds: 1));
      // Reduced motion turns on, then group 3's reveal timer fires: its
      // reveal now compares frames, waiting for a stable layout.
      await pumpApp(tester, host(reduced: true));
      await tester.pump(const Duration(milliseconds: 1));
      // Group 1's reveal runs on the next frame; group 3's must not follow.
      await tester.tap(find.text("Group 1"));
      await tester.pumpAndSettle();

      expect(find.text("Item 3.0"), findsNothing);
      _expectRevealed(tester, "Group 1");
    });

    testWidgets("a pending reveal is dropped when the browser is removed", (WidgetTester tester) async {
      await pumpApp(tester, _bounded(_browser(_Calls(), _groups(10))));

      await tester.tap(find.text("Group 3"));
      await tester.pump();
      // The reveal timer is pending; removing the browser must cancel it,
      // otherwise the test harness reports a pending Timer.
      await tester.pumpWidget(const SizedBox.shrink());

      expect(tester.takeException(), isNull);
    });

    // The reveal first waits for the tiles' resize time, then compares
    // frames until the layout is stable: a drag in either stage drops it.
    for (final (String stage, Duration wait) in <(String, Duration)>[
      ("resize wait", const Duration(milliseconds: 50)),
      ("settle frames", kMotionShort),
    ]) {
      testWidgets("a drag during the reveal's $stage keeps the list under the finger", (WidgetTester tester) async {
        await pumpApp(tester, _bounded(_browser(_Calls(), _groups(20))));

        await tester.tap(find.text("Group 3"));
        await tester.pump();
        await tester.pump(wait);
        final TestGesture finger = await tester.startGesture(tester.getCenter(find.byType(CategoryBrowser<int>)));
        await finger.moveBy(const Offset(0, -40));
        await tester.pump();
        await finger.moveBy(const Offset(0, -200));
        await tester.pump();
        final double dragged = _offset(tester);
        expect(dragged, greaterThan(0));

        expect(
          await _pumpPastReveal(tester),
          everyElement(dragged),
          reason: "the pending reveal must not pull the list away from the finger",
        );

        await finger.up();
        await tester.pumpAndSettle();
        expect(_offset(tester), greaterThanOrEqualTo(dragged));
      });
    }

    testWidgets("a fling started while the reveal waits is not pulled back", (WidgetTester tester) async {
      await pumpApp(tester, _bounded(_browser(_Calls(), _groups(30))));

      await tester.tap(find.text("Group 1"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.fling(find.byType(CategoryBrowser<int>), const Offset(0, -200), 2000);
      final double flung = _offset(tester);

      final List<double> offsets = await _pumpPastReveal(tester);
      expect(offsets.last, greaterThan(flung));
      for (int i = 1; i < offsets.length; i++) {
        expect(offsets[i], greaterThanOrEqualTo(offsets[i - 1]), reason: "the fling carries on; the reveal is dropped");
      }
    });

    testWidgets("a mouse wheel scroll while the reveal waits drops the reveal", (WidgetTester tester) async {
      await pumpApp(tester, _bounded(_browser(_Calls(), _groups(20))));

      await tester.tap(find.text("Group 3"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final TestPointer mouse = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(mouse.addPointer(location: tester.getCenter(find.byType(CategoryBrowser<int>))));
      await tester.sendEventToBinding(mouse.scroll(const Offset(0, 400)));
      await tester.pump();
      final double scrolled = _offset(tester);
      expect(scrolled, greaterThan(0));

      expect(await _pumpPastReveal(tester), everyElement(scrolled));
      await tester.sendEventToBinding(mouse.removePointer());
    });
  });

  group("updates", () {
    testWidgets("removing the open group closes it; re-adding keeps it closed", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _browser(calls, _groups(3), initialOpenKey: "g1"));
      expect(find.text("Item 1.0"), findsOneWidget);

      await pumpApp(tester, _browser(calls, <CategoryBrowserGroup<int>>[_group(0), _group(2)]));
      await tester.pumpAndSettle();
      expect(find.textContaining("Item "), findsNothing);

      await pumpApp(tester, _browser(calls, _groups(3)));
      await tester.pumpAndSettle();
      expect(find.text("Item 1.0"), findsNothing);
      expect(calls.opened, isEmpty, reason: "only user toggles are reported");
      expect(tester.takeException(), isNull);
    });

    testWidgets("rebuilding with equal groups keeps the open group", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _browser(calls, _groups(3)));
      await tester.tap(find.text("Group 2"));
      await tester.pumpAndSettle();

      await pumpApp(tester, _browser(calls, _groups(3)));
      await tester.pumpAndSettle();

      expect(find.text("Item 2.0"), findsOneWidget);
    });

    testWidgets("an open group that becomes non-expandable is closed", (WidgetTester tester) async {
      await pumpApp(tester, _browser(_Calls(), _groups(2), initialOpenKey: "g1"));

      await pumpApp(tester, _browser(_Calls(), <CategoryBrowserGroup<int>>[_group(0), _group(1, expandable: false)]));
      await tester.pumpAndSettle();
      await pumpApp(tester, _browser(_Calls(), _groups(2)));
      await tester.pumpAndSettle();

      expect(find.text("Item 1.0"), findsNothing);
    });

    testWidgets("reordered groups keep their open state and reveal target", (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);
      await pumpApp(tester, _bounded(_browser(_Calls(), _groups(10), controller: controller)));
      await tester.tap(find.text("Group 1"));
      await tester.pumpAndSettle();

      await pumpApp(tester, _bounded(_browser(_Calls(), _groups(10).reversed.toList(), controller: controller)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.widget<ExpandableGroupTile<int>>(_tileOf("Group 9")).isOpen, isFalse);

      // Group 1 now sits near the end of the list: it is still the open one.
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();
      expect(tester.widget<ExpandableGroupTile<int>>(_tileOf("Group 1")).isOpen, isTrue);
      expect(find.text("Item 1.0", skipOffstage: false), findsOneWidget);

      controller.jumpTo(0);
      await tester.pump();
      await tester.tap(find.text("Group 7"));
      await tester.pumpAndSettle();
      _expectRevealed(tester, "Group 7");
    });
  });

  group("scroll controller", () {
    testWidgets("an external controller drives the list and outlives the browser", (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      await pumpApp(tester, _bounded(_browser(_Calls(), _groups(10), controller: controller)));

      expect(controller.hasClients, isTrue);
      final double before = _topInBrowser(tester, "Group 1");
      controller.jumpTo(40);
      await tester.pump();
      expect(_topInBrowser(tester, "Group 1"), before - 40);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(controller.hasClients, isFalse);
      // A disposed controller would throw here.
      void listener() {}
      controller.addListener(listener);
      controller.removeListener(listener);
      controller.dispose();
    });

    testWidgets("switching from the owned controller to an external one", (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);
      await pumpApp(tester, _bounded(_browser(_Calls(), _groups(10))));

      await pumpApp(tester, _bounded(_browser(_Calls(), _groups(10), controller: controller)));
      expect(controller.hasClients, isTrue);

      await pumpApp(tester, _bounded(_browser(_Calls(), _groups(10))));
      expect(controller.hasClients, isFalse);
      expect(tester.takeException(), isNull);
    });
  });

  group("accessibility and themes", () {
    testWidgets("group headers and entry rows are at least 48 dp tall", (WidgetTester tester) async {
      await pumpApp(tester, _browser(_Calls(), _groups(2), initialOpenKey: "g0"));

      expect(tester.getSize(_inkWellOf("Group 0")).height, greaterThanOrEqualTo(kMinTapTarget));
      expect(tester.getSize(_inkWellOf("Group 1")).height, greaterThanOrEqualTo(kMinTapTarget));
      expect(tester.getSize(_inkWellOf("Item 0.0")).height, greaterThanOrEqualTo(kMinTapTarget));
    });

    testWidgets("dark theme smoke test", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _browser(calls, _groups(3)), theme: AppTheme.dark());

      await tester.tap(find.text("Group 0"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Item 0.1"));
      await tester.pumpAndSettle();

      expect(calls.selected, <int>[1]);
      expect(tester.takeException(), isNull);
    });
  });
}

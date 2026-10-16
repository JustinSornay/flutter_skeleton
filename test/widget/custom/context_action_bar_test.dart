// context_action_bar_test.dart
//
// Widget tests for ContextActionBar: one IconButton per item with its icon,
// tooltip and semantics, taps and disabled items, ColorScheme tokens under
// the light and dark themes, the staggered enter / joint exit animation and
// their durations (including after a change in the number of items),
// hidden-state guards (pointer and semantics), hiding mid-entry, changing
// the number of items while visible, reduced motion, first-mount entry,
// 48 dp targets on every platform and under a compact host iconButtonTheme,
// the published size helpers, the group label and disposal during an
// animation.

import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/ContextActionBar/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

/// Without EasyLocalization in the tree, `.tr()` returns the raw key.
const String _groupKey = "custom.context_action_bar.semantics_label";

/// Records how often each item was pressed, by label.
final class _Taps {
  final Map<String, int> counts = <String, int>{};

  VoidCallback on(String label) {
    return () => counts[label] = (counts[label] ?? 0) + 1;
  }

  int of(String label) => counts[label] ?? 0;
}

const List<IconData> _icons = <IconData>[
  Icons.edit_outlined,
  Icons.share_outlined,
  Icons.copy_outlined,
  Icons.archive_outlined,
  Icons.open_with,
  Icons.delete_outline,
];

/// [count] enabled items labelled "Action 0", "Action 1"…
List<ContextActionBarItem> _items(_Taps taps, int count) {
  return <ContextActionBarItem>[
    for (int i = 0; i < count; i++)
      ContextActionBarItem(icon: _icons[i], label: "Action $i", onPressed: taps.on("Action $i")),
  ];
}

/// One regular, one destructive and one disabled item.
List<ContextActionBarItem> _mixedItems(_Taps taps) {
  return <ContextActionBarItem>[
    ContextActionBarItem(icon: Icons.edit_outlined, label: "Edit", onPressed: taps.on("Edit")),
    ContextActionBarItem(
      icon: Icons.delete_outline,
      label: "Remove",
      onPressed: taps.on("Remove"),
      destructive: true,
    ),
    const ContextActionBarItem(icon: Icons.lock_outline, label: "Locked"),
  ];
}

Widget _bar(List<ContextActionBarItem> actions, {bool visible = true, String? semanticLabel}) {
  return Center(
    child: ContextActionBar(actions: actions, visible: visible, semanticLabel: semanticLabel),
  );
}

/// Forces `MediaQueryData.disableAnimations` for [child].
Widget _reducedMotion(Widget child) {
  return Builder(
    builder: (BuildContext context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child,
    ),
  );
}

Finder _inBar(Finder matching) {
  return find.descendant(of: find.byType(ContextActionBar), matching: matching);
}

/// Opacity of every button, in order.
List<double> _opacities(WidgetTester tester) {
  return tester
      .widgetList<FadeTransition>(_inBar(find.byType(FadeTransition)))
      .map((FadeTransition fade) => fade.opacity.value)
      .toList();
}

/// Slide offset of every button, in order.
List<Offset> _offsets(WidgetTester tester) {
  return tester
      .widgetList<SlideTransition>(_inBar(find.byType(SlideTransition)))
      .map((SlideTransition slide) => slide.position.value)
      .toList();
}

IconButton _button(WidgetTester tester, String label) {
  return tester.widget<IconButton>(find.ancestor(of: find.byTooltip(label), matching: find.byType(IconButton)));
}

/// Colour the button gives its icon.
Color? _iconColor(WidgetTester tester, IconData icon) {
  return IconTheme.of(tester.element(find.byIcon(icon))).color;
}

/// Fill of the circle behind [icon].
Color? _fill(WidgetTester tester, IconData icon) {
  return tester.widget<Material>(find.ancestor(of: find.byIcon(icon), matching: find.byType(Material)).first).color;
}

/// Semantics nodes announcing [tooltip].
SemanticsFinder _nodesWithTooltip(String tooltip) {
  return find.semantics.byPredicate((SemanticsNode node) => node.tooltip == tooltip);
}

Future<void> _expectThemeTokens(WidgetTester tester, ThemeData theme) async {
  await pumpApp(tester, _bar(_mixedItems(_Taps())), theme: theme);
  await tester.pumpAndSettle();
  final ColorScheme cs = theme.colorScheme;

  expect(_iconColor(tester, Icons.edit_outlined), cs.onSurface);
  expect(_iconColor(tester, Icons.delete_outline), cs.error);
  expect(_iconColor(tester, Icons.lock_outline), cs.onSurface.withValues(alpha: 0.38));
  for (final IconData icon in <IconData>[Icons.edit_outlined, Icons.delete_outline, Icons.lock_outline]) {
    expect(_fill(tester, icon), cs.surfaceContainerHigh);
  }
  final Material circle = tester.widget<Material>(
    find.ancestor(of: find.byIcon(Icons.edit_outlined), matching: find.byType(Material)).first,
  );
  expect(circle.elevation, 3);
  expect(circle.shadowColor, cs.shadow);
  expect(circle.shape, isA<CircleBorder>());
}

void main() {
  group("ContextActionBar content", () {
    testWidgets("renders one IconButton per item with its icon and tooltip", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_items(_Taps(), 4)));
      await tester.pumpAndSettle();

      expect(_inBar(find.byType(IconButton)), findsNWidgets(4));
      for (int i = 0; i < 4; i++) {
        expect(find.byIcon(_icons[i]), findsOneWidget);
        expect(find.byTooltip("Action $i"), findsOneWidget);
      }
      final List<double> xs = <double>[
        for (int i = 0; i < 4; i++) tester.getCenter(find.byIcon(_icons[i])).dx,
      ];
      expect(xs, orderedEquals(<double>[...xs]..sort()));
    });

    testWidgets("each button announces its label as an enabled button", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _bar(_mixedItems(_Taps())));
      await tester.pumpAndSettle();

      expect(_nodesWithTooltip("Edit"), findsOne);
      expect(
        tester.getSemantics(find.byTooltip("Edit")),
        isSemantics(tooltip: "Edit", isButton: true, isEnabled: true, hasEnabledState: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.byTooltip("Locked")),
        isSemantics(tooltip: "Locked", isButton: true, isEnabled: false, hasEnabledState: true),
      );
      handle.dispose();
    });

    testWidgets("tapping an item calls its onPressed once", (WidgetTester tester) async {
      final _Taps taps = _Taps();
      await pumpApp(tester, _bar(_mixedItems(taps)));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      expect(taps.of("Edit"), 1);
      expect(taps.of("Remove"), 1);
    });

    testWidgets("an item without onPressed is disabled", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_mixedItems(_Taps())));
      await tester.pumpAndSettle();

      expect(_button(tester, "Locked").onPressed, isNull);
      await tester.tap(find.byIcon(Icons.lock_outline));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets("an empty list renders an empty bar", (WidgetTester tester) async {
      await pumpApp(tester, _bar(const <ContextActionBarItem>[]));
      await tester.pumpAndSettle();

      expect(_inBar(find.byType(IconButton)), findsNothing);
      expect(tester.getSize(find.byType(ContextActionBar)).width, 0);
    });
  });

  group("ContextActionBar colours", () {
    testWidgets("uses ColorScheme tokens in the light theme", (WidgetTester tester) async {
      await _expectThemeTokens(tester, AppTheme.light());
    });

    testWidgets("uses ColorScheme tokens in the dark theme", (WidgetTester tester) async {
      await _expectThemeTokens(tester, AppTheme.dark());
    });
  });

  group("ContextActionBar visibility", () {
    testWidgets("visible and settled: every button is opaque and in place", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_items(_Taps(), 4)));
      await tester.pumpAndSettle();

      expect(_opacities(tester), <double>[1, 1, 1, 1]);
      expect(_offsets(tester), everyElement(Offset.zero));
    });

    testWidgets("built hidden: transparent, untappable and out of semantics", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final _Taps taps = _Taps();
      await pumpApp(tester, _bar(_items(taps, 3), visible: false));
      await tester.pumpAndSettle();

      expect(_opacities(tester), <double>[0, 0, 0]);
      expect(tester.widget<IgnorePointer>(_inBar(find.byType(IgnorePointer)).first).ignoring, isTrue);
      await tester.tap(find.byIcon(_icons[0]), warnIfMissed: false);
      await tester.pump();
      expect(taps.of("Action 0"), 0);
      expect(_nodesWithTooltip("Action 0"), findsNothing);
      expect(find.semantics.byLabel(_groupKey), findsNothing);
      handle.dispose();
    });

    testWidgets("showing staggers the buttons, then settles fully visible", (WidgetTester tester) async {
      final List<ContextActionBarItem> items = _items(_Taps(), 4);
      await pumpApp(tester, _bar(items, visible: false));
      await pumpApp(tester, _bar(items));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      final List<double> mid = _opacities(tester);
      expect(mid.first, greaterThan(0));
      expect(mid.first, greaterThan(mid.last));
      expect(mid.last, 0);
      expect(_offsets(tester).last.dy, closeTo(0.25, 1e-9));

      await tester.pumpAndSettle();
      expect(_opacities(tester), <double>[1, 1, 1, 1]);
    });

    testWidgets("the enter animation lasts kMotionShort plus the stagger", (WidgetTester tester) async {
      final List<ContextActionBarItem> items = _items(_Taps(), 4);
      await pumpApp(tester, _bar(items, visible: false));
      await pumpApp(tester, _bar(items));
      await tester.pump();
      await tester.pump(kMotionShort + const Duration(milliseconds: 60));
      expect(_opacities(tester).last, lessThan(1));

      await tester.pump(const Duration(milliseconds: 30));
      expect(_opacities(tester), <double>[1, 1, 1, 1]);
      // The controller reports completion on the frame after its last value.
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets("the enter duration follows a count change made while hidden", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_items(_Taps(), 2), visible: false));
      await pumpApp(tester, _bar(_items(_Taps(), 6), visible: false));
      await pumpApp(tester, _bar(_items(_Taps(), 6)));
      await tester.pump();
      // Six buttons: the last one starts 5 staggers late, so the entry
      // lasts kMotionShort + 150 ms. Stop 30 ms short of it.
      await tester.pump(kMotionShort + const Duration(milliseconds: 5 * 30 - 30));
      expect(_opacities(tester).last, lessThan(1));

      await tester.pump(const Duration(milliseconds: 30));
      expect(_opacities(tester), everyElement(1));
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets("hiding fades every button out together", (WidgetTester tester) async {
      final _Taps taps = _Taps();
      final List<ContextActionBarItem> items = _items(taps, 4);
      await pumpApp(tester, _bar(items));
      await tester.pumpAndSettle();
      final Offset target = tester.getCenter(find.byIcon(_icons[0]));

      await pumpApp(tester, _bar(items, visible: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final List<double> mid = _opacities(tester);
      expect(mid.first, inExclusiveRange(0, 1));
      expect(mid, everyElement(mid.first));

      // The joint exit lasts 160 ms: still visible at 159 ms, gone at 161 ms.
      await tester.pump(const Duration(milliseconds: 79));
      final List<double> late = _opacities(tester);
      expect(late.first, greaterThan(0));
      expect(late, everyElement(late.first));
      await tester.pump(const Duration(milliseconds: 2));
      expect(_opacities(tester), <double>[0, 0, 0, 0]);
      expect(tester.hasRunningAnimations, isFalse);

      await tester.tapAt(target);
      await tester.pump();
      expect(taps.of("Action 0"), 0);
    });

    testWidgets("a hidden bar ignores taps as soon as visible turns false", (WidgetTester tester) async {
      final _Taps taps = _Taps();
      final List<ContextActionBarItem> items = _items(taps, 2);
      await pumpApp(tester, _bar(items));
      await tester.pumpAndSettle();

      await pumpApp(tester, _bar(items, visible: false));
      await tester.pump(const Duration(milliseconds: 10));
      await tester.tap(find.byIcon(_icons[0]), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(taps.of("Action 0"), 0);
    });

    testWidgets("hiding during the staggered entry ends fully hidden", (WidgetTester tester) async {
      final List<ContextActionBarItem> items = _items(_Taps(), 6);
      await pumpApp(tester, _bar(items, visible: false));
      await pumpApp(tester, _bar(items));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      await pumpApp(tester, _bar(items, visible: false));
      await tester.pumpAndSettle();
      expect(_opacities(tester), everyElement(0));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets("showing again during the exit ends fully visible", (WidgetTester tester) async {
      final List<ContextActionBarItem> items = _items(_Taps(), 3);
      await pumpApp(tester, _bar(items));
      await tester.pumpAndSettle();

      await pumpApp(tester, _bar(items, visible: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      await pumpApp(tester, _bar(items));
      await tester.pumpAndSettle();
      expect(_opacities(tester), <double>[1, 1, 1]);
    });

    testWidgets("adding or removing items while visible keeps the bar visible", (WidgetTester tester) async {
      final _Taps taps = _Taps();
      await pumpApp(tester, _bar(_items(taps, 2)));
      await tester.pumpAndSettle();

      await pumpApp(tester, _bar(_items(taps, 5)));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(_opacities(tester), <double>[1, 1, 1, 1, 1]);

      await pumpApp(tester, _bar(_items(taps, 1)));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(_opacities(tester), <double>[1]);

      await tester.tap(find.byIcon(_icons[0]));
      expect(taps.of("Action 0"), 1);
    });

    testWidgets("changing the number of items during the entry settles visible", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_items(_Taps(), 6), visible: false));
      await pumpApp(tester, _bar(_items(_Taps(), 6)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      await pumpApp(tester, _bar(_items(_Taps(), 2)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_opacities(tester), <double>[1, 1]);
    });

    testWidgets("first mount with visible true plays the staggered entry", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_items(_Taps(), 4)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      final List<double> mid = _opacities(tester);
      expect(mid.first, greaterThan(mid.last));

      await tester.pumpAndSettle();
      expect(_opacities(tester), <double>[1, 1, 1, 1]);
    });

    testWidgets("reduced motion snaps in and out without running animations", (WidgetTester tester) async {
      final List<ContextActionBarItem> items = _items(_Taps(), 3);
      await pumpApp(tester, _reducedMotion(_bar(items)));
      expect(_opacities(tester), <double>[1, 1, 1]);
      expect(tester.hasRunningAnimations, isFalse);

      await pumpApp(tester, _reducedMotion(_bar(items, visible: false)));
      await tester.pump();
      expect(_opacities(tester), <double>[0, 0, 0]);
      expect(tester.hasRunningAnimations, isFalse);

      await pumpApp(tester, _reducedMotion(_bar(items)));
      await tester.pump();
      expect(_opacities(tester), <double>[1, 1, 1]);
      expect(_offsets(tester), everyElement(Offset.zero));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets("disposing during an animation throws nothing", (WidgetTester tester) async {
      final List<ContextActionBarItem> items = _items(_Taps(), 4);
      await pumpApp(tester, _bar(items, visible: false));
      await pumpApp(tester, _bar(items));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));

      await pumpApp(tester, const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });
  });

  group("ContextActionBar layout and accessibility", () {
    testWidgets(
      "every button has a 48 dp target and the size helpers match",
      (WidgetTester tester) async {
        for (final int count in <int>[1, 4, 6]) {
          await pumpApp(tester, _bar(_items(_Taps(), count)));
          await tester.pumpAndSettle();

          expect(tester.getSize(find.byType(ContextActionBar)), Size(ContextActionBar.widthFor(count), ContextActionBar.height));
          for (final Element button in _inBar(find.byType(IconButton)).evaluate()) {
            final Size size = tester.getSize(find.byElementPredicate((Element e) => e == button));
            expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
            expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
          }
        }
      },
      variant: TargetPlatformVariant.all(),
    );

    testWidgets("a compact host iconButtonTheme keeps the 48 dp target", (WidgetTester tester) async {
      final ThemeData compact = AppTheme.light().copyWith(
        iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(visualDensity: VisualDensity.compact)),
      );
      await pumpApp(tester, _bar(_items(_Taps(), 3)), theme: compact);
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(ContextActionBar)), Size(ContextActionBar.widthFor(3), ContextActionBar.height));
      for (final Element button in _inBar(find.byType(IconButton)).evaluate()) {
        expect(tester.getSize(find.byElementPredicate((Element e) => e == button)), const Size.square(kMinTapTarget));
      }
    });

    testWidgets("the visible circle is 40 dp, 8 dp apart from its neighbour", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_items(_Taps(), 2)));
      await tester.pumpAndSettle();

      final Finder first = find.ancestor(of: find.byIcon(_icons[0]), matching: find.byType(Material)).first;
      final Finder second = find.ancestor(of: find.byIcon(_icons[1]), matching: find.byType(Material)).first;
      expect(tester.getSize(first), const Size.square(40));
      expect(tester.getTopLeft(second).dx - tester.getTopRight(first).dx, 8);
    });

    testWidgets("meets the Android tap target guideline", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _bar(_mixedItems(_Taps())));
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets("the group uses the default label key", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _bar(_items(_Taps(), 2)));
      await tester.pumpAndSettle();

      expect(find.semantics.byLabel(_groupKey), findsOne);
      handle.dispose();
    });

    testWidgets("semanticLabel overrides the group label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _bar(_items(_Taps(), 2), semanticLabel: "Shape actions"));
      await tester.pumpAndSettle();

      expect(find.semantics.byLabel("Shape actions"), findsOne);
      expect(find.semantics.byLabel(_groupKey), findsNothing);
      handle.dispose();
    });
  });
}

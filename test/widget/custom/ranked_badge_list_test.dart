// ranked_badge_list_test.dart
//
// Widget tests for RankedBadgeList: empty list, descending-weight ranking
// (stable ties, input never mutated), collapsed slice and toggle (i18n keys,
// overrides, chevron, expand / collapse), the composed StatusPill (text,
// tone colours, semantics), the trailing builder, toggle semantics and tap
// target, reduced motion, a narrow parent and the dark theme.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/RankedBadgeList/index.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _showAll = "custom.ranked_badge_list.show_all";
const String _showLess = "custom.ranked_badge_list.show_less";

/// Four items given out of order: ranked a (0.30), b (0.22), c (0.11), d (0.05).
const List<RankedBadgeItem> _items = <RankedBadgeItem>[
  RankedBadgeItem(id: "c", label: "Gamma", weight: 0.11, tone: StatusTone.warning),
  RankedBadgeItem(id: "a", label: "Alpha", weight: 0.30, valueLabel: "−30 %", tone: StatusTone.danger),
  RankedBadgeItem(id: "d", label: "Delta", weight: 0.05),
  RankedBadgeItem(id: "b", label: "Beta", weight: 0.22, valueLabel: "−22 %", tone: StatusTone.danger),
];

Finder _inList(Finder matching) {
  return find.descendant(of: find.byType(RankedBadgeList), matching: matching);
}

Finder _toggle() => _inList(find.byType(InkWell));

/// Text of every StatusPill, top to bottom.
List<String> _pillLabels(WidgetTester tester) {
  return tester.widgetList<StatusPill>(_inList(find.byType(StatusPill))).map((StatusPill pill) => pill.label).toList();
}

StatusPill _pill(WidgetTester tester, String label) {
  return tester.widgetList<StatusPill>(find.byType(StatusPill)).firstWhere((StatusPill pill) => pill.label == label);
}

/// The row holding each StatusPill (its nearest Row ancestor), top to bottom.
List<Row> _badgeRows(WidgetTester tester) {
  return <Row>[
    for (final Element pill in find.byType(StatusPill).evaluate())
      tester.widget<Row>(find.ancestor(of: find.byWidget(pill.widget), matching: find.byType(Row)).first),
  ];
}

Widget _reducedMotion(Widget child) {
  return Builder(
    builder: (BuildContext context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child,
    ),
  );
}

Future<void> _tapToggle(WidgetTester tester) async {
  await tester.tap(_toggle());
  await tester.pumpAndSettle();
}

void main() {
  group("empty", () {
    testWidgets("renders nothing for an empty list", (WidgetTester tester) async {
      await pumpApp(tester, const RankedBadgeList(items: <RankedBadgeItem>[]));

      expect(_inList(find.byType(StatusPill)), findsNothing);
      expect(_inList(find.byType(InkWell)), findsNothing);
      expect(_inList(find.byType(Text)), findsNothing);
      expect(tester.getSize(find.byType(RankedBadgeList)), Size.zero);
    });
  });

  group("ranking", () {
    testWidgets("shows items by descending weight", (WidgetTester tester) async {
      await pumpApp(tester, const RankedBadgeList(items: _items, collapsedCount: 4));

      expect(_pillLabels(tester), <String>["Alpha · −30 %", "Beta · −22 %", "Gamma", "Delta"]);
      final double alpha = tester.getTopLeft(find.text("Alpha · −30 %")).dy;
      final double beta = tester.getTopLeft(find.text("Beta · −22 %")).dy;
      final double gamma = tester.getTopLeft(find.text("Gamma")).dy;
      expect(alpha, lessThan(beta));
      expect(beta, lessThan(gamma));
    });

    testWidgets("equal weights keep their input order", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const RankedBadgeList(
          items: <RankedBadgeItem>[
            RankedBadgeItem(id: "1", label: "First", weight: 0.1),
            RankedBadgeItem(id: "2", label: "Second", weight: 0.1),
            RankedBadgeItem(id: "3", label: "Top", weight: 0.9),
            RankedBadgeItem(id: "4", label: "Third", weight: 0.1),
          ],
          collapsedCount: 4,
        ),
      );

      expect(_pillLabels(tester), <String>["Top", "First", "Second", "Third"]);
    });

    testWidgets("never mutates the given list", (WidgetTester tester) async {
      final List<RankedBadgeItem> items = List<RankedBadgeItem>.of(_items);
      await pumpApp(tester, RankedBadgeList(items: items));

      expect(items.map((RankedBadgeItem item) => item.id).toList(), <String>["c", "a", "d", "b"]);
    });
  });

  group("collapsed", () {
    testWidgets("shows the first three by default with the show-all toggle", (WidgetTester tester) async {
      await pumpApp(tester, const RankedBadgeList(items: _items));

      expect(_pillLabels(tester), <String>["Alpha · −30 %", "Beta · −22 %", "Gamma"]);
      expect(find.text("Delta"), findsNothing);
      expect(find.text(_showAll), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up), findsNothing);
    });

    testWidgets("no toggle when every item fits", (WidgetTester tester) async {
      await pumpApp(tester, RankedBadgeList(items: _items.take(3).toList()));
      expect(_toggle(), findsNothing);
      expect(_pillLabels(tester), hasLength(3));

      await pumpApp(tester, RankedBadgeList(items: _items.take(1).toList(), collapsedCount: 1));
      expect(_toggle(), findsNothing);
      expect(_pillLabels(tester), hasLength(1));
    });

    testWidgets("collapsedCount sets the visible slice", (WidgetTester tester) async {
      await pumpApp(tester, const RankedBadgeList(items: _items, collapsedCount: 1));

      expect(_pillLabels(tester), <String>["Alpha · −30 %"]);
      expect(_toggle(), findsOneWidget);
    });

    testWidgets("asserts a positive collapsedCount", (WidgetTester tester) async {
      int count() => 0;
      expect(() => RankedBadgeList(items: _items, collapsedCount: count()), throwsAssertionError);
    });
  });

  group("toggle", () {
    testWidgets("expands to every item, then collapses back", (WidgetTester tester) async {
      await pumpApp(tester, const RankedBadgeList(items: _items));

      await _tapToggle(tester);
      expect(_pillLabels(tester), <String>["Alpha · −30 %", "Beta · −22 %", "Gamma", "Delta"]);
      expect(find.text(_showLess), findsOneWidget);
      expect(find.text(_showAll), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);

      await _tapToggle(tester);
      expect(_pillLabels(tester), hasLength(3));
      expect(find.text("Delta"), findsNothing);
      expect(find.text(_showAll), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });

    testWidgets("expanding animates the list height", (WidgetTester tester) async {
      await pumpApp(tester, const RankedBadgeList(items: _items));
      final double collapsed = tester.getSize(find.byType(AnimatedSize)).height;

      await tester.tap(_toggle());
      await tester.pump();
      await tester.pump(kMotionShort ~/ 2);
      final double midway = tester.getSize(find.byType(AnimatedSize)).height;
      await tester.pumpAndSettle();
      final double expanded = tester.getSize(find.byType(AnimatedSize)).height;

      expect(midway, greaterThan(collapsed));
      expect(midway, lessThan(expanded));
    });

    testWidgets("host labels override the built-in keys", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const RankedBadgeList(items: _items, showAllLabel: "More causes", showLessLabel: "Fewer causes"),
      );
      expect(find.text("More causes"), findsOneWidget);
      expect(find.text(_showAll), findsNothing);

      await _tapToggle(tester);
      expect(find.text("Fewer causes"), findsOneWidget);
      expect(find.text(_showLess), findsNothing);
    });

    testWidgets("is a button with an expanded state", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const RankedBadgeList(items: _items));

      expect(
        tester.getSemantics(_toggle()),
        matchesSemantics(
          label: _showAll,
          isButton: true,
          hasTapAction: true,
          hasExpandedState: true,
          isExpanded: false,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );

      await _tapToggle(tester);
      expect(
        tester.getSemantics(_toggle()),
        matchesSemantics(
          label: _showLess,
          isButton: true,
          hasTapAction: true,
          hasExpandedState: true,
          isExpanded: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets("hit area is at least kMinTapTarget high", (WidgetTester tester) async {
      await pumpApp(tester, const RankedBadgeList(items: _items));

      expect(tester.getSize(_toggle()).height, greaterThanOrEqualTo(kMinTapTarget));
    });

    testWidgets("uses the primary colour, underlined", (WidgetTester tester) async {
      await pumpApp(tester, const RankedBadgeList(items: _items));
      final ColorScheme cs = Theme.of(tester.element(find.byType(RankedBadgeList))).colorScheme;
      final TextStyle? style = tester.widget<Text>(find.text(_showAll)).style;

      expect(style?.color, cs.primary);
      expect(style?.decoration, TextDecoration.underline);
      expect(tester.widget<Icon>(find.byIcon(Icons.keyboard_arrow_down)).color, cs.primary);
    });

    testWidgets("reduced motion shows every item in one frame", (WidgetTester tester) async {
      await pumpApp(tester, _reducedMotion(const RankedBadgeList(items: _items)));

      await tester.tap(_toggle());
      await tester.pump();
      final double afterOneFrame = tester.getSize(find.byType(RankedBadgeList)).height;

      expect(_pillLabels(tester), hasLength(4));
      expect(_inList(find.byType(AnimatedSize)), findsNothing);
      // Only the InkWell splash may still run; the list height is final.
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(RankedBadgeList)).height, afterOneFrame);
    });
  });

  group("badges", () {
    testWidgets("each badge is a StatusPill in the item tone", (WidgetTester tester) async {
      await pumpApp(tester, const RankedBadgeList(items: _items, collapsedCount: 4));

      expect(_pill(tester, "Alpha · −30 %").tone, StatusTone.danger);
      expect(_pill(tester, "Gamma").tone, StatusTone.warning);
      expect(_pill(tester, "Delta").tone, StatusTone.neutral);
    });

    testWidgets("paints onContainer text on the tone container", (WidgetTester tester) async {
      await pumpApp(tester, const RankedBadgeList(items: _items, collapsedCount: 4));
      final BuildContext context = tester.element(find.byType(RankedBadgeList));

      for (final (String label, StatusTone tone) in <(String, StatusTone)>[
        ("Alpha · −30 %", StatusTone.danger),
        ("Gamma", StatusTone.warning),
      ]) {
        final ToneColors colors = StatusTones.colorsOf(context, tone);
        final Finder pill = find.ancestor(of: find.text(label), matching: find.byType(StatusPill));
        final Container box = tester.widget<Container>(find.descendant(of: pill, matching: find.byType(Container)));

        expect((box.decoration! as BoxDecoration).color, colors.container);
        expect(tester.widget<Text>(find.text(label)).style?.color, colors.onContainer);
      }
    });

    testWidgets("an empty value shows the label alone", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const RankedBadgeList(items: <RankedBadgeItem>[RankedBadgeItem(id: "x", label: "Solo", weight: 1, valueLabel: "")]),
      );

      expect(_pillLabels(tester), <String>["Solo"]);
    });

    testWidgets("semantics default to label and value, or the host label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const RankedBadgeList(
          items: <RankedBadgeItem>[
            RankedBadgeItem(id: "a", label: "Alpha", weight: 3, valueLabel: "−30 %"),
            RankedBadgeItem(id: "b", label: "Beta", weight: 2),
            RankedBadgeItem(id: "c", label: "Gamma", weight: 1, valueLabel: "−5 %", semanticsLabel: "Gamma lowers it by 5 percent"),
          ],
        ),
      );

      expect(find.bySemanticsLabel("Alpha, −30 %"), findsOneWidget);
      expect(find.bySemanticsLabel("Beta"), findsOneWidget);
      expect(find.bySemanticsLabel("Gamma lowers it by 5 percent"), findsOneWidget);
      expect(find.bySemanticsLabel("Alpha · −30 %"), findsNothing);
      handle.dispose();
    });

    testWidgets("a long label ellipsises in a narrow parent", (WidgetTester tester) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 200,
          child: RankedBadgeList(
            items: const <RankedBadgeItem>[
              RankedBadgeItem(id: "x", label: "A very long label that cannot fit on one line", weight: 1, valueLabel: "−9 %"),
            ],
            trailingBuilder: (BuildContext context, RankedBadgeItem item) => const Text("Help"),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(StatusPill)).width, lessThanOrEqualTo(200));
    });
  });

  group("trailingBuilder", () {
    testWidgets("is called for each visible item, in ranked order", (WidgetTester tester) async {
      final List<String> built = <String>[];
      await pumpApp(
        tester,
        RankedBadgeList(
          items: _items,
          trailingBuilder: (BuildContext context, RankedBadgeItem item) {
            built.add(item.id);
            return Text("help-${item.id}");
          },
        ),
      );

      expect(built, <String>["a", "b", "c"]);
      expect(find.text("help-a"), findsOneWidget);
      final Offset badge = tester.getCenter(find.text("Alpha · −30 %"));
      final Offset trailing = tester.getCenter(find.text("help-a"));
      expect(trailing.dx, greaterThan(badge.dx));
      expect((trailing.dy - badge.dy).abs(), lessThan(1));

      for (final Row row in _badgeRows(tester)) {
        expect(row.children, hasLength(3));
      }

      built.clear();
      await _tapToggle(tester);
      expect(built, <String>["a", "b", "c", "d"]);
      expect(find.text("help-d"), findsOneWidget);
    });

    testWidgets("null builder renders the badge only", (WidgetTester tester) async {
      await pumpApp(tester, const RankedBadgeList(items: _items, collapsedCount: 4));

      expect(_badgeRows(tester), hasLength(4));
      for (final Row row in _badgeRows(tester)) {
        expect(row.children, hasLength(1));
      }
    });
  });

  group("dark theme", () {
    testWidgets("renders with the dark tone colours", (WidgetTester tester) async {
      await pumpApp(tester, const RankedBadgeList(items: _items), theme: AppTheme.dark());
      final BuildContext context = tester.element(find.byType(RankedBadgeList));
      final ToneColors danger = StatusTones.colorsOf(context, StatusTone.danger);

      expect(Theme.of(context).colorScheme.brightness, Brightness.dark);
      expect(tester.takeException(), isNull);
      expect(tester.widget<Text>(find.text("Alpha · −30 %")).style?.color, danger.onContainer);

      await _tapToggle(tester);
      expect(_pillLabels(tester), hasLength(4));
    });
  });
}

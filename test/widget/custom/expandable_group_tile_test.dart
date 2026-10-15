// expandable_group_tile_test.dart
//
// Widget tests for ExpandableGroupTile: closed / open accordion structure,
// header and entry callbacks with a generic value, disabled entries, direct
// (non-expandable) mode, its subtitle fallback and its dimmed inert state,
// empty entries, the chevron rotation and body resize (durations, reduced
// motion, mid-animation size), header / entry semantics (tap hints, spoken
// fallback subtitle), 48 dp targets, narrow layouts and the ColorScheme
// tokens under the light and dark themes.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/ExpandableGroupTile/index.dart";
import "package:flutter_skeleton/widgets/custom/_base/choice_option.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _title = "Group A";
const String _subtitle = "3 items";

const List<ChoiceOption<int>> _entries = <ChoiceOption<int>>[
  ChoiceOption<int>(value: 1, label: "Alpha", description: "First entry", trailing: "5"),
  ChoiceOption<int>(value: 2, label: "Beta", description: "Second entry", trailing: "4"),
  ChoiceOption<int>(value: 3, label: "Gamma", trailing: "3"),
];

/// Records the callbacks of one tile.
final class _Calls {
  int toggles = 0;
  final List<int> selected = <int>[];
}

ExpandableGroupTile<int> _tile(
  _Calls calls, {
  bool isOpen = false,
  bool expandable = true,
  String? subtitle = _subtitle,
  IconData? icon = Icons.folder_outlined,
  List<ChoiceOption<int>> entries = _entries,
  String title = _title,
}) {
  return ExpandableGroupTile<int>(
    title: title,
    subtitle: subtitle,
    icon: icon,
    entries: entries,
    isOpen: isOpen,
    expandable: expandable,
    onToggle: () => calls.toggles++,
    onSelected: calls.selected.add,
  );
}

Finder _inTile(Finder matching) {
  return find.descendant(of: find.byType(ExpandableGroupTile<int>), matching: matching);
}

/// The InkWell holding [text] (header or entry row).
Finder _inkWellOf(String text) {
  return find.ancestor(of: find.text(text), matching: find.byType(InkWell)).first;
}

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(ExpandableGroupTile<int>))).colorScheme;
}

Color? _textColor(WidgetTester tester, String text) => tester.widget<Text>(find.text(text)).style?.color;

/// Opacity applied to the header content (the title's only Opacity ancestor).
double _headerOpacity(WidgetTester tester) {
  return tester.widget<Opacity>(find.ancestor(of: find.text(_title), matching: find.byType(Opacity))).opacity;
}

/// Host that owns the open state, like a real parent would.
Widget _controlledHost(_Calls calls) {
  bool open = false;
  return StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) => ExpandableGroupTile<int>(
      title: _title,
      subtitle: _subtitle,
      entries: _entries,
      isOpen: open,
      onToggle: () => setState(() {
        calls.toggles++;
        open = !open;
      }),
      onSelected: calls.selected.add,
    ),
  );
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

void main() {
  group("accordion", () {
    testWidgets("closed: header only, no entries, down chevron", (WidgetTester tester) async {
      await pumpApp(tester, _tile(_Calls()));

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_subtitle), findsOneWidget);
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      for (final ChoiceOption<int> entry in _entries) {
        expect(find.text(entry.label), findsNothing);
      }
      expect(_inTile(find.byType(Divider)), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets("open: divider then every entry's label, description and trailing", (WidgetTester tester) async {
      await pumpApp(tester, _tile(_Calls(), isOpen: true));

      expect(_inTile(find.byType(Divider)), findsOneWidget);
      for (final ChoiceOption<int> entry in _entries) {
        expect(find.text(entry.label), findsOneWidget);
        expect(find.text(entry.trailing!), findsOneWidget);
      }
      expect(find.text("First entry"), findsOneWidget);
      expect(find.text("Second entry"), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(_entries.length));
      expect(tester.widget<Icon>(find.byIcon(Icons.chevron_right).first).size, 16);
      expect(
        tester.getTopLeft(find.byType(Divider)).dy,
        lessThan(tester.getTopLeft(find.text("Alpha")).dy),
      );
    });

    testWidgets("a header tap calls onToggle once and never onSelected", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _tile(calls));

      await tester.tap(find.text(_title));
      await tester.pump();

      expect(calls.toggles, 1);
      expect(calls.selected, isEmpty);
    });

    testWidgets("an entry tap calls onSelected with that entry's typed value", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _tile(calls, isOpen: true));

      await tester.tap(find.text("Beta"));
      await tester.tap(find.text("Gamma"));
      await tester.pump();

      expect(calls.selected, <int>[2, 3]);
      expect(calls.toggles, 0);
    });

    testWidgets("a disabled entry is dimmed and ignores taps", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(
        tester,
        _tile(
          calls,
          isOpen: true,
          entries: const <ChoiceOption<int>>[
            ChoiceOption<int>(value: 1, label: "Alpha"),
            ChoiceOption<int>(value: 2, label: "Beta", enabled: false),
          ],
        ),
      );

      await tester.tap(find.text("Beta"));
      await tester.pump();
      expect(calls.selected, isEmpty);

      final Opacity dimmed = tester.widget<Opacity>(find.ancestor(of: find.text("Beta"), matching: find.byType(Opacity)));
      final Opacity normal = tester.widget<Opacity>(find.ancestor(of: find.text("Alpha"), matching: find.byType(Opacity)));
      expect(dimmed.opacity, 0.38);
      expect(normal.opacity, 1);
    });

    testWidgets("a null or empty subtitle is hidden", (WidgetTester tester) async {
      await pumpApp(tester, _tile(_Calls(), subtitle: null));
      expect(_inTile(find.byType(Text)), findsOneWidget);

      await pumpApp(tester, _tile(_Calls(), subtitle: ""));
      expect(_inTile(find.byType(Text)), findsOneWidget);
    });

    testWidgets("no icon: the title starts at the padding edge", (WidgetTester tester) async {
      await pumpApp(tester, _tile(_Calls(), icon: null));

      expect(_inTile(find.byIcon(Icons.folder_outlined)), findsNothing);
      final double cardLeft = tester.getTopLeft(_inTile(find.byType(Card))).dx;
      expect(tester.getTopLeft(find.text(_title)).dx - cardLeft, closeTo(kDefaultPadding * 2, 1.5));
    });

    testWidgets("a parent owning isOpen opens and closes the body", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _controlledHost(calls));

      await tester.tap(find.text(_title));
      await tester.pumpAndSettle();
      expect(find.text("Alpha"), findsOneWidget);

      await tester.tap(find.text(_title));
      await tester.pumpAndSettle();
      expect(find.text("Alpha"), findsNothing);
      expect(calls.toggles, 2);
    });

    testWidgets("empty entries: the header renders and opening shows only the divider", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _tile(calls, isOpen: true, entries: const <ChoiceOption<int>>[]));

      expect(tester.takeException(), isNull);
      expect(find.text(_title), findsOneWidget);
      expect(_inTile(find.byType(Divider)), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);

      await tester.tap(find.text(_title));
      expect(calls.toggles, 1);
    });
  });

  group("direct mode (expandable: false)", () {
    testWidgets("shows chevron_right, no body even when isOpen, subtitle = first label", (WidgetTester tester) async {
      await pumpApp(tester, _tile(_Calls(), expandable: false, isOpen: true, subtitle: null));

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
      expect(_inTile(find.byType(AnimatedSize)), findsNothing);
      expect(_inTile(find.byType(AnimatedRotation)), findsNothing);
      expect(_inTile(find.byType(Divider)), findsNothing);
      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("Beta"), findsNothing);
      expect(tester.widget<Icon>(find.byIcon(Icons.chevron_right)).size, isNull);
    });

    testWidgets("a header tap selects the first entry and does not toggle", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _tile(calls, expandable: false));

      await tester.tap(find.text(_title));
      await tester.pump();

      expect(calls.selected, <int>[1]);
      expect(calls.toggles, 0);
      expect(_headerOpacity(tester), 1);
    });

    testWidgets("an explicit subtitle overrides the first-label fallback", (WidgetTester tester) async {
      await pumpApp(tester, _tile(_Calls(), expandable: false));

      expect(find.text(_subtitle), findsOneWidget);
      expect(find.text("Alpha"), findsNothing);
    });

    testWidgets("empty entries: the header is inert and nothing throws", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(
        tester,
        _tile(calls, expandable: false, subtitle: null, entries: const <ChoiceOption<int>>[]),
      );

      await tester.tap(find.text(_title), warnIfMissed: false);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(calls.selected, isEmpty);
      expect(calls.toggles, 0);
      expect(_headerOpacity(tester), 0.38);
      expect(
        tester.getSemantics(find.text(_title)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false, hasTapAction: false),
      );
    });

    testWidgets("a disabled first entry makes the header inert", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(
        tester,
        _tile(
          calls,
          expandable: false,
          entries: const <ChoiceOption<int>>[ChoiceOption<int>(value: 9, label: "Only", enabled: false)],
        ),
      );

      await tester.tap(find.text(_title), warnIfMissed: false);
      await tester.pump();

      expect(calls.selected, isEmpty);
      expect(_headerOpacity(tester), 0.38);
      expect(
        tester.getSemantics(find.text(_title)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false, hasTapAction: false),
      );
    });

    testWidgets("with one entry, expandable stays an accordion", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      const List<ChoiceOption<int>> single = <ChoiceOption<int>>[ChoiceOption<int>(value: 7, label: "Only")];
      await pumpApp(tester, _tile(calls, isOpen: true, entries: single, subtitle: null));

      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      expect(find.text("Only"), findsOneWidget);

      await tester.tap(find.text(_title));
      await tester.tap(find.text("Only"));
      expect(calls.toggles, 1);
      expect(calls.selected, <int>[7]);
    });
  });

  group("motion", () {
    testWidgets("the chevron turns half a turn when open, over kMotionShort", (WidgetTester tester) async {
      await pumpApp(tester, _tile(_Calls()));
      AnimatedRotation rotation = tester.widget<AnimatedRotation>(_inTile(find.byType(AnimatedRotation)));
      expect(rotation.turns, 0);
      expect(rotation.duration, kMotionShort);
      expect(rotation.curve, Curves.easeInOut);

      await pumpApp(tester, _tile(_Calls(), isOpen: true));
      await tester.pumpAndSettle();
      rotation = tester.widget<AnimatedRotation>(_inTile(find.byType(AnimatedRotation)));
      expect(rotation.turns, 0.5);

      final AnimatedSize size = tester.widget<AnimatedSize>(_inTile(find.byType(AnimatedSize)));
      expect(size.duration, kMotionShort);
      expect(size.curve, Curves.easeInOut);
    });

    testWidgets("the body grows progressively while opening", (WidgetTester tester) async {
      await pumpApp(tester, _controlledHost(_Calls()));
      final double closed = tester.getSize(_inTile(find.byType(Card))).height;

      await tester.tap(find.text(_title));
      await tester.pump();
      await tester.pump(kMotionShort ~/ 2);
      final double halfway = tester.getSize(_inTile(find.byType(Card))).height;

      await tester.pumpAndSettle();
      final double open = tester.getSize(_inTile(find.byType(Card))).height;

      expect(halfway, greaterThan(closed));
      expect(halfway, lessThan(open));
    });

    testWidgets("reduced motion: zero rotation, no AnimatedSize, the body opens and closes at once", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _reducedMotion(_controlledHost(calls)));
      final double closed = tester.getSize(_inTile(find.byType(Card))).height;

      expect(tester.widget<AnimatedRotation>(_inTile(find.byType(AnimatedRotation))).duration, Duration.zero);
      expect(_inTile(find.byType(AnimatedSize)), findsNothing);

      await tester.tap(find.text(_title));
      await tester.pump();
      final double afterOneFrame = tester.getSize(_inTile(find.byType(Card))).height;
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text("Alpha"), findsOneWidget);
      expect(afterOneFrame, greaterThan(closed));
      expect(tester.getSize(_inTile(find.byType(Card))).height, afterOneFrame);

      await tester.tap(find.text(_title));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text("Alpha"), findsNothing);
      expect(tester.getSize(_inTile(find.byType(Card))).height, closed);
    });
  });

  group("semantics", () {
    testWidgets("accordion header: button with an expanded state and tap hint that follow isOpen", (WidgetTester tester) async {
      await pumpApp(tester, _tile(_Calls()));
      expect(
        tester.getSemantics(find.text(_title)),
        isSemantics(
          label: "$_title\n$_subtitle",
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasExpandedState: true,
          isExpanded: false,
          hasTapAction: true,
          onTapHint: "custom.expandable_group_tile.expand",
        ),
      );
      expect(_headerOpacity(tester), 1);

      await pumpApp(tester, _tile(_Calls(), isOpen: true));
      expect(
        tester.getSemantics(find.text(_title)),
        isSemantics(
          isButton: true,
          hasExpandedState: true,
          isExpanded: true,
          onTapHint: "custom.expandable_group_tile.collapse",
        ),
      );
    });

    testWidgets("direct header: button without an expanded state or tap hint", (WidgetTester tester) async {
      await pumpApp(tester, _tile(_Calls(), expandable: false));

      expect(
        tester.getSemantics(find.text(_title)),
        isSemantics(isButton: true, hasExpandedState: false, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.text(_title)).getSemanticsData().customSemanticsActionIds,
        anyOf(isNull, isEmpty),
      );
    });

    testWidgets("direct header: the fallback subtitle is spoken as the first entry's semanticsLabel", (WidgetTester tester) async {
      const List<ChoiceOption<int>> spoken = <ChoiceOption<int>>[
        ChoiceOption<int>(value: 1, label: "Alpha", semanticsLabel: "Alpha, five items"),
      ];
      await pumpApp(tester, _tile(_Calls(), expandable: false, subtitle: null, entries: spoken));

      expect(find.text("Alpha"), findsOneWidget);
      expect(
        tester.getSemantics(find.text(_title)),
        isSemantics(label: "$_title\nAlpha, five items", isButton: true, hasTapAction: true),
      );

      await pumpApp(tester, _tile(_Calls(), expandable: false, entries: spoken));
      expect(
        tester.getSemantics(find.text(_title)),
        isSemantics(label: "$_title\n$_subtitle", isButton: true, hasTapAction: true),
      );
    });

    testWidgets("entry rows: one button node each, semanticsLabel replaces the text", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _tile(
          _Calls(),
          isOpen: true,
          entries: const <ChoiceOption<int>>[
            ChoiceOption<int>(value: 1, label: "Alpha", description: "First entry", trailing: "5"),
            ChoiceOption<int>(value: 2, label: "Beta", trailing: "4", semanticsLabel: "Beta, four entries"),
          ],
        ),
      );

      expect(
        tester.getSemantics(find.text("Alpha")),
        isSemantics(label: "Alpha\nFirst entry\n5", isButton: true, isEnabled: true, hasTapAction: true),
      );
      expect(
        find.bySemanticsLabel("Beta, four entries"),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel("Beta, four entries")),
        isSemantics(isButton: true, hasTapAction: true),
      );
    });

    testWidgets("a disabled entry is announced as disabled", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _tile(
          _Calls(),
          isOpen: true,
          entries: const <ChoiceOption<int>>[ChoiceOption<int>(value: 1, label: "Alpha", enabled: false)],
        ),
      );

      expect(
        tester.getSemantics(find.text("Alpha")),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false, hasTapAction: false),
      );
    });
  });

  group("layout", () {
    testWidgets("the header and every entry row are at least 48 dp tall", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _tile(
          _Calls(),
          isOpen: true,
          subtitle: null,
          icon: null,
          entries: const <ChoiceOption<int>>[ChoiceOption<int>(value: 1, label: "A"), ChoiceOption<int>(value: 2, label: "B")],
        ),
      );

      expect(tester.getSize(_inkWellOf(_title)).height, greaterThanOrEqualTo(kMinTapTarget));
      expect(tester.getSize(_inkWellOf("A")).height, greaterThanOrEqualTo(kMinTapTarget));
      expect(tester.getSize(_inkWellOf("B")).height, greaterThanOrEqualTo(kMinTapTarget));
    });

    testWidgets("long texts wrap in a narrow card without overflow", (WidgetTester tester) async {
      const String long = "A rather long piece of text that cannot fit on a single line";
      await pumpApp(
        tester,
        _tile(
          _Calls(),
          isOpen: true,
          title: long,
          subtitle: long,
          entries: const <ChoiceOption<int>>[
            ChoiceOption<int>(value: 1, label: long, description: long, trailing: "1 234 567"),
          ],
        ),
        surfaceSize: const Size(240, 2000),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group("theme tokens", () {
    for (final (String name, ThemeData theme) in <(String, ThemeData)>[
      ("light", AppTheme.light()),
      ("dark", AppTheme.dark()),
    ]) {
      testWidgets("$name: card, texts, chevrons and divider use ColorScheme tokens", (WidgetTester tester) async {
        await pumpApp(tester, _tile(_Calls(), isOpen: true), theme: theme);
        final ColorScheme cs = _scheme(tester);

        expect(tester.takeException(), isNull);
        final Card card = tester.widget<Card>(_inTile(find.byType(Card)));
        expect(card.elevation, 0);
        expect(card.color, cs.surfaceContainerLowest);
        expect(card.margin, EdgeInsets.zero);
        expect(card.clipBehavior, Clip.antiAlias);
        final RoundedRectangleBorder shape = card.shape! as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(24));
        expect(shape.side.color, cs.outlineVariant);

        expect(_textColor(tester, _title), cs.onSurface);
        expect(_textColor(tester, _subtitle), cs.onSurfaceVariant);
        expect(_textColor(tester, "Alpha"), cs.onSurface);
        expect(_textColor(tester, "First entry"), cs.onSurfaceVariant);
        expect(_textColor(tester, "5"), cs.primary);

        final Icon leading = tester.widget<Icon>(find.byIcon(Icons.folder_outlined));
        expect(leading.color, cs.primary);
        expect(leading.size, 28);
        expect(tester.widget<Icon>(find.byIcon(Icons.keyboard_arrow_down)).color, cs.primary);
        expect(tester.widget<Icon>(find.byIcon(Icons.chevron_right).first).color, cs.outline);
        expect(tester.widget<Divider>(_inTile(find.byType(Divider))).color, cs.outlineVariant);
      });
    }

    testWidgets("dark: the direct-mode chevron uses cs.primary", (WidgetTester tester) async {
      await pumpApp(tester, _tile(_Calls(), expandable: false), theme: AppTheme.dark());

      expect(tester.widget<Icon>(find.byIcon(Icons.chevron_right)).color, _scheme(tester).primary);
    });
  });
}

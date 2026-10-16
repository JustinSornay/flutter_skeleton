// collapsible_section_card_test.dart
//
// Widget tests for CollapsibleSectionCard: closed / open structure, the
// header callback with a parent owning the state, the optional icon tile,
// overline, collapsed-only subtitle and summary slot, the chevron rotation
// and cross-fade (durations, full-width body while animating or closed,
// reduced motion), header semantics, summary nodes and tap hints, the 48 dp
// target, a narrow layout and the ColorScheme tokens under
// the light and dark themes.

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/CollapsibleSectionCard/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _title = "Details";
const String _overline = "Step 1";
const String _subtitle = "Option B";
const String _bodyText = "body-content";
const String _summaryText = "summary-chip";

const Widget _body = Text(_bodyText, key: Key("body"));
const Widget _summary = Chip(label: Text(_summaryText), key: Key("summary"));

CollapsibleSectionCard _card({
  bool isOpen = false,
  VoidCallback? onToggle,
  String title = _title,
  IconData? icon = Icons.tune,
  String? overline = _overline,
  String? subtitle,
  Widget? summary,
}) {
  return CollapsibleSectionCard(
    title: title,
    isOpen: isOpen,
    onToggle: onToggle ?? () {},
    body: _body,
    icon: icon,
    overline: overline,
    subtitle: subtitle,
    summary: summary,
  );
}

Finder _inCard(Finder matching) {
  return find.descendant(of: find.byType(CollapsibleSectionCard), matching: matching);
}

/// The header InkWell (the first InkWell of the card).
Finder _header() => _inCard(find.byType(InkWell)).first;

AnimatedCrossFade _crossFade(WidgetTester tester) {
  return tester.widget<AnimatedCrossFade>(_inCard(find.byType(AnimatedCrossFade)));
}

AnimatedRotation _rotation(WidgetTester tester) {
  return tester.widget<AnimatedRotation>(_inCard(find.byType(AnimatedRotation)));
}

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(CollapsibleSectionCard))).colorScheme;
}

/// Host that owns the open state, like a real parent would.
Widget _controlledHost(List<bool> toggles) {
  bool open = false;
  return StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) => CollapsibleSectionCard(
      title: _title,
      isOpen: open,
      onToggle: () => setState(() {
        open = !open;
        toggles.add(open);
      }),
      body: _body,
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

/// Body whose count lives in its own State, lost if the body is unmounted.
final class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

final class _CounterState extends State<_Counter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: () => setState(() => _count++), child: Text("count $_count"));
  }
}

Future<void> _expectTokens(WidgetTester tester) async {
  final ColorScheme cs = _scheme(tester);
  final Card card = tester.widget<Card>(_inCard(find.byType(Card)));
  final RoundedRectangleBorder shape = card.shape! as RoundedRectangleBorder;

  expect(card.color, cs.surfaceContainerLowest);
  expect(card.elevation, 0);
  expect(card.margin, EdgeInsets.zero);
  expect(shape.borderRadius, BorderRadius.circular(24));
  expect(shape.side.color, cs.outlineVariant);
  expect(tester.widget<Text>(find.text(_title)).style?.color, cs.onSurface);
  expect(tester.widget<Text>(find.text("· $_subtitle")).style?.color, cs.primary);
  expect(tester.widget<Text>(find.text(_overline.toUpperCase())).style?.color, cs.onSurfaceVariant);
  expect(tester.widget<Icon>(find.byIcon(Icons.keyboard_arrow_down_rounded)).color, cs.onSurfaceVariant);
  expect(tester.widget<Icon>(find.byIcon(Icons.tune)).color, cs.primary);
}

void main() {
  group("open / closed", () {
    testWidgets("closed: crossFade shows the first child, body hidden from taps and semantics", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _card());

      expect(_crossFade(tester).crossFadeState, CrossFadeState.showFirst);
      expect(find.text(_bodyText).hitTestable(), findsNothing);
      expect(find.bySemanticsLabel(_bodyText), findsNothing);
      handle.dispose();
    });

    testWidgets("open: a divider then the body, both visible", (WidgetTester tester) async {
      await pumpApp(tester, _card(isOpen: true));
      await tester.pumpAndSettle();

      expect(_crossFade(tester).crossFadeState, CrossFadeState.showSecond);
      expect(find.text(_bodyText).hitTestable(), findsOneWidget);
      final Finder divider = _inCard(find.byType(Divider));
      expect(divider, findsOneWidget);
      expect(tester.widget<Divider>(divider).color, _scheme(tester).outlineVariant);
      expect(tester.getTopLeft(divider).dy, greaterThan(tester.getBottomLeft(find.text(_title)).dy));
      expect(tester.getTopLeft(divider).dy, lessThan(tester.getTopLeft(find.text(_bodyText)).dy));
    });

    testWidgets("open: the body starts at the 16 dp inset", (WidgetTester tester) async {
      await pumpApp(tester, _card(isOpen: true));
      await tester.pumpAndSettle();

      final double cardLeft = tester.getTopLeft(_inCard(find.byType(Card))).dx;
      expect(tester.getTopLeft(find.text(_bodyText)).dx - cardLeft, closeTo(kDefaultPadding * 2, 1.5));
    });

    testWidgets("a header tap calls onToggle exactly once", (WidgetTester tester) async {
      int calls = 0;
      await pumpApp(tester, _card(onToggle: () => calls++));

      await tester.tap(find.text(_title));
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets("a parent owning isOpen opens and closes the body", (WidgetTester tester) async {
      final List<bool> toggles = <bool>[];
      await pumpApp(tester, _controlledHost(toggles));

      await tester.tap(find.text(_title));
      await tester.pumpAndSettle();
      expect(find.text(_bodyText).hitTestable(), findsOneWidget);

      await tester.tap(find.text(_title));
      await tester.pumpAndSettle();
      expect(find.text(_bodyText).hitTestable(), findsNothing);
      expect(toggles, <bool>[true, false]);
    });
  });

  group("header content", () {
    testWidgets("the overline renders uppercase; none is built when null or empty", (WidgetTester tester) async {
      await pumpApp(tester, _card());
      expect(find.text(_overline.toUpperCase()), findsOneWidget);
      expect(find.text(_overline), findsNothing);

      await pumpApp(tester, _card(overline: null));
      expect(find.text(_overline.toUpperCase()), findsNothing);
      expect(_inCard(find.byType(Text)), findsNWidgets(2));

      await pumpApp(tester, _card(overline: ""));
      expect(_inCard(find.byType(Text)), findsNWidgets(2));
    });

    testWidgets("the icon tile renders only when icon is set", (WidgetTester tester) async {
      await pumpApp(tester, _card());
      final Finder icon = find.byIcon(Icons.tune);
      expect(icon, findsOneWidget);
      expect(tester.widget<Icon>(icon).size, 16);
      final Finder tile = find.ancestor(of: icon, matching: find.byType(Container)).first;
      expect(tester.getSize(tile), const Size(32, 32));
      final BoxDecoration decoration = tester.widget<Container>(tile).decoration! as BoxDecoration;
      expect(decoration.color, _scheme(tester).primary.withValues(alpha: 0.10));
      expect(decoration.borderRadius, BorderRadius.circular(10));

      await pumpApp(tester, _card(icon: null));
      expect(find.byIcon(Icons.tune), findsNothing);
      final double cardLeft = tester.getTopLeft(_inCard(find.byType(Card))).dx;
      expect(tester.getTopLeft(find.text(_title)).dx - cardLeft, closeTo(kDefaultPadding * 2, 1.5));
    });

    testWidgets("the subtitle shows as '· subtitle' only while collapsed", (WidgetTester tester) async {
      await pumpApp(tester, _card(subtitle: _subtitle));
      expect(find.text("· $_subtitle"), findsOneWidget);
      expect(
        tester.getTopLeft(find.text("· $_subtitle")).dx,
        greaterThan(tester.getTopRight(find.text(_title)).dx),
      );

      await pumpApp(tester, _card(subtitle: _subtitle, isOpen: true));
      expect(find.text("· $_subtitle"), findsNothing);
    });

    testWidgets("an empty subtitle is hidden", (WidgetTester tester) async {
      await pumpApp(tester, _card(subtitle: ""));

      expect(find.textContaining("·"), findsNothing);
    });

    testWidgets("the summary stays in the header in both states and is absent when null", (WidgetTester tester) async {
      await pumpApp(tester, _card(summary: _summary));
      expect(find.byKey(const Key("summary")).hitTestable(), findsOneWidget);
      final double chevronLeft = tester.getTopLeft(find.byIcon(Icons.keyboard_arrow_down_rounded)).dx;
      expect(tester.getTopRight(find.byKey(const Key("summary"))).dx, lessThan(chevronLeft));

      await pumpApp(tester, _card(summary: _summary, isOpen: true));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key("summary")).hitTestable(), findsOneWidget);

      await pumpApp(tester, _card());
      expect(find.byKey(const Key("summary")), findsNothing);
    });
  });

  group("motion", () {
    testWidgets("the chevron turns half a turn when open; both animations use kMotionShort", (WidgetTester tester) async {
      await pumpApp(tester, _card());
      expect(_rotation(tester).turns, 0);
      expect(_rotation(tester).duration, kMotionShort);
      expect(_rotation(tester).curve, Curves.easeInOut);
      expect(_crossFade(tester).duration, kMotionShort);
      expect(_crossFade(tester).sizeCurve, Curves.easeInOut);

      await pumpApp(tester, _card(isOpen: true));
      await tester.pumpAndSettle();
      expect(_rotation(tester).turns, 0.5);
    });

    testWidgets("the card grows progressively while opening", (WidgetTester tester) async {
      await pumpApp(tester, _controlledHost(<bool>[]));
      final double closed = tester.getSize(_inCard(find.byType(Card))).height;

      await tester.tap(find.text(_title));
      await tester.pump();
      await tester.pump(kMotionShort ~/ 2);
      final double halfway = tester.getSize(_inCard(find.byType(Card))).height;

      await tester.pumpAndSettle();
      final double open = tester.getSize(_inCard(find.byType(Card))).height;

      expect(halfway, greaterThan(closed));
      expect(halfway, lessThan(open));
    });

    testWidgets("the reveal spans the full card width and the body keeps its width while collapsing", (WidgetTester tester) async {
      await pumpApp(tester, _controlledHost(<bool>[]));
      final Finder card = _inCard(find.byType(Card));
      final Finder fade = _inCard(find.byType(AnimatedCrossFade));

      await tester.tap(find.text(_title));
      await tester.pump();
      await tester.pump(kMotionShort ~/ 2);
      expect(tester.getSize(fade).width, tester.getSize(card).width);
      expect(tester.getTopLeft(fade).dx, tester.getTopLeft(card).dx);

      await tester.pumpAndSettle();
      final Size open = tester.getSize(find.text(_bodyText));

      await tester.tap(find.text(_title));
      await tester.pump();
      await tester.pump(kMotionShort ~/ 4);
      expect(tester.getSize(find.text(_bodyText)), open);
      await tester.pumpAndSettle();
    });

    testWidgets("a closed card still gives the body the full inner width", (WidgetTester tester) async {
      final List<double> maxWidths = <double>[];
      await pumpApp(
        tester,
        CollapsibleSectionCard(
          title: _title,
          isOpen: false,
          onToggle: () {},
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              maxWidths.add(constraints.maxWidth);
              return const SizedBox(height: kDefaultPadding);
            },
          ),
        ),
      );

      final double inner = tester.getSize(_inCard(find.byType(Card))).width - kDefaultPadding * 4;
      expect(maxWidths, isNotEmpty);
      expect(maxWidths.last, inner);
    });

    testWidgets("reduced motion: zero rotation, no cross-fade, the body opens and closes at once", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _reducedMotion(_controlledHost(<bool>[])));
      final double closed = tester.getSize(_inCard(find.byType(Card))).height;

      expect(_rotation(tester).duration, Duration.zero);
      expect(_inCard(find.byType(AnimatedCrossFade)), findsNothing);
      expect(find.text(_bodyText), findsNothing);
      expect(find.bySemanticsLabel(_bodyText), findsNothing);

      await tester.tap(find.text(_title));
      await tester.pump();
      final double afterOneFrame = tester.getSize(_inCard(find.byType(Card))).height;
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(afterOneFrame, greaterThan(closed));
      expect(tester.getSize(_inCard(find.byType(Card))).height, afterOneFrame);
      expect(find.text(_bodyText).hitTestable(), findsOneWidget);

      await tester.tap(find.text(_title));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_inCard(find.byType(Card))).height, closed);
      expect(find.text(_bodyText), findsNothing);
      handle.dispose();
    });

    testWidgets("a stateful body keeps its state across close / reopen, animated or not", (WidgetTester tester) async {
      for (final bool reduced in <bool>[false, true]) {
        bool open = true;
        final Widget host = StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) => CollapsibleSectionCard(
            title: _title,
            isOpen: open,
            onToggle: () => setState(() => open = !open),
            body: const _Counter(),
          ),
        );
        await pumpApp(tester, reduced ? _reducedMotion(host) : host);

        await tester.tap(find.text("count 0"));
        await tester.pump();
        await tester.tap(find.text(_title));
        await tester.pumpAndSettle();
        await tester.tap(find.text(_title));
        await tester.pumpAndSettle();

        expect(find.text("count 1"), findsOneWidget, reason: "reduced motion: $reduced");
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });

  group("accessibility", () {
    testWidgets("header: button with expanded state, merged texts and the expand hint", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _card(subtitle: _subtitle));

      expect(
        tester.getSemantics(find.text(_title)),
        isSemantics(
          label: "$_overline\n$_title\n$_subtitle",
          isButton: true,
          hasExpandedState: true,
          isExpanded: false,
          hasTapAction: true,
          onTapHint: "custom.collapsible_section_card.expand",
        ),
      );
      handle.dispose();
    });

    testWidgets("header when open: expanded and the collapse hint", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _card(isOpen: true));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.text(_title)),
        isSemantics(
          label: "$_overline\n$_title",
          isButton: true,
          hasExpandedState: true,
          isExpanded: true,
          onTapHint: "custom.collapsible_section_card.collapse",
        ),
      );
      handle.dispose();
    });

    testWidgets("a plain-text summary joins the header label; a chip summary stays its own node", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _card(summary: const Text(_summaryText)));
      expect(tester.getSemantics(find.text(_title)), isSemantics(label: "$_overline\n$_title\n$_summaryText", isButton: true));

      await pumpApp(tester, _card(summary: _summary));
      final SemanticsNode header = tester.getSemantics(find.text(_title));
      expect(header, isSemantics(label: "$_overline\n$_title", isButton: true, hasExpandedState: true));
      final Finder chip = find.bySemanticsLabel(_summaryText);
      expect(chip, findsOneWidget);
      SemanticsNode? ancestor = tester.getSemantics(chip).parent;
      while (ancestor != null && ancestor != header) {
        ancestor = ancestor.parent;
      }
      expect(ancestor, header, reason: "the chip node sits under the header node");
      handle.dispose();
    });

    testWidgets("the header is at least kMinTapTarget tall, even with no icon or overline", (WidgetTester tester) async {
      await pumpApp(tester, _card(icon: null, overline: null));

      expect(tester.getSize(_header()).height, greaterThanOrEqualTo(kMinTapTarget));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });

  group("layout and theme", () {
    testWidgets("no overflow at 320 px with long texts and a summary chip", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _card(
          title: "A very long title that cannot fit on a narrow screen at all",
          subtitle: "an equally long inline subtitle that must ellipsize",
          overline: "A long overline label for the section",
          summary: _summary,
        ),
        surfaceSize: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_inCard(find.byType(Card))).width, lessThanOrEqualTo(320));
    });

    testWidgets("light theme: ColorScheme tokens, radius 24, no elevation", (WidgetTester tester) async {
      await pumpApp(tester, _card(subtitle: _subtitle));
      await _expectTokens(tester);
    });

    testWidgets("dark theme smoke: same tokens resolve from the dark scheme", (WidgetTester tester) async {
      await pumpApp(tester, _card(subtitle: _subtitle, summary: _summary), theme: AppTheme.dark());

      expect(tester.takeException(), isNull);
      expect(_scheme(tester).brightness, Brightness.dark);
      await _expectTokens(tester);
    });
  });
}

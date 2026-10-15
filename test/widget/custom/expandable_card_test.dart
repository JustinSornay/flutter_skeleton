// expandable_card_test.dart
//
// Widget tests for ExpandableCard: header content (title, subtitle, badge,
// one or two key values), uncontrolled expansion and its callback, taps in
// the body and preview that must not toggle, the action row (callbacks,
// disabled state, destructive placement, 48 dp targets), narrow-width layout
// of the action row and the header without overflow, intrinsic sizes, the
// preview and its skeleton, section captions, the scrolling height cap,
// reduced motion, header and caption semantics, and ColorScheme /
// StatusTones colours under the light and dark themes.

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/core/decorators/SkeletonPulse/index.dart";
import "package:flutter_skeleton/widgets/custom/ExpandableCard/index.dart";
import "package:flutter_skeleton/widgets/custom/PillBadge/index.dart";
import "package:flutter_skeleton/widgets/custom/SkeletonBlock/index.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _title = "Main title";
const String _subtitle = "Second line";
const String _badgeLabel = "Active";
const String _sectionTitle = "Details";
const String _sectionText = "section-content";
const String _previewText = "preview-content";
const String _bodyText = "free-body";

const ExpandableCardBadge _badge = ExpandableCardBadge(label: _badgeLabel, tone: StatusTone.warning);

const ExpandableCardSection _section = ExpandableCardSection(
  title: _sectionTitle,
  child: Text(_sectionText),
);

/// Neutral "Open" and "Share" actions plus a destructive "Remove" declared
/// first; each tap appends its label to [taps].
List<ExpandableCardAction> _actions(List<String> taps) {
  return <ExpandableCardAction>[
    ExpandableCardAction(
      icon: Icons.delete_outline,
      label: "Remove",
      destructive: true,
      onPressed: () => taps.add("Remove"),
    ),
    ExpandableCardAction(icon: Icons.open_in_new, label: "Open", onPressed: () => taps.add("Open")),
    ExpandableCardAction(icon: Icons.share, label: "Share", onPressed: () => taps.add("Share")),
  ];
}

/// A card with the usual content; [expanded] and [changes] cover the state.
ExpandableCard _card({
  bool expanded = false,
  List<bool>? changes,
  List<String>? taps,
  Widget? preview,
  bool previewLoading = false,
}) {
  return ExpandableCard(
    title: _title,
    subtitle: _subtitle,
    badge: _badge,
    primaryValue: "82%",
    preview: preview,
    previewLoading: previewLoading,
    actions: _actions(taps ?? <String>[]),
    sections: const <ExpandableCardSection>[_section],
    initiallyExpanded: expanded,
    onExpandedChanged: changes?.add,
  );
}

Finder _inCard(Finder matching) {
  return find.descendant(of: find.byType(ExpandableCard), matching: matching);
}

/// The header InkWell (the first InkWell of the card).
Finder _header() => _inCard(find.byType(InkWell)).first;

Finder _action(String label) => find.widgetWithText(TextButton, label);

/// An enabled action labelled [label].
ExpandableCardAction _act(String label, {bool destructive = false}) {
  return ExpandableCardAction(icon: Icons.bolt, label: label, destructive: destructive, onPressed: () {});
}

/// Pumps an expanded card holding [actions] on a [width] dp wide surface.
Future<void> _pumpActions(WidgetTester tester, List<ExpandableCardAction> actions, double width) async {
  await pumpApp(
    tester,
    ExpandableCard(title: _title, initiallyExpanded: true, actions: actions),
    surfaceSize: Size(width, 800),
  );
  await tester.pumpAndSettle();
}

/// Expects every button of [actions] within the card's 16 dp side padding on
/// a [width] dp wide surface.
void _expectActionsInside(WidgetTester tester, List<ExpandableCardAction> actions, double width) {
  for (final ExpandableCardAction action in actions) {
    final Rect rect = tester.getRect(_action(action.label));
    expect(rect.left, greaterThanOrEqualTo(kDefaultPadding * 2 - 0.5), reason: action.label);
    expect(rect.right, lessThanOrEqualTo(width - kDefaultPadding * 2 + 0.5), reason: action.label);
  }
}

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(ExpandableCard))).colorScheme;
}

Material _cardMaterial(WidgetTester tester) {
  return tester.widget<Material>(_inCard(find.byType(Material)).first);
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
  _headerTests();
  _expansionTests();
  _actionTests();
  _narrowActionTests();
  _narrowHeaderTests();
  _previewAndSectionTests();
  _motionTests();
  _semanticsTests();
  _themeTests();
}

void _headerTests() {
  group("header", () {
    testWidgets("renders the title, the subtitle and the badge in uppercase", (WidgetTester tester) async {
      await pumpApp(tester, _card());

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_subtitle), findsOneWidget);
      expect(find.text(_badgeLabel.toUpperCase()), findsOneWidget);
      final StatusPill pill = tester.widget<StatusPill>(_inCard(find.byType(StatusPill)));
      expect(pill.label, _badgeLabel.toUpperCase());
      expect(pill.semanticsLabel, _badgeLabel);
      expect(pill.tone, StatusTone.warning);
      expect(pill.dense, isTrue);
    });

    testWidgets("omits the badge, subtitle and values when absent or empty", (WidgetTester tester) async {
      await pumpApp(tester, const ExpandableCard(title: _title));
      expect(_inCard(find.byType(StatusPill)), findsNothing);
      expect(_inCard(find.byType(Text)), findsOneWidget);

      await pumpApp(
        tester,
        const ExpandableCard(
          title: _title,
          subtitle: "",
          badge: ExpandableCardBadge(label: ""),
          primaryValue: "",
        ),
      );
      expect(_inCard(find.byType(StatusPill)), findsNothing);
      expect(_inCard(find.byType(Text)), findsOneWidget);
    });

    testWidgets("one value renders at 13 sp in the primary colour", (WidgetTester tester) async {
      await pumpApp(tester, const ExpandableCard(title: _title, primaryValue: "82%"));

      final Text value = tester.widget<Text>(find.text("82%"));
      expect(value.style?.fontSize, 13);
      expect(value.style?.fontWeight, FontWeight.w800);
      expect(value.style?.color, _scheme(tester).primary);
    });

    testWidgets("two values stack, primary above secondary", (WidgetTester tester) async {
      await pumpApp(tester, const ExpandableCard(title: _title, primaryValue: "82%", secondaryValue: "75%"));

      final ColorScheme cs = _scheme(tester);
      final Text first = tester.widget<Text>(find.text("82%"));
      final Text second = tester.widget<Text>(find.text("75%"));
      expect(first.style?.fontSize, 11);
      expect(second.style?.fontSize, 11);
      expect(first.style?.color, cs.primary);
      expect(second.style?.color, cs.tertiary);
      expect(tester.getTopLeft(find.text("75%")).dy, greaterThan(tester.getTopLeft(find.text("82%")).dy));
    });

    testWidgets("a secondary value without a primary value renders nothing", (WidgetTester tester) async {
      await pumpApp(tester, const ExpandableCard(title: _title, secondaryValue: "75%"));

      expect(find.text("75%"), findsNothing);
    });

    testWidgets("the header is at least 48 dp tall", (WidgetTester tester) async {
      await pumpApp(tester, const ExpandableCard(title: _title));

      expect(tester.getSize(_header()).height, greaterThanOrEqualTo(kMinTapTarget));
    });
  });
}

void _expansionTests() {
  group("expansion", () {
    testWidgets("starts collapsed: actions and sections are not hit-testable", (WidgetTester tester) async {
      await pumpApp(tester, _card());

      expect(find.text("Open").hitTestable(), findsNothing);
      expect(find.text(_sectionText).hitTestable(), findsNothing);
      expect(_inCard(find.byIcon(Icons.keyboard_arrow_down)), findsOneWidget);
    });

    testWidgets("initiallyExpanded shows the body", (WidgetTester tester) async {
      await pumpApp(tester, _card(expanded: true));
      await tester.pumpAndSettle();

      expect(find.text("Open").hitTestable(), findsOneWidget);
      expect(find.text(_sectionText).hitTestable(), findsOneWidget);
      expect(_inCard(find.byIcon(Icons.keyboard_arrow_up)), findsOneWidget);
    });

    testWidgets("header taps expand then collapse and report each state", (WidgetTester tester) async {
      final List<bool> changes = <bool>[];
      await pumpApp(tester, _card(changes: changes));

      await tester.tap(find.text(_title));
      await tester.pumpAndSettle();
      expect(find.text(_sectionText).hitTestable(), findsOneWidget);

      await tester.tap(find.text(_title));
      await tester.pumpAndSettle();
      expect(find.text(_sectionText).hitTestable(), findsNothing);
      expect(changes, <bool>[true, false]);
    });

    testWidgets("taps inside a section or the preview do not toggle the card", (WidgetTester tester) async {
      final List<bool> changes = <bool>[];
      int inner = 0;
      await pumpApp(
        tester,
        ExpandableCard(
          title: _title,
          preview: const Text(_previewText),
          sections: <ExpandableCardSection>[
            ExpandableCardSection(child: TextButton(onPressed: () => inner++, child: const Text("inner"))),
          ],
          initiallyExpanded: true,
          onExpandedChanged: changes.add,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text("inner"));
      await tester.tap(find.text(_previewText));
      await tester.pumpAndSettle();

      expect(inner, 1);
      expect(changes, isEmpty);
      expect(find.text("inner").hitTestable(), findsOneWidget);
    });

    testWidgets("the free body slot renders after the sections", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const ExpandableCard(
          title: _title,
          sections: <ExpandableCardSection>[_section],
          body: Text(_bodyText),
          initiallyExpanded: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(_bodyText).hitTestable(), findsOneWidget);
      expect(tester.getTopLeft(find.text(_bodyText)).dy, greaterThan(tester.getTopLeft(find.text(_sectionText)).dy));
    });

    testWidgets("content taller than bodyMaxHeight scrolls inside the body", (WidgetTester tester) async {
      await pumpApp(
        tester,
        ExpandableCard(
          title: _title,
          bodyMaxHeight: 200,
          initiallyExpanded: true,
          body: Column(
            children: List<Widget>.generate(30, (int i) => SizedBox(height: 48, child: Text("row $i"))),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_inCard(find.byType(SingleChildScrollView)), findsOneWidget);
      expect(tester.getSize(find.byType(ExpandableCard)).height, lessThan(200 + 120));
      expect(find.text("row 29").hitTestable(), findsNothing);

      await tester.drag(_inCard(find.byType(SingleChildScrollView)), const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(find.text("row 29").hitTestable(), findsOneWidget);
    });
  });
}

void _actionTests() {
  group("actions", () {
    testWidgets("a tap calls the action's onPressed", (WidgetTester tester) async {
      final List<String> taps = <String>[];
      await pumpApp(tester, _card(expanded: true, taps: taps));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Share"));
      await tester.tap(find.text("Remove"));
      await tester.pump();

      expect(taps, <String>["Share", "Remove"]);
    });

    testWidgets("an action without onPressed is disabled", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<bool> changes = <bool>[];
      await pumpApp(
        tester,
        ExpandableCard(
          title: _title,
          initiallyExpanded: true,
          onExpandedChanged: changes.add,
          actions: const <ExpandableCardAction>[ExpandableCardAction(icon: Icons.edit, label: "Edit")],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.widget<TextButton>(_action("Edit")).enabled, isFalse);
      expect(
        tester.getSemantics(_action("Edit")),
        isSemantics(label: "Edit", isButton: true, hasEnabledState: true, isEnabled: false),
      );
      await tester.tap(find.text("Edit"), warnIfMissed: false);
      await tester.pump();
      expect(changes, isEmpty);
      handle.dispose();
    });

    testWidgets("destructive actions sit after the neutral ones, at the trailing edge", (WidgetTester tester) async {
      await pumpApp(tester, _card(expanded: true));
      await tester.pumpAndSettle();

      final double removeLeft = tester.getTopLeft(_action("Remove")).dx;
      expect(removeLeft, greaterThan(tester.getTopRight(_action("Open")).dx));
      expect(removeLeft, greaterThan(tester.getTopRight(_action("Share")).dx));
      expect(tester.getTopLeft(_action("Open")).dx, lessThan(tester.getTopLeft(_action("Share")).dx));
      final double cardRight = tester.getTopRight(find.byType(ExpandableCard)).dx;
      expect(cardRight - tester.getTopRight(_action("Remove")).dx, closeTo(kDefaultPadding * 2, 1));
    });

    testWidgets("every action has a 48 x 48 tap target", (WidgetTester tester) async {
      await pumpApp(tester, _card(expanded: true));
      await tester.pumpAndSettle();

      for (final String label in <String>["Open", "Share", "Remove"]) {
        final Size size = tester.getSize(_action(label));
        expect(size.height, greaterThanOrEqualTo(kMinTapTarget), reason: label);
        expect(size.width, greaterThanOrEqualTo(kMinTapTarget), reason: label);
      }
    });

    testWidgets("neutral and destructive actions use their tokens", (WidgetTester tester) async {
      await pumpApp(tester, _card(expanded: true));
      await tester.pumpAndSettle();

      final ColorScheme cs = _scheme(tester);
      final ButtonStyle neutral = tester.widget<TextButton>(_action("Open")).style!;
      final ButtonStyle destructive = tester.widget<TextButton>(_action("Remove")).style!;
      expect(neutral.backgroundColor?.resolve(<WidgetState>{}), cs.surfaceContainerLowest);
      expect(neutral.foregroundColor?.resolve(<WidgetState>{}), cs.onSurfaceVariant);
      expect(destructive.backgroundColor?.resolve(<WidgetState>{}), cs.error);
      expect(destructive.foregroundColor?.resolve(<WidgetState>{}), cs.onError);
    });
  });
}

void _narrowActionTests() {
  group("narrow action row", () {
    testWidgets("two destructive actions, one long, stay inside a 320 dp card", (WidgetTester tester) async {
      final List<ExpandableCardAction> actions = <ExpandableCardAction>[
        _act("Open"),
        _act("Archive", destructive: true),
        _act("Delete permanently", destructive: true),
      ];
      await _pumpActions(tester, actions, 320);

      expect(tester.takeException(), isNull);
      _expectActionsInside(tester, actions, 320);
      expect(tester.getTopLeft(_action("Archive")).dy, greaterThan(tester.getTopLeft(_action("Open")).dy));
    });

    testWidgets("four short destructive actions stay inside a 360 dp card", (WidgetTester tester) async {
      final List<ExpandableCardAction> actions = <ExpandableCardAction>[
        _act("Open"),
        for (final String label in <String>["Remove", "Archive", "Block", "Discard"]) _act(label, destructive: true),
      ];
      await _pumpActions(tester, actions, 360);

      expect(tester.takeException(), isNull);
      _expectActionsInside(tester, actions, 360);
    });

    testWidgets("a destructive group that does not fit beside the neutral one starts its own line", (WidgetTester tester) async {
      final List<ExpandableCardAction> actions = <ExpandableCardAction>[
        _act("Remove", destructive: true),
        for (final String label in <String>["Open", "Share", "Print", "Rename"]) _act(label),
      ];
      await _pumpActions(tester, actions, 320);

      expect(tester.takeException(), isNull);
      _expectActionsInside(tester, actions, 320);
      final double neutralBottom = tester.getBottomLeft(_action("Rename")).dy;
      expect(tester.getTopLeft(_action("Remove")).dy, greaterThanOrEqualTo(neutralBottom));
      expect(tester.getTopLeft(_action("Remove")).dx, closeTo(kDefaultPadding * 2, 0.5));
    });

    testWidgets("destructive actions alone wrap from the trailing edge", (WidgetTester tester) async {
      final List<ExpandableCardAction> actions = <ExpandableCardAction>[
        for (final String label in <String>["Archive", "Delete permanently", "Purge"]) _act(label, destructive: true),
      ];
      await _pumpActions(tester, actions, 320);

      expect(tester.takeException(), isNull);
      for (final ExpandableCardAction action in actions) {
        expect(tester.getTopRight(_action(action.label)).dx, closeTo(320 - kDefaultPadding * 2, 0.5), reason: action.label);
      }
      expect(tester.getTopLeft(_action("Purge")).dy, greaterThan(tester.getTopLeft(_action("Archive")).dy));
    });
  });
}

void _narrowHeaderTests() {
  group("narrow header", () {
    testWidgets("a badge that fits stays on the title line, flush with the text column end", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const ExpandableCard(
          title: _title,
          badge: ExpandableCardBadge(label: "Pending review", tone: StatusTone.warning),
          primaryValue: "82%",
        ),
      );

      final Rect pill = tester.getRect(_inCard(find.byType(StatusPill)));
      expect(pill.center.dy, closeTo(tester.getCenter(find.text(_title)).dy, 1));
      expect(tester.getTopLeft(find.text("82%")).dx - pill.right, closeTo(kDefaultPadding, 0.5));
      expect(find.text("PENDING REVIEW"), findsOneWidget);
    });

    testWidgets("a long badge drops under the title and stays inside a 320 dp card", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const ExpandableCard(
          title: "Title",
          badge: ExpandableCardBadge(label: "Awaiting second approval", tone: StatusTone.warning),
          primaryValue: "82%",
          secondaryValue: "75%",
        ),
        surfaceSize: const Size(320, 800),
      );

      expect(tester.takeException(), isNull);
      final Rect pill = tester.getRect(_inCard(find.byType(StatusPill)));
      expect(pill.top, greaterThanOrEqualTo(tester.getBottomLeft(find.text("Title")).dy));
      expect(pill.left, closeTo(kDefaultPadding * 2, 0.5));
      expect(pill.right, lessThanOrEqualTo(tester.getTopLeft(find.text("82%")).dx - kDefaultPadding + 0.5));
    });

    testWidgets("long title, badge and values stay inside a 260 dp card", (WidgetTester tester) async {
      const String longValue = "1 234 567,89 units";
      await pumpApp(
        tester,
        const ExpandableCard(
          title: "A rather long heading that needs more than one line",
          subtitle: _subtitle,
          badge: ExpandableCardBadge(label: "Awaiting second approval", tone: StatusTone.warning),
          primaryValue: longValue,
          secondaryValue: "987 654,32 units",
        ),
        surfaceSize: const Size(260, 800),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.text(longValue)).width, lessThanOrEqualTo(kDefaultPadding * 10));
      expect(tester.getTopRight(_inCard(find.byType(StatusPill))).dx, lessThanOrEqualTo(tester.getTopLeft(find.text(longValue)).dx));
    });

    testWidgets("an expanded card with both action groups reports intrinsic sizes", (WidgetTester tester) async {
      await pumpApp(tester, Center(child: IntrinsicWidth(child: IntrinsicHeight(child: _card(expanded: true)))));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text("Remove").hitTestable(), findsOneWidget);
    });
  });
}

void _previewAndSectionTests() {
  group("preview and sections", () {
    testWidgets("previewLoading shows a pulsing skeleton bar instead of the preview", (WidgetTester tester) async {
      await pumpApp(tester, _card(preview: const Text(_previewText), previewLoading: true));
      await tester.pump(const Duration(milliseconds: 750));

      expect(_inCard(find.byType(SkeletonPulse)), findsOneWidget);
      expect(tester.widget<SkeletonBlock>(_inCard(find.byType(SkeletonBlock))).height, kDefaultPadding * 3);
      expect(find.text(_previewText), findsNothing);
    });

    testWidgets("the preview is visible collapsed and expanded", (WidgetTester tester) async {
      await pumpApp(tester, _card(preview: const Text(_previewText)));
      expect(find.text(_previewText).hitTestable(), findsOneWidget);

      await tester.tap(find.text(_title));
      await tester.pumpAndSettle();
      expect(find.text(_previewText).hitTestable(), findsOneWidget);
      expect(_inCard(find.byType(SkeletonPulse)), findsNothing);
    });

    testWidgets("a section title renders as an uppercase caption", (WidgetTester tester) async {
      await pumpApp(tester, _card(expanded: true));
      await tester.pumpAndSettle();

      final Text caption = tester.widget<Text>(find.text(_sectionTitle.toUpperCase()));
      expect(caption.semanticsLabel, _sectionTitle);
      expect(caption.style?.color, _scheme(tester).onSurfaceVariant);
      expect(tester.getTopLeft(find.text(_sectionText)).dy, greaterThan(tester.getTopLeft(find.text(_sectionTitle.toUpperCase())).dy));
    });

    testWidgets("a section without a title renders only its child", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const ExpandableCard(
          title: _title,
          initiallyExpanded: true,
          sections: <ExpandableCardSection>[
            ExpandableCardSection(child: Text(_sectionText)),
            ExpandableCardSection(title: "", child: Text("second")),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(_sectionText).hitTestable(), findsOneWidget);
      expect(find.text("second").hitTestable(), findsOneWidget);
      expect(_inCard(find.byType(Text)), findsNWidgets(3));
    });
  });
}

void _motionTests() {
  group("motion", () {
    testWidgets("the body animates through AnimatedSize and AnimatedCrossFade", (WidgetTester tester) async {
      await pumpApp(tester, _card());

      // The first AnimatedSize is the outer one; AnimatedCrossFade holds its own.
      expect(tester.widget<AnimatedSize>(_inCard(find.byType(AnimatedSize)).first).duration, const Duration(milliseconds: 220));
      final AnimatedCrossFade fade = tester.widget<AnimatedCrossFade>(_inCard(find.byType(AnimatedCrossFade)));
      expect(fade.duration, const Duration(milliseconds: 180));
      expect(fade.crossFadeState, CrossFadeState.showFirst);
    });

    testWidgets("reduced motion shows and hides the body at once", (WidgetTester tester) async {
      await pumpApp(tester, _reducedMotion(_card()));

      expect(_inCard(find.byType(AnimatedSize)), findsNothing);
      expect(_inCard(find.byType(AnimatedCrossFade)), findsNothing);
      expect(find.text(_sectionText), findsNothing);

      await tester.tap(find.text(_title));
      await tester.pump();
      expect(find.text(_sectionText).hitTestable(), findsOneWidget);
      expect(_cardMaterial(tester).animationDuration, Duration.zero);

      await tester.tap(find.text(_title));
      await tester.pump();
      expect(find.text(_sectionText), findsNothing);
    });
  });
}

void _semanticsTests() {
  group("semantics", () {
    testWidgets("the header is one button node with an expanded state and a hint", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const ExpandableCard(
          title: _title,
          subtitle: _subtitle,
          badge: _badge,
          primaryValue: "82%",
          secondaryValue: "75%",
        ),
      );

      expect(
        tester.getSemantics(_header()),
        isSemantics(
          label: _title,
          value: "$_subtitle, $_badgeLabel, 82%, 75%",
          hint: "custom.expandable_card.expand",
          isButton: true,
          hasExpandedState: true,
          isExpanded: false,
          hasTapAction: true,
        ),
      );

      await tester.tap(find.text(_title));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(_header()),
        isSemantics(hint: "custom.expandable_card.collapse", isExpanded: true),
      );
      handle.dispose();
    });

    testWidgets("the hidden body is out of the semantics tree; captions are headers", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _card());
      expect(find.bySemanticsLabel(_sectionTitle), findsNothing);
      expect(find.bySemanticsLabel("Open"), findsNothing);

      await tester.tap(find.text(_title));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(find.bySemanticsLabel(_sectionTitle)), isSemantics(isHeader: true));
      expect(find.bySemanticsLabel("Open"), findsOneWidget);
      handle.dispose();
    });
  });
}

void _themeTests() {
  group("theme", () {
    testWidgets("the card follows the ColorScheme in both states", (WidgetTester tester) async {
      await pumpApp(tester, _card());
      final ColorScheme cs = _scheme(tester);

      Material material = _cardMaterial(tester);
      RoundedRectangleBorder shape = material.shape! as RoundedRectangleBorder;
      expect(material.color, cs.surfaceContainerLowest);
      expect(shape.side.color, cs.outlineVariant);
      expect(shape.borderRadius, BorderRadius.circular(10));
      expect(tester.widget<Text>(find.text(_title)).style?.color, cs.onSurface);
      expect(tester.widget<Text>(find.text(_subtitle)).style?.color, cs.onSurfaceVariant);

      await tester.tap(find.text(_title));
      await tester.pumpAndSettle();
      material = _cardMaterial(tester);
      shape = material.shape! as RoundedRectangleBorder;
      expect(material.color, cs.surfaceContainerLow);
      expect(shape.side.color, cs.tertiaryContainer);
      expect(tester.widget<Icon>(_inCard(find.byIcon(Icons.keyboard_arrow_up))).color, cs.onTertiary);
    });

    testWidgets("badge colours come from StatusTones for every tone", (WidgetTester tester) async {
      for (final StatusTone tone in StatusTone.values) {
        await pumpApp(tester, ExpandableCard(title: _title, badge: ExpandableCardBadge(label: tone.name, tone: tone)));
        final ToneColors colors = StatusTones.colorsOf(tester.element(find.byType(ExpandableCard)), tone);
        final PillBadge pill = tester.widget<PillBadge>(_inCard(find.byType(PillBadge)));
        expect(pill.backgroundColor, colors.container, reason: tone.name);
        expect(pill.color, colors.onContainer, reason: tone.name);
      }
    });

    testWidgets("renders under AppTheme.dark() without exceptions", (WidgetTester tester) async {
      await pumpApp(tester, _card(expanded: true, previewLoading: true), theme: AppTheme.dark());
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      final ColorScheme cs = _scheme(tester);
      expect(cs.brightness, Brightness.dark);
      expect(_cardMaterial(tester).color, cs.surfaceContainerLow);
      expect(find.text("Open").hitTestable(), findsOneWidget);
    });
  });
}

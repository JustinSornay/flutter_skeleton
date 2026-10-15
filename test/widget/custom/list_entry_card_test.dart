// list_entry_card_test.dart
//
// Widget tests for ListEntryCard: titles (empty subtitle hidden without a
// gap), the composed StatusPill (tone pass-through, hidden when empty), the
// body slot, tap / chevron / ink rules, the 48 dp minimum height, merged
// semantics (default label, override, hint, button flag), no overflow at
// 300 dp, ColorScheme colours, and the dark theme for every tone.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/ListEntryCard/index.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _title = "Item alpha";
const String _subtitle = "Group B";
const String _badge = "Ready";
const String _hintKey = "custom.list_entry_card.open_hint";
const Key _bodyKey = Key("body");

/// Pumps [card] in a 300 dp wide column (the narrowest supported list width).
Future<void> _pump(WidgetTester tester, Widget card, {ThemeData? theme}) {
  return pumpApp(
    tester,
    Align(alignment: Alignment.topLeft, child: SizedBox(width: 300, child: card)),
    theme: theme,
  );
}

Finder _inCard(Finder matching) {
  return find.descendant(of: find.byType(ListEntryCard), matching: matching);
}

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(ListEntryCard))).colorScheme;

Text _text(WidgetTester tester, String text) => tester.widget<Text>(find.text(text));

void main() {
  group("titles", () {
    testWidgets("shows the title and the subtitle", (WidgetTester tester) async {
      await _pump(tester, const ListEntryCard(title: _title, subtitle: _subtitle));

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_subtitle), findsOneWidget);
      expect(tester.getTopLeft(find.text(_subtitle)).dy, greaterThan(tester.getBottomLeft(find.text(_title)).dy));
    });

    testWidgets("a null or empty subtitle is hidden and leaves no gap", (WidgetTester tester) async {
      await _pump(tester, const ListEntryCard(title: _title));
      final double heightWithoutSubtitle = tester.getSize(find.byType(ListEntryCard)).height;
      expect(_inCard(find.byType(Text)), findsOneWidget);

      await _pump(tester, const ListEntryCard(title: _title, subtitle: ""));
      expect(_inCard(find.byType(Text)), findsOneWidget);
      expect(tester.getSize(find.byType(ListEntryCard)).height, heightWithoutSubtitle);
    });

    testWidgets("title uses onSurface, subtitle onSurfaceVariant", (WidgetTester tester) async {
      await _pump(tester, const ListEntryCard(title: _title, subtitle: _subtitle));
      final ColorScheme cs = _scheme(tester);

      expect(_text(tester, _title).style?.color, cs.onSurface);
      expect(_text(tester, _title).style?.fontWeight, FontWeight.w700);
      expect(_text(tester, _subtitle).style?.color, cs.onSurfaceVariant);
    });
  });

  group("badge", () {
    testWidgets("composes a dense StatusPill with the label and tone", (WidgetTester tester) async {
      await _pump(
        tester,
        const ListEntryCard(title: _title, badgeLabel: _badge, badgeTone: StatusTone.success),
      );

      final StatusPill pill = tester.widget<StatusPill>(_inCard(find.byType(StatusPill)));
      expect(pill.label, _badge);
      expect(pill.tone, StatusTone.success);
      expect(pill.dense, isTrue);
      expect(find.text(_badge), findsOneWidget);
    });

    testWidgets("is absent when the label is null or empty", (WidgetTester tester) async {
      await _pump(tester, const ListEntryCard(title: _title));
      expect(_inCard(find.byType(StatusPill)), findsNothing);

      await _pump(tester, const ListEntryCard(title: _title, badgeLabel: ""));
      expect(_inCard(find.byType(StatusPill)), findsNothing);
    });

    testWidgets("every tone renders at 300 dp in its onContainer colour", (WidgetTester tester) async {
      for (final StatusTone tone in StatusTone.values) {
        await _pump(tester, ListEntryCard(title: _title, badgeLabel: _badge, badgeTone: tone, onTap: () {}));
        final ToneColors colors = StatusTones.colorsOf(tester.element(find.byType(ListEntryCard)), tone);

        expect(tester.takeException(), isNull, reason: "$tone");
        expect(_text(tester, _badge).style?.color, colors.onContainer, reason: "$tone");
      }
    });

    testWidgets("sits at the trailing edge, before the chevron", (WidgetTester tester) async {
      await _pump(tester, ListEntryCard(title: _title, badgeLabel: _badge, onTap: () {}));

      final double pillRight = tester.getTopRight(_inCard(find.byType(StatusPill))).dx;
      final double chevronLeft = tester.getTopLeft(find.byIcon(Icons.chevron_right)).dx;
      expect(chevronLeft - pillRight, kDefaultPadding / 2);
      expect(tester.getTopRight(find.byIcon(Icons.chevron_right)).dx, 300 - kDefaultPadding / 2);
    });
  });

  group("body", () {
    testWidgets("renders 12 dp under the header at full inner width", (WidgetTester tester) async {
      await _pump(
        tester,
        const ListEntryCard(title: _title, body: SizedBox(key: _bodyKey, height: 20)),
      );

      expect(find.byKey(_bodyKey), findsOneWidget);
      final double titleBottom = tester.getBottomLeft(find.text(_title)).dy;
      expect(tester.getTopLeft(find.byKey(_bodyKey)).dy - titleBottom, closeTo(kDefaultPadding * 1.5, 0.01));
      expect(tester.getSize(find.byKey(_bodyKey)).width, 300 - kDefaultPadding);
    });

    testWidgets("is omitted when null", (WidgetTester tester) async {
      await _pump(tester, const ListEntryCard(title: _title));

      expect(find.byKey(_bodyKey), findsNothing);
    });
  });

  group("interaction", () {
    testWidgets("a tap anywhere calls onTap once; ink and chevron are shown", (WidgetTester tester) async {
      int taps = 0;
      await _pump(
        tester,
        ListEntryCard(
          title: _title,
          body: const Text("Body", key: _bodyKey),
          onTap: () => taps++,
        ),
      );

      expect(_inCard(find.byType(InkWell)), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.tap(find.byKey(_bodyKey));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets("owns a transparent Material so the ink shows on any surface", (WidgetTester tester) async {
      await _pump(tester, ListEntryCard(title: _title, onTap: () {}));

      final Material material = tester.widget<Material>(
        find.ancestor(of: find.byType(InkWell), matching: find.byType(Material)).first,
      );
      expect(material.type, MaterialType.transparency);
    });

    testWidgets("without onTap: no ink, no chevron, a tap is harmless", (WidgetTester tester) async {
      await _pump(tester, const ListEntryCard(title: _title));

      expect(_inCard(find.byType(InkWell)), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);

      await tester.tap(find.byType(ListEntryCard), warnIfMissed: false);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets("showChevron false hides the chevron but keeps the tap", (WidgetTester tester) async {
      int taps = 0;
      await _pump(tester, ListEntryCard(title: _title, showChevron: false, onTap: () => taps++));

      expect(find.byIcon(Icons.chevron_right), findsNothing);
      await tester.tap(find.byType(ListEntryCard));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets("chevron uses onSurfaceVariant at 18 dp", (WidgetTester tester) async {
      await _pump(tester, ListEntryCard(title: _title, onTap: () {}));

      final Icon chevron = tester.widget<Icon>(find.byIcon(Icons.chevron_right));
      expect(chevron.color, _scheme(tester).onSurfaceVariant);
      expect(chevron.size, 18);
    });

    testWidgets("is at least kMinTapTarget tall", (WidgetTester tester) async {
      await _pump(tester, ListEntryCard(title: "A", onTap: () {}));

      expect(tester.getSize(find.byType(ListEntryCard)).height, greaterThanOrEqualTo(kMinTapTarget));
    });
  });

  group("semantics", () {
    testWidgets("one button node: title, subtitle and badge, with the hint", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(
        tester,
        ListEntryCard(title: _title, subtitle: _subtitle, badgeLabel: _badge, onTap: () {}),
      );

      expect(
        tester.getSemantics(find.byType(ListEntryCard)),
        isSemantics(
          label: "$_title, $_subtitle, $_badge",
          hint: _hintKey,
          isButton: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets("without onTap the node is not a button and has no hint", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, const ListEntryCard(title: _title, subtitle: ""));

      expect(
        tester.getSemantics(find.byType(ListEntryCard)),
        isSemantics(label: _title, hint: "", isButton: false, hasTapAction: false),
      );
      handle.dispose();
    });

    testWidgets("semanticsLabel replaces the default label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(
        tester,
        ListEntryCard(title: _title, badgeLabel: _badge, semanticsLabel: "Custom label", onTap: () {}),
      );

      expect(tester.getSemantics(find.byType(ListEntryCard)).label, "Custom label");
      handle.dispose();
    });

    testWidgets("the body's semantics are appended to the card node", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(
        tester,
        ListEntryCard(
          title: _title,
          body: Semantics(label: "Range 10 to 40", child: const SizedBox(height: 20)),
          onTap: () {},
        ),
      );

      expect(tester.getSemantics(find.byType(ListEntryCard)).label, "$_title\nRange 10 to 40");
      handle.dispose();
    });
  });

  group("layout", () {
    testWidgets("long title, subtitle and badge wrap or ellipsize at 300 dp", (WidgetTester tester) async {
      await _pump(
        tester,
        ListEntryCard(
          title: "An item name long enough to wrap over several lines in a narrow list column",
          subtitle: "A secondary line that is also much longer than the space left beside the pill",
          badgeLabel: "A status label far too long for the pill",
          badgeTone: StatusTone.warning,
          body: const SizedBox(key: _bodyKey, height: 20),
          onTap: () {},
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_inCard(find.byType(StatusPill))).width, lessThanOrEqualTo(kDefaultPadding * 15));
    });
  });

  group("dark theme", () {
    testWidgets("renders every tone without error", (WidgetTester tester) async {
      for (final StatusTone tone in StatusTone.values) {
        await _pump(
          tester,
          ListEntryCard(
            title: _title,
            subtitle: _subtitle,
            badgeLabel: _badge,
            badgeTone: tone,
            onTap: () {},
          ),
          theme: AppTheme.dark(),
        );
        final ColorScheme cs = _scheme(tester);

        expect(tester.takeException(), isNull, reason: "$tone");
        expect(cs.brightness, Brightness.dark);
        expect(_text(tester, _title).style?.color, cs.onSurface);
      }
    });
  });
}

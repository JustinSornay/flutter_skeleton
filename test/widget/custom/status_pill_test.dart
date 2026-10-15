// status_pill_test.dart
//
// Widget tests for StatusPill: the pill composed from PillBadge with the tone
// container / onContainer colours, icon and dense pass-through, the compact
// 24 dp circle (measured letter width, 1–2 character assert), the empty-label
// shrink in both variants, single-node semantics, a narrow parent, and the
// dark theme for every tone.

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/PillBadge/index.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _label = "Pending";
const String _letter = "P";

/// A runtime (non-const) empty string, so the compact assert runs at runtime
/// instead of failing const evaluation at compile time.
String _emptyLetter() => _letter.substring(1);

Finder _inPill(Finder matching) {
  return find.descendant(of: find.byType(StatusPill), matching: matching);
}

PillBadge _badge(WidgetTester tester) => tester.widget<PillBadge>(_inPill(find.byType(PillBadge)));

/// The PillBadge Container (pill variant).
Container _container(WidgetTester tester) => tester.widget<Container>(_inPill(find.byType(Container)));

/// The circle decoration (compact variant).
BoxDecoration _circle(WidgetTester tester) {
  return tester.widget<DecoratedBox>(_inPill(find.byType(DecoratedBox))).decoration as BoxDecoration;
}

Text _text(WidgetTester tester, String text) => tester.widget<Text>(find.text(text));

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(StatusPill))).colorScheme;

ToneColors _tone(WidgetTester tester, StatusTone tone) {
  return StatusTones.colorsOf(tester.element(find.byType(StatusPill)), tone);
}

void main() {
  group("pill", () {
    testWidgets("composes a PillBadge showing the label, no icon by default", (WidgetTester tester) async {
      await pumpApp(tester, const StatusPill(label: _label));

      expect(_inPill(find.byType(PillBadge)), findsOneWidget);
      expect(find.text(_label), findsOneWidget);
      expect(_inPill(find.byType(Icon)), findsNothing);
      expect(_badge(tester).dense, isFalse);
    });

    testWidgets("default tone is neutral: onSurface on surfaceContainerHighest", (WidgetTester tester) async {
      await pumpApp(tester, const StatusPill(label: _label));
      final ColorScheme cs = _scheme(tester);

      expect(_badge(tester).tone, StatusTone.neutral);
      expect((_container(tester).decoration! as BoxDecoration).color, cs.surfaceContainerHighest);
      expect(_text(tester, _label).style?.color, cs.onSurface);
    });

    testWidgets("danger uses the error container roles", (WidgetTester tester) async {
      await pumpApp(tester, const StatusPill(label: _label, tone: StatusTone.danger));
      final ColorScheme cs = _scheme(tester);

      expect((_container(tester).decoration! as BoxDecoration).color, cs.errorContainer);
      expect(_text(tester, _label).style?.color, cs.onErrorContainer);
    });

    testWidgets("every tone paints onContainer on container", (WidgetTester tester) async {
      for (final StatusTone tone in StatusTone.values) {
        await pumpApp(tester, StatusPill(label: _label, tone: tone));
        final ToneColors colors = _tone(tester, tone);

        expect(_badge(tester).backgroundColor, colors.container, reason: "$tone");
        expect(_badge(tester).color, colors.onContainer, reason: "$tone");
        expect((_container(tester).decoration! as BoxDecoration).color, colors.container, reason: "$tone");
        expect(_text(tester, _label).style?.color, colors.onContainer, reason: "$tone");
      }
    });

    testWidgets("fully rounded, label 11 sp / w700", (WidgetTester tester) async {
      await pumpApp(tester, const StatusPill(label: _label));

      final BoxDecoration decoration = _container(tester).decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(999));
      expect(_text(tester, _label).style?.fontSize, 11);
      expect(_text(tester, _label).style?.fontWeight, FontWeight.w700);
    });

    testWidgets("icon renders before the label in the text colour", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const StatusPill(label: "Ready · Q3", icon: Icons.arrow_forward_rounded, tone: StatusTone.success),
      );

      final Icon icon = tester.widget<Icon>(find.byIcon(Icons.arrow_forward_rounded));
      expect(icon.color, _tone(tester, StatusTone.success).onContainer);
      expect(
        tester.getTopLeft(find.byIcon(Icons.arrow_forward_rounded)).dx,
        lessThan(tester.getTopLeft(find.text("Ready · Q3")).dx),
      );
    });

    testWidgets("dense is passed to PillBadge (8 / 4 dp padding)", (WidgetTester tester) async {
      await pumpApp(tester, const StatusPill(label: _label, dense: true));

      expect(_badge(tester).dense, isTrue);
      expect(_container(tester).padding, const EdgeInsets.symmetric(horizontal: 8, vertical: 4));
    });

    testWidgets("a long label ellipsizes in a narrow parent", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 80, child: StatusPill(label: "Waiting for a second review")),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(StatusPill)).width, lessThanOrEqualTo(80));
      expect(_text(tester, "Waiting for a second review").overflow, TextOverflow.ellipsis);
    });
  });

  group("compact", () {
    testWidgets("is a 24 dp circle showing the letter, not the label", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: StatusPill.compact(letter: _letter, label: _label)));

      expect(tester.getSize(find.byType(StatusPill)), const Size(24, 24));
      expect(find.text(_letter), findsOneWidget);
      expect(find.text(_label), findsNothing);
      expect(_inPill(find.byType(PillBadge)), findsNothing);
      expect(_circle(tester).shape, BoxShape.circle);
    });

    testWidgets("a two-character code fits on one line inside the circle", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: StatusPill.compact(letter: "--", label: "No data")));

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(StatusPill)), const Size(24, 24));
      expect(_text(tester, "--").maxLines, 1);
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(find.text("--"));
      expect(paragraph.getMaxIntrinsicWidth(double.infinity), lessThanOrEqualTo(24));
    });

    test("an empty letter is rejected (no colour-only circle)", () {
      expect(() => StatusPill.compact(letter: _emptyLetter(), label: _label), throwsAssertionError);
    });

    test("a letter longer than two characters is rejected (no silent clipping)", () {
      expect(() => StatusPill.compact(letter: "${_letter}BC", label: _label), throwsAssertionError);
    });

    testWidgets("every tone paints onContainer on container, letter 11 sp / w700", (WidgetTester tester) async {
      for (final StatusTone tone in StatusTone.values) {
        await pumpApp(tester, Center(child: StatusPill.compact(letter: _letter, label: _label, tone: tone)));
        final ToneColors colors = _tone(tester, tone);

        expect(_circle(tester).color, colors.container, reason: "$tone");
        expect(_text(tester, _letter).style?.color, colors.onContainer, reason: "$tone");
        expect(_text(tester, _letter).style?.fontSize, 11, reason: "$tone");
        expect(_text(tester, _letter).style?.fontWeight, FontWeight.w700, reason: "$tone");
      }
    });

    testWidgets("default tone is neutral", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: StatusPill.compact(letter: _letter, label: _label)));

      expect(tester.widget<StatusPill>(find.byType(StatusPill)).tone, StatusTone.neutral);
      expect(_circle(tester).color, _scheme(tester).surfaceContainerHighest);
    });
  });

  group("empty label", () {
    testWidgets("the pill renders SizedBox.shrink", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: StatusPill(label: "", icon: Icons.check)));

      expect(tester.getSize(find.byType(StatusPill)), Size.zero);
      expect(_inPill(find.byType(PillBadge)), findsNothing);
      expect(_inPill(find.byType(Text)), findsNothing);
      expect(_inPill(find.byType(Icon)), findsNothing);
    });

    testWidgets("the compact circle renders SizedBox.shrink", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: StatusPill.compact(letter: _letter, label: "")));

      expect(tester.getSize(find.byType(StatusPill)), Size.zero);
      expect(find.text(_letter), findsNothing);
    });
  });

  group("semantics", () {
    testWidgets("the pill label is announced once", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const StatusPill(label: _label, icon: Icons.check));

      expect(find.bySemanticsLabel(_label), findsOneWidget);
      handle.dispose();
    });

    testWidgets("semanticsLabel replaces the pill label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const StatusPill(label: _label, semanticsLabel: "State: pending"));

      expect(find.bySemanticsLabel("State: pending"), findsOneWidget);
      expect(find.bySemanticsLabel(_label), findsNothing);
      handle.dispose();
    });

    testWidgets("the compact circle announces the label, not the letter", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const Center(child: StatusPill.compact(letter: _letter, label: _label)));

      expect(find.bySemanticsLabel(_label), findsOneWidget);
      expect(find.bySemanticsLabel(_letter), findsNothing);
      handle.dispose();
    });
  });

  group("dark theme", () {
    testWidgets("every tone renders in both variants with the dark tone colours", (WidgetTester tester) async {
      for (final StatusTone tone in StatusTone.values) {
        await pumpApp(
          tester,
          Column(
            children: <Widget>[
              StatusPill(label: _label, tone: tone, icon: tone.icon),
              StatusPill.compact(letter: _letter, label: "Compact", tone: tone),
            ],
          ),
          theme: AppTheme.dark(),
        );
        final BuildContext context = tester.element(find.byType(Column).first);
        final ToneColors colors = StatusTones.colorsOf(context, tone);

        expect(Theme.of(context).colorScheme.brightness, Brightness.dark);
        expect(tester.takeException(), isNull, reason: "$tone");
        expect(_text(tester, _label).style?.color, colors.onContainer, reason: "$tone");
        expect(_text(tester, _letter).style?.color, colors.onContainer, reason: "$tone");
      }
    });
  });
}

// section_block_test.dart
//
// Widget tests for SectionBlock: badge / title / caption / child rendering,
// the optional caption, header layout and 8 dp-grid gaps, ColorScheme tokens,
// the single header semantics node, robustness under long text and large
// text scales (the badge grows, never clips, and short labels stay round),
// the non-empty index label contract, and the dark theme.

import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/SectionBlock/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const SectionBlock _block = SectionBlock(
  indexLabel: "1",
  title: "Title",
  caption: "Caption",
  child: Text("Body"),
);

Finder _inBlock(Finder matching) {
  return find.descendant(of: find.byType(SectionBlock), matching: matching);
}

/// The badge's decorated box: the closest DecoratedBox above the index label.
Finder _badge(String label) {
  return find.ancestor(of: find.text(label), matching: find.byType(DecoratedBox)).first;
}

ShapeDecoration _badgeDecoration(WidgetTester tester, String label) {
  return tester.widget<DecoratedBox>(_badge(label)).decoration as ShapeDecoration;
}

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(SectionBlock))).colorScheme;

/// Wraps [child] in a MediaQuery with a linear text [scale].
Widget _scaled(double scale, Widget child) {
  return Builder(
    builder: (BuildContext context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
      child: child,
    ),
  );
}

void main() {
  group("structure", () {
    testWidgets("renders the index label, title, caption and child", (WidgetTester tester) async {
      await pumpApp(tester, _block);

      expect(find.text("1"), findsOneWidget);
      expect(find.text("Title"), findsOneWidget);
      expect(find.text("Caption"), findsOneWidget);
      expect(find.text("Body"), findsOneWidget);
    });

    testWidgets("renders no caption when it is null", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const SectionBlock(indexLabel: "1", title: "Title", child: Text("Body")),
      );

      expect(find.text("Title"), findsOneWidget);
      expect(find.text("Body"), findsOneWidget);
      expect(_inBlock(find.byType(Text)), findsNWidgets(3));
      // No caption gap is left behind: the child sits 16 dp below the
      // taller of the badge and the title.
      final double headerBottom = math.max(
        tester.getBottomLeft(_badge("1")).dy,
        tester.getBottomLeft(find.text("Title")).dy,
      );
      expect(tester.getTopLeft(find.text("Body")).dy, headerBottom + kDefaultPadding * 2);
    });

    test("rejects an empty index label", () {
      expect(
        () => SectionBlock(indexLabel: "", title: "Title", child: const Text("Body")),
        throwsAssertionError,
      );
    });
  });

  group("layout", () {
    testWidgets("the badge sits left of the title, 12 dp apart", (WidgetTester tester) async {
      await pumpApp(tester, _block);

      final double gap = tester.getTopLeft(find.text("Title")).dx - tester.getTopRight(_badge("1")).dx;
      expect(gap, kDefaultPadding * 1.5);
      expect(tester.getTopLeft(_badge("1")).dy, tester.getTopLeft(find.text("Title")).dy);
    });

    testWidgets("the caption is 4 dp under the title", (WidgetTester tester) async {
      await pumpApp(tester, _block);

      final double gap = tester.getTopLeft(find.text("Caption")).dy - tester.getBottomLeft(find.text("Title")).dy;
      expect(gap, kDefaultPadding / 2);
    });

    testWidgets("the child is 16 dp below the header row", (WidgetTester tester) async {
      await pumpApp(tester, _block);

      final double headerBottom = <double>[
        tester.getBottomLeft(_badge("1")).dy,
        tester.getBottomLeft(find.text("Caption")).dy,
      ].reduce((double a, double b) => a > b ? a : b);
      expect(tester.getTopLeft(find.text("Body")).dy, headerBottom + kDefaultPadding * 2);
      expect(tester.getTopLeft(find.text("Body")).dy, greaterThan(tester.getBottomLeft(find.text("Title")).dy));
    });

    testWidgets("the badge is a 30 dp circle for a short label", (WidgetTester tester) async {
      await pumpApp(tester, _block);

      expect(tester.getSize(_badge("1")), const Size(30, 30));
      expect(_badgeDecoration(tester, "1").shape, isA<StadiumBorder>());
      expect(tester.getCenter(find.text("1")), tester.getCenter(_badge("1")));
    });
  });

  group("theme tokens", () {
    testWidgets("badge uses primary / onPrimary", (WidgetTester tester) async {
      await pumpApp(tester, _block);

      final ColorScheme cs = _scheme(tester);
      expect(_badgeDecoration(tester, "1").color, cs.primary);
      final TextStyle? style = tester.widget<Text>(find.text("1")).style;
      expect(style?.color, cs.onPrimary);
      expect(style?.fontWeight, FontWeight.w800);
    });

    testWidgets("title is titleLarge w800 in onSurface", (WidgetTester tester) async {
      await pumpApp(tester, _block);

      final ThemeData theme = Theme.of(tester.element(find.byType(SectionBlock)));
      final TextStyle? style = tester.widget<Text>(find.text("Title")).style;
      expect(style?.fontSize, theme.textTheme.titleLarge?.fontSize);
      expect(style?.fontWeight, FontWeight.w800);
      expect(style?.color, theme.colorScheme.onSurface);
    });

    testWidgets("caption is bodyMedium in onSurfaceVariant with height 1.5", (WidgetTester tester) async {
      await pumpApp(tester, _block);

      final ThemeData theme = Theme.of(tester.element(find.byType(SectionBlock)));
      final TextStyle? style = tester.widget<Text>(find.text("Caption")).style;
      expect(style?.fontSize, theme.textTheme.bodyMedium?.fontSize);
      expect(style?.color, theme.colorScheme.onSurfaceVariant);
      expect(style?.height, 1.5);
    });
  });

  group("semantics", () {
    testWidgets("exposes one header node and hides the bare badge label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _block);

      expect(
        tester.getSemantics(find.bySemanticsLabel("1. Title")),
        matchesSemantics(isHeader: true, label: "1. Title"),
      );
      expect(find.bySemanticsLabel("1"), findsNothing);
      expect(find.bySemanticsLabel("Title"), findsNothing);
      expect(find.bySemanticsLabel("Caption"), findsOneWidget);
      expect(find.bySemanticsLabel("Body"), findsOneWidget);
      handle.dispose();
    });
  });

  group("robustness", () {
    testWidgets("long text, a two-digit label and text scale 2 lay out without error", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _scaled(
          2,
          SingleChildScrollView(
            child: SectionBlock(
              indexLabel: "10",
              title: "A rather long section title that wraps " * 3,
              caption: "A long descriptive paragraph that wraps over several lines. " * 4,
              child: const Text("Body"),
            ),
          ),
        ),
        surfaceSize: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
      // The badge grew past its default 30 dp diameter...
      final Size badge = tester.getSize(_badge("10"));
      expect(badge.width, greaterThan(30));
      expect(badge.height, greaterThan(30));
      // ...and the label keeps its natural width (it is not squeezed or clipped).
      final RenderParagraph label = tester.renderObject<RenderParagraph>(find.text("10"));
      expect(label.size.width, closeTo(label.getMaxIntrinsicWidth(double.infinity), 0.01));
      expect(badge.width, greaterThanOrEqualTo(label.size.width + kDefaultPadding));
      expect(tester.getTopRight(find.text("Body")).dx, lessThanOrEqualTo(320));
    });

    testWidgets("a one-character label stays a circle at text scale 2", (WidgetTester tester) async {
      await pumpApp(tester, _scaled(2, _block));

      expect(tester.takeException(), isNull);
      final Size badge = tester.getSize(_badge("1"));
      expect(badge.width, greaterThan(30));
      expect(badge.width, badge.height);
      expect(tester.getCenter(find.text("1")), tester.getCenter(_badge("1")));
    });
  });

  group("dark theme", () {
    testWidgets("renders with the dark scheme's primary / onPrimary", (WidgetTester tester) async {
      await pumpApp(tester, _block, theme: AppTheme.dark());

      expect(tester.takeException(), isNull);
      final ColorScheme cs = _scheme(tester);
      expect(cs.brightness, Brightness.dark);
      expect(_badgeDecoration(tester, "1").color, cs.primary);
      expect(tester.widget<Text>(find.text("1")).style?.color, cs.onPrimary);
      expect(tester.widget<Text>(find.text("Title")).style?.color, cs.onSurface);
    });
  });
}

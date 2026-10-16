// source_badge_test.dart
//
// Widget tests for SourceBadge: composition of an outlined, dense PillBadge,
// ColorScheme tokens in light and dark themes, the tap tooltip and its 48 dp
// hit area, single-node "source: description" semantics with no duplicate
// tooltip property, the empty description fallback, and layout in a narrow
// Wrap / one-line ellipsis.

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/PillBadge/index.dart";
import "package:flutter_skeleton/widgets/custom/SourceBadge/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _source = "Census";
const String _description = "National census, 2024 edition";
const String _semantics = "$_source: $_description";

Finder _inBadge(Finder matching) {
  return find.descendant(of: find.byType(SourceBadge), matching: matching);
}

PillBadge _pillBadge(WidgetTester tester) => tester.widget<PillBadge>(find.byType(PillBadge));

/// The pill Container drawn by PillBadge.
BoxDecoration _decoration(WidgetTester tester) {
  return tester.widget<Container>(_inBadge(find.byType(Container))).decoration! as BoxDecoration;
}

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(SourceBadge))).colorScheme;

Future<void> _finishTooltipTimers(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

/// Checks the pill tokens against the scheme in force.
void _expectTokens(WidgetTester tester) {
  final ColorScheme cs = _scheme(tester);
  final BoxDecoration decoration = _decoration(tester);

  expect(decoration.color, cs.surfaceContainerHigh);
  expect(decoration.border, Border.all(color: cs.outlineVariant));
  expect(decoration.borderRadius, BorderRadius.circular(999));
  expect(tester.widget<Text>(find.text(_source)).style?.color, cs.onSurfaceVariant);
}

void main() {
  group("structure", () {
    testWidgets("renders the source and hides the description until tapped", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: SourceBadge(source: _source, description: _description)));

      expect(find.text(_source), findsOneWidget);
      expect(find.text(_description), findsNothing);
    });

    testWidgets("composes an outlined, dense PillBadge with the description as tooltip", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: SourceBadge(source: _source, description: _description)));

      final PillBadge pill = _pillBadge(tester);
      expect(pill.label, _source);
      expect(pill.outlined, isTrue);
      expect(pill.dense, isTrue);
      expect(pill.tooltip, _description);
      expect(pill.semanticsLabel, isNull);
      expect(pill.icon, isNull);
    });
  });

  group("tokens", () {
    testWidgets("light theme: surfaceContainerHigh fill, outlineVariant border, muted label", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: SourceBadge(source: _source, description: _description)));

      expect(_scheme(tester).brightness, Brightness.light);
      _expectTokens(tester);
    });

    testWidgets("dark theme: the same tokens resolve from the dark scheme", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Center(child: SourceBadge(source: _source, description: _description)),
        theme: AppTheme.dark(),
      );

      expect(tester.takeException(), isNull);
      expect(_scheme(tester).brightness, Brightness.dark);
      _expectTokens(tester);
    });
  });

  group("tooltip", () {
    testWidgets("tapping shows the description, which then goes away", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: SourceBadge(source: _source, description: _description)));

      await tester.tap(find.byType(SourceBadge));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(_description), findsOneWidget);

      await _finishTooltipTimers(tester);
      expect(find.text(_description), findsNothing);
    });

    testWidgets("the hit area is at least 48 dp around the unchanged pill", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: SourceBadge(source: _source, description: _description)));

      final Size area = tester.getSize(find.byType(SourceBadge));
      final Size pill = tester.getSize(_inBadge(find.byType(Container)));
      expect(area.height, greaterThanOrEqualTo(kMinTapTarget));
      expect(area.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(pill.height, lessThan(kMinTapTarget));
    });

    testWidgets("an empty description gives no tooltip and a natural-height pill", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: SourceBadge(source: _source, description: "")));

      expect(_inBadge(find.byType(Tooltip)), findsNothing);
      expect(tester.getSize(find.byType(SourceBadge)).height, lessThan(kMinTapTarget));
    });
  });

  group("semantics", () {
    testWidgets("one node labelled source: description, nothing read twice", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const Center(child: SourceBadge(source: _source, description: _description)));

      expect(find.bySemanticsLabel(_semantics), findsOneWidget);
      expect(find.bySemanticsLabel(_source), findsNothing);
      // The label already carries the description: no tooltip property.
      expect(tester.getSemantics(find.bySemanticsLabel(_semantics)).getSemanticsData().tooltip, isEmpty);
      handle.dispose();
    });

    testWidgets("an empty description is announced as the source alone", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const Center(child: SourceBadge(source: _source, description: "")));

      expect(find.bySemanticsLabel(_source), findsOneWidget);
      expect(find.bySemanticsLabel("$_source: "), findsNothing);
      handle.dispose();
    });
  });

  group("layout", () {
    testWidgets("four badges in a 280 px Wrap lay out without overflow", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 280,
            child: Wrap(
              spacing: kDefaultPadding / 2,
              children: <Widget>[
                SourceBadge(source: "Census 2024", description: "First"),
                SourceBadge(source: "Open data portal", description: "Second"),
                SourceBadge(source: "Internal survey", description: "Third"),
                SourceBadge(source: "Field study", description: "Fourth"),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SourceBadge), findsNWidgets(4));
      for (final Element badge in find.byType(SourceBadge).evaluate()) {
        expect(tester.getRect(find.byWidget(badge.widget)).right, lessThanOrEqualTo(280));
      }
    });

    testWidgets("a long source ellipsizes on one line in a narrow parent", (WidgetTester tester) async {
      const String longSource = "A rather long source name that cannot fit";
      await pumpApp(
        tester,
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 80),
            child: const SourceBadge(source: longSource, description: _description),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(find.text(longSource));
      expect(paragraph.maxLines, 1);
      expect(paragraph.overflow, TextOverflow.ellipsis);
      expect(paragraph.didExceedMaxLines, isTrue);
      expect(tester.getSize(_inBadge(find.byType(Container))).height, lessThan(kMinTapTarget));
    });
  });
}

// distribution_bar_test.dart
//
// Widget tests of DistributionBar: proportional slices, the localised legend
// text, empty and zero cases, the optional title (hosted by SectionCard), the
// card and bar tokens, colour resolution (colour, tone, ColorScheme cycle and
// its contrast against the card), the legend builder seam, semantics, narrow
// layouts and a dark-theme smoke test.

import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/DistributionBar/index.dart";
import "package:flutter_skeleton/widgets/custom/SectionCard/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const List<DistributionBarSegment> _threeSegments = <DistributionBarSegment>[
  DistributionBarSegment(label: "Alpha", value: 42),
  DistributionBarSegment(label: "Beta", value: 31),
  DistributionBarSegment(label: "Gamma", value: 27),
];

/// Bar slices (ColoredBox under the bar's ClipRRect), left to right.
List<Element> _slices(WidgetTester tester) {
  final Finder finder = find.descendant(
    of: find.descendant(of: find.byType(DistributionBar), matching: find.byType(ClipRRect)),
    matching: find.byType(ColoredBox),
  );
  final List<Element> elements = finder.evaluate().toList();
  elements.sort((Element a, Element b) => tester.getTopLeft(find.byWidget(a.widget)).dx.compareTo(
        tester.getTopLeft(find.byWidget(b.widget)).dx,
      ));
  return elements;
}

Color _sliceColor(Element element) => (element.widget as ColoredBox).color;

/// Colour of the legend dot next to [text].
Color? _dotColor(WidgetTester tester, String text) {
  final Finder entry = find.ancestor(of: find.text(text), matching: find.byType(Row)).first;
  final Finder dot = find.descendant(of: entry, matching: find.byType(DecoratedBox));
  final BoxDecoration decoration = tester.widget<DecoratedBox>(dot.first).decoration as BoxDecoration;
  return decoration.color;
}

/// WCAG 2.x contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(DistributionBar))).colorScheme;
}

void main() {
  group("DistributionBar", () {
    testWidgets("slice widths keep the value ratio, in the given order", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Center(child: SizedBox(width: 400, child: DistributionBar(segments: _threeSegments))),
        surfaceSize: const Size(800, 600),
      );

      final List<Element> slices = _slices(tester);
      expect(slices, hasLength(3));
      final List<double> widths = <double>[
        for (final Element slice in slices) tester.getSize(find.byWidget(slice.widget)).width,
      ];
      final double total = widths.fold<double>(0, (double sum, double width) => sum + width);
      expect(widths[0], closeTo(total * 0.42, 1));
      expect(widths[1], closeTo(total * 0.31, 1));
      expect(widths[2], closeTo(total * 0.27, 1));

      final ColorScheme cs = _scheme(tester);
      expect(slices.map(_sliceColor).toList(), <Color>[cs.primary, cs.tertiary, cs.secondary]);
    });

    testWidgets("legend shows label · percentage in the default locale", (WidgetTester tester) async {
      await pumpApp(tester, const DistributionBar(segments: _threeSegments));

      expect(find.text("Alpha · 42%"), findsOneWidget);
      expect(find.text("Beta · 31%"), findsOneWidget);
      expect(find.text("Gamma · 27%"), findsOneWidget);
    });

    testWidgets("legend percentage follows the ambient locale", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => Localizations.override(
            context: context,
            locale: const Locale("fr"),
            child: const DistributionBar(segments: _threeSegments),
          ),
        ),
      );

      expect(find.text("Alpha · 42 %"), findsOneWidget);
      expect(find.text("Gamma · 27 %"), findsOneWidget);
    });

    testWidgets("shares come from the sum of the values", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const DistributionBar(
          segments: <DistributionBarSegment>[
            DistributionBarSegment(label: "Alpha", value: 3),
            DistributionBarSegment(label: "Beta", value: 1),
          ],
        ),
      );

      expect(find.text("Alpha · 75%"), findsOneWidget);
      expect(find.text("Beta · 25%"), findsOneWidget);
    });

    testWidgets("renders nothing when there are no segments", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: DistributionBar(segments: <DistributionBarSegment>[], title: "BREAKDOWN"),
        ),
      );

      expect(find.byType(Text), findsNothing);
      expect(tester.getSize(find.byType(DistributionBar)), Size.zero);
    });

    testWidgets("renders nothing when every value is 0", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: DistributionBar(
            title: "BREAKDOWN",
            segments: <DistributionBarSegment>[
              DistributionBarSegment(label: "Alpha", value: 0),
              DistributionBarSegment(label: "Beta", value: 0),
            ],
          ),
        ),
      );

      expect(find.byType(Text), findsNothing);
      expect(find.text("BREAKDOWN"), findsNothing);
      expect(tester.getSize(find.byType(DistributionBar)), Size.zero);
    });

    testWidgets("a zero-value segment draws no slice but keeps its legend entry", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const DistributionBar(
          segments: <DistributionBarSegment>[
            DistributionBarSegment(label: "Alpha", value: 2),
            DistributionBarSegment(label: "Beta", value: 0),
            DistributionBarSegment(label: "Gamma", value: 2),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      final List<Element> slices = _slices(tester);
      expect(slices, hasLength(2));
      final ColorScheme cs = _scheme(tester);
      expect(slices.map(_sliceColor).toList(), <Color>[cs.primary, cs.secondary]);
      expect(find.text("Beta · 0%"), findsOneWidget);
    });

    testWidgets("title renders verbatim in onSurfaceVariant, as a header", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const DistributionBar(segments: _threeSegments, title: "Breakdown"));

      expect(find.text("Breakdown"), findsOneWidget);
      final Text title = tester.widget<Text>(find.text("Breakdown"));
      expect(title.style?.color, _scheme(tester).onSurfaceVariant);
      expect(find.descendant(of: find.byType(DistributionBar), matching: find.byType(Divider)), findsOneWidget);
      expect(
        tester.getSemantics(find.text("Breakdown")),
        matchesSemantics(label: "Breakdown", isHeader: true),
      );
      handle.dispose();
    });

    testWidgets("without a title only the bar and the legend render", (WidgetTester tester) async {
      await pumpApp(tester, const DistributionBar(segments: _threeSegments));

      expect(find.descendant(of: find.byType(DistributionBar), matching: find.byType(Divider)), findsNothing);
      expect(find.descendant(of: find.byType(DistributionBar), matching: find.byType(Text)), findsNWidgets(3));
      expect(_slices(tester), hasLength(3));
    });

    testWidgets("untitled card and bar use the ColorScheme tokens", (WidgetTester tester) async {
      await pumpApp(tester, const DistributionBar(segments: _threeSegments));

      expect(find.byType(SectionCard), findsNothing);
      final Container card = tester.widget<Container>(
        find.descendant(of: find.byType(DistributionBar), matching: find.byType(Container)).first,
      );
      final BoxDecoration decoration = card.decoration! as BoxDecoration;
      final ColorScheme cs = _scheme(tester);
      expect(decoration.color, cs.surfaceContainerLow);
      expect((decoration.border! as Border).top.color, cs.outlineVariant);
      expect(decoration.borderRadius, BorderRadius.circular(12));
      expect(card.clipBehavior, Clip.antiAlias);

      final Finder bar = find.descendant(of: find.byType(DistributionBar), matching: find.byType(ClipRRect));
      expect(tester.widget<ClipRRect>(bar).borderRadius, BorderRadius.circular(999));
      final DecoratedBox track = tester.widget<DecoratedBox>(
        find.descendant(of: bar, matching: find.byType(DecoratedBox)).first,
      );
      expect((track.decoration as BoxDecoration).color, cs.surfaceContainerHighest);
    });

    testWidgets("a title hosts the bar and the legend in a SectionCard", (WidgetTester tester) async {
      await pumpApp(tester, const DistributionBar(segments: _threeSegments, title: "Breakdown"));

      final Finder section = find.descendant(of: find.byType(DistributionBar), matching: find.byType(SectionCard));
      expect(section, findsOneWidget);
      expect(tester.widget<SectionCard>(section).title, "Breakdown");
      expect(find.descendant(of: section, matching: find.byType(ClipRRect)), findsOneWidget);
      expect(find.descendant(of: section, matching: find.text("Alpha · 42%")), findsOneWidget);
    });

    testWidgets("explicit colour paints the slice and the dot, and wins over tone", (WidgetTester tester) async {
      final Color custom = AppTheme.light().colorScheme.inversePrimary;
      await pumpApp(
        tester,
        DistributionBar(
          segments: <DistributionBarSegment>[
            DistributionBarSegment(label: "Alpha", value: 1, color: custom, tone: StatusTone.danger),
            const DistributionBarSegment(label: "Beta", value: 1),
          ],
        ),
      );

      expect(_sliceColor(_slices(tester).first), custom);
      expect(_dotColor(tester, "Alpha · 50%"), custom);
    });

    testWidgets("tone paints its foreground; no colour falls back to the cycle", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const DistributionBar(
          segments: <DistributionBarSegment>[
            DistributionBarSegment(label: "Alpha", value: 1),
            DistributionBarSegment(label: "Beta", value: 1),
            DistributionBarSegment(label: "Gamma", value: 1, tone: StatusTone.warning),
          ],
        ),
      );

      final BuildContext context = tester.element(find.byType(DistributionBar));
      final ColorScheme cs = _scheme(tester);
      final Color warning = StatusTones.colorsOf(context, StatusTone.warning).foreground;
      expect(_slices(tester).map(_sliceColor).toList(), <Color>[cs.primary, cs.tertiary, warning]);
      expect(_dotColor(tester, "Alpha · 33%"), cs.primary);
      expect(_dotColor(tester, "Beta · 33%"), cs.tertiary);
      expect(_dotColor(tester, "Gamma · 33%"), warning);
    });

    testWidgets("the ColorScheme cycle wraps after seven segments", (WidgetTester tester) async {
      await pumpApp(
        tester,
        DistributionBar(
          segments: <DistributionBarSegment>[
            for (int i = 0; i < 8; i++) DistributionBarSegment(label: "Item $i", value: 1),
          ],
        ),
      );

      final ColorScheme cs = _scheme(tester);
      expect(_slices(tester).map(_sliceColor).toList(), <Color>[
        cs.primary,
        cs.tertiary,
        cs.secondary,
        cs.error,
        cs.onPrimaryContainer,
        cs.onTertiaryContainer,
        cs.outline,
        cs.primary,
      ]);
    });

    testWidgets("every cycle colour reaches 3:1 against the card in both themes", (WidgetTester tester) async {
      for (final ThemeData theme in <ThemeData>[AppTheme.light(), AppTheme.dark()]) {
        await pumpApp(
          tester,
          DistributionBar(
            segments: <DistributionBarSegment>[
              for (int i = 0; i < 7; i++) DistributionBarSegment(label: "Item $i", value: 1),
            ],
          ),
          theme: theme,
        );

        final ColorScheme cs = _scheme(tester);
        final List<Color> cycle = _slices(tester).map(_sliceColor).toList();
        expect(cycle.toSet(), hasLength(7), reason: "${cs.brightness}");
        for (final Color color in cycle) {
          expect(_contrast(color, cs.surfaceContainerLow), greaterThanOrEqualTo(3), reason: "${cs.brightness} $color");
        }
      }
    });

    testWidgets("legendTextBuilder receives each segment and its share", (WidgetTester tester) async {
      final List<(String, double)> calls = <(String, double)>[];
      await pumpApp(
        tester,
        DistributionBar(
          segments: const <DistributionBarSegment>[
            DistributionBarSegment(label: "Alpha", value: 3),
            DistributionBarSegment(label: "Beta", value: 1),
          ],
          legendTextBuilder: (DistributionBarSegment segment, double share) {
            calls.add((segment.label, share));
            return "${segment.label}: ${segment.value.toInt()} items";
          },
        ),
      );

      expect(calls, <(String, double)>[("Alpha", 0.75), ("Beta", 0.25)]);
      expect(find.text("Alpha: 3 items"), findsOneWidget);
      expect(find.text("Beta: 1 items"), findsOneWidget);
      expect(find.textContaining("%"), findsNothing);
    });

    test("a negative value fails the assertion", () {
      expect(() => DistributionBarSegment(label: "Alpha", value: -1), throwsAssertionError);
      expect(() => DistributionBarSegment(label: "Alpha", value: double.nan), throwsAssertionError);
      expect(() => DistributionBarSegment(label: "Alpha", value: double.infinity), throwsAssertionError);
    });

    testWidgets("legend text is in the semantics tree; bar and dots are excluded", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const DistributionBar(segments: _threeSegments));

      expect(find.bySemanticsLabel("Alpha · 42%"), findsOneWidget);
      expect(find.bySemanticsLabel("Beta · 31%"), findsOneWidget);
      expect(find.bySemanticsLabel("Gamma · 27%"), findsOneWidget);

      final Finder bar = find.descendant(of: find.byType(DistributionBar), matching: find.byType(ClipRRect));
      expect(find.ancestor(of: bar, matching: find.byType(ExcludeSemantics)), findsWidgets);
      final Finder dots = find.descendant(
        of: find.byType(DistributionBar),
        matching: find.byWidgetPredicate(
          (Widget widget) => widget is DecoratedBox && (widget.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      );
      expect(dots, findsNWidgets(3));
      for (final Element dot in dots.evaluate()) {
        expect(find.ancestor(of: find.byWidget(dot.widget), matching: find.byType(ExcludeSemantics)), findsWidgets);
      }
      handle.dispose();
    });

    testWidgets("legend wraps on narrow widths without overflow", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Center(
          child: SizedBox(
            width: 200,
            child: DistributionBar(
              segments: <DistributionBarSegment>[
                for (int i = 0; i < 5; i++) DistributionBarSegment(label: "Item $i", value: i + 1),
                const DistributionBarSegment(
                  label: "A deliberately long legend label that cannot fit on one line",
                  value: 2,
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final Set<double> runs = <double>{
        for (int i = 0; i < 5; i++) tester.getTopLeft(find.textContaining("Item $i ·")).dy,
      };
      expect(runs.length, greaterThan(1));
    });

    testWidgets("dark theme smoke test: colours follow the dark scheme", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const DistributionBar(
          title: "Breakdown",
          segments: <DistributionBarSegment>[
            DistributionBarSegment(label: "Alpha", value: 2),
            DistributionBarSegment(label: "Beta", value: 1, tone: StatusTone.danger),
          ],
        ),
        theme: AppTheme.dark(),
      );

      expect(tester.takeException(), isNull);
      final ColorScheme cs = _scheme(tester);
      expect(cs.brightness, Brightness.dark);
      final BuildContext context = tester.element(find.byType(DistributionBar));
      final Color danger = StatusTones.colorsOf(context, StatusTone.danger).foreground;
      expect(_slices(tester).map(_sliceColor).toList(), <Color>[cs.primary, danger]);
      expect(tester.widget<Text>(find.text("Alpha · 67%")).style?.color, cs.onSurface);
    });
  });
}

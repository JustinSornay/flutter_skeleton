// map_export_overlay_test.dart
//
// Widget tests for MapExportOverlay: which parts render (north badge, legend
// card, attribution pill) for each parameter combination, the legend rows and
// swatch colours, the joined attribution line, gesture pass-through, corner
// layout, wrapping of long labels, theme tokens under the light and dark
// themes, and the semantics labels.

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/custom/MapExportOverlay/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _northKey = "custom.map_export_overlay.north";
const String _northShortKey = "custom.map_export_overlay.north_short";
const String _legendKey = "custom.map_export_overlay.legend_label";

/// Overlay size in every test unless stated otherwise.
const Size _size = Size(600, 400);

final List<MapLegendEntry> _entries = <MapLegendEntry>[
  const MapLegendEntry(color: AppTheme.seed, label: "High"),
  MapLegendEntry(color: AppTheme.light().colorScheme.tertiary, label: "Medium"),
  MapLegendEntry(color: AppTheme.light().colorScheme.error, label: "Low"),
];

Future<void> _pump(
  WidgetTester tester,
  MapExportOverlay overlay, {
  ThemeData? theme,
  Size size = _size,
}) {
  return pumpApp(tester, overlay, surfaceSize: size, theme: theme);
}

/// Background colour of the nearest [DecoratedBox] above [text].
Color? _backgroundOf(WidgetTester tester, Finder text) {
  final DecoratedBox box = tester.widget<DecoratedBox>(
    find.ancestor(of: text, matching: find.byType(DecoratedBox)).first,
  );
  return (box.decoration as BoxDecoration).color;
}

/// Nearest [DecoratedBox] above [text], as a finder.
Finder _boxOf(Finder text) {
  return find.ancestor(of: text, matching: find.byType(DecoratedBox)).first;
}

Color? _textColor(WidgetTester tester, String text) {
  return tester.widget<Text>(find.text(text)).style?.color;
}

void main() {
  group("parts", () {
    testWidgets("defaults render only the north badge", (WidgetTester tester) async {
      await _pump(tester, const MapExportOverlay());

      expect(find.text(_northShortKey), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
      expect(find.bySemanticsLabel(_legendKey), findsNothing);
    });

    testWidgets("showNorthArrow false removes the badge and its label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, const MapExportOverlay(showNorthArrow: false, legendTitle: "Score"));

      expect(find.text(_northShortKey), findsNothing);
      expect(find.bySemanticsLabel(_northKey), findsNothing);
      expect(find.text("SCORE"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("nothing to show renders an empty overlay", (WidgetTester tester) async {
      await _pump(tester, const MapExportOverlay(showNorthArrow: false));

      expect(find.byType(Text), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group("legend", () {
    testWidgets("title is upper-cased and subtitle shown verbatim", (WidgetTester tester) async {
      await _pump(
        tester,
        const MapExportOverlay(legendTitle: "Score", legendSubtitle: "Reference period"),
      );

      expect(find.text("SCORE"), findsOneWidget);
      expect(find.text("Score"), findsNothing);
      expect(find.text("Reference period"), findsOneWidget);
    });

    testWidgets("renders one row per entry, in order, with its swatch colour", (WidgetTester tester) async {
      await _pump(tester, MapExportOverlay(legendTitle: "Score", legendEntries: _entries));

      double previousTop = -1;
      for (final MapLegendEntry entry in _entries) {
        final Finder label = find.text(entry.label);
        expect(label, findsOneWidget);
        final double top = tester.getTopLeft(label).dy;
        expect(top, greaterThan(previousTop));
        previousTop = top;

        final Finder row = find.ancestor(of: label, matching: find.byType(Row)).first;
        final Finder swatch = find.descendant(of: row, matching: find.byType(DecoratedBox));
        expect(swatch, findsOneWidget);
        final BoxDecoration decoration =
            tester.widget<DecoratedBox>(swatch).decoration as BoxDecoration;
        expect(decoration.color, entry.color);
        expect(tester.getSize(swatch), const Size(12, 12));
      }
    });

    testWidgets("accepts any number of rows", (WidgetTester tester) async {
      final List<MapLegendEntry> many = List<MapLegendEntry>.generate(
        7,
        (int i) => MapLegendEntry(color: AppTheme.seed, label: "Row $i"),
      );
      await _pump(tester, MapExportOverlay(legendEntries: many));

      for (int i = 0; i < 7; i++) {
        expect(find.text("Row $i"), findsOneWidget);
      }
    });

    testWidgets("card is absent without title, subtitle and entries", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, const MapExportOverlay(attributions: <String>["Source"]));

      expect(find.bySemanticsLabel(_legendKey), findsNothing);
      handle.dispose();
    });

    testWidgets("card is present with only entries", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, MapExportOverlay(legendEntries: _entries.sublist(0, 1)));

      expect(find.bySemanticsLabel(_legendKey), findsOneWidget);
      expect(find.text("High"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("card is present with only a title or only a subtitle", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, const MapExportOverlay(legendTitle: "Score"));
      expect(find.bySemanticsLabel(_legendKey), findsOneWidget);

      await _pump(tester, const MapExportOverlay(legendSubtitle: "Now"));
      expect(find.bySemanticsLabel(_legendKey), findsOneWidget);
      expect(find.text("Now"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("long labels wrap inside the overlay", (WidgetTester tester) async {
      const Size narrow = Size(200, 300);
      final String long = List<String>.filled(12, "word").join(" ");
      await _pump(
        tester,
        MapExportOverlay(
          legendTitle: long,
          legendEntries: <MapLegendEntry>[MapLegendEntry(color: AppTheme.seed, label: long)],
        ),
        size: narrow,
      );

      expect(tester.takeException(), isNull);
      final Rect card = tester.getRect(_boxOf(find.text(long.toUpperCase())));
      expect(card.left, greaterThanOrEqualTo(16));
      expect(card.right, closeTo(narrow.width - 16, 0.01));
    });
  });

  group("attributions", () {
    testWidgets("are joined in one centred pill", (WidgetTester tester) async {
      await _pump(tester, const MapExportOverlay(attributions: <String>["A", "B", "C"]));

      final Finder text = find.text("A · B · C");
      expect(text, findsOneWidget);
      final Rect pill = tester.getRect(_boxOf(text));
      expect(pill.center.dx, closeTo(_size.width / 2, 0.01));
      expect(pill.bottom, closeTo(_size.height - 12, 0.01));
    });

    testWidgets("empty list renders no pill", (WidgetTester tester) async {
      await _pump(tester, const MapExportOverlay(showNorthArrow: false));

      expect(find.byType(DecoratedBox), findsNothing);
    });
  });

  group("layout and interaction", () {
    testWidgets("places the badge and the legend 16 dp from the corners", (WidgetTester tester) async {
      await _pump(tester, MapExportOverlay(legendTitle: "Score", legendEntries: _entries));

      final Rect badge = tester.getRect(_boxOf(find.text(_northShortKey)));
      expect(badge.size, const Size(32, 32));
      expect(badge.topRight, const Offset(600 - 16, 16));

      final Rect card = tester.getRect(_boxOf(find.text("SCORE")));
      expect(card.right, closeTo(_size.width - 16, 0.01));
      expect(card.bottom, closeTo(_size.height - 36, 0.01));
    });

    testWidgets("never intercepts gestures", (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(
        tester,
        Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
              ),
            ),
            Positioned.fill(
              child: MapExportOverlay(
                legendTitle: "Score",
                legendEntries: _entries,
                attributions: const <String>["Source"],
              ),
            ),
          ],
        ),
        surfaceSize: _size,
      );

      await tester.tap(find.text(_northShortKey), warnIfMissed: false);
      await tester.tap(find.text("SCORE"), warnIfMissed: false);
      await tester.tap(find.text("Source"), warnIfMissed: false);
      await tester.tapAt(_size.center(Offset.zero));
      expect(taps, 4);
    });
  });

  group("theme", () {
    for (final (String name, ThemeData theme) in <(String, ThemeData)>[
      ("light", AppTheme.light()),
      ("dark", AppTheme.dark()),
    ]) {
      testWidgets("uses inverse-surface tokens ($name)", (WidgetTester tester) async {
        final ColorScheme cs = theme.colorScheme;
        await _pump(
          tester,
          MapExportOverlay(
            legendTitle: "Score",
            legendSubtitle: "Now",
            legendEntries: _entries,
            attributions: const <String>["Source"],
          ),
          theme: theme,
        );

        expect(
          _backgroundOf(tester, find.text(_northShortKey)),
          cs.inverseSurface.withValues(alpha: 0.58),
        );
        expect(
          _backgroundOf(tester, find.text("SCORE")),
          cs.inverseSurface.withValues(alpha: 0.62),
        );
        expect(
          _backgroundOf(tester, find.text("Source")),
          cs.inverseSurface.withValues(alpha: 0.58),
        );
        for (final String text in <String>[_northShortKey, "SCORE", "High", "Source"]) {
          expect(_textColor(tester, text), cs.onInverseSurface, reason: text);
        }
        expect(_textColor(tester, "Now"), cs.onInverseSurface.withValues(alpha: 0.54));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group("semantics", () {
    testWidgets("labels the north badge and the legend container", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, MapExportOverlay(legendTitle: "Score", legendEntries: _entries));

      expect(find.bySemanticsLabel(_northKey), findsOneWidget);
      expect(find.bySemanticsLabel(_northShortKey), findsNothing);
      expect(find.bySemanticsLabel(_legendKey), findsOneWidget);
      expect(find.bySemanticsLabel("SCORE"), findsOneWidget);
      expect(find.bySemanticsLabel("High"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("is wrapped in an ignoring IgnorePointer", (WidgetTester tester) async {
      await _pump(tester, const MapExportOverlay());

      final IgnorePointer ignore = tester.widget<IgnorePointer>(
        find.descendant(of: find.byType(MapExportOverlay), matching: find.byType(IgnorePointer)).first,
      );
      expect(ignore.ignoring, isTrue);
      expect(
        tester.renderObject<RenderIgnorePointer>(
          find.descendant(of: find.byType(MapExportOverlay), matching: find.byType(IgnorePointer)).first,
        ).ignoring,
        isTrue,
      );
    });
  });
}

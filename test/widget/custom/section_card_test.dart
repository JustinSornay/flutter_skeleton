// section_card_test.dart
//
// Widget tests for SectionCard: title and row rendering order, the divider
// and 8 dp-grid paddings, the verbatim title, header semantics, ColorScheme
// tokens in light and dark themes, the foreground border (row fills and
// pressed ink never cover the rounded corners, read from rendered pixels),
// clipping and the ink surface for ripples, width / height sizing, empty
// rows, tappable rows and reduced motion.

import "dart:typed_data";
import "dart:ui" as ui;

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/SectionCard/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const SectionCard _card = SectionCard(
  title: "Section",
  children: <Widget>[
    ListTile(title: Text("First row")),
    Divider(height: 1),
    ListTile(title: Text("Second row")),
  ],
);

/// Width of the panel border; the content sits inside it.
const double _border = 1;

Finder _inCard(Finder matching) {
  return find.descendant(of: find.byType(SectionCard), matching: matching);
}

/// The panel: the first Container under the card.
Container _panel(WidgetTester tester) {
  return tester.widget<Container>(_inCard(find.byType(Container)).first);
}

BoxDecoration _decoration(WidgetTester tester) {
  return _panel(tester).decoration! as BoxDecoration;
}

/// The panel border, painted above the rows.
BoxDecoration _foreground(WidgetTester tester) {
  return _panel(tester).foregroundDecoration! as BoxDecoration;
}

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(SectionCard))).colorScheme;

/// Colour of the rendered pixel at [position] in the RepaintBoundary found
/// by [boundary] (the card's local coordinates when it wraps the card).
Future<Color> _pixelAt(WidgetTester tester, Finder boundary, Offset position) async {
  final RenderRepaintBoundary render = tester.renderObject<RenderRepaintBoundary>(boundary);
  final Color? color = await tester.runAsync<Color>(() async {
    final ui.Image image = await render.toImage();
    final ByteData data = (await image.toByteData())!;
    final int i = (position.dy.floor() * image.width + position.dx.floor()) * 4;
    image.dispose();
    return Color.fromARGB(data.getUint8(i + 3), data.getUint8(i), data.getUint8(i + 1), data.getUint8(i + 2));
  });
  return color!;
}

/// Key of the RepaintBoundary wrapping the card in pixel tests.
const Key _boundary = Key("boundary");

/// Pumps a 200 dp wide card, wrapped in a RepaintBoundary, whose only row is
/// built by [lastRow] from the ambient ColorScheme.
Future<void> _pumpWithLastRow(WidgetTester tester, Widget Function(ColorScheme cs) lastRow) {
  return pumpApp(
    tester,
    Builder(
      builder: (BuildContext context) => RepaintBoundary(
        key: _boundary,
        child: SectionCard(title: "Section", children: <Widget>[lastRow(Theme.of(context).colorScheme)]),
      ),
    ),
    surfaceSize: const Size(200, 400),
  );
}

/// Checks that the bottom-left corner arc still shows the border, painted
/// over the last row, rather than the row's `primary` fill. Both sampled
/// pixels sit on the 1 dp border stroke of a radius-12 arc; only the bottom
/// one is covered by a row.
Future<void> _expectBottomArcIntact(WidgetTester tester) async {
  final double height = tester.getSize(find.byKey(_boundary)).height;
  final Color topArc = await _pixelAt(tester, find.byKey(_boundary), const Offset(4, 3));
  final Color bottomArc = await _pixelAt(tester, find.byKey(_boundary), Offset(4, height - 4));
  expect(_channelGap(bottomArc, _scheme(tester).primary), greaterThan(0.2));
  expect(_channelGap(bottomArc, topArc), lessThan(0.1));
}

/// Largest per-channel (r, g, b) difference between [a] and [b], in 0..1.
double _channelGap(Color a, Color b) {
  final List<double> gaps = <double>[(a.r - b.r).abs(), (a.g - b.g).abs(), (a.b - b.b).abs()];
  return gaps.reduce((double x, double y) => x > y ? x : y);
}

void main() {
  group("structure", () {
    testWidgets("renders the title then every row in order", (WidgetTester tester) async {
      await pumpApp(tester, _card);

      expect(find.text("Section"), findsOneWidget);
      expect(find.text("First row"), findsOneWidget);
      expect(find.text("Second row"), findsOneWidget);
      final double titleY = tester.getTopLeft(find.text("Section")).dy;
      final double firstY = tester.getTopLeft(find.text("First row")).dy;
      final double secondY = tester.getTopLeft(find.text("Second row")).dy;
      expect(titleY, lessThan(firstY));
      expect(firstY, lessThan(secondY));
    });

    testWidgets("renders the title verbatim, without changing its case", (WidgetTester tester) async {
      await pumpApp(tester, const SectionCard(title: "Mixed Case title", children: <Widget>[]));

      expect(find.text("Mixed Case title"), findsOneWidget);
      expect(find.text("MIXED CASE TITLE"), findsNothing);
    });

    testWidgets("draws one divider between the title and the first row", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const SectionCard(title: "Section", children: <Widget>[ListTile(title: Text("Row"))]),
      );

      final Finder divider = _inCard(find.byType(Divider));
      expect(divider, findsOneWidget);
      expect(tester.getTopLeft(divider).dy, greaterThan(tester.getBottomLeft(find.text("Section")).dy));
      expect(tester.getBottomLeft(divider).dy, lessThanOrEqualTo(tester.getTopLeft(find.byType(ListTile)).dy));
      expect(tester.getSize(divider).height, 1);
    });

    testWidgets("renders only the title and the divider without rows", (WidgetTester tester) async {
      await pumpApp(tester, const SectionCard(title: "Section", children: <Widget>[]));

      expect(tester.takeException(), isNull);
      expect(find.text("Section"), findsOneWidget);
      expect(_inCard(find.byType(Divider)), findsOneWidget);
      expect(_inCard(find.byType(ListTile)), findsNothing);
    });
  });

  group("layout", () {
    testWidgets("pads the title 16 dp on the top and left, 12 dp above the divider", (WidgetTester tester) async {
      await pumpApp(tester, _card);

      final Offset cardTopLeft = tester.getTopLeft(find.byType(SectionCard));
      final Offset titleTopLeft = tester.getTopLeft(find.text("Section"));
      expect(titleTopLeft.dx - cardTopLeft.dx, _border + kDefaultPadding * 2);
      expect(titleTopLeft.dy - cardTopLeft.dy, _border + kDefaultPadding * 2);
      final double gap = tester.getTopLeft(_inCard(find.byType(Divider)).first).dy -
          tester.getBottomLeft(find.text("Section")).dy;
      expect(gap, kDefaultPadding * 1.5);
    });

    testWidgets("rows run edge to edge inside the border, right under the divider", (WidgetTester tester) async {
      await pumpApp(tester, _card, surfaceSize: const Size(360, 640));

      final Finder firstRow = find.widgetWithText(ListTile, "First row");
      expect(tester.getTopLeft(firstRow).dy, tester.getBottomLeft(_inCard(find.byType(Divider)).first).dy);
      expect(tester.getSize(firstRow).width, 360 - 2 * _border);
      expect(tester.getTopLeft(firstRow).dx, _border);
    });

    testWidgets("fills the available width and hugs its content height", (WidgetTester tester) async {
      await pumpApp(tester, _card, surfaceSize: const Size(360, 640));

      final Size size = tester.getSize(find.byType(SectionCard));
      expect(size.width, 360);
      expect(size.height, lessThan(640));
      expect(tester.getBottomLeft(find.byType(SectionCard)).dy,
          tester.getBottomLeft(find.widgetWithText(ListTile, "Second row")).dy + _border);
    });
  });

  group("style", () {
    testWidgets("uses the ColorScheme panel tokens, radius 12 and anti-aliased clipping",
        (WidgetTester tester) async {
      await pumpApp(tester, _card);

      final ColorScheme cs = _scheme(tester);
      final BoxDecoration decoration = _decoration(tester);
      final BoxDecoration foreground = _foreground(tester);
      expect(decoration.color, cs.surfaceContainerLow);
      expect(decoration.borderRadius, BorderRadius.circular(12));
      expect(foreground.border, Border.all(color: cs.outlineVariant));
      expect(foreground.borderRadius, BorderRadius.circular(12));
      expect(_panel(tester).clipBehavior, Clip.antiAlias);
    });

    testWidgets("paints the border in the foreground, above the rows", (WidgetTester tester) async {
      await pumpApp(tester, _card);

      expect(_decoration(tester).border, isNull);
      expect(_foreground(tester).border, isNotNull);
      expect(_panel(tester).padding, const EdgeInsets.all(_border));
    });

    testWidgets("a filled last row does not paint over the border's rounded bottom corners",
        (WidgetTester tester) async {
      await _pumpWithLastRow(
        tester,
        (ColorScheme cs) => ListTile(tileColor: cs.primary, title: const Text("Filled row")),
      );

      await _expectBottomArcIntact(tester);
    });

    testWidgets("a pressed last row's ink does not paint over the border's rounded bottom corners",
        (WidgetTester tester) async {
      await _pumpWithLastRow(
        tester,
        (ColorScheme cs) => InkWell(
          onTap: () {},
          highlightColor: cs.primary,
          splashFactory: NoSplash.splashFactory,
          child: const SizedBox(height: kMinTapTarget, child: Text("Pressed row")),
        ),
      );
      final TestGesture press = await tester.startGesture(tester.getCenter(find.text("Pressed row")));
      // Past the tap-down deadline, then through the highlight fade-in.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 500));

      await _expectBottomArcIntact(tester);
      await press.up();
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets("styles the title as a muted, tracked label", (WidgetTester tester) async {
      await pumpApp(tester, _card);

      final ThemeData theme = Theme.of(tester.element(find.byType(SectionCard)));
      final TextStyle style = tester.widget<Text>(find.text("Section")).style!;
      expect(style.fontSize, theme.textTheme.labelSmall!.fontSize);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.letterSpacing, 1.4);
      expect(style.color, theme.colorScheme.onSurfaceVariant);
    });

    testWidgets("follows the dark ColorScheme", (WidgetTester tester) async {
      await pumpApp(tester, _card, theme: AppTheme.dark());

      final ColorScheme cs = _scheme(tester);
      expect(cs.brightness, Brightness.dark);
      final BoxDecoration decoration = _decoration(tester);
      expect(decoration.color, cs.surfaceContainerLow);
      expect((_foreground(tester).border! as Border).top.color, cs.outlineVariant);
      expect(tester.widget<Text>(find.text("Section")).style!.color, cs.onSurfaceVariant);
      expect(tester.takeException(), isNull);
    });
  });

  group("accessibility", () {
    testWidgets("exposes the title as a semantic header", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _card);

      expect(
        tester.getSemantics(find.text("Section")),
        matchesSemantics(isHeader: true, label: "Section", textDirection: TextDirection.ltr),
      );
      handle.dispose();
    });
  });

  group("interaction", () {
    testWidgets("tappable rows still receive taps", (WidgetTester tester) async {
      int tileTaps = 0;
      int inkTaps = 0;
      await pumpApp(
        tester,
        SectionCard(
          title: "Section",
          children: <Widget>[
            ListTile(title: const Text("Tile row"), onTap: () => tileTaps++),
            InkWell(
              onTap: () => inkTaps++,
              child: const SizedBox(height: kMinTapTarget, child: Text("Ink row")),
            ),
          ],
        ),
      );

      await tester.tap(find.text("Tile row"));
      await tester.tap(find.text("Ink row"));
      expect(tileTaps, 1);
      expect(inkTaps, 1);
    });

    testWidgets("row ripples are painted on an ink surface inside the clipped panel",
        (WidgetTester tester) async {
      await pumpApp(
        tester,
        SectionCard(
          title: "Section",
          children: <Widget>[
            InkWell(onTap: () {}, child: const SizedBox(height: kMinTapTarget, child: Text("Ink row"))),
          ],
        ),
      );

      final Material inkSurface = tester.widget<Material>(
        find.ancestor(of: find.byType(InkWell), matching: find.byType(Material)).first,
      );
      expect(inkSurface.type, MaterialType.transparency);
      expect(_inCard(find.byWidget(inkSurface)), findsOneWidget);
      expect(find.descendant(of: find.byWidget(_panel(tester)), matching: find.byWidget(inkSurface)),
          findsOneWidget);
    });
  });

  group("motion", () {
    testWidgets("the ink surface does not animate under reduced motion", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: _card,
          ),
        ),
      );

      final Material inkSurface = tester.widget<Material>(_inCard(find.byType(Material)).first);
      expect(inkSurface.animationDuration, Duration.zero);
    });

    testWidgets("the ink surface keeps the theme-change duration otherwise", (WidgetTester tester) async {
      await pumpApp(tester, _card);

      final Material inkSurface = tester.widget<Material>(_inCard(find.byType(Material)).first);
      expect(inkSurface.animationDuration, kThemeChangeDuration);
    });
  });
}

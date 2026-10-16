// icon_list_panel_test.dart
//
// Widget tests for IconListPanel: header and rows in order, dividers, the
// optional tile / tag / subtitle, the empty placeholder (default key and
// custom label), the composed StatusPill and the tile tones (and the tile
// icon contrast for every tone, light and dark), semantics (header, one merged node per row,
// decorative icon), the panel tokens, narrow widths and large text without
// overflow (the tag wraps under a long title), and the dark theme.

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/IconListPanel/index.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _emptyKey = "custom.icon_list_panel.empty";

const List<IconListPanelItem> _items = <IconListPanelItem>[
  IconListPanelItem(
    title: "First",
    subtitle: "12 entries · 3 open",
    icon: Icons.bolt_outlined,
    tag: "Urgent",
    tone: StatusTone.danger,
  ),
  IconListPanelItem(
    title: "Second",
    subtitle: "8 entries · 1 open",
    icon: Icons.schedule_outlined,
    tag: "Pending",
    tone: StatusTone.warning,
  ),
  IconListPanelItem(title: "Third", subtitle: "2 entries", icon: Icons.label_outline),
];

const IconListPanel _panel = IconListPanel(title: "Open items", items: _items);

Finder _inPanel(Finder matching) => find.descendant(of: find.byType(IconListPanel), matching: matching);

/// The merged row node holding [text].
Finder _rowOf(String text) => find.ancestor(of: find.text(text), matching: find.byType(MergeSemantics));

/// The icon tile (DecoratedBox) around [icon].
DecoratedBox _tile(WidgetTester tester, IconData icon) {
  return tester.widget<DecoratedBox>(
    find.ancestor(of: find.byIcon(icon), matching: find.byType(DecoratedBox)).first,
  );
}

ToneColors _tone(WidgetTester tester, StatusTone tone) {
  return StatusTones.colorsOf(tester.element(find.byType(IconListPanel)), tone);
}

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(IconListPanel))).colorScheme;

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double hi = la > lb ? la : lb;
  final double lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Pumps [panel] in a [width] dp wide column.
Future<void> _pump(WidgetTester tester, Widget panel, {double width = 480, ThemeData? theme}) {
  return pumpApp(
    tester,
    Align(alignment: Alignment.topLeft, child: SizedBox(width: width, child: panel)),
    surfaceSize: Size(width, 800),
    theme: theme,
  );
}

void main() {
  _structureTests();
  _optionalPartTests();
  _emptyTests();
  _toneTests();
  _semanticsTests();
  _layoutTests();
  _themeTests();
}

void _structureTests() {
  group("structure", () {
    testWidgets("renders the title, then each row's title, tag and subtitle in order", (WidgetTester tester) async {
      await _pump(tester, _panel);

      expect(find.text("Open items"), findsOneWidget);
      for (final String text in <String>["First", "Urgent", "12 entries · 3 open", "Second", "Pending", "Third"]) {
        expect(find.text(text), findsOneWidget);
      }
      final double headerY = tester.getTopLeft(find.text("Open items")).dy;
      final double firstY = tester.getTopLeft(find.text("First")).dy;
      final double secondY = tester.getTopLeft(find.text("Second")).dy;
      final double thirdY = tester.getTopLeft(find.text("Third")).dy;
      expect(headerY, lessThan(firstY));
      expect(firstY, lessThan(secondY));
      expect(secondY, lessThan(thirdY));
      expect(tester.getTopLeft(find.text("12 entries · 3 open")).dy, greaterThan(firstY));
    });

    testWidgets("renders the header title verbatim", (WidgetTester tester) async {
      await _pump(tester, const IconListPanel(title: "Mixed Case title", items: _items));

      expect(find.text("Mixed Case title"), findsOneWidget);
    });

    testWidgets("draws one divider fewer than rows", (WidgetTester tester) async {
      await _pump(tester, _panel);
      expect(_inPanel(find.byType(Divider)), findsNWidgets(2));
      expect(tester.widget<Divider>(_inPanel(find.byType(Divider)).first).height, 16);

      await _pump(tester, IconListPanel(title: "One", items: _items.sublist(0, 1)));
      expect(_inPanel(find.byType(Divider)), findsNothing);
      expect(_inPanel(find.byType(MergeSemantics)), findsOneWidget);
    });

    testWidgets("the icon tile is 36 x 36 with an 18 dp icon", (WidgetTester tester) async {
      await _pump(tester, _panel);

      final Finder tile = find.ancestor(of: find.byIcon(Icons.bolt_outlined), matching: find.byType(SizedBox)).first;
      expect(tester.getSize(tile), const Size(36, 36));
      expect(tester.widget<Icon>(find.byIcon(Icons.bolt_outlined)).size, 18);
    });
  });
}

void _optionalPartTests() {
  group("optional parts", () {
    testWidgets("a null or empty tag draws no pill", (WidgetTester tester) async {
      await _pump(
        tester,
        const IconListPanel(
          title: "Items",
          items: <IconListPanelItem>[
            IconListPanelItem(title: "No tag", icon: Icons.label_outline),
            IconListPanelItem(title: "Empty tag", tag: "", icon: Icons.label_outline),
          ],
        ),
      );

      expect(_inPanel(find.byType(StatusPill)), findsNothing);
    });

    testWidgets("a null or empty subtitle draws no second line", (WidgetTester tester) async {
      await _pump(
        tester,
        const IconListPanel(
          title: "Items",
          items: <IconListPanelItem>[
            IconListPanelItem(title: "No subtitle"),
            IconListPanelItem(title: "Empty subtitle", subtitle: ""),
          ],
        ),
      );

      expect(find.descendant(of: _rowOf("No subtitle"), matching: find.byType(Text)), findsOneWidget);
      expect(find.descendant(of: _rowOf("Empty subtitle"), matching: find.byType(Text)), findsOneWidget);
    });

    testWidgets("a null icon draws no tile and the title starts at the row edge", (WidgetTester tester) async {
      await _pump(
        tester,
        const IconListPanel(
          title: "Items",
          items: <IconListPanelItem>[
            IconListPanelItem(title: "With icon", icon: Icons.label_outline),
            IconListPanelItem(title: "Without icon"),
          ],
        ),
      );

      expect(find.descendant(of: _rowOf("Without icon"), matching: find.byType(Icon)), findsNothing);
      expect(find.descendant(of: _rowOf("With icon"), matching: find.byType(Icon)), findsOneWidget);
      final double rowLeft = tester.getTopLeft(_rowOf("Without icon")).dx;
      expect(tester.getTopLeft(find.text("Without icon")).dx, rowLeft);
      // 36 dp tile + 12 dp gap before the text.
      expect(tester.getTopLeft(find.text("With icon")).dx - rowLeft, 48);
    });
  });
}

void _emptyTests() {
  group("empty list", () {
    testWidgets("shows the default placeholder key and no row", (WidgetTester tester) async {
      await _pump(tester, const IconListPanel(title: "Items", items: <IconListPanelItem>[]));

      expect(find.text("Items"), findsOneWidget);
      expect(find.text(_emptyKey), findsOneWidget);
      expect(_inPanel(find.byType(MergeSemantics)), findsNothing);
      expect(_inPanel(find.byType(Divider)), findsNothing);
      final Text placeholder = tester.widget<Text>(find.text(_emptyKey));
      expect(placeholder.style?.color, _scheme(tester).onSurfaceVariant);
    });

    testWidgets("a custom emptyLabel replaces the default", (WidgetTester tester) async {
      await _pump(
        tester,
        const IconListPanel(title: "Items", items: <IconListPanelItem>[], emptyLabel: "Nothing flagged"),
      );

      expect(find.text("Nothing flagged"), findsOneWidget);
      expect(find.text(_emptyKey), findsNothing);
    });

    testWidgets("the placeholder is not shown when there are rows", (WidgetTester tester) async {
      await _pump(tester, const IconListPanel(title: "Items", items: _items, emptyLabel: "Nothing flagged"));

      expect(find.text("Nothing flagged"), findsNothing);
      expect(find.text(_emptyKey), findsNothing);
    });
  });
}

void _toneTests() {
  group("tones", () {
    testWidgets("the tag is a dense StatusPill in the item tone", (WidgetTester tester) async {
      await _pump(tester, _panel);

      final StatusPill urgent = tester.widget<StatusPill>(
        find.ancestor(of: find.text("Urgent"), matching: find.byType(StatusPill)),
      );
      expect(urgent.label, "Urgent");
      expect(urgent.tone, StatusTone.danger);
      expect(urgent.dense, isTrue);
      final StatusPill pending = tester.widget<StatusPill>(
        find.ancestor(of: find.text("Pending"), matching: find.byType(StatusPill)),
      );
      expect(pending.tone, StatusTone.warning);
    });

    testWidgets("the tile uses the tone container fill and onContainer icon", (WidgetTester tester) async {
      await _pump(tester, _panel);

      final ToneColors danger = _tone(tester, StatusTone.danger);
      expect((_tile(tester, Icons.bolt_outlined).decoration as BoxDecoration).color, danger.container);
      expect(tester.widget<Icon>(find.byIcon(Icons.bolt_outlined)).color, danger.onContainer);
      final ToneColors warning = _tone(tester, StatusTone.warning);
      expect((_tile(tester, Icons.schedule_outlined).decoration as BoxDecoration).color, warning.container);
      expect(tester.widget<Icon>(find.byIcon(Icons.schedule_outlined)).color, warning.onContainer);
    });

    testWidgets("the default tone is neutral (cs.onSurface on cs.surfaceContainerHighest)", (WidgetTester tester) async {
      await _pump(tester, _panel);

      final ColorScheme cs = _scheme(tester);
      expect(tester.widget<Icon>(find.byIcon(Icons.label_outline)).color, cs.onSurface);
      expect((_tile(tester, Icons.label_outline).decoration as BoxDecoration).color, cs.surfaceContainerHighest);
    });

    for (final ThemeData theme in <ThemeData>[AppTheme.light(), AppTheme.dark()]) {
      testWidgets("the tile icon keeps at least 4.5:1 on its tile for every tone (${theme.brightness.name})",
          (WidgetTester tester) async {
        await _pump(
          tester,
          IconListPanel(
            title: "Tones",
            items: <IconListPanelItem>[
              for (final StatusTone tone in StatusTone.values)
                IconListPanelItem(title: tone.name, icon: tone.icon, tone: tone),
            ],
          ),
          theme: theme,
        );

        for (final StatusTone tone in StatusTone.values) {
          final Icon icon = tester.widget<Icon>(find.byIcon(tone.icon));
          final Color fill = (_tile(tester, tone.icon).decoration as BoxDecoration).color!;
          expect(_contrast(icon.color!, fill), greaterThanOrEqualTo(4.5), reason: tone.name);
        }
      });
    }
  });
}

void _semanticsTests() {
  group("semantics", () {
    testWidgets("the header title is a semantic header", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _panel);

      final SemanticsNode header = tester.getSemantics(find.text("Open items"));
      expect(header.label, "Open items");
      expect(header.flagsCollection.isHeader, isTrue);
      handle.dispose();
    });

    testWidgets("each row is one node reading the title, the tag and the subtitle", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _panel);

      final SemanticsNode row = tester.getSemantics(_rowOf("First"));
      expect(row.label, contains("First"));
      expect(row.label, contains("Urgent"));
      expect(row.label, contains("12 entries · 3 open"));
      expect(row.label.indexOf("First"), lessThan(row.label.indexOf("Urgent")));
      expect(tester.getSemantics(find.text("Urgent")), same(row));
      expect(tester.getSemantics(find.text("12 entries · 3 open")), same(row));
      handle.dispose();
    });

    testWidgets("the tile icon is decorative", (WidgetTester tester) async {
      await _pump(tester, _panel);

      expect(
        find.ancestor(of: find.byIcon(Icons.bolt_outlined), matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
    });
  });
}

void _layoutTests() {
  group("layout", () {
    testWidgets("panel and header use the ColorScheme tokens", (WidgetTester tester) async {
      await _pump(tester, _panel);

      final ColorScheme cs = _scheme(tester);
      final Container panel = tester.widget<Container>(_inPanel(find.byType(Container)).first);
      expect((panel.decoration! as BoxDecoration).color, cs.surfaceContainerLow);
      expect((panel.decoration! as BoxDecoration).borderRadius, BorderRadius.circular(10));
      expect(((panel.foregroundDecoration! as BoxDecoration).border! as Border).top.color, cs.outlineVariant);
      expect(panel.clipBehavior, Clip.antiAlias);
      final Container header = tester.widget<Container>(
        find.ancestor(of: find.text("Open items"), matching: find.byType(Container)).first,
      );
      final BoxDecoration headerDecoration = header.decoration! as BoxDecoration;
      expect(headerDecoration.color, cs.surfaceContainerHigh);
      expect((headerDecoration.border! as Border).bottom.color, cs.outlineVariant);
      expect(tester.widget<Text>(find.text("Open items")).style?.color, cs.onSurfaceVariant);
      expect(tester.widget<Text>(find.text("First")).style?.color, cs.onSurface);
      expect(tester.widget<Text>(find.text("12 entries · 3 open")).style?.color, cs.onSurfaceVariant);
    });

    testWidgets("a short title keeps its tag on the same line", (WidgetTester tester) async {
      await _pump(tester, _panel);

      final Rect title = tester.getRect(find.text("First"));
      final Rect tag = tester.getRect(find.ancestor(of: find.text("Urgent"), matching: find.byType(StatusPill)));
      expect(tag.left, greaterThan(title.right));
      expect(tag.center.dy, moreOrLessEquals(title.center.dy, epsilon: 1));
    });

    testWidgets("a long title is ellipsised and its tag wraps under it at 320 dp", (WidgetTester tester) async {
      final String longTitle = List<String>.filled(30, "word").join(" ");
      await _pump(
        tester,
        IconListPanel(
          title: "Items",
          items: <IconListPanelItem>[
            IconListPanelItem(
              title: longTitle,
              subtitle: List<String>.filled(20, "detail").join(" "),
              icon: Icons.label_outline,
              tag: List<String>.filled(12, "tag").join(" "),
              tone: StatusTone.info,
            ),
          ],
        ),
        width: 320,
      );

      expect(tester.takeException(), isNull);
      final Text title = tester.widget<Text>(find.text(longTitle));
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);
      expect(tester.renderObject<RenderParagraph>(find.text(longTitle)).didExceedMaxLines, isTrue);
      final Rect titleRect = tester.getRect(find.text(longTitle));
      final Rect tagRect = tester.getRect(_inPanel(find.byType(StatusPill)));
      expect(tagRect.top, greaterThanOrEqualTo(titleRect.bottom));
      expect(tagRect.right, lessThanOrEqualTo(320));
    });

    testWidgets("lays out at 2x text scale in 320 dp without overflow", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Align(alignment: Alignment.topLeft, child: SizedBox(width: 320, child: _panel)),
        ),
        surfaceSize: const Size(320, 1200),
      );

      expect(tester.takeException(), isNull);
      expect(find.text("Urgent"), findsOneWidget);
    });
  });
}

void _themeTests() {
  group("themes", () {
    testWidgets("renders under the dark theme with the dark tokens", (WidgetTester tester) async {
      await _pump(tester, _panel, theme: AppTheme.dark());

      expect(tester.takeException(), isNull);
      final ColorScheme cs = _scheme(tester);
      expect(cs.brightness, Brightness.dark);
      final Container panel = tester.widget<Container>(_inPanel(find.byType(Container)).first);
      expect((panel.decoration! as BoxDecoration).color, cs.surfaceContainerLow);
      final ToneColors danger = _tone(tester, StatusTone.danger);
      expect(tester.widget<Icon>(find.byIcon(Icons.bolt_outlined)).color, danger.onContainer);
      expect((_tile(tester, Icons.bolt_outlined).decoration as BoxDecoration).color, danger.container);
      expect(find.text("Urgent"), findsOneWidget);
    });
  });
}

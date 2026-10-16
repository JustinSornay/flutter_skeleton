// swimlane_card_test.dart
//
// Widget tests for SwimlaneCard: header (title, subtitle, trailing slot,
// ellipsis), one tile per item with its value / caption / StatusPill badge,
// generic selection callback (tap and keyboard), read-only lane, tile
// semantics, selected outline, fill and value colours (tone and primary
// fallback), value / caption contrast on the selected fill for every tone in
// both themes, reduced motion, horizontal scrolling, value scale-down, text
// scaling, the tile width (custom and assert), tap target guidelines and the
// dark theme.

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";
import "package:flutter_skeleton/widgets/custom/SwimlaneCard/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

enum _Variant { first, second, third }

const String _title = "VARIANTS";

const List<SwimlaneItem<_Variant>> _items = <SwimlaneItem<_Variant>>[
  SwimlaneItem<_Variant>(id: _Variant.first, value: "0.87", label: "Plan A", tone: StatusTone.success),
  SwimlaneItem<_Variant>(id: _Variant.second, value: "0.73", label: "Plan B", badge: "Watch", tone: StatusTone.warning),
  SwimlaneItem<_Variant>(id: _Variant.third, value: "0.55", label: "Plan C", badge: "Capped"),
];

/// A runtime (non-const) width below kMinTapTarget, so the assert runs at
/// runtime instead of failing const evaluation at compile time.
double _narrowWidth() => kMinTapTarget - kDefaultPadding;

SwimlaneCard<_Variant> _card({
  List<SwimlaneItem<_Variant>> items = _items,
  _Variant? selectedId,
  ValueChanged<_Variant>? onSelected,
  String title = _title,
  String? subtitle,
  Widget? trailing,
}) {
  return SwimlaneCard<_Variant>(
    title: title,
    subtitle: subtitle,
    trailing: trailing,
    items: items,
    selectedId: selectedId,
    onSelected: onSelected,
  );
}

/// The animated box of the tile showing [value].
Finder _tile(String value) => find.ancestor(of: find.text(value), matching: find.byType(AnimatedContainer));

BoxDecoration _decoration(WidgetTester tester, String value) {
  return tester.widget<AnimatedContainer>(_tile(value)).decoration! as BoxDecoration;
}

BorderSide _outline(WidgetTester tester, String value) => (_decoration(tester, value).border! as Border).top;

InkWell _inkWell(WidgetTester tester, String value) {
  return tester.widget<InkWell>(find.ancestor(of: find.text(value), matching: find.byType(InkWell)));
}

Color? _textColor(WidgetTester tester, String text) => tester.widget<Text>(find.text(text)).style?.color;

BuildContext _context(WidgetTester tester) => tester.element(find.byType(SwimlaneCard<_Variant>));

ColorScheme _scheme(WidgetTester tester) => Theme.of(_context(tester)).colorScheme;

ToneColors _tone(WidgetTester tester, StatusTone tone) => StatusTones.colorsOf(_context(tester), tone);

/// Opaque fill of a selected tile: [accent] at 8 % over `cs.surfaceContainer`.
Color _selectedFill(WidgetTester tester, Color accent) {
  return Color.alphaBlend(accent.withValues(alpha: 0.08), _scheme(tester).surfaceContainer);
}

/// Colour of the card behind the tiles.
Color _cardColor(WidgetTester tester) {
  final Finder card = find.descendant(of: find.byType(SwimlaneCard<_Variant>), matching: find.byType(Container));
  return (tester.widget<Container>(card.first).decoration! as BoxDecoration).color!;
}

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
}

/// Wraps [child] with a MediaQuery override built from the ambient one.
Widget _withMediaQuery(Widget child, MediaQueryData Function(MediaQueryData data) update) {
  return Builder(
    builder: (BuildContext context) => MediaQuery(data: update(MediaQuery.of(context)), child: child),
  );
}

void main() {
  _layoutTests();
  _selectionTests();
  _semanticsTests();
  _contrastTests();

  testWidgets("renders in the dark theme with tone colours", (WidgetTester tester) async {
    await pumpApp(tester, _card(subtitle: "Subtitle", selectedId: _Variant.first), theme: AppTheme.dark());

    expect(tester.takeException(), isNull);
    expect(_scheme(tester).brightness, Brightness.dark);
    final Color foreground = _tone(tester, StatusTone.success).foreground;
    expect(_outline(tester, "0.87").color, foreground);
    expect(_textColor(tester, "0.87"), foreground);
  });
}

void _layoutTests() {
  group("SwimlaneCard layout", () {
    testWidgets("renders the title and one tile per item with value and caption", (WidgetTester tester) async {
      await pumpApp(tester, _card());

      expect(find.text(_title), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsNWidgets(_items.length));
      for (final SwimlaneItem<_Variant> item in _items) {
        expect(find.text(item.value), findsOneWidget);
        expect(find.text(item.label), findsOneWidget);
      }
    });

    testWidgets("shows the subtitle only when it is set", (WidgetTester tester) async {
      await pumpApp(tester, _card());
      expect(find.text("Subtitle"), findsNothing);

      await pumpApp(tester, _card(subtitle: "Subtitle"));
      expect(find.text("Subtitle"), findsOneWidget);
    });

    testWidgets("badges are dense StatusPills in the item tone, neutral without one", (WidgetTester tester) async {
      await pumpApp(tester, _card());

      expect(find.byType(StatusPill), findsNWidgets(2));
      final StatusPill watch = tester.widget<StatusPill>(find.widgetWithText(StatusPill, "Watch"));
      expect(watch.dense, isTrue);
      expect(watch.tone, StatusTone.warning);
      final StatusPill capped = tester.widget<StatusPill>(find.widgetWithText(StatusPill, "Capped"));
      expect(capped.tone, StatusTone.neutral);
    });

    testWidgets("an empty badge is hidden", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _card(items: const <SwimlaneItem<_Variant>>[SwimlaneItem<_Variant>(id: _Variant.first, value: "1", label: "A", badge: "")]),
      );

      expect(find.byType(StatusPill), findsNothing);
    });

    testWidgets("renders the trailing widget in the header", (WidgetTester tester) async {
      await pumpApp(tester, _card(trailing: const Text("Help")));

      expect(find.text("Help"), findsOneWidget);
      expect(tester.getCenter(find.text("Help")).dy, closeTo(tester.getCenter(find.text(_title)).dy, 1));
    });

    testWidgets("a long title is ellipsized and keeps the trailing widget on screen", (WidgetTester tester) async {
      final String longTitle = List<String>.filled(40, "LONG TITLE").join(" ");
      await pumpApp(
        tester,
        _card(title: longTitle, trailing: const SizedBox(key: Key("trailing"), width: kMinTapTarget, height: kMinTapTarget)),
        surfaceSize: const Size(320, 400),
      );

      expect(tester.takeException(), isNull);
      final Text title = tester.widget<Text>(find.text(longTitle));
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);
      final Rect card = tester.getRect(find.byType(SwimlaneCard<_Variant>));
      expect(tester.getRect(find.byKey(const Key("trailing"))).right, lessThanOrEqualTo(card.right));
    });

    testWidgets("tiles are tileWidth wide and the lane 96 dp tall", (WidgetTester tester) async {
      await pumpApp(tester, _card());

      expect(tester.getSize(_tile("0.87")), const Size(80, kDefaultPadding * 12));
    });

    testWidgets("a custom tileWidth sizes every tile", (WidgetTester tester) async {
      await pumpApp(tester, const SwimlaneCard<_Variant>(title: _title, items: _items, tileWidth: 120));

      for (final SwimlaneItem<_Variant> item in _items) {
        expect(tester.getSize(_tile(item.value)).width, 120);
      }
    });

    testWidgets("a long value scales down inside the tile", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _card(items: const <SwimlaneItem<_Variant>>[SwimlaneItem<_Variant>(id: _Variant.first, value: "1 234 567 €", label: "A")]),
      );

      expect(tester.takeException(), isNull);
      expect(find.ancestor(of: find.text("1 234 567 €"), matching: find.byType(FittedBox)), findsOneWidget);
      expect(tester.getSize(find.text("1 234 567 €")).width, greaterThan(80));
      final Rect value = tester.getRect(find.ancestor(of: find.text("1 234 567 €"), matching: find.byType(FittedBox)));
      expect(value.width, lessThanOrEqualTo(80));
    });

    testWidgets("the lane grows with the text scale and nothing overflows", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _withMediaQuery(_card(), (MediaQueryData data) => data.copyWith(textScaler: const TextScaler.linear(1.5))),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(ListView)).height, closeTo(kDefaultPadding * 12 * 1.5, 0.01));
    });

    testWidgets("many tiles scroll horizontally and the last one can be selected", (WidgetTester tester) async {
      final List<int> selected = <int>[];
      final List<SwimlaneItem<int>> items = List<SwimlaneItem<int>>.generate(
        12,
        (int index) => SwimlaneItem<int>(id: index, value: "$index", label: "Item $index"),
      );
      await pumpApp(
        tester,
        SwimlaneCard<int>(title: _title, items: items, onSelected: selected.add),
        surfaceSize: const Size(320, 400),
      );

      expect(tester.takeException(), isNull);
      expect(find.text("Item 11"), findsNothing);
      await tester.scrollUntilVisible(
        find.text("Item 11"),
        100,
        scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)),
      );
      await tester.tap(find.text("Item 11"));
      expect(selected, <int>[11]);
    });

    testWidgets("tileWidth below kMinTapTarget is rejected", (WidgetTester tester) async {
      expect(
        () => SwimlaneCard<int>(title: _title, items: const <SwimlaneItem<int>>[], tileWidth: _narrowWidth()),
        throwsAssertionError,
      );
    });
  });
}

void _selectionTests() {
  group("SwimlaneCard selection", () {
    testWidgets("tapping a tile reports its id once", (WidgetTester tester) async {
      final List<_Variant> selected = <_Variant>[];
      await pumpApp(tester, _card(onSelected: selected.add));

      await tester.tap(find.text("Plan B"));
      expect(selected, <_Variant>[_Variant.second]);
    });

    testWidgets("a focused tile is activated from the keyboard", (WidgetTester tester) async {
      final List<_Variant> selected = <_Variant>[];
      await pumpApp(tester, _card(onSelected: selected.add));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, <_Variant>[_Variant.first]);
    });

    testWidgets("without onSelected the tiles are read-only", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _card(selectedId: _Variant.first));

      expect(_inkWell(tester, "0.87").onTap, isNull);
      await tester.tap(find.text("Plan A"));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSemantics(find.bySemanticsLabel("Plan A, 0.87")),
        isSemantics(isButton: false, hasTapAction: false, hasSelectedState: true, isSelected: true),
      );
      handle.dispose();
    });

    testWidgets("the selected tile with a tone uses the tone foreground", (WidgetTester tester) async {
      await pumpApp(tester, _card(selectedId: _Variant.second));

      final Color foreground = _tone(tester, StatusTone.warning).foreground;
      expect(_outline(tester, "0.73").color, foreground);
      expect(_outline(tester, "0.73").width, 1.5);
      expect(_decoration(tester, "0.73").color, _selectedFill(tester, foreground));
      expect(_textColor(tester, "0.73"), foreground);
    });

    testWidgets("the selected tile without a tone uses cs.primary", (WidgetTester tester) async {
      await pumpApp(tester, _card(selectedId: _Variant.third));

      final ColorScheme cs = _scheme(tester);
      expect(_outline(tester, "0.55").color, cs.primary);
      expect(_decoration(tester, "0.55").color, _selectedFill(tester, cs.primary));
      expect(_textColor(tester, "0.55"), cs.onSurface);
    });

    testWidgets("unselected tiles keep a transparent outline of the same width", (WidgetTester tester) async {
      await pumpApp(tester, _card(selectedId: _Variant.second));

      final ColorScheme cs = _scheme(tester);
      expect(_outline(tester, "0.87").color, Colors.transparent);
      expect(_outline(tester, "0.87").width, 1.5);
      expect(_decoration(tester, "0.87").color, cs.surfaceContainer);
      expect(_textColor(tester, "0.87"), _tone(tester, StatusTone.success).foreground);
    });

    testWidgets("a null or unknown selectedId highlights no tile", (WidgetTester tester) async {
      await pumpApp(tester, _card());
      for (final SwimlaneItem<_Variant> item in _items) {
        expect(_outline(tester, item.value).color, Colors.transparent);
      }

      await pumpApp(
        tester,
        _card(items: _items.sublist(0, 2), selectedId: _Variant.third),
      );
      for (final SwimlaneItem<_Variant> item in _items.sublist(0, 2)) {
        expect(_outline(tester, item.value).color, Colors.transparent);
      }
    });

    testWidgets("the selection animates over kMotionShort", (WidgetTester tester) async {
      await pumpApp(tester, _card(selectedId: _Variant.first));

      final AnimatedContainer box = tester.widget<AnimatedContainer>(_tile("0.87"));
      expect(box.duration, kMotionShort);
      expect(box.curve, Curves.easeOutCubic);
    });

    testWidgets("reduced motion makes the selection instant", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _withMediaQuery(_card(selectedId: _Variant.first), (MediaQueryData data) => data.copyWith(disableAnimations: true)),
      );

      expect(tester.widget<AnimatedContainer>(_tile("0.87")).duration, Duration.zero);
    });
  });
}

void _semanticsTests() {
  group("SwimlaneCard semantics", () {
    testWidgets("each tile is one selectable button labelled label, value, badge", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _card(selectedId: _Variant.second, onSelected: (_Variant _) {}));

      expect(
        tester.getSemantics(find.bySemanticsLabel("Plan B, 0.73, Watch")),
        isSemantics(
          label: "Plan B, 0.73, Watch",
          isButton: true,
          isInMutuallyExclusiveGroup: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
          isFocusable: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel("Plan A, 0.87")),
        isSemantics(isButton: true, hasSelectedState: true, isSelected: false),
      );
      expect(find.bySemanticsLabel("Watch"), findsNothing);
      handle.dispose();
    });

    testWidgets("semanticsLabel replaces the composed label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        _card(
          items: const <SwimlaneItem<_Variant>>[
            SwimlaneItem<_Variant>(id: _Variant.first, value: "1", label: "A", semanticsLabel: "Spoken tile"),
          ],
        ),
      );

      expect(find.bySemanticsLabel("Spoken tile"), findsOneWidget);
      expect(find.bySemanticsLabel("A, 1"), findsNothing);
      handle.dispose();
    });

    testWidgets("tiles meet the tap target guidelines", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _card(onSelected: (_Variant _) {}));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });
}

/// A selected tile in every tone (and without one), in both themes: the fill
/// is opaque and the value and caption stay at least 4.5:1 on it.
void _contrastTests() {
  final Map<String, ThemeData Function()> themes = <String, ThemeData Function()>{
    "light": AppTheme.light,
    "dark": AppTheme.dark,
  };

  group("SwimlaneCard selected tile contrast", () {
    for (final MapEntry<String, ThemeData Function()> theme in themes.entries) {
      for (final StatusTone? tone in <StatusTone?>[null, ...StatusTone.values]) {
        testWidgets("${theme.key} theme, ${tone?.name ?? "no tone"}", (WidgetTester tester) async {
          final SwimlaneItem<_Variant> item = SwimlaneItem<_Variant>(id: _Variant.first, value: "0.87", label: "Plan A", tone: tone);
          await pumpApp(
            tester,
            _card(items: <SwimlaneItem<_Variant>>[item], selectedId: _Variant.first),
            theme: theme.value(),
          );

          final Color decoration = _decoration(tester, "0.87").color!;
          expect(decoration.a, 1.0);
          final Color fill = Color.alphaBlend(decoration, _cardColor(tester));
          expect(_contrast(_textColor(tester, "0.87")!, fill), greaterThanOrEqualTo(4.5));
          expect(_contrast(_textColor(tester, "Plan A")!, fill), greaterThanOrEqualTo(4.5));
        });
      }
    }
  });
}

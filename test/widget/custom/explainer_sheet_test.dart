// explainer_sheet_test.dart
//
// Widget tests for ExplainerSheet: title (default key, custom text, header
// semantics, style, centred wrapping), row order and truncation, dividers,
// the empty row (and its wrapping), optional caption / value, label / caption
// / value styles, tone colours, the badge slot, the "learn more" link
// (visibility, label, tap, 48 dp target, button semantics, no Material
// ancestor needed), merged row semantics, the content-only contract, hosting
// in a modal bottom sheet, short heights and the dark theme.

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/ExplainerSheet/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const List<ExplainerItem> _items = <ExplainerItem>[
  ExplainerItem(label: "First", tone: StatusTone.danger, value: "-18 %", caption: "Source A"),
  ExplainerItem(label: "Second", tone: StatusTone.warning, value: "-9 %"),
  ExplainerItem(label: "Third", tone: StatusTone.neutral),
  ExplainerItem(label: "Fourth", tone: StatusTone.info, value: "-1 %"),
];

Finder _inSheet(Finder matching) {
  return find.descendant(of: find.byType(ExplainerSheet), matching: matching);
}

/// Decorations of every circular dot in the sheet, top to bottom.
List<BoxDecoration> _dots(WidgetTester tester) {
  return tester
      .widgetList<DecoratedBox>(_inSheet(find.byType(DecoratedBox)))
      .map((DecoratedBox box) => box.decoration)
      .whereType<BoxDecoration>()
      .where((BoxDecoration decoration) => decoration.shape == BoxShape.circle)
      .toList();
}

Color? _textColor(WidgetTester tester, String text) {
  return tester.widget<Text>(find.text(text)).style?.color;
}

ToneColors _tone(WidgetTester tester, StatusTone tone) {
  return StatusTones.colorsOf(tester.element(find.byType(ExplainerSheet)), tone);
}

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(ExplainerSheet))).colorScheme;
}

/// Global horizontal extent of each laid-out line of [text], top to bottom.
List<({double left, double right})> _lines(WidgetTester tester, String text) {
  final Finder finder = find.text(text);
  final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(finder);
  final double origin = tester.getTopLeft(finder).dx;
  final Map<double, ({double left, double right})> byTop = <double, ({double left, double right})>{};
  for (final TextBox box in paragraph.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: text.length))) {
    final ({double left, double right})? line = byTop[box.top];
    byTop[box.top] = (
      left: line == null || box.left < line.left ? box.left : line.left,
      right: line == null || box.right > line.right ? box.right : line.right,
    );
  }
  final List<double> tops = byTop.keys.toList()..sort();
  return <({double left, double right})>[
    for (final double top in tops) (left: origin + byTop[top]!.left, right: origin + byTop[top]!.right),
  ];
}

void main() {
  group("title", () {
    testWidgets("defaults to the title key, as a header", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const ExplainerSheet(items: _items));

      expect(find.text("custom.explainer_sheet.title"), findsOneWidget);
      expect(
        tester.getSemantics(find.text("custom.explainer_sheet.title")),
        matchesSemantics(label: "custom.explainer_sheet.title", isHeader: true),
      );
      handle.dispose();
    });

    testWidgets("renders a custom title instead of the key", (WidgetTester tester) async {
      await pumpApp(tester, const ExplainerSheet(items: _items, title: "Why?"));

      expect(find.text("Why?"), findsOneWidget);
      expect(find.text("custom.explainer_sheet.title"), findsNothing);
    });

    testWidgets("is w700 onSurface and wraps centred at 320 dp", (WidgetTester tester) async {
      const String title = "Explanations of the result, in short";
      await pumpApp(tester, const ExplainerSheet(items: _items, title: title), surfaceSize: const Size(320, 640));

      expect(tester.takeException(), isNull);
      final TextStyle? style = tester.widget<Text>(find.text(title)).style;
      expect(style?.fontWeight, FontWeight.w700);
      expect(style?.color, _scheme(tester).onSurface);

      final List<({double left, double right})> lines = _lines(tester, title);
      expect(lines.length, greaterThan(1));
      // The last line is short, so only centring puts its middle on the axis.
      final ({double left, double right}) last = lines.last;
      const double contentWidth = 320 - kDefaultPadding * 6;
      expect(last.right - last.left, lessThan(contentWidth / 2));
      final double axis = tester.getCenter(find.byType(ExplainerSheet)).dx;
      expect((last.left + last.right) / 2, closeTo(axis, 0.5));
    });
  });

  group("rows", () {
    testWidgets("renders the first three items in order and drops the rest", (WidgetTester tester) async {
      await pumpApp(tester, const ExplainerSheet(items: _items));

      expect(find.text("Fourth"), findsNothing);
      final double first = tester.getTopLeft(find.text("First")).dy;
      final double second = tester.getTopLeft(find.text("Second")).dy;
      final double third = tester.getTopLeft(find.text("Third")).dy;
      expect(first, lessThan(second));
      expect(second, lessThan(third));
      expect(_dots(tester), hasLength(3));
    });

    testWidgets("maxItems limits the rendered rows", (WidgetTester tester) async {
      await pumpApp(tester, const ExplainerSheet(items: _items, maxItems: 1));

      expect(find.text("First"), findsOneWidget);
      expect(find.text("Second"), findsNothing);
      expect(_inSheet(find.byType(Divider)), findsNothing);
    });

    testWidgets("separates three rows with two outlineVariant dividers", (WidgetTester tester) async {
      await pumpApp(tester, const ExplainerSheet(items: _items));

      final Iterable<Divider> dividers = tester.widgetList<Divider>(_inSheet(find.byType(Divider)));
      expect(dividers, hasLength(2));
      for (final Divider divider in dividers) {
        expect(divider.color, _scheme(tester).outlineVariant);
        expect(divider.height, kDefaultPadding * 2);
      }
    });

    testWidgets("rows span the full width", (WidgetTester tester) async {
      await pumpApp(tester, const ExplainerSheet(items: _items));

      final double sheetRight = tester.getTopRight(find.byType(ExplainerSheet)).dx;
      final double valueRight = tester.getTopRight(find.text("-18 %")).dx;
      expect(sheetRight - valueRight, kDefaultPadding * 3);
    });

    testWidgets("shows caption and value only when given", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const ExplainerSheet(
          items: <ExplainerItem>[
            ExplainerItem(label: "Full", tone: StatusTone.info, value: "42", caption: "Note"),
            ExplainerItem(label: "Bare", tone: StatusTone.info, value: "", caption: ""),
          ],
        ),
      );

      expect(find.text("Note"), findsOneWidget);
      expect(find.text("42"), findsOneWidget);
      expect(tester.widget<Text>(find.text("Note")).style?.fontStyle, FontStyle.italic);
      final Finder bareRow = find.ancestor(of: find.text("Bare"), matching: find.byType(Row)).first;
      expect(find.descendant(of: bareRow, matching: find.byType(Text)), findsOneWidget);
    });

    testWidgets("styles the label w600 onSurface, the caption onSurfaceVariant, the value w700", (WidgetTester tester) async {
      await pumpApp(tester, const ExplainerSheet(items: _items));

      final ColorScheme cs = _scheme(tester);
      final TextStyle? label = tester.widget<Text>(find.text("First")).style;
      expect(label?.fontWeight, FontWeight.w600);
      expect(label?.color, cs.onSurface);
      expect(_textColor(tester, "Source A"), cs.onSurfaceVariant);
      expect(tester.widget<Text>(find.text("-18 %")).style?.fontWeight, FontWeight.w700);
    });

    testWidgets("paints the dot and the value in the tone foreground", (WidgetTester tester) async {
      await pumpApp(tester, const ExplainerSheet(items: _items));

      final List<BoxDecoration> dots = _dots(tester);
      expect(dots[0].color, _tone(tester, StatusTone.danger).foreground);
      expect(dots[1].color, _tone(tester, StatusTone.warning).foreground);
      expect(dots[2].color, _tone(tester, StatusTone.neutral).foreground);
      expect(_textColor(tester, "-18 %"), _tone(tester, StatusTone.danger).foreground);
      expect(_textColor(tester, "-9 %"), _tone(tester, StatusTone.warning).foreground);
    });

    testWidgets("centres the dot on the first line of the label", (WidgetTester tester) async {
      await pumpApp(tester, const ExplainerSheet(items: _items));

      final Finder dot = _inSheet(find.byType(DecoratedBox)).first;
      final Rect label = tester.getRect(find.text("First"));
      expect(tester.getSize(dot), const Size.square(kDefaultPadding));
      expect(tester.getCenter(dot).dy, closeTo(label.center.dy, 0.5));
    });
  });

  group("empty state", () {
    testWidgets("shows the default empty row in the success tone", (WidgetTester tester) async {
      await pumpApp(tester, const ExplainerSheet(items: <ExplainerItem>[]));

      expect(find.text("custom.explainer_sheet.empty"), findsOneWidget);
      expect(_inSheet(find.byType(Divider)), findsNothing);
      final Color success = _tone(tester, StatusTone.success).foreground;
      final List<BoxDecoration> dots = _dots(tester);
      expect(dots, hasLength(1));
      expect(dots.single.color, success);
      expect(_textColor(tester, "custom.explainer_sheet.empty"), success);
    });

    testWidgets("renders a custom empty label", (WidgetTester tester) async {
      await pumpApp(tester, const ExplainerSheet(items: <ExplainerItem>[], emptyLabel: "Nothing to report"));

      expect(find.text("Nothing to report"), findsOneWidget);
      expect(find.text("custom.explainer_sheet.empty"), findsNothing);
    });

    testWidgets("wraps a long empty label inside the padding at 320 dp", (WidgetTester tester) async {
      const String label = "Nothing stands out here, and this sentence is long enough to wrap";
      await pumpApp(
        tester,
        const ExplainerSheet(items: <ExplainerItem>[], emptyLabel: label),
        surfaceSize: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
      expect(_lines(tester, label).length, greaterThan(1));
      final double contentRight = tester.getTopRight(find.byType(ExplainerSheet)).dx - kDefaultPadding * 3;
      expect(tester.getRect(find.text(label)).right, lessThanOrEqualTo(contentRight));
    });
  });

  group("badge", () {
    testWidgets("renders the badge slot under the rows when given", (WidgetTester tester) async {
      const Key badgeKey = Key("badge");
      await pumpApp(
        tester,
        const ExplainerSheet(items: _items, badge: SizedBox(key: badgeKey, width: 40, height: 20)),
      );

      expect(find.byKey(badgeKey), findsOneWidget);
      expect(tester.getTopLeft(find.byKey(badgeKey)).dy, greaterThan(tester.getBottomLeft(find.text("Third")).dy));
      final double sheetCentre = tester.getCenter(find.byType(ExplainerSheet)).dx;
      expect(tester.getCenter(find.byKey(badgeKey)).dx, closeTo(sheetCentre, 0.5));
    });

    testWidgets("renders no badge when null", (WidgetTester tester) async {
      await pumpApp(tester, const ExplainerSheet(items: _items));

      expect(_inSheet(find.byKey(const Key("badge"))), findsNothing);
    });
  });

  group("learn more link", () {
    testWidgets("is hidden without onLearnMore", (WidgetTester tester) async {
      await pumpApp(tester, const ExplainerSheet(items: _items));

      expect(find.byType(TextButton), findsNothing);
      expect(find.text("custom.explainer_sheet.learn_more"), findsNothing);
    });

    testWidgets("defaults to the learn_more key and calls onLearnMore once per tap", (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(tester, ExplainerSheet(items: _items, onLearnMore: () => taps++));

      await tester.tap(find.text("custom.explainer_sheet.learn_more"));
      await tester.pump();

      expect(taps, 1);
      final Color? color = tester.widget<TextButton>(find.byType(TextButton)).style?.foregroundColor?.resolve(<WidgetState>{});
      expect(color, _scheme(tester).primary);
    });

    testWidgets("renders a custom label", (WidgetTester tester) async {
      await pumpApp(tester, ExplainerSheet(items: _items, learnMoreLabel: "Read the method", onLearnMore: () {}));

      expect(find.text("Read the method"), findsOneWidget);
      expect(find.text("custom.explainer_sheet.learn_more"), findsNothing);
    });

    testWidgets("is the last element, centred, at least 48 dp tall, with button semantics", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        ExplainerSheet(items: _items, badge: const SizedBox(key: Key("badge"), height: 20), onLearnMore: () {}),
      );

      final Finder link = find.byType(TextButton);
      expect(tester.getSize(link).height, greaterThanOrEqualTo(kMinTapTarget));
      expect(tester.getSize(link).width, greaterThanOrEqualTo(kMinTapTarget));
      expect(tester.getTopLeft(link).dy, greaterThan(tester.getBottomLeft(find.byKey(const Key("badge"))).dy));
      expect(tester.getCenter(link).dx, closeTo(tester.getCenter(find.byType(ExplainerSheet)).dx, 0.5));
      expect(
        tester.getSemantics(find.text("custom.explainer_sheet.learn_more")),
        matchesSemantics(
          label: "custom.explainer_sheet.learn_more",
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets("can be closed by its modal bottom sheet host from onLearnMore", (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (BuildContext sheetContext) => ExplainerSheet(
                items: _items,
                onLearnMore: () {
                  taps++;
                  Navigator.of(sheetContext).pop();
                },
              ),
            ),
            child: const Text("open"),
          ),
        ),
      );

      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();
      expect(find.byType(ExplainerSheet), findsOneWidget);

      await tester.tap(find.text("custom.explainer_sheet.learn_more"));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(find.byType(ExplainerSheet), findsNothing);
    });

    testWidgets("needs no Material ancestor: the link brings its own", (WidgetTester tester) async {
      int taps = 0;
      // Not pumpApp: its Scaffold would provide a Material.
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: ExplainerSheet(items: _items, onLearnMore: () => taps++)),
      );
      expect(find.ancestor(of: find.byType(ExplainerSheet), matching: find.byType(Material)), findsNothing);

      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(TextButton)));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(taps, 1);
    });
  });

  group("semantics", () {
    testWidgets("each row reads as one node with label, caption and value", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const ExplainerSheet(items: _items));

      final String label = tester.getSemantics(find.text("First")).label;
      expect(label, contains("First"));
      expect(label, contains("Source A"));
      expect(label, contains("-18 %"));
      expect(label.indexOf("First"), lessThan(label.indexOf("Source A")));
      expect(label.indexOf("Source A"), lessThan(label.indexOf("-18 %")));
      expect(tester.getSemantics(find.text("Second")).label, isNot(contains("First")));
      handle.dispose();
    });
  });

  group("layout", () {
    testWidgets("is content only: draws no handle and no background", (WidgetTester tester) async {
      await pumpApp(tester, ExplainerSheet(items: _items, onLearnMore: () {}));

      // Every decoration outside the dividers is a row dot: no handle bar,
      // no rounded background.
      final int decorated = _inSheet(find.byType(DecoratedBox)).evaluate().length;
      final int inDividers = find
          .descendant(of: find.byType(Divider), matching: find.byType(DecoratedBox))
          .evaluate()
          .length;
      expect(decorated - inDividers, _dots(tester).length);
      expect(_dots(tester), hasLength(3));
      expect(_inSheet(find.byType(Material)), findsOneWidget, reason: "only the link's own Material");
    });

    testWidgets("scrolls instead of overflowing in a short area", (WidgetTester tester) async {
      await pumpApp(
        tester,
        ExplainerSheet(items: _items, badge: const SizedBox(height: 40), onLearnMore: () {}),
        surfaceSize: const Size(320, 200),
      );

      expect(tester.takeException(), isNull);
      expect(_inSheet(find.byType(SingleChildScrollView)), findsOneWidget);
    });

    testWidgets("wraps long labels without overflow at 2x text scale", (WidgetTester tester) async {
      await pumpApp(
        tester,
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: ExplainerSheet(
            items: const <ExplainerItem>[
              ExplainerItem(
                label: "A rather long label that has to wrap over several lines",
                tone: StatusTone.warning,
                value: "-12 %",
                caption: "A long caption that also wraps",
              ),
            ],
            onLearnMore: () {},
          ),
        ),
        surfaceSize: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
    });
  });

  testWidgets("dark theme: renders with the dark tone colours", (WidgetTester tester) async {
    await pumpApp(
      tester,
      ExplainerSheet(items: _items, badge: const SizedBox(height: 20), onLearnMore: () {}),
      theme: AppTheme.dark(),
    );

    expect(tester.takeException(), isNull);
    final ToneColors danger = StatusTones.fromScheme(AppTheme.dark().colorScheme).danger;
    expect(_dots(tester).first.color, danger.foreground);
    expect(_textColor(tester, "-18 %"), danger.foreground);
    expect(_textColor(tester, "First"), AppTheme.dark().colorScheme.onSurface);
  });
}

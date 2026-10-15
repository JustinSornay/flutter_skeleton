// selection_strip_test.dart
//
// Widget tests for SelectionStrip: the "prefix value detail" text with its
// built-in prefix key and optional parts, the edit action (callback, hidden
// when read-only, 48 dp hit area, keyboard), semantics, layout under narrow
// widths, large text and RTL, and ColorScheme tokens in light and dark.

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/SelectionStrip/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _value = "Last 30 days";
const String _detail = "(12 items)";
const String _prefixKey = "custom.selection_strip.prefix";
const String _editKey = "custom.selection_strip.edit";
const String _editSemanticsKey = "custom.selection_strip.edit_semantics";
const String _long = "A very long selection label that cannot possibly fit on one line of the strip";

Finder _inStrip(Finder matching) {
  return find.descendant(of: find.byType(SelectionStrip), matching: matching);
}

Finder _edit() => _inStrip(find.byType(InkWell));

/// The one-line summary (the only Text.rich of the strip).
Text _summary(WidgetTester tester) {
  return tester.widget<Text>(_inStrip(find.byWidgetPredicate((Widget w) => w is Text && w.textSpan != null)));
}

String _summaryText(WidgetTester tester) => _summary(tester).textSpan!.toPlainText();

TextSpan _span(WidgetTester tester, String text) {
  final TextSpan root = _summary(tester).textSpan! as TextSpan;
  return root.children!.whereType<TextSpan>().firstWhere((TextSpan span) => span.text == text);
}

/// The usual strip: value, detail and an edit action.
SelectionStrip _strip({String? prefix, String? editLabel, VoidCallback? onEdit}) {
  return SelectionStrip(
    value: _value,
    prefix: prefix,
    detail: _detail,
    onEdit: onEdit ?? () {},
    editLabel: editLabel,
  );
}

Future<void> _pump(WidgetTester tester, SelectionStrip strip, {double? width, ThemeData? theme}) {
  return pumpApp(
    tester,
    Align(
      alignment: Alignment.topCenter,
      child: width == null ? strip : SizedBox(width: width, child: strip),
    ),
    theme: theme,
  );
}

void main() {
  group("text", () {
    testWidgets("renders the default prefix key, the value and the detail on one line", (WidgetTester tester) async {
      await _pump(tester, _strip());

      expect(_summaryText(tester), "$_prefixKey $_value $_detail");
      expect(_summary(tester).maxLines, 1);
      expect(_summary(tester).overflow, TextOverflow.ellipsis);
    });

    testWidgets("a custom prefix replaces the built-in one", (WidgetTester tester) async {
      await _pump(tester, _strip(prefix: "Period:"));

      expect(_summaryText(tester), "Period: $_value $_detail");
    });

    testWidgets("an empty prefix is hidden without a leading space", (WidgetTester tester) async {
      await _pump(tester, _strip(prefix: ""));

      expect(_summaryText(tester), "$_value $_detail");
    });

    testWidgets("null or empty detail leaves only prefix and value", (WidgetTester tester) async {
      await _pump(tester, SelectionStrip(value: _value, onEdit: () {}));
      expect(_summaryText(tester), "$_prefixKey $_value");

      await _pump(tester, SelectionStrip(value: _value, detail: "", onEdit: () {}));
      expect(_summaryText(tester), "$_prefixKey $_value");
    });

    testWidgets("the leading dot is an 8 dp circle", (WidgetTester tester) async {
      await _pump(tester, _strip());

      final Finder dot = _inStrip(
        find.byWidgetPredicate(
          (Widget w) => w is DecoratedBox && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      );
      expect(dot, findsOneWidget);
      expect(tester.getSize(dot), const Size.square(kDefaultPadding));
      expect(find.ancestor(of: dot, matching: find.byType(ExcludeSemantics)), findsWidgets);
    });
  });

  group("edit action", () {
    testWidgets("shows the built-in edit label and calls onEdit exactly once", (WidgetTester tester) async {
      int taps = 0;
      await _pump(tester, _strip(onEdit: () => taps++));

      expect(find.text(_editKey), findsOneWidget);
      await tester.tap(find.text(_editKey));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets("a custom edit label replaces the built-in one", (WidgetTester tester) async {
      await _pump(tester, _strip(editLabel: "Pick"));

      expect(find.text("Pick"), findsOneWidget);
      expect(find.text(_editKey), findsNothing);
    });

    testWidgets("null onEdit renders a read-only strip without action", (WidgetTester tester) async {
      await _pump(tester, const SelectionStrip(value: _value, detail: _detail));

      expect(_edit(), findsNothing);
      expect(find.text(_editKey), findsNothing);
      expect(_summaryText(tester), "$_prefixKey $_value $_detail");
      expect(tester.getSize(find.byType(SelectionStrip)).height, greaterThanOrEqualTo(kMinTapTarget));
    });

    testWidgets("label is labelSmall w600, underlined, cs.primary", (WidgetTester tester) async {
      await _pump(tester, _strip());

      final Text text = tester.widget<Text>(find.text(_editKey));
      final ThemeData theme = Theme.of(tester.element(find.byType(SelectionStrip)));
      expect(text.style?.fontSize, theme.textTheme.labelSmall?.fontSize);
      expect(text.style?.fontWeight, FontWeight.w600);
      expect(text.style?.decoration, TextDecoration.underline);
      expect(text.style?.color, theme.colorScheme.primary);
      expect(text.maxLines, 1);
    });

    testWidgets("hit area is at least kMinTapTarget on every platform", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _strip(editLabel: "Go"));

      final Size box = tester.getSize(_edit());
      expect(box.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(box.height, greaterThanOrEqualTo(kMinTapTarget));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    }, variant: TargetPlatformVariant.all());

    testWidgets("keyboard activation calls onEdit", (WidgetTester tester) async {
      int taps = 0;
      await _pump(tester, _strip(onEdit: () => taps++));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets("a host updates the value from onEdit", (WidgetTester tester) async {
      String value = "First";
      await pumpApp(
        tester,
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) => SelectionStrip(
            value: value,
            prefix: "",
            onEdit: () => setState(() => value = "Second"),
          ),
        ),
      );

      await tester.tap(_edit());
      await tester.pump();

      expect(_summaryText(tester), "Second");
    });
  });

  group("semantics", () {
    testWidgets("edit is one focusable button labelled with the default key", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _strip());

      expect(
        tester.getSemantics(_edit()),
        isSemantics(label: _editSemanticsKey, isButton: true, hasTapAction: true, isFocusable: true),
      );
      expect(find.bySemanticsLabel(_editKey), findsNothing);
      handle.dispose();
    });

    testWidgets("editSemanticsLabel overrides the default", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(
        tester,
        SelectionStrip(value: _value, detail: _detail, onEdit: () {}, editSemanticsLabel: "Change the period"),
      );

      expect(tester.getSemantics(_edit()), isSemantics(label: "Change the period", isButton: true, hasTapAction: true));
      handle.dispose();
    });

    testWidgets("the strip is one group read as its text, with the button as only child", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _strip(prefix: ""));

      final SemanticsNode node = tester.getSemantics(find.byType(SelectionStrip));
      expect(node.label, "$_value $_detail");
      final List<SemanticsNode> children = <SemanticsNode>[];
      node.visitChildren((SemanticsNode child) {
        children.add(child);
        return true;
      });
      expect(children, hasLength(1));
      expect(children.single.label, _editSemanticsKey);
      handle.dispose();
    });

    testWidgets("read-only strip has no tap action", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, const SelectionStrip(value: _value, detail: _detail));

      final SemanticsNode node = tester.getSemantics(find.byType(SelectionStrip));
      expect(node.label, "$_prefixKey $_value $_detail");
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      expect(find.bySemanticsLabel(_editSemanticsKey), findsNothing);
      handle.dispose();
    });
  });

  group("layout", () {
    testWidgets("a long value and detail ellipsize in 320 dp, edit stays visible", (WidgetTester tester) async {
      await _pump(tester, SelectionStrip(value: _long, detail: "(1234 entries)", onEdit: () {}), width: 320);

      expect(tester.takeException(), isNull);
      final Rect strip = tester.getRect(find.byType(SelectionStrip));
      expect(strip.width, 320);
      final Rect edit = tester.getRect(find.text(_editKey));
      expect(edit.right, lessThanOrEqualTo(strip.right));
      final Rect summary = tester.getRect(find.byWidget(_summary(tester)));
      expect(summary.right, lessThanOrEqualTo(edit.left));
      expect(tester.getSize(find.byType(SelectionStrip)).height, lessThan(kMinTapTarget + 2));
    });

    testWidgets("a short value is not truncated by the free space split", (WidgetTester tester) async {
      await _pump(tester, SelectionStrip(value: "Value", detail: _detail, onEdit: () {}), width: 320);

      final Rect summary = tester.getRect(find.byWidget(_summary(tester)));
      final Rect edit = tester.getRect(_edit());
      // The text box spans the whole free width up to the action.
      expect(edit.left - summary.right, kDefaultPadding);
    });

    testWidgets("a long edit label ellipsizes within 128 dp", (WidgetTester tester) async {
      await _pump(tester, _strip(editLabel: _long), width: 320);

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_edit()).width, lessThanOrEqualTo(kDefaultPadding * 16));
      expect(tester.widget<Text>(find.text(_long)).overflow, TextOverflow.ellipsis);
    });

    testWidgets("grows with large text instead of overflowing", (WidgetTester tester) async {
      await pumpApp(
        tester,
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: 320, child: SelectionStrip(value: _long, detail: _detail, onEdit: () {})),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(_editKey), findsOneWidget);
    });

    testWidgets("RTL mirrors the order: dot right, edit left", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Directionality(
          textDirection: TextDirection.rtl,
          child: Align(
            alignment: Alignment.topCenter,
            child: SelectionStrip(value: _value, onEdit: () {}),
          ),
        ),
      );

      final double textX = tester.getCenter(find.byWidget(_summary(tester))).dx;
      final Finder dot = _inStrip(find.byType(ExcludeSemantics)).first;
      expect(tester.getCenter(dot).dx, greaterThan(textX));
      expect(tester.getCenter(_edit()).dx, lessThan(textX));
    });
  });

  group("theme tokens", () {
    for (final (String name, ThemeData Function() theme) entry in <(String, ThemeData Function())>[
      ("light", AppTheme.light),
      ("dark", AppTheme.dark),
    ]) {
      testWidgets("${entry.$1}: tinted band, divider and text tokens", (WidgetTester tester) async {
        await _pump(tester, _strip(prefix: "Period:"), theme: entry.$2());
        expect(tester.takeException(), isNull);
        final ColorScheme cs = Theme.of(tester.element(find.byType(SelectionStrip))).colorScheme;

        final Container band = tester.widget<Container>(_inStrip(find.byType(Container)).first);
        final BoxDecoration decoration = band.decoration! as BoxDecoration;
        expect(decoration.color, cs.primary.withValues(alpha: 0.08));
        expect((decoration.border! as Border).bottom.color, cs.outlineVariant);

        expect(_span(tester, "Period:").style?.color, cs.onSurfaceVariant);
        expect(_span(tester, "Period:").style?.fontWeight, FontWeight.w500);
        expect(_span(tester, _value).style?.color, cs.primary);
        expect(_span(tester, _value).style?.fontWeight, FontWeight.w700);
        expect(_span(tester, _detail).style?.color, cs.primary.withValues(alpha: 0.85));
        expect(_span(tester, _detail).style?.fontWeight, FontWeight.w700);
      });
    }
  });
}

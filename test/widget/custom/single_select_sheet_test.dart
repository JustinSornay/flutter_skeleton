// single_select_sheet_test.dart
//
// Widget tests for SingleSelectSheet<T>: header, section label, rows and
// trailing hints, the pending selection (row taps never emit), confirm /
// cancel / close callbacks, the disabled confirm button without a selection,
// an initial value outside the options, default and overridden button
// labels, disabled rows, semantics, tap target sizes, long trailing hints at
// narrow widths, long lists, the dark theme and hosting inside a modal bottom
// sheet.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/SingleSelectSheet/index.dart";
import "package:flutter_skeleton/widgets/custom/_base/choice_option.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

enum _Speed { slow, medium, fast }

const String _title = "Pick a speed";
const String _section = "SPEEDS";

const List<ChoiceOption<String>> _options = <ChoiceOption<String>>[
  ChoiceOption<String>(value: "a", label: "Alpha · 1", trailing: "+1.0"),
  ChoiceOption<String>(value: "b", label: "Beta · 2", trailing: "+2.5"),
  ChoiceOption<String>(value: "c", label: "Gamma"),
];

/// Records the callbacks of one sheet, in call order.
final class _Calls {
  final List<String> log = <String>[];
  final List<String> confirmed = <String>[];

  void confirm(String value) {
    confirmed.add(value);
    log.add("confirm");
  }

  void cancel() => log.add("cancel");
}

SingleSelectSheet<String> _sheet(
  _Calls calls, {
  List<ChoiceOption<String>> options = _options,
  String? initialValue = "a",
  String? sectionLabel = _section,
  String? confirmLabel,
  String? cancelLabel,
}) {
  return SingleSelectSheet<String>(
    title: _title,
    sectionLabel: sectionLabel,
    options: options,
    initialValue: initialValue,
    onConfirm: calls.confirm,
    onCancel: calls.cancel,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
  );
}

/// The tappable row (InkWell) holding [label].
Finder _row(String label) {
  return find.ancestor(of: find.text(label), matching: find.byType(InkWell));
}

FilledButton _confirmButton(WidgetTester tester) {
  return tester.widget<FilledButton>(find.byType(FilledButton));
}

void main() {
  group("SingleSelectSheet rendering", () {
    testWidgets("renders the title, section label, labels and trailing hints", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls()));

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_section), findsOneWidget);
      expect(find.text("Alpha · 1"), findsOneWidget);
      expect(find.text("Beta · 2"), findsOneWidget);
      expect(find.text("Gamma"), findsOneWidget);
      expect(find.text("+1.0"), findsOneWidget);
      expect(find.text("+2.5"), findsOneWidget);
    });

    testWidgets("omits the section label when null", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls(), sectionLabel: null));

      expect(find.text(_section), findsNothing);
      expect(find.text("Alpha · 1"), findsOneWidget);
    });

    testWidgets("hides an empty trailing hint", (WidgetTester tester) async {
      const List<ChoiceOption<String>> options = <ChoiceOption<String>>[
        ChoiceOption<String>(value: "a", label: "Alpha", trailing: ""),
      ];
      await pumpApp(tester, _sheet(_Calls(), options: options));

      final Row row = tester.widget<Row>(
        find.ancestor(of: find.text("Alpha"), matching: find.byType(Row)).first,
      );
      expect(row.children.whereType<Text>(), isEmpty);
    });

    testWidgets("checks only the initial value", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls()));

      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(_options.length - 1));
      expect(
        find.descendant(of: _row("Alpha · 1"), matching: find.byIcon(Icons.radio_button_checked)),
        findsOneWidget,
      );
    });

    testWidgets("uses primary tokens for the selected row only", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls()));
      final ColorScheme cs = Theme.of(tester.element(find.byType(SingleSelectSheet<String>))).colorScheme;

      final Text selectedHint = tester.widget<Text>(find.text("+1.0"));
      final Text otherHint = tester.widget<Text>(find.text("+2.5"));
      expect(selectedHint.style?.color, cs.primary);
      expect(otherHint.style?.color, cs.onSurfaceVariant);

      final Icon checked = tester.widget<Icon>(find.byIcon(Icons.radio_button_checked));
      expect(checked.color, cs.primary);
    });
  });

  group("SingleSelectSheet selection", () {
    testWidgets("tapping a row moves the check without emitting", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _sheet(calls));

      await tester.tap(find.text("Beta · 2"));
      await tester.pump();

      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(
        find.descendant(of: _row("Beta · 2"), matching: find.byIcon(Icons.radio_button_checked)),
        findsOneWidget,
      );
      expect(calls.log, isEmpty);
    });

    testWidgets("confirm emits the pending selection once", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _sheet(calls));

      await tester.tap(find.text("Beta · 2"));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(calls.confirmed, <String>["b"]);
      expect(calls.log, <String>["confirm"]);
    });

    testWidgets("confirm without a tap emits the initial value", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _sheet(calls, initialValue: "c"));

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(calls.confirmed, <String>["c"]);
    });

    testWidgets("cancel calls onCancel only", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _sheet(calls));

      await tester.tap(find.text("Beta · 2"));
      await tester.pump();
      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();

      expect(calls.log, <String>["cancel"]);
      expect(calls.confirmed, isEmpty);
    });

    testWidgets("the close button calls onCancel only", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _sheet(calls));

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(calls.log, <String>["cancel"]);
      expect(calls.confirmed, isEmpty);
    });

    testWidgets("a null initial value checks nothing and disables confirm", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _sheet(calls, initialValue: null));

      expect(find.byIcon(Icons.radio_button_checked), findsNothing);
      expect(_confirmButton(tester).onPressed, isNull);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(calls.log, isEmpty);

      await tester.tap(find.text("Gamma"));
      await tester.pump();
      expect(_confirmButton(tester).onPressed, isNotNull);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(calls.confirmed, <String>["c"]);
    });

    testWidgets("an initial value outside the options checks nothing and disables confirm", (
      WidgetTester tester,
    ) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _sheet(calls, initialValue: "z"));

      expect(find.byIcon(Icons.radio_button_checked), findsNothing);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(_options.length));
      expect(_confirmButton(tester).onPressed, isNull);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(calls.log, isEmpty);

      await tester.tap(find.text("Beta · 2"));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(calls.confirmed, <String>["b"]);
    });

    testWidgets("a disabled row ignores taps and is dimmed", (WidgetTester tester) async {
      const List<ChoiceOption<String>> options = <ChoiceOption<String>>[
        ChoiceOption<String>(value: "a", label: "Alpha"),
        ChoiceOption<String>(value: "b", label: "Beta", enabled: false),
      ];
      final _Calls calls = _Calls();
      await pumpApp(tester, _sheet(calls, options: options));

      await tester.tap(find.text("Beta"), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(calls.confirmed, <String>["a"]);
      final Opacity opacity = tester.widget<Opacity>(
        find.ancestor(of: find.text("Beta"), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, lessThan(1));
    });

    testWidgets("a disabled row reports a disabled button without a tap action", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      const List<ChoiceOption<String>> options = <ChoiceOption<String>>[
        ChoiceOption<String>(value: "a", label: "Alpha"),
        ChoiceOption<String>(value: "b", label: "Beta", enabled: false),
      ];
      await pumpApp(tester, _sheet(_Calls(), options: options));

      expect(
        tester.getSemantics(_row("Beta")),
        isSemantics(
          label: "Beta",
          isButton: true,
          hasCheckedState: true,
          isChecked: false,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      handle.dispose();
    });

    testWidgets("works with an enum value type", (WidgetTester tester) async {
      _Speed? received;
      await pumpApp(
        tester,
        SingleSelectSheet<_Speed>(
          title: _title,
          options: const <ChoiceOption<_Speed>>[
            ChoiceOption<_Speed>(value: _Speed.slow, label: "Slow"),
            ChoiceOption<_Speed>(value: _Speed.medium, label: "Medium"),
            ChoiceOption<_Speed>(value: _Speed.fast, label: "Fast"),
          ],
          initialValue: _Speed.slow,
          onConfirm: (_Speed value) => received = value,
          onCancel: () {},
        ),
      );

      await tester.tap(find.text("Fast"));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(received, _Speed.fast);
    });
  });

  group("SingleSelectSheet labels", () {
    testWidgets("uses the default chrome keys", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls()));

      expect(find.text("custom.single_select_sheet.confirm"), findsOneWidget);
      expect(find.text("custom.single_select_sheet.cancel"), findsOneWidget);
      expect(find.byTooltip("custom.single_select_sheet.close"), findsOneWidget);
    });

    testWidgets("custom button labels replace the defaults", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls(), confirmLabel: "Apply", cancelLabel: "Back"));

      expect(find.text("Apply"), findsOneWidget);
      expect(find.text("Back"), findsOneWidget);
      expect(find.text("custom.single_select_sheet.confirm"), findsNothing);
      expect(find.text("custom.single_select_sheet.cancel"), findsNothing);
    });
  });

  group("SingleSelectSheet accessibility", () {
    testWidgets("rows are checkable buttons in a mutually exclusive group", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _sheet(_Calls()));

      expect(
        tester.getSemantics(_row("Alpha · 1")),
        isSemantics(
          label: "Alpha · 1, +1.0",
          isButton: true,
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(_row("Gamma")),
        isSemantics(
          label: "Gamma",
          isButton: true,
          hasCheckedState: true,
          isChecked: false,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets("semanticsLabel replaces the spoken text", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      const List<ChoiceOption<String>> options = <ChoiceOption<String>>[
        ChoiceOption<String>(value: "a", label: "A", trailing: "+1", semanticsLabel: "Option A, plus one"),
      ];
      await pumpApp(tester, _sheet(_Calls(), options: options));

      expect(
        tester.getSemantics(_row("A")),
        isSemantics(label: "Option A, plus one", isChecked: true),
      );
      handle.dispose();
    });

    testWidgets("the title is a header", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _sheet(_Calls()));

      expect(tester.getSemantics(find.text(_title)), isSemantics(label: _title, isHeader: true));
      handle.dispose();
    });

    testWidgets("rows, close and action buttons meet the tap target size", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls()));

      for (final ChoiceOption<String> option in _options) {
        expect(tester.getSize(_row(option.label)).height, greaterThanOrEqualTo(kMinTapTarget));
      }
      final Size close = tester.getSize(find.byType(IconButton));
      expect(close.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(close.height, greaterThanOrEqualTo(kMinTapTarget));
      expect(tester.getSize(find.byType(OutlinedButton)).height, greaterThanOrEqualTo(kMinTapTarget));
      expect(tester.getSize(find.byType(FilledButton)).height, greaterThanOrEqualTo(kMinTapTarget));
    });
  });

  group("SingleSelectSheet layout", () {
    testWidgets("no overflow at 400 px width", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls()), surfaceSize: const Size(400, 800));

      expect(tester.takeException(), isNull);
    });

    testWidgets("a long trailing hint ellipsizes at 320 px width", (WidgetTester tester) async {
      const String longHint = "A rather long trailing hint text here";
      const List<ChoiceOption<String>> options = <ChoiceOption<String>>[
        ChoiceOption<String>(value: "a", label: "Alpha", trailing: longHint),
        ChoiceOption<String>(value: "b", label: "Beta"),
      ];
      await pumpApp(tester, _sheet(_Calls(), options: options), surfaceSize: const Size(320, 800));

      expect(tester.takeException(), isNull);
      final Text hint = tester.widget<Text>(find.text(longHint));
      expect(hint.maxLines, 1);
      expect(hint.overflow, TextOverflow.ellipsis);
      expect(tester.getSize(find.text(longHint)).width, lessThan(tester.getSize(_row("Alpha")).width / 2));
      expect(tester.getSize(find.text("Alpha")).width, greaterThan(0));
    });

    testWidgets("a long list scrolls inside a short surface", (WidgetTester tester) async {
      final List<ChoiceOption<String>> options = <ChoiceOption<String>>[
        for (int i = 0; i < 30; i++) ChoiceOption<String>(value: "v$i", label: "Item $i", trailing: "#$i"),
      ];
      final _Calls calls = _Calls();
      await pumpApp(
        tester,
        _sheet(calls, options: options, initialValue: "v0"),
        surfaceSize: const Size(400, 600),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(FilledButton).hitTestable(), findsOneWidget);

      await tester.scrollUntilVisible(find.text("Item 29"), 200, scrollable: find.byType(Scrollable));
      await tester.tap(find.text("Item 29"));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(calls.confirmed, <String>["v29"]);
    });

    testWidgets("renders under the dark theme", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls()), theme: AppTheme.dark());

      expect(tester.takeException(), isNull);
      final ColorScheme cs = Theme.of(tester.element(find.byType(SingleSelectSheet<String>))).colorScheme;
      expect(cs.brightness, Brightness.dark);
      expect(tester.widget<Icon>(find.byIcon(Icons.radio_button_checked)).color, cs.primary);
    });

    testWidgets("closes a modal bottom sheet from the host callbacks", (WidgetTester tester) async {
      String? result;
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async {
              result = await showModalBottomSheet<String>(
                context: context,
                showDragHandle: true,
                builder: (BuildContext sheetContext) => SingleSelectSheet<String>(
                  title: _title,
                  options: _options,
                  initialValue: "a",
                  onConfirm: (String value) => Navigator.of(sheetContext).pop(value),
                  onCancel: () => Navigator.of(sheetContext).pop(),
                ),
              );
            },
            child: const Text("open"),
          ),
        ),
      );

      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();
      expect(find.text(_title), findsOneWidget);

      await tester.tap(find.text("Beta · 2"));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text(_title), findsNothing);
      expect(result, "b");
    });
  });
}

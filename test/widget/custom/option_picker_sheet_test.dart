// option_picker_sheet_test.dart
//
// Widget tests for OptionPickerSheet<T>: header, cards and optional fields,
// the selected / unselected markers and border tokens (light and dark), the
// onSelected callback (enum and String values, repeat taps, disabled cards),
// semantics, tap target size, long lists, and the host-owned closing inside
// a modal bottom sheet.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/OptionPickerSheet/index.dart";
import "package:flutter_skeleton/widgets/custom/_base/choice_option.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

enum _Density { compact, standard, wide }

const String _title = "Pick a density";

const List<ChoiceOption<_Density>> _options = <ChoiceOption<_Density>>[
  ChoiceOption<_Density>(
    value: _Density.compact,
    label: "Compact",
    description: "Dense rows",
    icon: Icons.density_small,
  ),
  ChoiceOption<_Density>(
    value: _Density.standard,
    label: "Standard",
    description: "Balanced rows",
    icon: Icons.density_medium,
  ),
  ChoiceOption<_Density>(value: _Density.wide, label: "Wide"),
];

OptionPickerSheet<_Density> _sheet({
  List<ChoiceOption<_Density>> options = _options,
  _Density? selected,
  ValueChanged<_Density>? onSelected,
}) {
  return OptionPickerSheet<_Density>(
    title: _title,
    options: options,
    selected: selected,
    onSelected: onSelected ?? (_Density _) {},
  );
}

/// The card (InkWell) holding [label].
Finder _card(String label) {
  return find.ancestor(of: find.text(label), matching: find.byType(InkWell));
}

/// The border of the card holding [label].
Border _border(WidgetTester tester, String label) {
  final Container container = tester.widget<Container>(
    find.ancestor(of: find.text(label), matching: find.byType(Container)).first,
  );
  final Decoration? decoration = container.decoration;
  expect(decoration, isA<BoxDecoration>());
  final BoxBorder? border = (decoration! as BoxDecoration).border;
  expect(border, isA<Border>());
  return border! as Border;
}

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(OptionPickerSheet<_Density>))).colorScheme;
}

void main() {
  group("OptionPickerSheet rendering", () {
    testWidgets("renders the title, labels and descriptions", (WidgetTester tester) async {
      await pumpApp(tester, _sheet());

      expect(find.text(_title), findsOneWidget);
      expect(find.text("Compact"), findsOneWidget);
      expect(find.text("Dense rows"), findsOneWidget);
      expect(find.text("Standard"), findsOneWidget);
      expect(find.text("Balanced rows"), findsOneWidget);
      expect(find.text("Wide"), findsOneWidget);
      expect(find.descendant(of: _card("Wide"), matching: find.byType(Text)), findsOneWidget);
    });

    testWidgets("an empty description is hidden", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _sheet(
          options: const <ChoiceOption<_Density>>[
            ChoiceOption<_Density>(value: _Density.compact, label: "Compact", description: ""),
          ],
        ),
      );

      expect(find.descendant(of: _card("Compact"), matching: find.byType(Text)), findsOneWidget);
    });

    testWidgets("the selected card shows the only check, the others a chevron", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(selected: _Density.standard));

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(
        find.descendant(of: _card("Standard"), matching: find.byIcon(Icons.check_circle_rounded)),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));
      expect(
        find.descendant(of: _card("Compact"), matching: find.byIcon(Icons.chevron_right_rounded)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _card("Wide"), matching: find.byIcon(Icons.chevron_right_rounded)),
        findsOneWidget,
      );
    });

    testWidgets("a null selection shows no check", (WidgetTester tester) async {
      await pumpApp(tester, _sheet());

      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(3));
    });

    testWidgets("a card without icon or description has no leading icon", (WidgetTester tester) async {
      await pumpApp(tester, _sheet());

      expect(tester.takeException(), isNull);
      final Finder icons = find.descendant(of: _card("Wide"), matching: find.byType(Icon));
      expect(icons, findsOneWidget);
      expect(tester.widget<Icon>(icons).icon, Icons.chevron_right_rounded);
    });

    testWidgets("the leading icon is tinted with the primary colour", (WidgetTester tester) async {
      await pumpApp(tester, _sheet());

      expect(tester.widget<Icon>(find.byIcon(Icons.density_small)).color, _scheme(tester).primary);
    });

    testWidgets("borders use the primary and outlineVariant tokens", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(selected: _Density.compact));
      final ColorScheme cs = _scheme(tester);

      final Border selected = _border(tester, "Compact");
      expect(selected.top.color, cs.primary);
      expect(selected.top.width, 2);
      final Border unselected = _border(tester, "Wide");
      expect(unselected.top.color, cs.outlineVariant);
      expect(unselected.top.width, 1);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.check_circle_rounded)).color,
        cs.primary,
      );
    });

    testWidgets("dark theme smoke test", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(selected: _Density.wide), theme: AppTheme.dark());
      final ColorScheme cs = _scheme(tester);

      expect(tester.takeException(), isNull);
      expect(cs.brightness, Brightness.dark);
      expect(_border(tester, "Wide").top.color, cs.primary);
      expect(_border(tester, "Compact").top.color, cs.outlineVariant);
      final Text title = tester.widget<Text>(find.text(_title));
      expect(title.style?.color, cs.onSurface);
    });

    testWidgets("every card is at least the minimum tap target tall", (WidgetTester tester) async {
      await pumpApp(tester, _sheet());

      for (final String label in <String>["Compact", "Standard", "Wide"]) {
        expect(tester.getSize(_card(label)).height, greaterThanOrEqualTo(kMinTapTarget));
      }
    });

    testWidgets("a long list scrolls without overflowing", (WidgetTester tester) async {
      await pumpApp(
        tester,
        OptionPickerSheet<int>(
          title: _title,
          options: <ChoiceOption<int>>[
            for (int i = 0; i < 30; i++)
              ChoiceOption<int>(value: i, label: "Option $i", description: "Line $i"),
          ],
          onSelected: (int _) {},
        ),
        surfaceSize: const Size(400, 600),
      );

      final Finder last = find.text("Option 29").hitTestable();
      expect(tester.takeException(), isNull);
      expect(last, findsNothing);
      await tester.scrollUntilVisible(last, 200, scrollable: find.byType(Scrollable));
      expect(last, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group("OptionPickerSheet selection", () {
    testWidgets("tapping a card calls onSelected once with its value", (WidgetTester tester) async {
      final List<_Density> picked = <_Density>[];
      await pumpApp(tester, _sheet(selected: _Density.compact, onSelected: picked.add));

      await tester.tap(find.text("Wide"));
      await tester.pump();

      expect(picked, <_Density>[_Density.wide]);
    });

    testWidgets("tapping the selected card still calls onSelected", (WidgetTester tester) async {
      final List<_Density> picked = <_Density>[];
      await pumpApp(tester, _sheet(selected: _Density.compact, onSelected: picked.add));

      await tester.tap(find.text("Compact"));
      await tester.pump();

      expect(picked, <_Density>[_Density.compact]);
    });

    testWidgets("works with String values", (WidgetTester tester) async {
      final List<String> picked = <String>[];
      await pumpApp(
        tester,
        OptionPickerSheet<String>(
          title: _title,
          options: const <ChoiceOption<String>>[
            ChoiceOption<String>(value: "a", label: "First"),
            ChoiceOption<String>(value: "b", label: "Second"),
          ],
          selected: "a",
          onSelected: picked.add,
        ),
      );

      expect(
        find.descendant(of: _card("First"), matching: find.byIcon(Icons.check_circle_rounded)),
        findsOneWidget,
      );
      await tester.tap(find.text("Second"));
      await tester.pump();

      expect(picked, <String>["b"]);
    });

    testWidgets("a disabled card is dimmed and ignores taps", (WidgetTester tester) async {
      final List<_Density> picked = <_Density>[];
      await pumpApp(
        tester,
        _sheet(
          options: const <ChoiceOption<_Density>>[
            ChoiceOption<_Density>(value: _Density.compact, label: "Compact", enabled: false),
            ChoiceOption<_Density>(value: _Density.wide, label: "Wide"),
          ],
          onSelected: picked.add,
        ),
      );

      final Opacity opacity = tester.widget<Opacity>(
        find.ancestor(of: find.text("Compact"), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, 0.38);
      expect(tester.widget<InkWell>(_card("Compact")).onTap, isNull);
      await tester.tap(find.text("Compact"), warnIfMissed: false);
      await tester.pump();

      expect(picked, isEmpty);
    });
  });

  group("OptionPickerSheet accessibility", () {
    testWidgets("the title is a header", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _sheet());

      expect(tester.getSemantics(find.text(_title)), isSemantics(label: _title, isHeader: true));
      handle.dispose();
    });

    testWidgets("cards are buttons of an exclusive group exposing the selection", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _sheet(selected: _Density.standard));

      expect(
        tester.getSemantics(find.text("Standard")),
        isSemantics(
          label: "Standard\nBalanced rows",
          isButton: true,
          isSelected: true,
          isEnabled: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.text("Wide")),
        isSemantics(
          label: "Wide",
          isButton: true,
          isSelected: false,
          isEnabled: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets("semanticsLabel replaces the spoken text and keeps the tap", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        _sheet(
          options: const <ChoiceOption<_Density>>[
            ChoiceOption<_Density>(
              value: _Density.compact,
              label: "C",
              description: "x",
              semanticsLabel: "Spoken",
            ),
          ],
        ),
      );

      expect(
        tester.getSemantics(_card("C")),
        isSemantics(label: "Spoken", isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });
  });

  group("OptionPickerSheet hosting", () {
    Future<void> openSheet(WidgetTester tester, ValueChanged<_Density> Function(BuildContext) onSelected) async {
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (BuildContext sheetContext) => _sheet(onSelected: onSelected(sheetContext)),
            ),
            child: const Text("open"),
          ),
        ),
      );
      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();
    }

    testWidgets("the widget does not close its sheet itself", (WidgetTester tester) async {
      final List<_Density> picked = <_Density>[];
      await openSheet(tester, (BuildContext _) => picked.add);

      await tester.tap(find.text("Standard"));
      await tester.pumpAndSettle();

      expect(picked, <_Density>[_Density.standard]);
      expect(find.byType(OptionPickerSheet<_Density>), findsOneWidget);
    });

    testWidgets("the host closes the sheet in onSelected", (WidgetTester tester) async {
      final List<_Density> picked = <_Density>[];
      await openSheet(
        tester,
        (BuildContext sheetContext) => (_Density value) {
          picked.add(value);
          Navigator.of(sheetContext).pop();
        },
      );

      await tester.tap(find.text("Compact"));
      await tester.pumpAndSettle();

      expect(picked, <_Density>[_Density.compact]);
      expect(find.byType(OptionPickerSheet<_Density>), findsNothing);
    });
  });
}

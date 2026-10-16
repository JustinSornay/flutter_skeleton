// choice_chip_row_test.dart
//
// Widget tests for ChoiceChipRow: one chip per option in order, the selected
// flag driven by selectedValue, typed onSelected callbacks (including a
// repeat tap and a host-owned selection), disabled options, the rendered
// ChoiceOption fields (icon, semanticsLabel), the optional caption, the
// ColorScheme tokens under the light and dark themes, 48 dp hit areas,
// reduced motion, a nullable value type whose null option is selectable, and
// wrapping in a narrow parent with a visible gap between runs at every text
// scale.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/ChoiceChipRow/index.dart";
import "package:flutter_skeleton/widgets/custom/_base/choice_option.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _caption = "PERIOD";

const List<ChoiceOption<int>> _options = <ChoiceOption<int>>[
  ChoiceOption<int>(value: 1, label: "Alpha"),
  ChoiceOption<int>(value: 2, label: "Beta"),
  ChoiceOption<int>(value: 3, label: "Gamma", enabled: false),
];

ChoiceChipRow<int> _row({
  List<ChoiceOption<int>> options = _options,
  int? selectedValue = 2,
  ValueChanged<int>? onSelected,
  String? label,
}) {
  return ChoiceChipRow<int>(
    options: options,
    selectedValue: selectedValue,
    onSelected: onSelected ?? (int _) {},
    label: label,
  );
}

Finder _chipOf(String label) => find.ancestor(of: find.text(label), matching: find.byType(ChoiceChip));

ChoiceChip _chip(WidgetTester tester, String label) => tester.widget<ChoiceChip>(_chipOf(label));

List<ChoiceChip> _chips(WidgetTester tester) => tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();

/// Texts drawn inside the chips, in tree order.
List<String?> _chipTexts(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.descendant(of: find.byType(ChoiceChip), matching: find.byType(Text)))
      .map((Text text) => text.data)
      .toList();
}

/// The visible pill of the chip holding [label] (its Material).
Finder _pillOf(String label) => find.descendant(of: _chipOf(label), matching: find.byType(Material)).first;

void main() {
  group("structure", _structureTests);
  group("selection", _selectionTests);
  group("disabled option", _disabledOptionTests);
  group("option fields", _optionFieldsTests);
  group("caption", _captionTests);
  group("colours", _coloursTests);
  group("accessibility and motion", _accessibilityAndMotionTests);
  group("layout", _layoutTests);
}

void _structureTests() {
  testWidgets("renders one ChoiceChip per option, in order, with its label", (WidgetTester tester) async {
    await pumpApp(tester, _row());

    expect(_chips(tester), hasLength(3));
    expect(_chipTexts(tester), <String>["Alpha", "Beta", "Gamma"]);
    expect(tester.getTopLeft(_chipOf("Alpha")).dx, lessThan(tester.getTopLeft(_chipOf("Beta")).dx));
    expect(tester.getTopLeft(_chipOf("Beta")).dx, lessThan(tester.getTopLeft(_chipOf("Gamma")).dx));
  });

  testWidgets("an empty option list renders no chip and no error", (WidgetTester tester) async {
    await pumpApp(tester, _row(options: const <ChoiceOption<int>>[]));

    expect(find.byType(ChoiceChip), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("pill chips: StadiumBorder, compact, no checkmark", (WidgetTester tester) async {
    await pumpApp(tester, _row());

    final ChoiceChip chip = _chip(tester, "Alpha");
    expect(chip.shape, isA<StadiumBorder>());
    expect(chip.showCheckmark, isFalse);
    expect(chip.visualDensity, VisualDensity.compact);
    expect(chip.labelStyle?.fontSize, 12);
    expect(chip.labelStyle?.fontWeight, FontWeight.w600);
  });
}

void _selectionTests() {
  testWidgets("only the chip whose value equals selectedValue is selected", (WidgetTester tester) async {
    await pumpApp(tester, _row(selectedValue: 2));

    expect(_chip(tester, "Alpha").selected, isFalse);
    expect(_chip(tester, "Beta").selected, isTrue);
    expect(_chip(tester, "Gamma").selected, isFalse);
  });

  testWidgets("with a non-nullable T, a null selectedValue selects no chip", (WidgetTester tester) async {
    await pumpApp(tester, _row(selectedValue: null));

    expect(_chips(tester).where((ChoiceChip chip) => chip.selected), isEmpty);
  });

  testWidgets("tapping an enabled chip calls onSelected once with its int value", (WidgetTester tester) async {
    final List<int> selected = <int>[];
    await pumpApp(tester, _row(onSelected: selected.add));

    await tester.tap(find.text("Alpha"));
    await tester.pump();

    expect(selected, <int>[1]);
  });

  testWidgets("with a nullable T, a null-valued option is selected by null and reports null", (
    WidgetTester tester,
  ) async {
    final List<int?> selected = <int?>[];
    await pumpApp(
      tester,
      ChoiceChipRow<int?>(
        options: const <ChoiceOption<int?>>[
          ChoiceOption<int?>(value: null, label: "All"),
          ChoiceOption<int?>(value: 1, label: "One"),
        ],
        selectedValue: null,
        onSelected: selected.add,
      ),
    );

    expect(_chip(tester, "All").selected, isTrue);
    expect(_chip(tester, "One").selected, isFalse);

    await tester.tap(find.text("One"));
    await tester.pump();
    await tester.tap(find.text("All"));
    await tester.pump();

    expect(selected, <int?>[1, null]);
  });

  testWidgets("works with any value type (String)", (WidgetTester tester) async {
    final List<String> selected = <String>[];
    await pumpApp(
      tester,
      ChoiceChipRow<String>(
        options: const <ChoiceOption<String>>[
          ChoiceOption<String>(value: "a", label: "First"),
          ChoiceOption<String>(value: "b", label: "Second"),
        ],
        selectedValue: "a",
        onSelected: selected.add,
      ),
    );

    await tester.tap(find.text("Second"));
    await tester.pump();

    expect(selected, <String>["b"]);
  });

  testWidgets("tapping the selected chip still reports its value", (WidgetTester tester) async {
    final List<int> selected = <int>[];
    await pumpApp(tester, _row(selectedValue: 2, onSelected: selected.add));

    await tester.tap(find.text("Beta"));
    await tester.pump();

    expect(selected, <int>[2]);
  });

  testWidgets("the host owns the selection: a rebuild moves the selected chip", (WidgetTester tester) async {
    int? current = 1;
    await pumpApp(
      tester,
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) => _row(
          selectedValue: current,
          onSelected: (int value) => setState(() => current = value),
        ),
      ),
    );

    await tester.tap(find.text("Beta"));
    await tester.pumpAndSettle();

    expect(current, 2);
    expect(_chip(tester, "Alpha").selected, isFalse);
    expect(_chip(tester, "Beta").selected, isTrue);
  });
}

void _disabledOptionTests() {
  testWidgets("has no onSelected and ignores taps", (WidgetTester tester) async {
    final List<int> selected = <int>[];
    await pumpApp(tester, _row(onSelected: selected.add));

    expect(_chip(tester, "Gamma").onSelected, isNull);
    expect(_chip(tester, "Alpha").onSelected, isNotNull);

    await tester.tap(find.text("Gamma"), warnIfMissed: false);
    await tester.pump();

    expect(selected, isEmpty);
  });

  testWidgets("is reported as disabled to screen readers", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpApp(tester, _row());

    expect(
      tester.getSemantics(_chipOf("Gamma")),
      isSemantics(label: "Gamma", hasEnabledState: true, isEnabled: false),
    );
    expect(
      tester.getSemantics(_chipOf("Beta")),
      isSemantics(label: "Beta", isEnabled: true, isSelected: true, hasTapAction: true),
    );
    handle.dispose();
  });
}

void _optionFieldsTests() {
  testWidgets("icon renders an 18 dp leading avatar in the label colour", (WidgetTester tester) async {
    await pumpApp(
      tester,
      _row(
        options: const <ChoiceOption<int>>[
          ChoiceOption<int>(value: 1, label: "Alpha", icon: Icons.star_outline),
          ChoiceOption<int>(value: 2, label: "Beta"),
        ],
      ),
    );

    final ChoiceChip chip = _chip(tester, "Alpha");
    final Icon icon = chip.avatar! as Icon;
    expect(icon.icon, Icons.star_outline);
    expect(icon.size, 18);
    expect(icon.color, chip.labelStyle?.color);
    expect(_chip(tester, "Beta").avatar, isNull);
  });

  testWidgets("semanticsLabel replaces the spoken label", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      _row(
        options: const <ChoiceOption<int>>[
          ChoiceOption<int>(value: 1, label: "Q1", semanticsLabel: "First quarter"),
        ],
      ),
    );

    expect(find.bySemanticsLabel("First quarter"), findsOneWidget);
    handle.dispose();
  });

  testWidgets("description and trailing are not rendered", (WidgetTester tester) async {
    await pumpApp(
      tester,
      _row(
        options: const <ChoiceOption<int>>[
          ChoiceOption<int>(value: 1, label: "Alpha", description: "Hidden line", trailing: "42"),
        ],
      ),
    );

    expect(find.text("Hidden line"), findsNothing);
    expect(find.text("42"), findsNothing);
  });
}

void _captionTests() {
  testWidgets("is shown as passed, above the chips, in onSurfaceVariant", (WidgetTester tester) async {
    await pumpApp(tester, _row(label: _caption));

    expect(find.text(_caption), findsOneWidget);
    expect(
      tester.getBottomLeft(find.text(_caption)).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.byType(Wrap)).dy - kDefaultPadding),
    );

    final BuildContext context = tester.element(find.byType(ChoiceChipRow<int>));
    final Text caption = tester.widget<Text>(find.text(_caption));
    expect(caption.style?.color, Theme.of(context).colorScheme.onSurfaceVariant);
    expect(caption.style?.fontSize, 9);
    expect(caption.style?.fontWeight, FontWeight.w700);
    expect(caption.style?.letterSpacing, 1);
  });

  testWidgets("without a label, the only texts are the chip labels", (WidgetTester tester) async {
    await pumpApp(tester, _row());

    final Iterable<String?> texts = tester.widgetList<Text>(find.byType(Text)).map((Text text) => text.data);
    expect(texts.toList(), <String>["Alpha", "Beta", "Gamma"]);
    expect(_chipTexts(tester), texts.toList());
  });
}

void _coloursTests() {
  for (final (String name, ThemeData Function() theme) in <(String, ThemeData Function())>[
    ("light", AppTheme.light),
    ("dark", AppTheme.dark),
  ]) {
    testWidgets("$name theme: selected, unselected and disabled tokens", (WidgetTester tester) async {
      await pumpApp(tester, _row(selectedValue: 2), theme: theme());

      final ColorScheme cs = Theme.of(tester.element(find.byType(ChoiceChipRow<int>))).colorScheme;
      final ChoiceChip selected = _chip(tester, "Beta");
      final ChoiceChip unselected = _chip(tester, "Alpha");
      final ChoiceChip disabled = _chip(tester, "Gamma");

      expect(selected.selectedColor, cs.primary);
      expect(selected.labelStyle?.color, cs.onPrimary);
      expect(selected.side?.color, cs.primary);

      expect(unselected.backgroundColor, cs.surfaceContainer);
      expect(unselected.labelStyle?.color, cs.onSurface);
      expect(unselected.side?.color, cs.outlineVariant);

      expect(disabled.disabledColor, cs.surfaceContainer);
      expect(disabled.labelStyle?.color, cs.onSurface.withValues(alpha: 0.38));
      expect(disabled.side?.color, cs.outlineVariant);
      expect(tester.takeException(), isNull);
    });
  }
}

void _accessibilityAndMotionTests() {
  testWidgets("every chip has a hit area of at least 48 x 48 dp, even a one-glyph label", (WidgetTester tester) async {
    await pumpApp(
      tester,
      _row(
        options: const <ChoiceOption<int>>[
          ChoiceOption<int>(value: 1, label: "I"),
          ChoiceOption<int>(value: 2, label: "A much longer label"),
        ],
        selectedValue: null,
      ),
    );

    for (final String label in <String>["I", "A much longer label"]) {
      final Size hitArea = tester.getSize(_chipOf(label));
      expect(hitArea.height, greaterThanOrEqualTo(kMinTapTarget));
      expect(tester.getSize(_pillOf(label)).width, greaterThanOrEqualTo(kMinTapTarget));
      expect(tester.getSize(_pillOf(label)).height, lessThan(kMinTapTarget));
    }
  });

  testWidgets("a tap just above or below the compact pill selects it", (WidgetTester tester) async {
    final List<int> selected = <int>[];
    await pumpApp(tester, _row(onSelected: selected.add));

    final Rect hitArea = tester.getRect(_chipOf("Alpha"));
    final Rect pill = tester.getRect(_pillOf("Alpha"));
    expect(hitArea.top, lessThan(pill.top));

    await tester.tapAt(Offset(pill.center.dx, hitArea.top + 1));
    await tester.tapAt(Offset(pill.center.dx, hitArea.bottom - 1));
    await tester.pump();

    expect(selected, <int>[1, 1]);
  });

  testWidgets("select and enable transitions last kMotionShort", (WidgetTester tester) async {
    await pumpApp(tester, _row());

    final ChipAnimationStyle? style = _chip(tester, "Alpha").chipAnimationStyle;
    expect(style?.selectAnimation?.duration, kMotionShort);
    expect(style?.enableAnimation?.duration, kMotionShort);
    expect(style?.avatarDrawerAnimation?.duration, kMotionShort);
  });

  testWidgets("reduced motion makes every chip transition instant", (WidgetTester tester) async {
    await pumpApp(
      tester,
      Builder(
        builder: (BuildContext context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: _row(),
        ),
      ),
    );

    for (final ChoiceChip chip in _chips(tester)) {
      expect(chip.chipAnimationStyle?.selectAnimation?.duration, Duration.zero);
      expect(chip.chipAnimationStyle?.enableAnimation?.duration, Duration.zero);
      expect(chip.chipAnimationStyle?.avatarDrawerAnimation?.duration, Duration.zero);
    }
  });
}

void _layoutTests() {
  testWidgets("wraps onto several runs in a narrow parent without overflow", (WidgetTester tester) async {
    final List<ChoiceOption<int>> many = <ChoiceOption<int>>[
      for (int i = 0; i < 8; i++) ChoiceOption<int>(value: i, label: "Option $i"),
    ];
    await pumpApp(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 200, child: _row(options: many, selectedValue: 0)),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(ChoiceChip), findsNWidgets(8));
    expect(
      tester.getTopLeft(_chipOf("Option 7")).dy,
      greaterThan(tester.getTopLeft(_chipOf("Option 0")).dy),
    );
    expect(tester.getTopRight(_chipOf("Option 7")).dx, lessThanOrEqualTo(200));
  });

  for (final double scale in <double>[1, 2, 2.5, 3]) {
    testWidgets("text scale $scale: pills on consecutive runs stay at least kDefaultPadding apart", (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 100,
                child: _row(
                  options: const <ChoiceOption<int>>[
                    ChoiceOption<int>(value: 1, label: "A"),
                    ChoiceOption<int>(value: 2, label: "B"),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final Rect first = tester.getRect(_pillOf("A"));
      final Rect second = tester.getRect(_pillOf("B"));
      expect(second.top, greaterThan(first.top), reason: "the chips must sit on two runs");
      expect(second.top - first.bottom, greaterThanOrEqualTo(kDefaultPadding));
    });
  }
}

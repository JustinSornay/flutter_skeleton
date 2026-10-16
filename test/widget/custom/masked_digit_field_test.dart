// masked_digit_field_test.dart
//
// Widget tests for MaskedDigitField: grouping while typing, raw digits sent
// to onChanged, rejection of non-digits, clamping to the slot count, removal
// of the dangling separator on delete, pattern changes (reformat, deferred
// single notification, setState-safe host), hint / label / error rendering,
// keyboard type, borders, the 48 dp height and a narrow layout under the
// light and dark themes.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/MaskedDigitField/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _spaced = "# ## ## ## ##";
const String _long = "### ########";

Finder _field() => find.byType(TextField);

TextEditingValue _value(WidgetTester tester) {
  return tester.widget<EditableText>(find.byType(EditableText)).controller.value;
}

InputDecoration _decoration(WidgetTester tester) {
  return tester.widget<TextField>(_field()).decoration!;
}

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(MaskedDigitField))).colorScheme;
}

/// Types [text] at the end of the current value, like a keystroke.
Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(_field(), _value(tester).text + text);
  await tester.pump();
}

/// Host whose parameters a test changes through [_Host.update]. Records every
/// onChanged value and, when [rebuildOnChange] is set, calls setState in it.
final class _Host {
  late StateSetter _setState;
  String pattern;
  String? errorText;
  bool rebuildOnChange = false;
  final List<String> changes = <String>[];

  _Host(this.pattern);

  Widget build() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        _setState = setState;
        return MaskedDigitField(
          pattern: pattern,
          errorText: errorText,
          onChanged: (String digits) {
            changes.add(digits);
            if (rebuildOnChange) setState(() {});
          },
        );
      },
    );
  }

  Future<void> update(WidgetTester tester, VoidCallback change) async {
    _setState(change);
    await tester.pump();
  }
}

void main() {
  group("MaskedDigitField typing", () {
    testWidgets("groups the digits and sends them raw to onChanged", (WidgetTester tester) async {
      final List<String> changes = <String>[];
      await pumpApp(tester, MaskedDigitField(pattern: _spaced, onChanged: changes.add));

      await tester.enterText(_field(), "612345678");
      await tester.pump();

      expect(find.text("6 12 34 56 78"), findsOneWidget);
      expect(changes.last, "612345678");
      expect(_value(tester).selection, const TextSelection.collapsed(offset: 13));
    });

    testWidgets("notifies once per keystroke with the growing digits", (WidgetTester tester) async {
      final List<String> changes = <String>[];
      await pumpApp(tester, MaskedDigitField(pattern: _spaced, onChanged: changes.add));

      for (final String digit in <String>["6", "1", "2"]) {
        await _type(tester, digit);
      }

      expect(_value(tester).text, "6 12");
      expect(changes, <String>["6", "61", "612"]);
    });

    testWidgets("rejects letters and symbols", (WidgetTester tester) async {
      final List<String> changes = <String>[];
      await pumpApp(tester, MaskedDigitField(pattern: _spaced, onChanged: changes.add));

      await tester.enterText(_field(), "6a1+2");
      await tester.pump();

      expect(_value(tester).text, "6 12");
      expect(changes, <String>["612"]);

      await _type(tester, "x");

      expect(_value(tester).text, "6 12");
      expect(changes, <String>["612"]);
    });

    testWidgets("clamps the input to the slot count", (WidgetTester tester) async {
      final List<String> changes = <String>[];
      await pumpApp(tester, MaskedDigitField(pattern: _spaced, onChanged: changes.add));

      await tester.enterText(_field(), "61234567899");
      await tester.pump();

      expect(_value(tester).text, "6 12 34 56 78");
      expect(changes, <String>["612345678"]);

      await _type(tester, "9");

      expect(_value(tester).text, "6 12 34 56 78");
      expect(changes, <String>["612345678"]);
    });

    testWidgets("deleting a digit removes the dangling separator", (WidgetTester tester) async {
      final List<String> changes = <String>[];
      await pumpApp(tester, MaskedDigitField(pattern: _spaced, onChanged: changes.add));
      await tester.enterText(_field(), "6123");
      await tester.pump();
      expect(_value(tester).text, "6 12 3");

      await tester.enterText(_field(), "6 12 ");
      await tester.pump();

      expect(_value(tester).text, "6 12");
      expect(_value(tester).selection, const TextSelection.collapsed(offset: 4));
      expect(changes.last, "612");
    });

    testWidgets("works without onChanged", (WidgetTester tester) async {
      await pumpApp(tester, const MaskedDigitField(pattern: "##/##/####"));

      await tester.enterText(_field(), "01022024");
      await tester.pump();

      expect(find.text("01/02/2024"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group("MaskedDigitField pattern changes", () {
    testWidgets("a shorter pattern truncates and notifies once after the frame", (WidgetTester tester) async {
      final _Host host = _Host(_long)..rebuildOnChange = true;
      await pumpApp(tester, host.build());
      await tester.enterText(_field(), "12345678901");
      await tester.pump();
      expect(_value(tester).text, "123 45678901");
      host.changes.clear();

      await host.update(tester, () => host.pattern = _spaced);

      expect(_value(tester).text, "1 23 45 67 89");
      expect(_value(tester).selection, const TextSelection.collapsed(offset: 13));
      expect(host.changes, <String>["123456789"]);
      expect(tester.takeException(), isNull);

      await tester.pump();
      expect(host.changes, <String>["123456789"]);
    });

    testWidgets("a pattern keeping every digit regroups without notifying", (WidgetTester tester) async {
      final _Host host = _Host(_spaced);
      await pumpApp(tester, host.build());
      await tester.enterText(_field(), "612345678");
      await tester.pump();
      host.changes.clear();

      await host.update(tester, () => host.pattern = "## ## ## ## #");
      await tester.pump();

      expect(_value(tester).text, "61 23 45 67 8");
      expect(host.changes, isEmpty);
    });

    testWidgets("a longer pattern keeps the digits without notifying", (WidgetTester tester) async {
      final _Host host = _Host(_spaced);
      await pumpApp(tester, host.build());
      await tester.enterText(_field(), "612345678");
      await tester.pump();
      host.changes.clear();

      await host.update(tester, () => host.pattern = _long);
      await tester.pump();

      expect(_value(tester).text, "612 345678");
      expect(host.changes, isEmpty);

      await _type(tester, "90");
      expect(_value(tester).text, "612 34567890");
      expect(host.changes, <String>["61234567890"]);
    });

    testWidgets("a pattern change that keeps the text keeps the caret", (WidgetTester tester) async {
      final _Host host = _Host(_spaced);
      await pumpApp(tester, host.build());
      await tester.enterText(_field(), "612");
      await tester.pump();
      tester.widget<EditableText>(find.byType(EditableText)).controller.selection =
          const TextSelection.collapsed(offset: 1);
      host.changes.clear();

      await host.update(tester, () => host.pattern = "# ## ## ## ## ##");
      await tester.pump();

      expect(_value(tester).text, "6 12");
      expect(_value(tester).selection, const TextSelection.collapsed(offset: 1));
      expect(host.changes, isEmpty);
    });

    testWidgets("a rebuild with the same pattern leaves the text alone", (WidgetTester tester) async {
      final _Host host = _Host(_spaced);
      await pumpApp(tester, host.build());
      await tester.enterText(_field(), "6123");
      await tester.pump();
      host.changes.clear();

      await host.update(tester, () => host.errorText = "Invalid");
      await tester.pump();

      expect(_value(tester).text, "6 12 3");
      expect(host.changes, isEmpty);
    });
  });

  group("MaskedDigitField decoration", () {
    testWidgets("the hint defaults to the pattern sample", (WidgetTester tester) async {
      await pumpApp(tester, const MaskedDigitField(pattern: _spaced));

      expect(find.text("1 23 45 67 89"), findsOneWidget);
      expect(_decoration(tester).hintText, const DigitMask(_spaced).sample());
    });

    testWidgets("hintText overrides the sample", (WidgetTester tester) async {
      await pumpApp(tester, const MaskedDigitField(pattern: _spaced, hintText: "Digits"));

      expect(find.text("Digits"), findsOneWidget);
      expect(find.text("1 23 45 67 89"), findsNothing);
    });

    testWidgets("the hint follows a pattern change", (WidgetTester tester) async {
      final _Host host = _Host(_spaced);
      await pumpApp(tester, host.build());

      await host.update(tester, () => host.pattern = "##/##/####");

      expect(_decoration(tester).hintText, "12/34/5678");
    });

    testWidgets("labelText is shown and is the accessible name", (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpApp(tester, const MaskedDigitField(pattern: _spaced, labelText: "Number"));

      expect(find.text("Number"), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel("Number")),
        isSemantics(label: "Number", isTextField: true),
      );
      semantics.dispose();
    });

    testWidgets("without labelText the hint is the accessible name", (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpApp(tester, const MaskedDigitField(pattern: _spaced, hintText: "Digits"));

      expect(
        tester.getSemantics(find.bySemanticsLabel("Digits")),
        isSemantics(label: "Digits", isTextField: true),
      );
      semantics.dispose();
    });

    testWidgets("errorText is shown in cs.error", (WidgetTester tester) async {
      await pumpApp(tester, const MaskedDigitField(pattern: _spaced, errorText: "Invalid"));

      expect(find.text("Invalid"), findsOneWidget);
      expect(tester.widget<Text>(find.text("Invalid")).style?.color, _scheme(tester).error);
    });

    testWidgets("errorText recolours the border with cs.error", (WidgetTester tester) async {
      await pumpApp(tester, const MaskedDigitField(pattern: _spaced));
      final ColorScheme cs = _scheme(tester);
      expect(find.byType(InputDecorator), paints..rrect(color: cs.outline));

      await pumpApp(tester, const MaskedDigitField(pattern: _spaced, errorText: "Invalid"));
      // The decorator animates the border change.
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(InputDecorator), paints..rrect(color: cs.error));
      expect(find.byType(InputDecorator), isNot(paints..rrect(color: cs.outline)));
    });

    testWidgets("keyboardType defaults to number and is forwarded", (WidgetTester tester) async {
      await pumpApp(tester, const MaskedDigitField(pattern: _spaced));
      expect(tester.widget<TextField>(_field()).keyboardType, TextInputType.number);

      await pumpApp(tester, const MaskedDigitField(pattern: _spaced, keyboardType: TextInputType.phone));
      expect(tester.widget<TextField>(_field()).keyboardType, TextInputType.phone);
    });

    testWidgets("borders use cs.outline at rest and cs.primary on focus", (WidgetTester tester) async {
      await pumpApp(tester, const MaskedDigitField(pattern: _spaced));
      final ColorScheme cs = _scheme(tester);
      final InputDecoration decoration = _decoration(tester);

      final OutlineInputBorder rest = decoration.enabledBorder! as OutlineInputBorder;
      final OutlineInputBorder focused = decoration.focusedBorder! as OutlineInputBorder;
      expect(rest.borderSide.color, cs.outline);
      expect(rest.borderRadius, BorderRadius.circular(8));
      expect(focused.borderSide.color, cs.primary);
      expect(focused.borderSide.width, 1.5);
      expect(focused.borderRadius, BorderRadius.circular(8));
      expect(decoration.contentPadding, const EdgeInsets.all(kDefaultPadding * 2));
    });

    testWidgets("the field is at least kMinTapTarget tall", (WidgetTester tester) async {
      await pumpApp(tester, const MaskedDigitField(pattern: _spaced));

      expect(_decoration(tester).constraints?.minHeight, kMinTapTarget);
      expect(tester.getSize(_field()).height, greaterThanOrEqualTo(kMinTapTarget));
    });
  });

  group("MaskedDigitField themes", () {
    for (final (String name, ThemeData theme) in <(String, ThemeData)>[
      ("light", AppTheme.light()),
      ("dark", AppTheme.dark()),
    ]) {
      testWidgets("renders narrow under the $name theme and disposes cleanly", (WidgetTester tester) async {
        await pumpApp(
          tester,
          const MaskedDigitField(pattern: "#### #### #### ####", labelText: "Number", errorText: "Invalid"),
          theme: theme,
          surfaceSize: const Size(240, 400),
        );
        await tester.enterText(_field(), "4111111111111111");
        await tester.pump();

        expect(find.text("4111 1111 1111 1111"), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      });
    }
  });
}

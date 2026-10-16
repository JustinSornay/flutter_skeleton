// choice_option_test.dart
//
// Unit tests for ChoiceOption<T> (lib/widgets/custom/_base/choice_option.dart).
// Covers: defaults of the optional fields, generic value typing.

import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/custom/_base/choice_option.dart";
import "package:flutter_test/flutter_test.dart";

enum _Size { small, large }

void main() {
  test("optional fields default to null and enabled to true", () {
    const ChoiceOption<int> option = ChoiceOption<int>(value: 1, label: "One");
    expect(option.value, 1);
    expect(option.label, "One");
    expect(option.description, isNull);
    expect(option.trailing, isNull);
    expect(option.icon, isNull);
    expect(option.enabled, isTrue);
    expect(option.semanticsLabel, isNull);
  });

  test("keeps every field it is given", () {
    const ChoiceOption<_Size> option = ChoiceOption<_Size>(
      value: _Size.large,
      label: "Large",
      description: "Second line",
      trailing: "12",
      icon: Icons.check,
      enabled: false,
      semanticsLabel: "Large size",
    );
    expect(option.value, _Size.large);
    expect(option.description, "Second line");
    expect(option.trailing, "12");
    expect(option.icon, Icons.check);
    expect(option.enabled, isFalse);
    expect(option.semanticsLabel, "Large size");
  });

  test("selection is matched on value", () {
    const List<ChoiceOption<_Size>> options = <ChoiceOption<_Size>>[
      ChoiceOption<_Size>(value: _Size.small, label: "Small"),
      ChoiceOption<_Size>(value: _Size.large, label: "Large"),
    ];
    final ChoiceOption<_Size> selected =
        options.firstWhere((ChoiceOption<_Size> o) => o.value == _Size.large);
    expect(selected.label, "Large");
  });
}

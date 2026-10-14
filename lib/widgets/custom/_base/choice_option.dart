// choice_option.dart
//
// ChoiceOption<T> — the single option value class shared by every picker in
// widgets/custom/ (chip rows, segmented pickers, select sheets, chip bars,
// expandable groups, filterable tables). `_base/` holds shared value
// classes, not widgets (same convention as providers/_base, api/dtos/_base).
//
// Each widget's dartdoc states which fields it renders.

import "package:flutter/widgets.dart";

/// One selectable option of a picker.
@immutable
final class ChoiceOption<T> {
  const ChoiceOption({
    required this.value,
    required this.label,
    this.description,
    this.trailing,
    this.icon,
    this.enabled = true,
    this.semanticsLabel,
  });

  /// Identity of the option, compared with `==`: pass enums, ids or value types.
  final T value;

  /// Visible label, already localised.
  final String label;

  /// Optional second line (sublabel, description, subtitle).
  final String? description;

  /// Optional short text on the right (hint, badge, count).
  final String? trailing;

  /// Leading icon where the widget supports one.
  final IconData? icon;

  /// `false` greys the option out and ignores taps.
  final bool enabled;

  /// Screen-reader label; defaults to [label].
  final String? semanticsLabel;
}

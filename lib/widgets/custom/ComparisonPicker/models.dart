// models.dart
//
// Value class of ComparisonPicker: ComparisonPickerItem, one selectable row
// (asserts that a tone is always named by a value or a tone label).
// No UI here.

part of "index.dart";

/// One selectable row of a [ComparisonPicker].
@immutable
final class ComparisonPickerItem {
  /// Stable id reported through [ComparisonPicker.onChanged]. Unique across
  /// the primary and secondary groups.
  final String id;

  /// Main row text (bold, takes the free width), already localised.
  final String label;

  /// Optional muted second line under [label] (e.g. a category or a "New"
  /// flag). Hidden when null or empty.
  final String? subtitle;

  /// Optional value at the end of the row, already formatted by the host
  /// (e.g. "67 %", "4.2", "12 €").
  final String? valueLabel;

  /// Optional status of the value. When set, the value is drawn in a tone
  /// pill (`StatusTones` container / onContainer) led by [StatusTone.icon],
  /// so the colour is never the only cue.
  final StatusTone? tone;

  /// Name of [tone], already localised (e.g. "High", "At risk"). Read by
  /// screen readers as the tone icon's label, just before [valueLabel];
  /// shown as the pill text when there is no [valueLabel]. Required when
  /// [tone] is set without [valueLabel], so a pill is never an unlabelled
  /// icon. Ignored without [tone].
  final String? toneLabel;

  const ComparisonPickerItem({
    required this.id,
    required this.label,
    this.subtitle,
    this.valueLabel,
    this.tone,
    this.toneLabel,
  }) : assert(tone == null || valueLabel != null || toneLabel != null, "A tone without valueLabel needs a toneLabel.");
}

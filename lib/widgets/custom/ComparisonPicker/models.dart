// models.dart
//
// Value class of ComparisonPicker: ComparisonPickerItem, one selectable row
// (asserts that a tone is always paired with a non-empty value or tone
// label).
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
  /// (e.g. "67 %", "4.2", "12 €"). Hidden when null or empty.
  final String? valueLabel;

  /// Optional status of the value, drawn as a tone pill (`StatusTones`
  /// container / onContainer) led by [StatusTone.icon] and holding a text,
  /// so the colour is never the only cue. The pill holds [toneLabel], or
  /// [valueLabel] when there is no [toneLabel].
  final StatusTone? tone;

  /// Name of [tone], already localised (e.g. "High", "At risk"). Shown as
  /// the pill text; [valueLabel], when set, then follows the pill as plain
  /// text (read in that order). A [tone] needs a non-empty [valueLabel] or
  /// [toneLabel] (asserted), so a pill is never an unlabelled icon. Ignored
  /// without [tone].
  final String? toneLabel;

  const ComparisonPickerItem({
    required this.id,
    required this.label,
    this.subtitle,
    this.valueLabel,
    this.tone,
    this.toneLabel,
  }) : assert(
         tone == null || (valueLabel != null && valueLabel != "") || (toneLabel != null && toneLabel != ""),
         "A tone needs a non-empty valueLabel or toneLabel.",
       );
}

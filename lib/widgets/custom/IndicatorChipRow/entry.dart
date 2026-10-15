// entry.dart
//
// IndicatorChipEntry — immutable description of one chip of an
// IndicatorChipRow: label, optional icon, tone and active flag.

part of "index.dart";

/// One chip in an [IndicatorChipRow].
@immutable
final class IndicatorChipEntry {
  /// Visible text, already localised; may include a count or a unit.
  final String label;

  /// Optional leading icon in the chip colour. Omitted when null.
  final IconData? icon;

  /// Tone of the chip when [active]. Ignored when inactive.
  ///
  /// An active entry with the neutral tone (the default) looks the same as
  /// a muted one, so [active] only shows when [tone] is not neutral.
  final StatusTone tone;

  /// When false the chip renders muted, in [StatusTone.neutral].
  ///
  /// An active entry with the neutral tone (the default) looks the same as
  /// a muted one, so [active] only shows when [tone] is not neutral.
  final bool active;

  /// Screen-reader label. Falls back to [label].
  final String? semanticsLabel;

  const IndicatorChipEntry({
    required this.label,
    this.icon,
    this.tone = StatusTone.neutral,
    this.active = true,
    this.semanticsLabel,
  });
}

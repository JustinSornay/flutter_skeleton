// cell.dart
//
// StatusHeatmapCell — immutable description of one column of a
// StatusHeatmapRow: caption, value, status tone and spoken status, or an
// empty placeholder when the value is missing.

part of "index.dart";

/// One column of a [StatusHeatmapRow].
@immutable
final class StatusHeatmapCell {
  /// Cell showing [value] in the colour of [tone], with the tone icon (or
  /// [icon]) as its non-colour status cue.
  const StatusHeatmapCell({
    required this.label,
    required double this.value,
    required String this.statusLabel,
    this.tone = StatusTone.neutral,
    this.icon,
  });

  /// Placeholder for a missing value: `—` and the neutral icon in
  /// `cs.onSurfaceVariant`, announced as
  /// `"<label>, custom.status_heatmap_row.no_value"`.
  const StatusHeatmapCell.empty({required this.label})
      : value = null,
        statusLabel = null,
        tone = StatusTone.neutral,
        icon = null;

  /// Short caption under the value, one line with ellipsis.
  final String label;

  /// Final value; counts up from 0 on first build. Null for an empty cell.
  final double? value;

  /// Spoken status name appended to the semantics label. Null for an empty
  /// cell.
  final String? statusLabel;

  /// Tone of the value, the icon, the tint and the border.
  final StatusTone tone;

  /// Status icon replacing [StatusTone.icon], e.g. to tell apart two levels
  /// sharing a tone. Null → `tone.icon`.
  final IconData? icon;

  /// Whether this is a [StatusHeatmapCell.empty] placeholder.
  bool get isEmpty => value == null;
}

// index.dart
//
// StatusHeatmapRow — compact, non-scrolling strip of equal-width cells that
// compares one numeric value across a few ordered columns (periods,
// variants, options…). Each cell shows the value (counting up from 0), a
// caption and its tone icon, tinted by a StatusTone. Value class:
// StatusHeatmapCell (cell.dart); tree in view.dart and widgets/.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "cell.dart";
part "view.dart";
part "widgets/cell_view.dart";
part "widgets/count_up_text.dart";

/// Formats a cell value for display. Applied to the final value (visible
/// text and semantics label) and to every count-up frame.
typedef StatusHeatmapValueFormatter = String Function(double value);

/// Titled strip of equal-width status cells. Never scrolls horizontally.
///
/// - Layout: a `cs.surfaceContainerHigh` card (radius 12, padding
///   2 × [kDefaultPadding]) holding the optional [title] and one row where
///   every cell is `Expanded`, in the order of [cells] (never re-sorted),
///   [kDefaultPadding] apart.
/// - Cell: minimum height 72, fill = tone foreground at 10 % alpha, border =
///   tone foreground at 25 % alpha, radius 8. Top to bottom: the value
///   (16 / w800, tone foreground, scaled down to fit the cell), the
///   [StatusHeatmapCell.label] caption (9 / w500, `cs.onSurfaceVariant`, one
///   line, ellipsis) and the status icon (14 dp, tone foreground) — the
///   non-colour cue next to the tint.
/// - Tone: `StatusTones.colorsOf(context, cell.tone).foreground`;
///   [StatusTone.neutral] resolves to `cs.onSurfaceVariant`.
/// - Count-up: the value tweens linearly from 0 to its final value over
///   500 ms on first build (and from the shown value to the new one when it
///   changes). The duration goes through [resolveMotion]: under reduced
///   motion the final value is shown at once.
/// - Format: [formatValue], or by default two decimals with intl
///   `NumberFormat.decimalPatternDigits` for the ambient locale (`0.58` in
///   English, `0,58` in French).
/// - Empty cell ([StatusHeatmapCell.empty]): value `—` and the neutral icon,
///   both in `cs.onSurfaceVariant`.
/// - Semantics: one node per cell,
///   `"<label>, <formatted value>, <statusLabel>"`, or
///   `"<label>, custom.status_heatmap_row.no_value"` for an empty cell; the
///   child texts are excluded so nothing is read twice.
///   The [title] is a semantics header.
///
/// Inert and overlay-free: no tooltip, no callback. Content strings
/// ([title], labels, status labels) are already localised by the host.
final class StatusHeatmapRow extends StatelessWidget with _ViewMixin {
  /// Cells rendered left to right in the given order.
  final List<StatusHeatmapCell> cells;

  /// Optional overline header (10 / w700, letter spacing 1.5,
  /// `cs.onSurfaceVariant`), rendered as given. Null → no header.
  final String? title;

  /// Value formatter. Null → two decimals for the ambient locale.
  final StatusHeatmapValueFormatter? formatValue;

  const StatusHeatmapRow({
    super.key,
    required this.cells,
    this.title,
    this.formatValue,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

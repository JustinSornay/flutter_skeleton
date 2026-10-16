// index.dart
//
// StatusStrip — a compact strip of N equal period cells (months, days,
// weeks, hours…). Each cell is filled with the colour of the category its
// value belongs to and shows a short period label; a legend lists the
// categories present. Optional overlays: comparison (split cells) and
// agreement (corner dot / dashed outline across alternative rows).
// Value classes: StatusStripCategory, StatusStripSeries. The tree lives in
// view.dart; the per-period analysis is in controllers/; the cell, the
// legends and the markers are private parts in widgets/.

import "dart:math" as math;

import "package:easy_localization/easy_localization.dart" hide TextDirection;
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "controllers/strip_analysis.dart";
part "view.dart";
part "widgets/category_legend.dart";
part "widgets/comparison_legend.dart";
part "widgets/legend_item.dart";
part "widgets/markers.dart";
part "widgets/strip_cell.dart";

/// One category a [StatusStrip] value can belong to.
///
/// The order of [StatusStrip.categories] is the legend order (for example
/// low → high). Category values should be unique.
@immutable
final class StatusStripCategory<T> {
  /// Matched with `==` against the series values.
  final T value;

  /// Legend and screen-reader text, already localised (and worded for its
  /// audience) by the host.
  final String label;

  /// Cell colours: fill = tone `container`, period label = tone
  /// `onContainer` (`StatusTones.colorsOf(context, tone)`).
  ///
  /// The default [StatusTone.neutral] fills with `cs.surfaceContainerHighest`,
  /// whose legend dot barely shows on `cs.surface`: give each category a
  /// distinct non-neutral tone (or an explicit [color]) so the categories
  /// stay apart.
  final StatusTone tone;

  /// Explicit data-palette fill replacing the tone `container`. The period
  /// label keeps the tone `onContainer`, so pick a [tone] whose
  /// `onContainer` reads on this colour.
  final Color? color;

  const StatusStripCategory({
    required this.value,
    required this.label,
    this.tone = StatusTone.neutral,
    this.color,
  });
}

/// One row of values, one per period.
@immutable
final class StatusStripSeries<T> {
  /// Values in period order; `values.length` must equal the number of
  /// periods (asserted when the strip renders).
  final List<T> values;

  /// Series name shown in the comparison legend, already localised. Null →
  /// the built-in `custom.status_strip.reference` / `comparison` text.
  final String? label;

  const StatusStripSeries({required this.values, this.label});
}

/// Strip of equal period cells coloured by category, with a legend of the
/// categories present.
///
/// Renders, top to bottom:
/// - one row of `periodLabels.length` cells, [cellHeight] tall, splitting
///   the available width evenly with a 2 dp gap (no gap when the width is
///   smaller than the gaps; the cell width never goes below 0). Each cell
///   (radius 3) is filled with its category fill (`color`, else the tone
///   `container`) and shows its period label centred (w700,
///   `max(7, cellWidth × 0.32)` px, tone `onContainer`), scaled down when it
///   does not fit. A value matching no category renders as an empty cell
///   (`cs.surface` fill, 1 dp `cs.outlineVariant` border,
///   `cs.onSurfaceVariant` label), distinct from every tone fill, and is
///   left out of the legend.
/// - comparison mode ([comparison] set): each cell is split horizontally,
///   [primary] category on top and [comparison] category below; the label
///   keeps the primary category's `onContainer`. A two-entry legend follows:
///   a `cs.primary` dash with `custom.status_strip.reference_labelled`
///   (`{label} (réf.)`) and a `cs.tertiary` dash with
///   `custom.status_strip.comparison_labelled` (`{label} (test)`); a null
///   series label shows `custom.status_strip.reference` / `comparison`
///   instead.
/// - agreement mode ([agreementSeries] set, two rows or more): at each
///   period, when every row holds a different value the cell gets a dashed
///   `cs.error` outline; when some rows agree and others differ it gets a
///   5 dp corner dot in the warning tone `foreground`, 2 dp from the end and
///   bottom edges. Both markers are drawn at any cell size: the dot is at
///   most half, its inset and the outline's 3 dp corner cut at most a
///   quarter of the cell's shortest side, so on narrow cells the dot shrinks
///   but stays inside the cell and the outline keeps all four sides. The
///   cell fill still comes from [primary].
/// - the legend (9 / w700, `cs.onSurfaceVariant`): an 8 dp dot in the fill
///   colour plus the label of each category present in [primary] (and
///   [comparison]), in [categories] order, then
///   `custom.status_strip.partial_agreement` and
///   `custom.status_strip.full_disagreement` entries, each only when its
///   marker is shown. Entries wrap onto new lines; each entry stays on one
///   line and ends with an ellipsis when it is wider than the strip. No
///   legend is drawn when it would be empty.
///
/// Accessibility: each cell is one semantics node labelled
/// `custom.status_strip.cell` (`{period}: {status}`) or, in comparison mode,
/// `custom.status_strip.cell_comparison` (`{period}: {primary} /
/// {comparison}`); with a marker, that text and the marker text are joined
/// by `custom.status_strip.cell_marker` (`{cell}, {marker}`). The period
/// comes from [periodSemanticLabels] (falls back to [periodLabels]); an
/// unknown value reads `custom.status_strip.unknown`. Colours are always
/// paired with the period label, the legend text and these labels.
///
/// Needs a bounded width. Display-only and stateless; no `Overlay` ancestor
/// is needed. Content strings (period labels, category and series labels)
/// are already localised by the host.
final class StatusStrip<T> extends StatelessWidget with _ViewMixin<T> {
  /// Short label drawn inside each cell (e.g. month initials). Its length
  /// sets the number of periods; must not be empty.
  final List<String> periodLabels;

  /// Full period names for screen readers, same length as [periodLabels].
  /// Null → [periodLabels].
  final List<String>? periodSemanticLabels;

  /// Ordered categories (legend order). Fields used: `value`, `label`,
  /// `tone`, `color`.
  final List<StatusStripCategory<T>> categories;

  /// Main row, always rendered: fills every cell (top half in comparison
  /// mode).
  final StatusStripSeries<T> primary;

  /// Comparison row: non-null splits each cell, [primary] on top and this
  /// series below. Exclusive with [agreementSeries].
  final StatusStripSeries<T>? comparison;

  /// Alternative rows (each one value per period) compared at each period:
  /// all equal → no marker, all different → dashed outline, otherwise →
  /// corner dot. Fewer than two rows → no marker. Exclusive with
  /// [comparison].
  final List<List<T>>? agreementSeries;

  /// False hides every legend (e.g. stacked strips sharing one legend).
  final bool showLegend;

  /// Height of every cell; the cell width comes from the available width.
  final double cellHeight;

  const StatusStrip({
    super.key,
    required this.periodLabels,
    this.periodSemanticLabels,
    required this.categories,
    required this.primary,
    this.comparison,
    this.agreementSeries,
    this.showLegend = true,
    this.cellHeight = 24,
  })  : assert(comparison == null || agreementSeries == null, "comparison and agreementSeries are exclusive"),
        assert(cellHeight > 0, "cellHeight must be positive");

  /// The 12 abbreviated month names of [locale] (`DateFormat.MMM`, e.g.
  /// "Jan" … "Dec"), or the full names (`DateFormat.MMMM`) when
  /// [abbreviated] is false — handy for [periodSemanticLabels].
  ///
  /// Pass `context.locale.toLanguageTag()`. The date symbols of [locale]
  /// must be loaded (done by the localization delegates of the app, or
  /// `initializeDateFormatting` from `package:intl`).
  static List<String> monthLabels(String locale, {bool abbreviated = true}) {
    final DateFormat format = abbreviated ? DateFormat.MMM(locale) : DateFormat.MMMM(locale);
    return List<String>.generate(
      DateTime.monthsPerYear,
      (int index) => format.format(DateTime(2000, index + 1)),
      growable: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

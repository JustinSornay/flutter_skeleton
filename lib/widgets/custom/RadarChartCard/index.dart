// index.dart
//
// RadarChartCard — a collapsible card that draws an N-axis radar (spider)
// chart with fl_chart: one main series, an optional comparison series drawn
// beneath it, optional weight suffixes on the axis titles and an optional
// help button. The value classes live in radar_axis.dart and
// radar_series.dart, the card in view.dart and the chart in
// widgets/radar_plot.dart.

import "package:easy_localization/easy_localization.dart";
import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "radar_axis.dart";
part "radar_series.dart";
part "view.dart";
part "widgets/radar_plot.dart";

/// Collapsible card that shows [series] on a radar chart with one spoke per
/// entry of [axes] (clockwise from the top). Use it for any multi-criteria
/// breakdown: a score split into factors, a skills profile, ratings…
///
/// Renders nothing (`SizedBox.shrink`) when [series] is null, when its
/// values are empty, or when there are fewer than 3 [axes].
///
/// Card: `Card(elevation: 0)`, `cs.surfaceContainerLowest`, radius 24 and a
/// `cs.outlineVariant` border (the CollapsibleSectionCard tokens), holding an
/// `ExpansionTile` that manages its own open state and starts collapsed
/// unless [initiallyExpanded]. While collapsed the chart is not built.
///
/// Header: [icon] in a 32 dp tile (`cs.primary` at 10 % behind a 16 dp
/// `cs.primary` glyph), [title] (`titleSmall` w800, `cs.onSurface`), then,
/// when [onHelp] is set, a `help_outline_rounded` button of [kMinTapTarget]
/// with the tooltip [helpLabel] (default `custom.radar_chart_card.help`).
/// Tapping it calls [onHelp] and does not toggle the card. A
/// `cs.onSurfaceVariant` chevron turns when the card opens.
///
/// Body: a `cs.outlineVariant` divider, then the chart, [chartHeight] tall,
/// with `2 × kDefaultPadding` around it:
/// - the scale always runs from 0 at the centre to [maxValue] on the outer
///   ring (two transparent anchor data sets), with 4 unlabelled rings in
///   `cs.outlineVariant`;
/// - each value is read from [RadarSeries.values] by [RadarAxis.key]
///   (missing → 0) and clamped to `[0, maxValue]`;
/// - [comparison], when set, is drawn under [series] with a thinner stroke
///   (1.5 dp, 2 dp dots) than the main series (2 dp, 3 dp dots). The stroke
///   is [RadarSeries.color] (default `cs.tertiary` for the comparison,
///   `cs.primary` for the main series) and the fill is the same colour at
///   25 % (comparison) or 20 % (main). Unset, its slot holds an invisible
///   copy of the main polygon, so toggling [comparison] fades the overlay
///   in or out without moving the main series;
/// - axis titles (`labelSmall` w600, `cs.onSurfaceVariant`) are
///   [RadarAxis.label], or `custom.radar_chart_card.axis_weight` with
///   `{label}` and `{percent}` when [RadarAxis.weight] is set;
/// - touch is disabled. Value changes animate over 500 ms (`Curves.easeOut`),
///   instantly under reduced motion; the open / close animation uses
///   `kMotionShort`, also through `resolveMotion`.
///
/// Accessibility: the chart is one semantics node whose label lists every
/// axis as `custom.radar_chart_card.axis_value` (`{label}` = the axis title,
/// `{percent}` = value / [maxValue]), one per line, then, when [comparison]
/// is set, `custom.radar_chart_card.comparison` followed by the comparison
/// values. Percentages use intl `NumberFormat.percentPattern` for the
/// ambient locale.
///
/// No `Material` ancestor is needed (the card is its own `Material`). When
/// [onHelp] is set, the help button's `Tooltip` needs an `Overlay` ancestor
/// (a routed page or a modal): do not mount the card in `Layout`, above the
/// Navigator. Content strings ([title], labels) are already localised by the
/// host.
final class RadarChartCard extends StatelessWidget with _ViewMixin {
  /// Spokes in display order, clockwise from the top. Fewer than 3 renders
  /// nothing.
  final List<RadarAxis> axes;

  /// Main series. Null, or empty values, renders nothing.
  final RadarSeries? series;

  /// Optional overlay drawn beneath [series] with a thinner stroke.
  final RadarSeries? comparison;

  /// Header text, already localised.
  final String title;

  /// Leading header icon, drawn in a `cs.primary` tinted tile.
  final IconData icon;

  /// Shows a help button before the chevron when non-null. Tapping it calls
  /// this callback and does not toggle the card.
  final VoidCallback? onHelp;

  /// Tooltip and screen-reader label of the help button. Null →
  /// `custom.radar_chart_card.help`.
  final String? helpLabel;

  /// Whether the card starts open.
  final bool initiallyExpanded;

  /// Height of the chart area inside the open card.
  final double chartHeight;

  /// Value drawn on the outer ring; the scale always starts at 0.
  final double maxValue;

  const RadarChartCard({
    super.key,
    required this.axes,
    required this.series,
    required this.title,
    this.comparison,
    this.icon = Icons.radar_rounded,
    this.onHelp,
    this.helpLabel,
    this.initiallyExpanded = false,
    this.chartHeight = 260,
    this.maxValue = 1.0,
  }) : assert(maxValue > 0, "maxValue must be positive"),
       assert(chartHeight > 0, "chartHeight must be positive");

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

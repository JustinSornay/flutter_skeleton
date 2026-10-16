// index.dart
//
// StatStrip — responsive strip of summary stat tiles (KPIs) for dashboards,
// report headers and detail headers. Each StatStripItem renders as an
// outlined MetricTile; StatStripLayout picks one row of equal tiles or a
// two-column grid sized from the parent width. The tree lives in view.dart.

import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/MetricTile/index.dart";

part "view.dart";

/// Arrangement of the tiles of a [StatStrip].
enum StatStripLayout {
  /// One row: every tile gets an equal share of the width and the height of
  /// the tallest tile.
  row,

  /// Two columns: rows of two tiles, each half of the width minus the gap;
  /// the tiles of a row share its height, and an odd last tile keeps half
  /// the width at the start edge.
  grid,
}

/// One tile of a [StatStrip]. Its fields map one to one to the
/// [MetricTile] parameters of the same name.
@immutable
final class StatStripItem {
  const StatStripItem({
    required this.label,
    this.value,
    this.unit,
    this.icon,
    this.valueTone,
    this.caption,
    this.captionTone = StatusTone.neutral,
    this.semanticsLabel,
  });

  /// Stat name, already localised. Shown upper-cased; announced as given.
  final String label;

  /// Formatted value, already localised (e.g. "850", "62 %", "18").
  /// Null or empty → a muted "—" placeholder, announced as "no value".
  final String? value;

  /// Short unit shown smaller after [value], on its baseline (e.g. "/100",
  /// "ms"). Ignored without a value.
  final String? unit;

  /// Optional decorative icon of the label row.
  final IconData? icon;

  /// Tint of the value (tone foreground) plus its [StatusTone.icon] before
  /// the value unless `neutral`. Null → `cs.onSurface`, no icon. Neither is
  /// announced: name the status in [caption] or [semanticsLabel].
  final StatusTone? valueTone;

  /// Secondary line under the value (a count, a share, a change…). Hidden
  /// when null or empty.
  final String? caption;

  /// Tint of [caption]; `neutral` is `cs.onSurfaceVariant`.
  final StatusTone captionTone;

  /// Screen-reader label of the tile. Null or empty →
  /// "label, value unit, caption".
  final String? semanticsLabel;
}

/// Responsive strip of stat tiles: one outlined [MetricTile] per item of
/// [items], in order.
///
/// - [StatStripLayout.row] (default): one row of equal-width tiles
///   (`Expanded`) that all take the height of the tallest one
///   (`IntrinsicHeight` + stretch).
/// - [StatStripLayout.grid]: rows of two tiles, each
///   `(available width - kDefaultPadding) / 2` wide, the width coming from
///   the parent constraints (not the screen). The tiles of a row share its
///   height; an odd last tile keeps half the width at the start edge.
/// - Gaps between tiles (horizontal and vertical): [kDefaultPadding].
/// - [padding] surrounds the whole strip (16 × 8 dp by default).
/// - An empty [items] list renders nothing (`SizedBox.shrink`, no padding).
///
/// Each tile is a [MetricTile] with `outlined: true`
/// (`cs.surfaceContainerHighest` fill, 1 dp `cs.outlineVariant` border,
/// radius 10): upper-case label row with the optional icon, 16 / w700 value
/// with its unit, optional caption, all on one line with an ellipsis. Units
/// should stay short: a tile narrower than about 92 dp may not fit a value,
/// a tone icon and a unit side by side, so prefer [StatStripLayout.grid]
/// when the row gets narrow.
///
/// The strip formats nothing and judges nothing: the host passes localised,
/// formatted strings and maps its own thresholds to a [StatusTone].
///
/// Accessibility: each tile is one semantics node labelled
/// [StatStripItem.semanticsLabel], by default "label, value unit, caption".
///
/// Needs a bounded width. No tooltip, so no `Overlay` ancestor is needed.
final class StatStrip extends StatelessWidget with _ViewMixin {
  /// Tiles to render, in order. Empty → nothing is rendered.
  final List<StatStripItem> items;

  /// Row of equal tiles, or two-column grid.
  final StatStripLayout layout;

  /// Space around the strip.
  final EdgeInsetsGeometry padding;

  const StatStrip({
    super.key,
    required this.items,
    this.layout = StatStripLayout.row,
    this.padding = const EdgeInsets.symmetric(horizontal: kDefaultPadding * 2, vertical: kDefaultPadding),
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

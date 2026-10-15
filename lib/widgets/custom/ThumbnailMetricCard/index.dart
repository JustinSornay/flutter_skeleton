// index.dart
//
// ThumbnailMetricCard — list card: a 56 × 56 rounded thumbnail (any
// ImageProvider, icon placeholder when absent or broken), a one-line title
// and optional subtitle, a row of small labelled value columns with an
// optional status-tone marker, and an optional trailing change badge
// (StatusPill with the tone icon). The columns and badge scale down when they
// would squeeze the title below 48 dp; measuring the width for that
// (LayoutBuilder) rules out intrinsic-size parents. Tappable when onTap is
// set. The column value class lives in thumbnail_metric.dart, the tree in
// view.dart, the thumbnail in widgets/thumbnail.dart and one column in
// widgets/metric_column.dart.

import "dart:math" as math;

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";

part "thumbnail_metric.dart";
part "view.dart";
part "widgets/metric_column.dart";
part "widgets/thumbnail.dart";

/// List card comparing a few values of one item: catalogue or search results
/// such as a price now and before, a latency today and yesterday, or a
/// candidate scored under two hypotheses.
///
/// Layout (one row; needs a bounded width and no intrinsic-size parent, see
/// "Hosts" below):
/// - Card: `cs.surfaceContainerLow` fill, 1 dp `cs.outlineVariant` border,
///   radius 16, 12 dp padding (`kDefaultPadding * 1.5`). The card is its own
///   [Material], so the ink of [onTap] shows and no Material ancestor is
///   needed; its theme-change animation goes through `resolveMotion`, so it
///   is instant under reduced motion.
/// - Thumbnail: 56 × 56, radius 8, [BoxFit.cover]. When [image] is null or
///   fails to load, [placeholderIcon] (24 dp, `cs.onSurfaceVariant`) on
///   `cs.surfaceContainerHighest` shows instead.
/// - Title (13 / w800, `cs.onSurface`) and [subtitle] (11 / w500,
///   `cs.onSurfaceVariant`), one line each with an ellipsis; they take the
///   width left by the other parts. An empty subtitle is hidden.
/// - [metrics]: one column per entry, in order, 8 dp apart — the label
///   (9 / w700, letter spacing 0.5, `cs.onSurfaceVariant`) over the value
///   (12 / w800, `cs.onSurface`). A [ThumbnailMetric.tone] adds its
///   [StatusTone.icon] (12 dp, tone foreground) before the value, so the
///   status never shows as colour alone.
/// - [delta]: a dense [StatusPill] in [deltaTone] after the columns, led by
///   the [StatusTone.icon] of [deltaTone] (no icon for
///   [StatusTone.neutral]), so a good or bad change is not shown by colour
///   alone. Null or empty → no badge.
/// - The columns and the badge keep their natural size while the title keeps
///   at least 48 dp; past that (narrow width, large text scale) they scale
///   down together instead of overflowing. Keep labels and values short and
///   the columns few; under very large text scales, prefer fewer columns or
///   a stacked layout in the host.
///
/// The card formats and judges nothing. The host passes localised, formatted
/// text, signs the change and hides it when it rounds to zero, and maps its
/// own scale to a [StatusTone], for instance:
///
/// ```dart
/// ThumbnailMetricCard(
///   title: item.name,
///   metrics: <ThumbnailMetric>[
///     ThumbnailMetric(label: before, value: format(old), tone: toneOf(old), toneLabel: nameOf(old)),
///     ThumbnailMetric(label: after, value: format(now), tone: toneOf(now), toneLabel: nameOf(now)),
///   ],
///   delta: change.abs() < 0.005 ? null : "${change > 0 ? "+" : ""}${change.toStringAsFixed(2)}",
///   deltaTone: change >= 0 ? StatusTone.success : StatusTone.danger,
///   onTap: () => open(item),
/// )
/// ```
///
/// Accessibility: the whole card is one merged semantics node reading the
/// title, the subtitle, each column (label, [ThumbnailMetric.toneLabel],
/// value) and the badge ([deltaSemanticsLabel], else
/// `"custom.thumbnail_metric_card.delta".tr()` with the delta as `value`).
/// The thumbnail is excluded. With [onTap] the node is a button with a tap
/// action; the card is at least 80 dp tall, above the 48 dp target.
///
/// Hosts: the trailing group measures the incoming width (`LayoutBuilder`),
/// so the card cannot sit under an intrinsic-size parent: `IntrinsicWidth`,
/// `IntrinsicHeight` (for instance to give side-by-side cards one height), a
/// `Table` with `IntrinsicColumnWidth`, or the `content` of an `AlertDialog`,
/// which measures it with `IntrinsicWidth`. Layout fails there (an error in
/// debug builds). Give it a width-constrained host such as a list, a page,
/// a sheet or `AppModal`, and give side-by-side cards a fixed height instead
/// of `IntrinsicHeight`.
///
/// No tooltip, so no `Overlay` ancestor is needed.
final class ThumbnailMetricCard extends StatelessWidget with _ViewMixin {
  /// Main line, already localised; one line with an ellipsis.
  final String title;

  /// Secondary line under [title]. Null or empty → hidden.
  final String? subtitle;

  /// Thumbnail ([NetworkImage], [AssetImage], [MemoryImage], …). Null or a
  /// failed load → [placeholderIcon].
  final ImageProvider<Object>? image;

  /// Icon of the thumbnail placeholder.
  final IconData placeholderIcon;

  /// Value columns, in display order; empty → none.
  final List<ThumbnailMetric> metrics;

  /// Change badge text, already formatted and signed by the host (e.g.
  /// "+0.13", "−12 ms"). Null or empty → no badge.
  final String? delta;

  /// Tone of the change badge (e.g. success when the change is good, danger
  /// when it is bad). Any tone but [StatusTone.neutral] also draws its
  /// [StatusTone.icon] in the badge.
  final StatusTone deltaTone;

  /// Screen-reader label of the badge. Null or empty →
  /// `"custom.thumbnail_metric_card.delta".tr()` with [delta] as `value`.
  /// Name the judgement here when [deltaTone] carries one.
  final String? deltaSemanticsLabel;

  /// Called when the card is tapped. Null → no ink, not a button.
  final VoidCallback? onTap;

  const ThumbnailMetricCard({
    super.key,
    required this.title,
    this.subtitle,
    this.image,
    this.placeholderIcon = Icons.image_outlined,
    this.metrics = const <ThumbnailMetric>[],
    this.delta,
    this.deltaTone = StatusTone.neutral,
    this.deltaSemanticsLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

// index.dart
//
// ClusteredValueAxis<T> — a horizontal axis of normalised values (0–1)
// plotted as tappable bubbles over optional ValueBand backgrounds, with one
// optional reference marker. Points that would overlap on screen merge into
// "N items" pills whose popover lists the members; a reference that overlaps
// an item merges with it into a reference pill. Single selection (a point
// id, or the reference as null) is reported through onSelect.
//
// The popover state lives in view_model.dart, the tree in view.dart, the
// pure layout maths in controllers/axis_layout.dart and the private parts in
// widgets/. Bands use the shared ValueBand (custom/_base/value_band.dart).

import "dart:math" as math;

import "package:easy_localization/easy_localization.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/_base/value_band.dart";

part "controllers/axis_layout.dart";
part "view_model.dart";
part "view.dart";
part "widgets/axis_header.dart";
part "widgets/band_track.dart";
part "widgets/cluster_pill.dart";
part "widgets/group_popover.dart";
part "widgets/pill_shell.dart";
part "widgets/pill_slot.dart";
part "widgets/popover_row.dart";
part "widgets/rank_badge.dart";
part "widgets/reference_marker.dart";
part "widgets/reference_pill.dart";
part "widgets/slot_visual.dart";
part "widgets/value_bubble.dart";

/// One point plotted on a [ClusteredValueAxis].
@immutable
final class ValueAxisPoint<T extends Object> {
  const ValueAxisPoint({
    required this.id,
    required this.value,
    required this.label,
    this.caption,
  }) : assert(value >= 0.0 && value <= 1.0, "value must be in [0, 1]");

  /// Stable identity used for selection, compared with `==`. Must be unique
  /// within [ClusteredValueAxis.points].
  final T id;

  /// Position on the axis, normalised to [0, 1].
  final double value;

  /// Popover primary line and screen-reader label, already localised.
  final String label;

  /// Optional popover secondary line, already localised.
  final String? caption;
}

/// Horizontal axis of normalised values with collision clustering.
///
/// Renders a `cs.surfaceContainerLow` panel (bottom `cs.outlineVariant`
/// border) holding, top to bottom:
/// - a header row, only when [title] is set: optional [icon] in a
///   `cs.primaryContainer` disc, [title], the point count label
///   (`custom.clustered_value_axis.count`, worded as a label such as
///   "Items: {count}" so it reads for one point too) and, when
///   [highlightBest], a star with the best value
///   (`custom.clustered_value_axis.best`).
/// - a 64 dp axis zoomed on the data (the union of [points] and
///   [reference], plus 10 % of the span on each side, clamped to
///   [0.015, 0.06] and to [0, 1]). A 16 dp `cs.surfaceContainerHighest`
///   track runs along it with the [bands] painted at their `[from, to)`
///   position (`ValueBand.resolveColor`: tone `container` unless `color`),
///   clipped to the visible range; gaps show the track. Band labels are
///   exposed to screen readers only.
///
/// Items on the axis line:
/// - each point is a 30 dp bubble showing [formatValue] of its value
///   (default `(value * 100).round()`, scaled down to fit). Selected
///   ([selectedId]) bubbles are filled `cs.primary` with a ring.
/// - points closer than one bubble, or whose pills would overlap, merge
///   into a stadium pill "N items" (`custom.clustered_value_axis.cluster`),
///   placed at its highest member. It fills when open or when a member is
///   selected. Tapping it toggles a 260 dp popover listing the members,
///   highest first: rank badge (1 = highest value, ties share a rank),
///   [ValueAxisPoint.label], [ValueAxisPoint.caption] and the value.
///   Tapping a row selects it and closes the popover; tapping outside
///   closes it. Only one popover is open at a time.
/// - [reference], when set, is a 32 dp `cs.inverseSurface` square showing
///   its value over [referenceIcon], with a ring while it is the active
///   selection ([selectedId] null). When it overlaps an item, both merge
///   into a reference pill (`custom.clustered_value_axis.reference_group`)
///   whose popover lists the reference row ([referenceLabel], default
///   `custom.clustered_value_axis.reference`) first, then the members.
/// - with [highlightBest], the point(s) holding the highest value get a
///   star (bubble, pill and popover badge) in `cs.tertiary`.
///
/// Tapping a bubble or a row calls [onSelect] with its id; tapping the
/// reference marker or row calls it with `null`. With [onSelect] null,
/// bubbles, the marker and rows are inert; pills still open their popover.
///
/// Every tappable element is [kMinTapTarget] tall and has a semantics
/// label (`label, caption, value`). Bubble and marker hit boxes never reach
/// into a neighbour's visible area: they are [kMinTapTarget] wide, pushed
/// away from a close neighbour, and narrow to the room left only between
/// two close neighbours. Pills announce their expanded state, the
/// `custom.clustered_value_axis.open_group` hint and, like bubbles and the
/// marker, whether they hold the selection. Empty [points] render
/// [SizedBox.shrink]. Needs a bounded width.
///
/// The popover closes when [points] (id, value, label or caption) or
/// [reference] change, or when a resize regroups the open pill.
///
/// Needs an `Overlay` ancestor (a routed page or a modal): the popover is
/// shown through an [OverlayPortal].
final class ClusteredValueAxis<T extends Object> extends StatefulWidget {
  /// Plotted points; ids must be unique. Empty renders nothing.
  final List<ValueAxisPoint<T>> points;

  /// Reference value in [0, 1]; null draws no marker and fuses nothing.
  final double? reference;

  /// Reference row and semantics label; defaults to
  /// `custom.clustered_value_axis.reference`.
  final String? referenceLabel;

  /// Icon of the reference marker, pill and popover row.
  final IconData referenceIcon;

  /// Id of the selected point; null means the reference is selected.
  final T? selectedId;

  /// Called with the tapped point's id, or `null` for the reference.
  final ValueChanged<T?>? onSelect;

  /// Background bands in the axis' 0–1 value units.
  final List<ValueBand> bands;

  /// Text of a value in bubbles, rows and the header; keep it to about
  /// three characters. Defaults to `(value * 100).round()`.
  final String Function(double value)? formatValue;

  /// Stars the highest value and shows it in the header.
  final bool highlightBest;

  /// Header title, already localised; null hides the header row.
  final String? title;

  /// Leading header icon.
  final IconData? icon;

  const ClusteredValueAxis({
    super.key,
    required this.points,
    this.reference,
    this.referenceLabel,
    this.referenceIcon = Icons.person_pin_circle_rounded,
    this.selectedId,
    this.onSelect,
    this.bands = const <ValueBand>[],
    this.formatValue,
    this.highlightBest = true,
    this.title,
    this.icon,
  }) : assert(
         reference == null || (reference >= 0.0 && reference <= 1.0),
         "reference must be in [0, 1]",
       );

  @override
  State<ClusteredValueAxis<T>> createState() => _ClusteredValueAxisState<T>();
}

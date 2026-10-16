// index.dart
//
// HistoryTimeline<T> — a kMinTapTarget-tall horizontal strip for any history
// list (versions, visits, check-ins, snapshots). Each entry is a dot placed in
// proportion to its date, with a date caption and a tooltip. items[0] is the
// current entry (filled dot with a halo); the others are past entries the
// user can tap to go back to. The oldest entries collapse into a "+N earlier"
// pill that expands the strip inline.
//
// State lives in view_model.dart, the tree in view.dart, the placement maths
// in controllers/timeline_layout.dart and the dot and pill in widgets/.

import "dart:math" as math;

import "package:easy_localization/easy_localization.dart";
import "package:flutter/foundation.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/utils/formatters/intl_locale.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "controllers/timeline_layout.dart";
part "view_model.dart";
part "view.dart";
part "widgets/overflow_pill.dart";
part "widgets/timeline_dot.dart";

/// Horizontal timeline whose dots are placed in proportion to their date.
///
/// - [items]: entries sorted **newest first**. `items[0]` is the current
///   entry (12 dp filled `cs.primary` dot with a halo, bold caption); every
///   other item is a past entry (8 dp outlined dot that fills on hover when
///   tappable).
/// - [dateOf]: the date that places an entry on the axis. The caller parses
///   strings and handles UTC offsets.
/// - [labelOf]: the entry text shown in the tooltip and the semantics label.
///   The caller handles any fallback; an empty string shows the hint alone.
/// - [onTapCurrent] / [onTapPast]: called with the tapped item. When a
///   callback is null, the matching dots are not interactive (no click
///   cursor, no hover fill, no button semantics).
/// - [maxVisible]: maximum number of dots before the oldest entries collapse
///   into the "+N earlier" pill (`custom.history_timeline.older`). Tapping
///   the pill expands the strip inline; it does not collapse back. Must be
///   > 0.
/// - [dateLabelOf]: caption under each dot. Defaults to intl
///   `DateFormat.MMMd` for the ambient locale (the app's `context.locale`).
/// - [currentHint] / [pastHint]: tooltip and semantics hints. Default to
///   `custom.history_timeline.current` and
///   `custom.history_timeline.resume_here`.
///
/// Each dot has a [kMinTapTarget]-tall hit box reaching up to
/// [kMinTapTarget] / 2 on each side of it and never past the midpoint with a
/// neighbour, so a pointer always reaches the nearest dot. It is announced as
/// `"label, caption"` with its hint; the current dot is marked selected.
/// Dates are spread over the strip between [kMinTapTarget] / 2 insets; dots
/// closer than 12 dp (the current dot's diameter) are nudged apart so none
/// hides another. When every visible entry has the same date, the dots are
/// spread evenly instead of stacking. Empty [items] render an empty
/// [kMinTapTarget]-tall box.
///
/// Needs a finite parent width (about 280 dp minimum is comfortable).
///
/// Needs an `Overlay` ancestor (a routed page or a modal): each dot shows a
/// [Tooltip] on hover and long press.
final class HistoryTimeline<T> extends StatefulWidget {
  /// Entries, newest first (index 0 = current).
  final List<T> items;

  /// Date used to place an entry on the axis.
  final DateTime Function(T item) dateOf;

  /// Tooltip and semantics text of an entry; "" shows the hint alone.
  final String Function(T item) labelOf;

  /// Tap on the current (`items[0]`) dot; null makes it inert.
  final ValueChanged<T>? onTapCurrent;

  /// Tap on a past dot; null makes past dots inert.
  final ValueChanged<T>? onTapPast;

  /// Dots shown before the oldest entries collapse into the pill.
  final int maxVisible;

  /// Caption under each dot; defaults to `DateFormat.MMMd` for the locale.
  final String Function(DateTime date)? dateLabelOf;

  /// Hint of the current dot; defaults to `custom.history_timeline.current`.
  final String? currentHint;

  /// Hint of past dots; defaults to `custom.history_timeline.resume_here`.
  final String? pastHint;

  const HistoryTimeline({
    super.key,
    required this.items,
    required this.dateOf,
    required this.labelOf,
    this.onTapCurrent,
    this.onTapPast,
    this.maxVisible = 6,
    this.dateLabelOf,
    this.currentHint,
    this.pastHint,
  }) : assert(maxVisible > 0, "maxVisible must be > 0");

  @override
  State<HistoryTimeline<T>> createState() => _HistoryTimelineState<T>();
}

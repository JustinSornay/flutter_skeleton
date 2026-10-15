// index.dart
//
// RankedList<T> — compact, height-capped, scrollable list of ranked rows
// (rank circle, label + optional detail, optional percentage StatusPill,
// optional decorative trailing icon). One row can be marked active (tertiary
// accent + badge). An optional header shows a title, the item count and a
// free trailing slot.
//
// RankedListEntry (the display data of one row, also used by RankedListPanel)
// is declared here, the ScrollController lives in view_model.dart, the list
// tree in view.dart and the private row in widgets/ranked_list_row.dart.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/PillBadge/index.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";

part "view_model.dart";
part "view.dart";
part "widgets/ranked_list_row.dart";

/// Display data of one ranked row, built by the host from its own items.
///
/// Shared by [RankedList] and `RankedListPanel`. [RankedList] renders
/// [rank], [label], [detail], [score] (tinted by [tone]) and
/// [semanticsLabel]; it does not draw [icon], which is the leading glyph of
/// `RankedListPanel`.
@immutable
final class RankedListEntry<T> {
  /// Value handed back to the tap callback and compared (`==`) with the
  /// list's active value.
  final T value;

  /// Main row text (one line, ellipsised), already localised.
  final String label;

  /// Score as a `0..1` ratio, shown as a locale-formatted percentage
  /// (`0.85` → `85%`). Null or not finite → no score.
  final double? score;

  /// Tone of the score pill (and of the leading icon in `RankedListPanel`).
  /// The host picks it; there is no built-in threshold.
  final StatusTone tone;

  /// Optional muted secondary text under the label (one line, ellipsised).
  final String? detail;

  /// Optional leading glyph, drawn by `RankedListPanel` only.
  final IconData? icon;

  /// Rank shown in the circle. Null → position in the list + 1.
  final int? rank;

  /// Screen-reader label of the whole row. Null → rank + label, detail,
  /// score and the active badge, joined with ", ".
  final String? semanticsLabel;

  const RankedListEntry({
    required this.value,
    required this.label,
    this.score,
    this.tone = StatusTone.neutral,
    this.detail,
    this.icon,
    this.rank,
    this.semanticsLabel,
  });
}

/// Compact list of ranked, tappable rows, capped at [maxHeight] and
/// scrollable beyond it (always-visible scrollbar).
///
/// - Rows, in the given order: a 22 dp rank circle ([RankedListEntry.rank],
///   else position + 1), the label (`bodyMedium` w700) with an optional muted
///   detail line, the score as a dense [StatusPill] in the entry's tone
///   (locale-formatted percentage, so the colour always comes with text), and
///   an optional decorative [trailingIcon] in a 26 dp circle. Each row is at
///   least [kMinTapTarget] tall and calls [onItemTap] with its value.
/// - Colours: rows are `cs.surfaceContainerLow` with a `cs.outlineVariant`
///   border and radius 10; the rank circle is `cs.tertiaryContainer`.
/// - Active row (`entry.value == activeValue`): `cs.tertiaryContainer` fill,
///   `cs.tertiary` border, rank circle and trailing circle; it shows
///   [activeBadgeLabel] in a `cs.tertiary` on `cs.surface` badge and is
///   announced as selected.
/// - Header: shown when [title] or [headerTrailing] is set. [title]
///   (`labelSmall` w700, `cs.onSurfaceVariant`, a semantic header) is
///   followed by the item count (`custom.ranked_list.count`); [headerTrailing]
///   sits at the right end (a badge, a link, …).
/// - Empty [entries]: only [emptyLabel] (default `custom.ranked_list.empty`)
///   is shown, without the header.
/// - Height: the list shrink-wraps, so a short list is only as tall as its
///   rows; [maxHeight] caps the scrolling area. The widget needs a bounded
///   width.
///
/// Accessibility: one semantics node per row (button, selected when active)
/// labelled [RankedListEntry.semanticsLabel], else
/// `custom.ranked_list.item_semantics` (rank and label), detail, score and
/// active badge. The trailing icon is decorative.
///
/// No tooltip or overlay is used, so the widget works anywhere in the tree,
/// including `Layout`.
final class RankedList<T> extends StatefulWidget {
  /// Rows in display order.
  final List<RankedListEntry<T>> entries;

  /// Called with the value of the tapped row.
  final ValueChanged<T> onItemTap;

  /// Value of the highlighted row. Null → no active row.
  final T? activeValue;

  /// Badge text shown inside the active row (e.g. "SELECTED"). Null or
  /// empty → no badge.
  final String? activeBadgeLabel;

  /// Header title, already localised. Null → no title and no count.
  final String? title;

  /// Free slot at the right end of the header.
  final Widget? headerTrailing;

  /// Message shown when [entries] is empty. Null → `custom.ranked_list.empty`.
  final String? emptyLabel;

  /// Decorative icon at the end of every row. Null hides it.
  final IconData? trailingIcon;

  /// Maximum height of the scrolling area.
  final double maxHeight;

  const RankedList({
    super.key,
    required this.entries,
    required this.onItemTap,
    this.activeValue,
    this.activeBadgeLabel,
    this.title,
    this.headerTrailing,
    this.emptyLabel,
    this.trailingIcon = Icons.swap_horiz,
    this.maxHeight = 194,
  }) : assert(maxHeight > 0);

  @override
  State<RankedList<T>> createState() => _RankedListState<T>();
}

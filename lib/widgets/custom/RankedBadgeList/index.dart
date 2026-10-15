// index.dart
//
// RankedBadgeList — ranked, collapsible list of tone-tinted badges. Items are
// shown by descending weight, each as a StatusPill with an optional trailing
// widget; the list starts collapsed to the first items and an accessible
// "Show all / Show less" toggle reveals the rest.
//
// RankedBadgeItem (the data of one badge) is declared here, the expanded flag
// and the ranking live in view_model.dart, the tree in view.dart, one row in
// widgets/badge_row.dart and the toggle in widgets/expand_toggle.dart.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";

part "view_model.dart";
part "view.dart";
part "widgets/badge_row.dart";
part "widgets/expand_toggle.dart";

/// One entry of a [RankedBadgeList], built by the host from its own data.
@immutable
final class RankedBadgeItem {
  /// Stable identifier, for the host only (e.g. to pick the trailing widget
  /// of this item in [RankedBadgeList.trailingBuilder]). Not displayed.
  final String id;

  /// Badge text, already localised (one line, ellipsised).
  final String label;

  /// Ranking key: items are displayed by descending weight. Items with the
  /// same weight keep their input order. The widget never interprets it.
  final double weight;

  /// Optional short value appended to the badge text after " · " (e.g.
  /// "−18 %", "3 d"). Formatting is up to the host. Null or empty → label
  /// only.
  final String? valueLabel;

  /// Tone of the badge, chosen by the host (no built-in threshold).
  final StatusTone tone;

  /// Screen-reader label of the badge. Null → "[label], [valueLabel]" (or
  /// [label] alone when there is no value).
  final String? semanticsLabel;

  const RankedBadgeItem({
    required this.id,
    required this.label,
    required this.weight,
    this.valueLabel,
    this.tone = StatusTone.neutral,
    this.semanticsLabel,
  });
}

/// Ranked, collapsible list of tone-tinted badges (impact breakdowns, top
/// contributing causes, the main warnings of a result, …).
///
/// - Ranking: [items] are shown by descending [RankedBadgeItem.weight]
///   (ties keep their input order); [items] itself is never mutated.
/// - Badges: each item is a [StatusPill] in the item's tone (`onContainer`
///   text on a `container` fill, so the colour always comes with text),
///   showing "label · value". In a narrow parent the text is ellipsised.
/// - Rows: the badge, then — when [trailingBuilder] is set — an 8 dp gap and
///   the widget it returns for the item (an inline help link, an action
///   chip, …). Badge and trailing widget share the row width (`Flexible`).
///   Rows are separated by 8 dp.
/// - Collapsed: only the first [collapsedCount] items are shown. When there
///   are more, a toggle (`labelMedium` w600, underlined, `cs.primary`, with
///   a chevron) reads `custom.ranked_badge_list.show_all` (total item count
///   as `{count}`) or `custom.ranked_badge_list.show_less`; [showAllLabel] /
///   [showLessLabel] override them. Expanding or collapsing animates the
///   list height ([kMotionShort], `easeInOut`, instant under reduced
///   motion).
/// - Empty [items] render `SizedBox.shrink()`.
///
/// Accessibility: one semantics node per badge
/// ([RankedBadgeItem.semanticsLabel]); the toggle is a button with an
/// expanded state and a [kMinTapTarget] (48 dp) high hit area.
///
/// The toggle uses an [InkWell], so the widget needs a `Material` ancestor
/// (any `Scaffold`, `Card` or sheet). No tooltip or overlay is used, so no
/// `Overlay` ancestor is needed.
final class RankedBadgeList extends StatefulWidget {
  /// Items to rank and display.
  final List<RankedBadgeItem> items;

  /// Number of items visible while collapsed. The toggle appears only when
  /// there are more items than this.
  final int collapsedCount;

  /// Optional widget placed after each visible badge, built for that item.
  /// Null → badge only.
  final Widget Function(BuildContext context, RankedBadgeItem item)? trailingBuilder;

  /// Toggle text while collapsed, already localised. Null →
  /// `custom.ranked_badge_list.show_all` with the item count.
  final String? showAllLabel;

  /// Toggle text while expanded, already localised. Null →
  /// `custom.ranked_badge_list.show_less`.
  final String? showLessLabel;

  const RankedBadgeList({
    super.key,
    required this.items,
    this.collapsedCount = 3,
    this.trailingBuilder,
    this.showAllLabel,
    this.showLessLabel,
  }) : assert(collapsedCount > 0, "collapsedCount must be > 0");

  @override
  State<RankedBadgeList> createState() => _RankedBadgeListState();
}

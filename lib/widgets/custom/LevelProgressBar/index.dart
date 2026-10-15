// index.dart
//
// LevelProgressBar — segmented progress bar through an ordered list of named
// levels (plans, onboarding stages, ranks, maturity steps…): a header (current
// level + optional counter), one pill segment per level filled up to the
// current one, a row of level labels, and an optional "next level" card
// (chips + call-to-action). Pure presentation: data and actions come from
// parameters. The tree lives in view.dart; the header, the segment row and
// the card are private parts in widgets/; the counter template split is pure
// logic in controllers/.

import "dart:math" as math;

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "controllers/level_counter.dart";
part "view.dart";
part "widgets/level_header.dart";
part "widgets/next_level_card.dart";
part "widgets/segmented_bar.dart";

/// Segmented progress bar for moving through an ordered list of named
/// [levels], lowest first.
///
/// - Header: `levels[currentIndex]` at the start (13, w700, `cs.onSurface`)
///   and, when both [count] and [total] are set, a counter at the end built
///   from `custom.level_progress_bar.counter` (named args `count`, `total`,
///   `label` = [countLabel] or empty). The `{count}` run is emphasised
///   (w800, `cs.primary`), the rest is `cs.onSurfaceVariant`. The counter
///   sits at the end of the row, at least 12 dp after the label. The label
///   keeps its natural width up to half the row; the counter uses whatever
///   the label leaves free, and a short counter leaves the rest to a long
///   label. Only when both are long does each get half the row (minus the
///   gap) and ellipsize on one line.
/// - Bar: one 6 dp pill segment per level, all the same width, with a 4 dp
///   gap; segments `0..currentIndex` are filled with `cs.primary`, the
///   others show the track colour `cs.surfaceContainerHighest`. Segment `i`
///   carries `ValueKey<String>("level_progress_bar.segment.$i")`.
/// - Labels: one label per level, exactly as wide as its segment (10, w600,
///   one line, ellipsis); reached levels in `cs.primary`, the others in
///   `cs.onSurfaceVariant`. The reached state is also spelled out by the
///   header text and the semantics label, never by colour alone.
/// - Next-level card: shown when [nextItems] is non-null and the current
///   level is not the last one. A primary-tinted box with [nextTitle]
///   (default `custom.level_progress_bar.next_title`), one chip per entry of
///   [nextItems] (none when the list is empty) and, when [onNextLevel] is
///   set, a full-width `FilledButton` (≥ [kMinTapTarget] high) labelled
///   [nextActionLabel] (default `custom.level_progress_bar.next_action`).
///
/// Accessibility: the header, bar and labels form one semantics node whose
/// label is `custom.level_progress_bar.semantics` (named args `current`
/// = `currentIndex + 1`, `count` = `levels.length`, `label` = current level)
/// and whose value is the counter text; the card's texts and button are read
/// normally.
///
/// Inert: tapping the button only calls [onNextLevel]; the host decides what
/// happens (navigation, sheet…). No tooltip, no animation: it needs no
/// `Overlay` ancestor. With a counter, the header splits its incoming width
/// (`LayoutBuilder`), so the bar then cannot sit under an intrinsic-size
/// parent (`IntrinsicWidth`, `IntrinsicHeight`). Content strings ([levels],
/// [countLabel], [nextItems], [nextTitle], [nextActionLabel]) are already
/// localised by the host.
final class LevelProgressBar extends StatelessWidget with _ViewMixin {
  /// Ordered level labels, lowest first (e.g. `["Basic", "Plus", "Max"]`).
  /// Must not be empty (asserted at build time).
  final List<String> levels;

  /// 0-based index of the level currently reached, in `[0, levels.length)`
  /// (asserted at build time).
  final int currentIndex;

  /// Number shown first in the counter (e.g. items unlocked so far). The
  /// counter is hidden when [count] or [total] is null.
  final int? count;

  /// Number shown after the slash in the counter.
  final int? total;

  /// Text shown after the numbers in the counter (e.g. "items unlocked").
  final String? countLabel;

  /// What the next level adds, one chip each. Null hides the next-level card;
  /// so does reaching the last level. An empty list shows the card without
  /// chips.
  final List<String>? nextItems;

  /// Card title. Null → `custom.level_progress_bar.next_title`.
  final String? nextTitle;

  /// Called when the card's button is tapped. Null hides the button.
  final VoidCallback? onNextLevel;

  /// Button label. Null → `custom.level_progress_bar.next_action`.
  final String? nextActionLabel;

  const LevelProgressBar({
    super.key,
    required this.levels,
    required this.currentIndex,
    this.count,
    this.total,
    this.countLabel,
    this.nextItems,
    this.nextTitle,
    this.onNextLevel,
    this.nextActionLabel,
  });

  /// [nextItems] when the next-level card is shown (not at the last level),
  /// else null.
  List<String>? get _shownNextItems => currentIndex < levels.length - 1 ? nextItems : null;

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

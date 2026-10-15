// index.dart
//
// RankedListPanel<T> — sheet-styled panel (rounded top corners, elevation,
// optional decorative grip and overline title) listing a short, already
// ordered set of ranked rows: rank, leading icon tinted by the entry's tone,
// bold label, muted detail and a chevron. Tapping a row hands its value back.
//
// Rows reuse RankedListEntry<T> from RankedList/index.dart (re-exported here
// so hosts need a single import). The panel tree lives in view.dart and the
// private row in widgets/ranked_list_panel_row.dart.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/RankedList/index.dart";

export "package:flutter_skeleton/widgets/custom/RankedList/index.dart" show RankedListEntry;

part "view.dart";
part "widgets/ranked_list_panel_row.dart";

/// Persistent, sheet-styled panel listing a short set of ranked results
/// (top hits, nearest matches, recommendations…) above a map or a page.
///
/// - Surface: `cs.surfaceContainerLow`, elevation 6 with a `cs.shadow`
///   shadow, 16 dp top corners. It keeps its own decorative grip
///   ([showHandle]) because it is a persistent panel, not a modal sheet.
/// - [title]: overline caption (`labelSmall` w700, letter-spacing 1.5,
///   `cs.onSurfaceVariant`), shown exactly as given and announced as a header.
/// - Rows, in the given order (the host sorts and trims the list): the rank
///   ([RankedListEntry.rank], else position + 1), the leading glyph
///   ([RankedListEntry.icon], else [icon]) tinted with the tone foreground of
///   [RankedListEntry.tone], the bold [RankedListEntry.label], the muted
///   trailing [RankedListEntry.detail] and a chevron. The detail sits by the
///   chevron and takes at most 128 dp and half of the width left for the two
///   texts; the label fills the rest, so a long detail never squeezes it out.
///   Both are one line, ellipsised. [RankedListEntry.score] is not drawn:
///   format it into the label. The label always carries the meaning,
///   so the tint is never colour-only coding; pass `tone.icon` as the entry
///   icon for an extra non-colour cue.
/// - Each row is at least [kMinTapTarget] tall and calls [onTap] with its
///   [RankedListEntry.value].
/// - Empty [entries]: the grip and the title only.
///
/// The panel is a min-size column, not a scroll view: it needs a bounded
/// width, and the host keeps the list short enough for the available height.
/// Rows measure their width with a [LayoutBuilder], so the panel cannot sit
/// under an intrinsic-size parent (`IntrinsicWidth`, `IntrinsicHeight`).
///
/// Accessibility: one button node per row labelled
/// [RankedListEntry.semanticsLabel], else `custom.ranked_list_panel.rank`
/// (the rank), the label and the detail joined with " — ". The grip, the
/// icons and the chevron are decorative.
///
/// No tooltip or overlay is used, so the widget works anywhere in the tree,
/// including `Layout`.
final class RankedListPanel<T> extends StatelessWidget with _ViewMixin<T> {
  /// Rows in display order.
  final List<RankedListEntry<T>> entries;

  /// Called with the value of the tapped row.
  final ValueChanged<T> onTap;

  /// Overline caption above the rows, already localised. Null hides it.
  final String? title;

  /// Leading glyph of rows whose entry has no icon. Null (with no entry
  /// icon) hides it.
  final IconData? icon;

  /// Shows the decorative grip at the top of the panel.
  final bool showHandle;

  const RankedListPanel({
    super.key,
    required this.entries,
    required this.onTap,
    this.title,
    this.icon = Icons.star_border_rounded,
    this.showHandle = true,
  });

  @override
  Widget build(BuildContext context) => render(context, this);
}

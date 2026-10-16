// index.dart
//
// IconListPanel — read-only titled card with a tinted header band and a
// divided list of rows. Each row shows an optional tone-tinted icon tile, a
// title, an optional tag (a dense StatusPill) and an optional muted subtitle.
// An empty list shows a muted placeholder line. Declares the
// IconListPanelItem value class; the card tree lives in view.dart and the row
// in widgets/item_row.dart.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";

part "view.dart";
part "widgets/item_row.dart";

/// One row of an [IconListPanel]. Every string is already localised by the
/// host.
@immutable
final class IconListPanelItem {
  /// Main row text (one line, ellipsised).
  final String title;

  /// Muted second line, wrapping. Null or empty → no second line.
  final String? subtitle;

  /// Icon of the leading 36 × 36 tile. Null → no tile; the title starts at
  /// the left edge of the row.
  final IconData? icon;

  /// Short label drawn as a dense [StatusPill] next to the title (it moves
  /// under the title when both do not fit on one line). Null or empty → no
  /// pill.
  final String? tag;

  /// Tone of the tile (`container` fill, `onContainer` icon) and of the pill
  /// (same pair). [StatusTone.neutral] (default) is `cs.onSurface` on
  /// `cs.surfaceContainerHighest`.
  final StatusTone tone;

  const IconListPanelItem({
    required this.title,
    this.subtitle,
    this.icon,
    this.tag,
    this.tone = StatusTone.neutral,
  });
}

/// Read-only card listing short categorised items (open issues by cause,
/// alerts by type, flagged records, risk areas…).
///
/// Layout:
/// - Full available width (needs a bounded width); the height hugs the rows.
/// - Panel: `cs.surfaceContainerLow`, radius 10, a 1 dp `cs.outlineVariant`
///   border painted above the content, clipped with [Clip.antiAlias].
/// - Header band: `cs.surfaceContainerHigh` with a `cs.outlineVariant` bottom
///   border, 16 / 8 dp padding, [title] verbatim in `labelSmall` w700,
///   letter-spacing 0.8, `cs.onSurfaceVariant`.
/// - Body: 12 dp padding, [items] in order with a `cs.outlineVariant`
///   [Divider] (16 dp tall) between two rows.
/// - Row: optional 36 × 36 icon tile (radius 8, tone `container` fill, 18 dp
///   icon in the tone `onContainer`, >= 4.5:1), then the title
///   (`bodyMedium` w600, `cs.onSurface`, one line with an ellipsis) followed
///   by the tag pill, then the subtitle (`bodySmall`, `cs.onSurfaceVariant`).
/// - Empty [items]: a single `bodySmall` `cs.onSurfaceVariant` line,
///   [emptyLabel] or `custom.icon_list_panel.empty`.
///
/// A tone never stands alone: it colours the icon the host chose and the tag
/// text. Map your own categories to a [StatusTone], an icon and a localised
/// tag in the host.
///
/// Accessibility: the title is a semantic header; each row is one merged
/// node reading the title, the tag and the subtitle; the tile icon is
/// decorative. Nothing is interactive.
///
/// No tooltip and no overlay, so no `Overlay` ancestor is needed (it also
/// works in `Layout`).
final class IconListPanel extends StatelessWidget with _ViewMixin {
  /// Header band text, already localised, rendered verbatim.
  final String title;

  /// Rows, rendered in order.
  final List<IconListPanelItem> items;

  /// Placeholder shown when [items] is empty. Null →
  /// `custom.icon_list_panel.empty`.
  final String? emptyLabel;

  const IconListPanel({
    super.key,
    required this.title,
    required this.items,
    this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

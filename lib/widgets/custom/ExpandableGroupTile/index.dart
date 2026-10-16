// index.dart
//
// ExpandableGroupTile<T> — controlled accordion card for one group of
// selectable entries (ChoiceOption<T>). The header toggles the body; each
// entry row hands its value back. A non-expandable tile is a single
// navigation row that selects its first entry. The card and body live in
// view.dart, the header and the entry rows in widgets/.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/_base/choice_option.dart";

part "view.dart";
part "widgets/entry_row.dart";
part "widgets/group_header.dart";

/// Controlled accordion card listing the selectable [entries] of one group.
///
/// The parent owns [isOpen] and flips it in [onToggle], so it can keep a
/// single group open at a time or scroll the opened tile into view.
///
/// Card: `Card(elevation: 0)`, `cs.surfaceContainerLowest`, radius 24 and a
/// `cs.outlineVariant` border (the same tokens as `CollapsibleSectionCard`).
///
/// Header (at least [kMinTapTarget] tall, one button semantics node):
/// - optional leading [icon] (28 dp, `cs.primary`);
/// - [title] (`titleSmall` w600, `cs.onSurface`) and, when non-empty,
///   [subtitle] (`bodySmall`, `cs.onSurfaceVariant`);
/// - a `cs.primary` chevron.
///
/// Two modes:
/// - **Accordion** ([expandable] true, the default): tapping the header calls
///   [onToggle]; the chevron (`keyboard_arrow_down`) turns half a turn when
///   [isOpen]; the body grows with [AnimatedSize] to show a divider and one
///   row per entry. The header exposes its expanded state to screen readers,
///   with a localised tap hint (`custom.expandable_group_tile.expand` /
///   `.collapse`).
/// - **Direct** ([expandable] false): the header shows `chevron_right`, has
///   no body and ignores [isOpen]; tapping it calls
///   `onSelected(entries.first.value)`. [subtitle] defaults to the first
///   entry's label, spoken as that entry's `semanticsLabel` when set. With
///   no entries, or a disabled first entry, the header is inert: dimmed to
///   38 %, announced as disabled and ignoring taps.
///
/// Entry rows render these [ChoiceOption] fields:
/// - `label` (`bodyMedium` w500, `cs.onSurface`);
/// - `description` as a second line (`bodySmall`, `cs.onSurfaceVariant`);
/// - `trailing`, a short pre-formatted text such as a count (`labelMedium`,
///   `cs.primary`), followed by a 16 dp `cs.outline` chevron;
/// - `enabled`: `false` dims the row to 38 % and ignores taps;
/// - `semanticsLabel`: replaces the row's spoken text (and, in direct mode,
///   the spoken fallback subtitle).
///
/// `ChoiceOption.icon` is not rendered. Tapping an enabled row calls
/// [onSelected] with its `value`.
///
/// Motion: the chevron rotation and the body resize use
/// `resolveMotion(context, kMotionShort)` and are instant under reduced
/// motion.
///
/// Content strings ([title], [subtitle], entry texts) are already localised
/// by the host. The only built-in strings are the accordion header's
/// screen-reader tap hints. The widget has no tooltip and no other overlay:
/// no `Overlay` ancestor is needed.
final class ExpandableGroupTile<T> extends StatelessWidget with _ViewMixin<T> {
  /// Header title.
  final String title;

  /// Selectable entries listed in the open body (or the target of a direct
  /// tile).
  final List<ChoiceOption<T>> entries;

  /// Whether the body is shown. Owned by the parent; ignored when
  /// [expandable] is false.
  final bool isOpen;

  /// Header tap in accordion mode; the parent flips [isOpen].
  final VoidCallback onToggle;

  /// Called with the tapped entry's value, or with `entries.first.value` on
  /// a header tap when [expandable] is false.
  final ValueChanged<T> onSelected;

  /// Header second line. Hidden when null or empty, except in direct mode
  /// where it defaults to `entries.first.label` (spoken as
  /// `entries.first.semanticsLabel` when that is set).
  final String? subtitle;

  /// Leading header icon (28 dp, `cs.primary`). Null shows none.
  final IconData? icon;

  /// `false` turns the tile into a direct navigation row with no body.
  final bool expandable;

  const ExpandableGroupTile({
    super.key,
    required this.title,
    required this.entries,
    required this.isOpen,
    required this.onToggle,
    required this.onSelected,
    this.subtitle,
    this.icon,
    this.expandable = true,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

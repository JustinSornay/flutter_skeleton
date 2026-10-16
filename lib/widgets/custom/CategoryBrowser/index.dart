// index.dart
//
// CategoryBrowser<T> — scrollable single-open accordion of groups, each
// rendered with ExpandableGroupTile. Tapping an entry (or a non-expandable
// group) hands back its typed value. The group value class lives in
// group.dart, the open key / scroll bookkeeping in view_model.dart and the
// list in view.dart.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/ExpandableGroupTile/index.dart";
import "package:flutter_skeleton/widgets/custom/_base/choice_option.dart";

part "group.dart";
part "view.dart";
part "view_model.dart";

/// Two-level picker: a vertical list of [groups] where at most one group is
/// open at a time, each one listing its selectable entries.
///
/// Every group is an [ExpandableGroupTile] (icon, title, subtitle, chevron;
/// entry rows with label, description and trailing text), separated by
/// [kDefaultPadding]. A group without an icon shows [Icons.category].
///
/// - Tapping an expandable group opens it and closes the previously open
///   one; tapping the open group closes it. [onOpenChanged] reports the new
///   open key (or null). Once the tiles have stopped resizing, the tapped
///   group is scrolled into view (`Scrollable.ensureVisible`, 300 ms,
///   `easeInOut`, alignment 0.1). Waiting keeps the target right when an
///   open group above collapses or the last group grows the scroll range.
///   A user scroll (drag, fling, mouse wheel) started before the reveal
///   cancels it: the user's gesture keeps control of the list.
/// - Tapping an entry calls [onEntrySelected] with its value.
/// - Tapping a non-expandable group calls [onEntrySelected] with its first
///   entry's value; it never opens and does not report to [onOpenChanged].
///   With no entries, or a disabled first entry, it is inert.
///
/// The open group lives in the widget's state: [initialOpenKey] seeds it on
/// the first build, and a host that rebuilds the browser (for example after
/// an entry was picked and the host navigated back) persists it through
/// [onOpenChanged]. When the open group disappears from [groups] or becomes
/// non-expandable, nothing is open (silently, without [onOpenChanged]).
///
/// The browser is a [ListView]: give it a bounded height (`Expanded`,
/// `SizedBox`) and never wrap it in another scroll view. Group keys must be
/// unique (asserted).
///
/// Motion: the reveal scroll and its wait for the tiles to resize
/// (`kMotionShort`, ExpandableGroupTile's resize time) both go through
/// `resolveMotion`; under reduced motion the list jumps on the next frame.
///
/// Content strings are already localised by the host; the widget adds none
/// of its own beyond [ExpandableGroupTile]'s screen-reader tap hints. No
/// tooltip and no other overlay: no `Overlay` ancestor is needed.
final class CategoryBrowser<T> extends StatefulWidget {
  /// Groups in display order.
  final List<CategoryBrowserGroup<T>> groups;

  /// Called with the tapped entry's value, or with the first entry's value
  /// when a non-expandable group is tapped.
  final ValueChanged<T> onEntrySelected;

  /// Key of the group open on the first build. Ignored when it matches no
  /// expandable group, and after the first build.
  final String? initialOpenKey;

  /// Called after a user toggle with the new open key, or null when the
  /// tapped group was closed.
  final ValueChanged<String?>? onOpenChanged;

  /// Optional external controller of the list. When null the browser owns
  /// one. An external controller is never disposed by the browser.
  final ScrollController? scrollController;

  const CategoryBrowser({
    super.key,
    required this.groups,
    required this.onEntrySelected,
    this.initialOpenKey,
    this.onOpenChanged,
    this.scrollController,
  });

  @override
  State<CategoryBrowser<T>> createState() => _CategoryBrowserState<T>();
}

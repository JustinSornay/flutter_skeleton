// index.dart
//
// MasterListPanel — fixed-width sidebar for the list side of a list/detail
// screen: optional create button, optional category tabs with item counts,
// single-select rows (title + trailing text, optional icon + subtitle line,
// tag pills with a "+N" overflow pill) marked by a left-border indicator,
// loading / error / empty states and a 3-snap pull-up drawer listing archived
// items.
//
// MasterListItem and MasterListTab (the display data) are declared here; the
// tab controller, active tab and drawer snap live in view_model.dart, the
// panel tree in view.dart, and the private row, drawer and skeleton row in
// widgets/.
// Composes PillBadge (tags), SkeletonBlock + SkeletonPulse (loading rows).

import "dart:math" as math;

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/utils/load_state.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/core/decorators/SkeletonPulse/index.dart";
import "package:flutter_skeleton/widgets/custom/PillBadge/index.dart";
import "package:flutter_skeleton/widgets/custom/SkeletonBlock/index.dart";

part "view_model.dart";
part "view.dart";
part "widgets/item_row.dart";
part "widgets/archive_drawer.dart";
part "widgets/skeleton_row.dart";

/// One row of a [MasterListPanel]. Every string is already localised and
/// formatted by the host (plurals, numbers, dates).
@immutable
final class MasterListItem {
  /// Stable identifier, passed back through [MasterListPanel.onSelect].
  final String id;

  /// Line 1, left: one line, ellipsised.
  final String title;

  /// Line 1, right (e.g. "3 items"): one line, at most 40 % of the line,
  /// ellipsised beyond. Hidden when null.
  final String? trailing;

  /// Line 2 (e.g. "North · 12.4 km"). The whole line is hidden when null.
  final String? subtitle;

  /// Leading icon of line 2; only rendered together with [subtitle].
  final IconData? subtitleIcon;

  /// Line 3 pills: the first [MasterListPanel.maxVisibleTags] are shown, the
  /// rest are summed up in a "+N" pill. No pills → no third line.
  final List<String> tags;

  /// Id of the [MasterListTab] this item belongs to. Ignored when the panel
  /// has fewer than 2 tabs; while tabs are shown, an item whose [tabId]
  /// matches no tab is hidden.
  final String? tabId;

  /// True → listed in the pull-up archive drawer instead of the main list.
  final bool archived;

  /// Line 2 of the archive drawer row (e.g. "Archived Oct 2025").
  final String? archivedCaption;

  const MasterListItem({
    required this.id,
    required this.title,
    this.trailing,
    this.subtitle,
    this.subtitleIcon,
    this.tags = const <String>[],
    this.tabId,
    this.archived = false,
    this.archivedCaption,
  });
}

/// A category tab of a [MasterListPanel]. The tab bar is rendered only when
/// the panel gets 2 tabs or more.
@immutable
final class MasterListTab {
  /// Identifier matched against [MasterListItem.tabId].
  final String id;

  /// Tab text, rendered as `custom.master_list_panel.tab_label`
  /// ("{label} ({count})") with the number of active items of the tab.
  final String label;

  /// Replaces [MasterListPanel.createLabel] while this tab is active.
  final String? createLabel;

  /// Replaces [MasterListPanel.archivedTitle] while this tab is active.
  final String? archivedTitle;

  const MasterListTab({
    required this.id,
    required this.label,
    this.createLabel,
    this.archivedTitle,
  });
}

/// Sidebar listing [MasterListItem]s as a single-select navigator.
///
/// - [state]: `Idle` / `Loading` → 5 pulsing skeleton rows (static under
///   reduced motion); `LoadError` → error text + retry button; `Loaded` →
///   the active (non-archived) rows, or the empty state. The panel never
///   fetches: the host owns the list and rebuilds with a new state.
/// - Header: a full-width create button when [onCreate] is set. It receives
///   the active tab id (null without tabs). Label: the active tab's
///   [MasterListTab.createLabel], else [createLabel], else
///   `custom.master_list_panel.create`.
/// - Tabs: with 2+ [tabs], a tab bar shows each tab's active-item count and
///   filters the main list and the archive drawer by [MasterListItem.tabId].
///   [onTabChanged] fires when the user switches tab. When [tabs] shrinks,
///   the active index is clamped without calling [onTabChanged].
/// - Rows: title + trailing, optional icon + subtitle, up to
///   [maxVisibleTags] tag pills + a "+N" pill. The row whose id equals
///   [selectedId] gets a `cs.secondaryContainer` background (its pills switch
///   to a `cs.surface` fill) and a 3 dp `cs.primary` left border, and is
///   announced as selected. Every row is at least [kMinTapTarget] tall and
///   announced as one button.
/// - Archive drawer (when [showArchived] and the state is `Loaded`): a 48 dp
///   pill "Archived (n)" pinned to the panel bottom. Tapping its handle
///   cycles closed → 42 % → 80 % of the panel height → closed; tapping
///   outside the drawer closes it. Its rows call [onSelect] too. The drawer
///   is tap-driven: open, its handle shows a down chevron (no drag grip).
///   Only the handle is fixed; the title scrolls with the rows, so short
///   panels never overflow.
///
/// Layout: [width] wide (296 dp by default); the panel needs a **bounded
/// height** (e.g. inside a `Row` of a sized page, or an `Expanded`). Colours
/// come from the `ColorScheme` only; the drawer motion goes through
/// `resolveMotion`.
///
/// No `Overlay` ancestor is needed (no tooltip): the panel works anywhere
/// below a `MaterialApp`, including `Layout`.
final class MasterListPanel extends StatefulWidget {
  /// Async state of the items, owned by the host.
  final LoadState<List<MasterListItem>> state;

  /// Selected item id; null = nothing selected.
  final String? selectedId;

  /// Tap on an active row or on an archive drawer row.
  final ValueChanged<String> onSelect;

  /// Retry in the error state; the button is hidden when null.
  final VoidCallback? onRetry;

  /// Create button handler, given the active tab id (null without tabs).
  /// The button is hidden when null.
  final ValueChanged<String?>? onCreate;

  /// Create button label. Null → `custom.master_list_panel.create`.
  final String? createLabel;

  /// Category tabs; the tab bar shows only with 2 tabs or more.
  final List<MasterListTab> tabs;

  /// Called with the new tab id when the user switches tab.
  final ValueChanged<String>? onTabChanged;

  /// Empty-state title. Null → `custom.master_list_panel.empty_title`.
  final String? emptyTitle;

  /// Empty-state secondary line; hidden when null.
  final String? emptyMessage;

  /// False → no archive drawer and no reserved bottom space.
  final bool showArchived;

  /// Drawer title. Null → `custom.master_list_panel.archived_title`.
  final String? archivedTitle;

  /// Number of tag pills shown before the "+N" pill.
  final int maxVisibleTags;

  /// Panel width.
  final double width;

  const MasterListPanel({
    super.key,
    required this.state,
    required this.selectedId,
    required this.onSelect,
    this.onRetry,
    this.onCreate,
    this.createLabel,
    this.tabs = const <MasterListTab>[],
    this.onTabChanged,
    this.emptyTitle,
    this.emptyMessage,
    this.showArchived = true,
    this.archivedTitle,
    this.maxVisibleTags = 3,
    this.width = 296,
  }) : assert(maxVisibleTags >= 0);

  @override
  State<MasterListPanel> createState() => _MasterListPanelState();
}

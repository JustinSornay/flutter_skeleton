// index.dart
//
// CollapsedGateGroup — folds several locked or unavailable features into one
// collapsible row so a screen does not fill up with lock cards. Expanding it
// lists every feature (icon, label, optional PillBadge) above one call to
// action whose outcome the host supplies. State lives in view_model.dart,
// the tree in view.dart, the header and rows in widgets/.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/PillBadge/index.dart";

part "view_model.dart";
part "view.dart";
part "widgets/gate_header.dart";
part "widgets/feature_row.dart";

/// One locked feature listed by [CollapsedGateGroup].
@immutable
final class GatedFeatureEntry {
  /// Visible feature name, already localised by the host.
  final String label;

  /// Leading icon of the row, tinted `cs.onSurfaceVariant` (decorative).
  final IconData icon;

  /// Pill shown at the end of the row (for example a plan name). Null falls
  /// back to [CollapsedGateGroup.badgeLabel]; an empty string shows no pill
  /// for this entry even when the group sets one.
  final String? badgeLabel;

  const GatedFeatureEntry({
    required this.label,
    this.icon = Icons.lock_outline_rounded,
    this.badgeLabel,
  });
}

/// Collapsible group condensing several locked features into one row with a
/// single call to action.
///
/// Container: `Material` in `cs.surfaceContainerLow`, radius 8, a
/// `cs.outlineVariant` border, clipped so the ink splash stays rounded.
///
/// Header (at least [kMinTapTarget] tall, one button semantics node with an
/// expanded state and the `custom.collapsed_gate_group.expand` / `.collapse`
/// tap hint): a 16 dp lock icon, [summary] (`bodyMedium` w600,
/// `cs.onSurfaceVariant`) and a chevron. Tapping it toggles the list.
///
/// Expanded content, cross-faded in under a `cs.outlineVariant` divider:
/// - one row per entry of [features]: decorative icon, label
///   (`bodyMedium`, `cs.onSurface`) and, when the entry or the group has a
///   badge label, a dense [PillBadge] (lock icon, `cs.onPrimary` on
///   `cs.primary`). The pill sits at the row end when it fits beside the
///   label, else it moves under the label (the label keeps the full width;
///   a pill wider than the row is ellipsized). Each row is read as one
///   semantics node ("label, badge");
/// - when [onAction] is set, a divider then a full-width [FilledButton]
///   (at least [kMinTapTarget] tall) labelled [actionLabel].
///
/// Motion: the cross-fade uses `resolveMotion(context, kMotionShort)` with
/// `Curves.easeOutCubic`; under reduced motion the content appears and
/// disappears at once. Hidden content is neither hit-testable, focusable
/// nor in the semantics tree.
///
/// An empty [features] list renders nothing (`SizedBox.shrink()`).
///
/// The widget is inert: plans, analytics and routing are the host's job,
/// done in [onAction]. Content strings are already localised by the host;
/// the built-in defaults are `custom.collapsed_gate_group.summary` (with
/// `{count}`) and `custom.collapsed_gate_group.unlock_all`. No tooltip or
/// other overlay is used: no `Overlay` ancestor is needed.
final class CollapsedGateGroup extends StatefulWidget {
  /// Entries listed when expanded. Empty → nothing is rendered.
  final List<GatedFeatureEntry> features;

  /// Header text. Null or empty → `custom.collapsed_gate_group.summary`
  /// with `{count}` = `features.length`.
  final String? summary;

  /// Default pill label for every row; [GatedFeatureEntry.badgeLabel]
  /// overrides it. Null or empty → no pill unless the entry sets one.
  final String? badgeLabel;

  /// Call-to-action text. Null or empty →
  /// `custom.collapsed_gate_group.unlock_all`.
  final String? actionLabel;

  /// Called when the call to action is tapped (navigation, analytics,
  /// opening a modal…). Null hides the button and its divider.
  final VoidCallback? onAction;

  /// Whether the list starts expanded. Read once, when the state is created.
  final bool initiallyExpanded;

  const CollapsedGateGroup({
    super.key,
    required this.features,
    this.summary,
    this.badgeLabel,
    this.actionLabel,
    this.onAction,
    this.initiallyExpanded = false,
  });

  @override
  State<CollapsedGateGroup> createState() => _CollapsedGateGroupState();
}

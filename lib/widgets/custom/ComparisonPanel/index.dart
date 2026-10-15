// index.dart
//
// ComparisonPanel — parent-controlled decision panel comparing a current
// option with a candidate option before the user confirms a change: a
// bordered card with an always-visible summary header (tag, title, subtitle
// per side, a central swap badge, an expand chevron), a collapsible detail
// section (colour legend, ComparisonBar rows, optional "from → to" callout)
// and a Cancel / Confirm action row under the card.
// Value classes live in models.dart, the card in view.dart, its pieces in
// widgets/, and the callout template splitter in controllers/.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/ComparisonBar/index.dart";

part "controllers/callout_template.dart";
part "models.dart";
part "view.dart";
part "widgets/action_row.dart";
part "widgets/change_callout.dart";
part "widgets/detail_section.dart";
part "widgets/summary_header.dart";

/// Decision panel comparing [current] with [candidate] before the user
/// confirms a change (plan swap, before / after configuration, alternative
/// item…). The parent owns [isExpanded] and flips it in [onToggle].
///
/// Card: `cs.surface`, radius 12, clipped, `cs.tertiary` border (1.5).
/// "Current" is identified by `cs.primary`, "candidate" by `cs.tertiary`.
///
/// Summary header (`cs.surfaceContainerLow`, always visible, at least
/// [kMinTapTarget] tall):
/// - each side shows its [ComparisonSide.tag] uppercased (9 / w800, in the
///   side colour), its [ComparisonSide.title] (13 / w800, `cs.onSurface`, one
///   line, ellipsis) and the optional [ComparisonSide.subtitle] (10 / w600,
///   `cs.onSurfaceVariant`); the candidate side is end-aligned;
/// - a 28 dp `cs.tertiary` badge with [icon] (`cs.onTertiary`) between them;
/// - when there is detail to show ([metrics] not empty or [change] set), a
///   24 dp chevron badge that turns half a turn when expanded (filled
///   `cs.tertiary` when expanded, outlined otherwise), and the header is
///   tappable ([onToggle]). Without detail there is no chevron and the
///   header is inert.
///
/// Detail section (only when [isExpanded] and there is detail; top divider
/// `cs.tertiary` 0.5):
/// - when [metrics] is not empty, a legend (one swatch per side, labelled
///   with the side tags as given) then one [ComparisonBar] per metric, the
///   current value as baseline (`cs.primary`) and the candidate value as
///   comparison (`cs.tertiary`);
/// - when [change] is set, a `cs.primaryContainer` callout rendered from
///   `custom.comparison_panel.callout` ("{label} : {from} → {to}"), with the
///   from / to values in w800 and [ComparisonChange.icon] in front.
///
/// Action row (under the card, [kMinTapTarget] tall, radius 10): an outlined
/// Cancel button (flex 1, [Icons.close]) and a filled `cs.tertiary` Confirm
/// button (flex 2, [icon]). [onConfirm] null disables Confirm (for example
/// while the host's confirmation is pending).
///
/// Motion: the detail reveal ([AnimatedSize]) and the chevron rotation use
/// `resolveMotion(context, kMotionShort)` with [Curves.easeOutCubic]; under
/// reduced motion both switch at once.
///
/// Accessibility: the header is one semantics node labelled
/// `custom.comparison_panel.summary_semantics` ("{current} compared with
/// {candidate}", each side read as "title (subtitle)"); when it is
/// tappable it is a focusable button with an expanded state and the hint
/// `custom.comparison_panel.show_details` / `hide_details`.
///
/// Content strings (tags, titles, subtitles, metric labels, change texts,
/// button label overrides) are already localised by the host. Needs a
/// bounded width. Uses no tooltip or other overlay: no `Overlay` ancestor is
/// needed.
final class ComparisonPanel extends StatelessWidget with _ViewMixin {
  /// Left side of the summary header: the existing option.
  final ComparisonSide current;

  /// Right side of the summary header: the option being evaluated.
  final ComparisonSide candidate;

  /// Rows of the detail section, rendered in order as [ComparisonBar]s.
  final List<ComparisonMetric> metrics;

  /// Optional "from → to" callout under the metrics. Null hides it.
  final ComparisonChange? change;

  /// Whether the detail section is expanded. Owned by the parent.
  final bool isExpanded;

  /// Called when the summary header is tapped (only when there is detail to
  /// show); the parent flips [isExpanded].
  final VoidCallback onToggle;

  /// Called when Cancel is tapped.
  final VoidCallback onCancel;

  /// Called when Confirm is tapped. Null disables the button.
  final VoidCallback? onConfirm;

  /// Confirm button label. Null → `custom.comparison_panel.confirm`.
  final String? confirmLabel;

  /// Cancel button label. Null → `custom.comparison_panel.cancel`.
  final String? cancelLabel;

  /// Icon of the central badge and of the Confirm button.
  final IconData icon;

  const ComparisonPanel({
    super.key,
    required this.current,
    required this.candidate,
    required this.isExpanded,
    required this.onToggle,
    required this.onCancel,
    required this.onConfirm,
    this.metrics = const <ComparisonMetric>[],
    this.change,
    this.confirmLabel,
    this.cancelLabel,
    this.icon = Icons.swap_horiz,
  });

  /// True when the detail section has something to show.
  bool get _hasDetail => metrics.isNotEmpty || change != null;

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

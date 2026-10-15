// index.dart
//
// SourceBadge — small outlined pill naming where a value comes from (a
// dataset, a publication, an internal reference). Tapping it shows a longer
// description in a tooltip. It composes PillBadge; the tree lives in
// view.dart.

import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/custom/PillBadge/index.dart";

part "view.dart";

/// Compact attribution chip: [source] on the pill, [description] shown on
/// tap in a tooltip ([TooltipTriggerMode.tap], so it works on touch screens).
///
/// Rendered as `PillBadge(label: source, outlined: true, dense: true,
/// tooltip: description)` under a `Semantics(label: "source: description",
/// excludeSemantics: true)`:
/// - 11 sp / w700 label in `cs.onSurfaceVariant`, on one line with an
///   ellipsis when the parent is too narrow;
/// - `cs.surfaceContainerHigh` fill, 1 dp `cs.outlineVariant` border,
///   radius 999, 8 / 4 dp padding;
/// - a hit area of at least `kMinTapTarget` (48 × 48) with the pill centred
///   inside it.
///
/// Hosts usually lay several badges out in a `Wrap` next to a chart, a
/// figure or a table.
///
/// Accessibility: one semantics node labelled "[source]: [description]",
/// with no `tooltip` property, so neither the visible text nor the
/// description is read a second time. An empty [description] gives no
/// tooltip, a natural-height pill and the label [source] alone.
///
/// **The tooltip needs an `Overlay` ancestor** (a routed page or a modal):
/// do not use this badge in `Layout`, which sits above the Navigator.
///
/// Content strings are already localised by the host.
final class SourceBadge extends StatelessWidget with _ViewMixin {
  /// Short label rendered on the pill (e.g. "Census 2024").
  final String source;

  /// Full text shown in the tooltip and announced by screen readers.
  final String description;

  const SourceBadge({
    super.key,
    required this.source,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

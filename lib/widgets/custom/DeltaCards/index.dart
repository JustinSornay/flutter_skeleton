// index.dart
//
// DeltaCards — compact row of 2 to 4 equal cards, each summarising how one
// metric changed between two states (before / after, period A / B, plan /
// actual): label, value and a toned trend caption. The value classes and the
// numeric / categorical derivation live in item.dart; view.dart maps the
// items onto a StatStrip row of MetricTiles.

import "dart:math" as math;

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/StatStrip/index.dart";

part "item.dart";
part "view.dart";

/// Row of 2 to 4 equal-width, equal-height cards, one per [DeltaCardItem],
/// left to right.
///
/// Each card shows:
/// - the item label (upper-cased, muted),
/// - the item value (pre-formatted, e.g. "↑ +3.3 %" from
///   [DeltaCardItem.numeric]),
/// - a trend caption: [DeltaCardItem.trendLabel], or the default caption of
///   [DeltaCardItem.trend] (`custom.delta_cards.increase` / `decrease` /
///   `stable` / `shift`) when it is null or empty, tinted with the
///   [DeltaCardItem.tone] foreground (`neutral` = `cs.onSurfaceVariant`).
///   The meaning of a change is therefore always given by text, never by
///   colour alone.
///
/// Rendering is delegated to [StatStrip] (`layout: StatStripLayout.row`,
/// `padding: EdgeInsets.zero`): every card is an outlined `MetricTile`, the
/// cards are `kDefaultPadding` apart, share the width equally and take the
/// height of the tallest one. Long labels wrap; values and captions stay on
/// one line with an ellipsis. Needs a bounded width.
///
/// The widget formats nothing beyond what the factories do and judges
/// nothing: the host passes localised strings, or raw before / after values
/// through [DeltaCardItem.numeric] / [DeltaCardItem.categorical] and says
/// which direction is adverse.
///
/// Accessibility: each card is one semantics node labelled
/// "label, value, caption".
///
/// [items] must hold 2 to 4 entries (checked by an assert when built).
/// No tooltip, so no `Overlay` ancestor is needed.
final class DeltaCards extends StatelessWidget with _ViewMixin {
  /// Cards, rendered left to right. 2 to 4 entries.
  final List<DeltaCardItem> items;

  const DeltaCards({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

// index.dart
//
// IndicatorChipRow — compact, read-only row of icon-and-label indicator
// chips that reflows over several lines on narrow panels. Each chip is an
// IndicatorChip, coloured by its entry's StatusTone when active and muted
// (neutral tone) otherwise. Value class: IndicatorChipEntry (entry.dart);
// tree in view.dart.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/IndicatorChip/index.dart";

part "entry.dart";
part "view.dart";

/// Read-only [Wrap] of [IndicatorChip]s, one per entry, in the given order.
///
/// - Layout: chips are `kDefaultPadding / 2` (4 dp) apart horizontally and
///   between runs; they reflow onto new lines when the row is too narrow, and
///   a label longer than the row ellipsizes instead of overflowing.
/// - Chip: `IndicatorChip(label, icon, tone: active ? entry.tone :
///   StatusTone.neutral)`, so the chips look the same as every other
///   indicator chip (radius 8, tinted fill and border, 14 dp icon).
/// - Muted: an inactive entry ([IndicatorChipEntry.active] false) ignores its
///   tone and renders in the neutral tone (`cs.onSurfaceVariant`). The label
///   always stays visible, so the state never relies on colour alone: the
///   host's label should carry it (e.g. a count of 0). An active entry with
///   the neutral tone (the default) looks the same as a muted one, so
///   [IndicatorChipEntry.active] only shows when
///   [IndicatorChipEntry.tone] is not neutral.
/// - Semantics: each chip is its own node labelled
///   [IndicatorChipEntry.semanticsLabel], falling back to the label.
/// - An empty [entries] list renders nothing (an empty [Wrap]).
///
/// Inert and overlay-free: no tooltip, no callback, no Overlay needed.
/// Content strings are already localised by the host.
final class IndicatorChipRow extends StatelessWidget with _ViewMixin {
  /// Chips rendered left to right, then top to bottom.
  final List<IndicatorChipEntry> entries;

  const IndicatorChipRow({
    super.key,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

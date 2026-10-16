// index.dart
//
// DistributionBar — a part-of-whole breakdown: one stacked horizontal bar
// whose slices are each segment's share of the total, and a wrapping legend
// ("label · 42%") under it, inside a bordered card with an optional title
// (a SectionCard when titled). The value class lives in segment.dart, the
// tree in view.dart and its private pieces (bar, legend entry) in widgets/.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/utils/formatters/intl_locale.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/SectionCard/index.dart";
import "package:intl/intl.dart" show NumberFormat;

part "segment.dart";
part "view.dart";
part "widgets/legend_entry.dart";
part "widgets/stacked_bar.dart";

/// Stacked proportional bar plus legend, in a card with an optional title.
///
/// Fits any categorical breakdown: storage by file type, items by status,
/// budget by category, votes by option…
///
/// Layout (needs a bounded width; the height hugs the content):
/// - Card: `cs.surfaceContainerLow`, a `cs.outlineVariant` border, radius 12,
///   clipped with [Clip.antiAlias]. When [title] is set, the card is a
///   [SectionCard], so the title (`labelSmall` w600, letter-spacing 1.4,
///   `cs.onSurfaceVariant`, a semantic header) and its 1 dp divider follow
///   SectionCard's chrome; without a title, a bare card with the same panel
///   tokens hosts the body.
/// - Body (16 dp padding): a 12 dp bar with fully rounded ends (radius 999,
///   track `cs.surfaceContainerHighest`) split into one slice per segment,
///   left to right, sized by `value / sum of values`; then, 12 dp below, a
///   [Wrap] legend with one entry per segment: an 8 dp dot and the legend
///   text in `labelSmall`, `cs.onSurface`.
///
/// Shares come from the sum of the segment values only. A segment whose
/// slice would round to nothing (a zero value or a tiny share) draws no
/// slice but keeps its legend entry. When [segments] is empty or every value
/// is 0, the widget renders nothing (`SizedBox.shrink`), title included.
///
/// Segment colour (slice and legend dot): [DistributionBarSegment.color],
/// else the foreground of [DistributionBarSegment.tone]
/// (`StatusTones.colorsOf(context, tone).foreground`), else a `ColorScheme`
/// cycle by index: primary, tertiary, secondary, error, onPrimaryContainer,
/// onTertiaryContainer, outline. Every cycle token reaches at least 3:1
/// against the card in AppTheme light and dark (WCAG 1.4.11 non-text
/// contrast). Beyond seven segments the cycle repeats, so pass explicit
/// colours or tones when every slice must be told apart.
///
/// Legend text: [legendTextBuilder], else `"label · <percent>"` with the share
/// formatted by intl `NumberFormat.percentPattern` for the ambient locale
/// (`Localizations.maybeLocaleOf`), e.g. `42%` in English, `42\u00A0%` in
/// French (a no-break space, U+00A0, before the sign).
///
/// Accessibility: the bar and the dots are decorative (`ExcludeSemantics`);
/// the legend text carries every label and share, so the breakdown never
/// relies on colour alone.
///
/// No overlay is used, so the widget works anywhere in the tree, including
/// `Layout`. Labels and [title] are content, already localised by the host;
/// the widget has no chrome strings.
final class DistributionBar extends StatelessWidget with _ViewMixin {
  /// Segments in display order (bar left to right, then legend order).
  final List<DistributionBarSegment> segments;

  /// Card title, rendered verbatim (uppercase it yourself for an overline
  /// look). Null leaves out the title and its divider.
  final String? title;

  /// Replaces the default legend text of each entry. [share] is the
  /// segment's share of the total, in `[0, 1]`.
  final String Function(DistributionBarSegment segment, double share)? legendTextBuilder;

  const DistributionBar({
    super.key,
    required this.segments,
    this.title,
    this.legendTextBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

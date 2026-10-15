// index.dart
//
// ListEntryCard — tappable row of a result list: a bold title, an optional
// muted subtitle, an optional status pill (StatusPill) and a chevron, with an
// optional body slot below the header (range bar, sparkline, metric row, …).
// The tree lives in view.dart.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";

part "view.dart";

/// One row of a result list, opened by a tap.
///
/// Layout (needs a bounded width; no card fill or border, so rows sit
/// directly on the host surface, typically separated by dividers):
/// - Padding 16 dp vertical / 4 dp horizontal, at least [kMinTapTarget]
///   (48 dp) tall.
/// - Header row, top-aligned:
///   - [title] (13 / w700, `cs.onSurface`, letter spacing −0.2, line height
///     1.2) and, 2 dp below, [subtitle] (10.5 / w500, `cs.onSurfaceVariant`).
///     Both wrap instead of overflowing. An empty subtitle is hidden.
///   - 8 dp gap, then a dense [StatusPill] showing [badgeLabel] in
///     [badgeTone] (tone `onContainer` on `container`), at most 120 dp wide
///     with an ellipsis. Null or empty → no pill.
///   - 4 dp gap, then an 18 dp `Icons.chevron_right` in `cs.onSurfaceVariant`,
///     only when [onTap] is set and [showChevron] is true.
/// - [body], 12 dp under the header, at full width. Null → nothing.
///
/// The card judges nothing: the host passes localised text and maps its own
/// status values to a [StatusTone], for instance:
///
/// ```dart
/// ListEntryCard(
///   title: item.name,
///   subtitle: item.group,
///   badgeLabel: levelName(item.level),
///   badgeTone: toneOf(item.level),
///   body: RangeEnvelopeBar(primary: series, min: 0, max: 100),
///   onTap: () => open(item.id),
/// )
/// ```
///
/// Interaction: with [onTap] the whole card is one [InkWell] (radius 8) on
/// its own transparent [Material], so the ink shows over any host surface
/// and no Material ancestor is needed. Null → no ink, no chevron.
///
/// Accessibility: the card is one merged semantics node. Its label is
/// [semanticsLabel], else the title, subtitle and badge joined with ", ";
/// the header itself is not read a second time. The [body]'s own semantics
/// are appended to that node, so keep the body non-interactive. With [onTap]
/// the node is a button with a tap action and the hint
/// `"custom.list_entry_card.open_hint".tr()`.
///
/// No tooltip, so the card itself needs no `Overlay` ancestor (a [body] that
/// uses one brings its own requirement).
final class ListEntryCard extends StatelessWidget with _ViewMixin {
  /// Main line, already localised. Wraps.
  final String title;

  /// Secondary line under [title]. Null or empty → hidden.
  final String? subtitle;

  /// Short status text, already localised, shown in a tinted pill at the
  /// trailing edge. Null or empty → no pill.
  final String? badgeLabel;

  /// Semantic tone of the pill. The label always accompanies the colour.
  final StatusTone badgeTone;

  /// Content under the header (range bar, chart, metric row, …). Null →
  /// omitted. Should be non-interactive: the whole card is the tap target.
  final Widget? body;

  /// Called when the card is tapped. Null → not interactive: no ink, no
  /// chevron, not a button.
  final VoidCallback? onTap;

  /// Shows the trailing chevron when [onTap] is set.
  final bool showChevron;

  /// Screen-reader label of the card. Null or empty → title, subtitle and
  /// badge joined with ", ".
  final String? semanticsLabel;

  const ListEntryCard({
    super.key,
    required this.title,
    this.subtitle,
    this.badgeLabel,
    this.badgeTone = StatusTone.neutral,
    this.body,
    this.onTap,
    this.showChevron = true,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

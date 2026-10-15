// index.dart
//
// AsyncSummaryCard — card that loads a short narrative text (summary,
// explanation, recommendation, …) through an injected async callback and owns
// its whole lifecycle: a pulsing skeleton, then either an error message with a
// retry button, or a header (icon, title, optional StatusPill badge, optional
// trailing slot) above the body text with **bold** markup and an optional
// italic footnote.
//
// AsyncSummary and AsyncSummaryBadge (what `load` returns) are declared here,
// state lives in view_model.dart, the card tree in view.dart and the private
// frame, header and skeleton in widgets/.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/utils/load_state.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/core/decorators/SkeletonPulse/index.dart";
import "package:flutter_skeleton/widgets/custom/SkeletonBlock/index.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";
import "package:logger/logger.dart";

part "view_model.dart";
part "view.dart";
part "widgets/card_frame.dart";
part "widgets/summary_header.dart";
part "widgets/summary_skeleton.dart";

/// Header badge of a loaded [AsyncSummaryCard] (a confidence level, a
/// freshness state, a source kind, …), rendered as a dense [StatusPill].
@immutable
final class AsyncSummaryBadge {
  /// Visible text, already localised by the host. It always accompanies the
  /// tone colour, so the badge never relies on colour alone. Empty hides the
  /// badge. The badge is at most 160 dp wide; a longer label is ellipsised
  /// (the semantics label still carries the full text).
  final String label;

  /// Fill and text colours from `StatusTones`. Null → [StatusTone.neutral]
  /// (`cs.onSurface` on `cs.surfaceContainerHighest`).
  final StatusTone? tone;

  /// Screen-reader label. Null or empty → [label]. The visible text is not
  /// read a second time.
  final String? semanticsLabel;

  const AsyncSummaryBadge({
    required this.label,
    this.tone,
    this.semanticsLabel,
  });
}

/// What [AsyncSummaryCard.load] resolves with.
@immutable
final class AsyncSummary {
  /// Body text, already localised. When [AsyncSummaryCard.parseBold] is true,
  /// `**x**` spans render in w700 and the markers are removed (also from the
  /// text read by screen readers). An unmatched `**` stays literal.
  final String text;

  /// Italic attribution or footnote under the body (where the text comes
  /// from, how it was produced, …). Null or empty hides it.
  final String? footnote;

  /// Header badge. Null, or a badge with an empty label, hides it.
  final AsyncSummaryBadge? badge;

  const AsyncSummary({
    required this.text,
    this.footnote,
    this.badge,
  });
}

/// Card that loads a short narrative text with [load] and shows it.
///
/// - [title]: header title (14 / w700, `cs.onSurface`), already localised.
///   It is a semantic header and wraps when the card is narrow.
/// - [load]: called once when the state is created, again on retry, and
///   whenever [reloadKey] changes. A throw or a rejected future shows the
///   error state; the error is logged and never escapes the widget. Timeouts,
///   fallbacks and the content itself are the host's job.
/// - [reloadKey]: compared with `==` in `didUpdateWidget`; a different value
///   starts a new load (back to the skeleton). The [load] closure itself is
///   never compared, since a parent rebuild recreates it. Pass a record of
///   every input that changes the text, e.g. `(itemId, variant)`. When a
///   newer load supersedes a pending one, the older result is dropped.
/// - [icon]: decorative leading header icon (18 dp, `cs.secondary`).
/// - [headerTrailing]: optional widget at the right end of the header, after
///   the badge (a help link, a menu, …). Shown in the loaded state only.
/// - [errorMessage]: italic error-state text, announced as a live region.
///   Null → `custom.async_summary_card.unavailable`. The retry button reads
///   `custom.async_summary_card.retry`.
/// - [parseBold]: renders `**bold**` markup in [AsyncSummary.text]; false
///   shows the asterisks literally.
///
/// States:
/// - Loading: four `SkeletonBlock` text lines (radius 4) pulsing with
///   `SkeletonPulse`, static under reduced motion (no ticker runs), announced
///   as `custom.async_summary_card.loading`.
/// - Error: [errorMessage] and a [kMinTapTarget] retry `TextButton`.
/// - Loaded: header on `cs.surfaceContainer`, a `cs.outlineVariant` divider,
///   then the body (14 / w400, line height 1.5, `cs.onSurface`) and the
///   footnote (11 italic, `cs.onSurfaceVariant`).
///
/// Layout: a `cs.surfaceContainerLow` card, radius 16, 1 dp
/// `cs.outlineVariant` border, that takes the full available width (it needs
/// a bounded width) and hugs its content vertically.
///
/// The widget itself uses no tooltip or other overlay, so it works anywhere
/// in the tree, including `Layout`. A [headerTrailing] that shows a tooltip
/// or a menu brings its own `Overlay` requirement (a routed page or a modal).
final class AsyncSummaryCard extends StatefulWidget {
  /// Header title.
  final String title;

  /// Fetches the content.
  final Future<AsyncSummary> Function() load;

  /// A change (by `==`) triggers a new load.
  final Object? reloadKey;

  /// Leading header icon.
  final IconData icon;

  /// Optional widget at the end of the header (loaded state only).
  final Widget? headerTrailing;

  /// Error-state text; null uses the built-in message.
  final String? errorMessage;

  /// Whether `**bold**` markup is rendered.
  final bool parseBold;

  const AsyncSummaryCard({
    super.key,
    required this.title,
    required this.load,
    this.reloadKey,
    this.icon = Icons.auto_awesome_rounded,
    this.headerTrailing,
    this.errorMessage,
    this.parseBold = true,
  });

  @override
  State<AsyncSummaryCard> createState() => _AsyncSummaryCardState();
}

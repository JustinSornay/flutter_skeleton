// index.dart
//
// ContextHeader — header for a detail panel: a leading icon, a title that may
// still be loading (pulsing skeleton), an always-visible subtitle, an
// optional inline "change" link and a divider below. The host owns any async
// lookup and passes its result in. The tree lives in view.dart; the loading
// placeholder composes SkeletonPulse + SkeletonBlock.

import "dart:math" as math;

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/core/decorators/SkeletonPulse/index.dart";
import "package:flutter_skeleton/widgets/custom/SkeletonBlock/index.dart";

part "view.dart";

/// Header for a detail panel showing what the panel is about, e.g. a place
/// name over its coordinates, a person's name over an identifier, or a file
/// name over its path, with an optional link to pick another one.
///
/// Layout (start to end): [icon] (22 dp, `cs.primary`), then a column with
/// the [title] (18 sp w700, `cs.onSurface`, one line, ellipsis) and the
/// [subtitle] (13 sp w400, `cs.onSurfaceVariant`), then the optional change
/// link (12 sp w700, 0.3 tracking, `cs.primary`), its label level with the
/// first text line. A full-width [Divider] (theme colour) closes the header.
/// The header takes its content height, even in a bounded parent.
///
/// [title] states:
/// - null: still resolving — a pulsing `SkeletonBlock(width: 120, height: 14)`
///   is shown, announced as `"custom.context_header.loading"`. It sits in a
///   slot one title line tall, so the subtitle does not move when the title
///   arrives. Under reduced motion the block is static (no SkeletonPulse is
///   mounted).
/// - `""`: no title row; the subtitle is still shown.
/// - otherwise: the title text.
///
/// The link is rendered only when [onChange] is set. Its hit area is at least
/// [kMinTapTarget] (48 × 48) and it is one button semantics node labelled
/// [changeSemanticsLabel] (falls back to the full visible label). It takes its
/// natural width up to 40 % of the row; a longer label (or a large text
/// scale) ends it with an ellipsis, so the title column always keeps the rest.
/// To cap the link the header reads its width (`LayoutBuilder`), so a header
/// *with a link* cannot sit under an intrinsic-size parent (`IntrinsicWidth`,
/// `IntrinsicHeight`, or the `content` of an `AlertDialog`); without a link
/// it can.
///
/// The widget never navigates: [onChange] does. The link carries its own
/// transparent `Material`, so neither a `Material` nor an `Overlay` ancestor
/// is needed.
final class ContextHeader extends StatelessWidget with _ViewMixin {
  /// Leading icon, e.g. `Icons.location_on`, `Icons.person_outline` or
  /// `Icons.description_outlined`. Decorative (not read by screen readers).
  final IconData icon;

  /// Primary label, already localised by the host. null shows the loading
  /// skeleton; an empty string hides the title row.
  final String? title;

  /// Secondary line, always shown (the value known upfront: a position, an
  /// identifier, a path…).
  final String subtitle;

  /// Called when the trailing link is tapped. null hides the link.
  final VoidCallback? onChange;

  /// Visible link text, best kept short (one or two words). It takes its
  /// natural width up to 40 % of the row, then ends with an ellipsis. null
  /// shows the built-in `"custom.context_header.change"` label.
  final String? changeLabel;

  /// Screen-reader label for the link (e.g. "Change the location"). Falls
  /// back to the full visible label (never the ellipsised one).
  final String? changeSemanticsLabel;

  const ContextHeader({
    super.key,
    required this.icon,
    this.title,
    required this.subtitle,
    this.onChange,
    this.changeLabel,
    this.changeSemanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

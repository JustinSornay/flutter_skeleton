// index.dart
//
// StatusPill — non-interactive status label tinted by a StatusTone: a
// PillBadge filled with the tone's container colour (default constructor) or
// a 24 dp circle, scaled with the text, showing a one- or two-character code
// (StatusPill.compact). An empty label renders nothing. The tree lives in
// view.dart.

import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/PillBadge/index.dart";

part "view.dart";

/// Tinted, non-interactive status label (record states, review states,
/// rating classes, an outlook for a later period, …).
///
/// - Colours: `StatusTones.colorsOf(context, tone)` — the text and the icon
///   use `onContainer` on a `container` fill (≥ 4.5:1 for every tone, light
///   and dark). `neutral` is `cs.onSurface` on `cs.surfaceContainerHighest`,
///   `danger` is `cs.onErrorContainer` on `cs.errorContainer`.
/// - Default constructor: a [PillBadge] (radius 999, 11 sp / w700 label on
///   one line with an ellipsis, optional 14 dp leading [icon], 12 / 8 dp
///   padding or 8 / 4 dp when [dense]).
/// - [StatusPill.compact]: a 24 × 24 circle showing [letter] (one or two
///   characters, asserted); [label] is not drawn but is the accessible name.
///   Under a larger text scale the circle grows with the code's font, so the
///   code stays whole and centred.
/// - An empty [label] renders `SizedBox.shrink()` in both variants, so a host
///   can mount it before its data is ready, or for a status it does not show,
///   without a guard.
///
/// The host maps its own status values to a [StatusTone] and passes already
/// localised text. The label (or, in the compact variant, the letter plus the
/// accessible name) always accompanies the colour, never colour alone. For an
/// outlook such as "Ready · Q3", compose the text in the host and pass
/// `icon: Icons.arrow_forward_rounded`.
///
/// Accessibility: one semantics node labelled [semanticsLabel] (default
/// [label]); the visible text is not read a second time.
///
/// No tooltip, so no `Overlay` ancestor is needed.
final class StatusPill extends StatelessWidget with _ViewMixin {
  /// Status text, already localised. Shown in the pill; in the compact
  /// variant it is only the accessible name. Empty → nothing is rendered.
  final String label;

  /// One or two characters drawn in the compact circle. Asserted in debug
  /// builds: 1–2 UTF-16 code units (constructor) and not blank (build), so the
  /// circle never shows colour alone; the circle scales with the text, so the
  /// code is not clipped. Null for the pill.
  final String? letter;

  /// Semantic tone giving the fill and the text colour.
  final StatusTone tone;

  /// Leading icon (14 dp, text colour). Pill only.
  final IconData? icon;

  /// Compact padding (8 / 4 dp instead of 12 / 8 dp). Pill only.
  final bool dense;

  /// Screen-reader label. Null or empty → [label]. Pill only.
  final String? semanticsLabel;

  /// Rounded pill showing [label].
  const StatusPill({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    this.dense = false,
    this.semanticsLabel,
  }) : letter = null;

  /// Circle (24 dp at the default text scale) showing [letter]; [label] is
  /// announced instead.
  const StatusPill.compact({
    super.key,
    required String this.letter,
    required this.label,
    this.tone = StatusTone.neutral,
  })  : assert(letter.length > 0 && letter.length <= 2, "letter must be one or two characters"),
        icon = null,
        dense = false,
        semanticsLabel = null;

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

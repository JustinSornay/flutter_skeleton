// index.dart
//
// ScoreBanner — full-width summary banner for a normalised score in [0, 1],
// coloured by a StatusTone: a status icon circle, a message written by the
// host, a thin score bar with its value label, an optional caveat note and an
// optional underlined link. The note value class lives in values.dart, the
// tree in view.dart, and the score row, note pill and link in widgets/.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "values.dart";
part "view.dart";
part "widgets/banner_link.dart";
part "widgets/note_pill.dart";
part "widgets/score_row.dart";

/// Full-width, tone-coloured summary banner for a normalised score (a
/// rating, a health or compliance score, a match quality, a completion
/// level…), shown at the top of a detail panel.
///
/// - Background: the [tone] `container` colour, radius 8, 24 / 16 dp padding.
///   The message, the value text, the bar, the link and the icon circle use
///   the tone `onContainer` colour; the glyph inside the circle uses
///   `container` (inverted), so every pairing keeps the tone's ≥ 4.5:1
///   contrast.
/// - Icon: [icon], else the tone's own glyph ([StatusTone.icon]), in a 30 dp
///   filled circle. It is decorative (no semantics node): the [message]
///   carries the meaning, so the tone is never conveyed by colour alone.
/// - [message]: the sentence beside the icon, written and localised by the
///   host (which also maps its own score thresholds to a [tone]).
/// - Score row: a 5 dp bar (radius 999) and the value text on its right:
///   [valueLabel], else `custom.score_banner.value` ("72 / 100"). [value] is
///   clamped to `[0, 1]` (NaN counts as 0) for both the bar and the default
///   text. The row is one semantics node labelled [valueLabel], else
///   `custom.score_banner.value_semantics` ("Score: 72 out of 100").
///   - Bar colours are an explicit exception to the shared bar tokens
///     (track `cs.surfaceContainerHighest`, fill = tone `foreground`), which
///     are meant for bars on a surface. On a tone `container` that track
///     vanishes (neutral in both themes, primary and danger in light) and the
///     `foreground` fill fades into the dark seeded containers (≈ 1.5:1). The
///     bar is therefore tone-derived: fill = `onContainer`, track =
///     `onContainer` at 18 % alpha, so the 0–100 extent shows on every tone
///     and the fill keeps ≥ 3:1 against the track and ≥ 4.5:1 against the
///     banner.
///   - The value text stays on one line and takes at most half the row; a
///     longer label ends with an ellipsis while the semantics node keeps the
///     full text.
/// - [note]: an optional caveat pill under the bar, in the note's own tone
///   (see [ScoreBannerNote]). Hidden when null.
/// - [onLink]: shows an underlined link under the content, labelled
///   [linkLabel], else `custom.score_banner.link`. The link has a 48 dp
///   minimum hit area and link + button semantics. Hidden when null.
///
/// Inert: no animation, no tooltip, no overlay, so it needs no `Overlay`
/// ancestor. It brings its own transparent `Material` for the link ink, so
/// it also needs no `Material` ancestor.
final class ScoreBanner extends StatelessWidget with _ViewMixin {
  /// Sentence beside the icon, already localised by the host.
  final String message;

  /// Normalised score in `[0, 1]`. Out-of-range values are clamped; NaN
  /// renders as 0.
  final double value;

  /// Colour family of the background, text, icon circle, bar and link.
  final StatusTone tone;

  /// Glyph inside the icon circle; null → [StatusTone.icon] of [tone].
  final IconData? icon;

  /// Text beside the bar and the bar's semantics label. Shown on one line in
  /// at most half the row (ellipsis beyond); the semantics label keeps the
  /// full text. Null → `custom.score_banner.value`.
  final String? valueLabel;

  /// Optional caveat pill under the bar; hidden when null.
  final ScoreBannerNote? note;

  /// Called when the link is tapped; null hides the link.
  final VoidCallback? onLink;

  /// Link text; null → `custom.score_banner.link`.
  final String? linkLabel;

  const ScoreBanner({
    super.key,
    required this.message,
    required this.value,
    required this.tone,
    this.icon,
    this.valueLabel,
    this.note,
    this.onLink,
    this.linkLabel,
  });

  /// [value] clamped to `[0, 1]`; NaN → 0.
  static double _ratio(double value) {
    if (value.isNaN) return 0;
    return value.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

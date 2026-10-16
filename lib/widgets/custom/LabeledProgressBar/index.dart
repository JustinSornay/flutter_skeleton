// index.dart
//
// LabeledProgressBar — labelled horizontal determinate bar for a ratio in
// [0, 1]: a header row (label left, formatted value right) above a 12 dp pill
// bar. Pure presentation: data, tone and colour come from parameters. The tree
// lives in view.dart. A non-primary tone adds its StatusTone.icon before the
// value text.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/utils/formatters/intl_locale.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:intl/intl.dart";

part "view.dart";

/// Labelled horizontal progress bar for a ratio in `[0, 1]` (completion,
/// usage, a test result, a vote share, a per-criterion rating…).
///
/// - Header row: [label] on the left (`bodyMedium`, w600, wraps when long)
///   and the value text on the right (`titleMedium`, w800), both in
///   `cs.onSurface`. Keep [valueLabel] short: it (and the tone icon) never
///   shrinks or truncates, so a long one overflows a narrow box.
/// - Value text: [valueLabel], else [value] as a percentage formatted by intl
///   `NumberFormat.percentPattern` for the ambient locale
///   (`Localizations.maybeLocaleOf`; an unknown locale falls back to intl's
///   default), e.g. `73%` in English, `73 %` in French.
/// - Bar: 12 dp below the header, 12 dp thick, spanning the available width
///   (the parent must bound it). Shared bar tokens: track
///   `cs.surfaceContainerHighest`, radius 999, fill = [color], else the
///   [tone] foreground (`StatusTones.colorsOf(context, tone).foreground`;
///   `primary` → `cs.primary`).
/// - Tone icon: when the fill shows a non-primary [tone] (no [color]
///   override), `tone.icon` (16 dp, in the tone foreground) sits before the
///   value text, so the status is never shown by colour alone. The default
///   `primary` tone and a [color] override draw no icon.
/// - [value] is clamped to `[0, 1]` and NaN counts as 0, for both the bar and
///   the default text.
///
/// Accessibility: one semantics node whose label is [label] and whose value
/// is the value text; the visible texts, the tone icon and the bar are not
/// read again. A host conveying a status (a non-primary [tone], or a [color]
/// override) names it in [label] or [valueLabel] so screen readers hear it.
///
/// Inert and overlay-free (no callbacks, no tooltip, no animation): it needs
/// no `Overlay` ancestor. Content strings ([label], [valueLabel]) are already
/// localised by the host.
final class LabeledProgressBar extends StatelessWidget with _ViewMixin {
  /// Name shown on the left of the header row; also the semantics label.
  final String label;

  /// Ratio in `[0, 1]`. Out-of-range values are clamped; NaN renders as 0.
  final double value;

  /// Semantic tone giving the default fill colour (its `foreground`).
  /// Callers mapping thresholds to a status pick the tone here; any tone but
  /// `primary` also draws `tone.icon` before the value text. Name the status
  /// in [label] or [valueLabel] too: the icon is not announced.
  final StatusTone tone;

  /// Fill colour override; wins over [tone] (no tone icon is drawn). If it
  /// encodes a status, name that status in [label] or [valueLabel].
  final Color? color;

  /// Text shown on the right and announced as the semantics value
  /// (e.g. "3/5", "45 GB"). Null → the locale-aware percentage of [value].
  final String? valueLabel;

  const LabeledProgressBar({
    super.key,
    required this.label,
    required this.value,
    this.tone = StatusTone.primary,
    this.color,
    this.valueLabel,
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

// index.dart
//
// IndicatorChip — compact tinted chip showing one indicator: an optional
// leading icon, a host-supplied label and an optional ratio appended as a
// locale-formatted percentage, e.g. "Ref: Moderate (55 %)". Fill, border,
// icon and text all derive from one StatusTone (or a colour override). An
// optional tap tooltip explains the indicator. The tree lives in view.dart.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:intl/intl.dart";

part "view.dart";

/// Rounded chip (radius 8) showing [label] and, when set, [ratio] as
/// " (55 %)", tinted by [tone].
///
/// - Foreground (icon and text): [color], else the [tone] foreground from
///   `StatusTones.colorsOf(context, tone)` (`neutral` → `cs.onSurfaceVariant`,
///   `primary` → `cs.primary`). [color] serves data palettes with more steps
///   than the status tones (e.g. a 5-class scale); pass a `ColorScheme` or
///   `StatusTones` colour.
/// - Fill: the foreground at 6 % opacity; border: the foreground at 30 %.
///   With a [tone], the text keeps >= 4.5:1 contrast on any surface from
///   `cs.surface` to `cs.surfaceContainerHighest`, in both themes. With
///   [color], contrast is the host's responsibility.
/// - The text is `textTheme.labelMedium` in w600 on one line, with an
///   ellipsis when the parent is too narrow. Because the label is always
///   visible, the tone is never colour-only.
/// - [ratio] (in `[0, 1]`) is formatted with intl
///   `NumberFormat.percentPattern` for the ambient locale
///   (`Localizations.maybeLocaleOf`, falling back to intl's default locale
///   when there is none or it is unknown) — "55%" in English, "55 %" in
///   French.
/// - Sizes to its content: under tight constraints the chip stays compact,
///   centred in the space it is given, with or without a tooltip.
///
/// Accessibility: the chip is its own semantics node (it never merges into an
/// enclosing one), labelled [semanticsLabel] (falls back to the visible text,
/// label + percentage) and carrying [tooltip]; the visible text is not read a
/// second time.
///
/// When [tooltip] is non-empty the message is shown on tap
/// ([TooltipTriggerMode.tap], no wait, visible 5 s) and the hit area grows to
/// [kMinTapTarget] (48 × 48) with the visible chip centred inside it.
/// **The tooltip needs an `Overlay` ancestor** (a routed page or a modal): do
/// not use a tooltip chip in `Layout`, which sits above the Navigator.
/// Without a tooltip no Overlay is needed.
///
/// Content strings ([label], [tooltip], [semanticsLabel]) are already
/// localised by the host. To hide the chip, leave it out of the tree
/// (collection-if): it always renders its label.
final class IndicatorChip extends StatelessWidget with _ViewMixin {
  /// Visible main text, one line.
  final String label;

  /// Optional value in `[0, 1]`, appended to [label] as a percentage.
  final double? ratio;

  /// Leading icon (14 dp) in the foreground colour. Omitted when null.
  final IconData? icon;

  /// Semantic tone giving the foreground, fill and border colours.
  final StatusTone tone;

  /// Foreground override (fill and border are derived from it).
  final Color? color;

  /// Message shown on tap. Null or empty → no tooltip, no enlarged hit area.
  /// Needs an `Overlay` ancestor.
  final String? tooltip;

  /// Screen-reader label. Falls back to the visible text. It replaces both
  /// [label] and the percentage, so an override should repeat the formatted
  /// ratio when [ratio] is set.
  final String? semanticsLabel;

  const IndicatorChip({
    super.key,
    required this.label,
    this.ratio,
    this.icon,
    this.tone = StatusTone.neutral,
    this.color,
    this.tooltip,
    this.semanticsLabel,
  }) : assert(ratio == null || (ratio >= 0 && ratio <= 1), "ratio must be in [0, 1]");

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

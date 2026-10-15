// index.dart
//
// ConfidenceBadge — compact indicator for a normalised 0..1 reliability,
// quality or confidence value: an icon plus a "title : level" label in the
// tone of the level (high / moderate / low), with a tap tooltip showing the
// percentage or a host-supplied hint. Level bucketing lives in
// ConfidenceBadge.levelOf, the tree in view.dart. Value enum: ConfidenceLevel.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "view.dart";

/// Qualitative bucket of a normalised value, with its status tone.
enum ConfidenceLevel {
  high(StatusTone.success),
  moderate(StatusTone.warning),
  low(StatusTone.danger);

  const ConfidenceLevel(this.tone);

  /// Tone colouring the icon and the label (success / warning / danger).
  final StatusTone tone;
}

/// Icon + "title : level" label coloured by the [ConfidenceLevel] of [value].
/// Tapping it shows a tooltip.
///
/// - Level: [levelOf] — `value >= highAt` → high, `value >= moderateAt` →
///   moderate, otherwise low ([value] is clamped to `[0, 1]` first).
/// - Colour: the level's [ConfidenceLevel.tone] foreground from
///   `StatusTones.colorsOf(context, tone)`, applied to the icon and the label.
///   The level is always spelled out in the label, so it never relies on
///   colour alone.
/// - Label: `custom.confidence_badge.label` with the [title] (default
///   `custom.confidence_badge.title`) and the level word
///   (`custom.confidence_badge.high` / `moderate` / `low`), one line, ellipsis
///   when the parent is too narrow. It is also the semantics label.
/// - Tooltip: [hint] when non-empty, otherwise
///   `custom.confidence_badge.tooltip` with the title, the level and the
///   percentage formatted by intl `NumberFormat.percentPattern` for the
///   current locale (`90 %` in French, `90%` in English). The percentage is
///   floored to a whole percent, so a value just below a threshold never
///   shows the threshold (0.7999 → `79%`, still moderate). Shown on tap
///   ([TooltipTriggerMode.tap]) for 5 s; screen readers get it as the
///   tooltip of the badge's semantics node.
/// - Hit area: at least [kMinTapTarget] × [kMinTapTarget] (48 × 48).
///
/// **Needs an `Overlay` ancestor** (a routed page or a modal) for its
/// [Tooltip]: do not place it in `Layout`, which sits above the Navigator.
///
/// Content strings ([title], [hint]) are already localised by the host.
final class ConfidenceBadge extends StatelessWidget with _ViewMixin {
  /// Normalised value in `[0, 1]`. Values outside the range are clamped.
  final double value;

  /// Prefix of the label. Null → `custom.confidence_badge.title`.
  final String? title;

  /// Tooltip text replacing the default "title : level (percent)". The host
  /// builds any contextual explanation and passes it here. Null or empty →
  /// default tooltip.
  final String? hint;

  /// `value >= highAt` → [ConfidenceLevel.high] (default 0.8).
  final double highAt;

  /// `value >= moderateAt` → [ConfidenceLevel.moderate], otherwise
  /// [ConfidenceLevel.low] (default 0.5).
  final double moderateAt;

  /// Leading icon, 14 dp (default [Icons.shield_outlined]).
  final IconData icon;

  const ConfidenceBadge({
    super.key,
    required this.value,
    this.title,
    this.hint,
    this.highAt = 0.8,
    this.moderateAt = 0.5,
    this.icon = Icons.shield_outlined,
  }) : assert(moderateAt <= highAt, "moderateAt must not exceed highAt");

  /// Buckets [value] (clamped to `[0, 1]`; NaN counts as 0) into a level.
  /// Exposed so hosts can reuse the bucketing, e.g. to decide whether to show
  /// the badge at all.
  static ConfidenceLevel levelOf(
    double value, {
    double highAt = 0.8,
    double moderateAt = 0.5,
  }) {
    final double v = _normalize(value);
    if (v >= highAt) return ConfidenceLevel.high;
    if (v >= moderateAt) return ConfidenceLevel.moderate;
    return ConfidenceLevel.low;
  }

  /// [value] clamped to `[0, 1]`, with NaN mapped to 0.
  static double _normalize(double value) {
    return value.isNaN ? 0 : value.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

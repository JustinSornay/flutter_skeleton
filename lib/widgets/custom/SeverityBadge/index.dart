// index.dart
//
// SeverityBadge — inline pill flagging how serious one item is on a 3-level
// scale (SeverityLevel: low / medium / high → success / warning / danger
// tone). Composes StatusPill; the tree lives in view.dart. The value-to-level
// mapping is SeverityLevel.fromValue, with thresholds supplied by the host.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";

part "view.dart";

/// Ordered severity scale rendered by [SeverityBadge].
enum SeverityLevel {
  low(StatusTone.success, "custom.severity_badge.low"),
  medium(StatusTone.warning, "custom.severity_badge.medium"),
  high(StatusTone.danger, "custom.severity_badge.high");

  const SeverityLevel(this.tone, this.semanticsKey);

  /// Tone of the pill: low → success, medium → warning, high → danger.
  final StatusTone tone;

  /// i18n key of the level name announced by the default semantics label
  /// (`custom.severity_badge.low` / `medium` / `high`).
  final String semanticsKey;

  /// Maps [value] onto the scale: `value >= highAt` → [high],
  /// `value >= mediumAt` → [medium], otherwise [low] (NaN → [low]).
  ///
  /// Higher values are worse; for a "higher is better" scale the host
  /// inverts the value first. There are no default thresholds: they are the
  /// host's own values. Asserts `mediumAt <= highAt`.
  static SeverityLevel fromValue(
    double value, {
    required double mediumAt,
    required double highAt,
  }) {
    assert(mediumAt <= highAt, "mediumAt must not exceed highAt");
    if (value >= highAt) return high;
    if (value >= mediumAt) return medium;
    return low;
  }
}

/// Tinted, non-interactive pill flagging the [severity] of a single item, for
/// rows, tables and score displays.
///
/// - Composes [StatusPill] with `severity.tone`: `onContainer` text and icon
///   on the tone `container` fill (≥ 4.5:1, light and dark), radius 999,
///   11 sp / w700 label on one line with an ellipsis, 12 / 8 dp padding.
/// - Text: "[label] [valueLabel]" (an empty or null [valueLabel] is left
///   out), so the magnitude can be read without relying on colour.
/// - Leading icon: `severity.tone.icon` (check / warning / error outline), so
///   the level itself is never shown by colour alone.
/// - Sizes to its content; wrap it in `SizedBox(width: double.infinity)` for
///   a full-width pill. It is not interactive, so it has no 48 dp minimum.
/// - An empty [label] with no [valueLabel] renders nothing.
///
/// Accessibility: one semantics node labelled [semanticsLabel], or by
/// default "label, valueLabel, level name" (`custom.severity_badge.<level>`);
/// the visible text is not read a second time.
///
/// No tooltip, so no `Overlay` ancestor is needed.
///
/// Content strings ([label], [valueLabel], [semanticsLabel]) are already
/// localised by the host.
final class SeverityBadge extends StatelessWidget with _ViewMixin {
  /// Visible text naming the item.
  final String label;

  /// Level giving the tone and the icon.
  final SeverityLevel severity;

  /// Optional magnitude shown after [label] (e.g. "−22 %").
  final String? valueLabel;

  /// Screen-reader label. Null or empty → "label, valueLabel, level name".
  final String? semanticsLabel;

  const SeverityBadge({
    super.key,
    required this.label,
    required this.severity,
    this.valueLabel,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

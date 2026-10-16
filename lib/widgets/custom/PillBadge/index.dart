// index.dart
//
// PillBadge — small fully rounded label (pill) with an optional leading icon,
// an optional tap-triggered tooltip and one accessible label. It is the base
// of every badge-style widget (tags, states, versions, sources): callers pick
// a StatusTone or pass ColorScheme colours. The tree lives in view.dart.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "view.dart";

/// Pill-shaped badge: optional leading [icon] + [label], optional tap
/// [tooltip].
///
/// - Foreground (label and icon): [color], else the [tone] foreground from
///   `StatusTones.colorsOf(context, tone)` (`neutral` → `cs.onSurfaceVariant`).
///   The label is always visible, so a tone is never colour-only; pass
///   `tone.icon` as [icon] for an extra non-colour cue.
/// - Background: [backgroundColor], else `cs.surfaceContainerHigh` when
///   [outlined], else `cs.surface` at 72 % opacity (reads well over maps,
///   media and tinted surfaces).
/// - [outlined] adds a 1 dp `cs.outlineVariant` border.
/// - [dense] uses 8 / 4 dp padding instead of 12 / 8 dp.
/// - The label is 11 / w700 (`textTheme.labelSmall`) on one line, with an
///   ellipsis when the parent is too narrow.
///
/// Accessibility: the badge exposes one semantics node labelled
/// [semanticsLabel] (falls back to [label] when null or empty); the visible
/// text is not read a second time.
///
/// When [tooltip] is non-empty the message is shown on tap
/// ([TooltipTriggerMode.tap]) and the hit area grows to [kMinTapTarget]
/// (48 × 48) with the visible pill centred inside it. **The tooltip needs an
/// `Overlay` ancestor** (a routed page or a modal): do not use a tooltip
/// badge in `Layout`, which sits above the Navigator. Without a tooltip no
/// Overlay is needed.
///
/// Content strings ([label], [tooltip], [semanticsLabel]) are already
/// localised by the host.
final class PillBadge extends StatelessWidget with _ViewMixin {
  /// Visible text, one line.
  final String label;

  /// Semantic tone giving the default foreground colour.
  final StatusTone tone;

  /// Leading icon (14 dp) rendered before [label]. Omitted when null.
  final IconData? icon;

  /// Foreground override for the label and the icon.
  final Color? color;

  /// Fill override.
  final Color? backgroundColor;

  /// Adds a `cs.outlineVariant` border on a `cs.surfaceContainerHigh` fill.
  final bool outlined;

  /// Compact padding (8 / 4 dp instead of 12 / 8 dp).
  final bool dense;

  /// Message shown on tap. Null or empty → no tooltip, no enlarged hit area.
  /// Needs an `Overlay` ancestor.
  final String? tooltip;

  /// Screen-reader label. Null or empty → [label] is announced.
  final String? semanticsLabel;

  const PillBadge({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    this.color,
    this.backgroundColor,
    this.outlined = false,
    this.dense = false,
    this.tooltip,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

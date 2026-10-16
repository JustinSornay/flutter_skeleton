// index.dart
//
// FeatureGate — shows its child when access is granted, otherwise a locked
// state in one of five modes (lock card, dimmed preview, blurred teaser,
// compact hint row, hidden). Whatever decides access stays with the host:
// the widget receives a bool, display strings and an onUnlock callback.
// The tree lives in view.dart; each locked mode and the lock badge (a dense
// PillBadge) live in widgets/.

import "dart:ui" as ui;

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/PillBadge/index.dart";

part "view.dart";
part "widgets/dimmed_preview.dart";
part "widgets/hint_row.dart";
part "widgets/lock_badge.dart";
part "widgets/lock_card.dart";
part "widgets/teaser.dart";

/// How a locked [FeatureGate] renders. Has no effect while unlocked.
enum GateDisplayMode {
  /// Centred lock icon, the locked label and an unlock [TextButton] (the
  /// button only when [FeatureGate.onUnlock] is set). Default.
  lockCard,

  /// The real child at 40 % opacity, with the lock badge in its top-right
  /// corner. The child cannot be reached by pointer, keyboard focus (Tab) or
  /// screen readers. The whole area is one tap target calling
  /// [FeatureGate.onUnlock].
  dimmed,

  /// A blurred static mock ([FeatureGate.teaserBuilder], else a generic
  /// placeholder) under a scrim, with a centred pill (badge + label). The
  /// mock cannot be reached by pointer, keyboard focus or screen readers,
  /// and the teaser is at least as tall as the pill. It NEVER builds the real
  /// child and is not tappable. Needs a bounded width.
  teaser,

  /// One compact row: lock icon, label and badge, at least [kMinTapTarget]
  /// tall. The row calls [FeatureGate.onUnlock]. Meant to be grouped by a
  /// parent. Needs a bounded width: the label fills the space left by the
  /// icon and the badge, so the row throws inside an unbounded `Row`.
  hint,

  /// Nothing (`SizedBox.shrink()`) while locked.
  hidden,
}

/// Shows [child] when [isLocked] is false, otherwise a locked state chosen
/// by [mode] (see [GateDisplayMode]).
///
/// - Access is decided by the host (plan, role, permission, sign-in, feature
///   flag…), which passes the result as [isLocked]. To hide the gate in a
///   context where the feature is irrelevant, leave the widget out.
/// - Locked text: [lockedLabel] (the gated feature's name), else
///   `custom.feature_gate.title`. It appears in the lock card, the teaser
///   pill, the teaser placeholder and the hint row.
/// - Badge: a dense [PillBadge] with a lock icon, `cs.onPrimary` on
///   `cs.primary`, labelled [badgeLabel], else `custom.feature_gate.locked`.
///   The lock icon pairs the colour with a non-colour cue.
/// - [onUnlock] is called by the lock-card button, the hint row and the
///   dimmed area; navigation and analytics happen there. When null nothing
///   is tappable and the lock-card button is omitted. The teaser is never
///   tappable.
/// - Colours: `cs.onSurface` / `cs.onSurfaceVariant` text, teaser scrim
///   `cs.scrim` at 30 %, teaser pill `cs.surfaceContainerHighest` with a
///   `cs.outlineVariant` border and a `cs.shadow` shadow, placeholder bars
///   `cs.surfaceContainerHighest`.
///
/// Accessibility: each visible locked mode is one container semantics node
/// labelled `custom.feature_gate.semantics` (`{label}` = [lockedLabel]; the
/// default title alone when [lockedLabel] is null or empty), followed by the
/// badge text. The dimmed and hint modes carry the button flag and the tap
/// action when [onUnlock] is set; the lock-card button is its own node.
/// Tap targets are at least [kMinTapTarget] (48 dp).
///
/// The teaser and hint modes need a bounded width. No animation, no tooltip
/// and no other overlay are used, so no `Overlay` ancestor is needed; the
/// dimmed and hint modes bring their own transparent `Material` for the ink.
///
/// Content strings are already localised by the host.
///
/// ```dart
/// FeatureGate(
///   isLocked: !access.canExport,
///   lockedLabel: "export.title".tr(),
///   badgeLabel: "Plus",
///   onUnlock: showAccessOptions, // host navigation / analytics
///   child: const ExportButton(),
/// )
/// ```
final class FeatureGate extends StatelessWidget with _ViewMixin {
  /// When false, [child] is returned unchanged, whatever the [mode].
  final bool isLocked;

  /// The gated content. Built only while unlocked, or dimmed in
  /// [GateDisplayMode.dimmed]; never in [GateDisplayMode.teaser].
  final Widget child;

  /// How the locked state renders.
  final GateDisplayMode mode;

  /// Name of the gated feature shown while locked. Null or empty →
  /// `custom.feature_gate.title`.
  final String? lockedLabel;

  /// Short text of the lock badge (a plan, a role…). Null or empty →
  /// `custom.feature_gate.locked`. Keep it to a word or two: the badge keeps
  /// its natural width and the locked label shrinks first, so a badge wider
  /// than the whole hint row or teaser pill overflows.
  final String? badgeLabel;

  /// Text of the lock-card button. Null or empty →
  /// `custom.feature_gate.unlock`.
  final String? actionLabel;

  /// Called when the user asks to unlock. Null → nothing is tappable.
  final VoidCallback? onUnlock;

  /// Static mock content for [GateDisplayMode.teaser]. It MUST NOT show real
  /// data. Null → a generic placeholder (label and two bars).
  final WidgetBuilder? teaserBuilder;

  const FeatureGate({
    super.key,
    required this.isLocked,
    required this.child,
    this.mode = GateDisplayMode.lockCard,
    this.lockedLabel,
    this.badgeLabel,
    this.actionLabel,
    this.onUnlock,
    this.teaserBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

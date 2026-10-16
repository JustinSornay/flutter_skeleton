// index.dart
//
// ContextActionBar — floating row of round icon buttons for actions on the
// current selection or context (a selected shape, list row or canvas
// object). The buttons fade and slide in one after another when `visible`
// becomes true and fade out together when it becomes false.
// ContextActionBarItem describes one button. The state (view_model.dart) owns
// the single AnimationController, view.dart builds the row and
// widgets/action_button.dart one button.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "view_model.dart";
part "view.dart";
part "widgets/action_button.dart";

/// One button of a [ContextActionBar].
@immutable
final class ContextActionBarItem {
  /// Glyph drawn in the button (20 dp).
  final IconData icon;

  /// Tooltip and accessibility label, already localised by the host.
  final String label;

  /// Tap handler. Null renders the button disabled.
  final VoidCallback? onPressed;

  /// Draws the icon in `cs.error`, for delete, discard and similar actions.
  final bool destructive;

  const ContextActionBarItem({
    required this.icon,
    required this.label,
    this.onPressed,
    this.destructive = false,
  });
}

/// Floating row of round icon buttons acting on the current selection.
///
/// Each [ContextActionBarItem] becomes an `IconButton`: a 40 dp circle
/// (`cs.surfaceContainerHigh`, elevation 3, shadow `cs.shadow`) with a 20 dp
/// icon in `cs.onSurface` (`cs.error` when `destructive`, `cs.onSurface` at
/// 38 % when `onPressed` is null), centred in a 48 dp ([kMinTapTarget]) tap
/// target. Neighbouring circles are therefore 8 dp apart. The bar is
/// [height] tall and [widthFor] `(actions.length)` wide, so a host can clamp
/// it to the viewport, for example in a `Positioned` inside a `Stack`:
///
/// ```dart
/// final double left = (anchor.dx - ContextActionBar.widthFor(n) / 2)
///     .clamp(margin, size.width - ContextActionBar.widthFor(n) - margin);
/// ```
///
/// Motion: when [visible] becomes true (or on first mount with [visible]
/// true) the buttons fade in and slide up by a quarter of their height one
/// after another: `kMotionShort` each, 30 ms apart, `easeOutCubic`. When
/// [visible] becomes false they fade and slide out together in 160 ms. Both
/// go through `resolveMotion`, so they are instant under reduced motion.
/// While [visible] is false the bar ignores pointers and is excluded from
/// semantics, even during the exit animation.
///
/// Semantics: the row is one container node labelled [semanticLabel]
/// (default `custom.context_action_bar.semantics_label`), and each button
/// announces its `label` as its tooltip.
///
/// Every button shows a [Tooltip], so **the bar needs an `Overlay`
/// ancestor** (a routed page or a modal): mount it in a page, not in
/// `Layout`, which sits above the Navigator.
final class ContextActionBar extends StatefulWidget {
  /// Buttons, rendered left to right in the given order.
  final List<ContextActionBarItem> actions;

  /// True plays the staggered enter animation, false the exit animation.
  final bool visible;

  /// Label of the whole group, already localised. Defaults to
  /// `custom.context_action_bar.semantics_label`.
  final String? semanticLabel;

  const ContextActionBar({
    super.key,
    required this.actions,
    required this.visible,
    this.semanticLabel,
  });

  /// Height of the bar: one tap target.
  static const double height = kMinTapTarget;

  /// Width of a bar holding [count] buttons.
  static double widthFor(int count) {
    assert(count >= 0);
    return count * kMinTapTarget;
  }

  @override
  State<ContextActionBar> createState() => _ContextActionBarState();
}

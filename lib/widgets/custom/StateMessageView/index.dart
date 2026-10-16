// index.dart
//
// StateMessageView — centred, full-area state message for error, empty,
// prerequisite-missing or blocked screens: a tone-tinted icon badge, a title,
// an optional message, an optional gauge and up to two stacked actions.
// The tree lives in view.dart; the gauge and the buttons are private parts in
// widgets/. Value classes: StateMessageAction, StateMessageGauge.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "view.dart";
part "widgets/action_button.dart";
part "widgets/gauge_bar.dart";

/// One button of the [StateMessageView] action stack.
@immutable
final class StateMessageAction {
  /// Visible button text, already localised by the host.
  final String label;

  /// Called once per tap.
  final VoidCallback onPressed;

  /// Optional leading icon (size 18) next to [label].
  final IconData? icon;

  const StateMessageAction({
    required this.label,
    required this.onPressed,
    this.icon,
  });
}

/// Capacity / limit gauge shown by [StateMessageView] above its actions.
@immutable
final class StateMessageGauge {
  /// Fill ratio; clamped to `0..1` by the view.
  final double value;

  /// Caption above the left end of the bar (`cs.onSurfaceVariant`); also the
  /// semantics label of the gauge node.
  final String leftCaption;

  /// Caption above the right end of the bar, in the tone foreground, w600;
  /// also the semantics value of the gauge node (always announced, unlike a
  /// hint), so put the status here.
  final String rightCaption;

  const StateMessageGauge({
    required this.value,
    required this.leftCaption,
    required this.rightCaption,
  });
}

/// Centred, full-area state message (error, empty, prerequisite missing,
/// blocked).
///
/// Renders, top to bottom:
/// - a 64 dp circle filled with the [tone] `container` colour, holding [icon]
///   (32 dp, tone `foreground`). [icon] defaults to `tone.icon`, so the tone
///   is never conveyed by colour alone. The badge is decorative and excluded
///   from semantics.
/// - [title] (`textTheme.titleMedium`, w700, `cs.onSurface`, centred,
///   announced as a header) and the optional [message]
///   (`textTheme.bodyMedium`, `cs.onSurfaceVariant`, centred; hidden when null
///   or empty). Both sit in a `liveRegion` so a state change is announced.
/// - when a [gauge] or an action exists, a [kSectionGap] then a column at
///   most [actionsMaxWidth] wide holding the [gauge] (track
///   `cs.surfaceContainerHighest`, radius 999, fill = tone `foreground`;
///   captions and bar form one semantics node, label = `leftCaption`,
///   value = `rightCaption`), the [primaryAction] ([FilledButton]) and the
///   [secondaryAction] ([OutlinedButton]) 8 dp below it. Buttons stretch to the column width
///   and are at least [kMinTapTarget] tall.
///
/// The content scrolls when the available height is too short. All strings
/// are parameters, already localised by the host; the host maps its own
/// error / state codes to an icon, tone, texts and actions. No `Overlay`
/// ancestor is needed.
final class StateMessageView extends StatelessWidget with _ViewMixin {
  /// Badge icon; null → `tone.icon`.
  final IconData? icon;

  /// Main line, centred.
  final String title;

  /// Secondary text under [title]; hidden when null or empty.
  final String? message;

  /// Colour role of the badge and of the gauge.
  final StatusTone tone;

  /// Optional gauge above the actions.
  final StateMessageGauge? gauge;

  /// Filled button, first in the stack.
  final StateMessageAction? primaryAction;

  /// Outlined button, under [primaryAction].
  final StateMessageAction? secondaryAction;

  /// Maximum width of the gauge + actions column.
  final double actionsMaxWidth;

  const StateMessageView({
    super.key,
    required this.title,
    this.icon,
    this.message,
    this.tone = StatusTone.neutral,
    this.gauge,
    this.primaryAction,
    this.secondaryAction,
    this.actionsMaxWidth = 320,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

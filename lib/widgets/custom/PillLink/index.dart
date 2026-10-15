// index.dart
//
// PillLink — compact inline call-to-action shaped like a pill: optional
// leading icon, a one-line label and a trailing forward arrow. It sits next
// to a value, header or badge and points to more detail; the host decides
// what a tap does through [PillLink.onPressed]. The tree lives in view.dart.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "view.dart";

/// Visual density of a [PillLink].
///
/// - [standard]: 28 dp pill, 14 dp icon, 11 sp label.
/// - [compact]: 24 dp pill, 12 dp icon, 10 sp label.
///
/// Both keep a hit area of at least [kMinTapTarget] (48 × 48).
enum PillLinkSize { standard, compact }

/// Pill-shaped inline call-to-action: optional [icon] + [label] + a trailing
/// forward arrow (`Icons.arrow_forward_rounded`, mirrored in RTL).
///
/// - Colours: `cs.primary` for the icon and label, `cs.primary` at 8 % for
///   the fill, 20 % for the 1 dp border and 60 % for the arrow. Radius 999.
/// - The label is `textTheme.labelSmall`, w700, one line with an ellipsis
///   when the parent is too narrow.
/// - The drawn pill keeps its [size] height (28 / 24 dp) but its hit area and
///   layout box are at least [kMinTapTarget] (48 × 48) on every platform,
///   desktop included. Focus, hover, the click cursor and keyboard
///   activation come from the underlying [TextButton]; no `Material` or
///   `Overlay` ancestor is needed.
///
/// Accessibility: one button node labelled [semanticsLabel] (falls back to
/// the visible label); the icons are not read.
///
/// The widget never navigates: [onPressed] does (e.g. `context.go(...)` or
/// `ModalProvider.show(...)` in the host).
final class PillLink extends StatelessWidget with _ViewMixin {
  /// Called on tap. The host decides what happens.
  final VoidCallback onPressed;

  /// Visible text, already localised by the host. Null shows the built-in
  /// `"custom.pill_link.learn_more"` label.
  final String? label;

  /// Leading icon in `cs.primary`. Defaults to a lightbulb; null hides it.
  final IconData? icon;

  /// Visual density.
  final PillLinkSize size;

  /// Screen-reader label. Falls back to the visible label. Use it to make a
  /// vague label such as "Learn more" clear out of context (WCAG 2.4.4).
  final String? semanticsLabel;

  const PillLink({
    super.key,
    required this.onPressed,
    this.label,
    this.icon = Icons.lightbulb_outline_rounded,
    this.size = PillLinkSize.standard,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

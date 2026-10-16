// index.dart
//
// FollowUpPageTemplate — layout for follow-up screens: pages reached after a
// primary action that show its detail or outcome and the next steps. A
// PageTitleBar with a back button on top, a padded scrolling body centred
// at kContentMaxWidth, and an optional action bar pinned at the bottom.
//
// The body IS wrapped in a scroll view: never pass a Listing here (use
// FullPageTemplate, which leaves the body unscrolled).

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/layout/PageTitleBar/index.dart";

part "view.dart";

/// Layout template for follow-up pages.
///
/// - The title bar always has a back button calling [onBack]: a follow-up
///   page always leads back to where the action started.
/// - [child] scrolls, with 16 dp padding, centred and capped at
///   [kContentMaxWidth].
/// - [actions] (the next steps: "Continue", "Done", "Open"…) stays visible
///   at the bottom, above a 1 dp border, outside the scroll view and the
///   system bottom inset. Hidden when null.
final class FollowUpPageTemplate extends StatelessWidget with _ViewMixin {
  /// Title shown in the PageTitleBar.
  final String title;

  /// Called by the back button.
  final VoidCallback onBack;

  /// Page body; scrolls when taller than the page.
  final Widget child;

  /// Next-step actions pinned at the bottom (usually a Row or Wrap of buttons).
  final Widget? actions;

  /// Optional action shown at the end of the title bar.
  final Widget? trailing;

  const FollowUpPageTemplate({
    super.key,
    required this.title,
    required this.onBack,
    required this.child,
    this.actions,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

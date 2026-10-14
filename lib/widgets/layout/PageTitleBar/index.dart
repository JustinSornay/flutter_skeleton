// index.dart
//
// PageTitleBar — a 56 px page-level title bar for secondary pages and panels.
//
// Renders a title with optional leading (e.g. back button) and trailing
// (e.g. action button) slots.
//
// Related:
//   AppHeader         — primary navigation bar at app-shell level
//   FullPageTemplate  — places a PageTitleBar above every full page

import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "view.dart";

/// Page-level title bar with a title and optional leading/trailing slots.
final class PageTitleBar extends StatelessWidget with _ViewMixin {
  /// The page title.
  final String title;

  /// Optional leading widget (e.g. a back [IconButton]) anchored to the left.
  final Widget? leading;

  /// Optional trailing widget (e.g. an [IconButton]) anchored to the right.
  final Widget? trailing;

  const PageTitleBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

// index.dart
//
// FullPageTemplate — layout for screens that occupy the whole content area
// below AppHeader: a PageTitleBar on top, then the page body centred and
// capped at kContentMaxWidth.
//
// The body receives bounded constraints and is NOT wrapped in a scroll view,
// so a Listing can be passed directly. Scrollable bodies bring their own
// SingleChildScrollView / ListView.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/layout/PageTitleBar/index.dart";

part "view.dart";

/// Layout template for full-width single-panel pages.
final class FullPageTemplate extends StatelessWidget with _ViewMixin {
  /// Title shown in the PageTitleBar.
  final String title;

  /// Page body.
  final Widget child;

  /// When set, a back button is shown in the title bar and calls it.
  final VoidCallback? onBack;

  /// Optional action shown at the end of the title bar.
  final Widget? trailing;

  const FullPageTemplate({
    super.key,
    required this.title,
    required this.child,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

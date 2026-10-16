// index.dart
//
// SplittedPageTemplate — layout for screens with two panels: a PageTitleBar
// on top, then a primary panel (detail, form, list) next to a secondary
// panel (map, preview, supplementary view). Side by side when the page is
// wide enough, stacked otherwise.
//
// Both panels receive bounded constraints and are NOT wrapped in a scroll
// view, so a Listing or a map can be passed directly. Scrollable panels
// bring their own SingleChildScrollView / ListView.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/layout/PageTitleBar/index.dart";

part "view.dart";

/// Width from which the panels sit side by side (Material "expanded"
/// window class). Measured on the template itself, not the screen.
const double kSplitBreakpoint = 840;

/// Layout template for two-panel pages.
///
/// - At least [kSplitBreakpoint] wide: [primary] at the start side, [primaryWidth]
///   wide, a 1 dp divider, then [secondary] filling the rest.
/// - Narrower: [primary] above [secondary], each taking half the height.
///
/// The start side follows the text direction (right in RTL).
final class SplittedPageTemplate extends StatelessWidget with _ViewMixin {
  /// Title shown in the PageTitleBar.
  final String title;

  /// Main panel: detail, form or list.
  final Widget primary;

  /// Supporting panel: map, preview or supplementary view.
  final Widget secondary;

  /// When set, a back button is shown in the title bar and calls it.
  final VoidCallback? onBack;

  /// Optional action shown at the end of the title bar.
  final Widget? trailing;

  /// Width of [primary] in the side-by-side layout.
  final double primaryWidth;

  const SplittedPageTemplate({
    super.key,
    required this.title,
    required this.primary,
    required this.secondary,
    this.onBack,
    this.trailing,
    this.primaryWidth = 400,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

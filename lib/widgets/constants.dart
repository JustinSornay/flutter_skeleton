// constants.dart
//
// Shared layout and motion constants for the widget layer.
// Import this file wherever a consistent spacing value or animation duration
// is needed instead of scattering magic numbers across widget files.

import "package:flutter/widgets.dart";

/// Default padding applied to widget interiors and between sibling elements.
///
/// Baseline unit of the 8 dp spacing grid. Prefer multiples of this value
/// (e.g. 2×, 3×) rather than introducing arbitrary pixel counts.
const double kDefaultPadding = 8;

/// Vertical gap between major sections in a page.
const double kSectionGap = 24;

/// Maximum width for centred page content on wide viewports.
const double kContentMaxWidth = 800;

/// Minimum interactive target size (WCAG 2.5.8).
const double kMinTapTarget = 48;

/// Duration for small UI transitions (banners, toasts, chips).
const Duration kMotionShort = Duration(milliseconds: 250);

/// Returns [duration], or [Duration.zero] when the user asked the platform
/// to reduce motion. Every animation in the app goes through this helper.
Duration resolveMotion(BuildContext context, Duration duration) {
  return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

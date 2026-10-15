// index.dart
//
// SkeletonBlock — rounded placeholder rectangle for loading skeletons (boxes,
// text lines, pills, avatars, media banners). It is static: wrap it in
// SkeletonPulse (widgets/core/decorators/) for the loading pulse.
//
// Related: view.dart renders the filled Container.

import "package:flutter/material.dart";

part "view.dart";

/// A rectangular placeholder block used in skeleton layouts.
///
/// - Fill: `cs.surfaceContainerHighest`, in light and dark themes.
/// - Does not animate on its own: wrap it (or a group of blocks) in
///   `SkeletonPulse` when a loading pulse is wanted.
/// - Decorative: no text and no semantics node. The loading announcement
///   belongs to the host screen.
///
/// No `Overlay` ancestor is needed.
final class SkeletonBlock extends StatelessWidget with _ViewMixin {
  /// Width in logical pixels. null = sized by the parent constraints
  /// (e.g. the cross axis of a stretched Column, or an Expanded).
  final double? width;

  /// Height in logical pixels.
  final double height;

  /// Corner radius. 8 (default) for boxes and cards, 4 for text lines,
  /// 999 for pills, 0 for edge-to-edge media.
  final double borderRadius;

  const SkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) => render(context, this);
}

// index.dart
//
// SectionBlock — numbered section container for long-form or step-by-step
// pages: a circular index badge next to a title and an optional caption, with
// any content widget placed below. Stateless; the tree lives in view.dart.

import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "view.dart";

/// Numbered section: a circular index badge, a title, an optional caption
/// and a content [child] rendered beneath the header row.
///
/// Layout:
/// - The badge is filled with `cs.primary`; its [indexLabel] is w800 in
///   `cs.onPrimary`. Its minimum diameter is 30 dp scaled by the ambient
///   text scaler (30 dp at the default scale), so a one- or two-character
///   label stays a circle at any text scale. A longer label widens it into
///   a stadium instead of being clipped.
/// - A 12 dp gap separates the badge from the title column.
/// - The title uses `titleLarge` w800 in `cs.onSurface`; the caption, 4 dp
///   below it, uses `bodyMedium` in `cs.onSurfaceVariant` with height 1.5.
/// - [child] sits 16 dp below the header row.
///
/// Accessibility: the badge is decorative and excluded from semantics; the
/// title is exposed as a single header node labelled `"<indexLabel>. <title>"`.
/// The caption and [child] keep their own semantics.
///
/// The title column sits in an [Expanded]: the block needs a bounded width.
/// No overlay is used, so the widget works anywhere in the tree.
///
/// Every string is content, already localised by the host.
final class SectionBlock extends StatelessWidget with _ViewMixin {
  /// Short text rendered inside the circular badge (e.g. "1", "A", "10").
  /// Must not be empty: it also prefixes the header's semantics label.
  final String indexLabel;

  /// Section heading displayed next to the badge.
  final String title;

  /// Optional descriptive paragraph under the title; nothing is rendered
  /// when null.
  final String? caption;

  /// Main section content rendered beneath the header row.
  final Widget child;

  const SectionBlock({
    super.key,
    required this.indexLabel,
    required this.title,
    this.caption,
    required this.child,
  }) : assert(indexLabel != "", "SectionBlock.indexLabel must not be empty");

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

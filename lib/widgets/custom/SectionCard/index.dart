// index.dart
//
// SectionCard — titled card that groups related rows (preferences, account
// details, usage or feature lines…) under one bordered, rounded panel.
// Stateless; the tree lives in view.dart.

import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "view.dart";

/// Bordered, rounded card with a section label, a hairline divider and the
/// caller's rows running edge to edge.
///
/// Layout:
/// - Full available width (`width: double.infinity`), so the card needs a
///   bounded width; its height hugs the content.
/// - Panel: `cs.surfaceContainerLow`, a 1 dp `cs.outlineVariant` border and
///   radius 12, clipped with [Clip.antiAlias]. The border is painted in the
///   foreground, above the rows, so a filled or pressed last row never covers
///   its rounded corners.
/// - [title] in `labelSmall` w600, letter-spacing 1.4, `cs.onSurfaceVariant`,
///   padded 16 / 16 / 16 / 12 dp, then a 1 dp [Divider] coloured by the
///   theme's `dividerTheme`.
/// - [children] follow the divider at full width (inside the 1 dp border)
///   with no extra padding.
///
/// Rows are hosted on a transparent [Material] inside the clipped panel, so
/// the ink ripples of [InkWell] / [ListTile] rows are painted above the panel
/// colour and stay inside the rounded corners.
///
/// Accessibility: the title is a semantic header, so screen readers can jump
/// from section to section. Rows keep their own semantics.
///
/// No overlay is used, so the widget works anywhere in the tree. The title is
/// content, already localised by the host; the card has no chrome strings.
final class SectionCard extends StatelessWidget with _ViewMixin {
  /// Section label shown above the divider, rendered verbatim (pass a
  /// translated string; uppercase it yourself for an overline look).
  final String title;

  /// Rows rendered under the divider, full width. Each row owns its padding;
  /// add `Divider(height: 1)` between rows when separators are wanted.
  final List<Widget> children;

  const SectionCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

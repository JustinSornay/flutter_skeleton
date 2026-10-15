// index.dart
//
// MetricLabel — muted label row in capital letters with an optional leading
// icon, used as the header of metric / stat displays (tiles, bars, gauges) so
// label typography stays identical across every value visualisation. The tree
// lives in view.dart.

import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "view.dart";

/// Header row of a metric display: optional leading [icon] + [label] in
/// upper case.
///
/// - The icon is 12 dp, followed by a 4 dp gap (`kDefaultPadding / 2`).
/// - The label is shown upper-cased, 10 / w600, letter spacing 0.5, and
///   wraps when the parent is too narrow.
/// - Icon and label use `cs.onSurfaceVariant`.
///
/// Accessibility: the row exposes one semantics node labelled with [label]
/// in its original casing, so screen readers do not spell the upper-cased
/// text letter by letter. The icon is decorative and not announced.
///
/// The label sits in an [Expanded]: the row needs a bounded width.
///
/// [label] is content, already localised by the host.
final class MetricLabel extends StatelessWidget with _ViewMixin {
  /// Text to display; rendered in upper case. Screen readers get the
  /// original casing.
  final String label;

  /// Optional leading icon, 12 dp, tinted `cs.onSurfaceVariant`.
  final IconData? icon;

  const MetricLabel({
    super.key,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

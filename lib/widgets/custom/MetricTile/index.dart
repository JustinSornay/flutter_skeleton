// index.dart
//
// MetricTile — compact, read-only stat tile: a MetricLabel header (upper-case
// label, optional icon), a prominent pre-formatted value with an optional
// smaller unit, and an optional caption line. Value and caption can each be
// tinted with a StatusTone; a value tone also draws its StatusTone.icon. Base
// tile of stat strips and before / after panels. The tree lives in view.dart
// and widgets/value_line.dart.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/MetricLabel/index.dart";

part "view.dart";
part "widgets/value_line.dart";

/// Read-only stat tile: [label], [value] (+ [unit]) and an optional
/// [caption] (a change, a status, a note…).
///
/// - Container: radius 10, padding 12 × 8 dp (`kDefaultPadding * 1.5` ×
///   [kDefaultPadding]). Fill `cs.surfaceContainerHigh`; when [outlined],
///   fill `cs.surfaceContainerHighest` with a 1 dp `cs.outlineVariant` border.
/// - Header: [MetricLabel] (upper-case 10 / w600 label, optional 12 dp
///   [icon], both `cs.onSurfaceVariant`).
/// - Value: 16 / w700, up to [maxLines] lines (one by default) with an
///   ellipsis, `cs.onSurface`, or the [valueTone] foreground. A null or empty
///   [value] shows a muted "—" and is announced as
///   `custom.metric_tile.no_value`.
/// - Value tone icon: when [valueTone] is set and not `neutral`, its
///   [StatusTone.icon] (12 dp, same foreground) sits 4 dp before the value,
///   so the status is not shown by colour alone. No icon with the "—"
///   placeholder.
/// - Unit: 11 / w500 `cs.onSurfaceVariant`, 2 dp after the value, on the
///   baseline of the value's first line. It stays visible when the value is
///   ellipsized and is hidden with the "—" placeholder. Keep units short: a
///   unit is capped at 48 dp and ellipsized beyond, so the value line never
///   overflows a tile 92 dp wide or more.
/// - Caption: 10 sp, up to [maxLines] lines (one by default) with an
///   ellipsis, coloured with the [captionTone] foreground (`neutral` =
///   `cs.onSurfaceVariant`); w700 when the tone is not `neutral`, w400
///   otherwise. Hidden when null or empty.
///
/// Sizing: the tile fills a tight width (grid cell, `Expanded`, stretched
/// column) and shrink-wraps its content otherwise (`Wrap`, `Row` without
/// `Expanded`, horizontal scroll); a long label then wraps under a bounded
/// width, and so do the value and the caption when [maxLines] allows it.
///
/// The tile formats nothing and judges nothing: the host passes localised,
/// formatted text and maps its own scale or comparison to a [StatusTone]
/// (for instance `score >= 0.6 ? StatusTone.success : StatusTone.warning`).
/// The caption is text and the value tone draws its icon, so neither relies
/// on colour alone on screen. Screen readers hear neither the tint nor the
/// icon: when [valueTone] encodes a status, name it in [caption] or
/// [semanticsLabel].
///
/// Accessibility: one semantics node labelled [semanticsLabel], by default
/// "label, value unit, caption" with the label in its original casing.
///
/// No tooltip, so no `Overlay` ancestor is needed.
final class MetricTile extends StatelessWidget with _ViewMixin {
  /// Metric name, already localised. Shown upper-cased; announced as given.
  final String label;

  /// Formatted value, already localised (e.g. "32", "Good", "650 ms").
  /// Null or empty → "—".
  final String? value;

  /// Short unit shown smaller after [value] (e.g. "ms", "/100"); capped at
  /// 48 dp with an ellipsis. Ignored without a value.
  final String? unit;

  /// Optional 12 dp leading icon of the label row; decorative.
  final IconData? icon;

  /// Tint of the value text (tone foreground). Null → `cs.onSurface`. Any
  /// tone but `neutral` also draws [StatusTone.icon] before the value; the
  /// icon is not announced, so name the status in [caption] or
  /// [semanticsLabel].
  final StatusTone? valueTone;

  /// Secondary line under the value (a change, a status, a note…). Hidden
  /// when null or empty.
  final String? caption;

  /// Tint of [caption] (tone foreground); `neutral` is `cs.onSurfaceVariant`.
  final StatusTone captionTone;

  /// Bordered variant on `cs.surfaceContainerHighest`, for strips of tiles
  /// laid on a `cs.surfaceContainerHigh` background.
  final bool outlined;

  /// Screen-reader label. Null or empty → "label, value unit, caption".
  final String? semanticsLabel;

  /// Line limit of the value and of the caption, ellipsized beyond. Null →
  /// no limit (they wrap freely under a bounded width). Must be positive.
  final int? maxLines;

  const MetricTile({
    super.key,
    required this.label,
    this.value,
    this.unit,
    this.icon,
    this.valueTone,
    this.caption,
    this.captionTone = StatusTone.neutral,
    this.outlined = false,
    this.semanticsLabel,
    this.maxLines = 1,
  }) : assert(maxLines == null || maxLines > 0);

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

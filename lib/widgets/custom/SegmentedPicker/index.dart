// index.dart
//
// SegmentedPicker<T> — single-select segmented track for a small set of
// ChoiceOption<T> (custom/_base): equal-width segments with a label and an
// optional second line, an elevated pill outlined in cs.primary behind the
// selected one, and optional locked segments that report taps through
// onLockedTap. The widget owns no state. The track lives in view.dart, one segment in
// widgets/segment.dart.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/_base/choice_option.dart";

part "view.dart";
part "widgets/segment.dart";

/// Single-select segmented track with an optional caption above it.
///
/// Layout: a start-aligned `Column` holding, when [label] is set, the caption
/// (`textTheme.labelSmall`, 9 / w700, letter spacing 1.2,
/// `cs.onSurfaceVariant`, upper-cased) and a [kDefaultPadding] gap, then the
/// track: a `cs.surfaceContainerHighest` [Material] (radius 8, padding
/// `kDefaultPadding / 2`) holding one equal-width segment per option, left to
/// right. Every segment is at least [kMinTapTarget] (48 dp) tall; its width is
/// the track width divided by the number of options, so keep the list short.
///
/// Segments render these [ChoiceOption] fields:
/// - `label`: the main line (12 / w700), single line, ellipsized;
/// - `description`: an optional second line (9 / w600, same colour as the
///   label), single line, ellipsized; omitted when null;
/// - `enabled`: `false` dims the segment (35 % opacity) and ignores taps;
/// - `semanticsLabel`: the spoken label, which defaults to
///   "label, description".
///
/// `icon` and `trailing` are not rendered.
///
/// A segment is **locked** when its option is enabled but [enabledValues] is
/// non-null and does not contain its value: it is dimmed (35 % opacity),
/// shows [lockedIcon] in its top-end corner (top-right in left-to-right
/// layouts), with the text kept clear of it, and reports taps through
/// [onLockedTap]. Locked and disabled segments expose the
/// `custom.segmented_picker.unavailable` hint to screen readers.
///
/// Colours come from the `ColorScheme` only. The selected segment gets a
/// `cs.surface` pill outlined in `cs.primary` (1.5 dp) with a soft
/// `cs.shadow` drop shadow and `cs.primary` text; the other segments are
/// transparent, with a transparent outline of the same width and
/// `cs.onSurfaceVariant` text. The selection does not rely on a fill or hue
/// change: the outline only appears around the selected segment and contrasts
/// at least 3:1 with the track in both `AppTheme` brightnesses, and each
/// segment reports `selected` to screen readers inside a mutually exclusive
/// group. The pill fades in over `resolveMotion(context, 160 ms)`, instantly
/// under reduced motion.
///
/// No overlay is used, and the track provides its own [Material] for ink:
/// the picker works anywhere, including `Layout`.
///
/// Content strings ([label], option texts) are already localised by the host.
final class SegmentedPicker<T> extends StatelessWidget with _ViewMixin<T> {
  const SegmentedPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.label,
    this.enabledValues,
    this.lockedIcon = Icons.lock_outline_rounded,
    this.onLockedTap,
  });

  /// Segments, rendered left to right with equal widths. Must not be empty
  /// (asserted when the picker builds, so the constructor stays const).
  final List<ChoiceOption<T>> options;

  /// Currently selected value, compared with `==` to each option's `value`.
  /// Null highlights no segment (the user has not picked yet).
  final T? selected;

  /// Called with the option's `value` when a selectable segment is tapped,
  /// including the one already selected (the host ignores repeats).
  final ValueChanged<T> onSelected;

  /// Optional caption above the track, already localised; drawn upper-cased.
  final String? label;

  /// When non-null, only these values are selectable and the other enabled
  /// options are locked. Null means no segment is locked.
  final Set<T>? enabledValues;

  /// Icon (11 dp) pinned to the top-end corner of locked segments. Null
  /// draws no icon (for example when a missing value means "no data").
  final IconData? lockedIcon;

  /// Called with the option's `value` when a locked segment is tapped (for
  /// example to explain why it is locked). Null makes locked segments inert.
  final ValueChanged<T>? onLockedTap;

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

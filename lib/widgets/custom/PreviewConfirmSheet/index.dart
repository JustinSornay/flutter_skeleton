// index.dart
//
// PreviewConfirmSheet — content for a modal or bottom sheet that previews one
// item before the user commits to an action: a hero image (or an icon
// placeholder), a title, an optional subtitle, a wrap of stat pills
// (composed StatusPill / PillBadge), a full-width confirm button and an
// optional cancel button. The tree lives in view.dart, the image header and
// the stat badge in widgets/. Value class: PreviewStat.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/PillBadge/index.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";

part "view.dart";
part "widgets/image_header.dart";
part "widgets/stat_badge.dart";

/// One stat of a [PreviewConfirmSheet]: a small caption ([label]) above a
/// pill showing [value].
///
/// - `tinted: false` (default): an outlined [PillBadge]. With a [tone], the
///   pill starts with a dot and its text uses the tone `foreground`; without
///   one, it is a plain neutral pill.
/// - `tinted: true`: a [StatusPill] filled with the tone `container`, with
///   the tone icon ([StatusTone.icon]) before the text. A null [tone] counts
///   as [StatusTone.neutral].
///
/// The label and the value are always visible, so a tone is never conveyed
/// by colour alone; a host that needs the meaning of the tone in words adds
/// it to [value] (e.g. "0.72 · Good").
@immutable
final class PreviewStat {
  /// Caption above the pill, already localised. Always shown.
  final String label;

  /// Preformatted value shown in the pill (the host formats numbers).
  final String value;

  /// Colour coding. Null → no colour coding.
  final StatusTone? tone;

  /// Draws a tone-filled [StatusPill] instead of an outlined [PillBadge].
  final bool tinted;

  /// Screen-reader label of the whole stat. Null or empty → "label: value".
  final String? semanticsLabel;

  const PreviewStat({
    required this.label,
    required this.value,
    this.tone,
    this.tinted = false,
    this.semanticsLabel,
  });

  /// Signed change, always [tinted].
  ///
  /// - `|delta| < epsilon` → value "=", tone [StatusTone.neutral].
  /// - otherwise → "+x.xx" or "-x.xx" with [fractionDigits] decimals, tone
  ///   [StatusTone.success] when the change is good and [StatusTone.danger]
  ///   when it is bad. A change is good when `delta > 0` and
  ///   [higherIsBetter], or `delta < 0` and not [higherIsBetter]; the sign
  ///   never flips.
  ///
  /// Keep [epsilon] at least half a unit of the last shown decimal, or a tiny
  /// change can render as "+0.00".
  factory PreviewStat.delta({
    required String label,
    required double delta,
    bool higherIsBetter = true,
    int fractionDigits = 2,
    double epsilon = 0.005,
    String? semanticsLabel,
  }) {
    if (delta.abs() < epsilon) {
      return PreviewStat(
        label: label,
        value: "=",
        tone: StatusTone.neutral,
        tinted: true,
        semanticsLabel: semanticsLabel,
      );
    }
    final bool isGood = higherIsBetter ? delta > 0 : delta < 0;
    final String sign = delta > 0 ? "+" : "";
    return PreviewStat(
      label: label,
      value: "$sign${delta.toStringAsFixed(fractionDigits)}",
      tone: isGood ? StatusTone.success : StatusTone.danger,
      tinted: true,
      semanticsLabel: semanticsLabel,
    );
  }
}

/// Confirmation content previewing one item before the user commits to an
/// action, hosted in a modal bottom sheet or an `AppModal`.
///
/// Renders, top to bottom, in a [SingleChildScrollView]:
/// - a full-width header: [image] at 180 dp (`BoxFit.cover`), or a 120 dp
///   `cs.surfaceContainerHighest` placeholder with [placeholderIcon] (48 dp,
///   `cs.onSurfaceVariant`) when [image] is null. An image that fails to load
///   shows the same placeholder at 180 dp. The image is announced with
///   [imageSemanticLabel], and excluded from semantics when it is null or
///   empty; the placeholder is always decorative.
/// - [title] (20 sp, w800, `cs.onSurface`, header semantics).
/// - [subtitle] (13 sp, `cs.onSurfaceVariant`, italic when
///   [italicSubtitle]), hidden when null or empty.
/// - [stats] in a [Wrap] (8 dp spacing, so long labels flow onto several
///   runs): each is a caption above a composed [PillBadge] or [StatusPill]
///   (see [PreviewStat]), read as one semantics node.
/// - a full-width [FilledButton] (at least [kMinTapTarget] tall) calling
///   [onConfirm], labelled [confirmLabel] (null or empty →
///   `custom.preview_confirm_sheet.confirm`).
/// - when [onCancel] is non-null, a full-width [TextButton] below it,
///   labelled [cancelLabel] (null or empty →
///   `custom.preview_confirm_sheet.cancel`).
///
/// Content only: no drag handle, no background, and it never touches the
/// Navigator. The host mounts it with
/// `showModalBottomSheet(showDragHandle: true, …)` or
/// `ModalProvider.show(AppModal(...))` and closes it itself in [onConfirm]
/// and [onCancel] (e.g. `Navigator.of(sheetContext).pop()` or
/// `modalProvider.dismiss()`).
///
/// Needs neither a `Material` nor an `Overlay` ancestor: the buttons bring
/// their own `Material` and nothing opens a tooltip or a popup. Content
/// strings are parameters, already localised by the host.
final class PreviewConfirmSheet extends StatelessWidget with _ViewMixin {
  /// Item name, already localised.
  final String title;

  /// Secondary line under [title]. Hidden when null or empty.
  final String? subtitle;

  /// Draws [subtitle] in italics (e.g. for a formal or alternate name).
  final bool italicSubtitle;

  /// Hero image (network, asset or memory). Null → icon placeholder.
  final ImageProvider? image;

  /// Icon of the placeholder shown when [image] is null or fails to load.
  final IconData placeholderIcon;

  /// Screen-reader description of [image]. Null or empty → the image is
  /// excluded from semantics.
  final String? imageSemanticLabel;

  /// Stat pills, in display order.
  final List<PreviewStat> stats;

  /// Confirm button text. Null or empty → `custom.preview_confirm_sheet.confirm`.
  final String? confirmLabel;

  /// Called once per confirm tap. The host closes the sheet here.
  final VoidCallback onConfirm;

  /// Cancel button text. Null or empty → `custom.preview_confirm_sheet.cancel`.
  final String? cancelLabel;

  /// Called once per cancel tap. Null → no cancel button (the host's own
  /// dismissal, such as a swipe or a scrim tap, still applies).
  final VoidCallback? onCancel;

  const PreviewConfirmSheet({
    super.key,
    required this.title,
    required this.onConfirm,
    this.subtitle,
    this.italicSubtitle = false,
    this.image,
    this.placeholderIcon = Icons.image_outlined,
    this.imageSemanticLabel,
    this.stats = const <PreviewStat>[],
    this.confirmLabel,
    this.cancelLabel,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

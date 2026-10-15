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

/// One stat of a [PreviewConfirmSheet]: a small [label] above a pill
/// showing [value], followed by " · [caption]" when [caption] is set.
///
/// - `tinted: false` (default): an outlined [PillBadge]. With a [tone], the
///   pill starts with a dot and its text uses the tone `foreground`; without
///   one, it is a plain neutral pill.
/// - `tinted: true`: a [StatusPill] filled with the tone `container`. A
///   non-neutral tone adds its icon ([StatusTone.icon]) before the text. A
///   null [tone] counts as [StatusTone.neutral], which carries no status and
///   so shows no icon.
///
/// The dot is the same glyph for every tone, and screen readers hear only
/// the text ("label: value", plus ", caption" when there is one), never the
/// tone. So whenever the tone carries meaning, the host must also give it in
/// words: a [caption] (shown and announced) or a [semanticsLabel].
@immutable
final class PreviewStat {
  /// Small text above the pill, already localised. Always shown.
  final String label;

  /// Preformatted value shown in the pill. The host formats numbers for the
  /// app locale (intl `NumberFormat` with `context.locale.toLanguageTag()`),
  /// so "0,72" in French. A [PreviewStat.delta] stat is formatted by the
  /// widget instead: see there.
  final String value;

  /// Colour coding. Null → no colour coding.
  final StatusTone? tone;

  /// Draws a tone-filled [StatusPill] instead of an outlined [PillBadge].
  final bool tinted;

  /// Words for the [tone] (e.g. "Good", "Worse"), already localised. Shown
  /// after [value] in the pill ("value · caption") and appended to the
  /// default semantics label. Null or empty → nothing is added. Give one (or
  /// a [semanticsLabel]) whenever the tone carries meaning, so colour is
  /// never the only signal.
  ///
  /// Keep it to a short word or two: it shares the pill's single line with
  /// [value], and when the sheet is narrow or the text scale large, the end
  /// of that line is ellipsized (the semantics label keeps it whole).
  final String? caption;

  /// Screen-reader label of the whole stat. Null or empty → "label: value",
  /// or "label: value, caption" when there is a [caption].
  final String? semanticsLabel;

  /// Signed change of a [PreviewStat.delta] stat, formatted by the view for
  /// the ambient locale. Null for every other stat (and for "=").
  final double? _delta;

  /// Decimals of [_delta].
  final int _fractionDigits;

  const PreviewStat({
    required this.label,
    required this.value,
    this.tone,
    this.tinted = false,
    this.caption,
    this.semanticsLabel,
  }) : _delta = null,
       _fractionDigits = 0;

  /// Tinted stat of a non-zero [PreviewStat.delta].
  const PreviewStat._change({
    required this.label,
    required this.value,
    required this.tone,
    required double delta,
    required int fractionDigits,
    this.caption,
    this.semanticsLabel,
  }) : tinted = true,
       _delta = delta,
       _fractionDigits = fractionDigits;

  /// Signed change, always [tinted].
  ///
  /// - `|delta| < epsilon` → value "=", tone [StatusTone.neutral].
  /// - otherwise → the change with [fractionDigits] decimals and an explicit
  ///   sign, tone [StatusTone.success] when the change is good and
  ///   [StatusTone.danger] when it is bad. A change is good when `delta > 0`
  ///   and [higherIsBetter], or `delta < 0` and not [higherIsBetter]; the
  ///   sign never flips.
  ///
  /// The pill and the default semantics label format the change with intl
  /// `NumberFormat.decimalPatternDigits` for the ambient locale
  /// (`Localizations.maybeLocaleOf`, so the app's `context.locale`): "+0.13"
  /// in English, "+0,13" in French, with the locale's grouping for large
  /// values. [value] keeps the locale-independent form ("+0.13": decimal
  /// point, no grouping).
  ///
  /// [epsilon] must be positive, so that a zero change is always "=", and
  /// [fractionDigits] must be in 0..20 (the range of
  /// [num.toStringAsFixed]); both are asserted. Keep [epsilon] at least half
  /// a unit of the last shown decimal, or a tiny change can render as
  /// "+0.00".
  ///
  /// [caption] and [semanticsLabel] work as in the default constructor. The
  /// good / bad tone is not announced, so give the words for it (e.g.
  /// "Better" / "Worse") in one of them.
  factory PreviewStat.delta({
    required String label,
    required double delta,
    bool higherIsBetter = true,
    int fractionDigits = 2,
    double epsilon = 0.005,
    String? caption,
    String? semanticsLabel,
  }) {
    assert(epsilon > 0, "epsilon must be positive, so that a zero change is '='");
    assert(fractionDigits >= 0 && fractionDigits <= 20, "fractionDigits must be in 0..20");
    if (delta.abs() < epsilon) {
      return PreviewStat(
        label: label,
        value: "=",
        tone: StatusTone.neutral,
        tinted: true,
        caption: caption,
        semanticsLabel: semanticsLabel,
      );
    }
    final bool isGood = higherIsBetter ? delta > 0 : delta < 0;
    final String sign = delta > 0 ? "+" : "";
    return PreviewStat._change(
      label: label,
      value: "$sign${delta.toStringAsFixed(fractionDigits)}",
      tone: isGood ? StatusTone.success : StatusTone.danger,
      delta: delta,
      fractionDigits: fractionDigits,
      caption: caption,
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
///   runs): each is a label above a composed [PillBadge] or [StatusPill]
///   (see [PreviewStat]), read as one semantics node.
/// - a full-width [FilledButton] calling [onConfirm], labelled
///   [confirmLabel] (null or empty → `custom.preview_confirm_sheet.confirm`).
/// - when [onCancel] is non-null, a full-width [TextButton] below it,
///   labelled [cancelLabel] (null or empty →
///   `custom.preview_confirm_sheet.cancel`).
///
/// Both buttons are at least [kMinTapTarget] tall on every platform: they
/// use the standard visual density and a padded tap target, so the compact
/// desktop defaults do not shrink them to 40 dp.
///
/// Content only: no drag handle, no background, and it never touches the
/// Navigator. The host mounts it with
/// `showModalBottomSheet(showDragHandle: true, …)` or
/// `ModalProvider.show(AppModal(...))` and closes it itself in [onConfirm]
/// and [onCancel] (e.g. `Navigator.of(sheetContext).pop()` or
/// `modalProvider.dismiss()`).
///
/// It does not clip either, and the header image is full-width with square
/// corners. A host with rounded corners and no drag handle above the
/// content (`AppModal`, or a bottom sheet without `showDragHandle`) wraps it
/// in a `ClipRRect` with the host's radius (16 dp for `AppModal`), or the
/// image paints over those corners.
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

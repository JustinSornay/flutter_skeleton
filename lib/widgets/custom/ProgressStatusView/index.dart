// index.dart
//
// ProgressStatusView — centred, full-area determinate progress display for a
// long-running or polled background job: a ring with the percentage, the
// current step title and subtitle, a linear bar, an optional pill of short
// context facts and an optional Cancel button. The tree lives in view.dart;
// the pill is a private part in widgets/details_pill.dart.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/utils/formatters/intl_locale.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "view.dart";
part "widgets/details_pill.dart";

/// Determinate progress panel for a long-running background job (report
/// generation, export, import, batch processing…).
///
/// Renders, top to bottom, centred and at most [kContentMaxWidth] wide:
/// - a 96 dp ring (`CircularProgressIndicator`, stroke 6, track
///   `cs.surfaceContainerHighest`, fill `cs.primary`) with the percentage in
///   its centre (`textTheme.titleLarge`, w800, `cs.onSurface`). The
///   percentage is [progress] formatted by intl `NumberFormat.percentPattern`
///   for the ambient locale (`45%` in English, `45 %` in French). It stays on
///   one line and scales down (`FittedBox`) to fit inside the stroke at large
///   text scales.
/// - [title] (`textTheme.titleMedium`, w700, `cs.onSurface`) and the optional
///   [subtitle] (`textTheme.bodySmall`, `cs.onSurfaceVariant`; hidden when
///   null or empty), both centred.
/// - a full-width 6 dp bar (radius 999, same colours and value as the ring).
/// - when [details] has a non-empty entry, a pill (`cs.surfaceContainer`,
///   border `cs.outlineVariant`, radius 999) showing the non-empty entries
///   joined by ` · ` (`textTheme.labelSmall`, w500, `cs.onSurfaceVariant`).
/// - when [onCancel] is set, an [OutlinedButton] at least [kMinTapTarget]
///   square, labelled with the i18n key `custom.progress_status_view.cancel`.
///
/// [progress] is a fraction in `[0, 1]`; out-of-range values are clamped and
/// NaN renders as 0. The ring and the bar always show the same value. The
/// content scrolls when the available height is too short.
///
/// Accessibility: the ring is one semantics node labelled [title] whose
/// value is the locale-formatted percentage text; the bar and the centred
/// text are not read again. The title and subtitle sit in a `liveRegion`, so
/// a step change is announced, while percentage ticks are not.
///
/// Trade-off: that node replaces the indicators' own semantics, so it has no
/// `SemanticsRole.progressBar` role (on the web it is a labelled node, not an
/// ARIA progressbar). The role requires a bare numeric value in `[0, 100]`,
/// which would drop the localised `45 %` text; the other progress widgets in
/// `custom/` (LabeledProgressBar, QuotaBar, LevelProgressBar) make the same
/// choice.
///
/// Inert: the host decides the current step, formats [details] and handles
/// [onCancel] (e.g. navigates away). No animation and no overlay: it needs no
/// `Overlay` ancestor. Content strings are already localised by the host.
final class ProgressStatusView extends StatelessWidget with _ViewMixin {
  /// Completion fraction in `[0, 1]`; clamped, NaN → 0. Drives the ring, the
  /// bar and the centred percentage.
  final double progress;

  /// Headline of the current step (e.g. "Building the export…"); also the
  /// semantics label of the ring.
  final String title;

  /// Secondary line under [title]; hidden when null or empty.
  final String? subtitle;

  /// Short pre-formatted context facts shown in one pill, joined by ` · `.
  /// Empty entries are skipped, like an empty [subtitle]; the pill is hidden
  /// when no entry remains.
  final List<String> details;

  /// Cancel action. The button is hidden when null.
  final VoidCallback? onCancel;

  const ProgressStatusView({
    super.key,
    required this.progress,
    required this.title,
    this.subtitle,
    this.details = const <String>[],
    this.onCancel,
  });

  /// [value] clamped to `[0, 1]`; NaN → 0.
  static double _fraction(double value) {
    if (value.isNaN) return 0;
    return value.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

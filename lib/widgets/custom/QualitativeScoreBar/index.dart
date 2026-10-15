// index.dart
//
// QualitativeScoreBar — a normalised 0..1 score shown as a word plus a thin
// tone-coloured bar, never as a number. The host supplies the scale as
// ScoreLevel steps (score_level.dart, with the pure ScoreLevel.resolve);
// view.dart draws the label, the bar and the single semantics node.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "score_level.dart";
part "view.dart";

/// A normalised score shown as a word plus a bar, with no number on screen
/// or for screen readers.
///
/// - Level: [ScoreLevel.resolve] picks, from [levels], the step with the
///   greatest `min` that is `<=` [value] (clamped to `[0, 1]`), or the lowest
///   step when [value] is below every `min`. [levels] may be in any order.
/// - Label: the level's [ScoreLevel.label] in the tone foreground
///   (`StatusTones.colorsOf(context, tone).foreground`), `titleMedium` at
///   15 sp, w800. The word is always shown, so the level never relies on
///   colour alone.
/// - Bar: a determinate bar filled to the clamped [value], [kDefaultPadding]
///   below the label: track `cs.surfaceContainerHighest`, radius 999, fill =
///   the same tone foreground, 5 dp thick. It spans the available width, so
///   the parent must give it a bounded width.
/// - No data: when [value] is null (or NaN) the label is [noDataLabel]
///   (default `custom.qualitative_score_bar.no_data`), the tone is
///   [StatusTone.neutral] and the bar is empty. [levels] is not read then.
/// - Semantics: one node whose label is the level label, prefixed with
///   [semanticsLabel] through `custom.qualitative_score_bar.semantics_label`
///   when given. The bar's own percentage value is excluded.
///
/// Inert and overlay-free: no callbacks, no tooltip, no animation, so it
/// needs no `Overlay` ancestor. Content strings ([ScoreLevel.label],
/// [noDataLabel], [semanticsLabel]) are already localised by the host.
final class QualitativeScoreBar extends StatelessWidget with _ViewMixin {
  /// Normalised score in `[0, 1]`; values outside the range are clamped.
  /// Null (or NaN) means no data.
  final double? value;

  /// The scale, in any order. Must not be empty when [value] is not null
  /// ([ScoreLevel.resolve] throws an [ArgumentError] otherwise).
  final List<ScoreLevel> levels;

  /// Label of the no-data state. Null → `custom.qualitative_score_bar.no_data`.
  final String? noDataLabel;

  /// Context for screen readers, e.g. "Quality" → "Quality: Good". Null or
  /// empty → the level label alone.
  final String? semanticsLabel;

  const QualitativeScoreBar({
    super.key,
    required this.value,
    required this.levels,
    this.noDataLabel,
    this.semanticsLabel,
  });

  /// [value] clamped to `[0, 1]`, or null when it is null or NaN (no data).
  static double? _normalize(double? value) {
    if (value == null || value.isNaN) return null;
    return value.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

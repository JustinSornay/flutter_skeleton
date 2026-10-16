// index.dart
//
// WeightedScoreCard — an interactive "what-if" card for a weighted score.
// One slider per component sets its weight; the weights always add up to
// 100 % (moving one rebalances the others proportionally). After a debounce
// the host's evaluator returns the overall score and one score per component;
// the card shows the score on a toned "/ 100" ring, a donut of each
// component's share with a legend of the weights, and an alert chip under a
// threshold. Value classes live in values.dart, the pure weight maths and the
// colour cycle in controllers/, the state in view_model.dart, the tree in
// view.dart and its private pieces in widgets/.

import "dart:async";

import "package:easy_localization/easy_localization.dart";
import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/utils/formatters/intl_locale.dart";
import "package:flutter_skeleton/utils/load_state.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";

part "controllers/component_palette.dart";
part "controllers/weight_mix.dart";
part "values.dart";
part "view.dart";
part "view_model.dart";
part "widgets/alert_chip.dart";
part "widgets/score_ring.dart";
part "widgets/share_donut.dart";
part "widgets/weight_slider_row.dart";

/// Card that lets the user tune the weights of [components] and shows the
/// weighted score returned by [evaluate].
///
/// Renders, inside a `cs.surface` card (radius 12, `cs.outlineVariant`
/// border, padding `2 × kDefaultPadding`):
/// - a header row: an 88 dp ring with the score as "NN" over "/ 100"
///   ("…" while loading, "—" before the first result or after an error),
///   stroked and coloured with the foreground of [toneOf] (`StatusTone.icon`
///   above the number); then an 88 dp donut (fl_chart `PieChart`) of each
///   component's share of the score, next to a legend "label  NN %" with the
///   current weights. While loading the donut slot shows a [Loader]; after an
///   error it shows `custom.weighted_score_card.load_error`;
/// - when the score is below [alertThreshold], an alert chip in the
///   `StatusTone.danger` container with [alertLabel] (default
///   `custom.weighted_score_card.alert`, `{threshold}` = threshold × 100),
///   announced as a live region. The chip follows the last settled result:
///   it stays while a new mix is evaluated, so the slider rows below never
///   move under the user's finger, and goes away after an error;
/// - a divider, then one row per component: label ([labelWidth], ellipsis),
///   a slider at least `kMinTapTarget` high, and the weight as a percentage.
///
/// Weights: the defaults are normalised to add up to 1. Moving one slider
/// spreads the opposite change over the others in proportion to their
/// weights (equally when they are all 0). [evaluate] is called once on
/// mount, then [debounce] after the last slider change, with a map holding
/// every component id and its weight in `[0, 1]` (sum 1). Only the latest
/// call's result is rendered; a thrown error shows the error state, and the
/// next slider change retries. An `AssertionError` from [evaluate] (for
/// example a [WeightedScoreResult.score] outside `[0, 1]`) is also reported
/// through `FlutterError.reportError`, since it is a host bug rather than a
/// runtime failure. A new [components] list with different ids resets the
/// weights and evaluates again. A new [evaluate] with the same ids does not
/// re-run it: give the card a new `Key` to re-evaluate when the evaluator's
/// other inputs change.
///
/// Component colour (slider, donut slice, legend dot):
/// [WeightedScoreComponent.color], else the foreground of
/// [WeightedScoreComponent.tone], else a `ColorScheme` cycle by index
/// ([WeightedScorePalette]: primary, tertiary, secondary, error,
/// onPrimaryContainer, onTertiaryContainer, outline), each at least 3:1
/// against `cs.surface` and the `cs.surfaceContainerHighest` slider track. An
/// explicit colour should keep that 3:1 floor.
///
/// Accessibility: once a score is loaded, the ring reads
/// `custom.weighted_score_card.score_semantics` (`{value}`); before that it is
/// hidden from screen readers, and the donut slot announces the [Loader] or
/// the error text instead. Each slider's value reads
/// `custom.weighted_score_card.weight_semantics` (`{label}`, `{value}` as a
/// localised percentage); the chip reads
/// `custom.weighted_score_card.alert_semantics` with its text. The donut is
/// decorative: the legend carries the weights in text.
///
/// Needs a bounded width and an `Overlay` ancestor (a routed page or a
/// modal): Material's `Slider` builds an `OverlayPortal` for its value
/// indicator, so the card cannot live in `Layout`, above the Navigator. The
/// card is its own `Material`, so no `Material` ancestor is needed. Labels
/// are already localised by the host.
final class WeightedScoreCard extends StatefulWidget {
  /// Weighted inputs, in display order. At least two, with unique ids.
  final List<WeightedScoreComponent> components;

  /// Returns the score for a weight mix; see [WeightedScoreEvaluator].
  final WeightedScoreEvaluator evaluate;

  /// Default tone ladder: a score `>=` this value is `StatusTone.success`.
  final double goodThreshold;

  /// A score below this value shows the alert chip and, in the default tone
  /// ladder, is `StatusTone.danger` (`StatusTone.warning` in between).
  final double alertThreshold;

  /// Tone of the ring for a score in `[0, 1]`. Null → the ladder built from
  /// [goodThreshold] and [alertThreshold].
  final StatusTone Function(double score)? toneOf;

  /// Alert chip text, already localised. Null →
  /// `custom.weighted_score_card.alert`.
  final String? alertLabel;

  /// Quiet time after the last slider change before [evaluate] runs.
  final Duration debounce;

  /// Width of the slider label column.
  final double labelWidth;

  const WeightedScoreCard({
    super.key,
    required this.components,
    required this.evaluate,
    this.goodThreshold = 0.70,
    this.alertThreshold = 0.40,
    this.toneOf,
    this.alertLabel,
    this.debounce = const Duration(milliseconds: 400),
    this.labelWidth = 72,
  }) : assert(alertThreshold <= goodThreshold, "alertThreshold must not exceed goodThreshold");

  /// Tone of the ring for [score]: [toneOf], or the threshold ladder.
  StatusTone _toneFor(double score) {
    final StatusTone Function(double score)? custom = toneOf;
    if (custom != null) return custom(score);
    if (score >= goodThreshold) return StatusTone.success;
    if (score >= alertThreshold) return StatusTone.warning;
    return StatusTone.danger;
  }

  @override
  State<WeightedScoreCard> createState() => _WeightedScoreCardState();
}

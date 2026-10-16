// index.dart
//
// ScoreListCard<T> — titled card that loads a list of items through an
// injected async callback and shows each one as a compact scored row (title,
// optional secondary text, a thin 0..1 bar with its value label, optional
// caption). Built-in loading (pulsing SkeletonBlock rows), empty and error +
// retry states.
//
// ScoreListEntry (the display data of one row) is declared here, state lives
// in view_model.dart, the card tree in view.dart and the private row, skeleton
// and state messages in widgets/.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/utils/load_state.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/core/decorators/SkeletonPulse/index.dart";
import "package:flutter_skeleton/widgets/custom/SkeletonBlock/index.dart";
import "package:logger/logger.dart";

part "view_model.dart";
part "view.dart";
part "widgets/score_list_row.dart";
part "widgets/score_list_skeleton.dart";
part "widgets/state_message.dart";

/// Display data for one row of a [ScoreListCard], built by the host from its
/// own item type in [ScoreListCard.entryOf].
@immutable
final class ScoreListEntry {
  /// Main row text (one line, ellipsised).
  final String title;

  /// Optional italic secondary text next to the title. Null or empty hides it.
  final String? subtitle;

  /// Normalised score. The bar value is clamped to `[0, 1]`; a non-finite
  /// score (NaN, ±infinity) draws an empty bar, matching its `"—"` label.
  final double score;

  /// Text to the right of the bar. Null → `(score * 100).round()` (e.g.
  /// `0.734` → `"73"`, unclamped), or `"—"` when [score] is not finite.
  /// Keep it short: every row's score slot takes the width of the card's
  /// widest label (32–96 dp, one line), so a long label shortens every bar
  /// track alike; beyond 96 dp it is ellipsised.
  final String? scoreLabel;

  /// Optional short caption under the bar; it wraps (friendlier to text
  /// scaling). Null or empty hides it. When [tone] carries a meaning, put
  /// that meaning here: the colour is never the only cue.
  final String? caption;

  /// Colour of the bar fill and of the score text (tone `foreground` from
  /// [StatusTones]). The default [StatusTone.primary] is `cs.primary`.
  final StatusTone tone;

  /// Screen-reader label of the row. Null → title, subtitle,
  /// `custom.score_list_card.score_semantics` (with the score text as
  /// `{value}`) and caption, joined with ", ".
  final String? semanticLabel;

  const ScoreListEntry({
    required this.title,
    required this.score,
    this.subtitle,
    this.scoreLabel,
    this.caption,
    this.tone = StatusTone.primary,
    this.semanticLabel,
  });

  /// [score] clamped to `[0, 1]`, non-finite → 0.
  double get _ratio => score.isFinite ? score.clamp(0.0, 1.0) : 0;

  /// [scoreLabel], else the rounded percentage of [score].
  String get _scoreText {
    final String? custom = scoreLabel;
    if (custom != null) return custom;
    return score.isFinite ? "${(score * 100).round()}" : "—";
  }
}

/// Titled card that loads items with [load] and renders each one as a scored
/// row through [entryOf].
///
/// - [title]: header caption, rendered as given (`labelSmall` w700,
///   letter-spacing 1.5, `cs.onSurfaceVariant`). Pass an uppercase string for
///   an overline look. It is a semantic header.
/// - [icon]: optional 16 dp header icon in `cs.primary` (decorative).
/// - [load]: fetches the items once, when the state is created, and again on
///   retry. The host decides the query, limit and order. To reload with new
///   parameters, give the widget a `ValueKey` holding every parameter that
///   should trigger a refetch (same contract as `Listing`): a new `load`
///   closure alone never reloads.
/// - [entryOf]: maps an item to its row content ([ScoreListEntry]).
/// - [onItemTap]: called with the tapped item. Null → rows are not
///   interactive (no ink, not announced as buttons).
/// - [emptyText]: shown when [load] returns an empty list. Null →
///   `custom.score_list_card.empty`.
/// - [errorText]: shown when [load] throws, next to a
///   `custom.score_list_card.retry` button that calls [load] again. Null →
///   `custom.score_list_card.load_error`. The error is logged and never
///   escapes the widget.
/// - [skeletonRowCount]: number of 48 dp placeholder rows while loading.
///   They pulse with `SkeletonPulse`, and stay static under reduced motion.
///
/// Layout: a `cs.surfaceContainerHigh` card with radius 12 and 16 dp padding,
/// which hugs its content. The rows do not scroll, so keep the list short (a
/// top-N). The card needs a bounded width. Every row is at least
/// [kMinTapTarget] tall. All rows share one score slot, as wide as the widest
/// score text (32–96 dp), so every bar track has the same length and the bars
/// stay comparable at any text scale.
///
/// No overlay is used, so the widget works anywhere in the tree, including
/// `Layout`.
final class ScoreListCard<T> extends StatefulWidget {
  /// Header caption.
  final String title;

  /// Optional header icon.
  final IconData? icon;

  /// Fetches the items.
  final Future<List<T>> Function() load;

  /// Maps an item to its row content.
  final ScoreListEntry Function(T item) entryOf;

  /// Row tap handler; null makes the rows inert.
  final ValueChanged<T>? onItemTap;

  /// Empty-state text; null uses the built-in message.
  final String? emptyText;

  /// Error-state text; null uses the built-in message.
  final String? errorText;

  /// Number of placeholder rows while loading.
  final int skeletonRowCount;

  const ScoreListCard({
    super.key,
    required this.title,
    required this.load,
    required this.entryOf,
    this.icon,
    this.onItemTap,
    this.emptyText,
    this.errorText,
    this.skeletonRowCount = 3,
  }) : assert(skeletonRowCount >= 0);

  @override
  State<ScoreListCard<T>> createState() => _ScoreListCardState<T>();
}

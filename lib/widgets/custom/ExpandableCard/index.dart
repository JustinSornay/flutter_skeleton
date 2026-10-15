// index.dart
//
// ExpandableCard — uncontrolled accordion card for list or summary items: a
// header (title, subtitle, tone badge, one or two key values, round chevron)
// that toggles an animated, height-capped, scrollable body (an action row,
// titled sections and a free body slot). An optional preview slot under the
// header stays visible in both states and shows a pulsing skeleton bar while
// loading. Value classes live in models.dart, the expanded state in
// view_model.dart, the card shell and body in view.dart, and the header,
// value stack and action button in widgets/.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/core/decorators/SkeletonPulse/index.dart";
import "package:flutter_skeleton/widgets/custom/SkeletonBlock/index.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";

part "models.dart";
part "view_model.dart";
part "view.dart";
part "widgets/action_button.dart";
part "widgets/card_header.dart";
part "widgets/value_stack.dart";

/// Accordion card for one list or summary item.
///
/// Card: a `Material` filled with `cs.surfaceContainerLowest` (collapsed) or
/// `cs.surfaceContainerLow` (expanded), radius 10, a 0.5 dp border in
/// `cs.outlineVariant` (collapsed) or `cs.tertiaryContainer` (expanded),
/// clipped. No outer margin: list spacing is the host's job.
///
/// Header (the only part that toggles the card; at least [kMinTapTarget]
/// tall):
/// - [title] (13 / w800, `cs.onSurface`) with the optional [badge] — a
///   [StatusPill] (dense) showing the label in uppercase, tinted by its tone.
///   The badge sits at the trailing end of the title's line while both fit
///   side by side, else on a line of its own under the title; it is
///   ellipsised only when wider than the whole text column;
/// - optional [subtitle] (10 / w600, `cs.onSurfaceVariant`);
/// - optional key values at the trailing edge: [primaryValue] alone
///   (13 / w800, `cs.primary`) or, with [secondaryValue], both stacked
///   (11 / w800, `cs.primary` then `cs.tertiary`), at most 80 dp wide (a
///   longer value wraps, end aligned);
/// - a 24 dp round chevron: `cs.tertiary` fill with a `cs.onTertiary` arrow
///   when expanded, `cs.surfaceContainerLowest` fill with a
///   `cs.outlineVariant` border and a `cs.onSurfaceVariant` arrow when
///   collapsed.
///
/// Preview: [preview] is shown under the header in both states; when
/// [previewLoading] is true a 24 dp pulsing bar ([SkeletonPulse] around a
/// [SkeletonBlock]) replaces it.
///
/// Body (expanded only, capped at [bodyMaxHeight] then scrolling with
/// `ClampingScrollPhysics`), in this order:
/// - the [actions] row: compact icon + label buttons (28 dp visual height,
///   radius 8, 48 dp tap target). Neutral ones (`cs.surfaceContainerLowest`,
///   `cs.outlineVariant` border, `cs.onSurfaceVariant`) wrap from the start
///   edge. Destructive ones (`cs.error` / `cs.onError`) sit at the trailing
///   edge of the same line while both groups fit side by side, else they
///   start a line of their own under the neutral ones; without neutral
///   actions they wrap from the trailing edge. `onPressed == null` renders
///   an action disabled;
/// - each of [sections]: an optional uppercase caption (9 / w800,
///   `cs.onSurfaceVariant`, letter spacing 0.5, a semantics header read in
///   its original casing) above its child;
/// - the free [body] widget.
/// Taps inside the body never toggle the card.
///
/// Motion: the body grows with `AnimatedSize` (220 ms, `easeOutCubic`) around
/// an `AnimatedCrossFade` (180 ms), both through `resolveMotion`. Under
/// reduced motion the body is shown or hidden at once without those wrappers
/// (kept mounted offstage while hidden). Switching the reduced-motion setting
/// while the card is mounted rebuilds the body subtree, so hosts keep
/// important state above the card.
///
/// Narrow widths: long titles, badges, values and action lists wrap instead
/// of overflowing (covered by tests down to a 260 dp wide card). The card
/// uses no LayoutBuilder, so it still reports intrinsic sizes (it may sit
/// under `IntrinsicWidth` / `IntrinsicHeight`).
///
/// Expansion is uncontrolled: it starts at [initiallyExpanded] and each
/// header tap reports the new state through [onExpandedChanged].
///
/// Accessibility: the header is one button node labelled [title], whose value
/// joins [subtitle], the badge label and the key values, with an expanded
/// state and the hint `custom.expandable_card.expand` / `.collapse`. Each
/// action is a button labelled by its text. The hidden body is neither
/// hit-testable nor in the semantics tree.
///
/// Content strings are already localised by the host. The widget uses no
/// tooltip or other overlay: no `Overlay` ancestor is needed.
final class ExpandableCard extends StatefulWidget {
  /// Main heading, always visible.
  final String title;

  /// Secondary line under the title. Hidden when null or empty.
  final String? subtitle;

  /// Status pill next to the title. Hidden when null or its label is empty.
  final ExpandableCardBadge? badge;

  /// Key value at the header's trailing edge (for example "82%").
  final String? primaryValue;

  /// Comparison value stacked under [primaryValue]. Ignored when
  /// [primaryValue] is null or empty.
  final String? secondaryValue;

  /// Always visible below the header, collapsed and expanded.
  final Widget? preview;

  /// True replaces [preview] with a pulsing 24 dp skeleton bar.
  final bool previewLoading;

  /// Buttons of the expanded body's action row, in the given order within
  /// their group (neutral first, destructive at the trailing edge).
  final List<ExpandableCardAction> actions;

  /// Titled blocks of the expanded body, under the action row.
  final List<ExpandableCardSection> sections;

  /// Free content of the expanded body, after [sections].
  final Widget? body;

  /// Expansion state on first build.
  final bool initiallyExpanded;

  /// Called with the new state each time the user toggles the header.
  final ValueChanged<bool>? onExpandedChanged;

  /// Maximum height of the expanded body before it scrolls.
  final double bodyMaxHeight;

  const ExpandableCard({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    this.primaryValue,
    this.secondaryValue,
    this.preview,
    this.previewLoading = false,
    this.actions = const <ExpandableCardAction>[],
    this.sections = const <ExpandableCardSection>[],
    this.body,
    this.initiallyExpanded = false,
    this.onExpandedChanged,
    this.bodyMaxHeight = 360,
  });

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

// index.dart
//
// ThumbnailChoicePicker<T> — controlled single-choice picker whose options
// are tappable thumbnail previews with a caption, next to an optional title
// and subtitle (side by side when wide, stacked when narrow). The widget owns
// no state: the host passes the selected value and reacts to onChanged. The
// option value class lives in thumbnail_choice.dart, the tree in view.dart,
// one card in widgets/choice_card.dart and the built-in mini app mockup in
// widgets/mockup_thumbnail.dart.

import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/_base/choice_option.dart";

part "thumbnail_choice.dart";
part "view.dart";
part "widgets/choice_card.dart";
part "widgets/mockup_thumbnail.dart";

/// Controlled single-choice picker of thumbnail options.
///
/// Fits any choice that reads best as a picture: appearance (light / dark /
/// system, each drawn from its own `ColorScheme`), layout or density,
/// template…
///
/// Layout (needs a bounded width; the height hugs the content), inside
/// [padding]:
/// - With a [title] or [subtitle]: when the available width is at least
///   [stackBreakpoint] and leaves 128 dp to the title next to the cards, the
///   title block sits on the left and the cards on the right in one row;
///   otherwise the title block is stacked above the cards (12 dp gap), which
///   then wrap onto several runs.
/// - Without both, only the cards are drawn (a wrapping row).
/// - The title is `textTheme.titleSmall` in `cs.onSurface`, the subtitle
///   `textTheme.bodySmall` in `cs.onSurfaceVariant`; screen readers announce
///   them together.
///
/// Each card is [thumbnailSize] wide (default 96 × 64, both sides at least
/// [kMinTapTarget], asserted when the picker builds): the thumbnail frame
/// (2 dp border, radius 8, content clipped) above a caption (`labelSmall`
/// w600, at most two centred lines). The selected card gets a `cs.primary`
/// border, a 3 dp `cs.primary` ring at 15 % opacity, a `cs.primary` check
/// badge in its top-right corner and a `cs.primary` caption; the others use a
/// `cs.outlineVariant` border and a `cs.onSurfaceVariant` caption. The
/// selection is never colour-only: the check badge marks it and each card
/// reports `selected` to screen readers inside a mutually exclusive group.
/// The selection changes instantly (no animation).
///
/// Cards render these [ChoiceOption] fields of [ThumbnailChoice.option]:
/// - `label`: the caption;
/// - `enabled`: `false` dims the card (38 % opacity) and ignores taps;
/// - `semanticsLabel`: the spoken label, which defaults to `label`.
///
/// `description`, `trailing` and `icon` are not rendered. The thumbnail
/// itself is excluded from semantics.
///
/// No overlay is used, and the picker provides its own [Material] for ink:
/// it works anywhere, including `Layout`.
///
/// Content strings ([title], [subtitle], captions) are already localised by
/// the host.
final class ThumbnailChoicePicker<T> extends StatelessWidget with _ViewMixin<T> {
  const ThumbnailChoicePicker({
    super.key,
    required this.choices,
    required this.selected,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.thumbnailSize = const Size(96, 64),
    this.spacing = kDefaultPadding,
    this.stackBreakpoint = 360,
    this.padding = const EdgeInsets.all(kDefaultPadding * 2),
  });

  /// Options, rendered left to right in this order. Must not be empty
  /// (asserted when the picker builds, so the constructor stays const).
  final List<ThumbnailChoice<T>> choices;

  /// Currently selected value, compared with `==` to each option's `value`.
  /// Null selects no card.
  final T? selected;

  /// Called with the option's `value` when an enabled, unselected card is
  /// tapped; tapping the selected card does nothing. Null disables every
  /// card (dimmed, inert, reported as disabled to screen readers).
  final ValueChanged<T>? onChanged;

  /// Optional title, already localised.
  final String? title;

  /// Optional second line under the title, already localised.
  final String? subtitle;

  /// Size of each thumbnail frame, border included; both sides must be at
  /// least [kMinTapTarget]. The card is as wide as the thumbnail.
  final Size thumbnailSize;

  /// Gap between cards, horizontally and between wrapped runs.
  final double spacing;

  /// Below this available width (inside [padding]) the title block is
  /// stacked above the cards.
  final double stackBreakpoint;

  /// Padding around the whole picker.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

// index.dart
//
// SwimlaneCard — a titled card holding a horizontally scrollable lane of
// fixed-width tiles (headline value, caption, optional badge) where the host
// highlights one tile and reacts to taps. Value class: SwimlaneItem. The card
// tree lives in view.dart; one tile is the private part in widgets/.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";

part "view.dart";
part "widgets/swimlane_tile.dart";

/// One tile of a [SwimlaneCard].
@immutable
final class SwimlaneItem<T> {
  /// Identity of the tile: compared with `==` against
  /// [SwimlaneCard.selectedId] and passed to [SwimlaneCard.onSelected].
  final T id;

  /// Headline shown large at the top of the tile, already formatted by the
  /// host ("0.87", "12 °C", "1 240 €"). Scaled down when wider than the tile.
  final String value;

  /// Short caption under the value (one line, ellipsized).
  final String label;

  /// Small tag at the bottom of the tile, drawn as a dense [StatusPill] in
  /// [tone] (neutral when [tone] is null). Null or empty hides it.
  final String? badge;

  /// Semantic accent of the tile. Non-null: the value text and the selected
  /// outline / fill use the tone `foreground`. Null: the value uses
  /// `cs.onSurface` and the selected outline / fill use `cs.primary`.
  final StatusTone? tone;

  /// Screen-reader label. Null or empty → "[label], [value], [badge]".
  final String? semanticsLabel;

  const SwimlaneItem({
    required this.id,
    required this.value,
    required this.label,
    this.badge,
    this.tone,
    this.semanticsLabel,
  });
}

/// Titled card with a horizontally scrollable lane of selectable tiles,
/// typically one metric compared across variants or periods (plans,
/// versions, months, …) with the active one highlighted.
///
/// - Card: `cs.surfaceContainerHigh`, radius 12, 16 dp padding.
/// - Header: [title] (`labelSmall` w700, letter spacing 1.5,
///   `cs.onSurfaceVariant`, one line, ellipsized) with [trailing] at the end
///   of the row; [subtitle] below it (`bodyMedium` w600, `cs.onSurface`, one
///   line, ellipsized) when non-null.
/// - Lane: 96 dp tall (grown with the text scale above 1), tiles
///   [tileWidth] wide with an 8 dp gap, scrolling horizontally when they do
///   not fit.
/// - Tile (radius 8, `cs.surfaceContainer`, 8 dp padding): the value
///   (18 / w800, scaled down to fit), the caption (`labelSmall`,
///   `cs.onSurfaceVariant`) and the optional badge, spread top to bottom.
/// - Selected tile ([SwimlaneItem.id] == [selectedId]): accent fill at 12 %
///   and a 1.5 dp accent outline, animated over `kMotionShort`
///   (`easeOutCubic`, instant under reduced motion). The accent is the tile
///   tone `foreground`, else `cs.primary`. The outline stroke and the
///   `selected` semantics flag mark the selection, not the fill alone.
/// - Tone: when [SwimlaneItem.tone] carries a meaning (a status), the host
///   also states it in [SwimlaneItem.badge] or [SwimlaneItem.label], so the
///   value colour is never the only cue.
///
/// The host owns the selection: it passes [selectedId] and updates it from
/// [onSelected]. With [onSelected] null the lane is read-only.
///
/// Accessibility: each tile is one semantics node labelled
/// [SwimlaneItem.semanticsLabel] (default "label, value, badge") and flagged
/// `selected`; interactive tiles are buttons of a mutually exclusive group,
/// focusable and keyboard-activatable through an [InkWell].
///
/// Content strings are already localised (and numbers formatted) by the
/// host. No tooltip, so no `Overlay` ancestor is needed (unless [trailing]
/// itself needs one). Needs a bounded width.
final class SwimlaneCard<T> extends StatelessWidget with _ViewMixin<T> {
  /// Section caption, shown as given (pass it uppercased for the usual
  /// caption look).
  final String title;

  /// Optional second header line. Hidden when null.
  final String? subtitle;

  /// Optional widget at the end of the header row (an action link, a help
  /// button, …).
  final Widget? trailing;

  /// Tiles in display order.
  final List<SwimlaneItem<T>> items;

  /// Id of the highlighted tile. Null or an id matching no item → none.
  final T? selectedId;

  /// Called with the tapped tile's id. Null makes every tile read-only (no
  /// ink, basic cursor, not a semantics button).
  final ValueChanged<T>? onSelected;

  /// Fixed tile width, at least [kMinTapTarget] (asserted).
  final double tileWidth;

  const SwimlaneCard({
    super.key,
    required this.title,
    required this.items,
    this.subtitle,
    this.trailing,
    this.selectedId,
    this.onSelected,
    this.tileWidth = 80,
  }) : assert(tileWidth >= kMinTapTarget, "tileWidth must be at least kMinTapTarget");

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

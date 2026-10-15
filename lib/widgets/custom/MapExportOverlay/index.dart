// index.dart
//
// MapExportOverlay — non-interactive cartographic overlay stacked over a map
// or chart while it is captured as an image (RepaintBoundary export): a
// north-arrow badge (top-right), a legend card (bottom-right) and an
// attribution pill (bottom-centre). The tree lives in view.dart; the badge,
// the card and the pill are private parts in widgets/. Value class:
// MapLegendEntry. The capture and share flow stays in the host.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "view.dart";
part "widgets/attribution_pill.dart";
part "widgets/legend_card.dart";
part "widgets/north_badge.dart";

/// One legend row of [MapExportOverlay]: a colour swatch always paired with
/// its text label (never colour alone).
@immutable
final class MapLegendEntry {
  /// Swatch fill, from the host's data palette (or a `StatusTones` colour).
  final Color color;

  /// Visible label next to the swatch, already localised by the host.
  final String label;

  const MapLegendEntry({required this.color, required this.label});
}

/// Capture-only overlay: north arrow, legend and attribution line.
///
/// Fills its parent (it needs bounded constraints): the host mounts it with
/// `Positioned.fill` over the map, inside the `RepaintBoundary` it captures,
/// only while the image is being taken. The whole overlay sits in an
/// [IgnorePointer], so it never intercepts gestures.
///
/// Renders, each part optional:
/// - [showNorthArrow]: a 32 dp circle, 16 dp from the top-right corner,
///   showing the `custom.map_export_overlay.north_short` glyph (13 / w800).
/// - a legend card, 16 dp from the right edge and 36 dp from the bottom
///   (10 dp padding, radius 8): [legendTitle] upper-cased (8 / w800, letter
///   spacing 1), [legendSubtitle] (7 / w500, muted), then one row per
///   [legendEntries] item (12 dp swatch, radius 2, then the label 9 / w400).
///   The card is hidden when the title, the subtitle and the entries are all
///   absent; it never grows wider than the overlay minus 16 dp on each side
///   (long labels wrap).
/// - [attributions] joined with " · " in one pill (radius 4, 9 / w500),
///   horizontally centred 12 dp from the bottom. Hidden when empty.
///
/// Colours: the badge and the pill use `cs.inverseSurface` at 58 % opacity,
/// the card at 62 %, so they stay readable over arbitrary imagery in both
/// brightnesses; text is `cs.onInverseSurface` (subtitle at 54 %). Text
/// styles derive from `textTheme.labelSmall` (app font).
///
/// Accessibility: the badge is one semantics node labelled
/// `custom.map_export_overlay.north` (the glyph is not read); the legend card
/// is a semantics container labelled `custom.map_export_overlay.legend_label`
/// whose title, subtitle and entry labels stay separate text nodes.
/// Swatches are decorative (each one is paired with its label).
///
/// No `Overlay` ancestor is needed. Content strings ([legendTitle],
/// [legendSubtitle], entry labels, [attributions]) are already localised by
/// the host.
final class MapExportOverlay extends StatelessWidget with _ViewMixin {
  /// Legend heading, rendered upper-cased. Null → no heading.
  final String? legendTitle;

  /// Muted line under the heading. Null → no subtitle.
  final String? legendSubtitle;

  /// Legend rows, in display order. Any number of rows.
  final List<MapLegendEntry> legendEntries;

  /// Source credits joined with " · " in one bottom-centre pill. Empty → no
  /// pill.
  final List<String> attributions;

  /// Shows the north-arrow badge in the top-right corner.
  final bool showNorthArrow;

  const MapExportOverlay({
    super.key,
    this.legendTitle,
    this.legendSubtitle,
    this.legendEntries = const <MapLegendEntry>[],
    this.attributions = const <String>[],
    this.showNorthArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

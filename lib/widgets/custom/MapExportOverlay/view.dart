// view.dart
//
// Tree of MapExportOverlay: an IgnorePointer Stack placing the optional
// north badge (top-right), legend card (bottom-right) and attribution pill
// (bottom-centre). Also holds the private layout and style constants shared
// with the parts in widgets/, and the text style helper.

part of "index.dart";

/// Inset of the north badge and the legend card from the overlay edges.
const double _edgeInset = 2 * kDefaultPadding;

/// Distance from the bottom edge to the legend card (clears the pill).
const double _legendBottom = 36;

/// Distance from the bottom edge to the attribution pill.
const double _attributionBottom = 12;

/// Separator between [MapExportOverlay.attributions].
const String _attributionSeparator = " · ";

/// Opacity of the badge and pill backgrounds (`cs.inverseSurface`).
const double _chipAlpha = 0.58;

/// Opacity of the legend card background (`cs.inverseSurface`).
const double _legendAlpha = 0.62;

/// Opacity of the muted legend subtitle (`cs.onInverseSurface`).
const double _mutedAlpha = 0.54;

/// `textTheme.labelSmall` resized for the overlay, in `cs.onInverseSurface`
/// unless [color] is given.
TextStyle _overlayTextStyle(
  BuildContext context, {
  required double fontSize,
  required FontWeight fontWeight,
  double letterSpacing = 0,
  Color? color,
}) {
  final ThemeData theme = Theme.of(context);
  return (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    color: color ?? theme.colorScheme.onInverseSurface,
  );
}

mixin _ViewMixin {
  Widget render(BuildContext context, MapExportOverlay widget) {
    final bool hasLegend = widget.legendTitle != null ||
        widget.legendSubtitle != null ||
        widget.legendEntries.isNotEmpty;

    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          if (widget.showNorthArrow)
            const Positioned(top: _edgeInset, right: _edgeInset, child: _NorthBadge()),
          if (hasLegend)
            Positioned(
              left: _edgeInset,
              right: _edgeInset,
              bottom: _legendBottom,
              child: Align(
                alignment: Alignment.bottomRight,
                child: _LegendCard(
                  title: widget.legendTitle,
                  subtitle: widget.legendSubtitle,
                  entries: widget.legendEntries,
                ),
              ),
            ),
          if (widget.attributions.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: _attributionBottom,
              child: Center(
                child: _AttributionPill(
                  text: widget.attributions.join(_attributionSeparator),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

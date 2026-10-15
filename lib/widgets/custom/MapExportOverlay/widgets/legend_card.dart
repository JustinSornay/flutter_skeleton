// legend_card.dart
//
// Private legend card of MapExportOverlay: an optional upper-cased title, an
// optional muted subtitle and one swatch + label row per MapLegendEntry, on
// a translucent inverse-surface card announced as the legend container.

part of "../index.dart";

/// Inner padding of the card.
const double _legendPadding = 10;

/// Corner radius of the card.
const double _legendRadius = 8;

/// Gap between the title / subtitle block and the first row.
const double _legendHeaderGap = 7;

/// Font sizes of the title, the subtitle and the row labels.
const double _titleFontSize = 8;
const double _subtitleFontSize = 7;
const double _labelFontSize = 9;

/// Letter spacing of the upper-cased title.
const double _titleLetterSpacing = 1;

/// Swatch geometry and spacing.
const double _swatchSize = 12;
const double _swatchRadius = 2;
const double _swatchGap = 6;
const double _rowVerticalPadding = 2;

final class _LegendCard extends StatelessWidget {
  /// Heading, shown upper-cased. Null → hidden.
  final String? title;

  /// Muted line under the heading. Null → hidden.
  final String? subtitle;

  /// Rows, in display order.
  final List<MapLegendEntry> entries;

  const _LegendCard({
    required this.title,
    required this.subtitle,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String? title = this.title;
    final String? subtitle = this.subtitle;
    final bool hasHeader = title != null || subtitle != null;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: "custom.map_export_overlay.legend_label".tr(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.inverseSurface.withValues(alpha: _legendAlpha),
          borderRadius: BorderRadius.circular(_legendRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(_legendPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (title != null)
                Text(
                  title.toUpperCase(),
                  style: _overlayTextStyle(
                    context,
                    fontSize: _titleFontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: _titleLetterSpacing,
                  ),
                ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: _overlayTextStyle(
                    context,
                    fontSize: _subtitleFontSize,
                    fontWeight: FontWeight.w500,
                    color: cs.onInverseSurface.withValues(alpha: _mutedAlpha),
                  ),
                ),
              if (hasHeader && entries.isNotEmpty) const SizedBox(height: _legendHeaderGap),
              for (final MapLegendEntry entry in entries) _row(context, entry),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, MapLegendEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _rowVerticalPadding),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox.square(
            dimension: _swatchSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: entry.color,
                borderRadius: BorderRadius.circular(_swatchRadius),
              ),
            ),
          ),
          const SizedBox(width: _swatchGap),
          Flexible(
            child: Text(
              entry.label,
              style: _overlayTextStyle(
                context,
                fontSize: _labelFontSize,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

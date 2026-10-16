// view.dart
//
// Tree of RadarChartCard: the guard that renders nothing without data, the
// bordered card, the self-managed ExpansionTile header (icon tile, title,
// optional help button, chevron) and the body with a divider above the chart
// (widgets/radar_plot.dart). Colours come from the ColorScheme only.

part of "index.dart";

/// Card corner radius, shared with CollapsibleSectionCard.
const double _cardRadius = 24;

/// Leading tile side.
const double _tileSize = 32;

/// Leading tile corner radius.
const double _tileRadius = 10;

/// Leading tile background opacity over `cs.primary`.
const double _tileAlpha = 0.10;

/// Icon size inside the leading tile.
const double _tileIconSize = 16;

/// Glyph size of the help button.
const double _helpIconSize = 18;

mixin _ViewMixin {
  Widget render(BuildContext context, RadarChartCard widget) {
    final RadarSeries? series = widget.series;
    if (series == null || series.values.isEmpty || widget.axes.length < _minAxes) {
      return const SizedBox.shrink();
    }
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: widget.initiallyExpanded,
        // The card draws the border: no extra lines around the open tile.
        shape: const Border(),
        collapsedShape: const Border(),
        expansionAnimationStyle: AnimationStyle(
          duration: resolveMotion(context, kMotionShort),
          curve: Curves.easeInOut,
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 2),
        childrenPadding: EdgeInsets.zero,
        iconColor: cs.onSurfaceVariant,
        collapsedIconColor: cs.onSurfaceVariant,
        leading: _leading(widget.icon, cs),
        title: _title(context, widget, cs),
        children: <Widget>[
          Divider(height: 1, thickness: 1, color: cs.outlineVariant),
          Padding(
            padding: const EdgeInsets.all(kDefaultPadding * 2),
            child: SizedBox(
              height: widget.chartHeight,
              child: _RadarPlot(
                axes: widget.axes,
                series: series,
                comparison: widget.comparison,
                maxValue: widget.maxValue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Decorative 32 dp tile tinted with the primary colour.
  Widget _leading(IconData icon, ColorScheme cs) {
    return Container(
      width: _tileSize,
      height: _tileSize,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: _tileAlpha),
        borderRadius: BorderRadius.circular(_tileRadius),
      ),
      child: Icon(icon, size: _tileIconSize, color: cs.primary),
    );
  }

  /// Title, followed by the help button when [RadarChartCard.onHelp] is set.
  Widget _title(BuildContext context, RadarChartCard widget, ColorScheme cs) {
    final Widget text = Text(
      widget.title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface),
    );
    final VoidCallback? onHelp = widget.onHelp;
    if (onHelp == null) return text;

    return Row(
      children: <Widget>[
        Expanded(child: text),
        const SizedBox(width: kDefaultPadding),
        SizedBox.square(
          dimension: kMinTapTarget,
          child: IconButton(
            onPressed: onHelp,
            padding: EdgeInsets.zero,
            tooltip: widget.helpLabel ?? "custom.radar_chart_card.help".tr(),
            icon: Icon(Icons.help_outline_rounded, size: _helpIconSize, color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

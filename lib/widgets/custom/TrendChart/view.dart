// view.dart
//
// Tree of TrendChart: the fallback text for empty or short series, else the
// fl_chart LineChart (one line coloured by side, threshold line, crossing
// markers, axis labels, horizontal grid) in a labelled semantics image node,
// then the optional caption. Colours come from the ColorScheme and
// StatusTones only.

part of "index.dart";

/// Hidden titles, shared by the top and right sides.
const AxisTitles _noTitles = AxisTitles(sideTitles: SideTitles(showTitles: false));

/// Height reserved under the plot for the X labels.
const double _bottomTitlesSize = 28;

/// Width reserved left of the plot for the Y labels.
const double _leftTitlesSize = 30;

/// Gap between an extra line and its label (fl_chart's default padding).
const double _lineLabelGap = 6;

mixin _ViewMixin {
  Widget render(BuildContext context, _TrendChartState state) {
    final TrendChart widget = state.widget;
    if (widget.points.isEmpty) return _TrendMessage(text: state._emptyMessage);
    if (widget.points.length < widget.minPoints) {
      return _TrendMessage(text: state._insufficientDataMessage);
    }

    final String? caption = widget.caption;
    return Padding(
      padding: const EdgeInsets.fromLTRB(kDefaultPadding, kDefaultPadding, kDefaultPadding * 2, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Semantics(
            container: true,
            image: true,
            label: state._semanticLabel,
            excludeSemantics: true,
            child: SizedBox(
              height: widget.height,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) => LineChart(
                  _chartData(
                    context,
                    state,
                    Size(constraints.maxWidth - _leftTitlesSize, widget.height - _bottomTitlesSize),
                  ),
                  duration: resolveMotion(context, _TrendChartState._entryDuration),
                  curve: Curves.easeOut,
                ),
              ),
            ),
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: kDefaultPadding),
            _caption(context, caption),
            const SizedBox(height: kDefaultPadding),
          ],
        ],
      ),
    );
  }

  /// [plot]: size of the plot area (axis labels excluded), used to keep the
  /// extra-line labels inside it.
  LineChartData _chartData(BuildContext context, _TrendChartState state, Size plot) {
    final TrendChart widget = state.widget;
    final TrendChartGeometry geometry = state._geometry;
    return LineChartData(
      minX: 0,
      maxX: (widget.points.length - 1).toDouble(),
      minY: geometry.minY,
      maxY: geometry.maxY,
      lineBarsData: <LineChartBarData>[_bar(context, state)],
      extraLinesData: _extraLines(context, state, plot),
      titlesData: FlTitlesData(
        bottomTitles: _bottomTitles(context, state),
        leftTitles: _leftTitles(context, state),
        rightTitles: _noTitles,
        topTitles: _noTitles,
      ),
      gridData: _grid(context, widget.yInterval),
      borderData: FlBorderData(show: false),
      lineTouchData: const LineTouchData(enabled: false),
      clipData: const FlClipData.none(),
    );
  }

  /// The whole series as one bar, so fl_chart draws the extra lines once
  /// (it redraws them after every bar). Several colour runs become a
  /// hard-stop gradient across the X axis, switching at each crossing.
  LineChartBarData _bar(BuildContext context, _TrendChartState state) {
    final TrendThreshold? threshold = state.widget.threshold;
    final TrendChartGeometry geometry = state._geometry;
    final double maxX = geometry.spots.last.x;
    final List<Color> colors = <Color>[];
    final List<double> stops = <double>[];
    for (final TrendChartSegment segment in geometry.segments) {
      final Color color = threshold == null
          ? Theme.of(context).colorScheme.primary
          : StatusTones.colorsOf(
              context,
              segment.favourable ? threshold.favourableTone : threshold.adverseTone,
            ).foreground;
      colors.addAll(<Color>[color, color]);
      stops.addAll(<double>[segment.spots.first.x / maxX, segment.spots.last.x / maxX]);
    }
    final bool single = geometry.segments.length == 1;
    return LineChartBarData(
      spots: geometry.spots,
      color: single ? colors.first : null,
      gradient: single ? null : LinearGradient(colors: colors, stops: stops),
      gradientArea: LineChartGradientArea.wholeChart,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  /// Threshold line and crossing markers. The plot is not clipped, so each
  /// label goes on the side of its line where the plot has room for it: the
  /// threshold label above its line (top right) unless the threshold is too
  /// close to the top, then under it (bottom right); a crossing label right
  /// of its marker unless the marker is too close to the right edge, then
  /// left of it.
  ExtraLinesData _extraLines(BuildContext context, _TrendChartState state, Size plot) {
    final TrendThreshold? threshold = state.widget.threshold;
    if (threshold == null) return const ExtraLinesData();

    final TrendChartGeometry geometry = state._geometry;
    final Color lineColor = StatusTones.colorsOf(context, StatusTone.warning).foreground;
    final Color adverseColor = StatusTones.colorsOf(context, threshold.adverseTone).foreground;
    final String thresholdLabel = state._thresholdLabel;
    final TextStyle thresholdStyle = _lineLabelStyle(context, lineColor);
    final double thresholdLabelHeight = _labelSize(context, thresholdLabel, thresholdStyle).height;
    final String crossingLabel = state._crossingLabel;
    final TextStyle crossingStyle = _lineLabelStyle(context, adverseColor);
    final double crossingLabelWidth = _labelSize(context, crossingLabel, crossingStyle).width;
    return ExtraLinesData(
      horizontalLines: <HorizontalLine>[
        HorizontalLine(
          y: threshold.value,
          color: lineColor,
          strokeWidth: 1,
          dashArray: <int>[6, 4],
          label: HorizontalLineLabel(
            show: true,
            labelResolver: (HorizontalLine _) => thresholdLabel,
            style: thresholdStyle,
            padding: const EdgeInsets.all(_lineLabelGap),
            alignment: geometry.roomAbove(threshold.value, plot.height) >= thresholdLabelHeight + _lineLabelGap
                ? Alignment.topRight
                : Alignment.bottomRight,
          ),
        ),
      ],
      verticalLines: <VerticalLine>[
        for (final double x in geometry.adverseCrossings)
          VerticalLine(
            x: x,
            color: adverseColor.withValues(alpha: 0.5),
            strokeWidth: 1,
            dashArray: <int>[4, 4],
            label: VerticalLineLabel(
              show: true,
              labelResolver: (VerticalLine _) => crossingLabel,
              style: crossingStyle,
              padding: const EdgeInsets.all(_lineLabelGap),
              alignment: geometry.roomRight(x, plot.width) >= crossingLabelWidth + _lineLabelGap
                  ? Alignment.topRight
                  : Alignment.topLeft,
            ),
          ),
      ],
    );
  }

  /// Size of [label] laid out the way fl_chart paints a line label: one
  /// unscaled line of [style] over the ambient text style, bold when the
  /// platform asks for bold text.
  Size _labelSize(BuildContext context, String label, TextStyle style) {
    TextStyle effective = DefaultTextStyle.of(context).style.merge(style);
    if (MediaQuery.boldTextOf(context)) effective = effective.merge(const TextStyle(fontWeight: FontWeight.bold));
    final TextPainter painter = TextPainter(
      text: TextSpan(text: label, style: effective),
      textDirection: TextDirection.ltr,
    )..layout();
    final Size size = painter.size;
    painter.dispose();
    return size;
  }

  AxisTitles _bottomTitles(BuildContext context, _TrendChartState state) {
    final List<TrendPoint> points = state.widget.points;
    final String Function(DateTime date) format = state._xFormatter(context);
    final TextStyle? style = _axisLabelStyle(context);
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: _bottomTitlesSize,
        interval: TrendChartGeometry.xLabelInterval(points.length),
        getTitlesWidget: (double value, TitleMeta meta) {
          final int i = value.round();
          if (i < 0 || i >= points.length || value != i.toDouble()) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: kDefaultPadding / 2),
            child: Text(format(points[i].date), style: style),
          );
        },
      ),
    );
  }

  AxisTitles _leftTitles(BuildContext context, _TrendChartState state) {
    final String Function(double value) format = state._yFormatter(context);
    final TextStyle? style = _axisLabelStyle(context);
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: _leftTitlesSize,
        interval: state.widget.yInterval,
        getTitlesWidget: (double value, TitleMeta meta) => Text(format(value), style: style),
      ),
    );
  }

  FlGridData _grid(BuildContext context, double? interval) {
    final Color color = Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3);
    return FlGridData(
      drawHorizontalLine: true,
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (double _) => FlLine(color: color, strokeWidth: 1),
    );
  }

  Widget _caption(BuildContext context, String caption) {
    final ThemeData theme = Theme.of(context);
    return Text(
      caption,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  TextStyle? _axisLabelStyle(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.textTheme.labelSmall?.copyWith(fontSize: 9, color: theme.colorScheme.onSurfaceVariant);
  }

  TextStyle _lineLabelStyle(BuildContext context, Color color) {
    return (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(fontSize: 9, color: color);
  }
}

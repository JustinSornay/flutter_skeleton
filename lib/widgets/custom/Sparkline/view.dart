// view.dart
//
// Tree of Sparkline: a fixed-size box holding a bare fl_chart LineChart (one
// line, every piece of chrome hidden, clipped only when a value falls outside
// the Y range, no animation), or nothing when the series has fewer than 2
// values. The box is excluded from semantics unless a label is given. Colours
// come from the ColorScheme only.

part of "index.dart";

/// Hidden titles, shared by the four sides of the chart.
const AxisTitles _noTitles = AxisTitles(sideTitles: SideTitles(showTitles: false));

mixin _ViewMixin {
  Widget render(BuildContext context, Sparkline widget) {
    assert(widget.values.every((double v) => v.isFinite), "Sparkline values must be finite");
    final Widget box = SizedBox(
      width: widget.width,
      height: widget.height,
      child: widget.values.length < 2 ? null : _chart(context, widget),
    );
    final String? label = widget.semanticsLabel;
    if (label == null) return ExcludeSemantics(child: box);
    return Semantics(
      container: true,
      image: true,
      label: label,
      excludeSemantics: true,
      child: box,
    );
  }

  Widget _chart(BuildContext context, Sparkline widget) {
    final ({double min, double max}) range = widget.yRange;
    // Only Y can leave the range (X always spans 0..len - 1). Clipping data
    // that stays inside would cut half the stroke at every edge it touches.
    final bool overflows = widget.values.any((double v) => v < range.min || v > range.max);
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (widget.values.length - 1).toDouble(),
        minY: range.min,
        maxY: range.max,
        lineBarsData: <LineChartBarData>[_line(context, widget)],
        titlesData: const FlTitlesData(
          bottomTitles: _noTitles,
          leftTitles: _noTitles,
          rightTitles: _noTitles,
          topTitles: _noTitles,
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        clipData: overflows ? const FlClipData.vertical() : const FlClipData.none(),
      ),
      duration: Duration.zero,
    );
  }

  LineChartBarData _line(BuildContext context, Sparkline widget) {
    return LineChartBarData(
      spots: <FlSpot>[
        for (int i = 0; i < widget.values.length; i++) FlSpot(i.toDouble(), widget.values[i]),
      ],
      color: widget.color ?? Theme.of(context).colorScheme.primary,
      barWidth: widget.strokeWidth,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
}

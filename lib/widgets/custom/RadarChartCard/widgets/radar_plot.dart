// radar_plot.dart
//
// Private chart of RadarChartCard: maps the series onto the axes (missing
// key → 0, clamped to [0, maxValue]), anchors the scale to [0, maxValue]
// with two transparent data sets, draws the optional comparison under the
// main series in a slot that stays in place (invisible when unset), builds
// the axis titles (with the weight suffix) and the screen-reader description
// of every value.

part of "../index.dart";

/// Fewest spokes a radar can draw (fl_chart asserts on fewer).
const int _minAxes = 3;

/// Rings between the centre and the outer ring.
const int _tickCount = 4;

/// Duration of the value-change animation.
const Duration _valueMotion = Duration(milliseconds: 500);

/// Distance of the axis titles from the outer ring (fraction of the radius).
const double _titleOffset = 0.2;

/// Fill opacity of the main series over its stroke colour.
const double _seriesFillAlpha = 0.20;

/// Fill opacity of the comparison series over its stroke colour.
const double _comparisonFillAlpha = 0.25;

/// Stroke width and dot radius of the main series.
const double _seriesBorderWidth = 2;
const double _seriesEntryRadius = 3;

/// Stroke width and dot radius of the comparison series.
const double _comparisonBorderWidth = 1.5;
const double _comparisonEntryRadius = 2;

/// Outer ring and inner rings / spokes widths.
const double _outerRingWidth = 1;
const double _gridWidth = 0.5;

final class _RadarPlot extends StatelessWidget {
  final List<RadarAxis> axes;

  final RadarSeries series;

  final RadarSeries? comparison;

  final double maxValue;

  const _RadarPlot({
    required this.axes,
    required this.series,
    required this.comparison,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final List<String> titles = <String>[for (final RadarAxis axis in axes) _title(context, axis)];
    final List<double> values = _valuesOf(series);
    final RadarSeries? overlay = comparison;
    final List<double>? overlayValues = overlay == null ? null : _valuesOf(overlay);

    return Semantics(
      container: true,
      label: _describe(context, titles, values, overlayValues),
      child: RadarChart(
        RadarChartData(
          dataSets: <RadarDataSet>[
            _anchor(0),
            _anchor(maxValue),
            // The comparison slot is always there: fl_chart lerps data sets
            // by index, so a stable count fades the overlay in and out
            // instead of morphing the main series into it.
            if (overlay != null && overlayValues != null)
              _dataSet(
                overlayValues,
                overlay.color ?? cs.tertiary,
                fillAlpha: _comparisonFillAlpha,
                borderWidth: _comparisonBorderWidth,
                entryRadius: _comparisonEntryRadius,
              )
            else
              _hiddenOverlay(values, cs.tertiary),
            _dataSet(
              values,
              series.color ?? cs.primary,
              fillAlpha: _seriesFillAlpha,
              borderWidth: _seriesBorderWidth,
              entryRadius: _seriesEntryRadius,
            ),
          ],
          // With the 0 anchor, the centre is 0 and the outer ring maxValue.
          isMinValueAtCenter: true,
          radarTouchData: RadarTouchData(enabled: false),
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: BorderSide(color: cs.outlineVariant, width: _outerRingWidth),
          tickBorderData: BorderSide(color: cs.outlineVariant, width: _gridWidth),
          gridBorderData: BorderSide(color: cs.outlineVariant, width: _gridWidth),
          tickCount: _tickCount,
          ticksTextStyle: const TextStyle(fontSize: 0, color: Colors.transparent),
          titlePositionPercentageOffset: _titleOffset,
          titleTextStyle: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
          getTitle: (int index, double angle) =>
              RadarChartTitle(text: index >= 0 && index < titles.length ? titles[index] : ""),
        ),
        duration: resolveMotion(context, _valueMotion),
        curve: Curves.easeOut,
      ),
    );
  }

  /// One value per axis, in axis order: missing → 0, NaN → 0, clamped to
  /// `[0, maxValue]`.
  List<double> _valuesOf(RadarSeries source) {
    return <double>[
      for (final RadarAxis axis in axes) _clamp(source.values[axis.key] ?? 0),
    ];
  }

  double _clamp(double value) => value.isNaN ? 0 : value.clamp(0, maxValue);

  /// Invisible data set pinning the scale: all entries at [value].
  RadarDataSet _anchor(double value) {
    return RadarDataSet(
      dataEntries: <RadarEntry>[for (int i = 0; i < axes.length; i++) RadarEntry(value: value)],
      fillColor: Colors.transparent,
      borderColor: Colors.transparent,
      borderWidth: 0,
      entryRadius: 0,
    );
  }

  /// Stand-in for an unset comparison: the main polygon ([values]) in the
  /// default comparison [color] at 0 % opacity, so a toggle grows the
  /// overlay out of the series (and back) while it fades.
  RadarDataSet _hiddenOverlay(List<double> values, Color color) {
    return _dataSet(values, color.withValues(alpha: 0), fillAlpha: 0, borderWidth: 0, entryRadius: 0);
  }

  /// Visible polygon: [stroke] border and dots, [stroke] at [fillAlpha] fill.
  RadarDataSet _dataSet(
    List<double> values,
    Color stroke, {
    required double fillAlpha,
    required double borderWidth,
    required double entryRadius,
  }) {
    return RadarDataSet(
      dataEntries: <RadarEntry>[for (final double value in values) RadarEntry(value: value)],
      fillColor: stroke.withValues(alpha: fillAlpha),
      borderColor: stroke,
      borderWidth: borderWidth,
      entryRadius: entryRadius,
    );
  }

  /// Axis label, with the localised weight suffix when the axis has one.
  String _title(BuildContext context, RadarAxis axis) {
    final double? weight = axis.weight;
    if (weight == null) return axis.label;
    return "custom.radar_chart_card.axis_weight".tr(
      namedArgs: <String, String>{"label": axis.label, "percent": _percent(context, weight)},
    );
  }

  /// One "title: percent" line per axis, then the comparison block.
  String _describe(BuildContext context, List<String> titles, List<double> values, List<double>? overlayValues) {
    final List<String> lines = _lines(context, titles, values);
    if (overlayValues != null) {
      lines
        ..add("custom.radar_chart_card.comparison".tr())
        ..addAll(_lines(context, titles, overlayValues));
    }
    return lines.join("\n");
  }

  List<String> _lines(BuildContext context, List<String> titles, List<double> values) {
    return <String>[
      for (int i = 0; i < titles.length; i++)
        "custom.radar_chart_card.axis_value".tr(
          namedArgs: <String, String>{"label": titles[i], "percent": _percent(context, values[i] / maxValue)},
        ),
    ];
  }

  /// [ratio] as a percentage for the ambient locale; an unknown locale falls
  /// back to intl's default.
  String _percent(BuildContext context, double ratio) {
    final String? tag = Localizations.maybeLocaleOf(context)?.toLanguageTag();
    final String? locale = Intl.verifiedLocale(tag, NumberFormat.localeExists, onFailure: (String _) => null);
    return NumberFormat.percentPattern(locale).format(ratio);
  }
}

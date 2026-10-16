// view.dart
//
// Tree of StepRangeChart: one semantics node summarising the scale, the
// labelled bands and every column over a 420 / 180 AspectRatio holding the
// painter. Colours are resolved here from
// the ColorScheme, StatusTones (band labels) and ValueBand, the text style
// from textTheme.labelSmall; the painter (widgets/step_range_painter.dart)
// reads no theme.

part of "index.dart";

/// Opacity of the envelope fill, applied to the line colour.
const double _kEnvelopeFillAlpha = 0.15;

/// Opacity of the envelope outline, applied to the line colour.
const double _kEnvelopeStrokeAlpha = 0.4;

/// Opacity of the selected-column halo, applied to the line colour.
const double _kHaloAlpha = 0.06;

/// Opacity of the captions of locked and valueless columns.
const double _kMutedAlpha = 0.5;

/// Opacity of the locked-column wash.
const double _kLockedWashAlpha = 0.9;

/// Value caption of locked and valueless columns.
const String _kNoValue = "—";

mixin _ViewMixin {
  Widget render(BuildContext context, StepRangeChart widget) {
    assert(widget.columns.isNotEmpty, "columns must not be empty");
    final int? requested = widget.selectedIndex;
    assert(
      requested == null || (requested >= 0 && requested < widget.columns.length),
      "selectedIndex must be within columns",
    );

    final ThemeData theme = Theme.of(context);
    final String Function(double value) format = widget.valueFormatter ?? _formatRounded;
    final int? selected = _effectiveSelection(widget);

    final _StepRangePainter painter = _StepRangePainter(
      scene: (
        columns: widget.columns,
        selectedIndex: selected,
        minValue: widget.minValue,
        maxValue: widget.maxValue,
        valueTexts: <String>[
          for (final StepRangeColumn column in widget.columns) _valueText(column, format),
        ],
        minText: format(widget.minValue),
        maxText: format(widget.maxValue),
        bands: <_BandPaint>[
          for (final ValueBand band in widget.bands)
            (
              from: band.from,
              to: band.to,
              color: band.resolveColor(context),
              label: band.label,
              labelColor: StatusTones.colorsOf(context, band.tone).foreground,
            ),
        ],
      ),
      palette: _palette(theme.colorScheme, widget.color),
      baseStyle: theme.textTheme.labelSmall ?? const TextStyle(),
      textDirection: Directionality.of(context),
    );

    return Semantics(
      container: true,
      label: _summary(widget, selected, format),
      child: AspectRatio(
        aspectRatio: _kViewWidth / _kViewHeight,
        child: CustomPaint(painter: painter),
      ),
    );
  }

  /// [StepRangeChart.selectedIndex] when it points at a valued, unlocked
  /// column; null otherwise.
  int? _effectiveSelection(StepRangeChart widget) {
    final int? index = widget.selectedIndex;
    if (index == null || index < 0 || index >= widget.columns.length) return null;
    final StepRangeColumn column = widget.columns[index];
    return column.locked || column.value == null ? null : index;
  }

  /// Formatted value, or "—" for locked and valueless columns.
  String _valueText(StepRangeColumn column, String Function(double value) format) {
    final double? value = column.value;
    return value == null ? _kNoValue : format(value);
  }

  /// Every painted colour, from the ColorScheme and the [color] override.
  _Palette _palette(ColorScheme cs, Color? color) {
    final Color line = color ?? cs.primary;
    return (
      line: line,
      envelopeFill: line.withValues(alpha: _kEnvelopeFillAlpha),
      envelopeStroke: line.withValues(alpha: _kEnvelopeStrokeAlpha),
      halo: line.withValues(alpha: _kHaloAlpha),
      grid: cs.outlineVariant,
      dotFill: cs.surface,
      label: cs.onSurfaceVariant,
      emphasized: cs.onSurface,
      muted: cs.onSurfaceVariant.withValues(alpha: _kMutedAlpha),
      lockedWash: cs.surfaceContainerHighest.withValues(alpha: _kLockedWashAlpha),
      lockGlyph: cs.onSurfaceVariant,
    );
  }

  /// `"<semanticLabel>. <scale>. <band>… <column>…"` for screen readers.
  /// An empty [StepRangeChart.semanticLabel] is skipped.
  String _summary(StepRangeChart widget, int? selected, String Function(double value) format) {
    final double min = widget.minValue;
    final double max = widget.maxValue;
    return <String>[
      if (widget.semanticLabel case final String title when title.isNotEmpty) title,
      "custom.step_range_chart.axis".tr(namedArgs: <String, String>{"min": format(min), "max": format(max)}),
      for (final ValueBand band in widget.bands)
        if (band.label case final String label when label.isNotEmpty && _bandVisible(band.from, band.to, min, max))
          "custom.step_range_chart.band".tr(
            namedArgs: <String, String>{
              "label": label,
              "from": format(math.max(band.from, min)),
              "to": format(math.min(band.to, max)),
            },
          ),
      for (int i = 0; i < widget.columns.length; i++)
        _columnSummary(widget.columns[i], selected: i == selected, format: format),
    ].join(". ");
  }

  /// One column entry: value / locked / unavailable, then range and
  /// selection, joined with ", ".
  String _columnSummary(
    StepRangeColumn column, {
    required bool selected,
    required String Function(double value) format,
  }) {
    final String sublabel = column.sublabel ?? "";
    final String name = sublabel.isEmpty ? column.label : "${column.label} ($sublabel)";
    if (column.locked) {
      return "custom.step_range_chart.locked".tr(namedArgs: <String, String>{"label": name});
    }
    final double? value = column.value;
    final double? low = column.low;
    final double? high = column.high;
    return <String>[
      if (value == null)
        "custom.step_range_chart.unavailable".tr(namedArgs: <String, String>{"label": name})
      else
        "custom.step_range_chart.value".tr(namedArgs: <String, String>{"label": name, "value": format(value)}),
      if (low != null && high != null)
        "custom.step_range_chart.range".tr(
          namedArgs: <String, String>{
            "low": format(math.min(low, high)),
            "high": format(math.max(low, high)),
          },
        ),
      if (selected) "custom.step_range_chart.selected".tr(),
    ].join(", ");
  }
}

/// Default [StepRangeChart.valueFormatter]: the value rounded to an integer.
String _formatRounded(double value) => value.round().toString();

// view.dart
//
// Tree of RangeEnvelopeBar: the painted bar (one semantics node summarising
// each series range and the marker), the caption row and the optional spread
// pill. Colours are resolved here from the ColorScheme and StatusTones, then
// injected into the painter.

part of "index.dart";

/// Height of the banded bar.
const double _barHeight = 22;

/// Space kept above the bar for the marker pill: the 3 dp gap plus the
/// 12.8 dp pill (9 dp text × 1.2 line height + 2 × 1 dp padding) fit in it.
const double _markerHeadroom = 16;

/// Space kept above the bar without a marker.
const double _plainHeadroom = 2;

/// Linear scale shared by the painter and the caption row.
typedef _ValueScale = ({double min, double max});

/// Position of [value] on [scale], as a fraction of the bar width in `0..1`.
double _fractionOf(_ValueScale scale, double value) {
  return ((value - scale.min) / (scale.max - scale.min)).clamp(0.0, 1.0);
}

mixin _ViewMixin {
  Widget render(BuildContext context, RangeEnvelopeBar widget) {
    assert(widget.primary.values.isNotEmpty, "primary.values must not be empty");
    assert(widget.secondary?.values.isNotEmpty ?? true, "secondary.values must not be empty");

    final bool insufficient = widget.primary.values.length < 2;
    final String? spreadLabel = widget.spreadLabel == null
        ? null
        : insufficient
            ? "custom.range_envelope_bar.insufficient_data".tr()
            : widget.spreadLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _bar(context, widget),
        const SizedBox(height: kDefaultPadding / 2),
        _ScaleCaptions(
          scale: (min: widget.min, max: widget.max),
          bands: widget.bands,
          minLabel: widget.formatValue(widget.min),
          maxLabel: widget.formatValue(widget.max),
        ),
        if (spreadLabel != null) ...<Widget>[
          const SizedBox(height: kDefaultPadding / 2),
          _SpreadPill(
            label: spreadLabel,
            tone: insufficient ? StatusTone.neutral : widget.spreadTone,
          ),
        ],
      ],
    );
  }

  Widget _bar(BuildContext context, RangeEnvelopeBar widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final RangeEnvelopeSeries? secondary = widget.secondary;
    final _MarkerPaint? marker = _markerPaint(context, widget);

    final _RangeEnvelopePainter painter = _RangeEnvelopePainter(
      scale: (min: widget.min, max: widget.max),
      trackColor: cs.surfaceContainerHighest,
      bands: <_BandPaint>[
        for (final ValueBand band in widget.bands)
          (from: band.from, to: band.to, color: band.resolveColor(context)),
      ],
      primary: (values: widget.primary.values, color: _seriesColor(context, widget.primary, cs.primary)),
      secondary: secondary == null
          ? null
          : (values: secondary.values, color: _seriesColor(context, secondary, cs.tertiary)),
      marker: marker,
      textDirection: Directionality.of(context),
    );

    return Semantics(
      container: true,
      label: _summary(widget, marker?.label),
      child: ExcludeSemantics(
        child: SizedBox(
          width: double.infinity,
          height: (marker == null ? _plainHeadroom : _markerHeadroom) + _barHeight,
          child: CustomPaint(painter: painter),
        ),
      ),
    );
  }

  /// Marker tick + pill: `cs.inverseSurface` fill, `cs.onInverseSurface`
  /// 9 / w800 text without tracking. Null when the bar has no marker.
  _MarkerPaint? _markerPaint(BuildContext context, RangeEnvelopeBar widget) {
    final double? value = widget.marker;
    if (value == null) return null;
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return (
      value: value,
      label: widget.markerLabel ?? widget.formatValue(value),
      color: cs.inverseSurface,
      textStyle: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: 0,
        color: cs.onInverseSurface,
      ),
    );
  }

  /// Series colour: explicit colour, else tone foreground, else [fallback].
  Color _seriesColor(BuildContext context, RangeEnvelopeSeries series, Color fallback) {
    final Color? color = series.color;
    if (color != null) return color;
    final StatusTone? tone = series.tone;
    return tone == null ? fallback : StatusTones.colorsOf(context, tone).foreground;
  }

  /// `"<series range>. <series range>. <marker text>"` for screen readers.
  String _summary(RangeEnvelopeBar widget, String? markerText) {
    final RangeEnvelopeSeries? secondary = widget.secondary;
    return <String>[
      _rangeText(widget, widget.primary),
      if (secondary != null) _rangeText(widget, secondary),
      ?markerText,
    ].join(". ");
  }

  String _rangeText(RangeEnvelopeBar widget, RangeEnvelopeSeries series) {
    return "custom.range_envelope_bar.semantics_range".tr(
      namedArgs: <String, String>{
        "label": series.label,
        "min": widget.formatValue(series.lowest),
        "max": widget.formatValue(series.highest),
      },
    );
  }
}

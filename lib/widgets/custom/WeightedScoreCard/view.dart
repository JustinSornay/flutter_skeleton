// view.dart
//
// Tree of WeightedScoreCard: a Material card holding the header row (score
// ring + donut slot), the optional alert chip, a divider and one slider row
// per component. Resolves the component colours, the localized strings and
// the percentages, then delegates to the private parts in widgets/.

part of "index.dart";

/// Diameter of the score ring and of the donut.
const double _headerSize = 88;

mixin _ViewMixin {
  Widget render(BuildContext context, _WeightedScoreCardState state) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final WeightedScoreCard widget = state.widget;
    final List<Color> colors = _componentColors(context, widget.components);
    // The last settled result, kept during a re-evaluation so the chip (and
    // the slider rows below it) stay put while the debounce fires.
    final WeightedScoreResult? result = state.lastResult;

    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                _ring(state),
                const SizedBox(width: kDefaultPadding * 3),
                Expanded(child: _donutSlot(context, state, colors)),
              ],
            ),
            if (result != null && result.score < widget.alertThreshold) ...<Widget>[
              const SizedBox(height: kDefaultPadding * 1.5),
              _AlertChip(
                text: widget.alertLabel ?? _defaultAlert(widget),
                semanticsLabel: "custom.weighted_score_card.alert_semantics".tr(),
              ),
            ],
            const SizedBox(height: kDefaultPadding * 2.5),
            Divider(color: cs.outlineVariant, height: 1),
            const SizedBox(height: kDefaultPadding * 2.5),
            for (int i = 0; i < widget.components.length; i++) _sliderRow(context, state, i, colors[i]),
          ],
        ),
      ),
    );
  }

  /// Score ring: "—" before a result or after an error, "…" while loading,
  /// the rounded score in its tone once loaded. Only a loaded score gets a
  /// screen-reader label; until then the donut slot announces the state.
  Widget _ring(_WeightedScoreCardState state) {
    final (String text, StatusTone? tone) = switch (state.evaluation) {
      Idle<WeightedScoreResult>() || LoadError<WeightedScoreResult>() => ("—", null),
      Loading<WeightedScoreResult>() => ("…", null),
      Loaded<WeightedScoreResult>(:final WeightedScoreResult data) => (
          "${(data.score * 100).round()}",
          state.widget._toneFor(data.score),
        ),
    };
    return _ScoreRing(
      text: text,
      tone: tone,
      size: _headerSize,
      semanticsLabel: tone == null
          ? null
          : "custom.weighted_score_card.score_semantics".tr(namedArgs: <String, String>{"value": text}),
    );
  }

  /// Donut + legend once loaded, a [Loader] while waiting, the error text
  /// after a failure.
  Widget _donutSlot(BuildContext context, _WeightedScoreCardState state, List<Color> colors) {
    return switch (state.evaluation) {
      Idle<WeightedScoreResult>() || Loading<WeightedScoreResult>() => const SizedBox(
          height: _headerSize,
          child: Center(child: Loader(size: 24)),
        ),
      LoadError<WeightedScoreResult>() => SizedBox(
          height: _headerSize,
          child: Center(
            child: Text(
              "custom.weighted_score_card.load_error".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      Loaded<WeightedScoreResult>(:final WeightedScoreResult data) => _ShareDonut(
          shares: _shares(state, data),
          colors: colors,
          legend: <String>[
            for (int i = 0; i < state.weights.length; i++)
              "${state.widget.components[i].label}  ${_percent(context, state.weights[i])}",
          ],
          size: _headerSize,
          duration: resolveMotion(context, PieChart.defaultDuration),
        ),
    };
  }

  Widget _sliderRow(BuildContext context, _WeightedScoreCardState state, int index, Color color) {
    final WeightedScoreComponent component = state.widget.components[index];
    return _WeightSliderRow(
      label: component.label,
      weight: state.weights[index],
      percent: _percent(context, state.weights[index]),
      color: color,
      labelWidth: state.widget.labelWidth,
      semanticsValue: (double value) => "custom.weighted_score_card.weight_semantics".tr(
        namedArgs: <String, String>{"label": component.label, "value": _percent(context, value)},
      ),
      onChanged: (double value) => state.onWeightChanged(index, value),
    );
  }

  /// Share of each component in the loaded score.
  List<double> _shares(_WeightedScoreCardState state, WeightedScoreResult result) {
    final List<double> scores = <double>[
      for (final WeightedScoreComponent component in state.widget.components) result.breakdown[component.id] ?? 0,
    ];
    return WeightedScoreMix.shares(state.weights, scores, result.score);
  }

  /// Component colour: explicit colour, else tone foreground, else the
  /// [WeightedScorePalette] cycle by index.
  List<Color> _componentColors(BuildContext context, List<WeightedScoreComponent> components) {
    final List<Color> palette = WeightedScorePalette.cycle(Theme.of(context).colorScheme);
    return <Color>[
      for (int i = 0; i < components.length; i++)
        components[i].color ?? _toneColor(context, components[i].tone) ?? palette[i % palette.length],
    ];
  }

  Color? _toneColor(BuildContext context, StatusTone? tone) {
    return tone == null ? null : StatusTones.colorsOf(context, tone).foreground;
  }

  String _defaultAlert(WeightedScoreCard widget) {
    return "custom.weighted_score_card.alert".tr(
      namedArgs: <String, String>{"threshold": "${(widget.alertThreshold * 100).round()}"},
    );
  }

  /// [value] (in `[0, 1]`) as a percentage for the ambient locale; an unknown
  /// locale falls back to intl's default.
  String _percent(BuildContext context, double value) {
    final String? locale = numberLocaleOf(context);
    return NumberFormat.percentPattern(locale).format(value);
  }
}

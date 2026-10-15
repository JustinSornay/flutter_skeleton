// view_model.dart
//
// _TrendChartState — recomputes the TrendChartGeometry whenever the widget
// changes, and resolves the default strings and the axis label formatters
// (intl for the ambient locale), so view.dart only maps state to widgets.

part of "index.dart";

final class _TrendChartState extends State<TrendChart> with _ViewMixin {
  /// Entry animation of the chart, before [resolveMotion].
  static const Duration _entryDuration = Duration(milliseconds: 500);

  late TrendChartGeometry _geometry;

  void _compute() {
    _geometry = TrendChartGeometry.compute(
      widget.points.map((TrendPoint point) => point.value).toList(growable: false),
      threshold: widget.threshold,
      minY: widget.minY,
      maxY: widget.maxY,
    );
  }

  String get _semanticLabel => widget.semanticLabel ?? "custom.trend_chart.semantics".tr();

  String get _emptyMessage => widget.emptyMessage ?? "custom.trend_chart.empty".tr();

  String get _insufficientDataMessage {
    return widget.insufficientDataMessage ?? "custom.trend_chart.insufficient_data".tr();
  }

  String get _thresholdLabel => widget.threshold?.label ?? "custom.trend_chart.threshold".tr();

  String get _crossingLabel {
    return widget.threshold?.crossingLabel ?? "custom.trend_chart.threshold_crossed".tr();
  }

  /// X label formatter: [TrendChart.xLabelBuilder], else `DateFormat.Md`
  /// for the ambient locale (intl's default when its data is not loaded).
  String Function(DateTime date) _xFormatter(BuildContext context) {
    final String Function(DateTime date)? custom = widget.xLabelBuilder;
    if (custom != null) return custom;
    final String? tag = Localizations.maybeLocaleOf(context)?.toLanguageTag();
    final String? locale = Intl.verifiedLocale(tag, DateFormat.localeExists, onFailure: (String _) => null);
    return DateFormat.Md(locale).format;
  }

  /// Y label formatter: [TrendChart.yLabelBuilder], else
  /// `NumberFormat.decimalPattern` for the ambient locale.
  String Function(double value) _yFormatter(BuildContext context) {
    final String Function(double value)? custom = widget.yLabelBuilder;
    if (custom != null) return custom;
    final String? tag = Localizations.maybeLocaleOf(context)?.toLanguageTag();
    final String? locale = Intl.verifiedLocale(tag, NumberFormat.localeExists, onFailure: (String _) => null);
    return NumberFormat.decimalPattern(locale).format;
  }

  @override
  void initState() {
    super.initState();
    _compute();
  }

  @override
  void didUpdateWidget(covariant TrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _compute();
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}

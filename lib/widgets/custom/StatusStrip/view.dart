// view.dart
//
// Tree of StatusStrip: the cell row (the available width split evenly), the
// comparison legend and the category / marker legend. Category colours and
// cell semantics labels are resolved here from StatusTones, the ColorScheme
// and the translations, then passed to the private parts in widgets/.

part of "index.dart";

/// Gap between two cells.
const double _cellGap = kDefaultPadding / 4;

/// Colours of one cell layer: background [fill], period [label] text and an
/// optional [border] (unknown values only).
typedef _CellColors = ({Color fill, Color label, Color? border});

mixin _ViewMixin<T> {
  Widget render(BuildContext context, StatusStrip<T> widget) {
    _assertLengths(widget);
    final List<_Divergence> divergences = _divergencesOf(widget.agreementSeries, widget.periodLabels.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return _row(context, widget, divergences, constraints.maxWidth);
          },
        ),
        if (widget.showLegend) ..._legends(context, widget, divergences),
      ],
    );
  }

  void _assertLengths(StatusStrip<T> widget) {
    final int count = widget.periodLabels.length;
    assert(count > 0, "periodLabels must not be empty");
    assert(widget.primary.values.length == count, "primary needs one value per period");
    assert((widget.comparison?.values.length ?? count) == count, "comparison needs one value per period");
    assert((widget.periodSemanticLabels?.length ?? count) == count, "periodSemanticLabels needs one label per period");
    assert(
      widget.agreementSeries?.every((List<T> row) => row.length == count) ?? true,
      "every agreementSeries row needs one value per period",
    );
  }

  Widget _row(BuildContext context, StatusStrip<T> widget, List<_Divergence> divergences, double maxWidth) {
    assert(maxWidth.isFinite, "StatusStrip needs a bounded width");
    final int count = widget.periodLabels.length;
    final double gap = maxWidth >= _cellGap * (count - 1) ? _cellGap : 0;
    final double cellWidth = math.max<double>(0, (maxWidth - gap * (count - 1)) / count);

    return SizedBox(
      height: widget.cellHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int index = 0; index < count; index++)
            Padding(
              padding: EdgeInsetsDirectional.only(start: index == 0 ? 0 : gap),
              child: _cell(context, widget, index, divergences[index], cellWidth),
            ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, StatusStrip<T> widget, int index, _Divergence divergence, double width) {
    final StatusStripCategory<T>? category = _categoryOf(widget.categories, widget.primary.values[index]);
    final List<T>? comparisonValues = widget.comparison?.values;
    final StatusStripCategory<T>? compared =
        comparisonValues == null ? null : _categoryOf(widget.categories, comparisonValues[index]);

    return _StripCell(
      width: width,
      height: widget.cellHeight,
      label: widget.periodLabels[index],
      colors: _colorsOf(context, category),
      comparison: comparisonValues == null ? null : _colorsOf(context, compared),
      divergence: divergence,
      semanticsLabel: _cellSemantics(
        widget.periodSemanticLabels?[index] ?? widget.periodLabels[index],
        _statusText(category),
        comparisonValues == null ? null : _statusText(compared),
        divergence,
      ),
    );
  }

  /// Category fill (`color`, else tone `container`) and label (tone
  /// `onContainer`), no border; unknown values → an empty-looking layer:
  /// `cs.surface` fill, `cs.outlineVariant` border, `cs.onSurfaceVariant`
  /// label (distinct from the neutral tone `container`).
  _CellColors _colorsOf(BuildContext context, StatusStripCategory<T>? category) {
    if (category == null) {
      final ColorScheme cs = Theme.of(context).colorScheme;
      return (fill: cs.surface, label: cs.onSurfaceVariant, border: cs.outlineVariant);
    }
    final ToneColors tone = StatusTones.colorsOf(context, category.tone);
    return (fill: category.color ?? tone.container, label: tone.onContainer, border: null);
  }

  String _statusText(StatusStripCategory<T>? category) {
    return category?.label ?? "custom.status_strip.unknown".tr();
  }

  /// `"{period}: {status}"` (or the comparison form), then the marker text
  /// joined by `custom.status_strip.cell_marker` (`"{cell}, {marker}"`).
  String _cellSemantics(String period, String status, String? compared, _Divergence divergence) {
    final String cell = compared == null
        ? "custom.status_strip.cell".tr(namedArgs: <String, String>{"period": period, "status": status})
        : "custom.status_strip.cell_comparison".tr(
            namedArgs: <String, String>{"period": period, "primary": status, "comparison": compared},
          );
    final String? marker = switch (divergence) {
      _Divergence.none => null,
      _Divergence.partial => "custom.status_strip.partial_agreement".tr(),
      _Divergence.full => "custom.status_strip.full_disagreement".tr(),
    };
    if (marker == null) return cell;
    return "custom.status_strip.cell_marker".tr(namedArgs: <String, String>{"cell": cell, "marker": marker});
  }

  List<Widget> _legends(BuildContext context, StatusStrip<T> widget, List<_Divergence> divergences) {
    final StatusStripSeries<T>? comparison = widget.comparison;
    final List<StatusStripCategory<T>> present = _presentCategories(
      widget.categories,
      <List<T>>[widget.primary.values, ?comparison?.values],
    );
    final bool partial = divergences.contains(_Divergence.partial);
    final bool full = divergences.contains(_Divergence.full);

    return <Widget>[
      if (comparison != null) ...<Widget>[
        const SizedBox(height: kDefaultPadding),
        _ComparisonLegend(
          primaryLabel: _seriesName(widget.primary.label, comparison: false),
          comparisonLabel: _seriesName(comparison.label, comparison: true),
        ),
      ],
      if (present.isNotEmpty || partial || full) ...<Widget>[
        const SizedBox(height: kDefaultPadding),
        _CategoryLegend(
          entries: <_LegendEntry>[
            for (final StatusStripCategory<T> category in present)
              (label: category.label, color: _colorsOf(context, category).fill),
          ],
          showPartial: partial,
          showFull: full,
        ),
      ],
    ];
  }

  /// `"{label} (réf.)"` / `"{label} (test)"`, or the built-in series name
  /// when [label] is null.
  String _seriesName(String? label, {required bool comparison}) {
    if (label == null) {
      return comparison ? "custom.status_strip.comparison".tr() : "custom.status_strip.reference".tr();
    }
    final Map<String, String> args = <String, String>{"label": label};
    return comparison
        ? "custom.status_strip.comparison_labelled".tr(namedArgs: args)
        : "custom.status_strip.reference_labelled".tr(namedArgs: args);
  }
}

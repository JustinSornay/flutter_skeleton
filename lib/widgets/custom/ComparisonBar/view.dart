// view.dart
//
// Tree of ComparisonBar: one semantics node over a row made of the label
// column, the track (widgets/comparison_track.dart) and the readout
// (widgets/comparison_readout.dart). Default colours, the direction tone and
// the localized strings are resolved here.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, ComparisonBar widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color baselineColor = widget.baselineColor ?? cs.onSurfaceVariant;
    final Color comparisonColor = widget.comparisonColor ?? cs.primary;
    final bool unchanged = widget._isUnchanged;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: _semanticsLabel(widget),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
        child: Row(
          children: <Widget>[
            SizedBox(width: widget.labelWidth, child: _labels(context, widget)),
            const SizedBox(width: kDefaultPadding),
            Expanded(
              child: _ComparisonTrack(
                baselinePosition: widget._baselinePosition,
                comparisonPosition: widget._comparisonPosition,
                baselineColor: baselineColor,
                comparisonColor: comparisonColor,
                showSegment: !unchanged,
              ),
            ),
            const SizedBox(width: kDefaultPadding),
            SizedBox(
              width: widget.valueWidth,
              child: _ComparisonReadout(
                parts: _readoutParts(unchanged),
                baselineText: widget.formatValue(widget.baselineValue),
                comparisonText: widget.formatValue(widget.comparisonValue),
                baselineColor: baselineColor,
                comparisonColor: comparisonColor,
                connectorTone: unchanged
                    ? null
                    : widget._isBetter
                        ? StatusTone.success
                        : StatusTone.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// [ComparisonBar.label] (11 / w700) over the optional sublabel (9 / w600).
  Widget _labels(BuildContext context, ComparisonBar widget) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final TextStyle base = (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(height: 1.15);
    final String? sublabel = widget.sublabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          widget.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: base.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        if (sublabel != null)
          Text(
            sublabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: base.copyWith(fontSize: 9, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
          ),
      ],
    );
  }

  /// Runs of the localized readout template, or of its built-in fallback
  /// when the key is not translated.
  List<ComparisonBarReadoutPart> _readoutParts(bool unchanged) {
    if (unchanged) {
      return ComparisonBarReadout.resolve(
        "custom.comparison_bar.readout_unchanged".tr(),
        ComparisonBarReadout.unchangedFallback,
        const <String>{ComparisonBarReadout.value},
      );
    }
    return ComparisonBarReadout.resolve(
      "custom.comparison_bar.readout".tr(),
      ComparisonBarReadout.changedFallback,
      const <String>{ComparisonBarReadout.baseline, ComparisonBarReadout.comparison},
    );
  }

  /// Localized summary read by screen readers instead of the glyphs.
  String _semanticsLabel(ComparisonBar widget) {
    final String? sublabel = widget.sublabel;
    final String name = sublabel == null ? widget.label : "${widget.label} ($sublabel)";
    final String from = widget.formatValue(widget.baselineValue);
    if (widget._isUnchanged) {
      return "custom.comparison_bar.semantics_unchanged".tr(
        namedArgs: <String, String>{"label": name, "value": from},
      );
    }
    final Map<String, String> args = <String, String>{
      "label": name,
      "from": from,
      "to": widget.formatValue(widget.comparisonValue),
    };
    return widget._isBetter
        ? "custom.comparison_bar.semantics_better".tr(namedArgs: args)
        : "custom.comparison_bar.semantics_worse".tr(namedArgs: args);
  }
}

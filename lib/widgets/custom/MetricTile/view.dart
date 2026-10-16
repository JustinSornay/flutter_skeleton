// view.dart
//
// Tree of MetricTile: one semantics node over a shrink-wrapping container
// (filled or outlined) holding the MetricLabel header, the value line
// (widgets/value_line.dart) and the optional toned caption, both limited to
// maxLines. Colours come from the ColorScheme and StatusTones only.

part of "index.dart";

/// Corner radius of the tile.
const double _radius = 10;

/// Vertical gap between the header, the value line and the caption (2 dp).
const double _lineGap = kDefaultPadding / 4;

/// Placeholder shown instead of a missing value.
const String _noValue = "—";

/// Ellipsis under a line limit; none without one, where an ellipsis would
/// still cut the text to a single line.
TextOverflow? _overflow(int? maxLines) {
  return maxLines == null ? null : TextOverflow.ellipsis;
}

mixin _ViewMixin {
  Widget render(BuildContext context, MetricTile widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String? caption = _nonEmpty(widget.caption);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: _semanticsLabel(widget, caption),
      child: IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 1.5, vertical: kDefaultPadding),
          decoration: BoxDecoration(
            color: widget.outlined ? cs.surfaceContainerHighest : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(_radius),
            border: widget.outlined ? Border.all(color: cs.outlineVariant) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MetricLabel(label: widget.label, icon: widget.icon),
              const SizedBox(height: _lineGap),
              _ValueLine(
                value: _nonEmpty(widget.value),
                unit: _nonEmpty(widget.unit),
                tone: widget.valueTone,
                maxLines: widget.maxLines,
              ),
              if (caption != null) ...<Widget>[
                const SizedBox(height: _lineGap),
                _caption(context, caption, widget.captionTone, widget.maxLines),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _caption(BuildContext context, String caption, StatusTone tone, int? maxLines) {
    return Text(
      caption,
      maxLines: maxLines,
      overflow: _overflow(maxLines),
      style: TextStyle(
        fontSize: 10,
        fontWeight: tone == StatusTone.neutral ? FontWeight.w400 : FontWeight.w700,
        color: StatusTones.colorsOf(context, tone).foreground,
      ),
    );
  }

  /// [semanticsLabel], or "label, value unit, caption" (the no-value key
  /// replaces a missing value; a missing unit or caption is skipped).
  String _semanticsLabel(MetricTile widget, String? caption) {
    final String? custom = _nonEmpty(widget.semanticsLabel);
    if (custom != null) return custom;

    final String? value = _nonEmpty(widget.value);
    final String? unit = _nonEmpty(widget.unit);
    final String spoken = value == null
        ? "custom.metric_tile.no_value".tr()
        : unit == null
            ? value
            : "$value $unit";
    return <String>[widget.label, spoken, ?caption].join(", ");
  }

  String? _nonEmpty(String? text) {
    return text == null || text.isEmpty ? null : text;
  }
}

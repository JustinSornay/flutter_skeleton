// view.dart
//
// Tree of ThumbnailMetricCard: one merged semantics node (a button when
// tappable) over a bordered Material card holding a single row — thumbnail,
// title block, value columns and the optional StatusPill change badge.
// Colours come from the ColorScheme and StatusTones only.

part of "index.dart";

/// Corner radius of the card.
const double _cardRadius = 16;

/// Inner padding of the card (12 dp).
const double _cardPadding = kDefaultPadding * 1.5;

/// Gap between the thumbnail and the title block (12 dp).
const double _thumbnailGap = kDefaultPadding * 1.5;

/// Gap before each value column and before the badge (8 dp).
const double _columnGap = kDefaultPadding;

/// [value], or null when it is null or empty.
String? _nonEmpty(String? value) {
  return value == null || value.isEmpty ? null : value;
}

mixin _ViewMixin {
  Widget render(BuildContext context, ThumbnailMetricCard widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final BorderRadius radius = BorderRadius.circular(_cardRadius);
    final VoidCallback? onTap = widget.onTap;
    final Widget content = Padding(
      padding: const EdgeInsets.all(_cardPadding),
      child: _row(context, widget),
    );

    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        child: Material(
          color: cs.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: cs.outlineVariant)),
          child: onTap == null ? content : InkWell(onTap: onTap, borderRadius: radius, child: content),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, ThumbnailMetricCard widget) {
    final String? delta = _nonEmpty(widget.delta);

    return Row(
      children: <Widget>[
        _Thumbnail(image: widget.image, placeholderIcon: widget.placeholderIcon),
        const SizedBox(width: _thumbnailGap),
        Expanded(child: _titles(context, widget)),
        for (final ThumbnailMetric metric in widget.metrics) ...<Widget>[
          const SizedBox(width: _columnGap),
          _MetricColumn(metric: metric),
        ],
        if (delta != null) ...<Widget>[
          const SizedBox(width: _columnGap),
          StatusPill(
            label: delta,
            tone: widget.deltaTone,
            dense: true,
            semanticsLabel: _nonEmpty(widget.deltaSemanticsLabel) ??
                "custom.thumbnail_metric_card.delta".tr(namedArgs: <String, String>{"value": delta}),
          ),
        ],
      ],
    );
  }

  Widget _titles(BuildContext context, ThumbnailMetricCard widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String? subtitle = _nonEmpty(widget.subtitle);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cs.onSurface),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
          ),
      ],
    );
  }
}

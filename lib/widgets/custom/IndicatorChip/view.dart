// view.dart
//
// Tree of IndicatorChip: the tinted rounded chip (icon + label + optional
// percentage), its own semantics node (label + tooltip) and, when a tooltip
// is set, the tap Tooltip with a 48 dp hit area. Colours come from
// StatusTones (or the colour override) only.

part of "index.dart";

/// Opacity of the fill derived from the foreground colour. 6 % keeps every
/// tone's text at >= 4.5:1 on `cs.surface` … `cs.surfaceContainerHighest` in
/// both themes (12 % drops light danger to 4.1:1 on the highest container).
const double _fillAlpha = 0.06;

/// Opacity of the border derived from the foreground colour.
const double _borderAlpha = 0.30;

/// Corner radius: a chip (8), not a pill (999).
const double _radius = 8;

/// Leading icon size.
const double _iconSize = 14;

/// Gap between the icon and the text (6 dp).
const double _iconGap = kDefaultPadding * 0.75;

/// 10 / 6 dp, the compact chip padding.
const EdgeInsets _padding = EdgeInsets.symmetric(
  horizontal: kDefaultPadding * 1.25,
  vertical: kDefaultPadding * 0.75,
);

/// How long the tap tooltip stays visible.
const Duration _tooltipShowDuration = Duration(seconds: 5);

mixin _ViewMixin {
  Widget render(BuildContext context, IndicatorChip widget) {
    final String text = _visibleText(context, widget);
    final String? tooltip = widget.tooltip;
    final bool hasTooltip = tooltip != null && tooltip.isNotEmpty;

    // Own node (`container`), so the label never merges into an enclosing
    // node; it carries the tooltip itself, hence `excludeFromSemantics` on
    // the Tooltip. The Center keeps the chip compact under tight constraints,
    // with or without a tooltip.
    final Widget chip = Center(
      widthFactor: 1,
      heightFactor: 1,
      child: Semantics(
        container: true,
        label: widget.semanticsLabel ?? text,
        tooltip: hasTooltip ? tooltip : null,
        excludeSemantics: true,
        child: _chip(context, widget, text),
      ),
    );
    if (!hasTooltip) return chip;

    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      waitDuration: Duration.zero,
      showDuration: _tooltipShowDuration,
      excludeFromSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: kMinTapTarget,
          minHeight: kMinTapTarget,
        ),
        child: chip,
      ),
    );
  }

  Widget _chip(BuildContext context, IndicatorChip widget, String text) {
    final ThemeData theme = Theme.of(context);
    final Color foreground = widget.color ?? StatusTones.colorsOf(context, widget.tone).foreground;
    final TextStyle baseStyle = theme.textTheme.labelMedium ?? const TextStyle(fontSize: 12);

    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: _fillAlpha),
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: foreground.withValues(alpha: _borderAlpha)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.icon != null) ...<Widget>[
            Icon(widget.icon, size: _iconSize, color: foreground),
            const SizedBox(width: _iconGap),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: baseStyle.copyWith(color: foreground, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// [IndicatorChip.label], followed by " (55 %)" when a ratio is set.
  String _visibleText(BuildContext context, IndicatorChip widget) {
    final double? ratio = widget.ratio;
    if (ratio == null) return widget.label;
    return "${widget.label} (${_percent(context, ratio)})";
  }

  /// [value] (already in `[0, 1]`) as a percentage for the ambient locale;
  /// an unknown locale falls back to intl's default.
  String _percent(BuildContext context, double value) {
    final String? locale = numberLocaleOf(context);
    return NumberFormat.percentPattern(locale).format(value);
  }
}

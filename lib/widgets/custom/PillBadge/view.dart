// view.dart
//
// Tree of PillBadge: the rounded pill (icon + label), its single semantics
// node and, when a tooltip is set, the tap Tooltip with a 48 dp hit area.
// Colours come from the ColorScheme and StatusTones only.

part of "index.dart";

/// Opacity of the default translucent `cs.surface` fill.
const double _translucentAlpha = 0.72;

/// Gap between the icon and the label (6 dp).
const double _iconGap = kDefaultPadding * 0.75;

const EdgeInsets _padding = EdgeInsets.symmetric(
  horizontal: kDefaultPadding * 1.5,
  vertical: kDefaultPadding,
);

const EdgeInsets _densePadding = EdgeInsets.symmetric(
  horizontal: kDefaultPadding,
  vertical: kDefaultPadding / 2,
);

mixin _ViewMixin {
  Widget render(BuildContext context, PillBadge widget) {
    final String? semanticsLabel = widget.semanticsLabel;
    final Widget pill = Semantics(
      label: (semanticsLabel == null || semanticsLabel.isEmpty) ? widget.label : semanticsLabel,
      excludeSemantics: true,
      child: _pill(context, widget),
    );

    final String? tooltip = widget.tooltip;
    if (tooltip == null || tooltip.isEmpty) return pill;

    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: kMinTapTarget,
          minHeight: kMinTapTarget,
        ),
        child: Center(widthFactor: 1, heightFactor: 1, child: pill),
      ),
    );
  }

  Widget _pill(BuildContext context, PillBadge widget) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Color foreground = widget.color ?? StatusTones.colorsOf(context, widget.tone).foreground;
    final Color background = widget.backgroundColor ??
        (widget.outlined ? cs.surfaceContainerHigh : cs.surface.withValues(alpha: _translucentAlpha));
    final TextStyle baseStyle = theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11);

    return Container(
      padding: widget.dense ? _densePadding : _padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: widget.outlined ? Border.all(color: cs.outlineVariant) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.icon != null) ...<Widget>[
            Icon(widget.icon, size: 14, color: foreground),
            const SizedBox(width: _iconGap),
          ],
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: baseStyle.copyWith(color: foreground, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

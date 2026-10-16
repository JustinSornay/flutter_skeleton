// view.dart
//
// Tree of PillLink: a TextButton styled as a translucent cs.primary pill
// (StadiumBorder, 28 / 24 dp) with a padded 48 dp hit area, holding one
// semantics label over the icon + label + arrow row.

part of "index.dart";

/// Opacity of `cs.primary` for the pill fill.
const double _fillAlpha = 0.08;

/// Opacity of `cs.primary` for the 1 dp border.
const double _borderAlpha = 0.20;

/// Opacity of `cs.primary` for the trailing arrow.
const double _arrowAlpha = 0.6;

/// Gap between the icon, the label and the arrow.
const double _gap = kDefaultPadding / 2;

/// Dimensions of one [PillLinkSize].
final class _PillMetrics {
  final double height;
  final double iconSize;
  final double arrowSize;
  final double fontSize;
  final EdgeInsetsDirectional padding;

  const _PillMetrics({
    required this.height,
    required this.iconSize,
    required this.arrowSize,
    required this.fontSize,
    required this.padding,
  });
}

const _PillMetrics _standardMetrics = _PillMetrics(
  height: 28,
  iconSize: 14,
  arrowSize: 12,
  fontSize: 11,
  padding: EdgeInsetsDirectional.only(start: kDefaultPadding * 1.25, end: kDefaultPadding * 1.5),
);

const _PillMetrics _compactMetrics = _PillMetrics(
  height: 24,
  iconSize: 12,
  arrowSize: 10,
  fontSize: 10,
  padding: EdgeInsetsDirectional.only(start: kDefaultPadding, end: kDefaultPadding * 1.25),
);

mixin _ViewMixin {
  Widget render(BuildContext context, PillLink widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final _PillMetrics metrics = switch (widget.size) {
      PillLinkSize.standard => _standardMetrics,
      PillLinkSize.compact => _compactMetrics,
    };
    final String label = widget.label ?? "custom.pill_link.learn_more".tr();

    return TextButton(
      onPressed: widget.onPressed,
      style: TextButton.styleFrom(
        foregroundColor: cs.primary,
        backgroundColor: cs.primary.withValues(alpha: _fillAlpha),
        side: BorderSide(color: cs.primary.withValues(alpha: _borderAlpha)),
        shape: const StadiumBorder(),
        minimumSize: Size(0, metrics.height),
        padding: metrics.padding,
        // Standard density keeps the 28 / 24 dp pill and the 48 dp hit area
        // on desktop, where the adaptive density would shrink both.
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: Semantics(
        label: widget.semanticsLabel ?? label,
        excludeSemantics: true,
        child: _content(context, widget, metrics, label),
      ),
    );
  }

  Widget _content(BuildContext context, PillLink widget, _PillMetrics metrics, String label) {
    final ThemeData theme = Theme.of(context);
    final Color color = theme.colorScheme.primary;
    final TextStyle style = (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
      fontSize: metrics.fontSize,
      fontWeight: FontWeight.w700,
      color: color,
    );
    final IconData? icon = widget.icon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: metrics.iconSize, color: color),
          const SizedBox(width: _gap),
        ],
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
        ),
        const SizedBox(width: _gap),
        Icon(
          Icons.arrow_forward_rounded,
          size: metrics.arrowSize,
          color: color.withValues(alpha: _arrowAlpha),
        ),
      ],
    );
  }
}

// view.dart
//
// Tree of MetricLabel: one semantics node (original casing) over a row with
// the optional 12 dp icon and the upper-cased label. Colours come from the
// ColorScheme only.

part of "index.dart";

/// Size of the leading icon.
const double _iconSize = 12;

/// Gap between the icon and the label (4 dp).
const double _iconGap = kDefaultPadding / 2;

mixin _ViewMixin {
  Widget render(BuildContext context, MetricLabel widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      label: widget.label,
      excludeSemantics: true,
      child: Row(
        children: <Widget>[
          if (widget.icon != null) ...<Widget>[
            Icon(widget.icon, size: _iconSize, color: cs.onSurfaceVariant),
            const SizedBox(width: _iconGap),
          ],
          Expanded(
            child: Text(
              widget.label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// strip_cell.dart
//
// Private cell of StatusStrip: the category fill (or two stacked halves in
// comparison mode; an unknown value is an outlined empty layer), the centred
// period label, and the agreement marker (corner dot scaled to fit the cell,
// or dashed outline). One semantics node per cell.

part of "../index.dart";

final class _StripCell extends StatelessWidget {
  /// Cell width.
  final double width;

  /// Cell height (the row height), used to fit the corner dot.
  final double height;

  /// Period label drawn in the centre.
  final String label;

  /// Layer of the whole cell (top half in comparison mode) and label colour.
  final _CellColors colors;

  /// Layer of the bottom half; null → single layer. Its label colour is
  /// unused.
  final _CellColors? comparison;

  /// Agreement marker drawn over the cell.
  final _Divergence divergence;

  /// Text read by screen readers instead of the label.
  final String semanticsLabel;

  const _StripCell({
    required this.width,
    required this.height,
    required this.label,
    required this.colors,
    required this.comparison,
    required this.divergence,
    required this.semanticsLabel,
  });

  static const double _radius = 3;
  static const double _minFontSize = 7;
  static const double _fontRatio = 0.32;
  static const double _borderWidth = 1;

  /// Inset of the corner dot from the end and bottom edges.
  static const double _dotInset = kDefaultPadding / 4;

  @override
  Widget build(BuildContext context) {
    // Dot at most half, inset at most a quarter of the shortest side: the
    // dot always stays inside the cell.
    final double side = math.min(width, height);
    final double dotInset = math.min(_dotInset, side / 4);
    return Semantics(
      container: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: <Widget>[
            _background(),
            Center(child: _label(context)),
            if (divergence == _Divergence.full)
              CustomPaint(painter: _DashedOutlinePainter(color: Theme.of(context).colorScheme.error)),
            if (divergence == _Divergence.partial)
              PositionedDirectional(
                end: dotInset,
                bottom: dotInset,
                child: _PartialMarker(size: math.min(_PartialMarker.maxSize, side / 2)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _background() {
    final _CellColors? lower = comparison;
    if (lower == null) return _layer(colors, BorderRadius.circular(_radius));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(child: _layer(colors, const BorderRadius.vertical(top: Radius.circular(_radius)))),
        Expanded(child: _layer(lower, const BorderRadius.vertical(bottom: Radius.circular(_radius)))),
      ],
    );
  }

  /// One fill layer, outlined when [layer] has a border colour.
  Widget _layer(_CellColors layer, BorderRadius radius) {
    final Color? border = layer.border;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: layer.fill,
        border: border == null ? null : Border.all(color: border, width: _borderWidth),
        borderRadius: radius,
      ),
    );
  }

  /// Label at `max(7, width × 0.32)` px, scaled down when it does not fit.
  Widget _label(BuildContext context) {
    final TextStyle style = (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(
      fontSize: math.max(_minFontSize, width * _fontRatio),
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      color: colors.label,
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, style: style, maxLines: 1, softWrap: false),
    );
  }
}

// step_range_painter.dart
//
// Private painter of StepRangeChart. Geometry is authored in a fixed
// 420 × 180 design viewport and scaled onto the real size. Paint order:
// bands → column grid → selected halo → envelopes → locked masks → step
// line → dots → value axis (band labels, bounds) → column captions. Every
// colour and the base text style are resolved by view.dart and injected
// here; caption sizes, weights and inks come from StepRangeCaptions
// (controllers/caption_style.dart). The painter reads no theme.

part of "../index.dart";

/// Width of the design viewport.
const double _kViewWidth = 420;

/// Height of the design viewport.
const double _kViewHeight = 180;

/// Plot area, in viewport units.
const double _kPlotLeft = 40;
const double _kPlotRight = 410;
const double _kPlotTop = 14;
const double _kPlotBottom = 134;

/// Right edge and width of the value-axis labels in the gutter.
const double _kGutterRight = 34;
const double _kGutterWidth = 30;

/// Vertical centres of the column captions.
const double _kNameY = 148;
const double _kSublabelY = 159;
const double _kValueY = 173;

/// A band resolved for painting.
typedef _BandPaint = ({double from, double to, Color color, String? label, Color labelColor});

/// Every colour the painter uses.
typedef _Palette = ({
  Color line,
  Color envelopeFill,
  Color envelopeStroke,
  Color halo,
  Color grid,
  Color dotFill,
  Color label,
  Color emphasized,
  Color muted,
  Color lockedWash,
  Color lockGlyph,
});

/// The chart content resolved for painting. [selectedIndex] is already null
/// when it pointed at a locked or valueless column; [valueTexts] holds one
/// caption per column ("—" without a value).
typedef _Scene = ({
  List<StepRangeColumn> columns,
  int? selectedIndex,
  double minValue,
  double maxValue,
  List<String> valueTexts,
  String minText,
  String maxText,
  List<_BandPaint> bands,
});

/// Left and right edges of one column, in viewport units.
typedef _Slot = ({double left, double right});

/// Whether the band [from]..[to] overlaps the value axis [min]..[max]; a
/// band outside it is neither painted nor announced.
bool _bandVisible(double from, double to, double min, double max) => to > min && from < max;

final class _StepRangePainter extends CustomPainter {
  final _Scene scene;
  final _Palette palette;

  /// Base of every caption (`textTheme.labelSmall`).
  final TextStyle baseStyle;

  final TextDirection textDirection;

  _StepRangePainter({
    required this.scene,
    required this.palette,
    required this.baseStyle,
    required this.textDirection,
  });

  static const double _gridWidth = 0.5;
  static const double _lineWidth = 2.5;
  static const double _dotRadius = 3.5;
  static const double _dotRingWidth = 2;
  static const double _selectedDotRadius = 4.5;
  static const double _selectedRingWidth = 2.5;
  static const double _lockGlyphSize = 18;
  static const IconData _lockIcon = Icons.lock_outline_rounded;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(size.width / _kViewWidth, size.height / _kViewHeight);
    final List<_Slot> slots = _slots();
    _paintBands(canvas);
    _paintGrid(canvas, slots);
    _paintHalo(canvas, slots);
    _paintEnvelopes(canvas, slots);
    _paintLocked(canvas, slots);
    _paintStepLine(canvas, slots);
    _paintDots(canvas, slots);
    _paintValueAxis(canvas);
    _paintCaptions(canvas, slots);
    canvas.restore();
  }

  /// Column extents: the plot width shared by `flex`.
  List<_Slot> _slots() {
    final List<StepRangeColumn> columns = scene.columns;
    final int total = columns.fold<int>(0, (int sum, StepRangeColumn column) => sum + column.flex);
    final double unit = (_kPlotRight - _kPlotLeft) / total;
    final List<_Slot> slots = <_Slot>[];
    int start = 0;
    for (final StepRangeColumn column in columns) {
      final int end = start + column.flex;
      slots.add((left: _kPlotLeft + start * unit, right: _kPlotLeft + end * unit));
      start = end;
    }
    return slots;
  }

  /// Viewport y of [value], clamped to the plot.
  double _y(double value) {
    final double t = ((value - scene.minValue) / (scene.maxValue - scene.minValue)).clamp(0.0, 1.0);
    return _kPlotBottom - t * (_kPlotBottom - _kPlotTop);
  }

  Rect _columnRect(_Slot slot) => Rect.fromLTRB(slot.left, _kPlotTop, slot.right, _kPlotBottom);

  /// Whether [band] overlaps the value axis.
  bool _visible(_BandPaint band) => _bandVisible(band.from, band.to, scene.minValue, scene.maxValue);

  void _paintBands(Canvas canvas) {
    for (final _BandPaint band in scene.bands) {
      if (!_visible(band)) continue;
      canvas.drawRect(
        Rect.fromLTRB(_kPlotLeft, _y(band.to), _kPlotRight, _y(band.from)),
        Paint()..color = band.color,
      );
    }
  }

  void _paintGrid(Canvas canvas, List<_Slot> slots) {
    final Paint paint = Paint()
      ..color = palette.grid
      ..strokeWidth = _gridWidth;
    for (int i = 1; i < slots.length; i++) {
      canvas.drawLine(Offset(slots[i].left, _kPlotTop), Offset(slots[i].left, _kPlotBottom), paint);
    }
  }

  void _paintHalo(Canvas canvas, List<_Slot> slots) {
    final int? selected = scene.selectedIndex;
    if (selected == null) return;
    canvas.drawRect(_columnRect(slots[selected]), Paint()..color = palette.halo);
  }

  void _paintEnvelopes(Canvas canvas, List<_Slot> slots) {
    for (int i = 0; i < slots.length; i++) {
      final double? low = scene.columns[i].low;
      final double? high = scene.columns[i].high;
      if (low == null || high == null) continue;
      final Rect rect = Rect.fromLTRB(
        slots[i].left,
        _y(math.max(low, high)),
        slots[i].right,
        _y(math.min(low, high)),
      );
      canvas.drawRect(rect, Paint()..color = palette.envelopeFill);
      canvas.drawRect(rect, _stroke(palette.envelopeStroke, _gridWidth));
    }
  }

  void _paintLocked(Canvas canvas, List<_Slot> slots) {
    for (int i = 0; i < slots.length; i++) {
      if (!scene.columns[i].locked) continue;
      final Rect rect = _columnRect(slots[i]);
      canvas.drawRect(rect, Paint()..color = palette.lockedWash);
      canvas.drawRect(rect, _stroke(palette.grid, _gridWidth));
      _drawText(
        canvas,
        String.fromCharCode(_lockIcon.codePoint),
        TextStyle(
          fontSize: _lockGlyphSize,
          fontFamily: _lockIcon.fontFamily,
          package: _lockIcon.fontPackage,
          color: palette.lockGlyph,
        ),
        rect.center,
        maxWidth: rect.width,
      );
    }
  }

  /// One flat segment per valued column across its width; a vertical
  /// connector joins it to the previous column when that one has a value.
  void _paintStepLine(Canvas canvas, List<_Slot> slots) {
    final Path path = Path();
    bool connected = false;
    for (int i = 0; i < slots.length; i++) {
      final double? value = scene.columns[i].value;
      if (value == null) {
        connected = false;
        continue;
      }
      final double y = _y(value);
      if (connected) {
        path.lineTo(slots[i].left, y);
      } else {
        path.moveTo(slots[i].left, y);
      }
      path.lineTo(slots[i].right, y);
      connected = true;
    }
    canvas.drawPath(
      path,
      _stroke(palette.line, _lineWidth)
        ..strokeCap = StrokeCap.butt
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  void _paintDots(Canvas canvas, List<_Slot> slots) {
    for (int i = 0; i < slots.length; i++) {
      final double? value = scene.columns[i].value;
      if (value == null) continue;
      final Offset center = Offset((slots[i].left + slots[i].right) / 2, _y(value));
      if (i == scene.selectedIndex) {
        canvas.drawCircle(center, _selectedDotRadius, Paint()..color = palette.line);
        canvas.drawCircle(center, _selectedDotRadius, _stroke(palette.dotFill, _selectedRingWidth));
      } else {
        canvas.drawCircle(center, _dotRadius, Paint()..color = palette.dotFill);
        canvas.drawCircle(center, _dotRadius, _stroke(palette.line, _dotRingWidth));
      }
    }
  }

  /// Non-empty band labels centred in their visible part, then the axis
  /// bounds on the plot edges.
  void _paintValueAxis(Canvas canvas) {
    for (final _BandPaint band in scene.bands) {
      final String? label = band.label;
      if (label == null || label.isEmpty || !_visible(band)) continue;
      _drawGutterText(
        canvas,
        label,
        _style(StepRangeCaptions.bandLabel, tone: band.labelColor),
        (_y(band.from) + _y(band.to)) / 2,
      );
    }
    _drawGutterText(canvas, scene.maxText, _style(StepRangeCaptions.bound), _kPlotTop);
    _drawGutterText(canvas, scene.minText, _style(StepRangeCaptions.bound), _kPlotBottom);
  }

  void _drawGutterText(Canvas canvas, String text, TextStyle style, double y) {
    _drawText(canvas, text, style, Offset(_kGutterRight, y), maxWidth: _kGutterWidth, alignRight: true);
  }

  void _paintCaptions(Canvas canvas, List<_Slot> slots) {
    for (int i = 0; i < slots.length; i++) {
      _paintColumnCaptions(canvas, i, slots[i]);
    }
  }

  /// Name, optional sublabel and value under the column at [index], each
  /// ellipsised to the column width.
  void _paintColumnCaptions(Canvas canvas, int index, _Slot slot) {
    final StepRangeColumn column = scene.columns[index];
    final bool selected = index == scene.selectedIndex;
    final double x = (slot.left + slot.right) / 2;
    final double width = slot.right - slot.left;

    _drawText(
      canvas,
      column.label,
      _style(StepRangeCaptions.name(column, selected: selected)),
      Offset(x, _kNameY),
      maxWidth: width,
    );
    final StepRangeCaptionStyle? sublabel = StepRangeCaptions.sublabel(column, selected: selected);
    if (sublabel != null) {
      _drawText(canvas, column.sublabel ?? "", _style(sublabel), Offset(x, _kSublabelY), maxWidth: width);
    }
    final TextStyle value = _style(StepRangeCaptions.value(column, selected: selected));
    _drawText(
      canvas,
      scene.valueTexts[index],
      value.copyWith(fontFeatures: const <FontFeature>[FontFeature.tabularFigures()]),
      Offset(x, _kValueY),
      maxWidth: width,
    );
  }

  /// [baseStyle] with the size, weight and colour of [caption]; [tone] is
  /// the colour of [StepRangeInk.tone].
  TextStyle _style(StepRangeCaptionStyle caption, {Color? tone}) {
    final Color color = switch (caption.ink) {
      StepRangeInk.label => palette.label,
      StepRangeInk.line => palette.line,
      StepRangeInk.emphasized => palette.emphasized,
      StepRangeInk.muted => palette.muted,
      StepRangeInk.tone => tone ?? palette.label,
    };
    return baseStyle.copyWith(fontSize: caption.fontSize, fontWeight: caption.fontWeight, color: color);
  }

  Paint _stroke(Color color, double width) {
    return Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
  }

  /// One line of [text] centred on [anchor] (or right-aligned on it),
  /// ellipsised to [maxWidth].
  void _drawText(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset anchor, {
    required double maxWidth,
    bool alignRight = false,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      maxLines: 1,
      ellipsis: "…",
    )..layout(maxWidth: maxWidth);
    final double dx = alignRight ? anchor.dx - painter.width : anchor.dx - painter.width / 2;
    painter.paint(canvas, Offset(dx, anchor.dy - painter.height / 2));
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _StepRangePainter oldDelegate) {
    final _Scene old = oldDelegate.scene;
    return !listEquals(old.columns, scene.columns) ||
        old.selectedIndex != scene.selectedIndex ||
        old.minValue != scene.minValue ||
        old.maxValue != scene.maxValue ||
        !listEquals(old.valueTexts, scene.valueTexts) ||
        old.minText != scene.minText ||
        old.maxText != scene.maxText ||
        !listEquals(old.bands, scene.bands) ||
        oldDelegate.palette != palette ||
        oldDelegate.baseStyle != baseStyle ||
        oldDelegate.textDirection != textDirection;
  }
}

// pill_slot.dart
//
// _PillSlotDelegate — places a pill on the axis from its measured width:
// centred on its display value and clamped inside the axis (with a small
// right margin), at the hit-box top. The layout's width estimates drive the
// collision maths only, so a label wider than estimated never overflows the
// axis edges.

part of "../index.dart";

final class _PillSlotDelegate extends SingleChildLayoutDelegate {
  _PillSlotDelegate({required this.centerX});

  /// X of the pill's display value on the axis.
  final double centerX;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final double left = ValueAxisLayout.slotLeft(
      centerX,
      childSize.width,
      size.width,
      rightMargin: _kPillRightMargin,
    );
    return Offset(left, _kHitTop);
  }

  @override
  bool shouldRelayout(_PillSlotDelegate oldDelegate) => oldDelegate.centerX != centerX;
}

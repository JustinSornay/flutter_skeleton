// sheet_layout.dart
//
// _SheetLayout — lays out the inside of SnapBottomSheet. The grip (handle +
// header) sits at the top at its natural height, reported to the
// view-model so the collapsed height can fit it, and the body takes the
// rest, never less than zero. A sheet shorter than the grip clips it instead
// of reporting a Column overflow.

part of "../index.dart";

enum _SheetSlot { grip, body }

final class _SheetLayout extends StatelessWidget {
  /// Handle and optional header, at their natural height.
  final Widget grip;

  /// Scrollable body, sized to the remaining height.
  final Widget body;

  /// Receives the grip's height after each layout.
  final ValueChanged<double> onGripLaidOut;

  const _SheetLayout({required this.grip, required this.body, required this.onGripLaidOut});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomMultiChildLayout(
        delegate: _SheetLayoutDelegate(onGripLaidOut: onGripLaidOut),
        children: <Widget>[
          LayoutId(id: _SheetSlot.grip, child: grip),
          LayoutId(id: _SheetSlot.body, child: body),
        ],
      ),
    );
  }
}

final class _SheetLayoutDelegate extends MultiChildLayoutDelegate {
  final ValueChanged<double> onGripLaidOut;

  _SheetLayoutDelegate({required this.onGripLaidOut});

  @override
  void performLayout(Size size) {
    final Size grip = layoutChild(_SheetSlot.grip, BoxConstraints.tightFor(width: size.width));
    onGripLaidOut(grip.height);
    positionChild(_SheetSlot.grip, Offset.zero);
    final double bodyHeight = math.max(0, size.height - grip.height);
    layoutChild(_SheetSlot.body, BoxConstraints.tightFor(width: size.width, height: bodyHeight));
    positionChild(_SheetSlot.body, Offset(0, grip.height));
  }

  @override
  bool shouldRelayout(_SheetLayoutDelegate oldDelegate) => false;
}

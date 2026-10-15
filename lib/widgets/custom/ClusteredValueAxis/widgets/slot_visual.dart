// slot_visual.dart
//
// _SlotVisual — places the visual of a _ValueBubble or _ReferenceMarker in
// its hit box: vertically centred, its centre at centerX, unclipped. The
// hit box can sit off-centre (pushed away from a close neighbour by
// ValueAxisLayout.hitSlots) while the visual stays on its value.

part of "../index.dart";

final class _SlotVisual extends StatelessWidget {
  /// X of the visual's centre within the hit box.
  final double centerX;

  /// Width of the visual.
  final double size;

  final Widget child;

  const _SlotVisual({required this.centerX, required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          left: centerX - size / 2,
          top: 0,
          bottom: 0,
          width: size,
          child: Center(child: child),
        ),
      ],
    );
  }
}

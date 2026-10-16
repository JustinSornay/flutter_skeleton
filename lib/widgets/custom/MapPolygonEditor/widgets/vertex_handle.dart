// vertex_handle.dart
//
// Draggable vertex handle of MapPolygonEditor: a 48 dp hit box around a dot
// that grows when it is the snap target or being dragged. Reports raw
// pointer events to the view model (_startVertexDrag / _updateVertexDrag /
// _endVertexDrag).

part of "../index.dart";

/// Visual of one handle state.
typedef _VertexStyle = ({
  Color fill,
  Color border,
  double size,
  double borderWidth,
  double blurRadius,
});

final class _VertexHandle extends StatelessWidget {
  final int index;
  final bool isDragging;
  final bool isSnapTarget;
  final VoidCallback onDragStart;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;

  const _VertexHandle({
    required this.index,
    required this.isDragging,
    required this.isSnapTarget,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  _VertexStyle _style(ColorScheme cs) {
    if (isDragging) {
      return (
        fill: cs.onPrimary,
        border: cs.primary,
        size: 22,
        borderWidth: 2.5,
        blurRadius: 8,
      );
    }
    if (isSnapTarget) {
      return (
        fill: cs.primary,
        border: cs.onPrimary,
        size: 18,
        borderWidth: 2,
        blurRadius: 4,
      );
    }
    return (
      fill: cs.primary,
      border: cs.primary,
      size: 10,
      borderWidth: 0,
      blurRadius: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final _VertexStyle style = _style(cs);
    return Semantics(
      container: true,
      label: "custom.map_polygon_editor.vertex".tr(
        namedArgs: <String, String>{"index": "${index + 1}"},
      ),
      // INTENTIONAL: Listener (raw pointer events) bypasses the gesture
      // arena — a GestureDetector pan loses to the FlutterMap pan handler.
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (PointerDownEvent event) => onDragStart(),
        onPointerMove: (PointerMoveEvent event) => onDragUpdate(event.delta),
        onPointerUp: (PointerUpEvent event) => onDragEnd(),
        onPointerCancel: (PointerCancelEvent event) => onDragEnd(),
        child: Center(
          child: AnimatedContainer(
            duration: resolveMotion(context, _kVertexMotion),
            curve: Curves.easeOutCubic,
            width: style.size,
            height: style.size,
            decoration: BoxDecoration(
              color: style.fill,
              shape: BoxShape.circle,
              border: style.borderWidth > 0
                  ? Border.all(color: style.border, width: style.borderWidth)
                  : null,
              boxShadow: style.blurRadius > 0
                  ? <BoxShadow>[
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.27),
                        blurRadius: style.blurRadius,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

// view.dart
//
// Layout of SnapBottomSheet: a DraggableScrollableSheet snapping at the
// three heights, read from the view-model for the parent height. Its surface
// is a cs.surfaceContainerLow box with 16 dp top corners and a soft
// cs.shadow, hosting a transparent Material. Inside, the grip (handle +
// optional header, draggable, measured) sits above the body, which is built
// with the sheet's ScrollController and watched for scroll and metrics
// notifications (widgets/sheet_layout.dart). ColorScheme tokens only.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, _SnapBottomSheetState state) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final SnapBottomSheetStops stops = state._stopsFor(constraints.maxHeight);
        return DraggableScrollableSheet(
          controller: state._sheet,
          initialChildSize: stops.fractionOf(state.widget.controller.snap),
          minChildSize: stops.collapsed,
          maxChildSize: stops.full,
          snap: true,
          snapSizes: stops.sizes,
          snapAnimationDuration: state._snapDuration(context),
          builder: (BuildContext context, ScrollController scrollController) {
            return _surface(context, state, scrollController);
          },
        );
      },
    );
  }

  Widget _surface(BuildContext context, _SnapBottomSheetState state, ScrollController scrollController) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final SnapBottomSheet widget = state.widget;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: _kSheetRadius,
        boxShadow: <BoxShadow>[
          BoxShadow(color: cs.shadow.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: _SheetLayout(
          onGripLaidOut: state._onGripLaidOut,
          grip: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // The handle's tap is the accessible way to change height.
            excludeFromSemantics: true,
            onVerticalDragStart: state._onGripDragStart,
            onVerticalDragUpdate: state._onGripDragUpdate,
            onVerticalDragEnd: state._onGripDragEnd,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _SheetHandle(controller: widget.controller, onTap: state._cycleSnap),
                ?widget.header,
              ],
            ),
          ),
          body: NotificationListener<ScrollMetricsNotification>(
            onNotification: (ScrollMetricsNotification notification) => state._onBodyMetrics(scrollController),
            child: NotificationListener<ScrollNotification>(
              onNotification: state._onBodyScroll,
              child: widget.builder(context, scrollController),
            ),
          ),
        ),
      ),
    );
  }
}

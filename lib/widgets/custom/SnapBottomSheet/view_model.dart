// view_model.dart
//
// _SnapBottomSheetState — owns the DraggableScrollableController that sizes
// SnapBottomSheet and the heights it snaps to (the collapsed one fitted to
// the measured grip). Moves the sheet when the caller's controller, the
// fractions or the parent height change (animated, or a jump under reduced
// motion). Writes the resting height back into the controller after user
// drags: snaps passed during a drag, on the way to a programmatic target or
// while new heights replace the old ones are ignored. Also handles the
// handle tap cycle and the grip drags.

part of "index.dart";

final class _SnapBottomSheetState extends State<SnapBottomSheet> with _ViewMixin {
  /// Sizes the sheet. Attached once the body's scrollable uses the sheet's
  /// scroll controller.
  final DraggableScrollableController _sheet = DraggableScrollableController();

  /// The three heights in use. Replaced only when one of them changes (see
  /// [_stopsFor]), so the sheet keeps the same snap sizes list: a new list
  /// re-snaps it and would end a drag in progress.
  late SnapBottomSheetStops _stops;

  /// Height of the grip (handle + header) at its last layout.
  double _gripHeight = kMinTapTarget;

  /// Destination of a move from code that is pending or in flight.
  SheetSnap? _target;

  /// Whether the user is dragging the handle or the header.
  bool _gripDragging = false;

  /// Whether the body's scrollable is being dragged or is still settling.
  bool _bodyDragging = false;

  @override
  void initState() {
    super.initState();
    _stops = SnapBottomSheetStops(
      collapsed: widget.collapsedFraction,
      mid: widget.midFraction,
      full: widget.fullFraction,
    );
    widget.controller.addListener(_onSnapChanged);
    _sheet.addListener(_syncFromSheet);
    _scheduleMove();
  }

  @override
  void didUpdateWidget(SnapBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_onSnapChanged);
    widget.controller.addListener(_onSnapChanged);
    _scheduleMove();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSnapChanged);
    _sheet.removeListener(_syncFromSheet);
    _sheet.dispose();
    super.dispose();
  }

  /// The heights for a parent [parentHeight] tall: the widget's fractions,
  /// with the collapsed one fitted to the grip. Returns the same instance
  /// while they are unchanged. New heights move the sheet back to the
  /// controller's height after this frame.
  SnapBottomSheetStops _stopsFor(double parentHeight) {
    final double collapsed = SnapBottomSheetStops.fitCollapsed(
      collapsed: widget.collapsedFraction,
      mid: widget.midFraction,
      gripHeight: _gripHeight,
      parentHeight: parentHeight,
    );
    final SnapBottomSheetStops current = _stops;
    if (current.collapsed == collapsed && current.mid == widget.midFraction && current.full == widget.fullFraction) {
      return current;
    }
    _stops = SnapBottomSheetStops(collapsed: collapsed, mid: widget.midFraction, full: widget.fullFraction);
    _scheduleMove();
    return _stops;
  }

  /// Called by the layout with the grip's height. Layout cannot rebuild, so
  /// a new height refits the collapsed height on the next frame.
  void _onGripLaidOut(double height) {
    if (height == _gripHeight) return;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted && height != _gripHeight) setState(() => _gripHeight = height);
    });
  }

  /// Moves the sheet to the controller's height after this frame: the sheet
  /// attaches during the first layout and must not move during a build.
  /// Until then the target is the controller's height, so a size the sheet
  /// reports in between (clamped to new heights, or reset to its initial
  /// height) is not written back into the controller.
  void _scheduleMove() {
    _target = widget.controller.snap;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted) _onSnapChanged();
    });
  }

  void _onSnapChanged() => _moveTo(widget.controller.snap);

  /// Moves the sheet to [snap]: animated, or a jump under reduced motion.
  /// Does nothing when the sheet is not attached or is already there.
  void _moveTo(SheetSnap snap) {
    if (!_sheet.isAttached) return;
    final double size = _stops.fractionOf(snap);
    if ((_sheet.size - size).abs() < SnapBottomSheetStops.tolerance) {
      _target = null;
      return;
    }
    final Duration duration = resolveMotion(context, _kSnapDuration);
    if (duration == Duration.zero) {
      _target = null;
      _sheet.jumpTo(size);
      return;
    }
    // Set before animating: animateTo may end a body scroll synchronously.
    _target = snap;
    unawaited(_sheet.animateTo(size, duration: duration, curve: Curves.easeOutCubic));
  }

  /// Writes the height the sheet rests at back into the controller. Ignores
  /// sizes passed during a user drag or on the way to [_target].
  void _syncFromSheet() {
    if (_gripDragging || _bodyDragging || !_sheet.isAttached) return;
    final SheetSnap? at = _stops.snapAt(_sheet.size);
    if (at == null) return;
    final SheetSnap? target = _target;
    if (target != null && at != target) return;
    _target = null;
    widget.controller.setSnap(at);
  }

  /// Tracks drags of the body's primary scrollable (depth 0). The scrollable
  /// ends its scroll once a released drag has snapped.
  bool _onBodyScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification is ScrollStartNotification && notification.dragDetails != null) {
      _bodyDragging = true;
      _target = null;
    } else if (notification is ScrollEndNotification) {
      _bodyDragging = false;
      _syncFromSheet();
    }
    return false;
  }

  /// Handle tap: collapsed → mid → full → collapsed.
  void _cycleSnap() {
    widget.controller.setSnap(switch (widget.controller.snap) {
      SheetSnap.collapsed => SheetSnap.mid,
      SheetSnap.mid => SheetSnap.full,
      SheetSnap.full => SheetSnap.collapsed,
    });
  }

  void _onGripDragStart(DragStartDetails details) {
    _gripDragging = true;
    _target = null;
  }

  void _onGripDragUpdate(DragUpdateDetails details) {
    if (!_sheet.isAttached) return;
    final double parentHeight = _sheet.sizeToPixels(1);
    if (parentHeight <= 0) return;
    final double size = _sheet.size - (details.primaryDelta ?? 0) / parentHeight;
    _sheet.jumpTo(size.clamp(_stops.collapsed, _stops.full));
  }

  /// Settles a released grip drag on the nearest height, or on the next one
  /// in the direction of a fling.
  void _onGripDragEnd(DragEndDetails details) {
    _gripDragging = false;
    if (!_sheet.isAttached) return;
    final double velocity = details.primaryVelocity ?? 0;
    final bool? growing = velocity.abs() < kMinFlingVelocity ? null : velocity < 0;
    final SheetSnap target = _stops.settle(_sheet.size, growing: growing);
    if (widget.controller.snap == target) {
      _moveTo(target);
    } else {
      widget.controller.setSnap(target);
    }
  }

  /// Snap duration of a released body drag: never zero (the sheet asserts it).
  Duration _snapDuration(BuildContext context) {
    final Duration duration = resolveMotion(context, _kSnapDuration);
    return duration == Duration.zero ? _kInstantSnap : duration;
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}

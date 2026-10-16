// view.dart
//
// Layout of ClusteredValueAxis: a cs.surfaceContainerLow panel with an
// optional _AxisHeader and a 64 dp axis Stack — the _BandTrack centred on
// the axis line, one _ValueBubble / _ClusterPill / _ReferencePill per item
// of ValueAxisLayout.computeItems, then the _ReferenceMarker when the
// reference was not fused. Bubble and marker hit boxes come from
// ValueAxisLayout.hitSlots, so they never reach into a neighbour. The panel
// sits in an OverlayPortal whose overlay child is the _GroupPopover of the
// open pill, following it through a CompositedTransformFollower.
// ColorScheme tokens only.

part of "index.dart";

/// Height of the axis strip.
const double _kAxisHeight = 64;

/// Y of the axis line: the track, bubbles, pills and marker centre on it.
const double _kAxisLineY = 32;

/// Top of every kMinTapTarget-tall hit box.
const double _kHitTop = _kAxisLineY - kMinTapTarget / 2;

/// Height of the band track.
const double _kTrackHeight = 16;

/// Room kept right of a pill clamped at the axis end.
const double _kPillRightMargin = 4;

mixin _ViewMixin<T extends Object> {
  Widget render(BuildContext context, _ClusteredValueAxisState<T> state) {
    final ClusteredValueAxis<T> widget = state.widget;
    if (widget.points.isEmpty) return const SizedBox.shrink();
    final ColorScheme cs = Theme.of(context).colorScheme;

    return OverlayPortal(
      controller: state._portal,
      overlayChildBuilder: (BuildContext context) => _popover(state),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          border: Border(bottom: BorderSide(color: cs.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 2, vertical: kDefaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.title case final String title) ...<Widget>[
                _AxisHeader(
                  title: title,
                  icon: widget.icon,
                  countText: "custom.clustered_value_axis.count".tr(
                    namedArgs: <String, String>{"count": "${widget.points.length}"},
                  ),
                  bestText: widget.highlightBest ? state._bestText : null,
                ),
                const SizedBox(height: kDefaultPadding),
              ],
              SizedBox(
                height: _kAxisHeight,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return _axis(state, constraints.maxWidth);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Track, items and marker for an axis [width] wide.
  Widget _axis(_ClusteredValueAxisState<T> state, double width) {
    final ClusteredValueAxis<T> widget = state.widget;
    final double? reference = widget.reference;
    final (double axisMin, double axisMax) = ValueAxisLayout.computeRange(
      reference,
      <double>[for (final ValueAxisPoint<T> point in widget.points) point.value],
    );
    final _AxisScale scale = _AxisScale(axisMin, axisMax, width);
    final List<ValueAxisItem<T>> items = ValueAxisLayout.computeItems<T>(
      points: widget.points,
      axisMin: axisMin,
      axisMax: axisMax,
      axisWidthPx: width,
      reference: reference,
      highlightBest: widget.highlightBest,
    );
    final bool fused = items.any((ValueAxisItem<T> item) => item is ValueAxisReferenceCluster<T>);
    final double? marker = fused ? null : reference;
    // Hit boxes of the items, then the marker, bounded by their neighbours.
    final List<(double, double)> slots = ValueAxisLayout.hitSlots(
      <(double, double)>[
        for (final ValueAxisItem<T> item in items) _extent(item, scale),
        if (marker != null) _around(_visualX(marker, scale), ValueAxisLayout.referenceSize),
      ],
      width,
    );
    state._closeIfRegrouped(items);

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          left: 0,
          right: 0,
          top: _kAxisLineY - _kTrackHeight / 2,
          height: _kTrackHeight,
          child: _BandTrack(
            bands: widget.bands,
            spans: ValueAxisLayout.computeBandSpans(axisMin, axisMax, widget.bands),
          ),
        ),
        for (int i = 0; i < items.length; i++) _item(state, items[i], scale, slots[i]),
        if (marker != null) _marker(state, marker, scale, slots.last),
      ],
    );
  }

  /// X of the centre of a bubble or the marker drawn at [value]: kept half
  /// a kMinTapTarget away from the axis ends.
  double _visualX(double value, _AxisScale scale) {
    return ValueAxisLayout.slotLeft(scale.px(value), kMinTapTarget, scale.width) + kMinTapTarget / 2;
  }

  (double, double) _around(double centerX, double width) => (centerX - width / 2, centerX + width / 2);

  /// Visible `(left, right)` of [item]: a bubble around its centre, a pill
  /// at its slot from its width estimate.
  (double, double) _extent(ValueAxisItem<T> item, _AxisScale scale) {
    final double width = ValueAxisLayout.itemRenderedWidth(item);
    if (item case ValueAxisSingle<T>(:final ValueAxisPoint<T> point)) {
      return _around(_visualX(point.value, scale), width);
    }
    final double left = ValueAxisLayout.slotLeft(
      scale.px(ValueAxisLayout.itemDisplayValue(item)),
      width,
      scale.width,
      rightMargin: _kPillRightMargin,
    );
    return (left, left + width);
  }

  /// [slot] is the bubble's hit box (ignored by pills).
  Widget _item(
    _ClusteredValueAxisState<T> state,
    ValueAxisItem<T> item,
    _AxisScale scale,
    (double, double) slot,
  ) {
    final String? bestText = state.widget.highlightBest ? state._bestText : null;
    return switch (item) {
      ValueAxisSingle<T>() => _bubble(state, item, scale, slot),
      ValueAxisCluster<T>(:final List<ValueAxisPoint<T>> points, :final bool containsBest) => _pill(
        state,
        item,
        scale,
        (_PillAnchor anchor) => _ClusterPill(
          count: points.length,
          filled: anchor.open || state._containsSelected(points),
          selected: state._containsSelected(points),
          bestText: containsBest ? bestText : null,
          anchor: anchor,
        ),
      ),
      ValueAxisReferenceCluster<T>(:final List<ValueAxisPoint<T>> points, :final bool containsBest) => _pill(
        state,
        item,
        scale,
        (_PillAnchor anchor) => _ReferencePill(
          count: points.length,
          icon: state.widget.referenceIcon,
          referenceLabel: state._referenceLabel,
          ring: anchor.open || state._referenceActive || state._containsSelected(points),
          selected: state._referenceActive || state._containsSelected(points),
          bestText: containsBest ? bestText : null,
          anchor: anchor,
        ),
      ),
    };
  }

  Widget _bubble(
    _ClusteredValueAxisState<T> state,
    ValueAxisSingle<T> item,
    _AxisScale scale,
    (double, double) slot,
  ) {
    final ValueAxisPoint<T> point = item.point;
    final ValueChanged<T?>? onSelect = state.widget.onSelect;
    final (double left, double hitWidth) = slot;
    return Positioned(
      left: left,
      top: _kHitTop,
      width: hitWidth,
      height: kMinTapTarget,
      child: _ValueBubble(
        visualCenter: _visualX(point.value, scale) - left,
        text: state._format(point.value),
        best: item.isBest,
        selected: state._isSelected(point.id),
        semanticsLabel: state._pointSemantics(point, best: item.isBest),
        onTap: onSelect == null ? null : () => state._select(point.id),
      ),
    );
  }

  /// A pill for [item], centred on its display value by _PillSlotDelegate
  /// from its measured width; [build] receives the popover anchor (link set
  /// only while this pill is open).
  Widget _pill(
    _ClusteredValueAxisState<T> state,
    ValueAxisItem<T> item,
    _AxisScale scale,
    Widget Function(_PillAnchor anchor) build,
  ) {
    final double leftPercent = scale.percent(ValueAxisLayout.itemDisplayValue(item));
    final double width = ValueAxisLayout.itemRenderedWidth(item);
    final _PillAnchor anchor = _PillAnchor(
      minWidth: width,
      tapGroup: state._tapGroup,
      onTap: () => state._toggleGroup(item, leftPercent),
      link: state._isOpen(item) ? state._link : null,
    );
    return Positioned.fill(
      child: CustomSingleChildLayout(
        delegate: _PillSlotDelegate(centerX: scale.width * leftPercent / 100),
        child: build(anchor),
      ),
    );
  }

  Widget _marker(
    _ClusteredValueAxisState<T> state,
    double reference,
    _AxisScale scale,
    (double, double) slot,
  ) {
    final ValueChanged<T?>? onSelect = state.widget.onSelect;
    final String text = state._format(reference);
    final (double left, double hitWidth) = slot;
    return Positioned(
      left: left,
      top: _kHitTop,
      width: hitWidth,
      height: kMinTapTarget,
      child: _ReferenceMarker(
        visualCenter: _visualX(reference, scale) - left,
        text: text,
        icon: state.widget.referenceIcon,
        active: state._referenceActive,
        semanticsLabel: "${state._referenceLabel}, $text",
        onTap: onSelect == null ? null : () => state._select(null),
      ),
    );
  }

  /// Overlay child: the open pill's popover, hanging 8 dp below it.
  Widget _popover(_ClusteredValueAxisState<T> state) {
    final ValueAxisItem<T>? item = state._openItem;
    if (item == null) return const SizedBox.shrink();
    final (Alignment target, Alignment follower) = state._popoverAnchors;
    // The overlay lays its child out full-screen: Align lets the follower
    // take the popover's own size so its anchors are the popover's corners.
    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: state._link,
        showWhenUnlinked: false,
        targetAnchor: target,
        followerAnchor: follower,
        offset: const Offset(0, kDefaultPadding),
        child: TapRegion(
          groupId: state._tapGroup,
          onTapOutside: (PointerDownEvent event) => state._closeGroup(),
          child: _GroupPopover(rows: _rows(state, item)),
        ),
      ),
    );
  }

  /// Reference row and divider (reference pill only), then the members.
  List<Widget> _rows(_ClusteredValueAxisState<T> state, ValueAxisItem<T> item) {
    final Map<T, int> ranks = ValueAxisLayout.ranksByValue<T>(state.widget.points);
    return <Widget>[
      if (item case ValueAxisReferenceCluster<T>(:final double reference)) ...<Widget>[
        _referenceRow(state, reference),
        const Divider(height: kDefaultPadding),
      ],
      for (final ValueAxisPoint<T> point in ValueAxisLayout.membersOf(item))
        _pointRow(state, point, ranks[point.id] ?? 1),
    ];
  }

  Widget _referenceRow(_ClusteredValueAxisState<T> state, double reference) {
    final ValueChanged<T?>? onSelect = state.widget.onSelect;
    return _PopoverRow(
      leading: _RankBadge.reference(state.widget.referenceIcon),
      label: state._referenceLabel,
      valueText: state._format(reference),
      active: state._referenceActive,
      reference: true,
      onTap: onSelect == null ? null : () => state._select(null),
    );
  }

  Widget _pointRow(_ClusteredValueAxisState<T> state, ValueAxisPoint<T> point, int rank) {
    final ValueChanged<T?>? onSelect = state.widget.onSelect;
    return _PopoverRow(
      leading: _RankBadge.rank(rank, best: state._isBest(point.value)),
      label: point.label,
      caption: point.caption,
      valueText: state._format(point.value),
      active: state._isSelected(point.id),
      onTap: onSelect == null ? null : () => state._select(point.id),
    );
  }
}

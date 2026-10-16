// view_model.dart
//
// _ClusteredValueAxisState — owns the popover: one OverlayPortalController,
// one LayerLink (attached only to the open pill), the tap-region group
// shared by the pills and the popover, and the open item with its axis
// position. Also resolves the value formatter, the reference label, the
// best value and the selection state, and routes taps (toggle / close /
// select). The popover closes when the points or the reference change, or
// when a resize regroups the open pill away.

part of "index.dart";

final class _ClusteredValueAxisState<T extends Object> extends State<ClusteredValueAxis<T>>
    with _ViewMixin<T> {
  final OverlayPortalController _portal = OverlayPortalController();

  /// Links the popover to the open pill; only that pill carries the target.
  final LayerLink _link = LayerLink();

  /// Tap-region group of the pills and the popover: a tap on a pill is not
  /// an outside tap.
  final Object _tapGroup = Object();

  /// Pill whose popover is open.
  ValueAxisItem<T>? _openItem;

  /// Axis position (0–100) of the open pill, which aligns the popover.
  double _openLeftPercent = 50;

  /// [ClusteredValueAxis.formatValue], else `(value * 100).round()`.
  String _format(double value) => widget.formatValue?.call(value) ?? "${(value * 100).round()}";

  String get _referenceLabel => widget.referenceLabel ?? "custom.clustered_value_axis.reference".tr();

  /// Whether the reference is the active selection.
  bool get _referenceActive => widget.reference != null && widget.selectedId == null;

  double get _maxValue => widget.points.map((ValueAxisPoint<T> p) => p.value).reduce(math.max);

  /// "Top {value}" for the highest value.
  String get _bestText {
    return "custom.clustered_value_axis.best".tr(namedArgs: <String, String>{"value": _format(_maxValue)});
  }

  /// Whether [value] is starred as the best.
  bool _isBest(double value) => widget.highlightBest && value == _maxValue;

  bool _isSelected(T id) => widget.selectedId == id;

  bool _containsSelected(List<ValueAxisPoint<T>> points) {
    return points.any((ValueAxisPoint<T> p) => _isSelected(p.id));
  }

  /// Screen-reader label of a point: `label, caption, value[, best]`.
  String _pointSemantics(ValueAxisPoint<T> point, {required bool best}) {
    return <String>[point.label, ?point.caption, _format(point.value), if (best) _bestText].join(", ");
  }

  /// Whether [item] is the open pill (same kind, same member ids).
  bool _isOpen(ValueAxisItem<T> item) {
    final ValueAxisItem<T>? open = _openItem;
    if (open == null) return false;
    if ((open is ValueAxisReferenceCluster<T>) != (item is ValueAxisReferenceCluster<T>)) return false;
    return listEquals(_ids(open), _ids(item));
  }

  List<T> _ids(ValueAxisItem<T> item) {
    return ValueAxisLayout.membersOf(item).map((ValueAxisPoint<T> p) => p.id).toList(growable: false);
  }

  /// `(targetAnchor, followerAnchor)`: the popover hangs right-aligned
  /// past 70 % of the axis, left-aligned under 30 %, centred otherwise.
  (Alignment, Alignment) get _popoverAnchors {
    if (_openLeftPercent > 70) return (Alignment.bottomRight, Alignment.topRight);
    if (_openLeftPercent < 30) return (Alignment.bottomLeft, Alignment.topLeft);
    return (Alignment.bottomCenter, Alignment.topCenter);
  }

  /// Opens the popover of [item] at [leftPercent], or closes it when it is
  /// already open. Opening another pill replaces the open one.
  void _toggleGroup(ValueAxisItem<T> item, double leftPercent) {
    if (_isOpen(item)) {
      _closeGroup();
      return;
    }
    setState(() {
      _openItem = item;
      _openLeftPercent = leftPercent;
    });
    _portal.show();
  }

  void _closeGroup() {
    if (_openItem == null) return;
    setState(() => _openItem = null);
    _portal.hide();
  }

  /// Closes the popover after this frame when no item of [items] is the
  /// open pill any more (a resize regrouped it): its rows would otherwise
  /// stay in the overlay, unlinked and invisible. Called during layout,
  /// hence the post-frame callback.
  void _closeIfRegrouped(List<ValueAxisItem<T>> items) {
    final ValueAxisItem<T>? open = _openItem;
    if (open == null || items.any(_isOpen)) return;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (mounted && identical(_openItem, open)) _closeGroup();
    });
  }

  /// Closes the popover and reports [id] (null = the reference).
  void _select(T? id) {
    _closeGroup();
    widget.onSelect?.call(id);
  }

  /// Same ids, values, labels and captions in the same order.
  bool _samePoints(List<ValueAxisPoint<T>> a, List<ValueAxisPoint<T>> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      final ValueAxisPoint<T> x = a[i];
      final ValueAxisPoint<T> y = b[i];
      if (x.id != y.id || x.value != y.value || x.label != y.label || x.caption != y.caption) return false;
    }
    return true;
  }

  @override
  void didUpdateWidget(covariant ClusteredValueAxis<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool changed = oldWidget.reference != widget.reference || !_samePoints(oldWidget.points, widget.points);
    if (changed && _openItem != null) {
      // The overlay child renders nothing from now on; the portal itself
      // cannot be hidden during build, so it is hidden after this frame.
      _openItem = null;
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted && _openItem == null && _portal.isShowing) _portal.hide();
      });
    }
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}

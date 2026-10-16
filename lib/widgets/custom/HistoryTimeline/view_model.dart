// view_model.dart
//
// _HistoryTimelineState — the hovered dot, the expanded flag, which entries
// are visible, where their dots sit and how far their hit boxes reach
// (through HistoryTimelineLayout), the caption formatter and hints, and the
// tap routing (items[0] → onTapCurrent, others → onTapPast). Entries are
// addressed by their newest-first index.

part of "index.dart";

final class _HistoryTimelineState<T> extends State<HistoryTimeline<T>> with _ViewMixin<T> {
  /// Dots at least one current-dot diameter apart, so every visible circle
  /// lies inside its own hit box.
  static const HistoryTimelineLayout _layout = HistoryTimelineLayout(
    inset: kMinTapTarget / 2,
    minGap: _kCurrentDotSize,
  );

  /// Newest-first index of the dot under the mouse.
  int? _hoverIndex;

  /// Whether the pill was tapped; expand-only, as in the source.
  bool _expanded = false;

  /// Number of entries collapsed into the pill.
  int get _hiddenCount {
    return _layout.hiddenCount(widget.items.length, widget.maxVisible, expanded: _expanded);
  }

  /// Visible entries, oldest first (left to right, newest painted on top).
  List<T> get _visibleOldestFirst {
    final List<T> items = widget.items;
    return items.sublist(0, items.length - _hiddenCount).reversed.toList(growable: false);
  }

  /// X centre of each dot of [oldestFirst] for a strip [width] wide.
  List<double> _positions(List<T> oldestFirst, double width) {
    return _layout.positions(oldestFirst.map<DateTime>(widget.dateOf).toList(growable: false), width);
  }

  /// Hit span of each dot centred at [xs]: up to [kMinTapTarget] wide, cut
  /// at the midpoints with its neighbours.
  List<({double left, double right})> _hitSpans(List<double> xs) {
    return _layout.hitSpans(xs, kMinTapTarget / 2);
  }

  /// Caption formatter: [HistoryTimeline.dateLabelOf], else `MMMd` for the
  /// ambient locale (intl's default when that locale has no date data).
  String Function(DateTime date) _captionFormatter(BuildContext context) {
    final String Function(DateTime date)? custom = widget.dateLabelOf;
    if (custom != null) return custom;
    final String? locale = dateLocaleOf(context);
    return DateFormat.MMMd(locale).format;
  }

  /// Tooltip and semantics hint of the current or a past dot.
  String _hint({required bool current}) {
    if (current) return widget.currentHint ?? "custom.history_timeline.current".tr();
    return widget.pastHint ?? "custom.history_timeline.resume_here".tr();
  }

  /// Whether the dot at newest-first [index] has a callback.
  bool _isTappable(int index) {
    return (index == 0 ? widget.onTapCurrent : widget.onTapPast) != null;
  }

  /// Routes a tap: index 0 → [HistoryTimeline.onTapCurrent], else
  /// [HistoryTimeline.onTapPast].
  void _onTap(int index, T item) {
    if (index == 0) {
      widget.onTapCurrent?.call(item);
    } else {
      widget.onTapPast?.call(item);
    }
  }

  /// Mouse entered or left the dot at newest-first [index]. A late exit of
  /// an overlapping dot does not clear the dot just entered.
  void _onHover(int index, {required bool inside}) {
    if (inside) {
      setState(() => _hoverIndex = index);
    } else if (_hoverIndex == index) {
      setState(() => _hoverIndex = null);
    }
  }

  void _expand() => setState(() => _expanded = true);

  @override
  void didUpdateWidget(covariant HistoryTimeline<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maxVisible != widget.maxVisible || !listEquals(oldWidget.items, widget.items)) {
      _hoverIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}

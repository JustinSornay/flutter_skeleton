// view_model.dart
//
// _RankedBadgeListState — owns the expanded flag and answers the view's
// questions: the items in ranked order, the visible slice and whether the
// toggle is needed.

part of "index.dart";

final class _RankedBadgeListState extends State<RankedBadgeList> with _ViewMixin {
  /// Whether every item is shown.
  bool isExpanded = false;

  /// Items by descending weight; equal weights keep their input order.
  /// Built from a copy, so `widget.items` is never mutated.
  List<RankedBadgeItem> get ranked {
    final List<RankedBadgeItem> items = widget.items;
    final List<int> order = List<int>.generate(items.length, (int index) => index)
      ..sort((int a, int b) {
        final int byWeight = items[b].weight.compareTo(items[a].weight);
        return byWeight != 0 ? byWeight : a.compareTo(b);
      });
    return <RankedBadgeItem>[for (final int index in order) items[index]];
  }

  /// Whether some items are hidden while collapsed.
  bool get hasMore => widget.items.length > widget.collapsedCount;

  /// Items currently displayed, in ranked order.
  List<RankedBadgeItem> get visible {
    final List<RankedBadgeItem> all = ranked;
    return isExpanded ? all : all.take(widget.collapsedCount).toList();
  }

  /// Flips between the collapsed and the expanded list.
  void toggle() {
    setState(() => isExpanded = !isExpanded);
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}

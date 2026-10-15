// view_model.dart
//
// _RankedListState — owns the ScrollController shared by the Scrollbar and
// the ListView (an always-visible thumb needs an attached controller on
// desktop and web), and answers the per-row questions of the view: active
// state, displayed rank and tap handler.

part of "index.dart";

final class _RankedListState<T> extends State<RankedList<T>> with _ViewMixin<T> {
  /// Controller of the scrolling area, shared by the Scrollbar and the list.
  final ScrollController scrollController = ScrollController();

  /// Whether [entry] is the highlighted row.
  bool isActive(RankedListEntry<T> entry) {
    final T? activeValue = widget.activeValue;
    return activeValue != null && entry.value == activeValue;
  }

  /// Rank drawn for the entry at [index]: its own rank, else index + 1.
  int rankAt(int index) => widget.entries[index].rank ?? index + 1;

  /// Tap handler of the row showing [entry].
  VoidCallback tapOf(RankedListEntry<T> entry) {
    return () => widget.onItemTap(entry.value);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}

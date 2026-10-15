// view.dart
//
// Tree of CategoryBrowser: a ListView of ExpandableGroupTile, one per group,
// separated by kDefaultPadding, under a listener that reports user scrolls
// to the view-model. Each tile carries its GlobalKey (reveal scroll target)
// and the open state owned by the view-model.

part of "index.dart";

mixin _ViewMixin<T> {
  Widget render(BuildContext context, _CategoryBrowserState<T> state) {
    final List<CategoryBrowserGroup<T>> groups = state.widget.groups;

    return NotificationListener<ScrollNotification>(
      onNotification: state.onScroll,
      child: ListView.separated(
        controller: state.scrollController,
        itemCount: groups.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(height: kDefaultPadding),
        itemBuilder: (BuildContext context, int index) => _tile(state, groups[index]),
      ),
    );
  }

  Widget _tile(_CategoryBrowserState<T> state, CategoryBrowserGroup<T> group) {
    return ExpandableGroupTile<T>(
      key: state.keyFor(group.key),
      title: group.title,
      subtitle: group.subtitle,
      icon: group.icon ?? Icons.category,
      entries: group.entries,
      isOpen: state.openKey == group.key,
      expandable: group.expandable,
      onToggle: () => state.toggle(group),
      onSelected: state.widget.onEntrySelected,
    );
  }
}

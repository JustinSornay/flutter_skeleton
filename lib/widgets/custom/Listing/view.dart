// view.dart
//
// UI layer for Listing<T>. Switches between four visual states:
//   1. Initial load — centred Loader while the first page is being fetched.
//   2. Error — widget.errorBuilder (if provided) when the first page failed.
//   3. Empty — widget.emptyBuilder (if provided) when the first page is empty.
//   4. List — ListView.separated driven by state.list, with a trailing
//      Loader while additional pages are loading.

part of "index.dart";

mixin _ViewMixin<T extends OutputInterface> {
  Widget render(BuildContext context, _ListingState<T> state) {
    if (state.isLoading && state.list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(kDefaultPadding * 4),
          child: Loader(),
        ),
      );
    }

    if (state.hasError && state.list.isEmpty && state.widget.errorBuilder != null) {
      return Center(child: state.widget.errorBuilder!(context, state.retry));
    }

    if (state.list.isEmpty && state.widget.emptyBuilder != null) {
      return Center(child: state.widget.emptyBuilder);
    }

    return ListView.separated(
      controller: state.controller,
      scrollDirection: state.widget.scrollDirection,
      padding: const EdgeInsets.all(kDefaultPadding),
      // Reserve one extra slot at the end for the pagination loader.
      itemCount: state.list.length + (state.isLoading ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (index == state.list.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: kDefaultPadding * 2),
              child: Loader(size: 24),
            ),
          );
        }
        return state.widget.itemBuilder(context, state.list[index]) ?? const SizedBox.shrink();
      },
      separatorBuilder: (BuildContext context, int index) => state.widget.separatorBuilder(context, state.list[index]),
    );
  }
}

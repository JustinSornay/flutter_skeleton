// view.dart
//
// _ViewMixin — tree of RankedList: the empty message, or the optional header
// (title + count + trailing slot) above a height-capped, shrink-wrapped
// ListView of _RankedListRow with an always-visible Scrollbar. The automatic
// desktop scrollbar is switched off so only one thumb is painted.

part of "index.dart";

/// Gap between the header and the list (10 dp).
const double _headerGap = kDefaultPadding * 1.25;

/// Gap between the title and the count (6 dp).
const double _countGap = kDefaultPadding * 0.75;

/// Gap between two rows (6 dp).
const double _rowGap = kDefaultPadding * 0.75;

mixin _ViewMixin<T> {
  Widget render(BuildContext context, _RankedListState<T> state) {
    final RankedList<T> widget = state.widget;
    if (widget.entries.isEmpty) return _empty(context, widget);

    final Widget? header = _header(context, widget);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (header != null) ...<Widget>[header, const SizedBox(height: _headerGap)],
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.maxHeight),
          child: Scrollbar(
            controller: state.scrollController,
            thumbVisibility: true,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: _list(state),
            ),
          ),
        ),
      ],
    );
  }

  Widget _list(_RankedListState<T> state) {
    final RankedList<T> widget = state.widget;
    return ListView.separated(
      controller: state.scrollController,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: widget.entries.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: _rowGap),
      itemBuilder: (BuildContext context, int index) {
        final RankedListEntry<T> entry = widget.entries[index];
        return _RankedListRow<T>(
          entry: entry,
          rank: state.rankAt(index),
          active: state.isActive(entry),
          activeBadgeLabel: widget.activeBadgeLabel,
          trailingIcon: widget.trailingIcon,
          onTap: state.tapOf(entry),
        );
      },
    );
  }

  Widget _empty(BuildContext context, RankedList<T> widget) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding * 1.5),
      child: Text(
        widget.emptyLabel ?? "custom.ranked_list.empty".tr(),
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

  /// Title + count and the trailing slot; null when neither title nor
  /// trailing slot is set.
  Widget? _header(BuildContext context, RankedList<T> widget) {
    final String? title = widget.title;
    final Widget? trailing = widget.headerTrailing;
    if (title == null && trailing == null) return null;

    return Row(
      children: <Widget>[
        Expanded(
          child: title == null ? const SizedBox.shrink() : _titleAndCount(context, title, widget.entries.length),
        ),
        ?trailing,
      ],
    );
  }

  Widget _titleAndCount(BuildContext context, String title, int count) {
    final ThemeData theme = Theme.of(context);
    final Color color = theme.colorScheme.onSurfaceVariant;
    final TextStyle? base = theme.textTheme.labelSmall;
    return Row(
      children: <Widget>[
        Flexible(
          child: Semantics(
            header: true,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: base?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5, color: color),
            ),
          ),
        ),
        const SizedBox(width: _countGap),
        Text(
          "custom.ranked_list.count".tr(namedArgs: <String, String>{"count": "$count"}),
          style: base?.copyWith(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

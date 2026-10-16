// view.dart
//
// Tree of FilterableDataTable: the card (Material shape with border and
// clip), the header strip (widgets/header.dart), the optional ChoiceChipRow
// of filters with its "all" chip, then the empty message or the DataTable
// (widgets/table.dart). Colours come from the ColorScheme only.

part of "index.dart";

/// Card corner radius.
const double _cardRadius = 10;

mixin _ViewMixin<T, F> {
  Widget render(BuildContext context, FilterableDataTable<T, F> widget) {
    assert(widget.columns.isNotEmpty, "FilterableDataTable needs at least one column");
    assert(
      widget.filters.isEmpty || widget.onFilterChanged != null,
      "FilterableDataTable needs onFilterChanged when filters are given",
    );
    final ColorScheme cs = Theme.of(context).colorScheme;

    // The Material paints the border above its clipped content, so the
    // header fill never covers the border at the corners, and it gives the
    // chips and the table their Material ancestor. Its implicit theme-change
    // tween (text style, shape) honours reduced motion.
    return Material(
      animationDuration: resolveMotion(context, kThemeChangeDuration),
      color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _Header(title: widget.title, count: widget.rows.length),
          if (widget.filters.isNotEmpty) _filterRow(widget),
          if (widget.rows.isEmpty) _emptyState(context, widget) else _Table<T, F>(table: widget),
        ],
      ),
    );
  }

  /// "All" chip followed by the host's options. Tapping the selected chip
  /// again clears the filter.
  Widget _filterRow(FilterableDataTable<T, F> widget) {
    final F? selected = widget.selectedFilter;
    final ValueChanged<F?>? onChanged = widget.onFilterChanged;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(kDefaultPadding * 2, kDefaultPadding, kDefaultPadding * 2, 0),
      child: ChoiceChipRow<F?>(
        options: <ChoiceOption<F?>>[
          ChoiceOption<F?>(
            value: null,
            label: widget.allFilterLabel ?? "custom.filterable_data_table.all".tr(),
          ),
          ...widget.filters,
        ],
        selectedValue: selected,
        onSelected: (F? value) => onChanged?.call(value == selected ? null : value),
      ),
    );
  }

  Widget _emptyState(BuildContext context, FilterableDataTable<T, F> widget) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding * 2),
      child: Text(
        widget.emptyMessage ?? "custom.filterable_data_table.empty".tr(),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// view.dart
//
// _ViewMixin — tree of ScoreListCard: a rounded cs.surfaceContainerHigh
// Material card (ink surface for the rows) holding the header (optional icon
// + caption) and the body picked by an exhaustive switch on the load state:
// skeleton, error + retry, empty text or the scored rows.

part of "index.dart";

/// Gap between the header and the body (12 dp).
const double _headerGap = kDefaultPadding * 1.5;

mixin _ViewMixin<T> {
  Widget render(BuildContext context, _ScoreListCardState<T> state) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _header(context, state.widget),
            const SizedBox(height: _headerGap),
            _body(state),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, ScoreListCard<T> widget) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final IconData? icon = widget.icon;
    return Row(
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: kDefaultPadding),
        ],
        Expanded(
          child: Semantics(
            container: true,
            header: true,
            child: Text(
              widget.title,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _body(_ScoreListCardState<T> state) {
    final ScoreListCard<T> widget = state.widget;
    return switch (state.items) {
      Idle<List<T>>() || Loading<List<T>>() => _ScoreListSkeleton(rowCount: widget.skeletonRowCount),
      LoadError<List<T>>() => _StateMessage.error(
          text: widget.errorText ?? "custom.score_list_card.load_error".tr(),
          onRetry: state.retry,
        ),
      Loaded<List<T>>(:final List<T> data) when data.isEmpty => _StateMessage.empty(
          text: widget.emptyText ?? "custom.score_list_card.empty".tr(),
        ),
      Loaded<List<T>>(:final List<T> data) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final T item in data) _ScoreListRow(entry: widget.entryOf(item), onTap: state.tapOf(item)),
          ],
        ),
    };
  }
}

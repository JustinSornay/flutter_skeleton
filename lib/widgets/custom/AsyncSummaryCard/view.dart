// view.dart
//
// _ViewMixin — tree of AsyncSummaryCard, picked by an exhaustive switch on the
// load state: the skeleton, the error message + retry button, or the loaded
// content (header, divider, body with bold runs, optional footnote), each
// inside the shared _CardFrame.

part of "index.dart";

/// Gap between the body and the footnote, and between the error text and the
/// retry button (12 dp).
const double _innerGap = kDefaultPadding * 1.5;

/// Padding of the skeleton, the error state and the body (16 dp).
const EdgeInsets _contentPadding = EdgeInsets.all(kDefaultPadding * 2);

mixin _ViewMixin {
  Widget render(BuildContext context, _AsyncSummaryCardState state) {
    return switch (state.summary) {
      Idle<AsyncSummary>() || Loading<AsyncSummary>() => const _CardFrame(
          padding: _contentPadding,
          child: _SummarySkeleton(),
        ),
      LoadError<AsyncSummary>() => _error(context, state),
      Loaded<AsyncSummary>(:final AsyncSummary data) => _loaded(context, state, data),
    };
  }

  Widget _error(BuildContext context, _AsyncSummaryCardState state) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return _CardFrame(
      padding: _contentPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            liveRegion: true,
            child: Text(
              state.widget.errorMessage ?? "custom.async_summary_card.unavailable".tr(),
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: _innerGap),
          TextButton.icon(
            onPressed: state.retry,
            style: TextButton.styleFrom(minimumSize: const Size(kMinTapTarget, kMinTapTarget)),
            icon: const Icon(Icons.refresh, size: 18),
            label: Text("custom.async_summary_card.retry".tr()),
          ),
        ],
      ),
    );
  }

  Widget _loaded(BuildContext context, _AsyncSummaryCardState state, AsyncSummary data) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncSummaryCard widget = state.widget;
    return _CardFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SummaryHeader(
            icon: widget.icon,
            title: widget.title,
            badge: data.badge,
            trailing: widget.headerTrailing,
          ),
          Divider(height: 1, thickness: 1, color: cs.outlineVariant),
          Padding(
            padding: _contentPadding,
            child: _body(context, state, data),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, _AsyncSummaryCardState state, AsyncSummary data) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String? footnote = data.footnote;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              for (final _TextRun run in state.runsOf(data.text))
                TextSpan(
                  text: run.text,
                  style: run.bold ? const TextStyle(fontWeight: FontWeight.w700) : null,
                ),
            ],
          ),
          style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
        ),
        if (footnote != null && footnote.isNotEmpty) ...<Widget>[
          const SizedBox(height: _innerGap),
          Text(
            footnote,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }
}

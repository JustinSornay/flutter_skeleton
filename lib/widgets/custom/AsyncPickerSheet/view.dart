// view.dart
//
// _ViewMixin — widget tree of AsyncPickerSheet on a transparent Material (ink
// surface for the caller's body): header, the error banner when the last
// submit failed, then the caller's picker body (covered by the busy overlay
// while a submit runs) filling the remaining height.

part of "index.dart";

mixin _ViewMixin<T> {
  Widget render(BuildContext context, _AsyncPickerSheetState<T> state) {
    final AsyncPickerSheet<T> widget = state.widget;
    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SheetHeader(title: widget.title, onClose: widget.onClose),
          switch (state.submission) {
            LoadError<void>(:final String? message) => _ErrorBanner(message: message ?? ""),
            _ => const SizedBox.shrink(),
          },
          Expanded(
            child: _BusyBody(
              busy: state.busy,
              child: widget.builder(context, state.pick),
            ),
          ),
        ],
      ),
    );
  }
}

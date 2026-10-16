// view.dart
//
// _ViewMixin — rendering for TodoDetail. Exhaustive switch over LoadState:
// skeleton while loading, message + retry on error, content once loaded.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, _TodoDetailState state) {
    return switch (state.todo) {
      Idle<TodoDetailOutput>() || Loading<TodoDetailOutput>() => _skeleton(context),
      LoadError<TodoDetailOutput>(:final String? message) => _error(context, state, message),
      Loaded<TodoDetailOutput>(:final TodoDetailOutput data) => _content(context, state, data),
    };
  }

  Widget _skeleton(BuildContext context) {
    final Color block = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double width) => Container(
      width: width,
      height: 16,
      margin: const EdgeInsets.only(bottom: kDefaultPadding * 2),
      decoration: BoxDecoration(color: block, borderRadius: BorderRadius.circular(4)),
    );

    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding * 2),
      child: SkeletonPulse(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[bar(280), bar(160), bar(220)],
        ),
      ),
    );
  }

  Widget _error(BuildContext context, _TodoDetailState state, String? message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text("error.load_failed".tr()),
          if (message != null) Text(message, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: kDefaultPadding * 2),
          FilledButton.tonal(
            onPressed: state.load,
            child: Text("common.retry".tr()),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, _TodoDetailState state, TodoDetailOutput todo) {
    final TextTheme text = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(kDefaultPadding * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(todo.title, style: text.headlineSmall),
          const SizedBox(height: kDefaultPadding),
          Text(
            "todo.user".tr(namedArgs: <String, String>{"id": "${todo.userId}"}),
            style: text.bodyMedium,
          ),
          const SizedBox(height: kSectionGap),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text("todo.completed".tr()),
            subtitle: Text((todo.completed ? "todos.status_done" : "todos.status_pending").tr()),
            value: todo.completed,
            onChanged: state.isSaving ? null : state.setCompleted,
          ),
          const SizedBox(height: kDefaultPadding * 2),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              minimumSize: const Size(kMinTapTarget, kMinTapTarget),
            ),
            onPressed: state.isSaving ? null : state.delete,
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text("todo.delete".tr()),
          ),
        ],
      ),
    );
  }
}

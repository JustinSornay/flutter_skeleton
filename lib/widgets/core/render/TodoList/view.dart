// view.dart
//
// _ViewMixin — rendering for TodoList. Every status icon is paired with a
// text label (never colour or shape alone).

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, TodoList widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Listing<TodoListOutput>(
      apiCallback: widget.fetchPage,
      itemBuilder: (BuildContext context, TodoListOutput todo) {
        final String status = (todo.completed ? "todos.status_done" : "todos.status_pending").tr();
        return ListTile(
          leading: Icon(
            todo.completed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: todo.completed ? cs.primary : cs.onSurfaceVariant,
          ),
          title: Text(todo.title),
          subtitle: Text(status),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.go("/todos/${todo.id}"),
        );
      },
      separatorBuilder: (BuildContext context, TodoListOutput todo) => const Divider(),
      emptyBuilder: Text("todos.empty".tr()),
      errorBuilder: (BuildContext context, VoidCallback retry) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text("error.load_failed".tr()),
          const SizedBox(height: kDefaultPadding * 2),
          FilledButton.tonal(
            onPressed: retry,
            child: Text("common.retry".tr()),
          ),
        ],
      ),
    );
  }
}

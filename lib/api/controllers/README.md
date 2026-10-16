# api/controllers/

Controllers sit between the widgets and the services, like controllers in an
API sit between the routes and the domain:

```
view model (local UI state) → controller (flow + feedback) → service (HTTP + DTO) → Http
```

A service only talks to the backend: it sends the request, parses the DTO,
logs and rethrows. A controller decides **what the user experiences around
that call**.

## What a controller does

1. **Calls services.** Never `Http` directly, never a DTO parse.
2. **Handles errors** so the screen does not have to:
   - an error toast (`ErrorProvider.show(…)`);
   - a redirection (`context.go(…)`), e.g. a 404 on a detail page sends the
     user back to the list;
   - the meaning of a status code for this flow (404 on a delete = already
     gone, 409 on a create = already exists, 403 = not allowed…).
3. **Runs complex flows**: authentication gates (sign in, then retry the
   action), multi-step business flows (create → upload → confirm), chained
   calls whose order matters.
4. **Owns the behaviour tied to a call**:
   - a confirmation modal before a destructive or irreversible call
     (`confirmAction`, below);
   - a feedback overlay while a long call runs (`ModalProvider.show(…)`, then
     `dismiss()` in a `finally`);
   - a success toast (`AppErrorLevel.success`) once it is done.

## What it does not do

- **No local UI state.** `LoadState`, `isSaving`, the selected tab… stay in
  the view model, which updates them from the controller's return value.
  A controller never calls `setState` and keeps no mutable field.
- **No rendering.** It mounts existing widgets (`AppModal`, `ConfirmCard`)
  through the providers; new UI goes in `widgets/`.
- **No HTTP or parsing.** That is the service's job (see
  `api/services/README.md`). Services already log their errors, so the
  controller does not log them again.

## Rules

- One class per entity or flow: `TodoController` in `todo_controller.dart`.
  `final class` with a `const` constructor.
- The service calls are constructor parameters **defaulting to the static
  service methods**. Production code uses `const TodoController()`; tests pass
  fakes (`TodoController(getTodo: (_) async => …)`), no static mocking.
- Every method is a `Future<T>` that takes the caller's `BuildContext` first
  and **never throws**. The return value tells the view model what happened:
  `LoadState<T>` for a load, `T?` for an update (null = failed, feedback
  already shown), `bool` for an action (false = cancelled or failed).
- Read providers (`context.read<ErrorProvider>()`, …) **before the first
  `await`**. After an `await`, use the context only behind `context.mounted`:
  a user who already left the page is not redirected.
- Navigation with `context.go()` only (never `push`). Dialogs through
  `ModalProvider`, never `showDialog`.
- User-visible strings with `"key".tr()`; add the keys to `fr.json` and
  `en.json`.

## `_base/`

| File | Content |
|---|---|
| `confirm_action.dart` | `confirmAction(context, title:, confirmLabel:, cancelLabel:, message:, destructive:)` mounts a `ConfirmCard` in an `AppModal` and completes with `true` (confirm) or `false` (cancel, scrim tap). |

## Example

`todo_controller.dart` (demo) shows the three kinds of method:

```dart
final class TodoController {
  final Future<TodoDetailOutput> Function(int id) getTodo;
  final Future<void> Function(int id) deleteTodo;

  const TodoController({
    this.getTodo = TodoService.get,
    this.deleteTodo = TodoService.delete,
  });

  /// 404 → warning toast + back to the list; other errors → LoadError.
  Future<LoadState<TodoDetailOutput>> load(BuildContext context, int id) async { … }

  /// Confirmation modal → DELETE → success toast + back to the list.
  Future<bool> delete(BuildContext context, int id) async {
    final ErrorProvider toasts = context.read<ErrorProvider>();
    final bool confirmed = await confirmAction(context, …, destructive: true);
    if (!confirmed) return false;
    try {
      await deleteTodo(id);
    } on ApiException catch (e) {
      if (e.status != 404) return _deleteFailed(toasts); // 404: already gone
    } catch (_) {
      return _deleteFailed(toasts);
    }
    toasts.show("todo.deleted".tr(), level: AppErrorLevel.success);
    if (context.mounted) context.go("/");
    return true;
  }
}
```

The view model keeps only its own state:

```dart
Future<void> delete() async {
  setState(() => isSaving = true);
  await _controller.delete(context, widget.todoId);
  if (mounted) setState(() => isSaving = false);
}
```

and the widget exposes the controller as its test seam
(`TodoDetail(controller: TodoController(getTodo: fake))`).

## Tests

`test/widget/controllers/todo_controller_test.dart` runs each method from a
context inside a small `GoRouter` (with a `ModalConsumer` for the modal) and
checks the return value, the `ErrorProvider` toast and the router location.
Clear the `ErrorProvider` at the end of a test that shows a toast (its
auto-dismiss timer would still be pending).

## Not to be confused with render-widget `controllers/`

`widgets/core/render/<Widget>/controllers/` holds plain classes for the UI
logic of **one** screen (filtering, sorting, a CSV export). The controllers
here are **app-wide flows around API calls**, shared by every screen that
triggers them.

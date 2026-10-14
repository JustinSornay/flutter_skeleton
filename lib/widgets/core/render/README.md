# widgets/core/render/

**Render widgets** are the MVVM components at the page or major-section level.
They are the boundary between the router (pages) and reusable widgets.

A render widget:

- **owns its own state** — loading, errors, local data, UI selections;
- **orchestrates service calls** directly or through providers;
- **delegates rendering** to `view.dart` through a pure mixin;
- **keeps internal sub-widgets** in `widgets/` — never imported from outside.

## Structure

```
MyWidget/
  index.dart        # StatefulWidget + public params + part directives
  view_model.dart   # _MyWidgetState extends State with _ViewMixin — lifecycle + logic
  view.dart         # mixin _ViewMixin — pure render() function
  widgets/          # internal sub-components (single files, optional)
  controllers/      # plain Dart classes for isolated logic (optional)
```

## Dependency injection (injectable seam pattern)

Static service methods are not mockable. Render widgets expose them as optional
function parameters whose production default is the real service; tests pass
fakes. See `TodoDetail` for a complete example:

```dart
final class TodoDetail extends StatefulWidget {
  final int todoId;
  final Future<TodoDetailOutput> Function(int id)? getTodo;   // test seam
  …
}

// view_model.dart
final TodoDetailOutput todo = await (widget.getTodo ?? TodoService.get)(widget.todoId);
```

## State

Prefer the `LoadState<T>` sealed class (`utils/load_state.dart`) over ad-hoc
`isLoading` / `hasError` / `data` triples, and `switch` on it in the view.

## What a render widget does NOT do

- It does not manage global state (that is the role of providers).
- It does not contain logic reusable across pages (that belongs in `custom/`).
- It does not know the route table — navigation is `context.go()` from
  callbacks in `view.dart`.

// todo_controller.dart
//
// Demo controller for todos: calls TodoService and owns everything that
// surrounds a call — confirmation modal, success / error toasts, redirection.
// Used by widgets/core/render/TodoDetail. Delete it together with
// todo_service.dart and the rest of the demo when starting a real project.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/widgets.dart";
import "package:flutter_skeleton/api/controllers/_base/confirm_action.dart";
import "package:flutter_skeleton/api/dtos/todo/input/patch_input.dart";
import "package:flutter_skeleton/api/dtos/todo/output/detail_output.dart";
import "package:flutter_skeleton/api/http/api_exception.dart";
import "package:flutter_skeleton/api/services/todo_service.dart";
import "package:flutter_skeleton/providers/error_provider.dart";
import "package:flutter_skeleton/utils/load_state.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";

/// User-facing flows around the todo API.
///
/// Every method takes the caller's [BuildContext] first and never throws:
/// failures end as feedback (toast, redirection) plus a return value the
/// view model can use for its own state. Providers are read before the first
/// `await`; navigation after an `await` happens only while
/// `context.mounted` (a user who already left is not redirected).
///
/// The service calls are constructor parameters defaulting to [TodoService],
/// so tests build `TodoController(getTodo: fake, …)` instead of mocking
/// static methods.
final class TodoController {
  final Future<TodoDetailOutput> Function(int id) getTodo;
  final Future<TodoDetailOutput> Function(int id, TodoPatchInput input) patchTodo;
  final Future<void> Function(int id) deleteTodo;

  const TodoController({
    this.getTodo = TodoService.get,
    this.patchTodo = TodoService.patch,
    this.deleteTodo = TodoService.delete,
  });

  /// Loads one todo for a detail screen.
  ///
  /// A 404 means the link is stale: a warning toast is shown and the user is
  /// sent back to the list. Any other failure becomes a [LoadError] the view
  /// renders with a retry button.
  Future<LoadState<TodoDetailOutput>> load(BuildContext context, int id) async {
    final ErrorProvider toasts = context.read<ErrorProvider>();
    try {
      return Loaded<TodoDetailOutput>(await getTodo(id));
    } on ApiException catch (e) {
      if (e.status == 404 && context.mounted) {
        toasts.show("todo.not_found".tr(), level: AppErrorLevel.warning);
        context.go("/");
      }
      return LoadError<TodoDetailOutput>(e.detail);
    } catch (_) {
      return const LoadError<TodoDetailOutput>();
    }
  }

  /// Saves the completion flag. Returns the updated todo after a success
  /// toast, or null after an error toast (the caller keeps its value).
  Future<TodoDetailOutput?> setCompleted(BuildContext context, int id, bool completed) async {
    final ErrorProvider toasts = context.read<ErrorProvider>();
    try {
      final TodoDetailOutput todo = await patchTodo(id, TodoPatchInput(completed: completed));
      toasts.show("todo.saved".tr(), level: AppErrorLevel.success);
      return todo;
    } catch (_) {
      toasts.show("error.save_failed".tr());
      return null;
    }
  }

  /// Asks for confirmation, deletes the todo, then shows a success toast and
  /// goes back to the list. A 404 means it is already gone: same outcome.
  /// Returns false when the user cancels or the call fails (error toast).
  Future<bool> delete(BuildContext context, int id) async {
    final ErrorProvider toasts = context.read<ErrorProvider>();
    final bool confirmed = await confirmAction(
      context,
      title: "todo.delete_title".tr(),
      message: "todo.delete_message".tr(),
      confirmLabel: "todo.delete".tr(),
      cancelLabel: "common.cancel".tr(),
      destructive: true,
    );
    if (!confirmed) return false;
    try {
      await deleteTodo(id);
    } on ApiException catch (e) {
      if (e.status != 404) return _deleteFailed(toasts);
    } catch (_) {
      return _deleteFailed(toasts);
    }
    toasts.show("todo.deleted".tr(), level: AppErrorLevel.success);
    if (context.mounted) context.go("/");
    return true;
  }

  bool _deleteFailed(ErrorProvider toasts) {
    toasts.show("todo.delete_failed".tr());
    return false;
  }
}

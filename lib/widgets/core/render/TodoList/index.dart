// index.dart
//
// TodoList — demo render widget: paginated list of todos backed by Listing.
//
// Shows the injectable seam pattern on a stateless widget: [getList] defaults
// to TodoService.getList and is replaced by a fake in widget tests.
// Tapping a row navigates to /todos/:id.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/api/dtos/todo/output/list_output.dart";
import "package:flutter_skeleton/api/services/_base/apiFilterBuilder/api_filter_builder.dart";
import "package:flutter_skeleton/api/services/todo_service.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/Listing/index.dart";
import "package:go_router/go_router.dart";

part "view.dart";

/// Lazy-loaded list of todos.
final class TodoList extends StatelessWidget with _ViewMixin {
  /// Test seam — defaults to [TodoService.getList].
  final Future<List<TodoListOutput>> Function([ApiFilterBuilder? apiFilterBuilder])? getList;

  const TodoList({
    super.key,
    this.getList,
  });

  /// Fetches one page. JSONPlaceholder paginates with `_page` / `_limit`.
  Future<List<TodoListOutput>> fetchPage(int page, int itemPerPage) {
    final ApiFilterBuilder filter = ApiFilterBuilder()
      ..addParam("_page", page)
      ..addParam("_limit", itemPerPage);
    return (getList ?? TodoService.getList)(filter);
  }

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

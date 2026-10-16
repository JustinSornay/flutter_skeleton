// todo_service.dart
//
// Demo service for the `todos` resource of the default `api` backend
// (JSONPlaceholder in .env.local). Delete it together with
// api/dtos/todo/ and widgets/core/render/Todo*/ when starting a real project.

import "package:flutter_skeleton/api/dtos/todo/input/patch_input.dart";
import "package:flutter_skeleton/api/dtos/todo/output/detail_output.dart";
import "package:flutter_skeleton/api/dtos/todo/output/list_output.dart";
import "package:flutter_skeleton/api/http/enums.dart";
import "package:flutter_skeleton/api/http/http.dart";
import "package:flutter_skeleton/api/http/http_output.dart";
import "package:flutter_skeleton/api/services/_base/apiFilterBuilder/api_filter_builder.dart";
import "package:logger/logger.dart";

/// API calls for todos. All methods are static; widgets and providers reach
/// them through injectable function parameters so tests can swap them out.
final class TodoService {
  static Future<TodoDetailOutput> get(int id) async {
    try {
      return TodoDetailOutput.fromOutput(await Http.output(
        api: HttpApiEnum.api,
        route: "todos/$id",
      ));
    } catch (e) {
      Logger().e("TodoService.get: $e");
      rethrow;
    }
  }

  static Future<List<TodoListOutput>> getList([ApiFilterBuilder? apiFilterBuilder]) async {
    try {
      final List<HttpOutput> result = await Http.listOutput(
        api: HttpApiEnum.api,
        route: "todos",
        queryBuilder: apiFilterBuilder,
      );
      return result.map(TodoListOutput.fromOutput).toList();
    } catch (e) {
      Logger().e("TodoService.getList: $e");
      rethrow;
    }
  }

  static Future<TodoDetailOutput> patch(int id, TodoPatchInput input) async {
    try {
      return TodoDetailOutput.fromOutput(await Http.input(
        method: HttpMethodEnum.patch,
        api: HttpApiEnum.api,
        route: "todos/$id",
        body: input,
      ));
    } catch (e) {
      Logger().e("TodoService.patch: $e");
      rethrow;
    }
  }

  static Future<void> delete(int id) async {
    try {
      await Http.request(
        method: HttpMethodEnum.delete,
        api: HttpApiEnum.api,
        route: "todos/$id",
      );
    } catch (e) {
      Logger().e("TodoService.delete: $e");
      rethrow;
    }
  }
}

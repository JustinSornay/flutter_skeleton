// todo_list_test.dart
//
// Widget tests for TodoList using the injectable `getList` seam.

import "package:flutter/material.dart";
import "package:flutter_skeleton/api/dtos/todo/output/list_output.dart";
import "package:flutter_skeleton/api/http/http_output.dart";
import "package:flutter_skeleton/api/services/_base/apiFilterBuilder/api_filter_builder.dart";
import "package:flutter_skeleton/widgets/core/render/TodoList/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";

import "../../helpers/widget_test_helpers.dart";

TodoListOutput _todo(int id, {bool completed = false}) {
  return TodoListOutput.fromOutput(HttpOutput.fromJson(<String, dynamic>{
    "id": id,
    "title": "Todo $id",
    "completed": completed,
  }));
}

void main() {
  testWidgets("requests page 1 and renders every todo with a status label", (WidgetTester tester) async {
    final List<Map<String, dynamic>> filters = <Map<String, dynamic>>[];
    Future<List<TodoListOutput>> fakeGetList([ApiFilterBuilder? filter]) async {
      filters.add(filter!.toMap());
      return <TodoListOutput>[_todo(1), _todo(2, completed: true)];
    }

    await pumpWithRouter(tester, TodoList(getList: fakeGetList));

    expect(filters.first, <String, dynamic>{"_page": "1", "_limit": "20"});
    expect(find.text("Todo 1"), findsOneWidget);
    expect(find.text("todos.status_pending"), findsOneWidget);
    expect(find.text("todos.status_done"), findsOneWidget);
  });

  testWidgets("tapping a todo navigates to its detail route", (WidgetTester tester) async {
    Future<List<TodoListOutput>> fakeGetList([ApiFilterBuilder? filter]) async => <TodoListOutput>[_todo(7)];

    await pumpWithRouter(
      tester,
      TodoList(getList: fakeGetList),
      extraRoutes: <RouteBase>[
        GoRoute(
          path: "/todos/:id",
          builder: (_, GoRouterState state) => Text("detail ${state.pathParameters["id"]}"),
        ),
      ],
    );

    await tester.tap(find.text("Todo 7"));
    await tester.pumpAndSettle();

    expect(find.text("detail 7"), findsOneWidget);
  });

  testWidgets("shows the error state with retry when loading fails", (WidgetTester tester) async {
    int calls = 0;
    Future<List<TodoListOutput>> fakeGetList([ApiFilterBuilder? filter]) async {
      calls++;
      if (calls == 1) throw Exception("offline");
      return <TodoListOutput>[_todo(1)];
    }

    await pumpWithRouter(tester, TodoList(getList: fakeGetList));
    expect(find.text("error.load_failed"), findsOneWidget);

    await tester.tap(find.text("common.retry"));
    await tester.pumpAndSettle();
    expect(find.text("Todo 1"), findsOneWidget);
  });
}

// todo_detail_test.dart
//
// Widget tests for TodoDetail using the injectable `getTodo` / `patchTodo`
// seams: loading → loaded, error → retry, toggle success and toggle failure.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_skeleton/api/dtos/todo/input/patch_input.dart";
import "package:flutter_skeleton/api/dtos/todo/output/detail_output.dart";
import "package:flutter_skeleton/api/http/api_exception.dart";
import "package:flutter_skeleton/api/http/http_output.dart";
import "package:flutter_skeleton/providers/error_provider.dart";
import "package:flutter_skeleton/widgets/core/decorators/SkeletonPulse/index.dart";
import "package:flutter_skeleton/widgets/core/render/TodoDetail/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:provider/provider.dart";

import "../../helpers/widget_test_helpers.dart";

TodoDetailOutput _todo({bool completed = false}) {
  return TodoDetailOutput.fromOutput(HttpOutput.fromJson(<String, dynamic>{
    "id": 1,
    "userId": 4,
    "title": "Write the README",
    "completed": completed,
  }));
}

void main() {
  testWidgets("shows a skeleton, then the todo", (WidgetTester tester) async {
    final Completer<TodoDetailOutput> response = Completer<TodoDetailOutput>();
    await pumpApp(
      tester,
      TodoDetail(todoId: 1, getTodo: (_) => response.future),
      providers: defaultTestProviders(),
    );
    expect(find.byType(SkeletonPulse), findsOneWidget);

    response.complete(_todo());
    await tester.pumpAndSettle();

    expect(find.byType(SkeletonPulse), findsNothing);
    expect(find.text("Write the README"), findsOneWidget);
    expect(find.text("todos.status_pending"), findsOneWidget);
  });

  testWidgets("shows the API error detail and retries", (WidgetTester tester) async {
    int calls = 0;
    await pumpApp(
      tester,
      TodoDetail(
        todoId: 1,
        getTodo: (_) async {
          calls++;
          if (calls == 1) throw const ApiException(status: 404, detail: "Not Found");
          return _todo();
        },
      ),
      providers: defaultTestProviders(),
    );
    await tester.pumpAndSettle();
    expect(find.text("Not Found"), findsOneWidget);

    await tester.tap(find.text("common.retry"));
    await tester.pumpAndSettle();
    expect(find.text("Write the README"), findsOneWidget);
  });

  testWidgets("toggling sends a PATCH and renders the response", (WidgetTester tester) async {
    TodoPatchInput? sent;
    await pumpApp(
      tester,
      TodoDetail(
        todoId: 1,
        getTodo: (_) async => _todo(),
        patchTodo: (int id, TodoPatchInput input) async {
          sent = input;
          return _todo(completed: true);
        },
      ),
      providers: defaultTestProviders(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(sent?.toJson(), <String, dynamic>{"completed": true});
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.text("todos.status_done"), findsOneWidget);
  });

  testWidgets("a failed PATCH keeps the value and reports through ErrorProvider", (WidgetTester tester) async {
    await pumpApp(
      tester,
      TodoDetail(
        todoId: 1,
        getTodo: (_) async => _todo(),
        patchTodo: (int id, TodoPatchInput input) async => throw Exception("offline"),
      ),
      providers: defaultTestProviders(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final ErrorProvider errors = Provider.of<ErrorProvider>(tester.element(find.byType(TodoDetail)), listen: false);
    expect(errors.current?.message, "error.save_failed");
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    errors.clear();
  });
}

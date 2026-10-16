// todo_detail_test.dart
//
// Widget tests for TodoDetail with a TodoController built on fake service
// calls: loading → loaded, error → retry, toggle success and toggle failure.
// The controller's own flows (toasts, 404 redirect, delete confirmation) are
// covered in test/widget/controllers/todo_controller_test.dart.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_skeleton/api/controllers/todo_controller.dart";
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
      TodoDetail(todoId: 1, controller: TodoController(getTodo: (_) => response.future)),
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
        controller: TodoController(
          getTodo: (_) async {
            calls++;
            if (calls == 1) throw const ApiException(status: 500, detail: "Server Error");
            return _todo();
          },
        ),
      ),
      providers: defaultTestProviders(),
    );
    await tester.pumpAndSettle();
    expect(find.text("Server Error"), findsOneWidget);

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
        controller: TodoController(
          getTodo: (_) async => _todo(),
          patchTodo: (int id, TodoPatchInput input) async {
            sent = input;
            return _todo(completed: true);
          },
        ),
      ),
      providers: defaultTestProviders(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(sent?.toJson(), <String, dynamic>{"completed": true});
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.text("todos.status_done"), findsOneWidget);
    Provider.of<ErrorProvider>(tester.element(find.byType(TodoDetail)), listen: false).clear();
  });

  testWidgets("disables both actions while a PATCH is in flight", (WidgetTester tester) async {
    final Completer<TodoDetailOutput> patch = Completer<TodoDetailOutput>();
    await pumpApp(
      tester,
      TodoDetail(
        todoId: 1,
        controller: TodoController(
          getTodo: (_) async => _todo(),
          patchTodo: (int id, TodoPatchInput input) => patch.future,
        ),
      ),
      providers: defaultTestProviders(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    expect(tester.widget<ButtonStyleButton>(find.widgetWithText(OutlinedButton, "todo.delete")).onPressed, isNull);

    patch.complete(_todo(completed: true));
    await tester.pumpAndSettle();
    expect(tester.widget<ButtonStyleButton>(find.widgetWithText(OutlinedButton, "todo.delete")).onPressed, isNotNull);
    Provider.of<ErrorProvider>(tester.element(find.byType(TodoDetail)), listen: false).clear();
  });

  testWidgets("a failed PATCH keeps the value and reports through ErrorProvider", (WidgetTester tester) async {
    await pumpApp(
      tester,
      TodoDetail(
        todoId: 1,
        controller: TodoController(
          getTodo: (_) async => _todo(),
          patchTodo: (int id, TodoPatchInput input) async => throw Exception("offline"),
        ),
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

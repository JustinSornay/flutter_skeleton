// todo_controller_test.dart
//
// Widget tests for TodoController: each flow is run from a context inside a
// small GoRouter shell (ModalConsumer for the confirmation modal) with fake
// service calls, and checked through its return value, the ErrorProvider
// toast and the router location.

import "package:flutter/material.dart";
import "package:flutter_skeleton/api/controllers/todo_controller.dart";
import "package:flutter_skeleton/api/dtos/todo/input/patch_input.dart";
import "package:flutter_skeleton/api/dtos/todo/output/detail_output.dart";
import "package:flutter_skeleton/api/http/api_exception.dart";
import "package:flutter_skeleton/api/http/http_output.dart";
import "package:flutter_skeleton/providers/error_provider.dart";
import "package:flutter_skeleton/providers/modal_provider.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/utils/load_state.dart";
import "package:flutter_skeleton/widgets/custom/ConfirmCard/index.dart";
import "package:flutter_skeleton/widgets/layout/ModalConsumer/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:provider/provider.dart";

TodoDetailOutput _todo({bool completed = false}) {
  return TodoDetailOutput.fromOutput(HttpOutput.fromJson(<String, dynamic>{
    "id": 1,
    "userId": 4,
    "title": "Write the README",
    "completed": completed,
  }));
}

/// The context a view model would pass, and the global toast channel.
final class _Harness {
  final BuildContext context;
  final ErrorProvider errors;

  const _Harness(this.context, this.errors);
}

/// Starts at `/todos/1` (a Builder exposing its context, under ModalConsumer);
/// `/` renders "list" so redirections are visible.
Future<_Harness> _pump(WidgetTester tester) async {
  final ErrorProvider errors = ErrorProvider();
  late BuildContext detailContext;
  final GoRouter router = GoRouter(
    initialLocation: "/todos/1",
    routes: <RouteBase>[
      GoRoute(path: "/", builder: (_, _) => const Scaffold(body: Text("list"))),
      GoRoute(
        path: "/todos/1",
        builder: (_, _) => ModalConsumer(
          child: Scaffold(
            body: Builder(builder: (BuildContext context) {
              detailContext = context;
              return const Text("detail");
            }),
          ),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<ErrorProvider>.value(value: errors),
        ChangeNotifierProvider<ModalProvider>(create: (_) => ModalProvider()),
      ],
      child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(detailContext, errors);
}

void main() {
  group("load", _loadTests);
  group("setCompleted", _setCompletedTests);
  group("delete", _deleteTests);
}

void _loadTests() {
  testWidgets("returns the todo as Loaded", (WidgetTester tester) async {
    final _Harness h = await _pump(tester);
    final TodoController controller = TodoController(getTodo: (_) async => _todo());

    final LoadState<TodoDetailOutput> state = await controller.load(h.context, 1);

    expect(state.dataOrNull?.title, "Write the README");
    expect(h.errors.current, isNull);
  });

  testWidgets("a server error becomes a LoadError without toast or redirection", (WidgetTester tester) async {
    final _Harness h = await _pump(tester);
    final TodoController controller = TodoController(
      getTodo: (_) async => throw const ApiException(status: 500, detail: "boom"),
    );

    final LoadState<TodoDetailOutput> state = await controller.load(h.context, 1);
    await tester.pumpAndSettle();

    expect((state as LoadError<TodoDetailOutput>).message, "boom");
    expect(h.errors.current, isNull);
    expect(find.text("detail"), findsOneWidget);
  });

  testWidgets("a 404 shows a warning and goes back to the list", (WidgetTester tester) async {
    final _Harness h = await _pump(tester);
    final TodoController controller = TodoController(
      getTodo: (_) async => throw const ApiException(status: 404, detail: "Not Found"),
    );

    final LoadState<TodoDetailOutput> state = await controller.load(h.context, 1);
    await tester.pumpAndSettle();

    expect(state, isA<LoadError<TodoDetailOutput>>());
    expect(h.errors.current?.message, "todo.not_found");
    expect(h.errors.current?.level, AppErrorLevel.warning);
    expect(find.text("list"), findsOneWidget);
    h.errors.clear();
  });
}

void _setCompletedTests() {
  testWidgets("sends the PATCH, shows a success toast and returns the todo", (WidgetTester tester) async {
    final _Harness h = await _pump(tester);
    TodoPatchInput? sent;
    final TodoController controller = TodoController(
      patchTodo: (int id, TodoPatchInput input) async {
        sent = input;
        return _todo(completed: true);
      },
    );

    final TodoDetailOutput? result = await controller.setCompleted(h.context, 1, true);

    expect(sent?.toJson(), <String, dynamic>{"completed": true});
    expect(result?.completed, isTrue);
    expect(h.errors.current?.message, "todo.saved");
    expect(h.errors.current?.level, AppErrorLevel.success);
    h.errors.clear();
  });

  testWidgets("a failure shows an error toast and returns null", (WidgetTester tester) async {
    final _Harness h = await _pump(tester);
    final TodoController controller = TodoController(
      patchTodo: (int id, TodoPatchInput input) async => throw Exception("offline"),
    );

    final TodoDetailOutput? result = await controller.setCompleted(h.context, 1, true);

    expect(result, isNull);
    expect(h.errors.current?.message, "error.save_failed");
    expect(h.errors.current?.level, AppErrorLevel.error);
    h.errors.clear();
  });
}

/// Starts [TodoController.delete] and waits until its confirmation modal is up.
Future<Future<bool>> _startDelete(WidgetTester tester, _Harness h, TodoController controller) async {
  final Future<bool> result = controller.delete(h.context, 1);
  await tester.pumpAndSettle();
  expect(find.byType(ConfirmCard), findsOneWidget);
  return result;
}

void _deleteTests() {
  testWidgets("cancel closes the modal without calling the API", (WidgetTester tester) async {
    final _Harness h = await _pump(tester);
    int calls = 0;
    final TodoController controller = TodoController(deleteTodo: (_) async => calls++);

    final Future<bool> result = await _startDelete(tester, h, controller);
    await tester.tap(find.text("common.cancel"));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
    expect(calls, 0);
    expect(find.byType(ConfirmCard), findsNothing);
    expect(find.text("detail"), findsOneWidget);
  });

  testWidgets("tapping the scrim counts as a cancel", (WidgetTester tester) async {
    final _Harness h = await _pump(tester);
    int calls = 0;
    final TodoController controller = TodoController(deleteTodo: (_) async => calls++);

    final Future<bool> result = await _startDelete(tester, h, controller);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
    expect(calls, 0);
    expect(find.byType(ConfirmCard), findsNothing);
  });

  testWidgets("confirm deletes, shows a success toast and goes back to the list", (WidgetTester tester) async {
    final _Harness h = await _pump(tester);
    final List<int> deleted = <int>[];
    final TodoController controller = TodoController(deleteTodo: (int id) async => deleted.add(id));

    final Future<bool> result = await _startDelete(tester, h, controller);
    await tester.tap(find.text("todo.delete"));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
    expect(deleted, <int>[1]);
    expect(h.errors.current?.message, "todo.deleted");
    expect(h.errors.current?.level, AppErrorLevel.success);
    expect(find.text("list"), findsOneWidget);
    h.errors.clear();
  });

  testWidgets("a 404 means already deleted: same outcome as a success", (WidgetTester tester) async {
    final _Harness h = await _pump(tester);
    final TodoController controller = TodoController(
      deleteTodo: (_) async => throw const ApiException(status: 404, detail: "Not Found"),
    );

    final Future<bool> result = await _startDelete(tester, h, controller);
    await tester.tap(find.text("todo.delete"));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
    expect(h.errors.current?.message, "todo.deleted");
    expect(find.text("list"), findsOneWidget);
    h.errors.clear();
  });

  testWidgets("a failure shows an error toast and stays on the page", (WidgetTester tester) async {
    final _Harness h = await _pump(tester);
    final TodoController controller = TodoController(
      deleteTodo: (_) async => throw const ApiException(status: 500, detail: "boom"),
    );

    final Future<bool> result = await _startDelete(tester, h, controller);
    await tester.tap(find.text("todo.delete"));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
    expect(h.errors.current?.message, "todo.delete_failed");
    expect(h.errors.current?.level, AppErrorLevel.error);
    expect(find.text("detail"), findsOneWidget);
    h.errors.clear();
  });
}

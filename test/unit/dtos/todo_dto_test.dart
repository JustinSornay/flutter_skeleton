// todo_dto_test.dart
//
// Unit tests for the demo todo DTOs.

import "package:flutter_skeleton/api/dtos/todo/input/patch_input.dart";
import "package:flutter_skeleton/api/dtos/todo/output/detail_output.dart";
import "package:flutter_skeleton/api/dtos/todo/output/list_output.dart";
import "package:flutter_skeleton/api/http/http_output.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  const Map<String, dynamic> json = <String, dynamic>{
    "userId": 3,
    "id": 42,
    "title": "Ship the skeleton",
    "completed": false,
  };

  test("TodoListOutput.fromOutput", () {
    final TodoListOutput todo = TodoListOutput.fromOutput(const HttpOutput.fromJson(json));
    expect(todo.id, 42);
    expect(todo.title, "Ship the skeleton");
    expect(todo.completed, isFalse);
  });

  test("TodoDetailOutput.fromOutput", () {
    final TodoDetailOutput todo = TodoDetailOutput.fromOutput(const HttpOutput.fromJson(json));
    expect(todo.userId, 3);
    expect(todo.id, 42);
  });

  test("TodoDetailOutput rejects a payload missing a field", () {
    expect(
      () => TodoDetailOutput.fromOutput(const HttpOutput.fromJson(<String, dynamic>{"id": 1})),
      throwsA(isA<AssertionError>()),
    );
  });

  test("TodoPatchInput serializes only the fields that are set", () {
    expect(const TodoPatchInput(completed: true).toJson(), <String, dynamic>{"completed": true});
    expect(const TodoPatchInput(title: "t").toJson(), <String, dynamic>{"title": "t"});
    expect(const TodoPatchInput().toJson(), isEmpty);
  });
}

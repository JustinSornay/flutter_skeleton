// index.dart
//
// TodoDetail — demo render widget: loads one todo, lets the user toggle its
// completion through a PATCH, and reports save failures via ErrorProvider.
//
// Shows the full MVVM triad with LoadState<T> and two injectable seams
// ([getTodo], [patchTodo]) defaulting to TodoService.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/api/dtos/todo/input/patch_input.dart";
import "package:flutter_skeleton/api/dtos/todo/output/detail_output.dart";
import "package:flutter_skeleton/api/http/api_exception.dart";
import "package:flutter_skeleton/api/services/todo_service.dart";
import "package:flutter_skeleton/providers/error_provider.dart";
import "package:flutter_skeleton/utils/load_state.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/core/decorators/SkeletonPulse/index.dart";
import "package:logger/logger.dart";
import "package:provider/provider.dart";

part "view_model.dart";
part "view.dart";

/// Detail view of a single todo.
final class TodoDetail extends StatefulWidget {
  final int todoId;

  /// Test seam — defaults to [TodoService.get].
  final Future<TodoDetailOutput> Function(int id)? getTodo;

  /// Test seam — defaults to [TodoService.patch].
  final Future<TodoDetailOutput> Function(int id, TodoPatchInput input)? patchTodo;

  const TodoDetail({
    super.key,
    required this.todoId,
    this.getTodo,
    this.patchTodo,
  });

  @override
  State<TodoDetail> createState() => _TodoDetailState();
}

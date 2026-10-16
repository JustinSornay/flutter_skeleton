// index.dart
//
// TodoDetail — demo render widget: loads one todo, lets the user toggle its
// completion or delete it.
//
// Shows the full MVVM triad with LoadState<T>. The calls and their feedback
// (toasts, confirmation modal, redirection) go through TodoController; the
// view model only keeps local UI state. Tests inject a [controller] built
// with fake service calls.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/api/controllers/todo_controller.dart";
import "package:flutter_skeleton/api/dtos/todo/output/detail_output.dart";
import "package:flutter_skeleton/utils/load_state.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/core/decorators/SkeletonPulse/index.dart";

part "view_model.dart";
part "view.dart";

/// Detail view of a single todo.
final class TodoDetail extends StatefulWidget {
  final int todoId;

  /// Test seam — defaults to a [TodoController] backed by TodoService.
  final TodoController? controller;

  const TodoDetail({
    super.key,
    required this.todoId,
    this.controller,
  });

  @override
  State<TodoDetail> createState() => _TodoDetailState();
}

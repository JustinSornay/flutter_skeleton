// todo_page.dart
//
// Route `/todos/:id` — demo todo detail.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/routing/templates/FullPageTemplate/index.dart";
import "package:flutter_skeleton/widgets/core/render/TodoDetail/index.dart";
import "package:go_router/go_router.dart";

/// Detail page for a single todo.
final class TodoPage extends StatelessWidget {
  final int todoId;

  const TodoPage({
    super.key,
    required this.todoId,
  });

  @override
  Widget build(BuildContext context) {
    return FullPageTemplate(
      title: "todo.title".tr(),
      onBack: () => context.go("/"),
      child: TodoDetail(todoId: todoId),
    );
  }
}

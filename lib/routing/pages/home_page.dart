// home_page.dart
//
// Route `/` — demo todo list. Pages are thin wrappers: a template plus the
// render widget(s) it hosts. No state, no service calls.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/routing/templates/FullPageTemplate/index.dart";
import "package:flutter_skeleton/widgets/core/render/TodoList/index.dart";

/// Landing page listing the demo todos.
final class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FullPageTemplate(
      title: "todos.title".tr(),
      child: const TodoList(),
    );
  }
}

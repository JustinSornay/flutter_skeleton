// index.dart
//
// AppHeader — the persistent top navigation bar rendered inside the GoRouter
// ShellRoute so it is shared across all pages.
//
// Contains the app title (links to /) and the navigation entries declared in
// data/nav_items.dart. Wide viewports show a row of links; narrow viewports
// collapse them into a menu button.
//
// The active route is tracked in the state (view_model.dart) by listening to
// GoRouter.routerDelegate — render() never subscribes to an InheritedWidget,
// which keeps GoRouter's init-time notifications from blocking pumpAndSettle.
//
// Related:
//   constants.dart  — kAppHeaderHeight (56 px), kNavBreakpoint
//   view_model.dart — _AppHeaderState (route listener lifecycle)
//   view.dart       — rendering (_ViewMixin)

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/data/nav_items.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/layout/AppHeader/constants.dart";
import "package:go_router/go_router.dart";

part "view_model.dart";
part "view.dart";

/// Persistent application header with navigation links.
final class AppHeader extends StatefulWidget {
  const AppHeader({super.key});

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

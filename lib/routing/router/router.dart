// router.dart
//
// GoRouter configuration for the entire application.
//
// Every in-app route is nested inside a ShellRoute that prepends AppHeader and
// mounts ModalConsumer (global modals). Unknown locations render NotFoundPage
// outside the shell.
//
// Route inventory:
//   /             — HomePage (demo todo list)
//   /todos/:id    — TodoPage (demo todo detail; non-numeric id → 404)
//   /settings     — SettingsPage
//
// Navigation rule: always context.go(), never context.push() — this is a
// URL-driven app and push() stacks history entries that break the back button.
//
// Route guards: add a `redirect` callback here (or on a GoRoute) and pass the
// providers it depends on as `refreshListenable` so GoRouter re-evaluates it.

import "package:flutter/material.dart";
import "package:flutter_skeleton/routing/pages/home_page.dart";
import "package:flutter_skeleton/routing/pages/not_found_page.dart";
import "package:flutter_skeleton/routing/pages/settings_page.dart";
import "package:flutter_skeleton/routing/pages/todo_page.dart";
import "package:flutter_skeleton/widgets/layout/AppHeader/index.dart";
import "package:flutter_skeleton/widgets/layout/ModalConsumer/index.dart";
import "package:go_router/go_router.dart";

// ─── Page transition helpers ──────────────────────────────────────────────
//
// Two variants, both short and skipped entirely under reduced motion:
//   _fadePage          — 180 ms fade. Main nav, peer-level swaps.
//   _fadeSlideUpPage   — 200 ms fade + subtle upward translate. Child/deep pages.

/// Fade-only transition. Use for peer-level navigation.
CustomTransitionPage<T> _fadePage<T>(Widget child, GoRouterState state) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 140),
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

/// Fade + subtle upward translate. Use for child/deep pages (detail views)
/// to signal hierarchical depth.
CustomTransitionPage<T> _fadeSlideUpPage<T>(Widget child, GoRouterState state) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 160),
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final CurvedAnimation curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Page builder for `/todos/:id`. A non-numeric id renders the 404 page.
Page<dynamic> _buildTodo(BuildContext context, GoRouterState state) {
  final int? id = int.tryParse(state.pathParameters["id"] ?? "");
  if (id == null) {
    return _fadePage(NotFoundPage(attemptedPath: state.uri.path), state);
  }
  return _fadeSlideUpPage(TodoPage(todoId: id), state);
}

/// Creates the app's [GoRouter]. Called once by the root widget, and by
/// widget tests with a custom [initialLocation].
GoRouter createRouter({String initialLocation = "/"}) {
  return GoRouter(
    initialLocation: initialLocation,
    errorBuilder: (BuildContext context, GoRouterState state) =>
        NotFoundPage(attemptedPath: state.uri.path),
    routes: <RouteBase>[
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return ModalConsumer(
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: <Widget>[
                  const AppHeader(),
                  Expanded(child: child),
                ],
              ),
            ),
          );
        },
        routes: <RouteBase>[
          GoRoute(
            path: "/",
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _fadePage(const HomePage(), state),
            routes: <RouteBase>[
              GoRoute(path: "todos/:id", pageBuilder: _buildTodo),
            ],
          ),
          GoRoute(
            path: "/settings",
            pageBuilder: (BuildContext context, GoRouterState state) =>
                _fadePage(const SettingsPage(), state),
          ),
        ],
      ),
    ],
  );
}

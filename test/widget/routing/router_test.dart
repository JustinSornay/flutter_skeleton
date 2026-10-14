// router_test.dart
//
// Widget tests for the application shell: routes, AppHeader navigation,
// 404 handling and translated strings (real assets via pumpLocalizedRouter).

import "package:flutter/material.dart";
import "package:flutter_skeleton/routing/pages/not_found_page.dart";
import "package:flutter_skeleton/widgets/layout/AppHeader/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";

import "../../helpers/widget_test_helpers.dart";

void main() {
  const Size desktop = Size(1280, 800);

  testWidgets("/settings renders inside the shell with translated strings", (WidgetTester tester) async {
    await pumpLocalizedRouter(tester, initialLocation: "/settings", surfaceSize: desktop);

    expect(find.byType(AppHeader), findsOneWidget);
    // "Réglages" appears in the header link (uppercased) and the page title.
    expect(find.text("Réglages"), findsOneWidget);
    expect(find.text("RÉGLAGES"), findsOneWidget);
    expect(find.text("Langue"), findsOneWidget);
  });

  testWidgets("unknown location renders the 404 page outside the shell", (WidgetTester tester) async {
    await pumpLocalizedRouter(tester, initialLocation: "/nope", surfaceSize: desktop);

    expect(find.byType(NotFoundPage), findsOneWidget);
    expect(find.byType(AppHeader), findsNothing);
    expect(find.text("/nope"), findsOneWidget);
    expect(find.text("Page introuvable"), findsOneWidget);
  });

  testWidgets("non-numeric todo id renders the 404 page", (WidgetTester tester) async {
    await pumpLocalizedRouter(tester, initialLocation: "/todos/abc", surfaceSize: desktop);

    expect(find.byType(NotFoundPage), findsOneWidget);
  });

  testWidgets("header link navigates with context.go", (WidgetTester tester) async {
    final GoRouter router = await pumpLocalizedRouter(tester, initialLocation: "/settings", surfaceSize: desktop);

    await tester.tap(find.text("TÂCHES"));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, "/");
  });

  testWidgets("narrow viewport collapses nav links into a menu", (WidgetTester tester) async {
    final GoRouter router = await pumpLocalizedRouter(tester, initialLocation: "/", surfaceSize: const Size(400, 800));

    expect(find.text("RÉGLAGES"), findsNothing);
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckedPopupMenuItem<String>, "Réglages"));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, "/settings");
  });

  testWidgets("switching language re-renders the shell in English", (WidgetTester tester) async {
    await pumpLocalizedRouter(tester, initialLocation: "/settings", surfaceSize: desktop);

    await tester.tap(find.text("English"));
    await tester.pumpAndSettle();

    expect(find.text("Language"), findsOneWidget);
    expect(find.text("SETTINGS"), findsOneWidget);
  });
}

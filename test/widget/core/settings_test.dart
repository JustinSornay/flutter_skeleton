// settings_test.dart
//
// Widget tests for Settings: the About dialog goes through ModalProvider and
// is dismissed by its close button.

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

void main() {
  testWidgets("About opens a modal that closes", (WidgetTester tester) async {
    await pumpLocalizedRouter(tester, initialLocation: "/settings", surfaceSize: const Size(1280, 800));

    await tester.tap(find.text("À propos"));
    await tester.pumpAndSettle();
    expect(find.text("Flutter Skeleton"), findsWidgets);
    expect(find.text("Fermer"), findsOneWidget);

    await tester.tap(find.text("Fermer"));
    await tester.pumpAndSettle();
    expect(find.text("Fermer"), findsNothing);
  });
}

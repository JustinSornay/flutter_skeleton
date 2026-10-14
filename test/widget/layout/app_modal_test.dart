// app_modal_test.dart
//
// Widget tests for the ModalProvider → ModalConsumer → AppModal chain.

import "package:flutter/material.dart";
import "package:flutter_skeleton/providers/modal_provider.dart";
import "package:flutter_skeleton/widgets/layout/AppModal/index.dart";
import "package:flutter_skeleton/widgets/layout/ModalConsumer/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:provider/provider.dart";

import "../../helpers/widget_test_helpers.dart";

void main() {
  Future<ModalProvider> pumpShell(WidgetTester tester) async {
    await pumpApp(
      tester,
      const ModalConsumer(child: Center(child: Text("page"))),
      providers: defaultTestProviders(),
    );
    return Provider.of<ModalProvider>(tester.element(find.text("page")), listen: false);
  }

  testWidgets("ModalProvider.show stacks the modal above the page", (WidgetTester tester) async {
    final ModalProvider modal = await pumpShell(tester);

    modal.show(AppModal(isVisible: true, onDismiss: modal.dismiss, child: const Text("dialog")));
    await tester.pumpAndSettle();

    expect(find.text("page"), findsOneWidget);
    expect(find.text("dialog"), findsOneWidget);
  });

  testWidgets("tapping the scrim dismisses, tapping the card does not", (WidgetTester tester) async {
    final ModalProvider modal = await pumpShell(tester);
    modal.show(AppModal(isVisible: true, onDismiss: modal.dismiss, child: const Text("dialog")));
    await tester.pumpAndSettle();

    await tester.tap(find.text("dialog"));
    await tester.pumpAndSettle();
    expect(find.text("dialog"), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text("dialog"), findsNothing);
    expect(modal.currentModal, isNull);
  });

  testWidgets("opens instantly under reduced motion", (WidgetTester tester) async {
    final ModalProvider modal = await pumpShell(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    modal.show(AppModal(isVisible: true, onDismiss: modal.dismiss, child: const Text("dialog")));
    await tester.pump();

    final FadeTransition fade = tester.widget<FadeTransition>(
      find.ancestor(of: find.text("dialog"), matching: find.byType(FadeTransition)).first,
    );
    expect(fade.opacity.value, 1.0);
  });
}

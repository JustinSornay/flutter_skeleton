// confirm_action_test.dart
//
// Widget tests for confirmAction: confirm, cancel, scrim tap, and a second
// modal replacing it (the first caller must not hang).

import "package:flutter/material.dart";
import "package:flutter_skeleton/api/controllers/_base/confirm_action.dart";
import "package:flutter_skeleton/providers/modal_provider.dart";
import "package:flutter_skeleton/widgets/custom/ConfirmCard/index.dart";
import "package:flutter_skeleton/widgets/layout/ModalConsumer/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:provider/provider.dart";

import "../../helpers/widget_test_helpers.dart";

Future<BuildContext> _pump(WidgetTester tester) async {
  await pumpApp(tester, const ModalConsumer(child: Center(child: Text("page"))), providers: defaultTestProviders());
  return tester.element(find.text("page"));
}

Future<bool> _ask(BuildContext context, String title) {
  return confirmAction(context, title: title, confirmLabel: "Yes", cancelLabel: "No");
}

void main() {
  testWidgets("completes with true on confirm and closes the modal", (WidgetTester tester) async {
    final BuildContext context = await _pump(tester);
    final Future<bool> answer = _ask(context, "Sure?");
    await tester.pumpAndSettle();

    await tester.tap(find.text("Yes"));
    await tester.pumpAndSettle();

    expect(await answer, isTrue);
    expect(find.byType(ConfirmCard), findsNothing);
  });

  testWidgets("completes with false on cancel and on a scrim tap", (WidgetTester tester) async {
    final BuildContext context = await _pump(tester);

    final Future<bool> cancelled = _ask(context, "Sure?");
    await tester.pumpAndSettle();
    await tester.tap(find.text("No"));
    await tester.pumpAndSettle();
    expect(await cancelled, isFalse);

    final Future<bool> dismissed = _ask(context, "Sure?");
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(await dismissed, isFalse);
    expect(find.byType(ConfirmCard), findsNothing);
  });

  testWidgets("a modal that replaces it completes it with false and stays open", (WidgetTester tester) async {
    final BuildContext context = await _pump(tester);
    final Future<bool> first = _ask(context, "First?");
    await tester.pumpAndSettle();

    final Future<bool> second = _ask(context, "Second?");
    await tester.pumpAndSettle();
    expect(await first, isFalse);
    expect(find.text("Second?"), findsOneWidget);

    await tester.tap(find.text("Yes"));
    await tester.pumpAndSettle();
    expect(await second, isTrue);
    expect(Provider.of<ModalProvider>(context, listen: false).currentModal, isNull);
  });
}

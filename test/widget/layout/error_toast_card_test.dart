// error_toast_card_test.dart
//
// Widget tests for ErrorToastCard driven by ErrorProvider.

import "package:flutter/material.dart";
import "package:flutter_skeleton/providers/error_provider.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/layout/ErrorToastCard/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:provider/provider.dart";

import "../../helpers/widget_test_helpers.dart";

void main() {
  testWidgets("renders nothing until an error is shown", (WidgetTester tester) async {
    await pumpApp(tester, const ErrorToastCard(), providers: defaultTestProviders());

    expect(find.byType(Material), findsOneWidget); // only the Scaffold's
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets("shows the message and clears on close", (WidgetTester tester) async {
    await pumpApp(tester, const ErrorToastCard(), providers: defaultTestProviders());
    final ErrorProvider provider = Provider.of<ErrorProvider>(
      tester.element(find.byType(ErrorToastCard)),
      listen: false,
    );

    provider.show("Save failed");
    await tester.pumpAndSettle();
    expect(find.text("Save failed"), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text("Save failed"), findsNothing);
    expect(provider.hasError, isFalse);
  });

  testWidgets("a success toast uses the success tone and a check icon", (WidgetTester tester) async {
    await pumpApp(tester, const ErrorToastCard(), providers: defaultTestProviders());
    final ErrorProvider provider = Provider.of<ErrorProvider>(
      tester.element(find.byType(ErrorToastCard)),
      listen: false,
    );

    provider.show("Saved", level: AppErrorLevel.success);
    await tester.pumpAndSettle();

    final ToneColors success = StatusTones.colorsOf(tester.element(find.text("Saved")), StatusTone.success);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    expect(tester.widget<Text>(find.text("Saved")).style?.color, success.onContainer);
    provider.clear();
    await tester.pumpAndSettle();
  });
}

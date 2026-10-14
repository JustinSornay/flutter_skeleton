// error_provider_test.dart
//
// Unit tests for ErrorProvider. testWidgets is used for its fake clock so the
// auto-dismiss timers can be advanced deterministically.

import "package:flutter_skeleton/providers/error_provider.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("show exposes the message and notifies", (WidgetTester tester) async {
    final ErrorProvider provider = ErrorProvider();
    addTearDown(provider.dispose);
    int notifications = 0;
    provider.addListener(() => notifications++);

    provider.show("Boom");

    expect(provider.hasError, isTrue);
    expect(provider.current?.message, "Boom");
    expect(provider.current?.level, AppErrorLevel.error);
    expect(notifications, 1);
    provider.clear();
  });

  testWidgets("errors auto-dismiss after 5 s, info after 3 s", (WidgetTester tester) async {
    final ErrorProvider provider = ErrorProvider();
    addTearDown(provider.dispose);

    provider.show("error");
    await tester.pump(const Duration(seconds: 4));
    expect(provider.hasError, isTrue);
    await tester.pump(const Duration(seconds: 1));
    expect(provider.hasError, isFalse);

    provider.show("info", level: AppErrorLevel.info);
    await tester.pump(const Duration(seconds: 3));
    expect(provider.hasError, isFalse);
  });

  testWidgets("a new message replaces the current one and restarts the timer", (WidgetTester tester) async {
    final ErrorProvider provider = ErrorProvider();
    addTearDown(provider.dispose);

    provider.show("first");
    await tester.pump(const Duration(seconds: 4));
    provider.show("second");
    await tester.pump(const Duration(seconds: 4));

    expect(provider.current?.message, "second");
    await tester.pump(const Duration(seconds: 1));
    expect(provider.hasError, isFalse);
  });
}

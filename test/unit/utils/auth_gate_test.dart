// auth_gate_test.dart
//
// Widget-level tests for requireAuth / AuthGate (a BuildContext is needed):
// token already present, no handler, handler success, failure, and a handler
// that reports success without a token.

import "package:flutter/widgets.dart";
import "package:flutter_skeleton/api/http/http.dart";
import "package:flutter_skeleton/utils/auth_gate.dart";
import "package:flutter_test/flutter_test.dart";

Future<BuildContext> _context(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  return tester.element(find.byType(SizedBox));
}

void main() {
  tearDown(() {
    AuthGate.reset();
    Http.resetAuthHooks();
  });

  testWidgets("returns true without asking when a token is present", (WidgetTester tester) async {
    final BuildContext context = await _context(tester);
    Http.setTokenProvider(() => "token");
    int asked = 0;
    AuthGate.setSignInHandler((_) async {
      asked++;
      return true;
    });

    expect(await requireAuth(context), isTrue);
    expect(asked, 0);
  });

  testWidgets("returns false when signed out and no handler is registered", (WidgetTester tester) async {
    final BuildContext context = await _context(tester);

    expect(await requireAuth(context), isFalse);
  });

  testWidgets("runs the handler and returns true once a token exists", (WidgetTester tester) async {
    final BuildContext context = await _context(tester);
    String? token;
    Http.setTokenProvider(() => token);
    BuildContext? received;
    AuthGate.setSignInHandler((BuildContext ctx) async {
      received = ctx;
      token = "fresh";
      return true;
    });

    expect(await requireAuth(context), isTrue);
    expect(received, same(context));
  });

  testWidgets("returns false when the user does not sign in", (WidgetTester tester) async {
    final BuildContext context = await _context(tester);
    AuthGate.setSignInHandler((_) async => false);

    expect(await requireAuth(context), isFalse);
  });

  testWidgets("returns false when the handler reports success without a token", (WidgetTester tester) async {
    final BuildContext context = await _context(tester);
    AuthGate.setSignInHandler((_) async => true);

    expect(await requireAuth(context), isFalse);
  });
}

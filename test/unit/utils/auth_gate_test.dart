// auth_gate_test.dart
//
// Widget-level tests for requireAuth / AuthGate (a BuildContext is needed):
// token already present, no handler, a flow that signs in or not, and
// concurrent calls sharing one flow.

import "dart:async";

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
    AuthGate.setSignInHandler((_) async => asked++);

    expect(await requireAuth(context), isTrue);
    expect(asked, 0);
  });

  testWidgets("returns false when signed out and no handler is registered", (WidgetTester tester) async {
    final BuildContext context = await _context(tester);

    expect(await requireAuth(context), isFalse);
  });

  testWidgets("runs the flow with the caller's context and returns true once a token exists", (WidgetTester tester) async {
    final BuildContext context = await _context(tester);
    String? token;
    Http.setTokenProvider(() => token);
    BuildContext? received;
    AuthGate.setSignInHandler((BuildContext ctx) async {
      received = ctx;
      token = "fresh";
    });

    expect(await requireAuth(context), isTrue);
    expect(received, same(context));
  });

  testWidgets("returns false when the flow ends without a token", (WidgetTester tester) async {
    final BuildContext context = await _context(tester);
    AuthGate.setSignInHandler((_) async {});

    expect(await requireAuth(context), isFalse);
  });

  testWidgets("concurrent calls share one running flow and all complete", (WidgetTester tester) async {
    final BuildContext context = await _context(tester);
    String? token;
    Http.setTokenProvider(() => token);
    final Completer<void> modalClosed = Completer<void>();
    int started = 0;
    AuthGate.setSignInHandler((_) {
      started++;
      return modalClosed.future;
    });

    final Future<bool> first = requireAuth(context);
    final Future<bool> second = requireAuth(context);
    token = "fresh";
    modalClosed.complete();

    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(started, 1);
  });

  testWidgets("a later call starts a new flow once the previous one ended", (WidgetTester tester) async {
    final BuildContext context = await _context(tester);
    int started = 0;
    AuthGate.setSignInHandler((_) async => started++);

    expect(await requireAuth(context), isFalse);
    expect(await requireAuth(context), isFalse);
    expect(started, 2);
  });
}

// email_verification_prompt_test.dart
//
// Widget tests for EmailVerificationPrompt: the send seam (after the first
// frame, resend, failures, overlapping sends, a host notifying listeners), the
// resend cooldown on the fake clock (including sub-second rounding), the check
// seam (not verified, pending, verified, failure, retry), the optional close
// button, disposal safety, accessibility (tap targets, contrast, header, live
// region) in light and dark themes, and the named-argument substitution with
// an in-memory translation loader. The backend calls are fake closures.

import "dart:async";

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/custom/EmailVerificationPrompt/index.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _title = "custom.email_verification_prompt.title";
const String _body = "custom.email_verification_prompt.body";
const String _confirm = "custom.email_verification_prompt.confirm";
const String _resendAction = "custom.email_verification_prompt.resend_action";
const String _resendCountdown = "custom.email_verification_prompt.resend_countdown";
const String _notVerified = "custom.email_verification_prompt.not_verified";
const String _checkFailed = "custom.email_verification_prompt.check_failed";
const String _close = "custom.email_verification_prompt.close";

/// Fake send: records each call, then completes, throws, or waits on its own
/// completer when [pending] is true.
final class _FakeSend {
  bool pending;
  bool fails;
  int calls = 0;
  final List<Completer<void>> waiting = <Completer<void>>[];

  _FakeSend({this.pending = false, this.fails = false});

  Future<void> call() {
    calls += 1;
    if (fails) return Future<void>.error(Exception("rate limited"));
    if (!pending) return Future<void>.value();
    final Completer<void> completer = Completer<void>();
    waiting.add(completer);
    return completer.future;
  }
}

/// Fake check: records each call and waits on its own completer.
final class _FakeCheck {
  int calls = 0;
  final List<Completer<bool>> waiting = <Completer<bool>>[];

  Future<bool> call() {
    calls += 1;
    final Completer<bool> completer = Completer<bool>();
    waiting.add(completer);
    return completer.future;
  }
}

final class _Harness {
  final _FakeSend send;
  final _FakeCheck check = _FakeCheck();
  int verified = 0;
  int dismissed = 0;

  _Harness([_FakeSend? send]) : send = send ?? _FakeSend();

  EmailVerificationPrompt prompt({
    bool dismissible = false,
    Duration resendCooldown = const Duration(seconds: 60),
  }) {
    return EmailVerificationPrompt(
      email: "j***@example.com",
      sendEmail: send.call,
      checkVerified: check.call,
      onVerified: () => verified += 1,
      onDismiss: dismissible ? () => dismissed += 1 : null,
      resendCooldown: resendCooldown,
    );
  }
}

/// Pumps [prompt] with pumpApp and lets the initial send settle.
Future<void> _pump(WidgetTester tester, Widget prompt, {ThemeData? theme}) async {
  await pumpApp(tester, prompt, theme: theme);
  await tester.pump();
}

/// Completes a future registered during the first build: its continuation
/// runs after the next frame, so a second frame shows the result.
Future<void> _flush(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

TextButton _textButton(WidgetTester tester, String label) {
  return tester.widget<TextButton>(
    find.ancestor(of: find.text(label), matching: find.byType(TextButton)),
  );
}

FilledButton _confirmButton(WidgetTester tester) {
  return tester.widget<FilledButton>(find.byType(FilledButton));
}

void main() {
  group("send and cooldown", () {
    testWidgets("sends once on mount and locks resend for 60 s", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await _pump(tester, harness.prompt());

      expect(harness.send.calls, 1);
      expect(find.text(_title), findsOneWidget);
      expect(find.text(_body), findsOneWidget);
      expect(_textButton(tester, _resendCountdown).onPressed, isNull);
      expect(find.text(_resendAction), findsNothing);

      await tester.pump(const Duration(seconds: 59));
      expect(_textButton(tester, _resendCountdown).onPressed, isNull);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text(_resendCountdown), findsNothing);
      expect(_textButton(tester, _resendAction).onPressed, isNotNull);
      expect(harness.send.calls, 1);
    });

    testWidgets("resend after the cooldown sends again and restarts it", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await _pump(tester, harness.prompt());
      await tester.pump(const Duration(seconds: 60));

      await tester.tap(find.text(_resendAction));
      await tester.pump();

      expect(harness.send.calls, 2);
      expect(_textButton(tester, _resendCountdown).onPressed, isNull);

      await tester.pump(const Duration(seconds: 60));
      expect(_textButton(tester, _resendAction).onPressed, isNotNull);
    });

    testWidgets("a failed send is swallowed and starts no cooldown", (WidgetTester tester) async {
      final _Harness harness = _Harness(_FakeSend(fails: true));
      await _pump(tester, harness.prompt());

      expect(tester.takeException(), isNull);
      expect(harness.send.calls, 1);
      expect(find.text(_notVerified), findsNothing);
      expect(find.text(_checkFailed), findsNothing);
      expect(_textButton(tester, _resendAction).onPressed, isNotNull);

      await tester.tap(find.text(_resendAction));
      await tester.pump();
      expect(harness.send.calls, 2);
      expect(_textButton(tester, _resendAction).onPressed, isNotNull);
    });

    testWidgets("resend is disabled while a send runs", (WidgetTester tester) async {
      final _Harness harness = _Harness(_FakeSend(pending: true));
      await _pump(tester, harness.prompt(resendCooldown: Duration.zero));

      expect(_textButton(tester, _resendAction).onPressed, isNull);
      harness.send.waiting.single.complete();
      await _flush(tester);
      expect(_textButton(tester, _resendAction).onPressed, isNotNull);

      await tester.tap(find.text(_resendAction));
      await tester.pump();
      expect(harness.send.calls, 2);
      expect(_textButton(tester, _resendAction).onPressed, isNull);

      await tester.tap(find.text(_resendAction), warnIfMissed: false);
      await tester.pump();
      expect(harness.send.calls, 2);

      harness.send.waiting.last.complete();
      await tester.pump();
      expect(_textButton(tester, _resendAction).onPressed, isNotNull);
    });

    testWidgets("a custom cooldown unlocks after its own duration", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await _pump(tester, harness.prompt(resendCooldown: const Duration(seconds: 5)));

      await tester.pump(const Duration(seconds: 4));
      expect(_textButton(tester, _resendCountdown).onPressed, isNull);
      await tester.pump(const Duration(seconds: 1));
      expect(_textButton(tester, _resendAction).onPressed, isNotNull);
    });

    testWidgets("a sub-second remainder rounds the cooldown up", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await _pump(tester, harness.prompt(resendCooldown: const Duration(milliseconds: 1500)));

      expect(_textButton(tester, _resendCountdown).onPressed, isNull);
      await tester.pump(const Duration(seconds: 1));
      expect(_textButton(tester, _resendCountdown).onPressed, isNull);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(_resendCountdown), findsNothing);
      expect(_textButton(tester, _resendAction).onPressed, isNotNull);
    });

    testWidgets("Duration.zero means no cooldown", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await _pump(tester, harness.prompt(resendCooldown: Duration.zero));

      expect(harness.send.calls, 1);
      expect(find.text(_resendCountdown), findsNothing);
      expect(_textButton(tester, _resendAction).onPressed, isNotNull);
    });

    testWidgets("a send notifying a listener outside the prompt is not run during build", (
      WidgetTester tester,
    ) async {
      final ValueNotifier<int> sends = ValueNotifier<int>(0);
      final ValueNotifier<bool> shown = ValueNotifier<bool>(false);
      addTearDown(sends.dispose);
      addTearDown(shown.dispose);
      final _Harness harness = _Harness();
      await pumpApp(
        tester,
        Column(
          children: <Widget>[
            ValueListenableBuilder<int>(
              valueListenable: sends,
              builder: (BuildContext context, int value, Widget? child) => Text("sends: $value"),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: shown,
              builder: (BuildContext context, bool value, Widget? child) => value
                  ? EmailVerificationPrompt(
                      email: "j***@example.com",
                      // Notifies before any await, like a provider calling
                      // notifyListeners() at the start of an async method.
                      sendEmail: () async => sends.value += 1,
                      checkVerified: harness.check.call,
                      onVerified: () => harness.verified += 1,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );

      shown.value = true;
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pump();

      expect(find.text("sends: 1"), findsOneWidget);
      expect(_textButton(tester, _resendCountdown).onPressed, isNull);
    });
  });

  group("verification check", () {
    testWidgets("not verified shows the spam hint in a live region", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await _pump(tester, harness.prompt());

      await tester.tap(find.text(_confirm));
      await tester.pump();
      harness.check.waiting.single.complete(false);
      await tester.pump();

      expect(find.text(_notVerified), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text(_notVerified),
          matching: find.byWidgetPredicate(
            (Widget widget) => widget is Semantics && widget.properties.liveRegion == true,
          ),
        ),
        findsOneWidget,
      );
      expect(harness.verified, 0);
      expect(_confirmButton(tester).onPressed, isNotNull);
    });

    testWidgets("a pending check shows the loader and ignores taps", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await _pump(tester, harness.prompt());

      await tester.tap(find.text(_confirm));
      await tester.pump();

      expect(find.byType(Loader), findsOneWidget);
      expect(find.text(_confirm), findsNothing);
      expect(_confirmButton(tester).onPressed, isNull);

      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();
      expect(harness.check.calls, 1);

      harness.check.waiting.single.complete(true);
      await tester.pump();

      expect(harness.verified, 1);
      expect(find.byType(Loader), findsNothing);
      // The host decides what happens next: the prompt never pops itself.
      expect(find.byType(EmailVerificationPrompt), findsOneWidget);
      expect(_confirmButton(tester).onPressed, isNull);
    });

    testWidgets("after success both buttons stay disabled", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await _pump(tester, harness.prompt(resendCooldown: Duration.zero));

      await tester.tap(find.text(_confirm));
      await tester.pump();
      harness.check.waiting.single.complete(true);
      await tester.pump();

      expect(_confirmButton(tester).onPressed, isNull);
      expect(_textButton(tester, _resendAction).onPressed, isNull);
      await tester.tap(find.text(_confirm), warnIfMissed: false);
      await tester.pump();
      expect(harness.check.calls, 1);
      expect(harness.verified, 1);
    });

    testWidgets("a failing check shows the generic error", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await _pump(tester, harness.prompt());

      await tester.tap(find.text(_confirm));
      await tester.pump();
      harness.check.waiting.single.completeError(Exception("network"));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text(_checkFailed), findsOneWidget);
      expect(find.text(_notVerified), findsNothing);
      expect(harness.verified, 0);
      expect(_confirmButton(tester).onPressed, isNotNull);
    });

    testWidgets("a new attempt clears the previous error", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await _pump(tester, harness.prompt());

      await tester.tap(find.text(_confirm));
      await tester.pump();
      harness.check.waiting.single.complete(false);
      await tester.pump();
      expect(find.text(_notVerified), findsOneWidget);

      await tester.tap(find.text(_confirm));
      await tester.pump();
      expect(find.text(_notVerified), findsNothing);
      expect(find.byType(Loader), findsOneWidget);

      harness.check.waiting.last.complete(true);
      await tester.pump();
      expect(harness.check.calls, 2);
      expect(harness.verified, 1);
    });
  });

  group("close button", () {
    testWidgets("is hidden without onDismiss", (WidgetTester tester) async {
      await _pump(tester, _Harness().prompt());
      expect(find.text(_close), findsNothing);
    });

    testWidgets("calls onDismiss when tapped", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await _pump(tester, harness.prompt(dismissible: true));

      await tester.tap(find.text(_close));
      await tester.pump();
      expect(harness.dismissed, 1);
    });
  });

  group("disposal", () {
    testWidgets("unmounting during the cooldown cancels the timer", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await _pump(tester, harness.prompt());
      expect(find.text(_resendCountdown), findsOneWidget);

      // No time passes after unmount: the framework's pending-timer check at
      // the end of the test fails unless dispose cancelled the timer.
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });

    testWidgets("late send and check results after unmount are ignored", (WidgetTester tester) async {
      final _Harness harness = _Harness(_FakeSend(pending: true));
      await _pump(tester, harness.prompt());
      await tester.tap(find.text(_confirm));
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      harness.send.waiting.single.complete();
      harness.check.waiting.single.complete(true);
      await tester.pump(const Duration(seconds: 61));

      expect(tester.takeException(), isNull);
      expect(harness.verified, 0);
    });
  });

  group("accessibility", () {
    for (final (String name, ThemeData Function() theme) in <(String, ThemeData Function())>[
      ("light", AppTheme.light),
      ("dark", AppTheme.dark),
    ]) {
      testWidgets("meets tap-target and contrast guidelines ($name)", (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        final _Harness harness = _Harness();
        await _pump(tester, harness.prompt(dismissible: true), theme: theme());

        await tester.tap(find.text(_confirm));
        await tester.pump();
        harness.check.waiting.single.complete(false);
        await tester.pump();

        expect(find.text(_notVerified), findsOneWidget);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }

    testWidgets("the title is a header and the icon is decorative", (WidgetTester tester) async {
      await _pump(tester, _Harness().prompt());

      expect(
        find.ancestor(
          of: find.text(_title),
          matching: find.byWidgetPredicate(
            (Widget widget) => widget is Semantics && widget.properties.header == true,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.byIcon(Icons.mark_email_unread_outlined),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });
  });

  group("translations", () {
    testWidgets("substitutes the email and the remaining seconds", (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await EasyLocalization.ensureInitialized();
      final _Harness harness = _Harness();

      // Loading translations sets easy_localization's global instance. The
      // finally block loads an empty map again, so `.tr()` returns raw keys
      // in the other tests whatever the order.
      try {
        await _pumpLocalized(tester, _MapLoader.substitution, harness.prompt());

        expect(find.text("Sent to j***@example.com."), findsOneWidget);
        expect(find.text("Resend in 60s"), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
        expect(find.text("Resend in 57s"), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpLocalized(tester, _MapLoader.empty, const SizedBox.shrink());
        await tester.pumpWidget(const SizedBox.shrink());
      }
      expect(_resendCountdown.tr(), _resendCountdown);
    });
  });
}

/// Mounts [child] under EasyLocalization fed by [loader], then lets the
/// translations load.
Future<void> _pumpLocalized(WidgetTester tester, _MapLoader loader, Widget child) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const <Locale>[Locale("en")],
      path: "unused",
      assetLoader: loader,
      startLocale: const Locale("en"),
      saveLocale: false,
      child: Builder(
        builder: (BuildContext context) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.light(),
          home: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// In-memory translations: the substitution map, or an empty map that puts
/// `.tr()` back to returning raw keys.
final class _MapLoader extends AssetLoader {
  final Map<String, dynamic> translations;

  const _MapLoader(this.translations);

  static const _MapLoader substitution = _MapLoader(<String, dynamic>{
    "custom": <String, dynamic>{
      "email_verification_prompt": <String, dynamic>{
        "body": "Sent to {email}.",
        "resend_countdown": "Resend in {seconds}s",
      },
    },
  });

  static const _MapLoader empty = _MapLoader(<String, dynamic>{});

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) {
    return Future<Map<String, dynamic>?>.value(translations);
  }
}

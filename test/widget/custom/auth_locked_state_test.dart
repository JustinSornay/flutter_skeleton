// auth_locked_state_test.dart
//
// Widget tests for AuthLockedState: content and defaults, label / icon
// overrides, the sign-in flow (onSignIn once per tap, onAuthenticated only
// on true and only while mounted), layout in a narrow area, tap target,
// semantics and theme tokens under the light and dark themes.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/AuthLockedState/index.dart";
import "package:flutter_skeleton/widgets/custom/StateMessageView/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _title = "Sign in to see this page";
const String _subtitle = "Your saved items appear here once you are signed in.";
const String _defaultLabel = "custom.auth_locked_state.sign_in";

Future<bool> _never() => Completer<bool>().future;

Future<void> _pump(WidgetTester tester, AuthLockedState widget, {ThemeData? theme, Size? surfaceSize}) {
  return pumpApp(tester, widget, theme: theme, surfaceSize: surfaceSize);
}

void main() {
  _contentTests();
  _flowTests();
  _layoutAndSemanticsTests();
  _themeTests();
}

void _contentTests() {
  group("content", () {
    testWidgets("renders title, subtitle, lock icon and the default label key", (WidgetTester tester) async {
      await _pump(tester, const AuthLockedState(title: _title, subtitle: _subtitle, onSignIn: _never));

      expect(find.text(_title), findsOneWidget);
      expect(find.text(_subtitle), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.widgetWithText(FilledButton, _defaultLabel), findsOneWidget);
      expect(
        find.descendant(of: find.byType(FilledButton), matching: find.byIcon(Icons.login_rounded)),
        findsOneWidget,
      );
    });

    testWidgets("composes a neutral StateMessageView with one primary action", (WidgetTester tester) async {
      await _pump(tester, const AuthLockedState(title: _title, subtitle: _subtitle, onSignIn: _never));

      final StateMessageView view = tester.widget<StateMessageView>(find.byType(StateMessageView));
      expect(view.tone, StatusTone.neutral);
      expect(view.title, _title);
      expect(view.message, _subtitle);
      expect(view.primaryAction?.label, _defaultLabel);
      expect(view.secondaryAction, isNull);
      expect(view.gauge, isNull);
    });

    testWidgets("actionLabel and icon overrides replace the defaults", (WidgetTester tester) async {
      await _pump(
        tester,
        const AuthLockedState(
          title: _title,
          subtitle: _subtitle,
          onSignIn: _never,
          actionLabel: "Connect account",
          icon: Icons.key_rounded,
        ),
      );

      expect(find.widgetWithText(FilledButton, "Connect account"), findsOneWidget);
      expect(find.text(_defaultLabel), findsNothing);
      expect(find.byIcon(Icons.key_rounded), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
    });
  });
}

void _flowTests() {
  group("sign-in flow", () {
    testWidgets("a tap calls onSignIn once; true calls onAuthenticated once", (WidgetTester tester) async {
      int signIns = 0;
      int authenticated = 0;
      await _pump(
        tester,
        AuthLockedState(
          title: _title,
          subtitle: _subtitle,
          onSignIn: () async {
            signIns++;
            return true;
          },
          onAuthenticated: () => authenticated++,
        ),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(signIns, 1);
      expect(authenticated, 1);
    });

    testWidgets("false never calls onAuthenticated", (WidgetTester tester) async {
      int signIns = 0;
      int authenticated = 0;
      await _pump(
        tester,
        AuthLockedState(
          title: _title,
          subtitle: _subtitle,
          onSignIn: () async {
            signIns++;
            return false;
          },
          onAuthenticated: () => authenticated++,
        ),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(signIns, 1);
      expect(authenticated, 0);
    });

    testWidgets("onAuthenticated waits for onSignIn to resolve", (WidgetTester tester) async {
      final Completer<bool> completer = Completer<bool>();
      int authenticated = 0;
      await _pump(
        tester,
        AuthLockedState(
          title: _title,
          subtitle: _subtitle,
          onSignIn: () => completer.future,
          onAuthenticated: () => authenticated++,
        ),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(authenticated, 0);

      completer.complete(true);
      await tester.pump();
      expect(authenticated, 1);
    });

    testWidgets("an unmounted widget does not call onAuthenticated", (WidgetTester tester) async {
      final Completer<bool> completer = Completer<bool>();
      int authenticated = 0;
      await _pump(
        tester,
        AuthLockedState(
          title: _title,
          subtitle: _subtitle,
          onSignIn: () => completer.future,
          onAuthenticated: () => authenticated++,
        ),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());

      completer.complete(true);
      await tester.pump();
      expect(authenticated, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets("a null onAuthenticated with a true result throws nothing", (WidgetTester tester) async {
      await _pump(
        tester,
        AuthLockedState(title: _title, subtitle: _subtitle, onSignIn: () async => true),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}

void _layoutAndSemanticsTests() {
  group("layout and semantics", () {
    testWidgets("a long subtitle lays out in a narrow, short area", (WidgetTester tester) async {
      await _pump(
        tester,
        AuthLockedState(title: _title, subtitle: List<String>.filled(30, _subtitle).join(" "), onSignIn: _never),
        surfaceSize: const Size(320, 480),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(FilledButton)).width, lessThanOrEqualTo(320));
    });

    testWidgets("the button meets the 48 dp tap target", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, const AuthLockedState(title: _title, subtitle: _subtitle, onSignIn: _never));

      expect(tester.getSize(find.byType(FilledButton)).height, greaterThanOrEqualTo(kMinTapTarget));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets("the title is a header and the icon is decorative", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, const AuthLockedState(title: _title, subtitle: _subtitle, onSignIn: _never));

      final SemanticsData data = tester.getSemantics(find.text(_title)).getSemanticsData();
      expect(data.flagsCollection.isHeader, isTrue);
      expect(
        find.ancestor(of: find.byIcon(Icons.lock_outline_rounded), matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
      expect(find.bySemanticsLabel(_defaultLabel), findsOneWidget);
      handle.dispose();
    });
  });
}

void _themeTests() {
  group("theme", () {
    Future<void> expectTokens(WidgetTester tester, ThemeData theme) async {
      await _pump(tester, const AuthLockedState(title: _title, subtitle: _subtitle, onSignIn: _never), theme: theme);
      final ColorScheme cs = Theme.of(tester.element(find.byType(AuthLockedState))).colorScheme;

      expect(cs.brightness, theme.brightness);
      expect(tester.widget<Icon>(find.byIcon(Icons.lock_outline_rounded)).color, cs.onSurfaceVariant);
      expect(tester.widget<Text>(find.text(_title)).style?.color, cs.onSurface);
      expect(tester.widget<Text>(find.text(_subtitle)).style?.color, cs.onSurfaceVariant);
      expect(tester.takeException(), isNull);
    }

    testWidgets("light theme tokens", (WidgetTester tester) async {
      await expectTokens(tester, AppTheme.light());
    });

    testWidgets("dark theme smoke test", (WidgetTester tester) async {
      await expectTokens(tester, AppTheme.dark());
    });
  });
}

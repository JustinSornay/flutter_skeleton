// quota_bar_test.dart
//
// Widget tests for QuotaBar: the derived state (clamping, ratio, limit,
// tone, action visibility, asserts), the limited layout (title, two-tone
// count, bar tokens and tones), the "limit reached" row and its action, the
// unlimited row, the label overrides, semantics, a narrow layout with long
// strings in both themes, a dark-theme tone smoke test, and the real strings
// (usage value, limit reached, unlimited) through an in-memory
// EasyLocalization. The localized tests reset the easy_localization
// singleton, so the raw-key tests pass in any order.

import "package:easy_localization/easy_localization.dart";
// Localization.load is the only way to empty the translations singleton that
// EasyLocalization fills; see _pumpLocalized.
// ignore: implementation_imports
import "package:easy_localization/src/localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/QuotaBar/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _title = "Saved items";
const String _action = "Upgrade";
const String _longTitle = "A very long title that cannot fit on one line of a narrow quota meter";
const String _limitKey = "custom.quota_bar.limit_reached";
const String _unlimitedKey = "custom.quota_bar.unlimited";
const String _usageKey = "custom.quota_bar.usage_value";

void _noop() {}

Finder _inBar(Finder matching) {
  return find.descendant(of: find.byType(QuotaBar), matching: matching);
}

LinearProgressIndicator _indicator(WidgetTester tester) {
  return tester.widget<LinearProgressIndicator>(_inBar(find.byType(LinearProgressIndicator)));
}

Color? _fill(WidgetTester tester) => _indicator(tester).valueColor?.value;

Text _text(WidgetTester tester, String data) => tester.widget<Text>(_inBar(find.text(data)));

BuildContext _context(WidgetTester tester) => tester.element(find.byType(QuotaBar));

ColorScheme _scheme(WidgetTester tester) => Theme.of(_context(tester)).colorScheme;

Color _tone(WidgetTester tester, StatusTone tone) {
  return StatusTones.colorsOf(_context(tester), tone).foreground;
}

/// The span of the count at [index] (0 = "used", 1 = "/limit").
TextSpan _countSpan(WidgetTester tester, String plain, int index) {
  final TextSpan root = _text(tester, plain).textSpan! as TextSpan;
  return root.children![index] as TextSpan;
}

Future<void> _pump(WidgetTester tester, QuotaBar bar, {ThemeData? theme, Size? surfaceSize}) {
  return pumpApp(
    tester,
    Padding(padding: const EdgeInsets.all(kDefaultPadding * 2), child: bar),
    theme: theme,
    surfaceSize: surfaceSize,
  );
}

/// In-memory translations matching the widget's i18n fragment, so the real
/// strings can be checked before the fragment is merged into assets.
final class _MemoryLoader extends AssetLoader {
  const _MemoryLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final bool fr = locale.languageCode == "fr";
    return <String, dynamic>{
      "custom": <String, dynamic>{
        "quota_bar": <String, dynamic>{
          "limit_reached": fr ? "Limite atteinte" : "Limit reached",
          "unlimited": fr ? "Illimité" : "Unlimited",
          "usage_value": fr ? "{used} sur {limit}" : "{used} of {limit}",
        },
      },
    };
  }
}

/// Pumps [bar] under EasyLocalization with the in-memory translations. The
/// loaded translations live in a singleton that outlives the test; the
/// tear-down empties it so every later `.tr()` returns the raw key again,
/// whatever the test order.
Future<void> _pumpLocalized(WidgetTester tester, Locale locale, QuotaBar bar) async {
  addTearDown(() => Localization.load(const Locale("fr")));
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const <Locale>[Locale("fr"), Locale("en")],
      path: "memory",
      fallbackLocale: const Locale("fr"),
      startLocale: locale,
      saveLocale: false,
      assetLoader: const _MemoryLoader(),
      child: Builder(
        builder: (BuildContext context) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.light(),
          home: Scaffold(
            body: Padding(padding: const EdgeInsets.all(kDefaultPadding * 2), child: bar),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The semantics value of the meter node labelled [_title].
String _meterValue(WidgetTester tester) => tester.getSemantics(find.bySemanticsLabel(_title)).value;

void main() {
  _derivedStateTests();
  _limitedLayoutTests();
  _limitTests();
  _actionTests();
  _unlimitedTests();
  _overrideAndSemanticsTests();
  _layoutTests();
  _darkThemeTests();
  _localizedTests();
}

void _derivedStateTests() {
  group("QuotaBar derived state", () {
    test("clamps used to [0, limit]", () {
      expect(const QuotaBar(title: _title, used: 5, limit: 3).displayedUsed, 3);
      expect(const QuotaBar(title: _title, used: -2, limit: 3).displayedUsed, 0);
      expect(const QuotaBar(title: _title, used: 2, limit: 3).displayedUsed, 2);
      expect(const QuotaBar(title: _title, used: 42).displayedUsed, 42);
      expect(const QuotaBar(title: _title, used: -1).displayedUsed, 0);
    });

    test("computes the ratio without dividing by zero", () {
      expect(const QuotaBar(title: _title, used: 1, limit: 4).ratio, 0.25);
      expect(const QuotaBar(title: _title, used: 9, limit: 4).ratio, 1.0);
      expect(const QuotaBar(title: _title, used: 3, limit: 0).ratio, 0.0);
      expect(const QuotaBar(title: _title, used: 3).ratio, 0.0);
    });

    test("maps the ratio to primary, warning and danger tones", () {
      const QuotaBar below = QuotaBar(title: _title, used: 3, limit: 5);
      const QuotaBar warning = QuotaBar(title: _title, used: 4, limit: 5);
      const QuotaBar full = QuotaBar(title: _title, used: 5, limit: 5);
      const QuotaBar empty = QuotaBar(title: _title, used: 0, limit: 0);
      const QuotaBar unlimited = QuotaBar(title: _title, used: 1000);

      expect(<StatusTone>[below.tone, warning.tone, full.tone, empty.tone, unlimited.tone], <StatusTone>[
        StatusTone.primary,
        StatusTone.warning,
        StatusTone.danger,
        StatusTone.danger,
        StatusTone.primary,
      ]);
      expect(<bool>[below.isWarning, warning.isWarning, full.isWarning], <bool>[false, true, true]);
      expect(<bool>[below.isAtLimit, warning.isAtLimit, full.isAtLimit, empty.isAtLimit, unlimited.isAtLimit], <bool>[
        false,
        false,
        true,
        true,
        false,
      ]);
      expect(unlimited.isUnlimited, isTrue);
      expect(full.isUnlimited, isFalse);
    });

    test("honours a custom warning threshold", () {
      expect(const QuotaBar(title: _title, used: 2, limit: 4, warningThreshold: 0.5).tone, StatusTone.warning);
      expect(const QuotaBar(title: _title, used: 2, limit: 4, warningThreshold: 0.9).tone, StatusTone.primary);
    });

    test("shows the action only at the limit with a label and a callback", () {
      expect(const QuotaBar(title: _title, used: 3, limit: 3, actionLabel: _action, onAction: _noop).showAction, isTrue);
      expect(const QuotaBar(title: _title, used: 2, limit: 3, actionLabel: _action, onAction: _noop).showAction, isFalse);
      expect(const QuotaBar(title: _title, used: 3, limit: 3, actionLabel: _action).showAction, isFalse);
      expect(const QuotaBar(title: _title, used: 3, limit: 3, onAction: _noop).showAction, isFalse);
      expect(const QuotaBar(title: _title, used: 3, actionLabel: _action, onAction: _noop).showAction, isFalse);
    });

    test("asserts a non-negative limit and a threshold in [0, 1]", () {
      int negative() => -1;
      double above() => 1.5;
      double below() => -0.1;
      expect(() => QuotaBar(title: _title, used: 0, limit: negative()), throwsAssertionError);
      expect(() => QuotaBar(title: _title, used: 0, limit: 3, warningThreshold: above()), throwsAssertionError);
      expect(() => QuotaBar(title: _title, used: 0, limit: 3, warningThreshold: below()), throwsAssertionError);
    });
  });
}

void _limitedLayoutTests() {
  group("QuotaBar limited layout", () {
    testWidgets("below the threshold: title, two-tone count, primary bar", (WidgetTester tester) async {
      await _pump(tester, const QuotaBar(title: _title, used: 1, limit: 3));

      expect(_inBar(find.text(_title)), findsOneWidget);
      final TextSpan used = _countSpan(tester, "1/3", 0);
      final TextSpan limit = _countSpan(tester, "1/3", 1);
      expect(used.text, "1");
      expect(used.style!.fontWeight, FontWeight.w800);
      expect(used.style!.color, _scheme(tester).primary);
      expect(limit.text, "/3");
      expect(limit.style!.fontWeight, FontWeight.w400);
      expect(limit.style!.color, _scheme(tester).onSurfaceVariant);

      expect(_indicator(tester).value, closeTo(1 / 3, 1e-9));
      expect(_fill(tester), _scheme(tester).primary);
      expect(_inBar(find.text(_limitKey)), findsNothing);
      expect(_inBar(find.byType(TextButton)), findsNothing);
    });

    testWidgets("uses the shared bar tokens and title style", (WidgetTester tester) async {
      await _pump(tester, const QuotaBar(title: _title, used: 1, limit: 3));

      final LinearProgressIndicator indicator = _indicator(tester);
      expect(indicator.backgroundColor, _scheme(tester).surfaceContainerHighest);
      expect(indicator.minHeight, 5);
      final ClipRRect clip = tester.widget<ClipRRect>(
        find.ancestor(of: find.byType(LinearProgressIndicator), matching: find.byType(ClipRRect)),
      );
      expect(clip.borderRadius, BorderRadius.circular(999));
      final Text title = _text(tester, _title);
      expect(title.style!.fontWeight, FontWeight.w700);
      expect(title.style!.color, _scheme(tester).onSurface);
    });

    testWidgets("from the threshold the bar and count use the warning tone", (WidgetTester tester) async {
      await _pump(tester, const QuotaBar(title: _title, used: 4, limit: 5));

      final Color warning = _tone(tester, StatusTone.warning);
      expect(_fill(tester), warning);
      expect(_countSpan(tester, "4/5", 0).style!.color, warning);
      expect(_inBar(find.text(_limitKey)), findsNothing);
    });

    testWidgets("a custom threshold moves the warning point", (WidgetTester tester) async {
      await _pump(tester, const QuotaBar(title: _title, used: 2, limit: 4, warningThreshold: 0.5));
      expect(_fill(tester), _tone(tester, StatusTone.warning));

      await _pump(tester, const QuotaBar(title: _title, used: 2, limit: 4, warningThreshold: 0.9));
      expect(_fill(tester), _scheme(tester).primary);
    });

    testWidgets("clamps an over-limit count", (WidgetTester tester) async {
      await _pump(tester, const QuotaBar(title: _title, used: 5, limit: 3));

      expect(_inBar(find.text("3/3")), findsOneWidget);
      expect(_inBar(find.text("5/3")), findsNothing);
      expect(_indicator(tester).value, 1.0);
    });

    testWidgets("clamps a negative count to zero", (WidgetTester tester) async {
      await _pump(tester, const QuotaBar(title: _title, used: -4, limit: 3));

      expect(_inBar(find.text("0/3")), findsOneWidget);
      expect(_indicator(tester).value, 0.0);
      expect(_fill(tester), _scheme(tester).primary);
    });
  });
}

void _limitTests() {
  group("QuotaBar at the limit", () {
    testWidgets("full danger bar and a live limit-reached row", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, const QuotaBar(title: _title, used: 3, limit: 3));

      final Color danger = _tone(tester, StatusTone.danger);
      expect(danger, _scheme(tester).error);
      expect(_indicator(tester).value, 1.0);
      expect(_fill(tester), danger);
      expect(_countSpan(tester, "3/3", 0).style!.color, danger);

      final Text status = _text(tester, _limitKey);
      expect(status.style!.color, danger);
      expect(status.style!.fontWeight, FontWeight.w600);
      expect(tester.getSemantics(_inBar(find.text(_limitKey))), isSemantics(label: _limitKey, isLiveRegion: true));
      handle.dispose();
    });

    testWidgets("a zero limit renders an empty bar at the limit", (WidgetTester tester) async {
      await _pump(tester, const QuotaBar(title: _title, used: 2, limit: 0));

      expect(tester.takeException(), isNull);
      expect(_inBar(find.text("0/0")), findsOneWidget);
      expect(_indicator(tester).value, 0.0);
      expect(_inBar(find.text(_limitKey)), findsOneWidget);
    });

    testWidgets("rebuilds when the count reaches the limit", (WidgetTester tester) async {
      await _pump(tester, const QuotaBar(title: _title, used: 1, limit: 2));
      expect(_inBar(find.text(_limitKey)), findsNothing);

      await _pump(tester, const QuotaBar(title: _title, used: 2, limit: 2));
      expect(_inBar(find.text(_limitKey)), findsOneWidget);
      expect(_fill(tester), _tone(tester, StatusTone.danger));
    });
  });
}

void _actionTests() {
  group("QuotaBar action", () {
    testWidgets("calls onAction once from a 48 dp text button", (WidgetTester tester) async {
      int taps = 0;
      await _pump(tester, QuotaBar(title: _title, used: 3, limit: 3, actionLabel: _action, onAction: () => taps++));

      final Finder button = _inBar(find.byType(TextButton));
      expect(button, findsOneWidget);
      final Size size = tester.getSize(button);
      expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTapTarget));

      final Text label = _text(tester, _action);
      expect(label.style!.color, _scheme(tester).primary);
      expect(label.style!.decoration, TextDecoration.underline);
      expect(label.style!.fontWeight, FontWeight.w700);

      await tester.tap(_inBar(find.text(_action)));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets("reports the action as an enabled button", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, const QuotaBar(title: _title, used: 3, limit: 3, actionLabel: _action, onAction: _noop));

      expect(
        tester.getSemantics(_inBar(find.byType(TextButton))),
        isSemantics(label: _action, isButton: true, isEnabled: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets("hides the action below the limit", (WidgetTester tester) async {
      await _pump(tester, const QuotaBar(title: _title, used: 2, limit: 3, actionLabel: _action, onAction: _noop));

      expect(_inBar(find.text(_action)), findsNothing);
      expect(_inBar(find.byType(TextButton)), findsNothing);
    });

    testWidgets("hides the action without a callback or a label", (WidgetTester tester) async {
      await _pump(tester, const QuotaBar(title: _title, used: 3, limit: 3, actionLabel: _action));
      expect(_inBar(find.text(_action)), findsNothing);
      expect(_inBar(find.text(_limitKey)), findsOneWidget);

      await _pump(tester, const QuotaBar(title: _title, used: 3, limit: 3, onAction: _noop));
      expect(_inBar(find.byType(TextButton)), findsNothing);
    });
  });
}

void _unlimitedTests() {
  group("QuotaBar unlimited", () {
    testWidgets("collapses to the title and the unlimited label", (WidgetTester tester) async {
      await _pump(tester, const QuotaBar(title: _title, used: 42, actionLabel: _action, onAction: _noop));

      expect(_inBar(find.text(_title)), findsOneWidget);
      final Text label = _text(tester, _unlimitedKey);
      expect(label.style!.color, _scheme(tester).primary);
      expect(label.style!.fontWeight, FontWeight.w600);
      expect(_inBar(find.byType(LinearProgressIndicator)), findsNothing);
      expect(_inBar(find.textContaining("42")), findsNothing);
      expect(_inBar(find.text(_limitKey)), findsNothing);
      expect(_inBar(find.text(_action)), findsNothing);
    });

    testWidgets("exposes the title and the unlimited label as one node", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, const QuotaBar(title: _title, used: 42));

      expect(tester.getSemantics(_inBar(find.text(_title))), isSemantics(label: _title, value: _unlimitedKey));
      handle.dispose();
    });
  });
}

void _overrideAndSemanticsTests() {
  group("QuotaBar overrides and semantics", () {
    testWidgets("label overrides replace the built-in strings", (WidgetTester tester) async {
      await _pump(tester, const QuotaBar(title: _title, used: 3, limit: 3, limitReachedLabel: "Full"));
      expect(_inBar(find.text("Full")), findsOneWidget);
      expect(_inBar(find.text(_limitKey)), findsNothing);

      await _pump(tester, const QuotaBar(title: _title, used: 3, unlimitedLabel: "No cap"));
      expect(_inBar(find.text("No cap")), findsOneWidget);
      expect(_inBar(find.text(_unlimitedKey)), findsNothing);
    });

    testWidgets("the meter exposes the title as label and the usage as value", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, const QuotaBar(title: _title, used: 1, limit: 3));

      expect(
        tester.getSemantics(_inBar(find.byType(LinearProgressIndicator))),
        isSemantics(label: _title, value: _usageKey),
      );
      handle.dispose();
    });
  });
}

void _layoutTests() {
  group("QuotaBar layout", () {
    for (final (String name, ThemeData Function() theme) in <(String, ThemeData Function())>[
      ("light", AppTheme.light),
      ("dark", AppTheme.dark),
    ]) {
      testWidgets("ellipsizes long strings at 320 dp ($name)", (WidgetTester tester) async {
        await _pump(
          tester,
          const QuotaBar(
            title: _longTitle,
            used: 999,
            limit: 999,
            limitReachedLabel: "The limit for this resource has been reached for the current period",
            actionLabel: "Upgrade to a larger plan to remove the limit entirely",
            onAction: _noop,
          ),
          theme: theme(),
          surfaceSize: const Size(320, 240),
        );

        expect(tester.takeException(), isNull);
        expect(_text(tester, _longTitle).overflow, TextOverflow.ellipsis);
        expect(_inBar(find.text("999/999")), findsOneWidget);
      });
    }

    testWidgets("ellipsizes a long title next to the default unlimited label", (WidgetTester tester) async {
      await _pump(tester, const QuotaBar(title: _longTitle, used: 1), surfaceSize: const Size(320, 120));

      expect(tester.takeException(), isNull);
      expect(_text(tester, _longTitle).overflow, TextOverflow.ellipsis);
      expect(_inBar(find.text(_unlimitedKey)), findsOneWidget);
    });

    testWidgets("ellipsizes a long unlimited label at 320 dp", (WidgetTester tester) async {
      const String long = "No limit on the current offer";
      await _pump(
        tester,
        const QuotaBar(title: "Items", used: 1, unlimitedLabel: long),
        surfaceSize: const Size(320, 120),
      );

      expect(tester.takeException(), isNull);
      final Text label = _text(tester, long);
      expect(label.maxLines, 1);
      expect(label.overflow, TextOverflow.ellipsis);
      expect(_inBar(find.text("Items")), findsOneWidget);
    });

    testWidgets("keeps a short unlimited label at the end of the row", (WidgetTester tester) async {
      await _pump(tester, const QuotaBar(title: _title, used: 1, unlimitedLabel: "No cap"));

      expect(
        tester.getTopRight(_inBar(find.text("No cap"))).dx,
        closeTo(tester.getTopRight(find.byType(QuotaBar)).dx, 0.01),
      );
    });
  });
}

void _darkThemeTests() {
  group("QuotaBar dark theme", () {
    testWidgets("resolves the tones from the dark scheme", (WidgetTester tester) async {
      await _pump(tester, const QuotaBar(title: _title, used: 4, limit: 5), theme: AppTheme.dark());

      final ColorScheme scheme = _scheme(tester);
      expect(scheme.brightness, Brightness.dark);
      expect(_fill(tester), StatusTones.fromScheme(scheme).warning.foreground);
      expect(_indicator(tester).backgroundColor, scheme.surfaceContainerHighest);

      await _pump(tester, const QuotaBar(title: _title, used: 5, limit: 5), theme: AppTheme.dark());
      expect(_fill(tester), _scheme(tester).error);
      expect(_text(tester, _limitKey).style!.color, _scheme(tester).error);
    });
  });
}

void _localizedTests() {
  group("QuotaBar localized", () {
    testWidgets("the meter value reads used of limit (en)", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(tester, const Locale("en"), const QuotaBar(title: _title, used: 1, limit: 3));

      expect(_meterValue(tester), "1 of 3");
      handle.dispose();
    });

    testWidgets("the meter value uses the clamped count", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(tester, const Locale("en"), const QuotaBar(title: _title, used: 5, limit: 3));

      expect(_meterValue(tester), "3 of 3");
      expect(find.text("Limit reached"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("renders the en unlimited label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(tester, const Locale("en"), const QuotaBar(title: _title, used: 1));

      expect(find.text("Unlimited"), findsOneWidget);
      expect(_meterValue(tester), "Unlimited");
      handle.dispose();
    });

    testWidgets("renders the fr strings", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(tester, const Locale("fr"), const QuotaBar(title: _title, used: 0, limit: 3));
      expect(_meterValue(tester), "0 sur 3");

      await _pumpLocalized(tester, const Locale("fr"), const QuotaBar(title: _title, used: 3, limit: 3));
      expect(_meterValue(tester), "3 sur 3");
      expect(find.text("Limite atteinte"), findsOneWidget);

      await _pumpLocalized(tester, const Locale("fr"), const QuotaBar(title: _title, used: 3));
      expect(find.text("Illimité"), findsOneWidget);
      handle.dispose();
    });
  });
}

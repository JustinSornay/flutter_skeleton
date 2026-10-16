// feature_gate_test.dart
//
// Widget tests for FeatureGate: the unlocked pass-through in every mode, then
// each locked mode (lock card, dimmed, teaser, hint, hidden): structure,
// default and custom strings, onUnlock wiring, the teaser never building the
// child, the dimmed child and the teaser mock staying inert (pointer,
// keyboard, screen readers), semantics, 48 dp targets, layout (the teaser pill
// at a 2x text scale) and the ColorScheme tokens under the light and dark
// themes. A last group reads the real fr / en semantics strings through
// EasyLocalization; it resets the easy_localization singleton afterwards, so
// the raw-key tests pass in any order.

import "package:easy_localization/easy_localization.dart";
// Localization.load is the only way to empty the translations singleton that
// EasyLocalization fills; see _pumpLocalized.
// ignore: implementation_imports
import "package:easy_localization/src/localization.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:flutter_skeleton/data/locales.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/FeatureGate/index.dart";
import "package:flutter_skeleton/widgets/custom/PillBadge/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _titleKey = "custom.feature_gate.title";
const String _lockedKey = "custom.feature_gate.locked";
const String _unlockKey = "custom.feature_gate.unlock";
const String _semanticsKey = "custom.feature_gate.semantics";

const String _label = "Export";
const String _badge = "Plus";
const Key _childKey = Key("child");
const Widget _child = Text("gated-content", key: _childKey);

FeatureGate _gate({
  bool isLocked = true,
  GateDisplayMode mode = GateDisplayMode.lockCard,
  String? lockedLabel = _label,
  String? badgeLabel = _badge,
  VoidCallback? onUnlock,
  WidgetBuilder? teaserBuilder,
  Widget child = _child,
}) {
  return FeatureGate(
    isLocked: isLocked,
    mode: mode,
    lockedLabel: lockedLabel,
    badgeLabel: badgeLabel,
    onUnlock: onUnlock,
    teaserBuilder: teaserBuilder,
    child: child,
  );
}

/// A tappable lock card with a custom button text.
FeatureGate _withAction(String actionLabel) {
  return FeatureGate(
    isLocked: true,
    lockedLabel: _label,
    actionLabel: actionLabel,
    onUnlock: () {},
    child: _child,
  );
}

Finder _inGate(Finder matching) {
  return find.descendant(of: find.byType(FeatureGate), matching: matching);
}

Finder _lockIcon() => _inGate(find.byIcon(Icons.lock_outline_rounded));

/// The gate's own container semantics node.
SemanticsData _gateSemantics(WidgetTester tester) {
  return tester.getSemantics(find.byType(FeatureGate)).getSemanticsData();
}

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(FeatureGate))).colorScheme;
}

/// Sends Tab then Enter [times] times, the way a keyboard user walks the
/// focus order and activates what it lands on.
Future<void> _tabAndEnter(WidgetTester tester, {int times = 1}) async {
  for (int i = 0; i < times; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
  }
}

/// Pumps [child] under EasyLocalization with the real translation assets in
/// [locale]. The loaded translations live in a singleton that outlives the
/// test; the tear-down empties it so every later `.tr()` returns the raw key
/// again, whatever the test order.
Future<void> _pumpLocalized(WidgetTester tester, Locale locale, Widget child) async {
  addTearDown(() => Localization.load(AppLocales.fallback));
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EasyLocalization.ensureInitialized();
  // Translation assets are read with real I/O, which fake-async test time
  // never completes on its own.
  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: AppLocales.supported,
        path: AppLocales.path,
        fallbackLocale: AppLocales.fallback,
        startLocale: locale,
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
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await tester.pumpAndSettle();
}

void main() {
  _unlockedTests();
  _lockCardTests();
  _dimmedTests();
  _teaserTests();
  _hintTests();
  _hiddenTests();
  _themeTests();
  _localizedTests();
}

void _unlockedTests() {
  group("FeatureGate — unlocked", () {
    for (final GateDisplayMode mode in GateDisplayMode.values) {
      testWidgets("returns the child unchanged in ${mode.name} mode", (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await pumpApp(tester, _gate(isLocked: false, mode: mode, onUnlock: () {}));

        expect(find.byKey(_childKey), findsOneWidget);
        expect(_lockIcon(), findsNothing);
        expect(_inGate(find.byType(PillBadge)), findsNothing);
        expect(_inGate(find.byType(InkWell)), findsNothing);
        expect(find.bySemanticsLabel(RegExp("custom.feature_gate")), findsNothing);
        handle.dispose();
      });
    }
  });
}

void _lockCardTests() {
  group("FeatureGate — lockCard", () {
    testWidgets("shows the lock icon, the label and the default button, not the child",
        (WidgetTester tester) async {
      await pumpApp(tester, _gate(onUnlock: () {}));

      expect(_lockIcon(), findsOneWidget);
      expect(find.text(_label), findsOneWidget);
      expect(find.widgetWithText(TextButton, _unlockKey), findsOneWidget);
      expect(find.byKey(_childKey), findsNothing);
      expect(_inGate(find.byType(PillBadge)), findsNothing);
    });

    testWidgets("is the default mode", (WidgetTester tester) async {
      await pumpApp(
        tester,
        FeatureGate(isLocked: true, lockedLabel: _label, onUnlock: () {}, child: _child),
      );

      expect(find.widgetWithText(TextButton, _unlockKey), findsOneWidget);
      expect(find.byKey(_childKey), findsNothing);
    });

    testWidgets("actionLabel overrides the button text; empty falls back", (WidgetTester tester) async {
      await pumpApp(tester, _withAction("Upgrade"));
      expect(find.widgetWithText(TextButton, "Upgrade"), findsOneWidget);
      expect(find.text(_unlockKey), findsNothing);

      await pumpApp(tester, _withAction(""));
      expect(find.widgetWithText(TextButton, _unlockKey), findsOneWidget);
    });

    testWidgets("tapping the button calls onUnlock once", (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(tester, _gate(onUnlock: () => taps++));

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets("no button when onUnlock is null", (WidgetTester tester) async {
      await pumpApp(tester, _gate());

      expect(_inGate(find.byType(TextButton)), findsNothing);
      expect(find.text(_unlockKey), findsNothing);
      expect(find.text(_label), findsOneWidget);
    });

    testWidgets("null or empty lockedLabel shows the default title", (WidgetTester tester) async {
      await pumpApp(tester, _gate(lockedLabel: null));
      expect(find.text(_titleKey), findsOneWidget);

      await pumpApp(tester, _gate(lockedLabel: ""));
      expect(find.text(_titleKey), findsOneWidget);
    });

    testWidgets("button is at least 48 × 48 dp", (WidgetTester tester) async {
      await pumpApp(tester, _withAction("Go"));

      final Size size = tester.getSize(find.byType(TextButton));
      expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
    });

    testWidgets("semantics: one container node, label read once, button is its own node",
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _gate(onUnlock: () {}));

      final SemanticsData gate = _gateSemantics(tester);
      expect(gate.label, _semanticsKey);
      expect(
        tester.getSemantics(find.byType(FeatureGate)),
        isSemantics(isButton: false, hasTapAction: false),
      );
      expect(
        tester.getSemantics(find.byType(TextButton)),
        isSemantics(label: _unlockKey, isButton: true, hasTapAction: true),
      );
      expect(find.bySemanticsLabel(_label), findsNothing);
      handle.dispose();
    });

    testWidgets("semantics: the default title alone when lockedLabel is null", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _gate(lockedLabel: null));

      expect(_gateSemantics(tester).label, _titleKey);
      handle.dispose();
    });

    testWidgets("label is cs.onSurface and the icon cs.onSurfaceVariant", (WidgetTester tester) async {
      await pumpApp(tester, _gate(onUnlock: () {}));
      final ColorScheme cs = _scheme(tester);

      expect(tester.widget<Text>(find.text(_label)).style?.color, cs.onSurface);
      expect(tester.widget<Icon>(_lockIcon()).color, cs.onSurfaceVariant);
    });

    testWidgets("meets the tap target and labelled target guidelines", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _gate(onUnlock: () {}));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });
}

void _dimmedTests() {
  group("FeatureGate — dimmed", () {
    testWidgets("renders the child at 0.4 opacity inside an ignoring IgnorePointer",
        (WidgetTester tester) async {
      await pumpApp(tester, _gate(mode: GateDisplayMode.dimmed, onUnlock: () {}));

      expect(find.byKey(_childKey), findsOneWidget);
      final Opacity opacity = tester.widget<Opacity>(
        find.ancestor(of: find.byKey(_childKey), matching: find.byType(Opacity)).first,
      );
      expect(opacity.opacity, closeTo(0.4, 0.001));
      final IgnorePointer ignore = tester.widget<IgnorePointer>(
        find.ancestor(of: find.byKey(_childKey), matching: find.byType(IgnorePointer)).first,
      );
      expect(ignore.ignoring, isTrue);
    });

    testWidgets("shows badgeLabel in a lock PillBadge; null or empty falls back", (WidgetTester tester) async {
      await pumpApp(tester, _gate(mode: GateDisplayMode.dimmed));
      final PillBadge badge = tester.widget<PillBadge>(_inGate(find.byType(PillBadge)));
      expect(badge.label, _badge);
      expect(badge.dense, isTrue);
      expect(badge.icon, Icons.lock_outline_rounded);

      await pumpApp(tester, _gate(mode: GateDisplayMode.dimmed, badgeLabel: null));
      expect(find.text(_lockedKey), findsOneWidget);

      await pumpApp(tester, _gate(mode: GateDisplayMode.dimmed, badgeLabel: ""));
      expect(find.text(_lockedKey), findsOneWidget);
    });

    testWidgets("the badge sits 4 dp inside the top-right corner", (WidgetTester tester) async {
      await pumpApp(tester, _gate(mode: GateDisplayMode.dimmed, onUnlock: () {}));

      expect(
        tester.getTopRight(_inGate(find.byType(PillBadge))),
        tester.getTopRight(find.byType(FeatureGate)) + const Offset(-kDefaultPadding / 2, kDefaultPadding / 2),
      );
    });

    testWidgets("tapping the area calls onUnlock; a button in the child never fires",
        (WidgetTester tester) async {
      int unlocks = 0;
      int inner = 0;
      await pumpApp(
        tester,
        _gate(
          mode: GateDisplayMode.dimmed,
          onUnlock: () => unlocks++,
          child: TextButton(onPressed: () => inner++, child: const Text("inner")),
        ),
      );

      await tester.tap(find.text("inner"), warnIfMissed: false);
      await tester.pump();

      expect(unlocks, 1);
      expect(inner, 0);
    });

    testWidgets("Tab + Enter reaches the unlock area, never a button in the child",
        (WidgetTester tester) async {
      int unlocks = 0;
      int inner = 0;
      await pumpApp(
        tester,
        _gate(
          mode: GateDisplayMode.dimmed,
          onUnlock: () => unlocks++,
          child: TextButton(onPressed: () => inner++, child: const Text("inner")),
        ),
      );

      await _tabAndEnter(tester, times: 4);

      expect(inner, 0);
      expect(unlocks, greaterThan(0));
    });

    testWidgets("without onUnlock, Tab + Enter cannot reach a button in the child",
        (WidgetTester tester) async {
      int inner = 0;
      await pumpApp(
        tester,
        _gate(
          mode: GateDisplayMode.dimmed,
          child: TextButton(onPressed: () => inner++, child: const Text("inner")),
        ),
      );

      await _tabAndEnter(tester, times: 2);

      expect(inner, 0);
      expect(
        tester.widget<ExcludeFocus>(
          find.ancestor(of: find.byType(TextButton), matching: find.byType(ExcludeFocus)).first,
        ).excluding,
        isTrue,
      );
    });

    testWidgets("without onUnlock nothing is tappable", (WidgetTester tester) async {
      await pumpApp(tester, _gate(mode: GateDisplayMode.dimmed));

      expect(_inGate(find.byType(InkWell)), findsNothing);
      expect(find.byKey(_childKey), findsOneWidget);
    });

    testWidgets("a small child still gets a 48 × 48 dp target", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: _gate(
            mode: GateDisplayMode.dimmed,
            onUnlock: () {},
            child: const SizedBox(width: 10, height: 10, key: _childKey),
          ),
        ),
      );

      final Size size = tester.getSize(_inGate(find.byType(InkWell)));
      expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
    });

    testWidgets("semantics: a button with the gate label and badge, child excluded",
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _gate(mode: GateDisplayMode.dimmed, onUnlock: () {}));

      expect(_gateSemantics(tester).label, "$_semanticsKey\n$_badge");
      expect(
        tester.getSemantics(find.byType(FeatureGate)),
        isSemantics(isButton: true, hasTapAction: true),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });
}

void _teaserTests() {
  group("FeatureGate — teaser", () {
    testWidgets("never builds the real child", (WidgetTester tester) async {
      bool built = false;
      await pumpApp(
        tester,
        _gate(
          mode: GateDisplayMode.teaser,
          onUnlock: () {},
          child: Builder(
            builder: (BuildContext context) {
              built = true;
              return _child;
            },
          ),
        ),
      );

      expect(built, isFalse);
      expect(find.byKey(_childKey), findsNothing);
    });

    testWidgets("renders the teaserBuilder content blurred under a scrim", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _gate(
          mode: GateDisplayMode.teaser,
          teaserBuilder: (BuildContext context) => const Text("mock", key: Key("mock")),
        ),
      );

      expect(find.byKey(const Key("mock")), findsOneWidget);
      expect(
        find.ancestor(of: find.byKey(const Key("mock")), matching: find.byType(ImageFiltered)),
        findsOneWidget,
      );
      final Opacity opacity = tester.widget<Opacity>(
        find.ancestor(of: find.byKey(const Key("mock")), matching: find.byType(Opacity)).first,
      );
      expect(opacity.opacity, closeTo(0.4, 0.001));
      expect(_inGate(find.byType(BackdropFilter)), findsOneWidget);
      // Label only in the pill: the placeholder is not used.
      expect(find.text(_label), findsOneWidget);
    });

    testWidgets("generic placeholder shows the label when teaserBuilder is null", (WidgetTester tester) async {
      await pumpApp(tester, _gate(mode: GateDisplayMode.teaser));

      // Once in the placeholder, once in the pill.
      expect(find.text(_label), findsNWidgets(2));
      expect(find.text(_badge), findsOneWidget);
    });

    testWidgets("is not tappable, even with onUnlock", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int unlocks = 0;
      await pumpApp(tester, _gate(mode: GateDisplayMode.teaser, onUnlock: () => unlocks++));

      expect(_inGate(find.byType(InkWell)), findsNothing);
      await tester.tap(find.text(_badge), warnIfMissed: false);
      await tester.pump();
      expect(unlocks, 0);

      // Exact: the placeholder label is not read a second time.
      expect(_gateSemantics(tester).label, "$_semanticsKey\n$_badge");
      expect(
        tester.getSemantics(find.byType(FeatureGate)),
        isSemantics(isButton: false, hasTapAction: false),
      );
      handle.dispose();
    });

    testWidgets("the host mock can be neither tapped nor read by screen readers",
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int presses = 0;
      await pumpApp(
        tester,
        _gate(
          mode: GateDisplayMode.teaser,
          onUnlock: () {},
          teaserBuilder: (BuildContext context) => TextButton(
            onPressed: () => presses++,
            child: const Text("mockbtn"),
          ),
        ),
      );

      await tester.tap(find.text("mockbtn"), warnIfMissed: false);
      await tester.pump();

      expect(presses, 0);
      final IgnorePointer ignore = tester.widget<IgnorePointer>(
        find.ancestor(of: find.byType(ImageFiltered), matching: find.byType(IgnorePointer)).first,
      );
      expect(ignore.ignoring, isTrue);
      expect(find.bySemanticsLabel("mockbtn"), findsNothing);
      expect(_gateSemantics(tester).label, "$_semanticsKey\n$_badge");
      handle.dispose();
    });

    testWidgets("Tab + Enter cannot reach a button in the host mock", (WidgetTester tester) async {
      int presses = 0;
      int unlocks = 0;
      await pumpApp(
        tester,
        _gate(
          mode: GateDisplayMode.teaser,
          onUnlock: () => unlocks++,
          teaserBuilder: (BuildContext context) => TextButton(
            onPressed: () => presses++,
            child: const Text("mockbtn"),
          ),
        ),
      );

      await _tabAndEnter(tester, times: 2);

      expect(presses, 0);
      expect(unlocks, 0);
    });

    testWidgets("the cs.scrim overlay at 30 % covers the whole teaser", (WidgetTester tester) async {
      await pumpApp(tester, _gate(mode: GateDisplayMode.teaser));
      final ColorScheme cs = _scheme(tester);

      final Finder scrimFinder = find.descendant(of: find.byType(BackdropFilter), matching: find.byType(ColoredBox));
      expect(tester.widget<ColoredBox>(scrimFinder).color, cs.scrim.withValues(alpha: 0.3));
      expect(tester.getRect(scrimFinder), tester.getRect(find.byType(FeatureGate)));
    });

    testWidgets("the pill is cs.surfaceContainerHighest with a cs.outlineVariant border",
        (WidgetTester tester) async {
      await pumpApp(tester, _gate(mode: GateDisplayMode.teaser));
      final ColorScheme cs = _scheme(tester);

      final Container pill = tester.widget<Container>(
        find.ancestor(of: _inGate(find.byType(PillBadge)), matching: find.byType(Container)).first,
      );
      final BoxDecoration decoration = pill.decoration! as BoxDecoration;
      expect(decoration.color, cs.surfaceContainerHighest);
      expect((decoration.border! as Border).top.color, cs.outlineVariant);
      expect(decoration.boxShadow?.single.color, cs.shadow.withValues(alpha: 0.06));
    });

    testWidgets("a tiny teaserBuilder still fits the pill without overflow", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Align(
          alignment: Alignment.topCenter,
          child: _gate(
            mode: GateDisplayMode.teaser,
            teaserBuilder: (BuildContext context) => const SizedBox(height: 4),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(FeatureGate)).height, greaterThanOrEqualTo(kMinTapTarget));
    });

    testWidgets("a tiny teaserBuilder grows to fit the whole pill at a 2x text scale",
        (WidgetTester tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(
        tester,
        Align(
          alignment: Alignment.topCenter,
          child: _gate(
            mode: GateDisplayMode.teaser,
            teaserBuilder: (BuildContext context) => const SizedBox(height: 4),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final RenderBox pill = tester.renderObject<RenderBox>(
        find.ancestor(of: _inGate(find.byType(PillBadge)), matching: find.byType(Container)).first,
      );
      final double pillNeeds = pill.getMinIntrinsicHeight(pill.size.width);
      expect(pillNeeds, greaterThan(kMinTapTarget));
      expect(pill.size.height, greaterThanOrEqualTo(pillNeeds));
      expect(tester.getSize(find.byType(FeatureGate)).height, greaterThanOrEqualTo(pillNeeds));
      final RenderParagraph badgeText = tester.renderObject<RenderParagraph>(find.text(_badge));
      expect(
        badgeText.size.height,
        greaterThanOrEqualTo(badgeText.getMinIntrinsicHeight(double.infinity)),
      );
    });
  });
}

void _hintTests() {
  group("FeatureGate — hint", () {
    testWidgets("shows the lock icon, the label and the badge, no button or child",
        (WidgetTester tester) async {
      await pumpApp(tester, _gate(mode: GateDisplayMode.hint, onUnlock: () {}));

      expect(_lockIcon(), findsWidgets);
      expect(find.text(_label), findsOneWidget);
      expect(find.text(_badge), findsOneWidget);
      expect(_inGate(find.byType(TextButton)), findsNothing);
      expect(find.text(_unlockKey), findsNothing);
      expect(find.byKey(_childKey), findsNothing);
    });

    testWidgets("tapping the row calls onUnlock", (WidgetTester tester) async {
      int unlocks = 0;
      await pumpApp(tester, _gate(mode: GateDisplayMode.hint, onUnlock: () => unlocks++));

      await tester.tap(_inGate(find.byType(InkWell)));
      await tester.pump();

      expect(unlocks, 1);
    });

    testWidgets("row is at least 48 dp tall", (WidgetTester tester) async {
      await pumpApp(tester, _gate(mode: GateDisplayMode.hint, onUnlock: () {}));

      expect(tester.getSize(_inGate(find.byType(InkWell))).height, greaterThanOrEqualTo(kMinTapTarget));
    });

    testWidgets("a long label ends with an ellipsis in a narrow parent", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _gate(mode: GateDisplayMode.hint, lockedLabel: "A very long feature name " * 6),
        surfaceSize: const Size(240, 400),
      );

      expect(tester.takeException(), isNull);
      final Text text = tester.widget<Text>(find.textContaining("A very long"));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets("semantics: a button with label and badge when onUnlock is set", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _gate(mode: GateDisplayMode.hint, onUnlock: () {}));

      final SemanticsData gate = _gateSemantics(tester);
      expect(gate.label, "$_semanticsKey\n$_badge");
      expect(
        tester.getSemantics(find.byType(FeatureGate)),
        isSemantics(isButton: true, hasTapAction: true),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets("semantics: no button and no tap without onUnlock", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _gate(mode: GateDisplayMode.hint));

      expect(_gateSemantics(tester).label, "$_semanticsKey\n$_badge");
      expect(
        tester.getSemantics(find.byType(FeatureGate)),
        isSemantics(isButton: false, hasTapAction: false),
      );
      handle.dispose();
    });
  });
}

void _hiddenTests() {
  group("FeatureGate — hidden", () {
    testWidgets("renders nothing while locked", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _gate(mode: GateDisplayMode.hidden, onUnlock: () {}));

      expect(find.byKey(_childKey), findsNothing);
      expect(_lockIcon(), findsNothing);
      expect(find.text(_unlockKey), findsNothing);
      expect(find.bySemanticsLabel(RegExp("custom.feature_gate")), findsNothing);
      expect(tester.getSize(find.byType(FeatureGate)), Size.zero);
      handle.dispose();
    });
  });
}

void _themeTests() {
  group("FeatureGate — themes", () {
    for (final ThemeData theme in <ThemeData>[AppTheme.light(), AppTheme.dark()]) {
      final String name = theme.brightness.name;

      testWidgets("every locked mode builds under the $name theme", (WidgetTester tester) async {
        for (final GateDisplayMode mode in GateDisplayMode.values) {
          await pumpApp(tester, _gate(mode: mode, onUnlock: () {}), theme: theme);
          expect(tester.takeException(), isNull, reason: mode.name);
        }
      });

      testWidgets("badge is cs.onPrimary on cs.primary under the $name theme", (WidgetTester tester) async {
        await pumpApp(tester, _gate(mode: GateDisplayMode.hint), theme: theme);
        final ColorScheme cs = _scheme(tester);

        final PillBadge badge = tester.widget<PillBadge>(_inGate(find.byType(PillBadge)));
        expect(badge.color, cs.onPrimary);
        expect(badge.backgroundColor, cs.primary);
        final Text label = tester.widget<Text>(find.text(_label));
        expect(label.style?.color, cs.onSurfaceVariant);
      });
    }
  });
}

void _localizedTests() {
  group("FeatureGate — real translations", () {
    final Map<Locale, String> expected = <Locale, String>{
      const Locale("fr"): "$_label : fonctionnalité verrouillée",
      const Locale("en"): "$_label: locked feature",
    };

    for (final MapEntry<Locale, String> entry in expected.entries) {
      testWidgets("the semantics label fills {label} in ${entry.key.languageCode}",
          (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await _pumpLocalized(tester, entry.key, _gate(onUnlock: () {}));

        expect(_gateSemantics(tester).label, entry.value);
        handle.dispose();
      });
    }
  });
}

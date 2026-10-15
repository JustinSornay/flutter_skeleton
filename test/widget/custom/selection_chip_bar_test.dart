// selection_chip_bar_test.dart
//
// Widget tests for SelectionChipBar: hidden / visible states, the slide +
// fade transition and reduced motion, the inert hidden bar (no focus, no
// semantics, even mid-exit), one chip per item in order with the rendered
// ChoiceOption fields, removal with a generic value, read-only and disabled
// chips, remove-button semantics, tooltip and 48 dp targets, the minItems /
// onAction rules of the action button, wrapping and the capped action label
// on narrow layouts, the ColorScheme tokens under the light and dark themes
// and the fr / en remove label through an in-memory EasyLocalization.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/SelectionChipBar/index.dart";
import "package:flutter_skeleton/widgets/custom/_base/choice_option.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _action = "Apply";

/// Without EasyLocalization in the tree, `.tr()` returns the raw key.
const String _removeKey = "custom.selection_chip_bar.remove";

const List<ChoiceOption<int>> _items = <ChoiceOption<int>>[
  ChoiceOption<int>(value: 10, label: "Alpha"),
  ChoiceOption<int>(value: 20, label: "Beta"),
  ChoiceOption<int>(value: 30, label: "Gamma"),
];

/// Records the callbacks of one bar.
final class _Calls {
  final List<int> removed = <int>[];
  int actions = 0;
}

SelectionChipBar<int> _bar(
  _Calls calls, {
  List<ChoiceOption<int>> items = _items,
  bool removable = true,
  bool actionable = true,
  int minItems = 1,
  String actionLabel = _action,
}) {
  return SelectionChipBar<int>(
    items: items,
    actionLabel: actionLabel,
    onRemove: removable ? calls.removed.add : null,
    onAction: actionable ? () => calls.actions++ : null,
    minItems: minItems,
  );
}

Finder _inBar(Finder matching) {
  return find.descendant(of: find.byType(SelectionChipBar<int>), matching: matching);
}

AnimatedSlide _slide(WidgetTester tester) => tester.widget<AnimatedSlide>(_inBar(find.byType(AnimatedSlide)));

AnimatedOpacity _fade(WidgetTester tester) => tester.widget<AnimatedOpacity>(_inBar(find.byType(AnimatedOpacity)));

/// The visibility IgnorePointer (the outermost one in the bar).
IgnorePointer _ignore(WidgetTester tester) => tester.widget<IgnorePointer>(_inBar(find.byType(IgnorePointer)).first);

double _translationY(WidgetTester tester) {
  return tester.widget<FractionalTranslation>(_inBar(find.byType(FractionalTranslation)).first).translation.dy;
}

/// The bar card (the outermost Material in the bar).
Material _barMaterial(WidgetTester tester) => tester.widget<Material>(_inBar(find.byType(Material)).first);

/// The chip Material holding [label].
Material _chipMaterial(WidgetTester tester, String label) {
  return tester.widget<Material>(find.ancestor(of: find.text(label), matching: find.byType(Material)).first);
}

/// The 48 dp InkResponse of the [index]-th remove button.
Finder _removeTarget(int index) {
  return find.ancestor(of: find.byIcon(Icons.close).at(index), matching: find.byType(InkResponse)).first;
}

FilledButton _button(WidgetTester tester) => tester.widget<FilledButton>(find.byType(FilledButton));

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(SelectionChipBar<int>))).colorScheme;
}

/// Whether the primary focus sits inside the bar.
bool _focusInBar() {
  final BuildContext? context = FocusManager.instance.primaryFocus?.context;
  return context?.findAncestorWidgetOfExactType<SelectionChipBar<int>>() != null;
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
        "selection_chip_bar": <String, dynamic>{
          "remove": fr ? "Retirer {label}" : "Remove {label}",
        },
      },
    };
  }
}

Future<void> _pumpLocalized(WidgetTester tester, Locale locale, Widget child) async {
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
          home: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Wraps [child] in the ambient MediaQuery with reduced motion turned on.
Widget _reducedMotion(Widget child) {
  return Builder(
    builder: (BuildContext context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child,
    ),
  );
}

void main() {
  group("visibility", () {
    testWidgets("empty: slid down, transparent, ignores pointers, no chips, no semantics", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_Calls(), items: const <ChoiceOption<int>>[]));

      expect(_slide(tester).offset, const Offset(0, 1));
      expect(_fade(tester).opacity, 0);
      expect(_ignore(tester).ignoring, isTrue);
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.bySemanticsLabel(_action), findsNothing);
    });

    testWidgets("with items: in place, opaque, hit-testable", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_Calls()));

      expect(_slide(tester).offset, Offset.zero);
      expect(_fade(tester).opacity, 1);
      expect(_ignore(tester).ignoring, isFalse);
      expect(find.bySemanticsLabel(_action), findsOneWidget);
    });

    testWidgets("slide uses kMotionShort / easeOutCubic, fade kMotionShort", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_Calls()));

      expect(_slide(tester).duration, kMotionShort);
      expect(_slide(tester).curve, Curves.easeOutCubic);
      expect(_fade(tester).duration, kMotionShort);
    });

    testWidgets("emptying the list slides the bar out over kMotionShort", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_Calls()));
      expect(_translationY(tester), 0);

      await pumpApp(tester, _bar(_Calls(), items: const <ChoiceOption<int>>[]));
      await tester.pump(kMotionShort ~/ 2);
      expect(_translationY(tester), greaterThan(0));
      expect(_translationY(tester), lessThan(1));
      expect(_ignore(tester).ignoring, isTrue);

      await tester.pump(kMotionShort);
      expect(_translationY(tester), 1);
    });

    testWidgets("reduced motion: zero durations, instant hide", (WidgetTester tester) async {
      await pumpApp(tester, _reducedMotion(_bar(_Calls())));

      expect(_slide(tester).duration, Duration.zero);
      expect(_fade(tester).duration, Duration.zero);

      await pumpApp(tester, _reducedMotion(_bar(_Calls(), items: const <ChoiceOption<int>>[])));
      await tester.pump();
      expect(_translationY(tester), 1);
    });

    testWidgets("hidden with minItems 0: the action cannot be focused or fired from the keyboard", (
      WidgetTester tester,
    ) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _bar(calls, items: const <ChoiceOption<int>>[], minItems: 0));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_focusInBar(), isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(calls.actions, 0);
    });

    testWidgets("emptying the list drops the focus held by the action", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _bar(calls, items: _items.sublist(0, 1), removable: false, minItems: 0));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_focusInBar(), isTrue);

      await pumpApp(tester, _bar(calls, items: const <ChoiceOption<int>>[], removable: false, minItems: 0));
      expect(_focusInBar(), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(calls.actions, 0);
    });

    testWidgets("leaves the live semantics tree as soon as the list empties", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_Calls()));
      expect(find.semantics.byLabel(_action), findsOne);

      await pumpApp(tester, _bar(_Calls(), items: const <ChoiceOption<int>>[]));
      await tester.pump(kMotionShort ~/ 2);
      expect(_translationY(tester), lessThan(1));
      expect(find.semantics.byLabel(_action), findsNothing);
      expect(find.semantics.byLabel(_removeKey), findsNothing);
    });
  });

  group("chips", () {
    testWidgets("one chip per item, in the given order", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_Calls()));

      for (final ChoiceOption<int> item in _items) {
        expect(find.text(item.label), findsOneWidget);
      }
      expect(find.byIcon(Icons.close), findsNWidgets(_items.length));
      final double alpha = tester.getTopLeft(find.text("Alpha")).dx;
      final double beta = tester.getTopLeft(find.text("Beta")).dx;
      final double gamma = tester.getTopLeft(find.text("Gamma")).dx;
      expect(alpha, lessThan(beta));
      expect(beta, lessThan(gamma));
    });

    testWidgets("label: 12 / w600 on one line with an ellipsis, cs.onSecondaryContainer", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_Calls()));

      final Text text = tester.widget<Text>(find.text("Alpha"));
      expect(text.style?.fontSize, 12);
      expect(text.style?.fontWeight, FontWeight.w600);
      expect(text.style?.color, _scheme(tester).onSecondaryContainer);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets("chip: cs.secondaryContainer, radius 8", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_Calls()));

      final Material chip = _chipMaterial(tester, "Alpha");
      expect(chip.color, _scheme(tester).secondaryContainer);
      expect(chip.borderRadius, BorderRadius.circular(8));
    });

    testWidgets("renders the 16 dp leading icon before the label", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _bar(_Calls(), items: const <ChoiceOption<int>>[
          ChoiceOption<int>(value: 1, label: "Alpha", icon: Icons.star_outline),
        ]),
      );

      final Icon icon = tester.widget<Icon>(find.byIcon(Icons.star_outline));
      expect(icon.size, 16);
      expect(icon.color, _scheme(tester).onSecondaryContainer);
      expect(
        tester.getTopLeft(find.byIcon(Icons.star_outline)).dx,
        lessThan(tester.getTopLeft(find.text("Alpha")).dx),
      );
    });

    testWidgets("description and trailing are not rendered", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _bar(_Calls(), items: const <ChoiceOption<int>>[
          ChoiceOption<int>(value: 1, label: "Alpha", description: "Second line", trailing: "7"),
        ]),
      );

      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("Second line"), findsNothing);
      expect(find.text("7"), findsNothing);
    });

    testWidgets("semanticsLabel replaces the spoken label", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _bar(_Calls(), items: const <ChoiceOption<int>>[
          ChoiceOption<int>(value: 1, label: "Alpha", semanticsLabel: "First selected entry"),
        ]),
      );

      expect(find.bySemanticsLabel("First selected entry"), findsOneWidget);
      expect(find.bySemanticsLabel("Alpha"), findsNothing);
      expect(find.text("Alpha"), findsOneWidget);
    });

    testWidgets("tapping the second remove button reports its value once", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _bar(calls));

      await tester.tap(_removeTarget(1));
      await tester.pump();

      expect(calls.removed, <int>[20]);
      expect(calls.actions, 0);
    });

    testWidgets("onRemove null: read-only chips, 32 dp tall, no remove button", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_Calls(), removable: false));

      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.bySemanticsLabel(_removeKey), findsNothing);
      expect(find.byTooltip(_removeKey), findsNothing);
      final Finder chip = find.ancestor(of: find.text("Alpha"), matching: find.byType(Material)).first;
      expect(tester.getSize(chip).height, kDefaultPadding * 4);
    });

    testWidgets("disabled item: dimmed to 38 %, remove button inert", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(
        tester,
        _bar(calls, items: const <ChoiceOption<int>>[
          ChoiceOption<int>(value: 1, label: "Alpha"),
          ChoiceOption<int>(value: 2, label: "Beta", enabled: false),
        ]),
      );

      final Finder dimmed = find.ancestor(of: find.text("Beta"), matching: find.byType(Opacity));
      expect(tester.widget<Opacity>(dimmed.first).opacity, 0.38);
      expect(find.ancestor(of: find.text("Alpha"), matching: find.byType(Opacity)), findsNothing);

      await tester.tap(_removeTarget(1));
      await tester.pump();
      expect(calls.removed, isEmpty);
      expect(
        tester.getSemantics(find.bySemanticsLabel(_removeKey).at(1)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );
    });

    testWidgets("disabled items still count towards minItems", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _bar(_Calls(), minItems: 2, items: const <ChoiceOption<int>>[
          ChoiceOption<int>(value: 1, label: "Alpha"),
          ChoiceOption<int>(value: 2, label: "Beta", enabled: false),
        ]),
      );

      expect(_button(tester).onPressed, isNotNull);
    });
  });

  group("remove button", () {
    testWidgets("one enabled button node per chip, labelled with the remove key", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_Calls()));

      expect(find.bySemanticsLabel(_removeKey), findsNWidgets(_items.length));
      expect(
        tester.getSemantics(find.bySemanticsLabel(_removeKey).first),
        isSemantics(
          label: _removeKey,
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets("shows the remove text as a tooltip", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_Calls()));

      expect(find.byTooltip(_removeKey), findsNWidgets(_items.length));
    });

    testWidgets("hit area is at least 48 × 48 with a 16 dp icon", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_Calls()));

      final Size size = tester.getSize(_removeTarget(0));
      expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
      expect(tester.widget<Icon>(find.byIcon(Icons.close).first).size, 16);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.close).first).color,
        _scheme(tester).onSecondaryContainer,
      );
    });
  });

  group("action button", () {
    testWidgets("shows actionLabel (13 / w700) and calls onAction once", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _bar(calls));

      final Text text = tester.widget<Text>(find.text(_action));
      expect(text.style?.fontSize, 13);
      expect(text.style?.fontWeight, FontWeight.w700);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(calls.actions, 1);
      expect(calls.removed, isEmpty);
    });

    testWidgets("default minItems (1) enables it with a single item", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_Calls(), items: _items.sublist(0, 1)));

      expect(_button(tester).onPressed, isNotNull);
    });

    testWidgets("disabled below minItems, enabled once reached", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _bar(calls, minItems: 2, items: _items.sublist(0, 1)));

      expect(_button(tester).onPressed, isNull);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(calls.actions, 0);

      await pumpApp(tester, _bar(calls, minItems: 2, items: _items.sublist(0, 2)));
      expect(_button(tester).onPressed, isNotNull);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(calls.actions, 1);
    });

    testWidgets("stays disabled without onAction", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_Calls(), actionable: false));

      expect(_button(tester).onPressed, isNull);
    });

    testWidgets("negative minItems is rejected", (WidgetTester tester) async {
      expect(
        () => SelectionChipBar<int>(items: _items, actionLabel: _action, minItems: -1),
        throwsAssertionError,
      );
    });

    testWidgets("is at least 48 × 48", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_Calls()));

      final Size size = tester.getSize(find.byType(FilledButton));
      expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
    });

    testWidgets("tokens: primary / onPrimary, disabled on the inverse surface", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_Calls()));
      final ColorScheme cs = _scheme(tester);
      final ButtonStyle style = _button(tester).style!;
      const Set<WidgetState> disabled = <WidgetState>{WidgetState.disabled};

      expect(style.backgroundColor?.resolve(<WidgetState>{}), cs.primary);
      expect(style.foregroundColor?.resolve(<WidgetState>{}), cs.onPrimary);
      expect(style.backgroundColor?.resolve(disabled), cs.onInverseSurface.withValues(alpha: 0.12));
      expect(style.foregroundColor?.resolve(disabled), cs.onInverseSurface.withValues(alpha: 0.38));
    });

    testWidgets("sits to the right of the chips", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_Calls()));

      expect(
        tester.getTopLeft(find.byType(FilledButton)).dx,
        greaterThan(tester.getTopRight(_removeTarget(_items.length - 1)).dx),
      );
    });
  });

  group("layout", () {
    testWidgets("narrow width: chips wrap onto several lines without overflow", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_Calls()), surfaceSize: const Size(320, 480));

      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(find.text("Gamma")).dy,
        greaterThan(tester.getTopLeft(find.text("Alpha")).dy),
      );
    });

    testWidgets("a very long label ellipsises instead of overflowing", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _bar(_Calls(), items: <ChoiceOption<int>>[
          ChoiceOption<int>(value: 1, label: List<String>.filled(40, "word").join(" ")),
        ]),
        surfaceSize: const Size(320, 480),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets("a long action label is capped and ellipsised, leaving room for a chip", (WidgetTester tester) async {
      const String label = "Export the selected entries as one file";
      await pumpApp(
        tester,
        _bar(_Calls(), items: _items.sublist(0, 1), actionLabel: label),
        surfaceSize: const Size(320, 480),
      );

      expect(tester.takeException(), isNull);
      final Text text = tester.widget<Text>(find.text(label));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      // 320 − 2 × 16 (margin) − 2 × 12 (padding) − 8 (gap) − 120 (chip room).
      expect(tester.getSize(find.byType(FilledButton)).width, lessThanOrEqualTo(136));
      expect(tester.getSize(find.byType(FilledButton)).height, greaterThanOrEqualTo(kMinTapTarget));
      expect(
        tester.getTopRight(_removeTarget(0)).dx,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(FilledButton)).dx),
      );
      expect(find.text("Alpha"), findsOneWidget);
      expect(find.semantics.byLabel(label), findsOne);
    });
  });

  group("theme", () {
    testWidgets("light: bar is cs.inverseSurface, elevation 6, cs.shadow, radius 12", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_Calls()));
      final ColorScheme cs = _scheme(tester);
      final Material bar = _barMaterial(tester);

      expect(bar.color, cs.inverseSurface);
      expect(bar.elevation, 6);
      expect(bar.shadowColor, cs.shadow);
      expect(bar.borderRadius, BorderRadius.circular(12));
    });

    testWidgets("dark smoke test: dark scheme tokens, no exception", (WidgetTester tester) async {
      await pumpApp(tester, _bar(_Calls()), theme: AppTheme.dark());
      final ColorScheme cs = _scheme(tester);

      expect(tester.takeException(), isNull);
      expect(cs.brightness, Brightness.dark);
      expect(_barMaterial(tester).color, cs.inverseSurface);
      expect(_chipMaterial(tester, "Alpha").color, cs.secondaryContainer);
      expect(tester.widget<Text>(find.text("Alpha")).style?.color, cs.onSecondaryContainer);
    });
  });

  // Last: EasyLocalization keeps the loaded translations in a singleton, so
  // pumpApp tests that follow would read them instead of the raw keys.
  group("translations", () {
    testWidgets("fr: remove label and tooltip substitute the item label", (WidgetTester tester) async {
      await _pumpLocalized(tester, const Locale("fr"), _bar(_Calls(), items: _items.sublist(0, 2)));

      expect(
        tester.getSemantics(find.bySemanticsLabel("Retirer Alpha")),
        isSemantics(label: "Retirer Alpha", isButton: true),
      );
      expect(find.semantics.byLabel("Retirer Beta"), findsOne);
      expect(find.byTooltip("Retirer Alpha"), findsOneWidget);
      expect(find.byTooltip("Retirer Beta"), findsOneWidget);
    });

    testWidgets("en: remove label and tooltip substitute the item label", (WidgetTester tester) async {
      await _pumpLocalized(tester, const Locale("en"), _bar(_Calls(), items: _items.sublist(0, 2)));

      expect(
        tester.getSemantics(find.bySemanticsLabel("Remove Alpha")),
        isSemantics(label: "Remove Alpha", isButton: true),
      );
      expect(find.semantics.byLabel("Remove Beta"), findsOne);
      expect(find.byTooltip("Remove Alpha"), findsOneWidget);
      expect(find.byTooltip("Remove Beta"), findsOneWidget);
    });
  });
}

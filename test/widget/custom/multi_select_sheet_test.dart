// multi_select_sheet_test.dart
//
// Widget tests for MultiSelectSheet<K>: header, counter, rows and badges,
// toggling by row or checkbox, initial selection, the optional cap, disabled
// options, the confirm button and its payload, empty state, custom labels,
// the capped list height, semantics and tap targets, real translations,
// the selection clean-up after a host rebuild, the dark theme, and hosting in
// an AppModal and a modal bottom sheet.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/providers/modal_provider.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/MultiSelectSheet/index.dart";
import "package:flutter_skeleton/widgets/custom/_base/choice_option.dart";
import "package:flutter_skeleton/widgets/layout/AppModal/index.dart";
import "package:flutter_skeleton/widgets/layout/ModalConsumer/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:provider/provider.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _title = "Pick items";
const String _counterKey = "custom.multi_select_sheet.counter";
const String _counterMaxKey = "custom.multi_select_sheet.counter_max";
const String _emptyKey = "custom.multi_select_sheet.empty";
const String _confirmKey = "custom.multi_select_sheet.confirm";

const List<ChoiceOption<int>> _options = <ChoiceOption<int>>[
  ChoiceOption<int>(value: 1, label: "Alpha", trailing: "12 u"),
  ChoiceOption<int>(value: 2, label: "Beta", trailing: "3 u"),
  ChoiceOption<int>(value: 3, label: "Gamma"),
];

/// Records every onConfirm payload.
final class _Calls {
  final List<Set<int>> confirmed = <Set<int>>[];

  void confirm(Set<int> values) => confirmed.add(values);
}

MultiSelectSheet<int> _sheet(
  _Calls calls, {
  List<ChoiceOption<int>> options = _options,
  Set<int> initialSelection = const <int>{},
  int? max,
  String? emptyLabel,
  String? confirmLabel,
}) {
  return MultiSelectSheet<int>(
    title: _title,
    options: options,
    onConfirm: calls.confirm,
    initialSelection: initialSelection,
    max: max,
    emptyLabel: emptyLabel,
    confirmLabel: confirmLabel,
  );
}

/// The tappable row (InkWell) holding [label].
Finder _row(String label) {
  return find.ancestor(of: find.text(label), matching: find.byType(InkWell));
}

/// The checkbox inside the row holding [label].
Checkbox _checkbox(WidgetTester tester, String label) {
  return tester.widget<Checkbox>(
    find.descendant(of: _row(label), matching: find.byType(Checkbox)),
  );
}

FilledButton _confirmButton(WidgetTester tester) {
  return tester.widget<FilledButton>(find.byType(FilledButton));
}

/// Decoration of the pill holding [text].
BoxDecoration _pillDecoration(WidgetTester tester, String text) {
  final DecoratedBox box = tester.widget<DecoratedBox>(
    find.ancestor(of: find.text(text), matching: find.byType(DecoratedBox)).first,
  );
  return box.decoration as BoxDecoration;
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
        "multi_select_sheet": <String, dynamic>{
          "confirm": fr ? "Valider" : "Confirm",
          "empty": fr ? "Aucun élément disponible." : "No items available.",
          "counter": fr ? "{count} sélectionné(s)" : "{count} selected",
          "counter_max": fr ? "{count}/{max} sélectionné(s)" : "{count}/{max} selected",
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

void main() {
  group("MultiSelectSheet rendering", () {
    testWidgets("renders the title, one checkbox row per option and the default labels", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls()));

      expect(find.text(_title), findsOneWidget);
      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("Beta"), findsOneWidget);
      expect(find.text("Gamma"), findsOneWidget);
      expect(find.byType(Checkbox), findsNWidgets(_options.length));
      expect(find.text(_counterKey), findsOneWidget);
      expect(find.text(_confirmKey), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(_options.length - 1));
    });

    testWidgets("shows a badge pill only for a non-empty trailing", (WidgetTester tester) async {
      const List<ChoiceOption<int>> options = <ChoiceOption<int>>[
        ChoiceOption<int>(value: 1, label: "Alpha", trailing: "12 u"),
        ChoiceOption<int>(value: 2, label: "Beta", trailing: ""),
        ChoiceOption<int>(value: 3, label: "Gamma"),
      ];
      await pumpApp(tester, _sheet(_Calls(), options: options));

      expect(find.text("12 u"), findsOneWidget);
      expect(find.descendant(of: _row("Alpha"), matching: find.byType(DecoratedBox)), findsOneWidget);
      expect(find.descendant(of: _row("Beta"), matching: find.byType(DecoratedBox)), findsNothing);
      expect(find.descendant(of: _row("Gamma"), matching: find.byType(DecoratedBox)), findsNothing);
    });

    testWidgets("uses theme tokens for the title, labels, pills and dividers", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls(), max: 2));
      final ColorScheme cs = Theme.of(tester.element(find.byType(MultiSelectSheet<int>))).colorScheme;

      expect(tester.widget<Text>(find.text(_title)).style?.color, cs.onSurface);
      expect(tester.widget<Text>(find.text("Alpha")).style?.color, cs.onSurface);
      expect(tester.widget<Text>(find.text("12 u")).style?.color, cs.onSurfaceVariant);
      expect(tester.widget<Text>(find.text(_counterMaxKey)).style?.color, cs.onSurfaceVariant);

      final BoxDecoration badge = _pillDecoration(tester, "12 u");
      expect(badge.color, cs.surfaceContainerHighest);
      expect(badge.borderRadius, BorderRadius.circular(4));
      expect(badge.border, Border.all(color: cs.outlineVariant));
      final BoxDecoration counter = _pillDecoration(tester, _counterMaxKey);
      expect(counter.color, cs.surfaceContainerHighest);
      expect(counter.borderRadius, BorderRadius.circular(999));
      expect(counter.border, Border.all(color: cs.outlineVariant));

      final Divider divider = tester.widget<Divider>(find.byType(Divider).first);
      expect(divider.color, cs.outlineVariant);
      expect(divider.height, 1);
    });

    testWidgets("truncates a long label to one line", (WidgetTester tester) async {
      final String long = "Very long label " * 20;
      await pumpApp(
        tester,
        _sheet(_Calls(), options: <ChoiceOption<int>>[ChoiceOption<int>(value: 1, label: long, trailing: "9 u")]),
      );

      final Text text = tester.widget<Text>(find.text(long));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });
  });

  group("MultiSelectSheet selection", () {
    testWidgets("tapping a row or its checkbox toggles it", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls()));

      expect(_checkbox(tester, "Alpha").value, isFalse);
      await tester.tap(find.text("Alpha"));
      await tester.pump();
      expect(_checkbox(tester, "Alpha").value, isTrue);

      await tester.tap(find.descendant(of: _row("Alpha"), matching: find.byType(Checkbox)));
      await tester.pump();
      expect(_checkbox(tester, "Alpha").value, isFalse);

      await tester.tap(find.descendant(of: _row("Beta"), matching: find.byType(Checkbox)));
      await tester.pump();
      expect(_checkbox(tester, "Beta").value, isTrue);
    });

    testWidgets("pre-checks the initial selection and enables confirm", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls(), initialSelection: <int>{1, 2}));

      expect(_checkbox(tester, "Alpha").value, isTrue);
      expect(_checkbox(tester, "Beta").value, isTrue);
      expect(_checkbox(tester, "Gamma").value, isFalse);
      expect(_confirmButton(tester).onPressed, isNotNull);
    });

    testWidgets("confirm is disabled until something is selected", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _sheet(calls));

      expect(_confirmButton(tester).onPressed, isNull);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(calls.confirmed, isEmpty);

      await tester.tap(find.text("Beta"));
      await tester.pump();
      expect(_confirmButton(tester).onPressed, isNotNull);

      await tester.tap(find.text("Beta"));
      await tester.pump();
      expect(_confirmButton(tester).onPressed, isNull);
    });

    testWidgets("confirm emits the values once, in selection order", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _sheet(calls, initialSelection: <int>{2}));

      await tester.tap(find.text("Gamma"));
      await tester.tap(find.text("Alpha"));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(calls.confirmed, hasLength(1));
      expect(calls.confirmed.single.toList(), <int>[2, 3, 1]);
    });

    testWidgets("confirm hands over a copy of the selection", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _sheet(calls, initialSelection: <int>{1}));

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      calls.confirmed.single.clear();
      await tester.tap(find.text("Beta"));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(calls.confirmed.last, <int>{1, 2});
    });

    testWidgets("works with enum values", (WidgetTester tester) async {
      final List<Set<Axis>> confirmed = <Set<Axis>>[];
      await pumpApp(
        tester,
        MultiSelectSheet<Axis>(
          title: _title,
          options: const <ChoiceOption<Axis>>[
            ChoiceOption<Axis>(value: Axis.horizontal, label: "Horizontal"),
            ChoiceOption<Axis>(value: Axis.vertical, label: "Vertical"),
          ],
          onConfirm: confirmed.add,
        ),
      );

      await tester.tap(find.text("Vertical"));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(confirmed.single, <Axis>{Axis.vertical});
    });
  });

  group("MultiSelectSheet cap", () {
    testWidgets("disables the unchecked rows once max is reached", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _sheet(calls, max: 2));

      await tester.tap(find.text("Alpha"));
      await tester.tap(find.text("Beta"));
      await tester.pump();

      expect(_checkbox(tester, "Gamma").onChanged, isNull);
      expect(tester.widget<InkWell>(_row("Gamma")).onTap, isNull);
      expect(_checkbox(tester, "Alpha").onChanged, isNotNull);
      final ColorScheme cs = Theme.of(tester.element(find.byType(MultiSelectSheet<int>))).colorScheme;
      expect(tester.widget<Text>(find.text("Gamma")).style?.color, cs.onSurfaceVariant);

      await tester.tap(find.text("Gamma"));
      await tester.pump();
      expect(_checkbox(tester, "Gamma").value, isFalse);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(calls.confirmed.single, <int>{1, 2});
    });

    testWidgets("unchecking a row re-enables the others", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls(), max: 2, initialSelection: <int>{1, 2}));

      expect(_checkbox(tester, "Gamma").onChanged, isNull);
      await tester.tap(find.text("Alpha"));
      await tester.pump();
      expect(_checkbox(tester, "Gamma").onChanged, isNotNull);

      await tester.tap(find.text("Gamma"));
      await tester.pump();
      expect(_checkbox(tester, "Gamma").value, isTrue);
      expect(_checkbox(tester, "Alpha").onChanged, isNull);
    });

    testWidgets("drops initial values that match no option", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _sheet(calls, max: 2, initialSelection: <int>{7, 8}));

      for (final ChoiceOption<int> option in _options) {
        expect(_checkbox(tester, option.label).value, isFalse);
        expect(_checkbox(tester, option.label).onChanged, isNotNull);
      }
      expect(_confirmButton(tester).onPressed, isNull);

      await tester.tap(find.text("Gamma"));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(calls.confirmed.single, <int>{3});
    });

    testWidgets("keeps at most max initial values, in iteration order", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _sheet(calls, max: 2, initialSelection: <int>{9, 1, 2, 3}));

      expect(_checkbox(tester, "Alpha").value, isTrue);
      expect(_checkbox(tester, "Beta").value, isTrue);
      expect(_checkbox(tester, "Gamma").value, isFalse);
      expect(_checkbox(tester, "Gamma").onChanged, isNull);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(calls.confirmed.single.toList(), <int>[1, 2]);
    });

    testWidgets("uses the capped counter key only with max", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls(), max: 5));
      expect(find.text(_counterMaxKey), findsOneWidget);
      expect(find.text(_counterKey), findsNothing);

      await pumpApp(tester, _sheet(_Calls()));
      expect(find.text(_counterKey), findsOneWidget);
      expect(find.text(_counterMaxKey), findsNothing);
    });

    testWidgets("never disables a row without max", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls()));

      for (final ChoiceOption<int> option in _options) {
        await tester.tap(find.text(option.label));
      }
      await tester.pump();

      for (final ChoiceOption<int> option in _options) {
        expect(_checkbox(tester, option.label).value, isTrue);
        expect(_checkbox(tester, option.label).onChanged, isNotNull);
      }
    });

    testWidgets("a disabled option ignores taps and keeps its initial state", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      const List<ChoiceOption<int>> options = <ChoiceOption<int>>[
        ChoiceOption<int>(value: 1, label: "Alpha", enabled: false),
        ChoiceOption<int>(value: 2, label: "Beta", enabled: false),
        ChoiceOption<int>(value: 3, label: "Gamma"),
      ];
      await pumpApp(tester, _sheet(calls, options: options, initialSelection: <int>{1}));

      expect(_checkbox(tester, "Alpha").onChanged, isNull);
      expect(_checkbox(tester, "Beta").onChanged, isNull);
      await tester.tap(find.text("Alpha"));
      await tester.tap(find.text("Beta"));
      await tester.pump();
      expect(_checkbox(tester, "Alpha").value, isTrue);
      expect(_checkbox(tester, "Beta").value, isFalse);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(calls.confirmed.single, <int>{1});
    });
  });

  group("MultiSelectSheet empty state and labels", () {
    testWidgets("shows the default empty text and disables confirm", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls(), options: const <ChoiceOption<int>>[]));

      expect(find.byType(ListView), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.text(_emptyKey), findsOneWidget);
      expect(_confirmButton(tester).onPressed, isNull);
    });

    testWidgets("a custom empty label replaces the default", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls(), options: const <ChoiceOption<int>>[], emptyLabel: "Nothing here"));

      expect(find.text("Nothing here"), findsOneWidget);
      expect(find.text(_emptyKey), findsNothing);
    });

    testWidgets("a custom confirm label replaces the default", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls(), confirmLabel: "Apply"));

      expect(find.text("Apply"), findsOneWidget);
      expect(find.text(_confirmKey), findsNothing);
    });
  });

  group("MultiSelectSheet layout", () {
    testWidgets("caps the list at 360 dp and scrolls to the last row", (WidgetTester tester) async {
      final List<ChoiceOption<int>> many = List<ChoiceOption<int>>.generate(
        30,
        (int i) => ChoiceOption<int>(value: i, label: "Item $i"),
      );
      await pumpApp(tester, _sheet(_Calls(), options: many), surfaceSize: const Size(600, 1200));

      expect(tester.getSize(find.byType(ListView)).height, 360);
      expect(find.text("Item 29"), findsNothing);

      await tester.scrollUntilVisible(find.text("Item 29"), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text("Item 29"));
      await tester.pump();
      expect(_checkbox(tester, "Item 29").value, isTrue);
    });

    testWidgets("shrinks the list instead of overflowing a short host", (WidgetTester tester) async {
      final List<ChoiceOption<int>> many = List<ChoiceOption<int>>.generate(
        30,
        (int i) => ChoiceOption<int>(value: i, label: "Item $i"),
      );
      await pumpApp(tester, _sheet(_Calls(), options: many), surfaceSize: const Size(400, 400));

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(ListView)).height, lessThan(360));
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets("ellipsizes a long badge instead of overflowing", (WidgetTester tester) async {
      final String long = "badge " * 30;
      await pumpApp(
        tester,
        _sheet(_Calls(), options: <ChoiceOption<int>>[ChoiceOption<int>(value: 1, label: "Alpha", trailing: long)]),
        surfaceSize: const Size(360, 640),
      );

      expect(tester.takeException(), isNull);
      final Text badge = tester.widget<Text>(find.text(long));
      expect(badge.maxLines, 1);
      expect(badge.overflow, TextOverflow.ellipsis);
      expect(tester.getSize(find.text("Alpha")).width, greaterThan(0));
    });

    testWidgets("rows and the confirm button are at least 48 dp tall", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls()));

      expect(tester.getSize(_row("Gamma")).height, greaterThanOrEqualTo(kMinTapTarget));
      expect(tester.getSize(find.byType(FilledButton)).height, greaterThanOrEqualTo(kMinTapTarget));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });

  group("MultiSelectSheet semantics", () {
    testWidgets("each row is one node with its label, checked and selected states", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _sheet(_Calls(), initialSelection: <int>{1}, max: 1));

      expect(
        tester.getSemantics(find.text("Alpha")),
        isSemantics(
          label: "Alpha\n12 u",
          isChecked: true,
          isSelected: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.text("Gamma")),
        isSemantics(label: "Gamma", isChecked: false, isSelected: false, isEnabled: false),
      );
      expect(find.bySemanticsLabel(RegExp("^Alpha")), findsOneWidget);
      handle.dispose();
    });

    testWidgets("semanticsLabel replaces the spoken label and badge", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        _sheet(
          _Calls(),
          options: const <ChoiceOption<int>>[
            ChoiceOption<int>(value: 1, label: "Alpha", trailing: "12 u", semanticsLabel: "Alpha, twelve units"),
          ],
        ),
      );

      expect(
        tester.getSemantics(find.text("Alpha")),
        isSemantics(label: "Alpha, twelve units", isChecked: false),
      );
      handle.dispose();
    });

    testWidgets("the title is a header and the counter a live region", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _sheet(_Calls()));

      expect(tester.getSemantics(find.text(_title)), isSemantics(label: _title, isHeader: true));
      expect(tester.getSemantics(find.text(_counterKey)), isSemantics(isLiveRegion: true));
      handle.dispose();
    });
  });

  group("MultiSelectSheet use cases", () {
    testWidgets("empty selection", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls(), max: 5));

      expect(find.byWidgetPredicate((Widget w) => w is Checkbox && (w.value ?? false)), findsNothing);
      expect(_confirmButton(tester).onPressed, isNull);
    });

    testWidgets("pre-selected 2 of 3", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls(), max: 5, initialSelection: <int>{1, 2}));

      expect(find.byWidgetPredicate((Widget w) => w is Checkbox && (w.value ?? false)), findsNWidgets(2));
      expect(_confirmButton(tester).onPressed, isNotNull);
    });

    testWidgets("empty list", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls(), max: 5, options: const <ChoiceOption<int>>[]));

      expect(find.text(_emptyKey), findsOneWidget);
      expect(_confirmButton(tester).onPressed, isNull);
    });
  });

  group("MultiSelectSheet theming and hosting", () {
    testWidgets("renders under the dark theme with scheme tokens", (WidgetTester tester) async {
      await pumpApp(tester, _sheet(_Calls(), max: 2, initialSelection: <int>{1}), theme: AppTheme.dark());

      final ColorScheme cs = Theme.of(tester.element(find.byType(MultiSelectSheet<int>))).colorScheme;
      expect(cs.brightness, Brightness.dark);
      expect(tester.widget<Text>(find.text(_title)).style?.color, cs.onSurface);
      expect(_pillDecoration(tester, "12 u").color, cs.surfaceContainerHighest);
      expect(tester.takeException(), isNull);
    });

    testWidgets("works inside an AppModal mounted by ModalProvider", (WidgetTester tester) async {
      final List<Set<int>> confirmed = <Set<int>>[];
      await pumpApp(
        tester,
        ModalConsumer(
          child: SizedBox.expand(
            child: Builder(
              builder: (BuildContext context) => TextButton(
                onPressed: () {
                  final ModalProvider modals = context.read<ModalProvider>();
                  modals.show(
                    AppModal(
                      isVisible: true,
                      onDismiss: modals.dismiss,
                      child: MultiSelectSheet<int>(
                        title: _title,
                        options: _options,
                        max: 2,
                        onConfirm: (Set<int> values) {
                          confirmed.add(values);
                          modals.dismiss();
                        },
                      ),
                    ),
                  );
                },
                child: const Text("open"),
              ),
            ),
          ),
        ),
        providers: defaultTestProviders(),
      );

      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();
      expect(find.text(_title), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text("Beta"));
      await tester.pump();
      expect(_checkbox(tester, "Beta").value, isTrue);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(confirmed.single, <int>{2});
      expect(find.text(_title), findsNothing);
    });

    testWidgets("works as modal bottom sheet content that pops its route", (WidgetTester tester) async {
      Set<int>? result;
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async {
              result = await showModalBottomSheet<Set<int>>(
                context: context,
                showDragHandle: true,
                builder: (BuildContext sheetContext) => MultiSelectSheet<int>(
                  title: _title,
                  options: List<ChoiceOption<int>>.generate(
                    30,
                    (int i) => ChoiceOption<int>(value: i, label: "Item $i"),
                  ),
                  initialSelection: const <int>{4},
                  onConfirm: (Set<int> values) => Navigator.of(sheetContext).pop(values),
                ),
              );
            },
            child: const Text("open"),
          ),
        ),
        surfaceSize: const Size(400, 700),
      );

      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text("Item 0"));
      await tester.pump();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(result, <int>{4, 0});
      expect(find.text(_title), findsNothing);
    });
  });

  // Last: loading real translations leaves them active for later tests.
  group("MultiSelectSheet translations", () {
    testWidgets("renders the capped counter and updates it in French", (WidgetTester tester) async {
      await _pumpLocalized(tester, const Locale("fr"), _sheet(_Calls(), initialSelection: <int>{1, 2}, max: 5));

      expect(find.text("2/5 sélectionné(s)"), findsOneWidget);
      expect(find.text("Valider"), findsOneWidget);

      await tester.tap(find.text("Gamma"));
      await tester.pump();
      expect(find.text("3/5 sélectionné(s)"), findsOneWidget);
    });

    testWidgets("does not count unknown initial values", (WidgetTester tester) async {
      await _pumpLocalized(tester, const Locale("en"), _sheet(_Calls(), initialSelection: <int>{7, 8}, max: 2));
      expect(find.text("0/2 selected"), findsOneWidget);
    });

    testWidgets("never counts more initial values than max", (WidgetTester tester) async {
      await _pumpLocalized(tester, const Locale("en"), _sheet(_Calls(), initialSelection: <int>{1, 2, 3}, max: 2));
      expect(find.text("2/2 selected"), findsOneWidget);
    });

    testWidgets("re-cleans the selection when a rebuild shrinks options and max", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      final ValueNotifier<bool> shrunk = ValueNotifier<bool>(false);
      addTearDown(shrunk.dispose);
      await _pumpLocalized(
        tester,
        const Locale("en"),
        ValueListenableBuilder<bool>(
          valueListenable: shrunk,
          builder: (BuildContext context, bool isShrunk, Widget? child) =>
              isShrunk ? _sheet(calls, options: _options.sublist(1), max: 1) : _sheet(calls),
        ),
      );

      await tester.tap(find.text("Alpha"));
      await tester.tap(find.text("Beta"));
      await tester.tap(find.text("Gamma"));
      await tester.pump();
      expect(find.text("3 selected"), findsOneWidget);

      shrunk.value = true;
      await tester.pump();
      expect(find.text("Alpha"), findsNothing);
      expect(find.text("1/1 selected"), findsOneWidget);
      expect(_checkbox(tester, "Beta").value, isTrue);
      expect(_checkbox(tester, "Gamma").value, isFalse);
      expect(_checkbox(tester, "Gamma").onChanged, isNull);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(calls.confirmed.single.toList(), <int>[2]);
    });

    testWidgets("renders the uncapped counter and empty text in English", (WidgetTester tester) async {
      await _pumpLocalized(tester, const Locale("en"), _sheet(_Calls(), options: const <ChoiceOption<int>>[]));

      expect(find.text("0 selected"), findsOneWidget);
      expect(find.text("No items available."), findsOneWidget);
      expect(find.text("Confirm"), findsOneWidget);
    });
  });
}

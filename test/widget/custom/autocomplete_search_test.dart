// autocomplete_search_test.dart
//
// Widget tests for AutocompleteSearch: minimum query length, debounce and
// trimming, the spinner, the dropdown rows (itemBuilder, default text and
// icon theme, 48 dp button rows, live region), the empty-result text, picking
// (clear or selectionLabel), shortening the query, the stale-response guard,
// errors and onError, tap outside and tapping the field again, focus on
// desktop, custom length / debounce / size parameters, the default and custom
// hint, the dropdown geometry, dispose safety, the dark theme and the
// translated result count.

import "dart:async";

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/AutocompleteSearch/index.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";
import "package:flutter_skeleton/widgets/custom/SearchField/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _hintKey = "custom.autocomplete_search.hint";
const String _noResultsKey = "custom.autocomplete_search.no_results";
const String _resultsKey = "custom.autocomplete_search.results";
const Duration _debounce = Duration(milliseconds: 500);

/// Test item; identity matters for onSelected.
final class _Item {
  final String label;

  const _Item(this.label);
}

const _Item _alpha = _Item("Alpha");
const _Item _beta = _Item("Beta");
const _Item _gamma = _Item("Gamma");

/// Records every query and answers each one with a Completer the test owns.
final class _FakeSearch {
  final List<String> queries = <String>[];
  final List<Completer<List<_Item>>> calls = <Completer<List<_Item>>>[];

  Future<List<_Item>> call(String query) {
    queries.add(query);
    final Completer<List<_Item>> completer = Completer<List<_Item>>();
    calls.add(completer);
    return completer.future;
  }
}

Widget _host({
  required Future<List<_Item>> Function(String query) search,
  ValueChanged<_Item>? onSelected,
  ValueChanged<Object>? onError,
  String Function(_Item item)? selectionLabel,
  String? hintText,
  String? noResultsText,
  Widget Function(BuildContext context, _Item item)? itemBuilder,
  int minQueryLength = 2,
  Duration debounce = _debounce,
  double dropdownWidth = 320,
  double dropdownMaxHeight = 280,
}) {
  return Padding(
    padding: const EdgeInsets.all(kDefaultPadding * 2),
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 360,
        child: AutocompleteSearch<_Item>(
          search: search,
          itemBuilder:
              itemBuilder ?? (BuildContext context, _Item item) => Text(item.label),
          onSelected: onSelected ?? (_Item item) {},
          onError: onError,
          selectionLabel: selectionLabel,
          hintText: hintText,
          noResultsText: noResultsText,
          minQueryLength: minQueryLength,
          debounce: debounce,
          dropdownWidth: dropdownWidth,
          dropdownMaxHeight: dropdownMaxHeight,
        ),
      ),
    ),
  );
}

Finder _dropdown() {
  return find.byWidgetPredicate(
    (Widget widget) => widget is Material && widget.elevation == 4,
  );
}

Finder _loader() {
  return find.descendant(of: find.byType(SearchField), matching: find.byType(Loader));
}

String _fieldText(WidgetTester tester) {
  return tester.widget<TextField>(find.byType(TextField)).controller!.text;
}

FocusNode _fieldFocus(WidgetTester tester) {
  return tester.widget<EditableText>(find.byType(EditableText)).focusNode;
}

/// Serves only the result-count key, in French and English, so a test can
/// check the `{count}` argument. EasyLocalization keeps the loaded strings in
/// a global for the rest of the file, so the test using it runs last.
final class _MemoryLoader extends AssetLoader {
  const _MemoryLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final bool fr = locale.languageCode == "fr";
    return <String, dynamic>{
      "custom": <String, dynamic>{
        "autocomplete_search": <String, dynamic>{
          "results": fr ? "Résultats : {count}" : "Results: {count}",
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

/// Types [text], waits for the debounce and answers the latest call.
Future<void> _searchAndAnswer(
  WidgetTester tester,
  _FakeSearch search,
  String text,
  List<_Item> results,
) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(_debounce);
  search.calls.last.complete(results);
  await tester.pump();
}

void main() {
  group("query gating", () {
    testWidgets("a query shorter than minQueryLength never searches", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(tester, _host(search: search.call));

      await tester.enterText(find.byType(TextField), "a");
      await tester.pump(const Duration(seconds: 1));

      expect(search.queries, isEmpty);
      expect(_loader(), findsNothing);
      expect(_dropdown(), findsNothing);
    });

    testWidgets("the spinner shows at once and the search waits for the debounce", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(tester, _host(search: search.call));

      await tester.enterText(find.byType(TextField), "  Par ");
      await tester.pump();
      expect(_loader(), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 499));
      expect(search.queries, isEmpty);

      await tester.pump(const Duration(milliseconds: 1));
      expect(search.queries, <String>["Par"]);
    });

    testWidgets("fast keystrokes give a single call with the last value", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(tester, _host(search: search.call));

      for (final String text in <String>["ab", "abc", "abcd"]) {
        await tester.enterText(find.byType(TextField), text);
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.pump(_debounce);

      expect(search.queries, <String>["abcd"]);
    });

    testWidgets("custom minQueryLength, debounce and dropdown size are honoured", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(
        tester,
        _host(
          search: search.call,
          minQueryLength: 3,
          debounce: const Duration(milliseconds: 100),
          dropdownWidth: 200,
          dropdownMaxHeight: 150,
        ),
        surfaceSize: const Size(800, 1200),
      );

      await tester.enterText(find.byType(TextField), "ab");
      await tester.pump(const Duration(seconds: 1));
      expect(search.queries, isEmpty);
      expect(_loader(), findsNothing);

      await tester.enterText(find.byType(TextField), "abc");
      await tester.pump(const Duration(milliseconds: 99));
      expect(search.queries, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(search.queries, <String>["abc"]);

      search.calls.single.complete(List<_Item>.generate(20, (int i) => _Item("Item $i")));
      await tester.pump();
      expect(tester.getSize(_dropdown()), const Size(200, 150));
    });
  });

  group("dropdown", () {
    testWidgets("renders one row per result and stops the spinner", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(tester, _host(search: search.call));

      await _searchAndAnswer(tester, search, "al", <_Item>[_alpha, _beta]);

      expect(_dropdown(), findsOneWidget);
      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("Beta"), findsOneWidget);
      expect(_loader(), findsNothing);
    });

    testWidgets("rows apply the default text style and icon theme", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(
        tester,
        _host(
          search: search.call,
          itemBuilder: (BuildContext context, _Item item) => Row(
            children: <Widget>[
              const Icon(Icons.star_outline),
              const SizedBox(width: kDefaultPadding),
              Expanded(child: Text(item.label)),
            ],
          ),
        ),
      );
      await _searchAndAnswer(tester, search, "al", <_Item>[_alpha]);

      final BuildContext textContext = tester.element(find.text("Alpha"));
      final ColorScheme cs = Theme.of(textContext).colorScheme;
      final DefaultTextStyle textStyle = DefaultTextStyle.of(textContext);
      expect(textStyle.style.color, cs.onSurface);
      expect(textStyle.style.fontSize, 13);
      expect(textStyle.maxLines, 2);

      final IconThemeData iconTheme = IconTheme.of(tester.element(find.byIcon(Icons.star_outline)));
      expect(iconTheme.color, cs.primary);
      expect(iconTheme.size, 16);
    });

    testWidgets("rows are 48 dp buttons and the list is a live region", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final _FakeSearch search = _FakeSearch();
      await pumpApp(tester, _host(search: search.call));
      await _searchAndAnswer(tester, search, "al", <_Item>[_alpha, _beta]);

      final Finder row = find.ancestor(of: find.text("Alpha"), matching: find.byType(InkWell));
      expect(tester.getSize(row).height, greaterThanOrEqualTo(kMinTapTarget));
      expect(
        tester.getSemantics(find.text("Alpha")),
        isSemantics(label: "Alpha", isButton: true, hasTapAction: true),
      );
      // The raw key has no {count}: the count itself is checked with real
      // strings in "the live region label carries the translated count".
      expect(
        tester.getSemantics(find.bySemanticsLabel(_resultsKey)),
        isSemantics(isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets("follows the field's bottom-left corner with the default size", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(tester, _host(search: search.call));
      await _searchAndAnswer(tester, search, "al", <_Item>[_alpha]);

      final Rect field = tester.getRect(find.byType(SearchField));
      final Rect dropdown = tester.getRect(_dropdown());
      expect(dropdown.left, field.left);
      expect(dropdown.top, field.bottom + kDefaultPadding);
      expect(dropdown.width, 320);
    });

    testWidgets("caps the height at 280 and scrolls past it", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(tester, _host(search: search.call), surfaceSize: const Size(800, 1200));
      final List<_Item> many = List<_Item>.generate(20, (int i) => _Item("Item $i"));
      await _searchAndAnswer(tester, search, "it", many);

      expect(tester.getSize(_dropdown()).height, 280);
      expect(find.text("Item 19"), findsNothing);
      await tester.scrollUntilVisible(
        find.text("Item 19"),
        100,
        scrollable: find.descendant(of: _dropdown(), matching: find.byType(Scrollable)),
      );
      expect(find.text("Item 19"), findsOneWidget);
    });

    testWidgets("an empty result shows the default no-results text as a live region", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final _FakeSearch search = _FakeSearch();
      await pumpApp(tester, _host(search: search.call));
      await _searchAndAnswer(tester, search, "zz", <_Item>[]);

      expect(_dropdown(), findsOneWidget);
      expect(find.text(_noResultsKey), findsOneWidget);
      expect(_loader(), findsNothing);
      expect(
        tester.getSemantics(find.text(_noResultsKey)),
        isSemantics(label: _noResultsKey, isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets("noResultsText overrides the default", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(tester, _host(search: search.call, noResultsText: "Nothing here"));
      await _searchAndAnswer(tester, search, "zz", <_Item>[]);

      expect(find.text("Nothing here"), findsOneWidget);
      expect(find.text(_noResultsKey), findsNothing);
    });

    testWidgets("previous results stay visible while the next query loads", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(tester, _host(search: search.call));
      await _searchAndAnswer(tester, search, "al", <_Item>[_alpha]);

      await tester.enterText(find.byType(TextField), "alp");
      await tester.pump();
      expect(find.text("Alpha"), findsOneWidget);
      expect(_loader(), findsOneWidget);

      await tester.pump(_debounce);
      search.calls.last.complete(<_Item>[_beta]);
      await tester.pump();
      expect(find.text("Alpha"), findsNothing);
      expect(find.text("Beta"), findsOneWidget);
    });
  });

  group("picking", () {
    testWidgets("tapping a row reports the same item, closes and clears", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      final List<_Item> picked = <_Item>[];
      await pumpApp(tester, _host(search: search.call, onSelected: picked.add));
      await _searchAndAnswer(tester, search, "al", <_Item>[_alpha, _beta]);

      await tester.tap(find.text("Beta"));
      await tester.pump();

      expect(picked, hasLength(1));
      expect(identical(picked.single, _beta), isTrue);
      expect(_dropdown(), findsNothing);
      expect(_fieldText(tester), isEmpty);
      expect(_loader(), findsNothing);
    });

    testWidgets("selectionLabel puts the label in the field without searching again", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(
        tester,
        _host(search: search.call, selectionLabel: (_Item item) => "Picked ${item.label}"),
      );
      await _searchAndAnswer(tester, search, "al", <_Item>[_alpha]);

      await tester.tap(find.text("Alpha"));
      await tester.pump(_debounce * 2);

      expect(_fieldText(tester), "Picked Alpha");
      final TextSelection selection =
          tester.widget<TextField>(find.byType(TextField)).controller!.selection;
      expect(selection, const TextSelection.collapsed(offset: 12));
      expect(search.queries, <String>["al"]);
      expect(_dropdown(), findsNothing);
    });

    testWidgets("tapping the field after a pick searches the selectionLabel", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(
        tester,
        _host(search: search.call, selectionLabel: (_Item item) => "Picked ${item.label}"),
      );
      await _searchAndAnswer(tester, search, "al", <_Item>[_alpha]);
      await tester.tap(find.text("Alpha"));
      await tester.pump();

      await tester.tap(find.byType(TextField));
      await tester.pump(_debounce);

      expect(search.queries, <String>["al", "Picked Alpha"]);
    });
  });

  group("closing", () {
    testWidgets("shortening the query closes the dropdown and cancels the pending call", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(tester, _host(search: search.call));
      await _searchAndAnswer(tester, search, "al", <_Item>[_alpha]);

      await tester.enterText(find.byType(TextField), "alp");
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), "a");
      await tester.pump(_debounce * 2);

      expect(search.queries, <String>["al"]);
      expect(_dropdown(), findsNothing);
      expect(_loader(), findsNothing);
    });

    testWidgets("tapping outside closes the dropdown", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(tester, _host(search: search.call), surfaceSize: const Size(800, 800));
      await _searchAndAnswer(tester, search, "al", <_Item>[_alpha]);

      await tester.tapAt(const Offset(700, 700));
      await tester.pump();

      expect(_dropdown(), findsNothing);
      expect(_fieldText(tester), "al");
    });

    testWidgets("tapping the field or inside the dropdown keeps it open", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(tester, _host(search: search.call));
      await _searchAndAnswer(tester, search, "zz", <_Item>[]);

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(_dropdown(), findsOneWidget);

      await tester.tap(find.text(_noResultsKey));
      await tester.pump();
      expect(_dropdown(), findsOneWidget);

      await tester.pump(_debounce);
      expect(search.queries, <String>["zz"]);
    });

    testWidgets("desktop: a tap inside the dropdown keeps the field focused", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(tester, _host(search: search.call), surfaceSize: const Size(800, 800));
      await _searchAndAnswer(tester, search, "zz", <_Item>[]);
      expect(_fieldFocus(tester).hasFocus, isTrue);

      await tester.tap(find.text(_noResultsKey));
      await tester.pump();
      expect(_fieldFocus(tester).hasFocus, isTrue);
      expect(_dropdown(), findsOneWidget);

      await tester.tapAt(const Offset(700, 700));
      await tester.pump();
      expect(_fieldFocus(tester).hasFocus, isFalse);
      expect(_dropdown(), findsNothing);
    }, variant: TargetPlatformVariant.desktop());

    testWidgets("tapping the field after a tap outside searches its text again", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(tester, _host(search: search.call), surfaceSize: const Size(800, 800));
      await _searchAndAnswer(tester, search, "al", <_Item>[_alpha]);

      await tester.tapAt(const Offset(700, 700));
      await tester.pump();
      expect(_dropdown(), findsNothing);

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(_loader(), findsOneWidget);
      await tester.pump(_debounce);
      expect(search.queries, <String>["al", "al"]);

      search.calls.last.complete(<_Item>[_alpha]);
      await tester.pump();
      expect(find.text("Alpha"), findsOneWidget);
      expect(_loader(), findsNothing);
    });

    testWidgets("tapping the field with a too short query does not search", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(tester, _host(search: search.call));

      await tester.enterText(find.byType(TextField), "a");
      await tester.tap(find.byType(TextField));
      await tester.pump(const Duration(seconds: 1));

      expect(search.queries, isEmpty);
      expect(_loader(), findsNothing);
      expect(_dropdown(), findsNothing);
    });

    testWidgets("tapping outside while loading drops the pending call", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(tester, _host(search: search.call), surfaceSize: const Size(800, 800));

      await tester.enterText(find.byType(TextField), "al");
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(const Offset(700, 700));
      await tester.pump(_debounce * 2);

      expect(search.queries, isEmpty);
      expect(_loader(), findsNothing);
      expect(_dropdown(), findsNothing);
    });
  });

  group("stale responses", () {
    testWidgets("an older response arriving last is ignored", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(tester, _host(search: search.call));

      await tester.enterText(find.byType(TextField), "ab");
      await tester.pump(_debounce);
      await tester.enterText(find.byType(TextField), "abc");
      await tester.pump(_debounce);
      expect(search.queries, <String>["ab", "abc"]);

      search.calls[1].complete(<_Item>[_gamma]);
      await tester.pump();
      search.calls[0].complete(<_Item>[_alpha]);
      await tester.pump();

      expect(find.text("Gamma"), findsOneWidget);
      expect(find.text("Alpha"), findsNothing);
      expect(_loader(), findsNothing);
    });

    testWidgets("a response arriving while the next call waits shows and keeps the spinner", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(tester, _host(search: search.call));

      await tester.enterText(find.byType(TextField), "ab");
      await tester.pump(_debounce);
      await tester.enterText(find.byType(TextField), "abc");
      await tester.pump(const Duration(milliseconds: 100));
      search.calls[0].complete(<_Item>[_alpha]);
      await tester.pump();

      expect(find.text("Alpha"), findsOneWidget);
      expect(_loader(), findsOneWidget);

      await tester.pump(_debounce);
      search.calls[1].complete(<_Item>[_gamma]);
      await tester.pump();
      expect(find.text("Gamma"), findsOneWidget);
      expect(_loader(), findsNothing);
    });

    testWidgets("a response after the query was shortened does not reopen the dropdown", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(tester, _host(search: search.call));

      await tester.enterText(find.byType(TextField), "ab");
      await tester.pump(_debounce);
      await tester.enterText(find.byType(TextField), "");
      await tester.pump();
      search.calls.single.complete(<_Item>[_alpha]);
      await tester.pump();

      expect(_dropdown(), findsNothing);
      expect(find.text("Alpha"), findsNothing);
    });
  });

  group("errors", () {
    testWidgets("a failing search stops the spinner, closes the dropdown and reports the error", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      final List<Object> errors = <Object>[];
      await pumpApp(tester, _host(search: search.call, onError: errors.add));
      await _searchAndAnswer(tester, search, "al", <_Item>[_alpha]);

      await tester.enterText(find.byType(TextField), "alp");
      await tester.pump(_debounce);
      final StateError failure = StateError("lookup failed");
      search.calls.last.completeError(failure);
      await tester.pump();

      expect(errors, <Object>[failure]);
      expect(_loader(), findsNothing);
      expect(_dropdown(), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets("a synchronous throw without onError is swallowed", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _host(search: (String query) => throw StateError("lookup failed")),
      );

      await tester.enterText(find.byType(TextField), "al");
      await tester.pump(_debounce);
      await tester.pump();

      expect(_loader(), findsNothing);
      expect(_dropdown(), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets("an outdated failure is not reported", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      final List<Object> errors = <Object>[];
      await pumpApp(tester, _host(search: search.call, onError: errors.add));

      await tester.enterText(find.byType(TextField), "ab");
      await tester.pump(_debounce);
      await tester.enterText(find.byType(TextField), "abc");
      await tester.pump(_debounce);
      search.calls[0].completeError(StateError("lookup failed"));
      await tester.pump();

      expect(errors, isEmpty);
      expect(_loader(), findsOneWidget);
      search.calls[1].complete(<_Item>[_gamma]);
      await tester.pump();
    });
  });

  group("hint", () {
    testWidgets("defaults to the chrome key", (WidgetTester tester) async {
      await pumpApp(tester, _host(search: _FakeSearch().call));

      expect(find.text(_hintKey), findsOneWidget);
    });

    testWidgets("hintText overrides the default", (WidgetTester tester) async {
      await pumpApp(tester, _host(search: _FakeSearch().call, hintText: "Find something"));

      expect(find.text("Find something"), findsOneWidget);
      expect(find.text(_hintKey), findsNothing);
    });
  });

  group("dispose safety", () {
    testWidgets("unmounting with a pending debounce never searches", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      await pumpApp(tester, _host(search: search.call));

      await tester.enterText(find.byType(TextField), "al");
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(_debounce);

      expect(search.queries, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets("a call settling after unmount is dropped", (WidgetTester tester) async {
      final _FakeSearch search = _FakeSearch();
      final List<Object> errors = <Object>[];
      await pumpApp(tester, _host(search: search.call, onError: errors.add));

      await tester.enterText(find.byType(TextField), "al");
      await tester.pump(_debounce);
      await tester.enterText(find.byType(TextField), "alp");
      await tester.pump(_debounce);
      await tester.pumpWidget(const SizedBox.shrink());

      search.calls[0].complete(<_Item>[_alpha]);
      search.calls[1].completeError(StateError("lookup failed"));
      await tester.pump();

      expect(errors, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets("dark theme: dropdown and rows use the scheme tokens", (WidgetTester tester) async {
    final ThemeData dark = AppTheme.dark();
    final _FakeSearch search = _FakeSearch();
    await pumpApp(tester, _host(search: search.call), theme: dark);
    await _searchAndAnswer(tester, search, "al", <_Item>[_alpha]);

    expect(tester.widget<Material>(_dropdown()).color, dark.colorScheme.surfaceContainerHigh);
    expect(
      DefaultTextStyle.of(tester.element(find.text("Alpha"))).style.color,
      dark.colorScheme.onSurface,
    );
    expect(tester.takeException(), isNull);
  });

  // Keep last: see _MemoryLoader.
  testWidgets("the live region label carries the translated count", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final _FakeSearch search = _FakeSearch();
    await _pumpLocalized(tester, const Locale("fr"), _host(search: search.call));
    await _searchAndAnswer(tester, search, "al", <_Item>[_alpha, _beta]);

    expect(
      tester.getSemantics(find.bySemanticsLabel("Résultats : 2")),
      isSemantics(isLiveRegion: true),
    );
    handle.dispose();
  });
}

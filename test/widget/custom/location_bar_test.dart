// location_bar_test.dart
//
// Widget tests for LocationBar: the three modes (empty, selected, editing)
// and their optional chrome, entering and cancelling editing (focus, field
// reset, callbacks), the composed AutocompleteSearch (debounce, trimmed query,
// suggestion rows, latest response only, errors), the host-driven mode
// changes, the current-location action (busy state, reduced motion, errors,
// results dropped after Cancel, a pick or a host value change), unmount
// safety, accessibility guidelines, the dark theme, and the fr / en reminder
// strings (from a copy of the i18n fragment).

import "dart:async";

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/custom/AutocompleteSearch/index.dart";
import "package:flutter_skeleton/widgets/custom/EditableValueRow/index.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";
import "package:flutter_skeleton/widgets/custom/LocationBar/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _placeholderKey = "custom.location_bar.placeholder";
const String _cancelKey = "custom.location_bar.cancel";
const String _currentlyKey = "custom.location_bar.currently_at";
const String _unknownKey = "custom.location_bar.unknown_place";
const String _myLocationKey = "custom.location_bar.my_location";
const String _modifyKey = "custom.location_bar.modify_semantics";
const String _loadingKey = "common.loading";

const LocationSuggestion<int> _alpha = LocationSuggestion<int>(
  value: 1,
  title: "Alpha",
  subtitle: "North side",
  badge: "Town",
);
const LocationSuggestion<int> _beta = LocationSuggestion<int>(value: 2, title: "Beta");

/// Bar configuration; every field is optional.
typedef _BarConfig = ({
  int? value,
  String? title,
  String? subtitle,
  String? hintText,
  String? alternativeHint,
});

const _BarConfig _noConfig = (value: null, title: null, subtitle: null, hintText: null, alternativeHint: null);
const _BarConfig _alphaSelected = (value: 1, title: "Alpha", subtitle: "1.00, 2.00", hintText: null, alternativeHint: null);

/// Records the callbacks of an `int`-valued LocationBar and builds bars whose search
/// and current-location lookups are replaceable.
final class _Harness {
  final List<String> queries = <String>[];
  final List<LocationSuggestion<int>> picked = <LocationSuggestion<int>>[];
  final List<Object> errors = <Object>[];
  int started = 0;
  int cancelled = 0;
  int locateCalls = 0;

  /// Answers search calls.
  Future<List<LocationSuggestion<int>>> Function(String query) answer =
      (String query) async => <LocationSuggestion<int>>[_alpha, _beta];

  /// Answers current-location calls; null hides the row.
  Future<LocationSuggestion<int>?> Function()? locate;

  Future<List<LocationSuggestion<int>>> _search(String query) {
    queries.add(query);
    return answer(query);
  }

  Future<LocationSuggestion<int>?> _locate() {
    locateCalls++;
    return locate!();
  }

  LocationBar<int> bar([_BarConfig config = _noConfig]) {
    return LocationBar<int>(
      search: _search,
      onSelected: picked.add,
      value: config.value,
      title: config.title,
      subtitle: config.subtitle,
      hintText: config.hintText,
      alternativeHint: config.alternativeHint,
      onEditingStarted: () => started++,
      onEditingCancelled: () => cancelled++,
      onUseCurrentLocation: locate == null ? null : _locate,
      onError: errors.add,
    );
  }
}

Finder get _field => find.byType(TextField);

/// The InkWell around the selected row (its centre may miss the row's texts).
Finder get _selectedRow => find.ancestor(of: find.byType(EditableValueRow), matching: find.byType(InkWell)).first;

String _fieldText(WidgetTester tester) => tester.widget<TextField>(_field).controller!.text;

bool _fieldFocused(WidgetTester tester) => tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus;

/// Lets a mode switch run its 150 ms cross-fade (and a post-frame focus).
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Types [text] and waits for the debounced search to answer.
Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(_field, text);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}

/// The busy my-location row: one disabled button, without a tap action,
/// announcing the loading label before its text.
final Matcher _busyRowSemantics = isSemantics(
  label: "$_loadingKey\n$_myLocationKey",
  isButton: true,
  hasEnabledState: true,
  isEnabled: false,
  hasTapAction: false,
);

void main() {
  _emptyModeTests();
  _selectedModeTests();
  _editingTests();
  _searchTests();
  _hostUpdateTests();
  _locateTests();
  _lifecycleTests();
  _accessibilityTests();
  _themeTests();
  _localizedTests();
}

void _emptyModeTests() {
  group("empty mode", () {
    testWidgets("shows the search field with the default placeholder only", (WidgetTester tester) async {
      await pumpApp(tester, _Harness().bar());

      expect(_field, findsOneWidget);
      expect(find.text(_placeholderKey), findsOneWidget);
      expect(find.byType(EditableValueRow), findsNothing);
      expect(find.text(_cancelKey), findsNothing);
      expect(find.text(_currentlyKey), findsNothing);
      expect(find.text(_myLocationKey), findsNothing);
      expect(find.byIcon(Icons.touch_app_rounded), findsNothing);
    });

    testWidgets("hintText overrides the placeholder", (WidgetTester tester) async {
      const _BarConfig config = (value: null, title: null, subtitle: null, hintText: "Find a spot", alternativeHint: null);
      await pumpApp(tester, _Harness().bar(config));

      expect(find.text("Find a spot"), findsOneWidget);
      expect(find.text(_placeholderKey), findsNothing);
    });

    testWidgets("alternativeHint shows with a touch icon", (WidgetTester tester) async {
      const _BarConfig config = (value: null, title: null, subtitle: null, hintText: null, alternativeHint: "or tap the canvas");
      await pumpApp(tester, _Harness().bar(config));

      expect(find.text("or tap the canvas"), findsOneWidget);
      expect(find.byIcon(Icons.touch_app_rounded), findsOneWidget);
    });

    testWidgets("the my-location row shows only with onUseCurrentLocation", (WidgetTester tester) async {
      final _Harness harness = _Harness()..locate = () async => null;
      await pumpApp(tester, harness.bar());

      expect(find.text(_myLocationKey), findsOneWidget);
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
      // Its own transparent Material, so its ink is not hidden by a coloured
      // host background between the bar and the Scaffold.
      final Material ink = tester.widget<Material>(
        find.ancestor(of: find.text(_myLocationKey), matching: find.byType(Material)).first,
      );
      expect(ink.type, MaterialType.transparency);
    });
  });
}

void _selectedModeTests() {
  group("selected mode", () {
    testWidgets("renders an EditableValueRow with the title and the subtitle", (WidgetTester tester) async {
      await pumpApp(tester, _Harness().bar(_alphaSelected));

      final EditableValueRow row = tester.widget<EditableValueRow>(find.byType(EditableValueRow));
      expect(row.icon, Icons.location_on_rounded);
      expect(row.title, "Alpha");
      expect(row.subtitle, "1.00, 2.00");
      expect(row.semanticsLabel, _modifyKey);
      expect(find.text("1.00, 2.00"), findsOneWidget);
      expect(_field, findsNothing);
    });

    testWidgets("a null or empty title falls back to the unknown-place text", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await pumpApp(tester, harness.bar((value: 1, title: null, subtitle: null, hintText: null, alternativeHint: null)));
      expect(find.text(_unknownKey), findsOneWidget);

      await pumpApp(tester, harness.bar((value: 1, title: "", subtitle: null, hintText: null, alternativeHint: null)));
      expect(find.text(_unknownKey), findsOneWidget);
      expect(tester.widget<EditableValueRow>(find.byType(EditableValueRow)).subtitle, isNull);
    });
  });
}

void _editingTests() {
  group("editing", () {
    testWidgets("tapping the selected row opens an empty, focused field", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await pumpApp(tester, harness.bar(_alphaSelected));

      await tester.tap(_selectedRow);
      await _settle(tester);

      expect(harness.started, 1);
      expect(find.byType(EditableValueRow), findsNothing);
      expect(_fieldText(tester), isEmpty);
      expect(_fieldFocused(tester), isTrue);
      expect(find.text(_cancelKey), findsOneWidget);
      expect(find.text(_currentlyKey), findsOneWidget);
    });

    testWidgets("focusing the field in empty mode enters editing, without a reminder", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await pumpApp(tester, harness.bar());

      await tester.tap(_field);
      await _settle(tester);

      expect(harness.started, 1);
      expect(_fieldFocused(tester), isTrue);
      expect(find.text(_cancelKey), findsOneWidget);
      expect(find.text(_currentlyKey), findsNothing);
    });

    testWidgets("Cancel from empty editing clears the field and drops the pending search", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await pumpApp(tester, harness.bar());
      await tester.tap(_field);
      await _settle(tester);
      await tester.enterText(_field, "Alp");
      await tester.pump();

      await tester.tap(find.text(_cancelKey));
      await _settle(tester);
      await tester.pump(const Duration(milliseconds: 600));

      expect(harness.cancelled, 1);
      expect(find.text(_cancelKey), findsNothing);
      expect(find.byType(EditableValueRow), findsNothing);
      expect(_fieldText(tester), isEmpty);
      expect(_fieldFocused(tester), isFalse);
      expect(harness.queries, isEmpty);
    });

    testWidgets("Cancel from a selected place returns to the selected row", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await pumpApp(tester, harness.bar(_alphaSelected));
      await tester.tap(_selectedRow);
      await _settle(tester);

      await tester.tap(find.text(_cancelKey));
      await _settle(tester);

      expect(harness.cancelled, 1);
      expect(find.byType(EditableValueRow), findsOneWidget);
      expect(_field, findsNothing);
      expect(FocusManager.instance.primaryFocus?.context?.widget, isNot(isA<EditableText>()));
    });

    testWidgets("re-opening right after Cancel starts from an empty field", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await pumpApp(tester, harness.bar(_alphaSelected));
      await tester.tap(_selectedRow);
      await _settle(tester);
      await tester.enterText(_field, "Alp");
      await tester.pump();
      await tester.tap(find.text(_cancelKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // The search layout is still fading out: the switcher revives it.
      await tester.tap(_selectedRow);
      await _settle(tester);
      await tester.pump(const Duration(milliseconds: 600));

      expect(harness.started, 2);
      expect(harness.cancelled, 1);
      expect(_fieldText(tester), isEmpty);
      expect(_fieldFocused(tester), isTrue);
      expect(harness.queries, isEmpty);
    });

    testWidgets("works without the optional callbacks", (WidgetTester tester) async {
      await pumpApp(
        tester,
        LocationBar<int>(
          search: (String query) async => <LocationSuggestion<int>>[],
          onSelected: (LocationSuggestion<int> suggestion) {},
          value: 1,
        ),
      );

      await tester.tap(_selectedRow);
      await _settle(tester);
      await tester.tap(find.text(_cancelKey));
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(EditableValueRow), findsOneWidget);
    });
  });
}

void _searchTests() {
  group("search", () {
    testWidgets("is debounced, needs two characters and trims the query", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await pumpApp(tester, harness.bar());

      await tester.enterText(_field, "a");
      await tester.pump(const Duration(milliseconds: 600));
      expect(harness.queries, isEmpty);

      await tester.enterText(_field, "Al");
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(_field, " Alp ");
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(harness.queries, <String>["Alp"]);
    });

    testWidgets("rows show the title, the subtitle and the badge only when set", (WidgetTester tester) async {
      await pumpApp(tester, _Harness().bar());

      await _search(tester, "Al");

      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("North side"), findsOneWidget);
      expect(find.text("Town"), findsOneWidget);
      expect(find.text("Beta"), findsOneWidget);
      final ColorScheme cs = AppTheme.light().colorScheme;
      final Finder badges = find.byWidgetPredicate(
        (Widget w) => w is DecoratedBox && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).color == cs.primaryContainer,
      );
      expect(badges, findsOneWidget);
      final Finder search = find.byType(AutocompleteSearch<LocationSuggestion<int>>);
      expect(tester.widget<AutocompleteSearch<LocationSuggestion<int>>>(search).dropdownWidth, tester.getSize(search).width);
    });

    testWidgets("an explicit semanticsLabel replaces the row's texts", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final _Harness harness = _Harness()
        ..answer = (String query) async => <LocationSuggestion<int>>[
              const LocationSuggestion<int>(value: 3, title: "Gamma", badge: "Area", semanticsLabel: "Gamma, full address"),
            ];
      await pumpApp(tester, harness.bar());

      await _search(tester, "Ga");

      expect(find.bySemanticsLabel("Gamma, full address"), findsOneWidget);
      expect(find.bySemanticsLabel("Area"), findsNothing);
      handle.dispose();
    });

    testWidgets("picking a suggestion reports it and shows the selected row", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await pumpApp(tester, harness.bar());
      await _search(tester, "Al");

      await tester.tap(find.text("Alpha"));
      await _settle(tester);

      expect(harness.picked, hasLength(1));
      expect(identical(harness.picked.single, _alpha), isTrue);
      expect(harness.picked.single.value, 1);
      expect(find.byType(EditableValueRow), findsOneWidget);
      expect(_field, findsNothing);

      await pumpApp(tester, harness.bar((value: 1, title: "Alpha", subtitle: null, hintText: null, alternativeHint: null)));
      expect(tester.widget<EditableValueRow>(find.byType(EditableValueRow)).title, "Alpha");
    });

    testWidgets("only the latest response is shown", (WidgetTester tester) async {
      final Map<String, Completer<List<LocationSuggestion<int>>>> calls = <String, Completer<List<LocationSuggestion<int>>>>{};
      final _Harness harness = _Harness()
        ..answer = (String query) => (calls[query] = Completer<List<LocationSuggestion<int>>>()).future;
      await pumpApp(tester, harness.bar());

      await tester.enterText(_field, "Al");
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(_field, "Be");
      await tester.pump(const Duration(milliseconds: 500));
      calls["Be"]!.complete(<LocationSuggestion<int>>[_beta]);
      await tester.pump();
      calls["Al"]!.complete(<LocationSuggestion<int>>[_alpha]);
      await tester.pump();

      expect(find.text("Beta"), findsOneWidget);
      expect(find.text("Alpha"), findsNothing);
    });

    testWidgets("a throwing search is reported through onError", (WidgetTester tester) async {
      final _Harness harness = _Harness()..answer = (String query) async => throw StateError("offline");
      await pumpApp(tester, harness.bar());

      await _search(tester, "Al");

      expect(tester.takeException(), isNull);
      expect(harness.errors.single, isA<StateError>());
      expect(find.byType(Loader), findsNothing);
      expect(find.text("Alpha"), findsNothing);
    });
  });
}

void _hostUpdateTests() {
  group("host updates", () {
    testWidgets("a new value while editing returns to the selected row", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await pumpApp(tester, harness.bar(_alphaSelected));
      await tester.tap(_selectedRow);
      await _settle(tester);

      await pumpApp(tester, harness.bar((value: 2, title: "Beta", subtitle: null, hintText: null, alternativeHint: null)));
      await _settle(tester);

      expect(find.byType(EditableValueRow), findsOneWidget);
      expect(find.text("Beta"), findsOneWidget);
      expect(_field, findsNothing);
    });

    testWidgets("an equal value while editing keeps editing", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await pumpApp(tester, harness.bar(_alphaSelected));
      await tester.tap(_selectedRow);
      await _settle(tester);

      await pumpApp(tester, harness.bar(_alphaSelected));
      await _settle(tester);

      expect(find.text(_cancelKey), findsOneWidget);
      expect(find.byType(EditableValueRow), findsNothing);
    });

    testWidgets("a value set while editing from empty selects it", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await pumpApp(tester, harness.bar());
      await tester.tap(_field);
      await _settle(tester);

      await pumpApp(tester, harness.bar(_alphaSelected));
      await _settle(tester);

      expect(find.byType(EditableValueRow), findsOneWidget);
    });

    testWidgets("a value selects the empty bar and null empties the selected bar", (WidgetTester tester) async {
      final _Harness harness = _Harness();
      await pumpApp(tester, harness.bar());

      await pumpApp(tester, harness.bar(_alphaSelected));
      await _settle(tester);
      expect(find.byType(EditableValueRow), findsOneWidget);

      await pumpApp(tester, harness.bar());
      await _settle(tester);
      expect(find.byType(EditableValueRow), findsNothing);
      expect(_field, findsOneWidget);
      expect(harness.started, 0);
    });
  });
}

void _locateTests() {
  group("current location", () {
    testWidgets("a non-null result is selected like a pick", (WidgetTester tester) async {
      final _Harness harness = _Harness()..locate = () async => _beta;
      await pumpApp(tester, harness.bar());

      await tester.tap(find.text(_myLocationKey));
      await _settle(tester);

      expect(harness.locateCalls, 1);
      expect(identical(harness.picked.single, _beta), isTrue);
      expect(find.byType(EditableValueRow), findsOneWidget);
    });

    testWidgets("while busy it shows a Loader and ignores taps; null keeps the mode", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final Completer<LocationSuggestion<int>?> call = Completer<LocationSuggestion<int>?>();
      final _Harness harness = _Harness()..locate = () => call.future;
      await pumpApp(tester, harness.bar());

      await tester.tap(find.text(_myLocationKey));
      await tester.pump();
      expect(find.byType(Loader), findsOneWidget);
      expect(find.byIcon(Icons.my_location_rounded), findsNothing);
      expect(tester.getSemantics(find.text(_myLocationKey)), _busyRowSemantics);

      await tester.tap(find.text(_myLocationKey));
      await tester.pump();
      expect(harness.locateCalls, 1);

      call.complete(null);
      await tester.pump();
      expect(find.byType(Loader), findsNothing);
      expect(harness.picked, isEmpty);
      expect(_field, findsOneWidget);
      handle.dispose();
    });

    testWidgets("under reduced motion a static, labelled busy icon replaces the Loader", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final Completer<LocationSuggestion<int>?> call = Completer<LocationSuggestion<int>?>();
      final _Harness harness = _Harness()..locate = () => call.future;
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: harness.bar(),
          ),
        ),
      );

      await tester.tap(find.text(_myLocationKey));
      await tester.pump();

      expect(harness.locateCalls, 1);
      expect(find.byType(Loader), findsNothing);
      expect(find.byIcon(Icons.my_location_rounded), findsNothing);
      final Icon busy = tester.widget<Icon>(find.byIcon(Icons.hourglass_top_rounded));
      expect(busy.color, AppTheme.light().colorScheme.onSurfaceVariant);
      expect(tester.getSemantics(find.text(_myLocationKey)), _busyRowSemantics);

      await tester.tap(find.text(_myLocationKey));
      await tester.pump();
      expect(harness.locateCalls, 1);

      call.complete(null);
      await tester.pump();
      expect(find.byIcon(Icons.hourglass_top_rounded), findsNothing);
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
      handle.dispose();
    });

    testWidgets("a throwing lookup is reported through onError", (WidgetTester tester) async {
      final _Harness harness = _Harness()..locate = () async => throw StateError("denied");
      await pumpApp(tester, harness.bar());

      await tester.tap(find.text(_myLocationKey));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(harness.errors.single, isA<StateError>());
      expect(find.byType(Loader), findsNothing);
      expect(harness.picked, isEmpty);
    });

    testWidgets("Cancel drops a result still in flight", (WidgetTester tester) async {
      final Completer<LocationSuggestion<int>?> call = Completer<LocationSuggestion<int>?>();
      final _Harness harness = _Harness()..locate = () => call.future;
      await pumpApp(tester, harness.bar(_alphaSelected));
      await tester.tap(_selectedRow);
      await _settle(tester);
      await tester.tap(find.text(_myLocationKey));
      await tester.pump();

      await tester.tap(find.text(_cancelKey));
      await _settle(tester);
      call.complete(_beta);
      await tester.pump();

      expect(harness.picked, isEmpty);
      expect(find.byType(Loader), findsNothing);
    });

    testWidgets("a new host value drops a result still in flight", (WidgetTester tester) async {
      final Completer<LocationSuggestion<int>?> call = Completer<LocationSuggestion<int>?>();
      final _Harness harness = _Harness()..locate = () => call.future;
      await pumpApp(tester, harness.bar(_alphaSelected));
      await tester.tap(_selectedRow);
      await _settle(tester);
      await tester.tap(find.text(_myLocationKey));
      await tester.pump();

      await pumpApp(tester, harness.bar((value: 2, title: "Beta", subtitle: null, hintText: null, alternativeHint: null)));
      await _settle(tester);
      call.complete(_alpha);
      await tester.pump();

      expect(harness.picked, isEmpty);
      expect(tester.widget<EditableValueRow>(find.byType(EditableValueRow)).title, "Beta");
      expect(find.byType(Loader), findsNothing);
    });

    testWidgets("picking a suggestion drops a result still in flight", (WidgetTester tester) async {
      final Completer<LocationSuggestion<int>?> call = Completer<LocationSuggestion<int>?>();
      final _Harness harness = _Harness()..locate = () => call.future;
      await pumpApp(tester, harness.bar());
      await tester.tap(find.text(_myLocationKey));
      await tester.pump();
      await _search(tester, "Al");

      await tester.tap(find.text("Alpha"));
      await _settle(tester);
      call.complete(_beta);
      await tester.pump();

      expect(harness.picked, <LocationSuggestion<int>>[_alpha]);
      expect(find.byType(EditableValueRow), findsOneWidget);
      expect(find.byType(Loader), findsNothing);
    });
  });
}

void _lifecycleTests() {
  group("lifecycle", () {
    testWidgets("unmounting with a pending debounce or a search in flight is safe", (WidgetTester tester) async {
      final Completer<List<LocationSuggestion<int>>> call = Completer<List<LocationSuggestion<int>>>();
      final _Harness harness = _Harness()..answer = (String query) => call.future;
      await pumpApp(tester, harness.bar());
      await tester.enterText(_field, "Al");
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(_field, "Alp");
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(const SizedBox.shrink());
      call.complete(<LocationSuggestion<int>>[_alpha]);
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull);
      expect(harness.queries, <String>["Al"]);
    });

    testWidgets("unmounting during a current-location call is safe", (WidgetTester tester) async {
      final Completer<LocationSuggestion<int>?> call = Completer<LocationSuggestion<int>?>();
      final _Harness harness = _Harness()..locate = () => call.future;
      await pumpApp(tester, harness.bar());
      await tester.tap(find.text(_myLocationKey));
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      call.complete(_alpha);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(harness.picked, isEmpty);
    });
  });
}

void _accessibilityTests() {
  group("accessibility", () {
    testWidgets("meets the tap-target and labelled-target guidelines in every mode", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final _Harness harness = _Harness()..locate = () async => null;
      const _BarConfig config = (value: 1, title: "Alpha", subtitle: "1.00, 2.00", hintText: null, alternativeHint: "or tap the canvas");
      await pumpApp(tester, harness.bar(_noConfig));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      await pumpApp(tester, harness.bar(config));
      await _settle(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      await tester.tap(_selectedRow);
      await _settle(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets("the my-location row is one button labelled by its text", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final _Harness harness = _Harness()..locate = () async => null;
      await pumpApp(tester, harness.bar());

      expect(
        tester.getSemantics(find.text(_myLocationKey)),
        isSemantics(label: _myLocationKey, isButton: true, hasEnabledState: true, isEnabled: true, hasTapAction: true),
      );
      handle.dispose();
    });
  });
}

void _themeTests() {
  group("theme", () {
    testWidgets("dark theme: every mode renders with the dark ColorScheme", (WidgetTester tester) async {
      final ThemeData dark = AppTheme.dark();
      final _Harness harness = _Harness()..locate = () async => null;
      const _BarConfig config = (value: null, title: null, subtitle: null, hintText: null, alternativeHint: "or tap the canvas");
      await pumpApp(tester, harness.bar(config), theme: dark);
      await _search(tester, "Al");

      final Text hint = tester.widget<Text>(find.text("or tap the canvas"));
      expect(hint.style?.color, dark.colorScheme.onSurfaceVariant);
      final Text badge = tester.widget<Text>(find.text("Town"));
      expect(badge.style?.color, dark.colorScheme.onPrimaryContainer);

      await tester.tap(find.text("Alpha"));
      await _settle(tester);
      await pumpApp(tester, harness.bar(_alphaSelected), theme: dark);
      await tester.tap(_selectedRow);
      await _settle(tester);

      final ColoredBox strip = tester.widget<ColoredBox>(
        find.ancestor(of: find.text(_currentlyKey), matching: find.byType(ColoredBox)).first,
      );
      expect(strip.color, dark.colorScheme.surfaceContainerLow);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Verbatim copy of the widget's i18n fragment (`i18n/LocationBar.json`, the
/// `custom.location_bar` section of assets/translations/fr.json and en.json).
/// Any change to those strings must be mirrored here; once the fragment is
/// merged into the assets, these tests should load the real asset files.
const Map<String, Map<String, String>> _fragment = <String, Map<String, String>>{
  "fr": <String, String>{
    "placeholder": "Rechercher un lieu…",
    "cancel": "Annuler",
    "currently_at": "Actuellement : {name}",
    "unknown_place": "Lieu sélectionné",
    "my_location": "Ma position",
    "modify_semantics": "Modifier le lieu sélectionné",
  },
  "en": <String, String>{
    "placeholder": "Search for a place…",
    "cancel": "Cancel",
    "currently_at": "Currently: {name}",
    "unknown_place": "Selected location",
    "my_location": "My location",
    "modify_semantics": "Edit selected location",
  },
};

/// Serves [_fragment]; [empty] loads no strings so `.tr()` returns raw keys
/// again.
final class _MemoryLoader extends AssetLoader {
  final bool empty;

  const _MemoryLoader({this.empty = false});

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    if (empty) return <String, dynamic>{};
    return <String, dynamic>{
      "custom": <String, dynamic>{"location_bar": _fragment[locale.languageCode]},
    };
  }
}

Future<void> _pumpLocalized(WidgetTester tester, Locale locale, _MemoryLoader loader, Widget child) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    EasyLocalization(
      key: UniqueKey(),
      supportedLocales: const <Locale>[Locale("fr"), Locale("en")],
      path: "memory",
      fallbackLocale: const Locale("fr"),
      startLocale: locale,
      saveLocale: false,
      assetLoader: loader,
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

/// Pumps [child] with the in-memory [locale] strings, opens editing and runs
/// [body]. `.tr()` reads EasyLocalization's global singleton, which outlives
/// the test: the `finally` reloads an empty table so the raw-key tests pass
/// in any order.
Future<void> _withLocalizedEditing(WidgetTester tester, Locale locale, Widget child, void Function() body) async {
  try {
    await _pumpLocalized(tester, locale, const _MemoryLoader(), child);
    await tester.tap(_selectedRow);
    await _settle(tester);
    body();
  } finally {
    await _pumpLocalized(tester, locale, const _MemoryLoader(empty: true), const SizedBox.shrink());
  }
}

void _localizedTests() {
  group("localized", () {
    testWidgets("fr: the reminder reads 'title (subtitle)'", (WidgetTester tester) async {
      await _withLocalizedEditing(tester, const Locale("fr"), _Harness().bar(_alphaSelected), () {
        expect(find.text("Actuellement : Alpha (1.00, 2.00)"), findsOneWidget);
        expect(find.text("Annuler"), findsOneWidget);
      });
    });

    testWidgets("en: without title or subtitle the reminder names the unknown place", (WidgetTester tester) async {
      const _BarConfig config = (value: 1, title: null, subtitle: null, hintText: null, alternativeHint: null);
      await _withLocalizedEditing(tester, const Locale("en"), _Harness().bar(config), () {
        expect(find.text("Currently: Selected location"), findsOneWidget);
      });
    });
  });
}

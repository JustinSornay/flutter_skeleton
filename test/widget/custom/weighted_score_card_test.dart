// weighted_score_card_test.dart
//
// Widget tests for WeightedScoreCard: the first evaluation with normalised
// weights, loading / loaded / error states of the ring and the donut slot,
// the tone ladder and toneOf, the alert chip (and its stable slot during a
// re-evaluation), assertion reporting, proportional rebalancing and the
// all-others-zero split, the debounce, stale results, disposal,
// didUpdateWidget and re-keying, component colours (the full contrast-safe
// cycle in both themes), reduced motion, accessibility, the Overlay / Material
// ancestry, the dark theme, and the real fr / en strings through an in-memory
// EasyLocalization.

import "dart:async";
import "dart:math" as math;

import "package:easy_localization/easy_localization.dart";
import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";
import "package:flutter_skeleton/widgets/custom/WeightedScoreCard/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _alertKey = "custom.weighted_score_card.alert";
const String _errorKey = "custom.weighted_score_card.load_error";
const String _scoreKey = "custom.weighted_score_card.score_semantics";

const Size _surface = Size(400, 700);
const Duration _debounce = Duration(milliseconds: 400);

const List<WeightedScoreComponent> _components = <WeightedScoreComponent>[
  WeightedScoreComponent(id: "a", label: "Alpha", defaultWeight: 20),
  WeightedScoreComponent(id: "b", label: "Beta", defaultWeight: 50),
  WeightedScoreComponent(id: "c", label: "Gamma", defaultWeight: 20),
  WeightedScoreComponent(id: "d", label: "Delta", defaultWeight: 10),
];

const Map<String, double> _breakdown = <String, double>{"a": 0.9, "b": 0.7, "c": 0.5, "d": 0.3};

WeightedScoreResult _result(double score) => WeightedScoreResult(score: score, breakdown: _breakdown);

/// Records every call and answers with [respond] (default: score 0.68).
final class _Evaluator {
  _Evaluator([this.respond]);

  final Future<WeightedScoreResult> Function(Map<String, double> weights)? respond;
  final List<Map<String, double>> calls = <Map<String, double>>[];

  Future<WeightedScoreResult> call(Map<String, double> weights) {
    calls.add(weights);
    final Future<WeightedScoreResult> Function(Map<String, double> weights)? answer = respond;
    return answer == null ? Future<WeightedScoreResult>.value(_result(0.68)) : answer(weights);
  }
}

/// Evaluator answering each call with the next pending [Completer].
final class _ManualEvaluator {
  final List<Completer<WeightedScoreResult>> pending = <Completer<WeightedScoreResult>>[];
  final List<Map<String, double>> calls = <Map<String, double>>[];

  Future<WeightedScoreResult> call(Map<String, double> weights) {
    calls.add(weights);
    final Completer<WeightedScoreResult> completer = Completer<WeightedScoreResult>();
    pending.add(completer);
    return completer.future;
  }
}

WeightedScoreCard _card(
  WeightedScoreEvaluator evaluate, {
  List<WeightedScoreComponent> components = _components,
  String? alertLabel,
  StatusTone Function(double score)? toneOf,
  Duration debounce = _debounce,
}) {
  return WeightedScoreCard(
    components: components,
    evaluate: evaluate,
    alertLabel: alertLabel,
    toneOf: toneOf,
    debounce: debounce,
  );
}

/// Pumps [card] and lets an immediate evaluation resolve.
Future<void> _pump(WidgetTester tester, Widget card, {ThemeData? theme, Size surfaceSize = _surface}) async {
  await pumpApp(
    tester,
    Align(alignment: Alignment.topCenter, child: card),
    surfaceSize: surfaceSize,
    theme: theme,
  );
  await tester.pump();
}

BuildContext _context(WidgetTester tester) => tester.element(find.byType(WeightedScoreCard));

ColorScheme _scheme(WidgetTester tester) => Theme.of(_context(tester)).colorScheme;

ToneColors _tone(WidgetTester tester, StatusTone tone) => StatusTones.colorsOf(_context(tester), tone);

Finder _slider(int index) => find.byType(Slider).at(index);

double _weight(WidgetTester tester, int index) => tester.widget<Slider>(_slider(index)).value;

List<double> _weights(WidgetTester tester) {
  return <double>[for (int i = 0; i < tester.widgetList(find.byType(Slider)).length; i++) _weight(tester, i)];
}

Future<void> _drag(WidgetTester tester, int index, double value) async {
  tester.widget<Slider>(_slider(index)).onChanged!(value);
  await tester.pump();
}

Color? _textColor(WidgetTester tester, String text) => tester.widget<Text>(find.text(text)).style?.color;

Color? _activeTrack(WidgetTester tester, int index) {
  final Finder theme = find.ancestor(of: _slider(index), matching: find.byType(SliderTheme)).first;
  return tester.widget<SliderTheme>(theme).data.activeTrackColor;
}

/// Top edge of the slider at [index], to detect layout jumps.
double _sliderTop(WidgetTester tester, int index) => tester.getTopLeft(_slider(index)).dy;

/// WCAG 2.x contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// [count] components with equal weights and no colour or tone.
List<WeightedScoreComponent> _plainComponents(int count) {
  return <WeightedScoreComponent>[
    for (int i = 0; i < count; i++) WeightedScoreComponent(id: "c$i", label: "C$i", defaultWeight: 1),
  ];
}

void _expectWeights(List<double> actual, List<double> expected) {
  expect(actual.length, expected.length);
  for (int i = 0; i < expected.length; i++) {
    expect(actual[i], closeTo(expected[i], 1e-6), reason: "weight $i");
  }
}

void _expectCall(Map<String, double> call, Map<String, double> expected) {
  expect(call.keys.toSet(), expected.keys.toSet());
  for (final MapEntry<String, double> entry in expected.entries) {
    expect(call[entry.key], closeTo(entry.value, 1e-6), reason: entry.key);
  }
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
        "weighted_score_card": <String, dynamic>{
          "score_semantics": fr ? "Score agrégé : {value} sur 100" : "Aggregate score: {value} out of 100",
          "alert": fr ? "Score critique (< {threshold})" : "Critical score (< {threshold})",
          "alert_semantics": fr ? "Alerte : score critique" : "Alert: critical score",
          "load_error": fr ? "Erreur de chargement" : "Loading error",
          "weight_semantics": fr ? "{label} : {value}" : "{label}: {value}",
        },
      },
    };
  }
}

Future<void> _pumpLocalized(WidgetTester tester, Locale locale, Widget child) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EasyLocalization.ensureInitialized();
  tester.view.physicalSize = _surface;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
          home: Scaffold(body: Align(alignment: Alignment.topCenter, child: child)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group("first evaluation", () {
    testWidgets("calls evaluate once at mount with the normalised defaults", (WidgetTester tester) async {
      final _Evaluator evaluator = _Evaluator();
      await _pump(tester, _card(evaluator.call));

      expect(evaluator.calls, hasLength(1));
      _expectCall(evaluator.calls.single, <String, double>{"a": 0.2, "b": 0.5, "c": 0.2, "d": 0.1});
      expect(() => evaluator.calls.single["a"] = 1, throwsUnsupportedError);
      _expectWeights(_weights(tester), <double>[0.2, 0.5, 0.2, 0.1]);
    });

    testWidgets("gives equal weights when every default is 0", (WidgetTester tester) async {
      final _Evaluator evaluator = _Evaluator();
      await _pump(
        tester,
        _card(
          evaluator.call,
          components: const <WeightedScoreComponent>[
            WeightedScoreComponent(id: "x", label: "X", defaultWeight: 0),
            WeightedScoreComponent(id: "y", label: "Y", defaultWeight: 0),
          ],
        ),
      );

      _expectCall(evaluator.calls.single, <String, double>{"x": 0.5, "y": 0.5});
    });

    testWidgets("shows the pending ring and the Loader while evaluating", (WidgetTester tester) async {
      final _ManualEvaluator evaluator = _ManualEvaluator();
      await _pump(tester, _card(evaluator.call));

      expect(find.text("…"), findsOneWidget);
      expect(find.text("/ 100"), findsOneWidget);
      expect(find.byType(Loader), findsOneWidget);
      expect(find.byType(PieChart), findsNothing);
      expect(_textColor(tester, "…"), _scheme(tester).onSurfaceVariant);

      evaluator.pending.single.complete(_result(0.68));
      await tester.pump();
      expect(find.byType(Loader), findsNothing);
      expect(find.text("68"), findsOneWidget);
    });

    testWidgets("asserts at least two components", (WidgetTester tester) async {
      await _pump(
        tester,
        _card(
          _Evaluator().call,
          components: const <WeightedScoreComponent>[WeightedScoreComponent(id: "x", label: "X", defaultWeight: 1)],
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets("asserts unique ids", (WidgetTester tester) async {
      await _pump(
        tester,
        _card(
          _Evaluator().call,
          components: const <WeightedScoreComponent>[
            WeightedScoreComponent(id: "x", label: "X", defaultWeight: 1),
            WeightedScoreComponent(id: "x", label: "Y", defaultWeight: 1),
          ],
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });
  });

  group("loaded", () {
    testWidgets("shows the score in the warning tone with its icon", (WidgetTester tester) async {
      await _pump(tester, _card(_Evaluator().call));

      final ToneColors warning = _tone(tester, StatusTone.warning);
      expect(find.text("68"), findsOneWidget);
      expect(find.text("/ 100"), findsOneWidget);
      expect(_textColor(tester, "68"), warning.foreground);
      expect(find.byIcon(StatusTone.warning.icon), findsOneWidget);
      expect(tester.widget<Icon>(find.byIcon(StatusTone.warning.icon)).color, warning.foreground);
      expect(find.text(_alertKey), findsNothing);
    });

    testWidgets("uses the success tone from goodThreshold up", (WidgetTester tester) async {
      await _pump(tester, _card(_Evaluator((_) async => _result(0.70)).call));

      expect(find.text("70"), findsOneWidget);
      expect(_textColor(tester, "70"), _tone(tester, StatusTone.success).foreground);
      expect(find.byIcon(StatusTone.success.icon), findsOneWidget);
    });

    testWidgets("toneOf overrides the ladder", (WidgetTester tester) async {
      await _pump(tester, _card(_Evaluator().call, toneOf: (double score) => StatusTone.info));

      expect(_textColor(tester, "68"), _tone(tester, StatusTone.info).foreground);
    });

    testWidgets("draws one donut slice per component with its share", (WidgetTester tester) async {
      await _pump(tester, _card(_Evaluator().call));

      final List<PieChartSectionData> sections = tester.widget<PieChart>(find.byType(PieChart)).data.sections;
      expect(sections, hasLength(4));
      expect(sections[0].value, closeTo(0.2 * 0.9 / 0.68 * 100, 1e-6));
      expect(sections[1].value, closeTo(0.5 * 0.7 / 0.68 * 100, 1e-6));
      expect(sections.every((PieChartSectionData section) => section.title.isEmpty), isTrue);
    });

    testWidgets("falls back to the weights when the score is 0", (WidgetTester tester) async {
      await _pump(tester, _card(_Evaluator((_) async => _result(0)).call));

      final List<PieChartSectionData> sections = tester.widget<PieChart>(find.byType(PieChart)).data.sections;
      expect(<double>[for (final PieChartSectionData s in sections) s.value], <double>[20, 50, 20, 10]);
      expect(find.text("0"), findsOneWidget);
    });

    testWidgets("skips the slice of a component without a score", (WidgetTester tester) async {
      await _pump(
        tester,
        _card(_Evaluator((_) async => const WeightedScoreResult(score: 0.5, breakdown: <String, double>{"a": 1})).call),
      );

      expect(tester.widget<PieChart>(find.byType(PieChart)).data.sections, hasLength(1));
    });

    testWidgets("lists every label with its weight", (WidgetTester tester) async {
      await _pump(tester, _card(_Evaluator().call));

      expect(find.text("Alpha  20%"), findsOneWidget);
      expect(find.text("Beta  50%"), findsOneWidget);
      expect(find.text("Gamma  20%"), findsOneWidget);
      expect(find.text("Delta  10%"), findsOneWidget);
      expect(find.text("50%"), findsOneWidget);
      expect(find.text("20%"), findsNWidgets(2));
    });
  });

  group("alert chip", () {
    testWidgets("shows under the threshold in the danger tone", (WidgetTester tester) async {
      await _pump(tester, _card(_Evaluator((_) async => _result(0.39)).call));

      final ToneColors danger = _tone(tester, StatusTone.danger);
      expect(find.text(_alertKey), findsOneWidget);
      expect(_textColor(tester, _alertKey), danger.onContainer);
      expect(_textColor(tester, "39"), danger.foreground);
      expect(tester.widget<Icon>(find.byIcon(Icons.warning_amber_rounded)).color, danger.onContainer);
      final DecoratedBox box = tester.widget<DecoratedBox>(
        find.ancestor(of: find.text(_alertKey), matching: find.byType(DecoratedBox)).first,
      );
      expect((box.decoration as BoxDecoration).color, danger.container);
    });

    testWidgets("is a live region", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _card(_Evaluator((_) async => _result(0.2)).call));

      final Finder region = find.ancestor(
        of: find.text(_alertKey),
        matching: find.byWidgetPredicate((Widget widget) => widget is Semantics && widget.properties.liveRegion == true),
      );
      expect(region, findsOneWidget);
      expect(tester.getSemantics(region), isSemantics(isLiveRegion: true));
      handle.dispose();
    });

    testWidgets("is hidden at exactly the threshold", (WidgetTester tester) async {
      await _pump(tester, _card(_Evaluator((_) async => _result(0.40)).call));

      expect(find.text(_alertKey), findsNothing);
      expect(_textColor(tester, "40"), _tone(tester, StatusTone.warning).foreground);
    });

    testWidgets("shows a custom alertLabel", (WidgetTester tester) async {
      await _pump(tester, _card(_Evaluator((_) async => _result(0.1)).call, alertLabel: "Too low"));

      expect(find.text("Too low"), findsOneWidget);
      expect(find.text(_alertKey), findsNothing);
    });

    testWidgets("is hidden while loading and after an error", (WidgetTester tester) async {
      final _ManualEvaluator evaluator = _ManualEvaluator();
      await _pump(tester, _card(evaluator.call));
      expect(find.text(_alertKey), findsNothing);

      evaluator.pending.single.completeError(StateError("offline"));
      await tester.pump();
      expect(find.text(_alertKey), findsNothing);
    });

    testWidgets("keeps its slot while a new mix is evaluated", (WidgetTester tester) async {
      final _ManualEvaluator evaluator = _ManualEvaluator();
      await _pump(tester, _card(evaluator.call));
      evaluator.pending[0].complete(_result(0.2));
      await tester.pump();
      final double loadedTop = _sliderTop(tester, 0);
      expect(find.text(_alertKey), findsOneWidget);

      await _drag(tester, 0, 0.3);
      await tester.pump(_debounce);
      expect(evaluator.calls, hasLength(2));
      expect(find.text("…"), findsOneWidget);
      expect(find.text(_alertKey), findsOneWidget);
      expect(_sliderTop(tester, 0), loadedTop);

      evaluator.pending[1].complete(_result(0.25));
      await tester.pump();
      expect(find.text("25"), findsOneWidget);
      expect(_sliderTop(tester, 0), loadedTop);
    });

    testWidgets("goes away once the new score clears the threshold", (WidgetTester tester) async {
      final _ManualEvaluator evaluator = _ManualEvaluator();
      await _pump(tester, _card(evaluator.call));
      evaluator.pending[0].complete(_result(0.2));
      await tester.pump();

      await _drag(tester, 0, 0.3);
      await tester.pump(_debounce);
      evaluator.pending[1].complete(_result(0.8));
      await tester.pump();

      expect(find.text(_alertKey), findsNothing);
    });

    testWidgets("does not come back for a re-evaluation after an error", (WidgetTester tester) async {
      final _ManualEvaluator evaluator = _ManualEvaluator();
      await _pump(tester, _card(evaluator.call));
      evaluator.pending[0].complete(_result(0.2));
      await tester.pump();

      await _drag(tester, 0, 0.3);
      await tester.pump(_debounce);
      evaluator.pending[1].completeError(StateError("offline"));
      await tester.pump();
      expect(find.text(_alertKey), findsNothing);

      await _drag(tester, 0, 0.4);
      await tester.pump(_debounce);
      expect(evaluator.calls, hasLength(3));
      expect(find.text(_alertKey), findsNothing);
    });

    testWidgets("is dropped when new ids reset the card", (WidgetTester tester) async {
      final _ManualEvaluator evaluator = _ManualEvaluator();
      await _pump(tester, _card(evaluator.call));
      evaluator.pending[0].complete(_result(0.2));
      await tester.pump();

      await _pump(tester, _card(evaluator.call, components: _plainComponents(2)));
      expect(evaluator.calls, hasLength(2));
      expect(find.text(_alertKey), findsNothing);
    });
  });

  group("error", () {
    testWidgets("shows the dash and the error text, then recovers", (WidgetTester tester) async {
      int attempt = 0;
      final _Evaluator evaluator = _Evaluator((_) async {
        attempt++;
        if (attempt == 1) throw StateError("offline");
        return _result(0.85);
      });
      await _pump(tester, _card(evaluator.call));

      expect(find.text("—"), findsOneWidget);
      expect(find.text(_errorKey), findsOneWidget);
      expect(find.byType(PieChart), findsNothing);
      expect(_textColor(tester, "—"), _scheme(tester).onSurfaceVariant);

      await _drag(tester, 0, 0.3);
      await tester.pump(_debounce);
      await tester.pump();

      expect(evaluator.calls, hasLength(2));
      expect(find.text("85"), findsOneWidget);
      expect(find.text(_errorKey), findsNothing);
      expect(find.byType(PieChart), findsOneWidget);
    });

    testWidgets("catches an evaluator that throws synchronously", (WidgetTester tester) async {
      await _pump(tester, _card((Map<String, double> weights) => throw ArgumentError("bad")));

      expect(tester.takeException(), isNull);
      expect(find.text(_errorKey), findsOneWidget);
    });

    testWidgets("reports a score outside [0, 1] to the developer", (WidgetTester tester) async {
      await _pump(tester, _card(_Evaluator((_) async => _result(68)).call));

      expect(tester.takeException(), isAssertionError);
      expect(find.text(_errorKey), findsOneWidget);
      expect(find.text("—"), findsOneWidget);
    });
  });

  group("rebalancing", () {
    testWidgets("spreads a change over the others in proportion", (WidgetTester tester) async {
      await _pump(tester, _card(_Evaluator().call));

      await _drag(tester, 1, 0.6);

      final List<double> weights = _weights(tester);
      _expectWeights(weights, <double>[0.16, 0.6, 0.16, 0.08]);
      expect(weights.fold(0.0, (double sum, double weight) => sum + weight), closeTo(1, 1e-6));
      expect(find.text("60%"), findsOneWidget);
      expect(find.text("16%"), findsNWidgets(2));
      expect(find.text("8%"), findsOneWidget);
    });

    testWidgets("gives equal others equal shares", (WidgetTester tester) async {
      await _pump(
        tester,
        _card(
          _Evaluator().call,
          components: const <WeightedScoreComponent>[
            WeightedScoreComponent(id: "a", label: "Alpha", defaultWeight: 1),
            WeightedScoreComponent(id: "b", label: "Beta", defaultWeight: 1),
            WeightedScoreComponent(id: "c", label: "Gamma", defaultWeight: 1),
            WeightedScoreComponent(id: "d", label: "Delta", defaultWeight: 1),
          ],
        ),
      );

      await _drag(tester, 1, 0.6);
      _expectWeights(_weights(tester), <double>[0.4 / 3, 0.6, 0.4 / 3, 0.4 / 3]);
    });

    testWidgets("splits the remainder equally when the others are 0", (WidgetTester tester) async {
      await _pump(
        tester,
        _card(
          _Evaluator().call,
          components: const <WeightedScoreComponent>[
            WeightedScoreComponent(id: "a", label: "Alpha", defaultWeight: 1),
            WeightedScoreComponent(id: "b", label: "Beta", defaultWeight: 0),
            WeightedScoreComponent(id: "c", label: "Gamma", defaultWeight: 0),
            WeightedScoreComponent(id: "d", label: "Delta", defaultWeight: 0),
          ],
        ),
      );

      await _drag(tester, 0, 0.4);
      _expectWeights(_weights(tester), <double>[0.4, 0.2, 0.2, 0.2]);
    });

    testWidgets("updates the legend while the last result stays shown", (WidgetTester tester) async {
      await _pump(tester, _card(_Evaluator().call));

      await _drag(tester, 1, 0.6);
      expect(find.text("Beta  60%"), findsOneWidget);
      expect(find.text("68"), findsOneWidget);
    });
  });

  group("debounce", () {
    testWidgets("evaluates once with the last weights after the quiet time", (WidgetTester tester) async {
      final _Evaluator evaluator = _Evaluator();
      await _pump(tester, _card(evaluator.call));

      await _drag(tester, 0, 0.3);
      await tester.pump(const Duration(milliseconds: 100));
      await _drag(tester, 0, 0.4);
      await tester.pump(const Duration(milliseconds: 100));
      await _drag(tester, 1, 0.3);
      final List<double> last = _weights(tester);

      await tester.pump(const Duration(milliseconds: 399));
      expect(evaluator.calls, hasLength(1));
      await tester.pump(const Duration(milliseconds: 1));
      expect(evaluator.calls, hasLength(2));
      _expectCall(evaluator.calls.last, <String, double>{"a": last[0], "b": last[1], "c": last[2], "d": last[3]});
    });

    testWidgets("respects a custom debounce", (WidgetTester tester) async {
      final _Evaluator evaluator = _Evaluator();
      await _pump(tester, _card(evaluator.call, debounce: const Duration(seconds: 1)));

      await _drag(tester, 0, 0.3);
      await tester.pump(const Duration(milliseconds: 999));
      expect(evaluator.calls, hasLength(1));
      await tester.pump(const Duration(milliseconds: 1));
      expect(evaluator.calls, hasLength(2));
    });

    testWidgets("defaults to 400 ms", (WidgetTester tester) async {
      final _Evaluator evaluator = _Evaluator();
      await _pump(tester, WeightedScoreCard(components: _components, evaluate: evaluator.call));

      await _drag(tester, 0, 0.3);
      await tester.pump(const Duration(milliseconds: 399));
      expect(evaluator.calls, hasLength(1));
      await tester.pump(const Duration(milliseconds: 1));
      expect(evaluator.calls, hasLength(2));
    });
  });

  group("stale results", () {
    testWidgets("renders only the latest evaluation", (WidgetTester tester) async {
      final _ManualEvaluator evaluator = _ManualEvaluator();
      await _pump(tester, _card(evaluator.call));
      evaluator.pending[0].complete(_result(0.68));
      await tester.pump();

      await _drag(tester, 0, 0.3);
      await tester.pump(_debounce);
      await _drag(tester, 0, 0.4);
      await tester.pump(_debounce);
      expect(evaluator.calls, hasLength(3));

      evaluator.pending[2].complete(_result(0.85));
      await tester.pump();
      expect(find.text("85"), findsOneWidget);

      evaluator.pending[1].complete(_result(0.30));
      await tester.pump();
      expect(find.text("85"), findsOneWidget);
      expect(find.text("30"), findsNothing);
      expect(find.text(_alertKey), findsNothing);
    });

    testWidgets("ignores a stale error", (WidgetTester tester) async {
      final _ManualEvaluator evaluator = _ManualEvaluator();
      await _pump(tester, _card(evaluator.call));

      await _drag(tester, 0, 0.3);
      await tester.pump(_debounce);
      evaluator.pending[1].complete(_result(0.5));
      await tester.pump();
      evaluator.pending[0].completeError(StateError("late"));
      await tester.pump();

      expect(find.text("50"), findsOneWidget);
      expect(find.text(_errorKey), findsNothing);
    });
  });

  group("dispose", () {
    testWidgets("cancels a pending debounce", (WidgetTester tester) async {
      final _Evaluator evaluator = _Evaluator();
      await _pump(tester, _card(evaluator.call));
      await _drag(tester, 0, 0.3);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));

      expect(evaluator.calls, hasLength(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets("ignores a result that lands after unmount", (WidgetTester tester) async {
      final _ManualEvaluator evaluator = _ManualEvaluator();
      await _pump(tester, _card(evaluator.call));

      await tester.pumpWidget(const SizedBox.shrink());
      evaluator.pending.single.complete(_result(0.5));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group("didUpdateWidget", () {
    testWidgets("keeps the weights for a new list with the same ids", (WidgetTester tester) async {
      final _Evaluator evaluator = _Evaluator();
      await _pump(tester, _card(evaluator.call));
      await _drag(tester, 1, 0.6);

      await _pump(
        tester,
        _card(
          evaluator.call,
          components: <WeightedScoreComponent>[
            for (final WeightedScoreComponent component in _components)
              WeightedScoreComponent(id: component.id, label: "${component.label}!", defaultWeight: 1),
          ],
        ),
      );

      _expectWeights(_weights(tester), <double>[0.16, 0.6, 0.16, 0.08]);
      expect(find.text("Beta!"), findsOneWidget);
      expect(evaluator.calls, hasLength(1));
    });

    testWidgets("resets the weights and evaluates for new ids", (WidgetTester tester) async {
      final _Evaluator evaluator = _Evaluator();
      await _pump(tester, _card(evaluator.call));
      await _drag(tester, 1, 0.6);

      await _pump(
        tester,
        _card(
          evaluator.call,
          components: const <WeightedScoreComponent>[
            WeightedScoreComponent(id: "x", label: "X", defaultWeight: 3),
            WeightedScoreComponent(id: "y", label: "Y", defaultWeight: 1),
          ],
        ),
      );

      _expectWeights(_weights(tester), <double>[0.75, 0.25]);
      expect(evaluator.calls, hasLength(2));
      _expectCall(evaluator.calls.last, <String, double>{"x": 0.75, "y": 0.25});

      // The debounce scheduled before the update was cancelled.
      await tester.pump(const Duration(seconds: 1));
      expect(evaluator.calls, hasLength(2));
    });

    testWidgets("re-evaluates when the host gives the card a new key", (WidgetTester tester) async {
      final _Evaluator evaluator = _Evaluator();
      Widget keyed(String key) {
        return WeightedScoreCard(key: ValueKey<String>(key), components: _components, evaluate: evaluator.call);
      }

      await _pump(tester, keyed("first"));
      await _pump(tester, keyed("first"));
      expect(evaluator.calls, hasLength(1));

      await _pump(tester, keyed("second"));
      expect(evaluator.calls, hasLength(2));
    });
  });

  group("colours", () {
    testWidgets("cycles ColorScheme colours by default", (WidgetTester tester) async {
      await _pump(tester, _card(_Evaluator().call));

      final ColorScheme cs = _scheme(tester);
      expect(_activeTrack(tester, 0), cs.primary);
      expect(_activeTrack(tester, 1), cs.tertiary);
      expect(_activeTrack(tester, 2), cs.secondary);
      expect(_activeTrack(tester, 3), cs.error);
      final List<PieChartSectionData> sections = tester.widget<PieChart>(find.byType(PieChart)).data.sections;
      expect(sections[1].color, cs.tertiary);
    });

    testWidgets("uses the tone foreground, then the explicit colour", (WidgetTester tester) async {
      final Color explicit = AppTheme.light().colorScheme.inversePrimary;
      await _pump(
        tester,
        _card(
          _Evaluator().call,
          components: <WeightedScoreComponent>[
            const WeightedScoreComponent(id: "a", label: "Alpha", defaultWeight: 1, tone: StatusTone.success),
            WeightedScoreComponent(id: "b", label: "Beta", defaultWeight: 1, tone: StatusTone.danger, color: explicit),
          ],
        ),
      );

      expect(_activeTrack(tester, 0), _tone(tester, StatusTone.success).foreground);
      expect(_activeTrack(tester, 1), explicit);
    });

    for (final (String name, ThemeData theme) in <(String, ThemeData)>[
      ("light", AppTheme.light()),
      ("dark", AppTheme.dark()),
    ]) {
      testWidgets("keeps every default colour visible with 8 components ($name)", (WidgetTester tester) async {
        await _pump(tester, _card(_Evaluator().call, components: _plainComponents(8)), theme: theme, surfaceSize: const Size(400, 1000));
        expect(tester.takeException(), isNull);

        final ColorScheme cs = _scheme(tester);
        final List<Color> expected = <Color>[
          cs.primary,
          cs.tertiary,
          cs.secondary,
          cs.error,
          cs.onPrimaryContainer,
          cs.onTertiaryContainer,
          cs.outline,
          cs.primary,
        ];
        final List<PieChartSectionData> sections = tester.widget<PieChart>(find.byType(PieChart)).data.sections;
        expect(sections, hasLength(8));
        for (int i = 0; i < 8; i++) {
          final Color color = _activeTrack(tester, i)!;
          expect(color, expected[i], reason: "slider $i");
          expect(sections[i].color, expected[i], reason: "slice $i");
          expect(_contrast(color, cs.surface), greaterThanOrEqualTo(3), reason: "slider $i on surface");
          expect(_contrast(color, cs.surfaceContainerHighest), greaterThanOrEqualTo(3), reason: "slider $i on track");
        }
      });
    }

    testWidgets("draws the card with theme tokens", (WidgetTester tester) async {
      await _pump(tester, _card(_Evaluator().call));

      final ColorScheme cs = _scheme(tester);
      final Material card = tester.widget<Material>(
        find.descendant(of: find.byType(WeightedScoreCard), matching: find.byType(Material)).first,
      );
      expect(card.color, cs.surface);
      expect((card.shape! as RoundedRectangleBorder).side.color, cs.outlineVariant);
      final SliderTheme sliderTheme = tester.widget<SliderTheme>(
        find.ancestor(of: _slider(0), matching: find.byType(SliderTheme)).first,
      );
      expect(sliderTheme.data.inactiveTrackColor, cs.surfaceContainerHighest);
    });
  });

  group("motion", () {
    testWidgets("animates the donut by default", (WidgetTester tester) async {
      await _pump(tester, _card(_Evaluator().call));

      expect(tester.widget<PieChart>(find.byType(PieChart)).duration, PieChart.defaultDuration);
      expect(PieChart.defaultDuration, isNot(Duration.zero));
    });

    testWidgets("skips the donut animation under reduced motion", (WidgetTester tester) async {
      await _pump(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: _card(_Evaluator().call),
          ),
        ),
      );

      expect(tester.widget<PieChart>(find.byType(PieChart)).duration, Duration.zero);
    });
  });

  group("accessibility", () {
    testWidgets("slider rows are at least 48 dp high", (WidgetTester tester) async {
      await _pump(tester, _card(_Evaluator().call));

      for (int i = 0; i < 4; i++) {
        expect(tester.getSize(_slider(i)).height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets("the ring is one labelled node", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, _card(_Evaluator().call));

      expect(find.bySemanticsLabel(_scoreKey), findsOneWidget);
      handle.dispose();
    });

    testWidgets("the ring has no label until a score is loaded", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final _ManualEvaluator evaluator = _ManualEvaluator();
      await _pump(tester, _card(evaluator.call));

      expect(find.bySemanticsLabel(_scoreKey), findsNothing);
      expect(find.bySemanticsLabel("common.loading"), findsOneWidget);

      evaluator.pending.single.completeError(StateError("offline"));
      await tester.pump();
      expect(find.bySemanticsLabel(_scoreKey), findsNothing);
      expect(find.bySemanticsLabel(_errorKey), findsOneWidget);
      handle.dispose();
    });

    testWidgets("a slider can be moved through semantics", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final _Evaluator evaluator = _Evaluator();
      await _pump(tester, _card(evaluator.call));

      tester.semantics.increase(find.semantics.byValue("custom.weighted_score_card.weight_semantics").first);
      await tester.pump();
      expect(_weight(tester, 0), greaterThan(0.2));
      handle.dispose();
    });
  });

  group("layout", () {
    testWidgets("fits a narrow width", (WidgetTester tester) async {
      await _pump(tester, _card(_Evaluator((_) async => _result(0.2)).call), surfaceSize: const Size(300, 700));

      expect(tester.takeException(), isNull);
      expect(find.text(_alertKey), findsOneWidget);
    });

    testWidgets("works without a Material ancestor", (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Align(alignment: Alignment.topCenter, child: _card(_Evaluator().call)),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.ancestor(of: find.byType(WeightedScoreCard), matching: find.byType(Material)), findsNothing);
      expect(find.text("68"), findsOneWidget);
      await _drag(tester, 0, 0.5);
      expect(_weight(tester, 0), closeTo(0.5, 1e-6));
    });

    testWidgets("fails without an Overlay ancestor", (WidgetTester tester) async {
      // Everything a MaterialApp provides except the Navigator and its Overlay.
      final List<FlutterErrorDetails> errors = <FlutterErrorDetails>[];
      final void Function(FlutterErrorDetails details)? previous = FlutterError.onError;
      FlutterError.onError = errors.add;
      try {
        await tester.pumpWidget(
          Localizations(
            locale: const Locale("en"),
            delegates: const <LocalizationsDelegate<dynamic>>[
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            child: MediaQuery(
              data: const MediaQueryData(size: _surface),
              child: Theme(
                data: AppTheme.light(),
                child: Align(alignment: Alignment.topCenter, child: _card(_Evaluator().call)),
              ),
            ),
          ),
        );
      } finally {
        FlutterError.onError = previous;
      }

      expect(errors, isNotEmpty);
      for (final FlutterErrorDetails error in errors) {
        expect(error.exceptionAsString(), contains("No Overlay widget found"));
      }
    });
  });

  group("dark theme", () {
    testWidgets("renders the tones of the dark scheme", (WidgetTester tester) async {
      await _pump(tester, _card(_Evaluator((_) async => _result(0.3)).call), theme: AppTheme.dark());

      final ColorScheme cs = _scheme(tester);
      expect(cs.brightness, Brightness.dark);
      expect(_textColor(tester, "30"), _tone(tester, StatusTone.danger).foreground);
      expect(_textColor(tester, _alertKey), _tone(tester, StatusTone.danger).onContainer);
      expect(_activeTrack(tester, 0), cs.primary);
      expect(tester.takeException(), isNull);
    });
  });

  // Last: EasyLocalization keeps the loaded translations in a singleton, so
  // pumpApp tests that follow would read them instead of the raw keys.
  group("localized", () {
    testWidgets("reads the en strings", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(tester, const Locale("en"), _card(_Evaluator((_) async => _result(0.39)).call));

      expect(find.text("Critical score (< 40)"), findsOneWidget);
      expect(find.bySemanticsLabel("Aggregate score: 39 out of 100"), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp("^Alert: critical score")), findsOneWidget);
      expect(tester.getSemantics(_slider(1)), isSemantics(value: "Beta: 50%"));
      expect(find.text("Alpha  20%"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("reads the fr strings and percentages", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(tester, const Locale("fr"), _card(_Evaluator().call));

      final String fifty = NumberFormat.percentPattern("fr").format(0.5);
      expect(fifty, isNot("50%"));
      expect(find.bySemanticsLabel("Score agrégé : 68 sur 100"), findsOneWidget);
      expect(tester.getSemantics(_slider(1)), isSemantics(value: "Beta : $fifty"));
      expect(find.text(fifty), findsOneWidget);
      expect(find.text("Beta  $fifty"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("reads the error text", (WidgetTester tester) async {
      await _pumpLocalized(
        tester,
        const Locale("en"),
        _card((Map<String, double> weights) async => throw StateError("offline")),
      );

      expect(find.text("Loading error"), findsOneWidget);
    });
  });
}

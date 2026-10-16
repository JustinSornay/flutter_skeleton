// value_matrix_test.dart
//
// Widget tests for ValueMatrix: the Loader while columns load, the header
// (labels, captions, corner label), row labels and default 2-decimal values
// (ambient locale), wide values scaled down instead of cut, the concurrency
// cap and one call per column, hidden rows and ignored ids, the "—" missing
// cell, header sorting (direction, arrows, missing last, ties), error (live
// region) + retry, the empty state, the CSV export (sort order, formatValue),
// tone tinting and untinted cells, reload rules in didUpdateWidget (Loader
// while reloading, stale results, errors and chunks of a superseded load
// dropped, no setState after dispose), 48 dp targets and header semantics,
// and a dark-theme smoke test.

import "dart:async";
import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";
import "package:flutter_skeleton/widgets/custom/ValueMatrix/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const Size _surface = Size(800, 600);
const String _loadErrorKey = "custom.value_matrix.load_error";
const String _retryKey = "custom.value_matrix.retry";
const String _emptyKey = "custom.value_matrix.empty";
const String _exportKey = "custom.value_matrix.export_csv";
const String _sortHintKey = "custom.value_matrix.sort_hint";
const String _ascendingKey = "custom.value_matrix.sorted_ascending";
const String _descendingKey = "custom.value_matrix.sorted_descending";
const String _noValueKey = "custom.value_matrix.no_value";

const List<ValueMatrixRow> _rows = <ValueMatrixRow>[
  ValueMatrixRow(id: "a", label: "Alpha"),
  ValueMatrixRow(id: "b", label: "Beta"),
  ValueMatrixRow(id: "c", label: "Gamma"),
  ValueMatrixRow(id: "d", label: "Delta"),
];

const List<ValueMatrixColumn> _columns = <ValueMatrixColumn>[
  ValueMatrixColumn(id: "x", label: "Col X", caption: "+1"),
  ValueMatrixColumn(id: "y", label: "Col Y"),
];

/// x: a 0.5, b 0.9, c 0.5 — y: a 0.2, b 0.4 — d has no value, z is unlisted.
const Map<String, Map<String, double>> _data = <String, Map<String, double>>{
  "x": <String, double>{"a": 0.5, "b": 0.9, "c": 0.5, "z": 0.7},
  "y": <String, double>{"a": 0.2, "b": 0.4},
};

/// Loader resolving immediately with [data] and counting its calls.
final class _Source {
  _Source([this.data = _data]);

  final Map<String, Map<String, double>> data;
  final List<String> calls = <String>[];

  Future<Map<String, double>> call(String columnId) async {
    calls.add(columnId);
    return data[columnId] ?? const <String, double>{};
  }
}

/// Loader whose calls stay pending until [complete] / [fail].
final class _PendingSource {
  final List<String> calls = <String>[];
  final Map<String, Completer<Map<String, double>>> _pending = <String, Completer<Map<String, double>>>{};
  int inFlight = 0;
  int maxInFlight = 0;

  Future<Map<String, double>> call(String columnId) {
    calls.add(columnId);
    inFlight++;
    maxInFlight = math.max(maxInFlight, inFlight);
    final Completer<Map<String, double>> completer = Completer<Map<String, double>>();
    _pending[columnId] = completer;
    return completer.future.whenComplete(() => inFlight--);
  }

  void complete(String columnId, [Map<String, double> values = const <String, double>{"a": 1}]) {
    _pending.remove(columnId)!.complete(values);
  }

  void fail(String columnId) {
    _pending.remove(columnId)!.completeError(StateError("boom"));
  }
}

ValueMatrix _matrix({
  List<ValueMatrixRow> rows = _rows,
  List<ValueMatrixColumn> columns = _columns,
  Future<Map<String, double>> Function(String columnId)? loadColumn,
  int? maxConcurrent,
  StatusTone Function(double value)? toneOf,
  Future<void> Function(String csv)? onExport,
  String Function(double value)? formatValue,
}) {
  final Future<Map<String, double>> Function(String columnId) load = loadColumn ?? _Source().call;
  return maxConcurrent == null
      ? ValueMatrix(
          rows: rows,
          columns: columns,
          loadColumn: load,
          rowHeaderLabel: "Name",
          toneOf: toneOf,
          onExport: onExport,
          formatValue: formatValue,
        )
      : ValueMatrix(
          rows: rows,
          columns: columns,
          loadColumn: load,
          maxConcurrent: maxConcurrent,
          rowHeaderLabel: "Name",
          toneOf: toneOf,
          onExport: onExport,
          formatValue: formatValue,
        );
}

Future<void> _pump(WidgetTester tester, Widget matrix, {ThemeData? theme}) async {
  await pumpApp(tester, matrix, surfaceSize: _surface, theme: theme);
  await tester.pump();
}

/// [labels] ordered top to bottom as rendered.
List<String> _order(WidgetTester tester, List<String> labels) {
  final List<String> sorted = List<String>.of(labels);
  sorted.sort((String a, String b) => tester.getTopLeft(find.text(a)).dy.compareTo(tester.getTopLeft(find.text(b)).dy));
  return sorted;
}

BoxDecoration _cellDecoration(WidgetTester tester, String text) {
  final Finder cell = find.ancestor(of: find.text(text), matching: find.byType(Container)).first;
  return tester.widget<Container>(cell).decoration! as BoxDecoration;
}

Finder _header(String label) => find.ancestor(of: find.text(label), matching: find.byType(InkWell));

void main() {
  group("loading and layout", () {
    testWidgets("shows the Loader until every column resolves", (WidgetTester tester) async {
      final _PendingSource source = _PendingSource();
      await pumpApp(tester, _matrix(loadColumn: source.call), surfaceSize: _surface);
      expect(find.byType(Loader), findsOneWidget);

      source.complete("x", const <String, double>{"a": 0.5});
      await tester.pump();
      expect(find.byType(Loader), findsOneWidget);

      source.complete("y", const <String, double>{"a": 0.25});
      await tester.pump();
      expect(find.byType(Loader), findsNothing);
      expect(find.text("Alpha"), findsOneWidget);
    });

    testWidgets("renders headers, captions, row labels and 2-decimal values", (WidgetTester tester) async {
      await _pump(tester, _matrix());

      expect(find.text("Name"), findsOneWidget);
      expect(find.text("Col X"), findsOneWidget);
      expect(find.text("+1"), findsOneWidget);
      expect(find.text("Col Y"), findsOneWidget);
      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("Beta"), findsOneWidget);
      expect(find.text("Gamma"), findsOneWidget);
      expect(find.text("0.90"), findsOneWidget);
      expect(find.text("0.50"), findsNWidgets(2));
      expect(find.text("0.20"), findsOneWidget);
      expect(find.text("0.40"), findsOneWidget);
    });

    testWidgets("hides an empty caption", (WidgetTester tester) async {
      await _pump(
        tester,
        _matrix(columns: const <ValueMatrixColumn>[ValueMatrixColumn(id: "x", label: "Col X", caption: "")]),
      );
      final Finder texts = find.descendant(of: _header("Col X"), matching: find.byType(Text));
      expect(texts, findsOneWidget);
    });

    testWidgets("formats values for the ambient locale by default", (WidgetTester tester) async {
      await _pump(
        tester,
        Builder(
          builder: (BuildContext context) => Localizations.override(
            context: context,
            locale: const Locale("fr", "FR"),
            child: _matrix(),
          ),
        ),
      );
      expect(find.text("0,90"), findsOneWidget);
    });

    testWidgets("uses formatValue when given", (WidgetTester tester) async {
      await _pump(tester, _matrix(formatValue: (double value) => "${(value * 100).round()}%"));
      expect(find.text("90%"), findsOneWidget);
      expect(find.text("0.90"), findsNothing);
    });

    testWidgets("scales a wide value down instead of cutting it", (WidgetTester tester) async {
      await _pump(
        tester,
        _matrix(
          columns: const <ValueMatrixColumn>[ValueMatrixColumn(id: "x", label: "Col X")],
          loadColumn: _Source(const <String, Map<String, double>>{
            "x": <String, double>{"a": 12345678.25},
          }).call,
        ),
      );
      final Finder value = find.text("12345678.25");
      expect(value, findsOneWidget);
      expect(tester.renderObject<RenderParagraph>(value).didExceedMaxLines, isFalse);
      expect(tester.getRect(value).width, lessThanOrEqualTo(90));
      expect(tester.takeException(), isNull);
    });

    testWidgets("follows rows order, hides empty rows and ignores unlisted ids", (WidgetTester tester) async {
      await _pump(tester, _matrix());

      expect(_order(tester, <String>["Gamma", "Alpha", "Beta"]), <String>["Alpha", "Beta", "Gamma"]);
      expect(find.text("Delta"), findsNothing);
      expect(find.text("0.70"), findsNothing);
    });

    testWidgets("shows a missing value as an announced dash", (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _pump(tester, _matrix());

      expect(find.text("—"), findsOneWidget);
      expect(find.bySemanticsLabel(_noValueKey), findsOneWidget);
      semantics.dispose();
    });
  });

  group("concurrency", () {
    testWidgets("loads each column once, at most maxConcurrent at a time", (WidgetTester tester) async {
      final _PendingSource source = _PendingSource();
      final List<ValueMatrixColumn> columns = List<ValueMatrixColumn>.generate(
        5,
        (int i) => ValueMatrixColumn(id: "c$i", label: "C$i"),
      );
      await pumpApp(tester, _matrix(columns: columns, loadColumn: source.call, maxConcurrent: 2), surfaceSize: _surface);
      expect(source.calls, <String>["c0", "c1"]);

      source.complete("c0");
      await tester.pump();
      expect(source.calls, <String>["c0", "c1"]);

      source.complete("c1");
      await tester.pump();
      expect(source.calls, <String>["c0", "c1", "c2", "c3"]);

      source.complete("c3");
      source.complete("c2");
      await tester.pump();
      expect(source.calls, <String>["c0", "c1", "c2", "c3", "c4"]);

      source.complete("c4");
      await tester.pump();
      expect(source.maxInFlight, 2);
      expect(find.text("Alpha"), findsOneWidget);
    });

    testWidgets("defaults to two calls in flight", (WidgetTester tester) async {
      final _PendingSource source = _PendingSource();
      final List<ValueMatrixColumn> columns = List<ValueMatrixColumn>.generate(
        3,
        (int i) => ValueMatrixColumn(id: "c$i", label: "C$i"),
      );
      await pumpApp(tester, _matrix(columns: columns, loadColumn: source.call), surfaceSize: _surface);
      expect(source.calls, <String>["c0", "c1"]);
    });
  });

  group("sorting", () {
    const List<String> labels = <String>["Alpha", "Beta", "Gamma"];

    testWidgets("first tap sorts descending, second tap ascending", (WidgetTester tester) async {
      await _pump(tester, _matrix());
      expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);

      await tester.tap(find.text("Col X"));
      await tester.pump();
      expect(_order(tester, labels), <String>["Beta", "Alpha", "Gamma"]);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);

      await tester.tap(find.text("Col X"));
      await tester.pump();
      expect(_order(tester, labels), <String>["Alpha", "Gamma", "Beta"]);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
    });

    testWidgets("another column restarts descending with missing values last", (WidgetTester tester) async {
      await _pump(tester, _matrix());

      await tester.tap(find.text("Col X"));
      await tester.pump();
      await tester.tap(find.text("Col X"));
      await tester.pump();
      await tester.tap(find.text("Col Y"));
      await tester.pump();
      expect(_order(tester, labels), <String>["Beta", "Alpha", "Gamma"]);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);

      await tester.tap(find.text("Col Y"));
      await tester.pump();
      expect(_order(tester, labels), <String>["Alpha", "Beta", "Gamma"]);
    });
  });

  group("error and empty", () {
    testWidgets("shows the error in a live region and reloads on retry", (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      int attempts = 0;
      Future<Map<String, double>> load(String columnId) async {
        attempts++;
        if (attempts == 1) throw StateError("boom");
        return _data[columnId] ?? const <String, double>{};
      }

      await _pump(tester, _matrix(loadColumn: load));
      expect(find.text(_loadErrorKey), findsOneWidget);
      expect(tester.getSemantics(find.text(_loadErrorKey)), isSemantics(isLiveRegion: true));
      expect(find.text(_retryKey), findsOneWidget);
      expect(tester.getSize(find.byType(TextButton)).height, greaterThanOrEqualTo(kMinTapTarget));

      await tester.tap(find.text(_retryKey));
      await tester.pump();
      expect(find.text(_loadErrorKey), findsNothing);
      expect(find.text("Alpha"), findsOneWidget);
      semantics.dispose();
    });

    testWidgets("shows the empty message when no listed row has a value", (WidgetTester tester) async {
      await _pump(
        tester,
        _matrix(
          loadColumn: _Source(const <String, Map<String, double>>{
            "x": <String, double>{"z": 1},
          }).call,
          onExport: (String csv) async {},
        ),
      );
      expect(find.text(_emptyKey), findsOneWidget);
      expect(find.text("Col X"), findsNothing);
      expect(find.text(_exportKey), findsNothing);
    });

    testWidgets("shows the empty message without columns", (WidgetTester tester) async {
      await _pump(tester, _matrix(columns: const <ValueMatrixColumn>[]));
      expect(find.text(_emptyKey), findsOneWidget);
    });
  });

  group("export", () {
    testWidgets("hides the export bar without onExport", (WidgetTester tester) async {
      await _pump(tester, _matrix());
      expect(find.text(_exportKey), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets("hands over the CSV in the current sort order", (WidgetTester tester) async {
      final List<String> exported = <String>[];
      await _pump(
        tester,
        _matrix(
          columns: const <ValueMatrixColumn>[
            ValueMatrixColumn(id: "x", label: "A;B", caption: "+1"),
            ValueMatrixColumn(id: "y", label: "Say \"hi\""),
          ],
          onExport: (String csv) async => exported.add(csv),
        ),
      );
      expect(tester.getSize(find.byType(OutlinedButton)).height, greaterThanOrEqualTo(kMinTapTarget));

      await tester.tap(find.text("A;B"));
      await tester.pump();
      await tester.tap(find.text(_exportKey));
      await tester.pump();

      expect(exported, <String>[
        "Name;\"A;B +1\";\"Say \"\"hi\"\"\"\nBeta;0.90;0.40\nAlpha;0.50;0.20\nGamma;0.50;\n",
      ]);
    });

    testWidgets("formats the CSV values with formatValue", (WidgetTester tester) async {
      final List<String> exported = <String>[];
      await _pump(
        tester,
        _matrix(
          formatValue: (double value) => "${(value * 100).round()}%",
          onExport: (String csv) async => exported.add(csv),
        ),
      );

      await tester.tap(find.text(_exportKey));
      await tester.pump();

      expect(exported, <String>["Name;Col X +1;Col Y\nAlpha;50%;20%\nBeta;90%;40%\nGamma;50%;\n"]);
      expect(exported.single, isNot(contains("0.90")));
    });
  });

  group("tones", () {
    testWidgets("tints cells with the tone container and onContainer", (WidgetTester tester) async {
      await _pump(
        tester,
        _matrix(toneOf: (double value) => value >= 0.8 ? StatusTone.success : StatusTone.warning),
      );
      final BuildContext context = tester.element(find.byType(ValueMatrix));
      final ToneColors success = StatusTones.colorsOf(context, StatusTone.success);
      final ToneColors warning = StatusTones.colorsOf(context, StatusTone.warning);

      expect(_cellDecoration(tester, "0.90").color, success.container);
      expect(tester.widget<Text>(find.text("0.90")).style?.color, success.onContainer);
      expect(_cellDecoration(tester, "0.20").color, warning.container);
      expect(tester.widget<Text>(find.text("0.20")).style?.color, warning.onContainer);
      expect(_cellDecoration(tester, "—").color, isNull);
    });

    testWidgets("leaves cells untinted without toneOf", (WidgetTester tester) async {
      await _pump(tester, _matrix());
      final ColorScheme cs = Theme.of(tester.element(find.byType(ValueMatrix))).colorScheme;

      expect(_cellDecoration(tester, "0.90").color, isNull);
      expect(tester.widget<Text>(find.text("0.90")).style?.color, cs.onSurface);
    });

    testWidgets("renders under the dark theme", (WidgetTester tester) async {
      await _pump(
        tester,
        _matrix(
          toneOf: (double value) => value >= 0.8 ? StatusTone.success : StatusTone.danger,
          onExport: (String csv) async {},
        ),
        theme: AppTheme.dark(),
      );
      final BuildContext context = tester.element(find.byType(ValueMatrix));
      final ColorScheme cs = Theme.of(context).colorScheme;

      expect(tester.takeException(), isNull);
      expect(cs.brightness, Brightness.dark);
      expect(_cellDecoration(tester, "0.90").color, StatusTones.colorsOf(context, StatusTone.success).container);
      final Finder headerMaterial = find.ancestor(of: _header("Col X"), matching: find.byType(Material)).first;
      expect(tester.widget<Material>(headerMaterial).color, cs.primary);
      expect(find.text(_exportKey), findsOneWidget);
    });
  });

  group("reload", () {
    testWidgets("reloads when ids change, not for an equal new list", (WidgetTester tester) async {
      final _Source source = _Source();
      await _pump(tester, _matrix(loadColumn: source.call));
      expect(source.calls, <String>["x", "y"]);

      await _pump(tester, _matrix(rows: List<ValueMatrixRow>.of(_rows), loadColumn: source.call));
      expect(source.calls, <String>["x", "y"]);

      await _pump(tester, _matrix(rows: _rows.sublist(0, 2), loadColumn: source.call));
      expect(source.calls, <String>["x", "y", "x", "y"]);
      expect(find.text("Gamma"), findsNothing);

      await _pump(
        tester,
        _matrix(
          rows: _rows.sublist(0, 2),
          columns: const <ValueMatrixColumn>[ValueMatrixColumn(id: "y", label: "Col Y")],
          loadColumn: source.call,
        ),
      );
      expect(source.calls, <String>["x", "y", "x", "y", "y"]);
      expect(find.text("Col X"), findsNothing);
    });

    testWidgets("drops the results of a superseded load", (WidgetTester tester) async {
      final _PendingSource first = _PendingSource();
      await pumpApp(tester, _matrix(loadColumn: first.call), surfaceSize: _surface);
      expect(first.calls, <String>["x", "y"]);

      await _pump(tester, _matrix(rows: _rows.sublist(0, 2), loadColumn: _Source().call));
      expect(find.text("0.90"), findsOneWidget);

      first.complete("x", const <String, double>{"a": 0.11});
      first.complete("y", const <String, double>{"a": 0.22});
      await tester.pump();
      expect(find.text("0.11"), findsNothing);
      expect(find.text("0.90"), findsOneWidget);
    });

    testWidgets("shows the Loader again while reloading", (WidgetTester tester) async {
      await _pump(tester, _matrix());
      expect(find.text("0.90"), findsOneWidget);

      final _PendingSource next = _PendingSource();
      await pumpApp(tester, _matrix(rows: _rows.sublist(0, 2), loadColumn: next.call), surfaceSize: _surface);
      expect(find.byType(Loader), findsOneWidget);
      expect(find.text("0.90"), findsNothing);

      next.complete("x", const <String, double>{"b": 0.33});
      next.complete("y");
      await tester.pump();
      expect(find.byType(Loader), findsNothing);
      expect(find.text("0.33"), findsOneWidget);
    });

    testWidgets("ignores the error of a superseded load", (WidgetTester tester) async {
      final _PendingSource first = _PendingSource();
      await pumpApp(tester, _matrix(loadColumn: first.call), surfaceSize: _surface);

      await _pump(tester, _matrix(rows: _rows.sublist(0, 2), loadColumn: _Source().call));
      expect(find.text("0.90"), findsOneWidget);

      first.fail("x");
      first.complete("y");
      await tester.pump();
      expect(find.text(_loadErrorKey), findsNothing);
      expect(find.text("0.90"), findsOneWidget);
    });

    testWidgets("stops the remaining chunks of a superseded load", (WidgetTester tester) async {
      final _PendingSource first = _PendingSource();
      final List<ValueMatrixColumn> columns = List<ValueMatrixColumn>.generate(
        4,
        (int i) => ValueMatrixColumn(id: "c$i", label: "C$i"),
      );
      await pumpApp(tester, _matrix(columns: columns, loadColumn: first.call, maxConcurrent: 2), surfaceSize: _surface);
      expect(first.calls, <String>["c0", "c1"]);

      await _pump(
        tester,
        _matrix(rows: _rows.sublist(0, 2), columns: columns, loadColumn: _Source().call, maxConcurrent: 2),
      );
      first.complete("c0");
      first.complete("c1");
      await tester.pump();
      expect(first.calls, <String>["c0", "c1"]);
    });

    testWidgets("drops a load that resolves after dispose", (WidgetTester tester) async {
      final _PendingSource source = _PendingSource();
      await pumpApp(tester, _matrix(loadColumn: source.call), surfaceSize: _surface);

      await pumpApp(tester, const SizedBox(), surfaceSize: _surface);
      source.complete("x");
      source.complete("y");
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets("drops a load that fails after dispose", (WidgetTester tester) async {
      final _PendingSource source = _PendingSource();
      await pumpApp(tester, _matrix(loadColumn: source.call), surfaceSize: _surface);

      await pumpApp(tester, const SizedBox(), surfaceSize: _surface);
      source.fail("x");
      source.complete("y");
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group("accessibility", () {
    testWidgets("headers are 48 dp buttons with sort hint and direction", (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _pump(tester, _matrix());

      final Size size = tester.getSize(_header("Col X"));
      expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
      expect(
        tester.getSemantics(find.bySemanticsLabel("Col X +1")),
        isSemantics(label: "Col X +1", hint: _sortHintKey, isButton: true, hasTapAction: true),
      );

      await tester.tap(find.text("Col X"));
      await tester.pump();
      expect(tester.getSemantics(find.bySemanticsLabel("Col X +1")), isSemantics(value: _descendingKey));

      await tester.tap(find.text("Col X"));
      await tester.pump();
      expect(tester.getSemantics(find.bySemanticsLabel("Col X +1")), isSemantics(value: _ascendingKey));
      semantics.dispose();
    });
  });
}

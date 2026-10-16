// clustered_value_axis_test.dart
//
// Widget tests for ClusteredValueAxis: the empty state, one bubble per
// far-apart point (default and custom formatter, best star on and off),
// selection taps and styling (points and the reference), cluster pills and
// their popover (order, rank, caption, row tap, outside tap, toggle, one at
// a time, inert rows), the reference pill and its popover, the header, the
// band track, the popover reset on didUpdateWidget (points, reference) and
// on a regrouping resize, hit boxes that never reach into a close
// neighbour, semantics (pill selection included), 48 dp hit boxes and a
// dark-theme smoke test.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/ClusteredValueAxis/index.dart";
import "package:flutter_skeleton/widgets/custom/_base/value_band.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const Size _surface = Size(800, 600);
const String _clusterKey = "custom.clustered_value_axis.cluster";
const String _countKey = "custom.clustered_value_axis.count";
const String _bestKey = "custom.clustered_value_axis.best";
const String _referenceKey = "custom.clustered_value_axis.reference";
const String _referenceGroupKey = "custom.clustered_value_axis.reference_group";
const String _openGroupKey = "custom.clustered_value_axis.open_group";

/// Where a tap lands outside the axis and the popover.
const Offset _outside = Offset(400, 560);

ValueAxisPoint<int> _pt(int id, double value, String label, {String? caption}) {
  return ValueAxisPoint<int>(id: id, value: value, label: label, caption: caption);
}

/// Three far-apart points.
final List<ValueAxisPoint<int>> _far = <ValueAxisPoint<int>>[
  _pt(1, 0.20, "A", caption: "cap A"),
  _pt(2, 0.50, "B"),
  _pt(3, 0.85, "C"),
];

/// One far point and three points that merge into a cluster.
final List<ValueAxisPoint<int>> _clustered = <ValueAxisPoint<int>>[
  _pt(1, 0.30, "X"),
  _pt(2, 0.70, "A", caption: "cap A"),
  _pt(3, 0.71, "B", caption: "cap B"),
  _pt(4, 0.72, "C", caption: "cap C"),
];

/// Two clusters at opposite ends.
final List<ValueAxisPoint<int>> _twoClusters = <ValueAxisPoint<int>>[
  _pt(1, 0.30, "L1"),
  _pt(2, 0.31, "L2"),
  _pt(3, 0.32, "L3"),
  _pt(4, 0.70, "H1"),
  _pt(5, 0.71, "H2"),
  _pt(6, 0.72, "H3"),
];

/// Two clusterable points, a third close to them and one far away: at
/// 800 dp {A, B} and D render apart; at 430 dp all three merge.
final List<ValueAxisPoint<int>> _regrouped = <ValueAxisPoint<int>>[
  _pt(1, 0.30, "X"),
  _pt(2, 0.70, "A"),
  _pt(3, 0.71, "B"),
  _pt(4, 0.78, "D"),
];

/// Ends at 0 and 1 (a 768 dp axis spanning 0–1) and two bubbles 36.9 dp
/// apart, just too far to merge.
final List<ValueAxisPoint<int>> _close = <ValueAxisPoint<int>>[
  _pt(1, 0.0, "Min"),
  _pt(2, 0.50, "A"),
  _pt(3, 0.548, "B"),
  _pt(4, 1.0, "Max"),
];

/// Pumps [axis] on an 800 x 600 surface.
Future<void> _pump(WidgetTester tester, ClusteredValueAxis<int> axis, {ThemeData? theme}) {
  return pumpApp(tester, axis, surfaceSize: _surface, theme: theme);
}

/// The decoration of the bubble or marker showing [text].
BoxDecoration _decorationOf(WidgetTester tester, String text) {
  final Finder box = find.ancestor(of: find.text(text), matching: find.byType(Container)).first;
  return tester.widget<Container>(box).decoration! as BoxDecoration;
}

/// The hit box (InkWell) around [finder].
Finder _hitBox(Finder finder) => find.ancestor(of: finder, matching: find.byType(InkWell)).first;

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(ClusteredValueAxis<int>))).colorScheme;
}

void main() {
  group("rendering", () {
    testWidgets("renders nothing for no points", (WidgetTester tester) async {
      await _pump(tester, const ClusteredValueAxis<int>(points: <ValueAxisPoint<int>>[], reference: 0.5, title: "T"));
      expect(find.byType(OverlayPortal), findsNothing);
      expect(find.text("T"), findsNothing);
      expect(tester.getSize(find.byType(ClusteredValueAxis<int>)), Size.zero);
    });

    testWidgets("draws one bubble per far-apart point with the default format", (WidgetTester tester) async {
      await _pump(tester, ClusteredValueAxis<int>(points: _far));
      expect(find.text("20"), findsOneWidget);
      expect(find.text("50"), findsOneWidget);
      expect(find.text("85"), findsOneWidget);
      expect(find.text(_clusterKey), findsNothing);
    });

    testWidgets("orders bubbles left to right by value", (WidgetTester tester) async {
      await _pump(tester, ClusteredValueAxis<int>(points: _far));
      final double a = tester.getCenter(find.text("20")).dx;
      final double b = tester.getCenter(find.text("50")).dx;
      final double c = tester.getCenter(find.text("85")).dx;
      expect(a, lessThan(b));
      expect(b, lessThan(c));
    });

    testWidgets("honours a custom formatter", (WidgetTester tester) async {
      await _pump(
        tester,
        ClusteredValueAxis<int>(points: _far, formatValue: (double value) => "v${(value * 10).round()}"),
      );
      expect(find.text("v2"), findsOneWidget);
      expect(find.text("v5"), findsOneWidget);
      expect(find.text("v9"), findsOneWidget);
    });

    testWidgets("stars the best point only", (WidgetTester tester) async {
      await _pump(tester, ClusteredValueAxis<int>(points: _far));
      final Finder star = find.byIcon(Icons.star_rounded);
      expect(star, findsOneWidget);
      final Finder bestBubble = find.ancestor(of: find.text("85"), matching: find.byType(Stack)).first;
      expect(find.descendant(of: bestBubble, matching: star), findsOneWidget);
      final ColorScheme cs = _scheme(tester);
      expect((_decorationOf(tester, "85").border! as Border).top.color, cs.tertiary);
      expect((_decorationOf(tester, "50").border! as Border).top.color, cs.primary);
    });

    testWidgets("draws no star when highlightBest is false", (WidgetTester tester) async {
      await _pump(
        tester,
        ClusteredValueAxis<int>(points: _far, highlightBest: false, title: "T", icon: Icons.timeline),
      );
      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.text(_bestKey), findsNothing);
    });

    testWidgets("draws no marker without a reference", (WidgetTester tester) async {
      await _pump(tester, ClusteredValueAxis<int>(points: _far));
      expect(find.byIcon(Icons.person_pin_circle_rounded), findsNothing);
    });

    testWidgets("draws the reference marker with its value", (WidgetTester tester) async {
      await _pump(tester, ClusteredValueAxis<int>(points: _far, reference: 0.10));
      expect(find.text("10"), findsOneWidget);
      expect(find.byIcon(Icons.person_pin_circle_rounded), findsOneWidget);
      expect(tester.getCenter(find.text("10")).dx, lessThan(tester.getCenter(find.text("20")).dx));
    });
  });

  group("header", () {
    testWidgets("is hidden without a title", (WidgetTester tester) async {
      await _pump(tester, ClusteredValueAxis<int>(points: _far));
      expect(find.text(_countKey), findsNothing);
      expect(find.text(_bestKey), findsNothing);
    });

    testWidgets("shows the title, icon, count and best value", (WidgetTester tester) async {
      await _pump(tester, ClusteredValueAxis<int>(points: _far, title: "Title", icon: Icons.timeline));
      expect(find.text("Title"), findsOneWidget);
      expect(find.byIcon(Icons.timeline), findsOneWidget);
      expect(find.text(_countKey), findsOneWidget);
      expect(find.text(_bestKey), findsOneWidget);
      // Header star + best bubble star.
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
      expect(tester.getCenter(find.text("Title")).dy, lessThan(tester.getCenter(find.text("50")).dy));
    });
  });

  group("bands", () {
    testWidgets("draws a plain track without bands", (WidgetTester tester) async {
      await _pump(tester, ClusteredValueAxis<int>(points: _far));
      final ColorScheme cs = _scheme(tester);
      expect(
        find.byWidgetPredicate((Widget w) => w is ColoredBox && w.color == cs.surfaceContainerHighest),
        findsOneWidget,
      );
    });

    testWidgets("paints visible bands with their resolved colour and label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      const List<ValueBand> bands = <ValueBand>[
        ValueBand(from: 0.0, to: 0.5, tone: StatusTone.danger, label: "Low"),
        ValueBand(from: 0.5, to: 1.0, tone: StatusTone.success),
      ];
      await _pump(tester, ClusteredValueAxis<int>(points: _far, bands: bands));
      final BuildContext context = tester.element(find.byType(ClusteredValueAxis<int>));
      final Color low = StatusTones.colorsOf(context, StatusTone.danger).container;
      final Color high = StatusTones.colorsOf(context, StatusTone.success).container;
      final Finder lowBox = find.byWidgetPredicate((Widget w) => w is ColoredBox && w.color == low);
      final Finder highBox = find.byWidgetPredicate((Widget w) => w is ColoredBox && w.color == high);
      expect(lowBox, findsOneWidget);
      expect(highBox, findsOneWidget);
      expect(tester.getTopRight(lowBox).dx, closeTo(tester.getTopLeft(highBox).dx, 0.01));
      expect(find.bySemanticsLabel("Low"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("skips bands outside the visible range", (WidgetTester tester) async {
      await _pump(
        tester,
        ClusteredValueAxis<int>(
          points: <ValueAxisPoint<int>>[_pt(1, 0.80, "A"), _pt(2, 0.90, "B")],
          bands: const <ValueBand>[ValueBand(from: 0.0, to: 0.3, tone: StatusTone.danger)],
        ),
      );
      final Color low = StatusTones.colorsOf(
        tester.element(find.byType(ClusteredValueAxis<int>)),
        StatusTone.danger,
      ).container;
      expect(find.byWidgetPredicate((Widget w) => w is ColoredBox && w.color == low), findsNothing);
    });
  });

  group("selection", () {
    testWidgets("tapping a bubble reports its id", (WidgetTester tester) async {
      final List<int?> selected = <int?>[];
      await _pump(tester, ClusteredValueAxis<int>(points: _far, onSelect: selected.add));
      await tester.tap(find.text("50"));
      expect(selected, <int?>[2]);
    });

    testWidgets("tapping the reference marker reports null", (WidgetTester tester) async {
      final List<int?> selected = <int?>[];
      await _pump(
        tester,
        ClusteredValueAxis<int>(points: _far, reference: 0.10, selectedId: 2, onSelect: selected.add),
      );
      await tester.tap(find.text("10"));
      expect(selected, <int?>[null]);
    });

    testWidgets("fills the selected bubble", (WidgetTester tester) async {
      await _pump(tester, ClusteredValueAxis<int>(points: _far, selectedId: 2, onSelect: (int? id) {}));
      final ColorScheme cs = _scheme(tester);
      expect(_decorationOf(tester, "50").color, cs.primary);
      expect(_decorationOf(tester, "20").color, cs.surface);
      expect(_decorationOf(tester, "85").color, cs.primary);
    });

    testWidgets("turns the selected best bubble tertiary", (WidgetTester tester) async {
      await _pump(tester, ClusteredValueAxis<int>(points: _far, selectedId: 3, onSelect: (int? id) {}));
      expect(_decorationOf(tester, "85").color, _scheme(tester).tertiary);
    });

    testWidgets("rings the reference only while it is selected", (WidgetTester tester) async {
      await _pump(tester, ClusteredValueAxis<int>(points: _far, reference: 0.10));
      expect(_decorationOf(tester, "10").boxShadow, hasLength(2));
      await _pump(tester, ClusteredValueAxis<int>(points: _far, reference: 0.10, selectedId: 1));
      expect(_decorationOf(tester, "10").boxShadow, hasLength(1));
    });

    testWidgets("bubbles and the marker are inert without onSelect", (WidgetTester tester) async {
      await _pump(tester, ClusteredValueAxis<int>(points: _far, reference: 0.10));
      expect(tester.widget<InkWell>(_hitBox(find.text("50"))).onTap, isNull);
      expect(tester.widget<InkWell>(_hitBox(find.text("10"))).onTap, isNull);
    });
  });

  group("cluster popover", () {
    testWidgets("merges close points into one pill", (WidgetTester tester) async {
      await _pump(tester, ClusteredValueAxis<int>(points: _clustered));
      expect(find.text(_clusterKey), findsOneWidget);
      expect(find.text("30"), findsOneWidget);
      expect(find.text("70"), findsNothing);
      // The pill holds the best value: one star on it.
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets("lists the members highest first with rank, caption and value", (WidgetTester tester) async {
      await _pump(tester, ClusteredValueAxis<int>(points: _clustered));
      await tester.tap(find.text(_clusterKey));
      await tester.pumpAndSettle();

      for (final String text in <String>["A", "B", "C", "cap A", "cap B", "cap C", "70", "71", "72", "1", "2", "3"]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.text("X"), findsNothing);
      final double c = tester.getTopLeft(find.text("C")).dy;
      final double b = tester.getTopLeft(find.text("B")).dy;
      final double a = tester.getTopLeft(find.text("A")).dy;
      expect(c, lessThan(b));
      expect(b, lessThan(a));
      expect(tester.getTopLeft(find.text("C")).dy, greaterThan(tester.getBottomLeft(find.text(_clusterKey)).dy));
      expect(
        tester.getSize(find.ancestor(of: find.text("C"), matching: find.byType(SingleChildScrollView))).width,
        260,
      );
    });

    testWidgets("tapping a row selects it and closes the popover", (WidgetTester tester) async {
      final List<int?> selected = <int?>[];
      await _pump(tester, ClusteredValueAxis<int>(points: _clustered, onSelect: selected.add));
      await tester.tap(find.text(_clusterKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text("B"));
      await tester.pumpAndSettle();
      expect(selected, <int?>[3]);
      expect(find.text("B"), findsNothing);
    });

    testWidgets("tapping outside closes the popover", (WidgetTester tester) async {
      final List<int?> selected = <int?>[];
      await _pump(tester, ClusteredValueAxis<int>(points: _clustered, onSelect: selected.add));
      await tester.tap(find.text(_clusterKey));
      await tester.pumpAndSettle();
      await tester.tapAt(_outside);
      await tester.pumpAndSettle();
      expect(find.text("C"), findsNothing);
      expect(selected, isEmpty);
    });

    testWidgets("tapping the pill again closes the popover", (WidgetTester tester) async {
      await _pump(tester, ClusteredValueAxis<int>(points: _clustered));
      await tester.tap(find.text(_clusterKey));
      await tester.pumpAndSettle();
      expect(find.text("C"), findsOneWidget);
      await tester.tap(find.text(_clusterKey));
      await tester.pumpAndSettle();
      expect(find.text("C"), findsNothing);
    });

    testWidgets("keeps one popover open at a time", (WidgetTester tester) async {
      await _pump(tester, ClusteredValueAxis<int>(points: _twoClusters));
      expect(find.text(_clusterKey), findsNWidgets(2));
      await tester.tap(find.text(_clusterKey).first);
      await tester.pumpAndSettle();
      expect(find.text("L1"), findsOneWidget);
      await tester.tap(find.text(_clusterKey).last);
      await tester.pumpAndSettle();
      expect(find.text("L1"), findsNothing);
      expect(find.text("H1"), findsOneWidget);
    });

    testWidgets("fills the pill while open or holding the selection", (WidgetTester tester) async {
      await _pump(tester, ClusteredValueAxis<int>(points: _clustered));
      final ColorScheme cs = _scheme(tester);
      expect(_decorationOf(tester, _clusterKey).color, cs.surface);
      await tester.tap(find.text(_clusterKey));
      await tester.pumpAndSettle();
      expect(_decorationOf(tester, _clusterKey).color, cs.primary);
      await tester.tap(find.text(_clusterKey));
      await tester.pumpAndSettle();
      expect(find.text("C"), findsNothing);
      expect(_decorationOf(tester, _clusterKey).color, cs.surface);
      // Closed, but holding the selection.
      await _pump(tester, ClusteredValueAxis<int>(points: _clustered, selectedId: 3, onSelect: (int? id) {}));
      expect(find.text("C"), findsNothing);
      expect(_decorationOf(tester, _clusterKey).color, cs.primary);
    });

    testWidgets("rows are inert without onSelect", (WidgetTester tester) async {
      await _pump(tester, ClusteredValueAxis<int>(points: _clustered));
      await tester.tap(find.text(_clusterKey));
      await tester.pumpAndSettle();
      expect(tester.widget<InkWell>(_hitBox(find.text("B"))).onTap, isNull);
    });

    testWidgets("closes when the points change", (WidgetTester tester) async {
      final ValueNotifier<List<ValueAxisPoint<int>>> points = ValueNotifier<List<ValueAxisPoint<int>>>(_clustered);
      addTearDown(points.dispose);
      await pumpApp(
        tester,
        ValueListenableBuilder<List<ValueAxisPoint<int>>>(
          valueListenable: points,
          builder: (BuildContext context, List<ValueAxisPoint<int>> value, Widget? child) {
            return ClusteredValueAxis<int>(points: value);
          },
        ),
        surfaceSize: _surface,
      );
      await tester.tap(find.text(_clusterKey));
      await tester.pumpAndSettle();

      // Equal content in a new list keeps it open.
      points.value = List<ValueAxisPoint<int>>.of(_clustered);
      await tester.pumpAndSettle();
      expect(find.text("C"), findsOneWidget);

      points.value = <ValueAxisPoint<int>>[..._clustered, _pt(9, 0.73, "D")];
      await tester.pumpAndSettle();
      expect(find.text("C"), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets("stays closed after the points empty while open", (WidgetTester tester) async {
      final ValueNotifier<List<ValueAxisPoint<int>>> points = ValueNotifier<List<ValueAxisPoint<int>>>(_clustered);
      addTearDown(points.dispose);
      await pumpApp(
        tester,
        ValueListenableBuilder<List<ValueAxisPoint<int>>>(
          valueListenable: points,
          builder: (BuildContext context, List<ValueAxisPoint<int>> value, Widget? child) {
            return ClusteredValueAxis<int>(points: value);
          },
        ),
        surfaceSize: _surface,
      );
      await tester.tap(find.text(_clusterKey));
      await tester.pumpAndSettle();

      points.value = const <ValueAxisPoint<int>>[];
      await tester.pumpAndSettle();
      expect(find.byType(OverlayPortal), findsNothing);

      points.value = _clustered;
      await tester.pumpAndSettle();
      expect(find.text(_clusterKey), findsOneWidget);
      expect(find.text("C"), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets("closes when the reference changes", (WidgetTester tester) async {
      final ValueNotifier<double> reference = ValueNotifier<double>(0.10);
      addTearDown(reference.dispose);
      await pumpApp(
        tester,
        ValueListenableBuilder<double>(
          valueListenable: reference,
          builder: (BuildContext context, double value, Widget? child) {
            return ClusteredValueAxis<int>(points: _clustered, reference: value);
          },
        ),
        surfaceSize: _surface,
      );
      await tester.tap(find.text(_clusterKey));
      await tester.pumpAndSettle();
      expect(find.text("C"), findsOneWidget);

      reference.value = 0.12;
      await tester.pumpAndSettle();
      expect(find.text("C"), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets("closes when a resize regroups the open pill", (WidgetTester tester) async {
      final ValueNotifier<double> width = ValueNotifier<double>(_surface.width);
      addTearDown(width.dispose);
      await pumpApp(
        tester,
        ValueListenableBuilder<double>(
          valueListenable: width,
          builder: (BuildContext context, double value, Widget? child) {
            return Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: value,
                child: ClusteredValueAxis<int>(points: _regrouped),
              ),
            );
          },
        ),
        surfaceSize: _surface,
      );
      // Wide: {A, B} pill + D bubble.
      expect(find.text("78"), findsOneWidget);
      await tester.tap(find.text(_clusterKey));
      await tester.pumpAndSettle();
      expect(find.text("B"), findsOneWidget);

      // Narrow: D joins the pill, which is a different group.
      width.value = 430;
      await tester.pumpAndSettle();
      expect(find.text("78"), findsNothing);
      expect(find.text("B"), findsNothing);
      expect(find.text("A"), findsNothing);

      // Wide again: the popover does not come back on its own.
      width.value = _surface.width;
      await tester.pumpAndSettle();
      expect(find.text("78"), findsOneWidget);
      expect(find.text("B"), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group("hit boxes", () {
    testWidgets("a tap inside a bubble never selects its close neighbour", (WidgetTester tester) async {
      final List<int?> selected = <int?>[];
      await _pump(tester, ClusteredValueAxis<int>(points: _close, onSelect: selected.add));
      final Offset a = tester.getCenter(find.text("50"));
      final Offset b = tester.getCenter(find.text("55"));
      expect(b.dx - a.dx, closeTo(36.9, 0.1));
      // 14 dp from the centre is inside the 30 dp circle.
      await tester.tapAt(a + const Offset(14, 0));
      await tester.tapAt(b - const Offset(14, 0));
      expect(selected, <int?>[2, 3]);
      // Each still gets a full-size box, pushed away from the other.
      expect(tester.getSize(_hitBox(find.text("50"))), const Size.square(kMinTapTarget));
      expect(tester.getSize(_hitBox(find.text("55"))), const Size.square(kMinTapTarget));
      expect(
        tester.getRect(_hitBox(find.text("50"))).right,
        lessThanOrEqualTo(tester.getRect(_hitBox(find.text("55"))).left),
      );
    });

    testWidgets("a tap inside a bubble never selects a close reference", (WidgetTester tester) async {
      final List<int?> selected = <int?>[];
      // The marker sits 37.5 dp right of the 0.50 bubble: not fused.
      await _pump(
        tester,
        ClusteredValueAxis<int>(
          points: <ValueAxisPoint<int>>[_close[0], _close[1], _close[3]],
          reference: 0.5 + 37.5 / 768,
          selectedId: 1,
          onSelect: selected.add,
        ),
      );
      expect(find.text(_referenceGroupKey), findsNothing);
      final Offset bubble = tester.getCenter(find.text("50"));
      final Offset marker = tester.getCenter(find.text("55"));
      expect(marker.dx - bubble.dx, closeTo(37.5, 0.01));
      await tester.tapAt(bubble + const Offset(14, 0));
      await tester.tapAt(marker - const Offset(15, 0));
      expect(selected, <int?>[2, null]);
    });

    testWidgets("narrows a box squeezed between two close neighbours", (WidgetTester tester) async {
      final List<int?> selected = <int?>[];
      await _pump(
        tester,
        ClusteredValueAxis<int>(points: <ValueAxisPoint<int>>[..._close, _pt(5, 0.596, "E")], onSelect: selected.add),
      );
      final Rect a = tester.getRect(_hitBox(find.text("50")));
      final Rect b = tester.getRect(_hitBox(find.text("55")));
      final Rect e = tester.getRect(_hitBox(find.text("60")));
      expect(a.right, lessThanOrEqualTo(b.left));
      expect(b.right, lessThanOrEqualTo(e.left));
      expect(b.width, lessThan(kMinTapTarget));
      expect(b.width, greaterThan(ValueAxisLayout.bubbleSize));
      expect(b.height, kMinTapTarget);
      await tester.tapAt(tester.getCenter(find.text("55")) + const Offset(14, 0));
      await tester.tapAt(tester.getCenter(find.text("55")) - const Offset(14, 0));
      expect(selected, <int?>[3, 3]);
    });
  });

  group("reference pill", () {
    testWidgets("fuses the reference with an overlapping cluster", (WidgetTester tester) async {
      await _pump(tester, ClusteredValueAxis<int>(points: _clustered, reference: 0.69));
      expect(find.text(_referenceGroupKey), findsOneWidget);
      expect(find.text(_clusterKey), findsNothing);
      expect(find.text("69"), findsNothing);
      // Only the pill's icon: no standalone marker.
      expect(find.byIcon(Icons.person_pin_circle_rounded), findsOneWidget);
    });

    testWidgets("lists the reference row first, then the members", (WidgetTester tester) async {
      final List<int?> selected = <int?>[];
      await _pump(
        tester,
        ClusteredValueAxis<int>(points: _clustered, reference: 0.69, selectedId: 2, onSelect: selected.add),
      );
      await tester.tap(find.text(_referenceGroupKey));
      await tester.pumpAndSettle();

      expect(find.text(_referenceKey), findsOneWidget);
      expect(find.text("69"), findsOneWidget);
      expect(tester.getTopLeft(find.text(_referenceKey)).dy, lessThan(tester.getTopLeft(find.text("C")).dy));
      expect(find.byType(Divider), findsOneWidget);

      await tester.tap(find.text(_referenceKey));
      await tester.pumpAndSettle();
      expect(selected, <int?>[null]);
      expect(find.text(_referenceKey), findsNothing);
    });

    testWidgets("uses a custom reference label", (WidgetTester tester) async {
      await _pump(tester, ClusteredValueAxis<int>(points: _clustered, reference: 0.69, referenceLabel: "Mine"));
      await tester.tap(find.text(_referenceGroupKey));
      await tester.pumpAndSettle();
      expect(find.text("Mine"), findsOneWidget);
      expect(find.text(_referenceKey), findsNothing);
    });
  });

  group("accessibility", () {
    testWidgets("labels bubbles, the marker and pills", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, ClusteredValueAxis<int>(points: _clustered, reference: 0.10, onSelect: (int? id) {}));
      expect(
        tester.getSemantics(find.bySemanticsLabel("X, 30")),
        isSemantics(label: "X, 30", isButton: true, hasTapAction: true, isSelected: false),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel("$_referenceKey, 10")),
        isSemantics(isButton: true, isSelected: true),
      );
      final Finder pill = find.bySemanticsLabel("$_clusterKey, $_bestKey");
      expect(
        tester.getSemantics(pill),
        isSemantics(isButton: true, hasExpandedState: true, isExpanded: false, hint: _openGroupKey),
      );

      await tester.tap(find.text(_clusterKey));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(pill), isSemantics(isExpanded: true));
      expect(find.bySemanticsLabel("C, cap C, 72"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("pills announce the selection they hold", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      const String referencePill = "$_referenceKey, $_referenceGroupKey, $_bestKey";
      const String clusterPill = "$_clusterKey, $_bestKey";
      Future<void> pumpWith({double? reference, int? selectedId}) {
        return _pump(
          tester,
          ClusteredValueAxis<int>(
            points: _clustered,
            reference: reference,
            selectedId: selectedId,
            onSelect: (int? id) {},
          ),
        );
      }

      // Fused reference, which is the active selection.
      await pumpWith(reference: 0.69);
      expect(tester.getSemantics(find.bySemanticsLabel(referencePill)), isSemantics(isSelected: true));
      // A member of the reference pill.
      await pumpWith(reference: 0.69, selectedId: 3);
      expect(tester.getSemantics(find.bySemanticsLabel(referencePill)), isSemantics(isSelected: true));
      // A point outside it.
      await pumpWith(reference: 0.69, selectedId: 1);
      expect(tester.getSemantics(find.bySemanticsLabel(referencePill)), isSemantics(isSelected: false));
      // A member of a cluster pill, then a point outside it.
      await pumpWith(selectedId: 3);
      expect(tester.getSemantics(find.bySemanticsLabel(clusterPill)), isSemantics(isSelected: true));
      await pumpWith(selectedId: 1);
      expect(tester.getSemantics(find.bySemanticsLabel(clusterPill)), isSemantics(isSelected: false));
      handle.dispose();
    });

    testWidgets("adds the best text to the best bubble's label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, ClusteredValueAxis<int>(points: _far));
      expect(find.bySemanticsLabel("A, cap A, 20"), findsOneWidget);
      expect(find.bySemanticsLabel("C, 85, $_bestKey"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("every hit box is at least 48 x 48", (WidgetTester tester) async {
      await _pump(tester, ClusteredValueAxis<int>(points: _clustered, reference: 0.10, onSelect: (int? id) {}));
      for (final String text in <String>["30", "10", _clusterKey]) {
        final Size size = tester.getSize(_hitBox(find.text(text)));
        expect(size.width, greaterThanOrEqualTo(kMinTapTarget), reason: text);
        expect(size.height, greaterThanOrEqualTo(kMinTapTarget), reason: text);
      }
      await tester.tap(find.text(_clusterKey));
      await tester.pumpAndSettle();
      expect(tester.getSize(_hitBox(find.text("B"))).height, greaterThanOrEqualTo(kMinTapTarget));
    });

    testWidgets("keeps edge hit boxes inside the axis", (WidgetTester tester) async {
      await _pump(
        tester,
        ClusteredValueAxis<int>(points: <ValueAxisPoint<int>>[_pt(1, 0.0, "Min"), _pt(2, 1.0, "Max")]),
      );
      // The axis spans the surface minus the 16 dp side padding.
      const double left = kDefaultPadding * 2;
      final double right = _surface.width - kDefaultPadding * 2;
      expect(tester.getRect(_hitBox(find.text("0"))).left, greaterThanOrEqualTo(left));
      expect(tester.getRect(_hitBox(find.text("100"))).right, lessThanOrEqualTo(right));
    });
  });

  testWidgets("renders under the dark theme", (WidgetTester tester) async {
    await _pump(
      tester,
      ClusteredValueAxis<int>(
        points: _clustered,
        reference: 0.69,
        selectedId: 1,
        onSelect: (int? id) {},
        title: "Title",
        icon: Icons.timeline,
        bands: const <ValueBand>[
          ValueBand(from: 0.0, to: 0.5, tone: StatusTone.warning),
          ValueBand(from: 0.5, to: 1.0, tone: StatusTone.success),
        ],
      ),
      theme: AppTheme.dark(),
    );
    await tester.tap(find.text(_referenceGroupKey));
    await tester.pumpAndSettle();
    expect(find.text("C"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

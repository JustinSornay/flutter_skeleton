// trend_chart_test.dart
//
// Widget tests for TrendChart: the empty and insufficient-data fallbacks and
// their overrides, the plain primary line without a threshold, the single
// bar and its hard-stop gradient (colour switch read from rendered pixels),
// the threshold line and crossing markers (both polarities, custom tones and
// labels), where the line labels go and that they are painted inside the
// plot, the bound asserts, the caption, the semantics label, the entry
// animation under reduced motion, the axis labels and steps, the Y range
// without clipping, rebuilds and a dark-theme smoke test.

import "dart:typed_data";
import "dart:ui" as ui;

import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/TrendChart/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

/// 15 January 2026 plus [days].
DateTime _day(int days) => DateTime(2026, 1, 15).add(Duration(days: days));

List<TrendPoint> _series(List<double> values) {
  return <TrendPoint>[for (int i = 0; i < values.length; i++) TrendPoint(date: _day(i), value: values[i])];
}

final List<TrendPoint> _rising = _series(<double>[0.63, 0.70, 0.74, 0.78, 0.82]);

final List<TrendPoint> _falling = _series(<double>[0.50, 0.46, 0.40, 0.36, 0.30]);

final List<TrendPoint> _crossing = _series(<double>[0.72, 0.68, 0.63, 0.59, 0.56]);

const TrendThreshold _threshold = TrendThreshold(value: 0.6);

LineChart _lineChart(WidgetTester tester) => tester.widget<LineChart>(find.byType(LineChart));

LineChartData _data(WidgetTester tester) => _lineChart(tester).data;

LineChartBarData _bar(WidgetTester tester) => _data(tester).lineBarsData.single;

/// Colour of each run of the single bar: its colour, or one per hard-stop
/// pair of its gradient.
List<Color> _runColors(WidgetTester tester) {
  final LineChartBarData bar = _bar(tester);
  final Gradient? gradient = bar.gradient;
  if (gradient == null) return <Color>[bar.color!];
  return <Color>[for (int i = 0; i < gradient.colors.length; i += 2) gradient.colors[i]];
}

/// Matches a list of doubles within 1e-9 of [expected], item by item.
Matcher _closeToAll(List<double> expected) {
  return pairwiseCompare<double, double>(expected, (double e, double a) => (a - e).abs() < 1e-9, "within 1e-9 of");
}

HorizontalLine _thresholdLine(WidgetTester tester) => _data(tester).extraLinesData.horizontalLines.single;

BuildContext _context(WidgetTester tester) => tester.element(find.byType(TrendChart));

Color _tone(WidgetTester tester, StatusTone tone) => StatusTones.colorsOf(_context(tester), tone).foreground;

Future<void> _pump(WidgetTester tester, TrendChart chart, {ThemeData? theme}) async {
  await pumpApp(tester, chart, theme: theme);
  await tester.pump(const Duration(seconds: 1));
}

const Key _boundary = Key("boundary");

/// Pumps [chart] 40 dp inside a 400 dp wide RepaintBoundary, so pixels the
/// chart paints outside its own bounds are captured too.
Future<void> _pumpBoundary(WidgetTester tester, TrendChart chart) async {
  await pumpApp(
    tester,
    Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 400,
        child: RepaintBoundary(
          key: _boundary,
          child: Padding(padding: const EdgeInsets.all(40), child: chart),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

/// Plot area of the chart (axis titles excluded), local to the boundary.
Rect _plot(WidgetTester tester) {
  final Rect chart = tester.getRect(find.byType(LineChart)).shift(-tester.getTopLeft(find.byKey(_boundary)));
  return Rect.fromLTRB(chart.left + 30, chart.top, chart.right, chart.bottom - 28);
}

/// Pixels painted exactly in [color] in the boundary image, split by whether
/// their centre is in [area] (boundary-local).
Future<({int inside, int outside})> _pixels(WidgetTester tester, Color color, Rect area) async {
  final RenderRepaintBoundary render = tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  final ({int inside, int outside})? counts = await tester.runAsync<({int inside, int outside})>(() async {
    final ui.Image image = await render.toImage();
    final ByteData data = (await image.toByteData())!;
    final int target = color.toARGB32();
    int inside = 0;
    int outside = 0;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final int i = (y * image.width + x) * 4;
        final int argb =
            data.getUint8(i + 3) << 24 | data.getUint8(i) << 16 | data.getUint8(i + 1) << 8 | data.getUint8(i + 2);
        if (argb != target) continue;
        if (area.contains(Offset(x + 0.5, y + 0.5))) {
          inside++;
        } else {
          outside++;
        }
      }
    }
    image.dispose();
    return (inside: inside, outside: outside);
  });
  return counts!;
}

void main() {
  group("fallbacks", () {
    testWidgets("no point shows the empty key and no chart", (WidgetTester tester) async {
      await _pump(tester, const TrendChart(points: <TrendPoint>[]));

      expect(find.text("custom.trend_chart.empty"), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets("the empty message can be overridden", (WidgetTester tester) async {
      await _pump(tester, const TrendChart(points: <TrendPoint>[], emptyMessage: "Nothing yet"));

      expect(find.text("Nothing yet"), findsOneWidget);
      expect(find.text("custom.trend_chart.empty"), findsNothing);
    });

    testWidgets("fewer than 3 points shows the insufficient-data key, in italic", (WidgetTester tester) async {
      await _pump(tester, TrendChart(points: _rising.sublist(0, 2)));

      expect(find.byType(LineChart), findsNothing);
      final Text text = tester.widget<Text>(find.text("custom.trend_chart.insufficient_data"));
      expect(text.style?.fontStyle, FontStyle.italic);
      expect(text.style?.color, Theme.of(_context(tester)).colorScheme.onSurfaceVariant);
      expect(text.textAlign, TextAlign.center);
    });

    testWidgets("the insufficient-data message can be overridden", (WidgetTester tester) async {
      await _pump(tester, TrendChart(points: _rising.sublist(0, 1), insufficientDataMessage: "Too few"));

      expect(find.text("Too few"), findsOneWidget);
    });

    testWidgets("minPoints: 2 draws two points", (WidgetTester tester) async {
      await _pump(tester, TrendChart(points: _rising.sublist(0, 2), minPoints: 2));

      expect(find.byType(LineChart), findsOneWidget);
    });

    test("minPoints below 2 and inverted bounds are rejected", () {
      expect(() => TrendChart(points: _rising, minPoints: 1), throwsAssertionError);
      expect(() => TrendChart(points: _rising, minY: 1, maxY: 0), throwsAssertionError);
    });

    testWidgets("a threshold outside explicit bounds is rejected", (WidgetTester tester) async {
      await pumpApp(tester, TrendChart(points: _rising, threshold: const TrendThreshold(value: 1.5), minY: 0, maxY: 1));
      expect(tester.takeException(), isAssertionError);

      await pumpApp(tester, TrendChart(points: _rising, threshold: const TrendThreshold(value: 0.5), minY: 0.6));
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets("a value outside explicit bounds is rejected", (WidgetTester tester) async {
      await pumpApp(tester, TrendChart(points: _rising, maxY: 0.8));
      expect(tester.takeException(), isAssertionError);
    });
  });

  group("line without a threshold", () {
    testWidgets("one primary bar holds every point, with no extra line", (WidgetTester tester) async {
      await _pump(tester, TrendChart(points: _crossing));

      final LineChartBarData bar = _bar(tester);
      expect(bar.spots.map((FlSpot s) => s.y).toList(), <double>[0.72, 0.68, 0.63, 0.59, 0.56]);
      expect(bar.color, Theme.of(_context(tester)).colorScheme.primary);
      expect(bar.gradient, isNull);
      expect(bar.barWidth, 2);
      expect(bar.isStrokeCapRound, isTrue);
      expect(_data(tester).extraLinesData.horizontalLines, isEmpty);
      expect(_data(tester).extraLinesData.verticalLines, isEmpty);
      expect(_data(tester).lineTouchData.enabled, isFalse);
      expect(_data(tester).minX, 0);
      expect(_data(tester).maxX, 4);
    });
  });

  group("threshold", () {
    testWidgets("all favourable: one success segment and a warning reference line", (WidgetTester tester) async {
      await _pump(tester, TrendChart(points: _rising, threshold: _threshold));

      expect(_bar(tester).color, _tone(tester, StatusTone.success));
      expect(_bar(tester).gradient, isNull);
      final HorizontalLine line = _thresholdLine(tester);
      expect(line.y, 0.6);
      expect(line.color, _tone(tester, StatusTone.warning));
      expect(line.dashArray, <int>[6, 4]);
      expect(line.label.show, isTrue);
      expect(line.label.labelResolver(line), "custom.trend_chart.threshold");
      expect(line.label.style?.color, _tone(tester, StatusTone.warning));
      expect(_data(tester).extraLinesData.verticalLines, isEmpty);
    });

    testWidgets("all adverse: one danger segment and no marker", (WidgetTester tester) async {
      await _pump(tester, TrendChart(points: _falling, threshold: _threshold));

      expect(_bar(tester).color, _tone(tester, StatusTone.danger));
      expect(_data(tester).extraLinesData.verticalLines, isEmpty);
    });

    testWidgets("a downward crossing switches colour at the crossing and adds a labelled marker", (
      WidgetTester tester,
    ) async {
      await _pump(tester, TrendChart(points: _crossing, threshold: _threshold));

      // One bar, so fl_chart draws the extra lines (and the 50 % marker) once.
      final LineChartBarData bar = _bar(tester);
      expect(bar.spots.map((FlSpot s) => s.y).toList(), <double>[0.72, 0.68, 0.63, 0.59, 0.56]);
      expect(bar.color, isNull);
      expect(bar.gradientArea, LineChartGradientArea.wholeChart);
      final Color success = _tone(tester, StatusTone.success);
      final Color danger = _tone(tester, StatusTone.danger);
      expect(bar.gradient!.colors, <Color>[success, success, danger, danger]);
      expect(bar.gradient!.stops, _closeToAll(<double>[0, 2.75 / 4, 2.75 / 4, 1]));
      expect(_data(tester).extraLinesData.extraLinesOnTop, isTrue);

      final VerticalLine marker = _data(tester).extraLinesData.verticalLines.single;
      expect(marker.x, closeTo(2.75, 1e-9));
      expect(marker.color, _tone(tester, StatusTone.danger).withValues(alpha: 0.5));
      expect(marker.dashArray, <int>[4, 4]);
      expect(marker.label.show, isTrue);
      expect(marker.label.labelResolver(marker), "custom.trend_chart.threshold_crossed");
      expect(marker.label.style?.color, _tone(tester, StatusTone.danger));
    });

    testWidgets("down then up marks only the downward crossing", (WidgetTester tester) async {
      await _pump(tester, TrendChart(points: _series(<double>[0.8, 0.4, 0.8]), threshold: _threshold));

      expect(_runColors(tester), <Color>[
        _tone(tester, StatusTone.success),
        _tone(tester, StatusTone.danger),
        _tone(tester, StatusTone.success),
      ]);
      expect(_bar(tester).gradient!.stops, _closeToAll(<double>[0, 0.25, 0.25, 0.75, 0.75, 1]));
      expect(_data(tester).extraLinesData.verticalLines.single.x, closeTo(0.5, 1e-9));
    });

    testWidgets("lower-is-better inverts the colours and marks upward crossings", (WidgetTester tester) async {
      await _pump(
        tester,
        TrendChart(
          points: _series(<double>[0.4, 0.8, 0.8]),
          threshold: const TrendThreshold(value: 0.6, higherIsBetter: false),
        ),
      );

      expect(_runColors(tester), <Color>[_tone(tester, StatusTone.success), _tone(tester, StatusTone.danger)]);
      expect(_data(tester).extraLinesData.verticalLines.single.x, closeTo(0.5, 1e-9));
    });

    testWidgets("custom tones and labels are used", (WidgetTester tester) async {
      await _pump(
        tester,
        TrendChart(
          points: _crossing,
          threshold: const TrendThreshold(
            value: 0.6,
            label: "Target",
            crossingLabel: "Missed",
            favourableTone: StatusTone.info,
            adverseTone: StatusTone.warning,
          ),
        ),
      );

      expect(_runColors(tester), <Color>[_tone(tester, StatusTone.info), _tone(tester, StatusTone.warning)]);
      final HorizontalLine line = _thresholdLine(tester);
      final VerticalLine marker = _data(tester).extraLinesData.verticalLines.single;
      expect(line.label.labelResolver(line), "Target");
      expect(marker.label.labelResolver(marker), "Missed");
    });
  });

  group("painted line and labels", () {
    testWidgets("the line is painted in the favourable tone left of the crossing, adverse right", (
      WidgetTester tester,
    ) async {
      await _pumpBoundary(
        tester,
        TrendChart(
          points: _crossing,
          threshold: const TrendThreshold(value: 0.6, label: "Limit", crossingLabel: "XX"),
        ),
      );
      final Rect plot = _plot(tester);
      final double crossing = plot.left + plot.width * 2.75 / 4;

      final ({int inside, int outside}) favourable = await _pixels(
        tester,
        _tone(tester, StatusTone.success),
        Rect.fromLTRB(0, 0, crossing + 1, 1000),
      );
      final ({int inside, int outside}) adverse = await _pixels(
        tester,
        _tone(tester, StatusTone.danger),
        Rect.fromLTRB(crossing - 1, 0, 1000, 1000),
      );
      expect(favourable.inside, greaterThan(0));
      expect(favourable.outside, 0);
      expect(adverse.inside, greaterThan(0));
      expect(adverse.outside, 0);
    });

    testWidgets("a mid-range threshold keeps its label above the line, top right", (WidgetTester tester) async {
      await _pump(tester, TrendChart(points: _crossing, threshold: _threshold));

      expect(_thresholdLine(tester).label.alignment, Alignment.topRight);
    });

    testWidgets("a threshold at or near the top puts its label under the line", (WidgetTester tester) async {
      final List<TrendChart> charts = <TrendChart>[
        // Open bounds, every value below: the threshold is the top.
        TrendChart(points: _falling, threshold: _threshold),
        // Open bounds, 0.02 under a 0.32 span: about 10 dp of room.
        TrendChart(points: _series(<double>[0.62, 0.46, 0.40, 0.36, 0.30]), threshold: _threshold),
        // Explicit bound equal to the threshold.
        TrendChart(points: _falling, threshold: const TrendThreshold(value: 1), minY: 0, maxY: 1),
      ];
      for (final TrendChart chart in charts) {
        await _pump(tester, chart);
        expect(_thresholdLine(tester).label.alignment, Alignment.bottomRight);
      }
    });

    testWidgets("a threshold label at the top is painted inside the plot", (WidgetTester tester) async {
      await _pumpBoundary(
        tester,
        TrendChart(
          points: _falling,
          threshold: const TrendThreshold(value: 0.6, label: "Limit"),
        ),
      );

      final ({int inside, int outside}) label = await _pixels(tester, _tone(tester, StatusTone.warning), _plot(tester));
      expect(label.inside, greaterThan(0));
      expect(label.outside, 0);
    });

    testWidgets("a crossing label near the right edge goes left of its marker, inside the plot", (
      WidgetTester tester,
    ) async {
      // Crossing at x = 5.97 of 6, under explicit bounds.
      await _pumpBoundary(
        tester,
        TrendChart(
          points: _series(<double>[0.9, 0.9, 0.9, 0.9, 0.9, 0.9, 0.59]),
          threshold: const TrendThreshold(value: 0.6, crossingLabel: "XX"),
          minY: 0,
          maxY: 1,
        ),
      );
      expect(_data(tester).extraLinesData.verticalLines.single.label.alignment, Alignment.topLeft);

      final Rect plot = _plot(tester);
      final ({int inside, int outside}) label = await _pixels(
        tester,
        _tone(tester, StatusTone.danger),
        Rect.fromLTRB(plot.left, plot.top, plot.right - 8, plot.top + 24),
      );
      expect(label.inside, greaterThan(0));
      final ({int inside, int outside}) beyond = await _pixels(
        tester,
        _tone(tester, StatusTone.danger),
        plot.inflate(1),
      );
      expect(beyond.outside, 0);
    });

    testWidgets("a crossing label with room keeps right of its marker", (WidgetTester tester) async {
      await _pump(
        tester,
        TrendChart(
          points: _crossing,
          threshold: const TrendThreshold(value: 0.6, crossingLabel: "XX"),
        ),
      );

      expect(_data(tester).extraLinesData.verticalLines.single.label.alignment, Alignment.topRight);
    });
  });

  group("caption and semantics", () {
    testWidgets("no caption by default", (WidgetTester tester) async {
      await _pump(tester, TrendChart(points: _rising));

      final Finder italic = find.descendant(
        of: find.byType(TrendChart),
        matching: find.byWidgetPredicate((Widget w) => w is Text && w.style?.fontStyle == FontStyle.italic),
      );
      expect(italic, findsNothing);
    });

    testWidgets("a caption is shown in italic under the chart", (WidgetTester tester) async {
      await _pump(tester, TrendChart(points: _rising, caption: "Note"));

      final Text caption = tester.widget<Text>(find.text("Note"));
      expect(caption.style?.fontStyle, FontStyle.italic);
      expect(tester.getTopLeft(find.text("Note")).dy, greaterThan(tester.getBottomLeft(find.byType(LineChart)).dy));
    });

    testWidgets("the chart is labelled with the default key or the given label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, TrendChart(points: _rising));
      expect(find.bySemanticsLabel("custom.trend_chart.semantics"), findsOneWidget);

      await _pump(tester, TrendChart(points: _rising, semanticLabel: "Weekly trend"));
      expect(find.bySemanticsLabel("Weekly trend"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("axis labels are excluded from semantics; the caption is read", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, TrendChart(points: _rising, caption: "Note"));

      expect(find.text("1/15"), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp("1/15")), findsNothing);
      expect(find.bySemanticsLabel("Note"), findsOneWidget);
      handle.dispose();
    });
  });

  group("motion", () {
    testWidgets("the entry animation is 500 ms easeOut", (WidgetTester tester) async {
      await _pump(tester, TrendChart(points: _rising));

      expect(_lineChart(tester).duration, const Duration(milliseconds: 500));
      expect(_lineChart(tester).curve, Curves.easeOut);
    });

    testWidgets("reduced motion makes it instant", (WidgetTester tester) async {
      await pumpApp(
        tester,
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: TrendChart(points: _rising),
        ),
      );

      expect(_lineChart(tester).duration, Duration.zero);
    });
  });

  group("axes", () {
    testWidgets("default labels use DateFormat.Md and decimalPattern", (WidgetTester tester) async {
      await _pump(tester, TrendChart(points: _rising, minY: 0, maxY: 1, yInterval: 0.2));

      expect(find.text("1/15"), findsOneWidget);
      expect(find.text("1/19"), findsOneWidget);
      expect(find.text("0.2"), findsOneWidget);
      expect(find.text("1"), findsOneWidget);
    });

    testWidgets("custom label builders are used", (WidgetTester tester) async {
      await _pump(
        tester,
        TrendChart(
          points: _rising,
          minY: 0,
          maxY: 1,
          yInterval: 0.5,
          xLabelBuilder: (DateTime date) => "d${date.day}",
          yLabelBuilder: (double value) => "${(value * 100).round()}%",
        ),
      );

      expect(find.text("d15"), findsOneWidget);
      expect(find.text("50%"), findsOneWidget);
    });

    testWidgets("the X label step is 1, 5 or 15 for 10, 30 or 90 points", (WidgetTester tester) async {
      for (final (int count, double step) in <(int, double)>[(10, 1), (30, 5), (90, 15)]) {
        await _pump(tester, TrendChart(points: _series(List<double>.filled(count, 0.5))));
        expect(_data(tester).titlesData.bottomTitles.sideTitles.interval, step);
      }
    });

    testWidgets("Y bounds and step pass through, without clipping", (WidgetTester tester) async {
      await _pump(tester, TrendChart(points: _rising, minY: 0, maxY: 1, yInterval: 0.2));

      final LineChartData data = _data(tester);
      expect((data.minY, data.maxY), (0.0, 1.0));
      expect(data.gridData.horizontalInterval, 0.2);
      expect(data.gridData.drawVerticalLine, isFalse);
      expect(data.titlesData.leftTitles.sideTitles.interval, 0.2);
      expect(data.clipData.any, isFalse);
    });

    testWidgets("a value on an explicit bound keeps its full stroke (no clipping)", (WidgetTester tester) async {
      await _pumpBoundary(tester, TrendChart(points: _series(<double>[1, 1, 1]), minY: 0, maxY: 1));

      final Rect plot = _plot(tester);
      final ({int inside, int outside}) stroke = await _pixels(
        tester,
        Theme.of(_context(tester)).colorScheme.primary,
        Rect.fromLTRB(plot.left, plot.top - 2, plot.right, plot.top),
      );
      expect(stroke.inside, greaterThan(0));
    });

    testWidgets("open bounds fit the data and the threshold, without clipping", (WidgetTester tester) async {
      await _pump(tester, TrendChart(points: _falling, threshold: _threshold));

      final LineChartData data = _data(tester);
      expect((data.minY, data.maxY), (0.30, 0.6));
      expect(data.clipData.any, isFalse);
      expect(data.gridData.horizontalInterval, isNull);
    });
  });

  testWidgets("a rebuild with new points and threshold recomputes the geometry", (WidgetTester tester) async {
    await _pump(tester, TrendChart(points: _rising));
    final State<StatefulWidget> state = tester.state(find.byType(TrendChart));

    await _pump(tester, TrendChart(points: _crossing, threshold: _threshold));

    expect(tester.state(find.byType(TrendChart)), same(state));
    expect(_runColors(tester), hasLength(2));
    expect(_data(tester).extraLinesData.verticalLines, hasLength(1));
  });

  testWidgets("renders under the dark theme with its tones", (WidgetTester tester) async {
    await _pump(
      tester,
      TrendChart(points: _crossing, threshold: _threshold, caption: "Note"),
      theme: AppTheme.dark(),
    );

    expect(tester.takeException(), isNull);
    expect(Theme.of(_context(tester)).brightness, Brightness.dark);
    expect(_runColors(tester), <Color>[_tone(tester, StatusTone.success), _tone(tester, StatusTone.danger)]);
  });
}

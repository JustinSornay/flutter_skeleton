// range_envelope_bar_test.dart
//
// Widget tests for RangeEnvelopeBar: captions (band labels positioned on the
// scale, formatted endpoints), the spread pill and its insufficient-data
// fallback, the reserved marker space, the semantics summary (raw keys under
// pumpApp, real fr / en strings through an in-memory EasyLocalization), the
// painted track / bands / envelopes / ticks / marker (colours, pill geometry
// and clamping, pill text colour read from rendered pixels), repaint
// decisions, narrow widths, text scaling, asserts and the dark theme.

import "dart:typed_data";
import "dart:ui" as ui;

import "package:easy_localization/easy_localization.dart" hide TextDirection;
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/RangeEnvelopeBar/index.dart";
import "package:flutter_skeleton/widgets/custom/_base/value_band.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _insufficientKey = "custom.range_envelope_bar.insufficient_data";
const String _rangeKey = "custom.range_envelope_bar.semantics_range";

/// Width of the bar in every test unless stated otherwise.
const double _width = 400;

const RangeEnvelopeSeries _series = RangeEnvelopeSeries(
  label: "Series A",
  values: <double>[60, 64, 67],
);

const RangeEnvelopeSeries _other = RangeEnvelopeSeries(
  label: "Series B",
  values: <double>[40, 55],
);

const List<ValueBand> _fiveBands = <ValueBand>[
  ValueBand(from: 0, to: 20, tone: StatusTone.danger, label: "Band 1"),
  ValueBand(from: 20, to: 40, tone: StatusTone.warning, label: "Band 2"),
  ValueBand(from: 40, to: 60, label: "Band 3"),
  ValueBand(from: 60, to: 80, tone: StatusTone.info, label: "Band 4"),
  ValueBand(from: 80, to: 100, tone: StatusTone.success, label: "Band 5"),
];

Future<void> _pump(
  WidgetTester tester,
  RangeEnvelopeBar bar, {
  double width = _width,
  ThemeData? theme,
}) async {
  await pumpApp(
    tester,
    Center(child: SizedBox(width: width, child: bar)),
    theme: theme,
  );
}

Finder _inBar(Finder matching) {
  return find.descendant(of: find.byType(RangeEnvelopeBar), matching: matching);
}

/// The CustomPaint drawing the bar (the only one inside the widget).
Finder get _paint => _inBar(find.byType(CustomPaint));

BuildContext _context(WidgetTester tester) => tester.element(find.byType(RangeEnvelopeBar));

ColorScheme _scheme(WidgetTester tester) => Theme.of(_context(tester)).colorScheme;

ToneColors _tone(WidgetTester tester, StatusTone tone) => StatusTones.colorsOf(_context(tester), tone);

/// Decoration of the spread pill (the only DecoratedBox inside the widget).
BoxDecoration _pillDecoration(WidgetTester tester) {
  return tester.widget<DecoratedBox>(_inBar(find.byType(DecoratedBox))).decoration as BoxDecoration;
}

/// Rounded rectangle of an envelope, in the CustomPaint's local coordinates.
RRect _envelope(double left, double top, double right, double bottom) {
  return RRect.fromRectAndRadius(Rect.fromLTRB(left, top, right, bottom), const Radius.circular(3));
}

double _sameValue() => 10;

/// Outer rect of the marker pill: the only rounded rectangle painted in
/// `cs.inverseSurface` (compared as 32-bit ARGB, the precision a Paint keeps).
Rect _pillRect(WidgetTester tester) {
  final int inverse = _scheme(tester).inverseSurface.toARGB32();
  Rect? pill;
  expect(
    tester.renderObject(_paint),
    paints
      ..something((Symbol method, List<dynamic> arguments) {
        if (method != #drawRRect || (arguments[1] as Paint).color.toARGB32() != inverse) return false;
        pill = (arguments[0] as RRect).outerRect;
        return true;
      }),
  );
  return pill!;
}

/// The painter currently installed on the bar's CustomPaint.
CustomPainter _painter(WidgetTester tester) => tester.widget<CustomPaint>(_paint).painter!;

/// Whether the painter built for [to] asks to repaint over the one built for
/// [from].
Future<bool> _repaints(WidgetTester tester, RangeEnvelopeBar from, RangeEnvelopeBar to) async {
  await _pump(tester, from);
  final CustomPainter old = _painter(tester);
  await _pump(tester, to);
  return _painter(tester).shouldRepaint(old);
}

/// Colour of the rendered pixel at [position] in the RepaintBoundary found
/// by [boundary] (the bar's local coordinates when it wraps the bar).
Future<Color> _pixelAt(WidgetTester tester, Finder boundary, Offset position) async {
  final RenderRepaintBoundary render = tester.renderObject<RenderRepaintBoundary>(boundary);
  final Color? color = await tester.runAsync<Color>(() async {
    final ui.Image image = await render.toImage();
    final ByteData data = (await image.toByteData())!;
    final int i = (position.dy.floor() * image.width + position.dx.floor()) * 4;
    image.dispose();
    return Color.fromARGB(data.getUint8(i + 3), data.getUint8(i), data.getUint8(i + 1), data.getUint8(i + 2));
  });
  return color!;
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
        "range_envelope_bar": <String, dynamic>{
          "insufficient_data": fr ? "Données insuffisantes" : "Insufficient data",
          "semantics_range": fr ? "{label} : de {min} à {max}" : "{label}: from {min} to {max}",
        },
      },
    };
  }
}

Future<void> _pumpLocalized(WidgetTester tester, Locale locale, RangeEnvelopeBar bar) async {
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
          home: Scaffold(body: Center(child: SizedBox(width: _width, child: bar))),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group("captions", () {
    testWidgets("renders every band label and the formatted endpoints", (WidgetTester tester) async {
      await _pump(tester, const RangeEnvelopeBar(primary: _series, bands: _fiveBands));

      for (final ValueBand band in _fiveBands) {
        expect(find.text(band.label!), findsOneWidget);
      }
      expect(find.text("0"), findsOneWidget);
      expect(find.text("100"), findsOneWidget);
    });

    testWidgets("formatValue formats the endpoints", (WidgetTester tester) async {
      await _pump(
        tester,
        RangeEnvelopeBar(primary: _series, formatValue: (double v) => "${v.toInt()} %"),
      );

      expect(find.text("0 %"), findsOneWidget);
      expect(find.text("100 %"), findsOneWidget);
    });

    testWidgets("band labels are centred under their band on the value scale", (WidgetTester tester) async {
      await _pump(
        tester,
        const RangeEnvelopeBar(
          primary: _series,
          min: 10,
          max: 110,
          bands: <ValueBand>[
            ValueBand(from: 10, to: 35, label: "Low"),
            ValueBand(from: 35, to: 110, label: "High"),
          ],
        ),
      );

      final double left = tester.getTopLeft(find.byType(RangeEnvelopeBar)).dx;
      expect(tester.getCenter(find.text("Low")).dx - left, moreOrLessEquals(_width * 0.125, epsilon: 0.5));
      expect(tester.getCenter(find.text("High")).dx - left, moreOrLessEquals(_width * 0.625, epsilon: 0.5));
    });

    testWidgets("endpoints are pinned to the left and right edges", (WidgetTester tester) async {
      await _pump(tester, const RangeEnvelopeBar(primary: _series, bands: _fiveBands));

      final Rect bar = tester.getRect(find.byType(RangeEnvelopeBar));
      expect(tester.getTopLeft(find.text("0")).dx, bar.left);
      expect(tester.getTopRight(find.text("100")).dx, bar.right);
    });

    testWidgets("captions are 8 / w700 in cs.onSurfaceVariant", (WidgetTester tester) async {
      await _pump(tester, const RangeEnvelopeBar(primary: _series, bands: _fiveBands));

      for (final String text in <String>["0", "100", "Band 3"]) {
        final TextStyle? style = tester.widget<Text>(find.text(text)).style;
        expect(style?.fontSize, 8);
        expect(style?.fontWeight, FontWeight.w700);
        expect(style?.color, _scheme(tester).onSurfaceVariant);
      }
    });

    testWidgets("without bands only the endpoints are captioned", (WidgetTester tester) async {
      await _pump(tester, const RangeEnvelopeBar(primary: _series));

      expect(_inBar(find.byType(Text)), findsNWidgets(2));
      expect(_paint, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("bands without a label or outside the scale get no caption", (WidgetTester tester) async {
      await _pump(
        tester,
        const RangeEnvelopeBar(
          primary: _series,
          bands: <ValueBand>[
            ValueBand(from: 0, to: 50),
            ValueBand(from: 120, to: 150, label: "Outside"),
          ],
        ),
      );

      expect(find.text("Outside"), findsNothing);
      expect(_inBar(find.byType(Text)), findsNWidgets(2));
    });
  });

  group("spread pill", () {
    testWidgets("no pill without a spread label", (WidgetTester tester) async {
      await _pump(tester, const RangeEnvelopeBar(primary: _series));

      expect(_inBar(find.byType(DecoratedBox)), findsNothing);
    });

    testWidgets("shows the label upper-cased in the tone container colours", (WidgetTester tester) async {
      await _pump(
        tester,
        const RangeEnvelopeBar(primary: _series, spreadLabel: "Tight · ±7", spreadTone: StatusTone.success),
      );

      expect(find.text("TIGHT · ±7"), findsOneWidget);
      final ToneColors success = _tone(tester, StatusTone.success);
      final BoxDecoration decoration = _pillDecoration(tester);
      expect(decoration.color, success.container);
      expect(decoration.borderRadius, BorderRadius.circular(999));
      final TextStyle? style = tester.widget<Text>(find.text("TIGHT · ±7")).style;
      expect(style?.color, success.onContainer);
      expect(style?.fontSize, 8);
      expect(style?.fontWeight, FontWeight.w800);
    });

    testWidgets("screen readers get the original casing", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, const RangeEnvelopeBar(primary: _series, spreadLabel: "Tight · ±7"));

      expect(find.bySemanticsLabel("Tight · ±7"), findsOneWidget);
      expect(find.bySemanticsLabel("TIGHT · ±7"), findsNothing);
      handle.dispose();
    });

    testWidgets("fewer than two values shows insufficient data in the neutral tone", (WidgetTester tester) async {
      await _pump(
        tester,
        const RangeEnvelopeBar(
          primary: RangeEnvelopeSeries(label: "Single", values: <double>[42]),
          spreadLabel: "Tight · ±0",
          spreadTone: StatusTone.danger,
        ),
      );

      expect(find.text(_insufficientKey.toUpperCase()), findsOneWidget);
      expect(find.text("TIGHT · ±0"), findsNothing);
      expect(_pillDecoration(tester).color, _tone(tester, StatusTone.neutral).container);
    });

    testWidgets("fewer than two values and no spread label: no pill", (WidgetTester tester) async {
      await _pump(
        tester,
        const RangeEnvelopeBar(primary: RangeEnvelopeSeries(label: "Single", values: <double>[42])),
      );

      expect(find.text(_insufficientKey.toUpperCase()), findsNothing);
    });
  });

  group("marker space", () {
    testWidgets("no marker reserves 2 dp above the 22 dp bar", (WidgetTester tester) async {
      await _pump(tester, const RangeEnvelopeBar(primary: _series));

      expect(tester.getSize(_paint), const Size(_width, 24));
    });

    testWidgets("a marker reserves 16 dp above the bar", (WidgetTester tester) async {
      await _pump(tester, const RangeEnvelopeBar(primary: _series, marker: 67));

      expect(tester.getSize(_paint), const Size(_width, 38));
    });
  });

  group("semantics", () {
    testWidgets("summarises each series range and the marker label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(
        tester,
        const RangeEnvelopeBar(primary: _series, secondary: _other, marker: 67, markerLabel: "67 now"),
      );

      expect(find.bySemanticsLabel("$_rangeKey. $_rangeKey. 67 now"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("the marker text defaults to formatValue(marker)", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, const RangeEnvelopeBar(primary: _series, marker: 67.6));

      expect(find.bySemanticsLabel("$_rangeKey. 68"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("without a marker the summary is the range only", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, const RangeEnvelopeBar(primary: _series));

      expect(find.bySemanticsLabel(_rangeKey), findsOneWidget);
      handle.dispose();
    });
  });

  group("painting", () {
    testWidgets("track, then bands at their value position", (WidgetTester tester) async {
      await _pump(
        tester,
        const RangeEnvelopeBar(
          primary: _series,
          bands: <ValueBand>[
            ValueBand(from: 20, to: 40, tone: StatusTone.warning),
            ValueBand(from: 80, to: 100, color: Colors.transparent),
          ],
        ),
      );
      final ColorScheme cs = _scheme(tester);

      expect(
        tester.renderObject(_paint),
        paints
          ..clipRRect(rrect: RRect.fromRectAndRadius(const Rect.fromLTWH(0, 2, _width, 22), const Radius.circular(4)))
          ..rect(rect: const Rect.fromLTWH(0, 2, _width, 22), color: cs.surfaceContainerHighest)
          ..rect(rect: const Rect.fromLTRB(80, 2, 160, 24), color: _tone(tester, StatusTone.warning).container)
          ..rect(rect: const Rect.fromLTRB(320, 2, 400, 24), color: Colors.transparent),
      );
    });

    testWidgets("single layout: full-height envelope in cs.primary and one tick per value", (WidgetTester tester) async {
      await _pump(tester, const RangeEnvelopeBar(primary: _series));
      final Color primary = _scheme(tester).primary;

      expect(
        tester.renderObject(_paint),
        paints
          ..rrect(rrect: _envelope(240, 5, 268, 21), color: primary.withValues(alpha: 0.28))
          ..rrect(rrect: _envelope(240, 5, 268, 21), color: primary, style: PaintingStyle.stroke, strokeWidth: 1)
          ..line(p1: const Offset(240, 10), p2: const Offset(240, 16), color: primary, strokeWidth: 2)
          ..line(p1: const Offset(256, 10), p2: const Offset(256, 16), color: primary, strokeWidth: 2)
          ..line(p1: const Offset(268, 10), p2: const Offset(268, 16), color: primary, strokeWidth: 2),
      );
      expect(tester.renderObject(_paint), paintsExactlyCountTimes(#drawLine, 3));
    });

    testWidgets("dual layout: stacked halves, secondary in cs.tertiary, no ticks", (WidgetTester tester) async {
      await _pump(tester, const RangeEnvelopeBar(primary: _series, secondary: _other));
      final ColorScheme cs = _scheme(tester);

      expect(
        tester.renderObject(_paint),
        paints
          ..rrect(rrect: _envelope(240, 5, 268, 14), color: cs.primary.withValues(alpha: 0.28))
          ..rrect(rrect: _envelope(240, 5, 268, 14), color: cs.primary, style: PaintingStyle.stroke)
          ..rrect(rrect: _envelope(160, 15, 220, 24), color: cs.tertiary.withValues(alpha: 0.25))
          ..rrect(rrect: _envelope(160, 15, 220, 24), color: cs.tertiary, style: PaintingStyle.stroke),
      );
      expect(tester.renderObject(_paint), paintsExactlyCountTimes(#drawLine, 0));
    });

    testWidgets("series tone and explicit colour override the defaults", (WidgetTester tester) async {
      final Color override = AppTheme.light().colorScheme.secondary;
      await _pump(
        tester,
        RangeEnvelopeBar(
          primary: const RangeEnvelopeSeries(label: "A", values: <double>[10, 20], tone: StatusTone.success),
          secondary: RangeEnvelopeSeries(
            label: "B",
            values: const <double>[30, 40],
            tone: StatusTone.danger,
            color: override,
          ),
        ),
      );
      final Color success = _tone(tester, StatusTone.success).foreground;

      expect(
        tester.renderObject(_paint),
        paints
          ..rrect(color: success.withValues(alpha: 0.28))
          ..rrect(color: success, style: PaintingStyle.stroke)
          ..rrect(color: override.withValues(alpha: 0.25))
          ..rrect(color: override, style: PaintingStyle.stroke),
      );
    });

    testWidgets("marker: inverse-surface tick through the bar, pill and text above", (WidgetTester tester) async {
      await _pump(tester, const RangeEnvelopeBar(primary: _series, marker: 50));
      final Color inverse = _scheme(tester).inverseSurface;

      expect(
        tester.renderObject(_paint),
        paints
          // Three value ticks, then the marker.
          ..line()
          ..line()
          ..line()
          ..line(p1: const Offset(200, 14), p2: const Offset(200, 40), color: inverse, strokeWidth: 2)
          ..rrect(color: inverse)
          ..paragraph(),
      );
      expect(tester.renderObject(_paint), paintsExactlyCountTimes(#drawLine, 4));
    });

    testWidgets("marker pill: centred on the tick, inside the 16 dp headroom, text inset", (
      WidgetTester tester,
    ) async {
      await _pump(tester, const RangeEnvelopeBar(primary: _series, marker: 50));
      final Rect pill = _pillRect(tester);

      expect(pill.center.dx, moreOrLessEquals(200));
      expect(pill.top, greaterThanOrEqualTo(0));
      // 3 dp gap above the bar top (y = 16).
      expect(pill.bottom, moreOrLessEquals(13));
      expect(tester.renderObject(_paint), paints..paragraph(offset: Offset(pill.left + 4, pill.top + 1)));
    });

    testWidgets("marker pill text is painted in cs.onInverseSurface on cs.inverseSurface", (
      WidgetTester tester,
    ) async {
      const Key boundary = Key("boundary");
      await pumpApp(
        tester,
        const Center(
          child: SizedBox(
            width: _width,
            child: RepaintBoundary(
              key: boundary,
              child: RangeEnvelopeBar(primary: _series, marker: 50),
            ),
          ),
        ),
      );
      final ColorScheme cs = _scheme(tester);
      final Rect pill = _pillRect(tester);

      // Left padding of the pill, then the middle of the first glyph.
      expect(
        await _pixelAt(tester, find.byKey(boundary), Offset(pill.left + 2, pill.center.dy)),
        isSameColorAs(cs.inverseSurface),
      );
      expect(
        await _pixelAt(tester, find.byKey(boundary), Offset(pill.left + 4 + 4.5, pill.center.dy)),
        isSameColorAs(cs.onInverseSurface),
      );
    });

    testWidgets("values, bands and marker are clamped to the scale", (WidgetTester tester) async {
      await _pump(
        tester,
        const RangeEnvelopeBar(
          primary: RangeEnvelopeSeries(label: "A", values: <double>[-20, 150]),
          bands: <ValueBand>[ValueBand(from: -50, to: 10)],
          marker: 130,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.renderObject(_paint),
        paints
          ..rect(rect: const Rect.fromLTWH(0, 16, _width, 22))
          ..rect(rect: const Rect.fromLTRB(0, 16, 40, 38))
          ..rrect(rrect: _envelope(0, 19, _width, 35))
          ..line(p1: const Offset(0, 24), p2: const Offset(0, 30))
          ..line(p1: const Offset(_width, 24), p2: const Offset(_width, 30))
          ..line(p1: const Offset(399, 14), p2: const Offset(399, 40)),
      );
      expect(_pillRect(tester).right, moreOrLessEquals(_width));
    });

    testWidgets("a marker at the left end keeps its pill inside the bar", (WidgetTester tester) async {
      await _pump(tester, const RangeEnvelopeBar(primary: _series, marker: 0));

      expect(
        tester.renderObject(_paint),
        paints
          ..line()
          ..line()
          ..line()
          ..line(p1: const Offset(1, 14), p2: const Offset(1, 40)),
      );
      expect(_pillRect(tester).left, moreOrLessEquals(0));
    });

    testWidgets("repaints when the values change", (WidgetTester tester) async {
      await _pump(tester, const RangeEnvelopeBar(primary: _series));
      await _pump(
        tester,
        const RangeEnvelopeBar(primary: RangeEnvelopeSeries(label: "Series A", values: <double>[10, 30])),
      );

      expect(tester.renderObject(_paint), paints..rrect(rrect: _envelope(40, 5, 120, 21)));
    });

    testWidgets("shouldRepaint is false for an equal configuration, true when it changes", (
      WidgetTester tester,
    ) async {
      const RangeEnvelopeBar base = RangeEnvelopeBar(primary: _series, bands: _fiveBands, marker: 50);

      // Equal content in fresh list instances.
      expect(
        await _repaints(
          tester,
          base,
          RangeEnvelopeBar(
            primary: RangeEnvelopeSeries(label: "Series A", values: List<double>.of(_series.values)),
            bands: List<ValueBand>.of(_fiveBands),
            marker: 50,
          ),
        ),
        isFalse,
      );
      expect(
        await _repaints(
          tester,
          base,
          const RangeEnvelopeBar(
            primary: RangeEnvelopeSeries(label: "Series A", values: <double>[60, 64, 70]),
            bands: _fiveBands,
            marker: 50,
          ),
        ),
        isTrue,
      );
      expect(
        await _repaints(
          tester,
          base,
          RangeEnvelopeBar(
            primary: _series,
            bands: <ValueBand>[
              ..._fiveBands.take(4),
              const ValueBand(from: 80, to: 100, tone: StatusTone.danger, label: "Band 5"),
            ],
            marker: 50,
          ),
        ),
        isTrue,
      );
      expect(
        await _repaints(tester, base, const RangeEnvelopeBar(primary: _series, bands: _fiveBands, marker: 60)),
        isTrue,
      );
      expect(
        await _repaints(
          tester,
          base,
          const RangeEnvelopeBar(primary: _series, bands: _fiveBands, marker: 50, markerLabel: "50 now"),
        ),
        isTrue,
      );
      expect(
        await _repaints(
          tester,
          base,
          const RangeEnvelopeBar(
            primary: RangeEnvelopeSeries(label: "Series A", values: <double>[60, 64, 67], tone: StatusTone.danger),
            bands: _fiveBands,
            marker: 50,
          ),
        ),
        isTrue,
      );
    });
  });

  group("robustness", () {
    testWidgets("out-of-range data at 160 dp does not throw", (WidgetTester tester) async {
      await _pump(
        tester,
        const RangeEnvelopeBar(
          primary: RangeEnvelopeSeries(label: "A", values: <double>[-20, 150]),
          secondary: _other,
          bands: _fiveBands,
          marker: 130,
          markerLabel: "130 now",
          spreadLabel: "Wide · ±85",
        ),
        width: 160,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets("a bar narrower than the marker pill does not throw", (WidgetTester tester) async {
      await _pump(
        tester,
        const RangeEnvelopeBar(primary: _series, marker: 50, markerLabel: "A long marker label"),
        width: 8,
      );

      expect(tester.takeException(), isNull);
      // Wider than the bar: pinned to the left edge.
      expect(_pillRect(tester).left, 0);
    });

    testWidgets("the caption row grows with the text scale and stays above the pill", (
      WidgetTester tester,
    ) async {
      Future<double> captionRowHeight(double scale) async {
        await pumpApp(
          tester,
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: const Center(
              child: SizedBox(
                width: 300,
                child: RangeEnvelopeBar(primary: _series, bands: _fiveBands, spreadLabel: "Medium · ±12"),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(
          tester.getBottomLeft(find.text("0")).dy,
          lessThanOrEqualTo(tester.getTopLeft(find.text("MEDIUM · ±12")).dy),
        );
        return tester.getSize(find.ancestor(of: find.text("0"), matching: find.byType(Stack)).first).height;
      }

      final double regular = await captionRowHeight(1);
      expect(await captionRowHeight(2), greaterThan(regular));
    });

    test("max must be greater than min", () {
      expect(
        () => RangeEnvelopeBar(primary: _series, min: 10, max: _sameValue()),
        throwsAssertionError,
      );
    });

    testWidgets("empty values assert when rendering", (WidgetTester tester) async {
      await _pump(
        tester,
        const RangeEnvelopeBar(primary: RangeEnvelopeSeries(label: "Empty", values: <double>[])),
      );

      expect(tester.takeException(), isA<AssertionError>());
    });

    test("series getters give the lowest, highest and spread", () {
      expect(_series.lowest, 60);
      expect(_series.highest, 67);
      expect(_series.spread, 7);
    });
  });

  group("dark theme", () {
    testWidgets("single and dual layouts render with dark tones", (WidgetTester tester) async {
      await _pump(
        tester,
        const RangeEnvelopeBar(
          primary: _series,
          bands: _fiveBands,
          marker: 67,
          spreadLabel: "Medium · ±12",
          spreadTone: StatusTone.warning,
        ),
        theme: AppTheme.dark(),
      );

      expect(tester.takeException(), isNull);
      expect(_scheme(tester).brightness, Brightness.dark);
      expect(_pillDecoration(tester).color, _tone(tester, StatusTone.warning).container);

      await _pump(
        tester,
        const RangeEnvelopeBar(primary: _series, secondary: _other, bands: _fiveBands),
        theme: AppTheme.dark(),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.renderObject(_paint),
        paints
          ..rrect(color: _scheme(tester).primary.withValues(alpha: 0.28))
          ..rrect(color: _scheme(tester).primary, style: PaintingStyle.stroke)
          ..rrect(color: _scheme(tester).tertiary.withValues(alpha: 0.25)),
      );
    });
  });

  // Keep this group last: EasyLocalization keeps the loaded translations in a
  // process-wide singleton, so `.tr()` in later pumpApp tests would no longer
  // return the raw key.
  group("real strings", () {
    testWidgets("each series label, lowest and highest, then the marker (en)", (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(
        tester,
        const Locale("en"),
        const RangeEnvelopeBar(primary: _series, secondary: _other, marker: 67, markerLabel: "67 now"),
      );

      expect(
        find.bySemanticsLabel("Series A: from 60 to 67. Series B: from 40 to 55. 67 now"),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets("French summary", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(
        tester,
        const Locale("fr"),
        const RangeEnvelopeBar(primary: _series, secondary: _other, marker: 67, markerLabel: "67 now"),
      );

      expect(find.bySemanticsLabel("Series A : de 60 à 67. Series B : de 40 à 55. 67 now"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("formatValue formats the summary values and the marker", (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(
        tester,
        const Locale("en"),
        RangeEnvelopeBar(primary: _series, marker: 50, formatValue: (double v) => "${v.toStringAsFixed(1)} %"),
      );

      expect(find.bySemanticsLabel("Series A: from 60.0 % to 67.0 %. 50.0 %"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("insufficient data uses the real translated string", (WidgetTester tester) async {
      await _pumpLocalized(
        tester,
        const Locale("en"),
        const RangeEnvelopeBar(
          primary: RangeEnvelopeSeries(label: "Single", values: <double>[42]),
          spreadLabel: "Tight · ±0",
        ),
      );

      expect(find.text("INSUFFICIENT DATA"), findsOneWidget);
    });
  });
}

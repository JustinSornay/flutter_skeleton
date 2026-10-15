// metric_tile_test.dart
//
// Widget tests for MetricTile: header / value / unit / caption structure and
// line gaps, the "—" placeholder, tone colours of the value and the caption,
// the value tone icon, the capped unit, maxLines, the filled and outlined
// containers, the single semantics node, sizing in grids, rows and wraps, and
// the dark theme.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/MetricLabel/index.dart";
import "package:flutter_skeleton/widgets/custom/MetricTile/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _label = "Latency";
const String _shownLabel = "LATENCY";

Finder _inTile(Finder matching) {
  return find.descendant(of: find.byType(MetricTile), matching: matching);
}

Text _text(WidgetTester tester, String data) => tester.widget<Text>(find.text(data));

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(MetricTile).first)).colorScheme;

ToneColors _tone(WidgetTester tester, StatusTone tone) {
  return StatusTones.colorsOf(tester.element(find.byType(MetricTile).first), tone);
}

BoxDecoration _decoration(WidgetTester tester) {
  final Container container = tester.widget<Container>(_inTile(find.byType(Container)).first);
  return container.decoration! as BoxDecoration;
}

/// Global y of the alphabetic baseline of the Text showing [data], measured
/// with a TextPainter using the same effective style.
double _baseline(WidgetTester tester, String data) {
  final Finder finder = find.text(data);
  final TextStyle style = DefaultTextStyle.of(tester.element(finder)).style.merge(_text(tester, data).style);
  final TextPainter painter = TextPainter(text: TextSpan(text: data, style: style), textDirection: TextDirection.ltr)
    ..layout();
  final double baseline = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  painter.dispose();
  return tester.getTopLeft(finder).dy + baseline;
}

/// Pumps [tile] centred in a 200 dp-wide box.
Future<void> _pumpTile(WidgetTester tester, MetricTile tile, {ThemeData? theme}) {
  return pumpApp(tester, Center(child: SizedBox(width: 200, child: tile)), theme: theme);
}

void main() {
  group("structure", () {
    testWidgets("shows the label upper-cased through MetricLabel and the value", (WidgetTester tester) async {
      await _pumpTile(tester, const MetricTile(label: _label, value: "650"));

      expect(_inTile(find.byType(MetricLabel)), findsOneWidget);
      expect(find.text(_shownLabel), findsOneWidget);
      expect(find.text("650"), findsOneWidget);
      expect(_inTile(find.byType(Text)), findsNWidgets(2));
    });

    testWidgets("an empty caption counts as absent", (WidgetTester tester) async {
      await _pumpTile(tester, const MetricTile(label: _label, value: "650", caption: ""));

      expect(_inTile(find.byType(Text)), findsNWidgets(2));
    });

    testWidgets("shows the caption under the value", (WidgetTester tester) async {
      await _pumpTile(tester, const MetricTile(label: _label, value: "650", caption: "+20 vs last year"));

      expect(find.text("+20 vs last year"), findsOneWidget);
      expect(tester.getTopLeft(find.text("+20 vs last year")).dy, greaterThan(tester.getBottomLeft(find.text("650")).dy));
    });

    testWidgets("forwards the icon to the label row", (WidgetTester tester) async {
      await _pumpTile(tester, const MetricTile(label: _label, value: "650", icon: Icons.speed));

      expect(find.byIcon(Icons.speed), findsOneWidget);
      expect(tester.widget<MetricLabel>(find.byType(MetricLabel)).icon, Icons.speed);
    });

    testWidgets("renders no icon by default", (WidgetTester tester) async {
      await _pumpTile(tester, const MetricTile(label: _label, value: "650"));

      expect(_inTile(find.byType(Icon)), findsNothing);
    });

    testWidgets("value and caption are single lines with an ellipsis", (WidgetTester tester) async {
      await _pumpTile(tester, const MetricTile(label: _label, value: "650", caption: "note"));

      for (final String data in <String>["650", "note"]) {
        expect(_text(tester, data).maxLines, 1);
        expect(_text(tester, data).overflow, TextOverflow.ellipsis);
      }
    });
  });

  group("value", () {
    testWidgets("is 16 / w700 in cs.onSurface without a tone", (WidgetTester tester) async {
      await _pumpTile(tester, const MetricTile(label: _label, value: "650"));

      final TextStyle style = _text(tester, "650").style!;
      expect(style.fontSize, 16);
      expect(style.fontWeight, FontWeight.w700);
      expect(style.color, _scheme(tester).onSurface);
    });

    testWidgets("takes the valueTone foreground", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Column(
          children: <Widget>[
            MetricTile(label: "a", value: "ok", valueTone: StatusTone.success),
            MetricTile(label: "b", value: "low", valueTone: StatusTone.danger),
            MetricTile(label: "c", value: "mid", valueTone: StatusTone.warning),
          ],
        ),
      );

      expect(_text(tester, "ok").style!.color, _tone(tester, StatusTone.success).foreground);
      expect(_text(tester, "low").style!.color, _tone(tester, StatusTone.danger).foreground);
      expect(_text(tester, "mid").style!.color, _tone(tester, StatusTone.warning).foreground);
    });

    testWidgets("a non-neutral valueTone adds its StatusTone.icon 4 dp before the value", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Column(
          children: <Widget>[
            MetricTile(label: "a", value: "ok", valueTone: StatusTone.success),
            MetricTile(label: "b", value: "low", valueTone: StatusTone.danger),
            MetricTile(label: "c", value: "mid", valueTone: StatusTone.warning),
          ],
        ),
      );

      final List<(String, StatusTone)> cases = <(String, StatusTone)>[
        ("ok", StatusTone.success),
        ("low", StatusTone.danger),
        ("mid", StatusTone.warning),
      ];
      for (final (String value, StatusTone tone) in cases) {
        final Finder icon = find.byIcon(tone.icon);
        expect(icon, findsOneWidget);
        expect(tester.widget<Icon>(icon).size, 12);
        expect(tester.widget<Icon>(icon).color, _tone(tester, tone).foreground);
        expect(tester.getTopLeft(find.text(value)).dx - tester.getTopRight(icon).dx, kDefaultPadding / 2);
        final Rect line = tester.getRect(find.text(value));
        final Rect glyph = tester.getRect(icon);
        expect(glyph.top, greaterThanOrEqualTo(line.top));
        expect(glyph.bottom, lessThanOrEqualTo(line.bottom));
      }
    });

    testWidgets("a null or neutral valueTone draws no icon", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Column(
          children: <Widget>[
            MetricTile(label: "a", value: "1"),
            MetricTile(label: "b", value: "2", valueTone: StatusTone.neutral),
          ],
        ),
      );

      expect(_inTile(find.byType(Icon)), findsNothing);
      expect(_text(tester, "2").style!.color, _tone(tester, StatusTone.neutral).foreground);
    });

    for (final String? missing in <String?>[null, ""]) {
      testWidgets("${missing == null ? "null" : "empty"} shows a muted dash and hides the unit", (WidgetTester tester) async {
        await _pumpTile(
          tester,
          MetricTile(label: _label, value: missing, unit: "ms", valueTone: StatusTone.success),
        );

        expect(find.text("—"), findsOneWidget);
        expect(find.text("ms"), findsNothing);
        expect(_text(tester, "—").style!.color, _scheme(tester).onSurfaceVariant);
        expect(_inTile(find.byType(Icon)), findsNothing);
      });
    }
  });

  group("unit", () {
    testWidgets("follows the value 2 dp apart, smaller and muted", (WidgetTester tester) async {
      await _pumpTile(tester, const MetricTile(label: _label, value: "650", unit: "ms"));

      final TextStyle style = _text(tester, "ms").style!;
      expect(style.fontSize, 11);
      expect(style.fontWeight, FontWeight.w500);
      expect(style.color, _scheme(tester).onSurfaceVariant);

      final double gap = tester.getTopLeft(find.text("ms")).dx - tester.getTopRight(find.text("650")).dx;
      expect(gap, kDefaultPadding / 4);
    });

    testWidgets("sits on the value's baseline", (WidgetTester tester) async {
      await _pumpTile(tester, const MetricTile(label: _label, value: "650", unit: "ms"));

      final Row row = tester.widget<Row>(
        find.ancestor(of: find.text("ms"), matching: find.byType(Row)).first,
      );
      expect(row.crossAxisAlignment, CrossAxisAlignment.baseline);
      expect(row.textBaseline, TextBaseline.alphabetic);
      expect(_baseline(tester, "ms"), closeTo(_baseline(tester, "650"), 0.01));
      expect(tester.getTopLeft(find.text("ms")).dy, greaterThan(tester.getTopLeft(find.text("650")).dy));
    });

    testWidgets("stays visible when a long value is ellipsized", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Center(
          child: SizedBox(
            width: 120,
            child: MetricTile(label: _label, value: "123456789012345678901234567890", unit: "ms"),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final Rect tile = tester.getRect(find.byType(MetricTile));
      expect(tester.getRect(find.text("ms")).right, lessThanOrEqualTo(tile.right));
    });

    testWidgets("a long unit is capped at 48 dp with an ellipsis", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: MetricTile(label: _label, value: "650", unit: "units per period"),
        ),
      );

      final Text unit = _text(tester, "units per period");
      expect(unit.maxLines, 1);
      expect(unit.overflow, TextOverflow.ellipsis);
      expect(tester.getSize(find.text("units per period")).width, kDefaultPadding * 6);
      expect(find.text("650"), findsOneWidget);
    });

    for (final (double width, StatusTone? tone, bool outlined) in <(double, StatusTone?, bool)>[
      (90, null, false),
      (92, StatusTone.success, true),
    ]) {
      testWidgets("a long unit does not overflow a $width dp tile (tone: ${tone?.name}, outlined: $outlined)", (
        WidgetTester tester,
      ) async {
        await pumpApp(
          tester,
          Center(
            child: SizedBox(
              width: width,
              child: MetricTile(label: "a", value: "12", unit: "units per period", valueTone: tone, outlined: outlined),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        final Rect tile = tester.getRect(find.byType(MetricTile));
        expect(
          tester.getRect(find.text("units per period")).right,
          lessThanOrEqualTo(tile.right - kDefaultPadding * 1.5),
        );
      });
    }
  });

  group("caption", () {
    testWidgets("is 10 / w400 cs.onSurfaceVariant by default", (WidgetTester tester) async {
      await _pumpTile(tester, const MetricTile(label: _label, value: "650", caption: "note"));

      final TextStyle style = _text(tester, "note").style!;
      expect(style.fontSize, 10);
      expect(style.fontWeight, FontWeight.w400);
      expect(style.color, _scheme(tester).onSurfaceVariant);
    });

    testWidgets("takes the captionTone foreground in w700", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Column(
          children: <Widget>[
            MetricTile(label: "a", value: "1", caption: "up", captionTone: StatusTone.success),
            MetricTile(label: "b", value: "2", caption: "down", captionTone: StatusTone.warning),
          ],
        ),
      );

      expect(_text(tester, "up").style!.color, _tone(tester, StatusTone.success).foreground);
      expect(_text(tester, "up").style!.fontWeight, FontWeight.w700);
      expect(_text(tester, "down").style!.color, _tone(tester, StatusTone.warning).foreground);
      expect(_text(tester, "down").style!.fontWeight, FontWeight.w700);
    });

    testWidgets("value and caption tones are independent", (WidgetTester tester) async {
      await _pumpTile(
        tester,
        const MetricTile(
          label: _label,
          value: "6.8",
          valueTone: StatusTone.success,
          caption: "Changed",
          captionTone: StatusTone.warning,
        ),
      );

      expect(_text(tester, "6.8").style!.color, _tone(tester, StatusTone.success).foreground);
      expect(_text(tester, "Changed").style!.color, _tone(tester, StatusTone.warning).foreground);
    });
  });

  group("container", () {
    testWidgets("is filled with cs.surfaceContainerHigh, radius 10, no border", (WidgetTester tester) async {
      await _pumpTile(tester, const MetricTile(label: _label, value: "650"));

      final BoxDecoration decoration = _decoration(tester);
      expect(decoration.color, _scheme(tester).surfaceContainerHigh);
      expect(decoration.borderRadius, BorderRadius.circular(10));
      expect(decoration.border, isNull);
    });

    testWidgets("outlined uses cs.surfaceContainerHighest and a cs.outlineVariant border", (WidgetTester tester) async {
      await _pumpTile(tester, const MetricTile(label: _label, value: "650", outlined: true));

      final BoxDecoration decoration = _decoration(tester);
      expect(decoration.color, _scheme(tester).surfaceContainerHighest);
      expect(decoration.border, Border.all(color: _scheme(tester).outlineVariant));
    });

    testWidgets("pads the content 12 dp horizontally and 8 dp vertically", (WidgetTester tester) async {
      await _pumpTile(tester, const MetricTile(label: _label, value: "650"));

      final Rect tile = tester.getRect(find.byType(MetricTile));
      final Rect header = tester.getRect(find.byType(MetricLabel));
      expect(header.left - tile.left, kDefaultPadding * 1.5);
      expect(header.top - tile.top, kDefaultPadding);
      expect(tile.bottom - tester.getRect(find.text("650")).bottom, kDefaultPadding);
    });

    testWidgets("spaces the header, the value and the caption 2 dp apart", (WidgetTester tester) async {
      await _pumpTile(tester, const MetricTile(label: _label, value: "650", caption: "note"));

      final Rect tile = tester.getRect(find.byType(MetricTile));
      final Rect header = tester.getRect(find.byType(MetricLabel));
      final Rect value = tester.getRect(find.text("650"));
      final Rect caption = tester.getRect(find.text("note"));
      expect(value.top - header.bottom, kDefaultPadding / 4);
      expect(caption.top - value.bottom, kDefaultPadding / 4);
      expect(tile.bottom - caption.bottom, kDefaultPadding);
    });
  });

  group("semantics", () {
    testWidgets("one node reading label, value with unit and caption", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpTile(tester, const MetricTile(label: _label, value: "650", unit: "ms", caption: "+20 ms"));

      expect(tester.getSemantics(find.byType(MetricTile)).label, "Latency, 650 ms, +20 ms");
      expect(find.bySemanticsLabel(_shownLabel), findsNothing);
      handle.dispose();
    });

    testWidgets("reads label and value without unit or caption", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpTile(tester, const MetricTile(label: _label, value: "650"));

      expect(tester.getSemantics(find.byType(MetricTile)).label, "Latency, 650");
      handle.dispose();
    });

    testWidgets("does not announce the value tone icon", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpTile(tester, const MetricTile(label: _label, value: "650", valueTone: StatusTone.danger));

      expect(find.byIcon(StatusTone.danger.icon), findsOneWidget);
      expect(tester.getSemantics(find.byType(MetricTile)).label, "Latency, 650");
      handle.dispose();
    });

    testWidgets("announces a missing value with the no-value key", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpTile(tester, const MetricTile(label: _label, unit: "ms"));

      expect(tester.getSemantics(find.byType(MetricTile)).label, "Latency, custom.metric_tile.no_value");
      handle.dispose();
    });

    testWidgets("semanticsLabel replaces the composed label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpTile(tester, const MetricTile(label: _label, value: "650", semanticsLabel: "Latency is 650 ms"));

      expect(tester.getSemantics(find.byType(MetricTile)).label, "Latency is 650 ms");
      handle.dispose();
    });
  });

  group("maxLines", () {
    const String longValue = "A value long enough to wrap";
    const String longCaption = "A caption long enough to wrap";

    /// Pumps a one-line reference tile ("1" / "c") above a 120 dp-wide tile
    /// showing [value] and [caption] under [maxLines].
    Future<void> pumpLong(WidgetTester tester, String value, String caption, int? maxLines) {
      return pumpApp(
        tester,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const MetricTile(label: "a", value: "1", caption: "c"),
            SizedBox(
              width: 120,
              child: MetricTile(label: _label, value: value, unit: "ms", caption: caption, maxLines: maxLines),
            ),
          ],
        ),
      );
    }

    double height(WidgetTester tester, String data) => tester.getSize(find.text(data)).height;

    testWidgets("null lets the value and the caption wrap, the unit on the first line", (WidgetTester tester) async {
      await pumpLong(tester, longValue, longCaption, null);

      expect(tester.takeException(), isNull);
      for (final (String data, String oneLine) in <(String, String)>[(longValue, "1"), (longCaption, "c")]) {
        expect(_text(tester, data).maxLines, isNull);
        expect(_text(tester, data).overflow, isNull);
        expect(height(tester, data), greaterThan(height(tester, oneLine) * 1.5));
      }
      expect(_baseline(tester, "ms"), closeTo(_baseline(tester, longValue), 0.01));
    });

    testWidgets("caps the value and the caption at the given line count", (WidgetTester tester) async {
      const String value = "$longValue $longValue $longValue";
      const String caption = "$longCaption $longCaption $longCaption";
      await pumpLong(tester, value, caption, 2);

      expect(tester.takeException(), isNull);
      for (final (String data, String oneLine) in <(String, String)>[(value, "1"), (caption, "c")]) {
        expect(_text(tester, data).maxLines, 2);
        expect(_text(tester, data).overflow, TextOverflow.ellipsis);
        expect(height(tester, data), closeTo(height(tester, oneLine) * 2, 0.01));
      }
    });

    test("rejects a non-positive count", () {
      expect(() => MetricTile(label: _label, maxLines: 0), throwsAssertionError);
    });
  });

  group("sizing", () {
    testWidgets("four tiles fit a 2-column grid with long values and captions", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Center(
          child: SizedBox(
            width: 320,
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: kDefaultPadding,
              mainAxisSpacing: kDefaultPadding,
              childAspectRatio: 2,
              children: List<Widget>.generate(
                4,
                (int i) => MetricTile(
                  label: "Item $i",
                  value: "123456.789 units of measure",
                  unit: "ms",
                  icon: Icons.speed,
                  caption: "+1234.5 compared with the previous period",
                  captionTone: StatusTone.success,
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(MetricTile), findsNWidgets(4));
      expect(tester.getSize(find.byType(MetricTile).first).width, closeTo((320 - kDefaultPadding) / 2, 0.01));
    });

    testWidgets("fills an Expanded cell", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const SizedBox(
          width: 300,
          child: Row(
            children: <Widget>[
              Expanded(child: MetricTile(label: "a", value: "1")),
              SizedBox(width: kDefaultPadding),
              Expanded(child: MetricTile(label: "b", value: "2")),
            ],
          ),
        ),
      );

      expect(tester.getSize(find.byType(MetricTile).first).width, (300 - kDefaultPadding) / 2);
    });

    testWidgets("shrink-wraps in a Row without Expanded", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Row(
          children: <Widget>[
            MetricTile(label: "a", value: "1"),
            SizedBox(width: kDefaultPadding),
            MetricTile(label: "Long label", value: "Good", caption: "Unchanged"),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(MetricTile).first).width, lessThan(100));
    });

    testWidgets("shrink-wraps in a Wrap", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const SizedBox(
          width: 400,
          child: Wrap(
            spacing: kDefaultPadding,
            runSpacing: kDefaultPadding,
            children: <Widget>[
              MetricTile(label: "a", value: "6.8", valueTone: StatusTone.success),
              MetricTile(label: "b", value: "32", unit: "%", valueTone: StatusTone.warning),
              MetricTile(label: "c", value: "18"),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final double first = tester.getTopLeft(find.byType(MetricTile).at(0)).dy;
      final double third = tester.getTopLeft(find.byType(MetricTile).at(2)).dy;
      expect(third, first);
    });

    testWidgets("a long label wraps under a bounded width", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                MetricTile(label: "A", value: "1"),
                MetricTile(label: "A label long enough to wrap", value: "1"),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(MetricTile).at(1)).width, lessThanOrEqualTo(100));
      final double oneLine = tester.getSize(find.byType(MetricLabel).at(0)).height;
      expect(tester.getSize(find.byType(MetricLabel).at(1)).height, greaterThan(oneLine * 1.5));
    });
  });

  group("dark theme", () {
    testWidgets("renders with dark tokens and tones", (WidgetTester tester) async {
      await _pumpTile(
        tester,
        const MetricTile(
          label: _label,
          value: "650",
          valueTone: StatusTone.info,
          caption: "+20",
          captionTone: StatusTone.danger,
          outlined: true,
        ),
        theme: AppTheme.dark(),
      );

      expect(tester.takeException(), isNull);
      expect(_scheme(tester).brightness, Brightness.dark);
      expect(_text(tester, "650").style!.color, _tone(tester, StatusTone.info).foreground);
      expect(tester.widget<Icon>(find.byIcon(StatusTone.info.icon)).color, _tone(tester, StatusTone.info).foreground);
      expect(_text(tester, "+20").style!.color, _tone(tester, StatusTone.danger).foreground);
      expect(_decoration(tester).color, _scheme(tester).surfaceContainerHighest);
    });

    testWidgets("an untoned value uses the dark cs.onSurface", (WidgetTester tester) async {
      await _pumpTile(tester, const MetricTile(label: _label, value: "650"), theme: AppTheme.dark());

      expect(_text(tester, "650").style!.color, _scheme(tester).onSurface);
      expect(_decoration(tester).color, _scheme(tester).surfaceContainerHigh);
    });
  });
}

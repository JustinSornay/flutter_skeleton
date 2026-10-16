// radar_chart_card_test.dart
//
// Widget tests for RadarChartCard: the empty guards, the self-managed
// expansion (collapsed by default, initiallyExpanded, reduced motion), the
// data mapping onto fl_chart (axis order, missing keys, clamping, the 0 and
// maxValue anchors), the comparison overlay and its stable slot, the chart
// height, the axis titles and weight suffix, the help button (callback, no
// toggle, 48 dp, tooltip), the ColorScheme tokens under the light and dark
// themes, the chart animation (including the comparison toggle mid-flight)
// and the screen-reader description. The last group loads the widget's
// translations through EasyLocalization with an in-memory loader; it runs
// last because EasyLocalization keeps its translations in a singleton.

import "package:easy_localization/easy_localization.dart";
import "package:fl_chart/fl_chart.dart";
// RadarChartLeaf carries the in-flight (lerped) data; fl_chart does not
// export it.
// ignore: implementation_imports
import "package:fl_chart/src/chart/radar_chart/radar_chart_renderer.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/RadarChartCard/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _title = "Profile";

const List<RadarAxis> _axes = <RadarAxis>[
  RadarAxis(key: "speed", label: "Speed"),
  RadarAxis(key: "power", label: "Power"),
  RadarAxis(key: "range", label: "Range"),
  RadarAxis(key: "comfort", label: "Comfort"),
  RadarAxis(key: "price", label: "Price"),
];

const RadarSeries _series = RadarSeries(
  values: <String, double>{"speed": 0.8, "power": 0.4, "range": 0.6, "comfort": 0.9, "price": 0.2},
);

const RadarSeries _comparison = RadarSeries(
  values: <String, double>{"speed": 0.5, "power": 0.7, "range": 0.3, "comfort": 0.6, "price": 0.4},
);

const Duration _settle = Duration(milliseconds: 600);

RadarChartCard _card({
  List<RadarAxis> axes = _axes,
  RadarSeries? series = _series,
  RadarSeries? comparison,
  VoidCallback? onHelp,
  String? helpLabel,
  bool initiallyExpanded = true,
  double maxValue = 1.0,
}) {
  return RadarChartCard(
    axes: axes,
    series: series,
    title: _title,
    comparison: comparison,
    onHelp: onHelp,
    helpLabel: helpLabel,
    initiallyExpanded: initiallyExpanded,
    maxValue: maxValue,
  );
}

/// Wraps [child] so the platform asks for reduced motion.
Widget _reducedMotion(Widget child) {
  return Builder(
    builder: (BuildContext context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child,
    ),
  );
}

RadarChart _chart(WidgetTester tester) => tester.widget<RadarChart>(find.byType(RadarChart));

RadarChartData _data(WidgetTester tester) => _chart(tester).data;

/// Data actually painted on the current frame (mid-animation: the lerp).
RadarChartData _painted(WidgetTester tester) => tester.widget<RadarChartLeaf>(find.byType(RadarChartLeaf)).data;

List<double> _values(RadarDataSet set) {
  return <double>[for (final RadarEntry entry in set.dataEntries) entry.value];
}

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(RadarChartCard))).colorScheme;
}

Finder _helpIcon() => find.byIcon(Icons.help_outline_rounded);

void main() {
  group("renders nothing", () {
    testWidgets("when series is null", (WidgetTester tester) async {
      await pumpApp(tester, _card(series: null));

      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.byType(RadarChart), findsNothing);
      expect(find.text(_title), findsNothing);
    });

    testWidgets("when the series has no values", (WidgetTester tester) async {
      await pumpApp(tester, _card(series: const RadarSeries(values: <String, double>{})));

      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.byType(RadarChart), findsNothing);
    });

    testWidgets("with fewer than 3 axes", (WidgetTester tester) async {
      await pumpApp(tester, _card(axes: _axes.sublist(0, 2)));

      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.byType(RadarChart), findsNothing);
    });

    testWidgets("draws exactly 3 axes", (WidgetTester tester) async {
      await pumpApp(tester, _card(axes: _axes.sublist(0, 3)));

      expect(_data(tester).titleCount, 3);
    });
  });

  group("expansion", () {
    testWidgets("is collapsed by default and opens on a header tap", (WidgetTester tester) async {
      await pumpApp(tester, const RadarChartCard(axes: _axes, series: _series, title: _title));

      expect(find.text(_title), findsOneWidget);
      expect(find.byIcon(Icons.radar_rounded), findsOneWidget);
      expect(find.byType(RadarChart), findsNothing);

      await tester.tap(find.text(_title));
      await tester.pump(_settle);
      expect(find.byType(RadarChart), findsOneWidget);

      await tester.tap(find.text(_title));
      await tester.pump(_settle);
      expect(find.byType(RadarChart), findsNothing);
    });

    testWidgets("initiallyExpanded shows the chart on the first frame", (WidgetTester tester) async {
      await pumpApp(tester, _card());

      expect(find.byType(RadarChart), findsOneWidget);
    });

    testWidgets("custom leading icon", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const RadarChartCard(axes: _axes, series: _series, title: _title, icon: Icons.insights),
      );

      expect(find.byIcon(Icons.insights), findsOneWidget);
      expect(find.byIcon(Icons.radar_rounded), findsNothing);
    });

    testWidgets("open / close uses kMotionShort", (WidgetTester tester) async {
      await pumpApp(tester, _card(initiallyExpanded: false));

      final ExpansionTile tile = tester.widget<ExpansionTile>(find.byType(ExpansionTile));
      expect(tile.expansionAnimationStyle?.duration, kMotionShort);
      expect(tile.initiallyExpanded, isFalse);
    });

    testWidgets("opens instantly under reduced motion", (WidgetTester tester) async {
      await pumpApp(tester, _reducedMotion(_card(initiallyExpanded: false)));

      final ExpansionTile tile = tester.widget<ExpansionTile>(find.byType(ExpansionTile));
      expect(tile.expansionAnimationStyle?.duration, Duration.zero);
      final double collapsed = tester.getSize(find.byType(Card)).height;

      await tester.tap(find.text(_title));
      await tester.pump();
      final double firstFrame = tester.getSize(find.byType(Card)).height;
      await tester.pump(_settle);

      // Already at full height on the first frame after the tap.
      expect(firstFrame, greaterThan(collapsed));
      expect(firstFrame, tester.getSize(find.byType(Card)).height);
    });
  });

  group("data", () {
    testWidgets("follows the axis order and anchors the scale to [0, maxValue]", (WidgetTester tester) async {
      await pumpApp(tester, _card());

      final RadarChartData data = _data(tester);
      expect(data.dataSets, hasLength(4));
      expect(_values(data.dataSets[0]), everyElement(0.0));
      expect(_values(data.dataSets[1]), everyElement(1.0));
      expect(_values(data.dataSets[3]), <double>[0.8, 0.4, 0.6, 0.9, 0.2]);
      expect(data.isMinValueAtCenter, isTrue);
      expect(data.tickCount, 4);
      expect(data.titlePositionPercentageOffset, 0.2);
      expect(data.radarTouchData.enabled, isFalse);
    });

    testWidgets("missing keys are 0 and values are clamped", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _card(
          series: const RadarSeries(
            values: <String, double>{"speed": 1.4, "power": -0.3, "range": double.nan, "comfort": 0.5},
          ),
        ),
      );

      expect(_values(_data(tester).dataSets[3]), <double>[1.0, 0.0, 0.0, 0.5, 0.0]);
    });

    testWidgets("maxValue sets the outer ring and the clamp", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _card(
          maxValue: 10,
          series: const RadarSeries(
            values: <String, double>{"speed": 12, "power": 5, "range": 2.5, "comfort": 10, "price": 0},
          ),
        ),
      );

      final RadarChartData data = _data(tester);
      expect(_values(data.dataSets[0]), everyElement(0.0));
      expect(_values(data.dataSets[1]), everyElement(10.0));
      expect(_values(data.dataSets[3]), <double>[10, 5, 2.5, 10, 0]);
    });

    testWidgets("comparison is drawn beneath the series with a thinner stroke", (WidgetTester tester) async {
      await pumpApp(tester, _card(comparison: _comparison));

      final RadarChartData data = _data(tester);
      expect(data.dataSets, hasLength(4));

      final RadarDataSet overlay = data.dataSets[2];
      expect(_values(overlay), <double>[0.5, 0.7, 0.3, 0.6, 0.4]);
      expect(overlay.borderWidth, 1.5);
      expect(overlay.entryRadius, 2);

      final RadarDataSet main = data.dataSets[3];
      expect(_values(main), <double>[0.8, 0.4, 0.6, 0.9, 0.2]);
      expect(main.borderWidth, 2);
      expect(main.entryRadius, 3);
    });

    testWidgets("without comparison its slot is an invisible copy of the series", (WidgetTester tester) async {
      await pumpApp(tester, _card());

      final RadarDataSet hidden = _data(tester).dataSets[2];
      expect(_values(hidden), <double>[0.8, 0.4, 0.6, 0.9, 0.2]);
      expect(hidden.borderColor.a, 0);
      expect(hidden.fillColor.a, 0);
      expect(hidden.borderWidth, 0);
      expect(hidden.entryRadius, 0);
    });

    testWidgets("chartHeight sets the chart height", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const RadarChartCard(axes: _axes, series: _series, title: _title, initiallyExpanded: true, chartHeight: 180),
      );

      expect(tester.getSize(find.byType(RadarChart)).height, 180);
    });
  });

  group("axis titles", () {
    testWidgets("use the axis labels in order", (WidgetTester tester) async {
      await pumpApp(tester, _card());

      final RadarChartData data = _data(tester);
      for (int i = 0; i < _axes.length; i++) {
        expect(data.getTitle!(i, 0).text, _axes[i].label);
      }
      expect(data.getTitle!(_axes.length, 0).text, "");
      expect(data.getTitle!(-1, 0).text, "");
    });

    testWidgets("a weighted axis uses the axis_weight key", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _card(
          axes: const <RadarAxis>[
            RadarAxis(key: "speed", label: "Speed", weight: 0.35),
            RadarAxis(key: "power", label: "Power"),
            RadarAxis(key: "range", label: "Range"),
          ],
        ),
      );

      final RadarChartData data = _data(tester);
      expect(data.getTitle!(0, 0).text, "custom.radar_chart_card.axis_weight");
      expect(data.getTitle!(1, 0).text, "Power");
    });
  });

  group("help button", () {
    testWidgets("is hidden without onHelp", (WidgetTester tester) async {
      await pumpApp(tester, _card(initiallyExpanded: false));

      expect(_helpIcon(), findsNothing);
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets("calls onHelp once and does not toggle the card", (WidgetTester tester) async {
      int calls = 0;
      await pumpApp(tester, _card(initiallyExpanded: false, onHelp: () => calls++));

      await tester.tap(_helpIcon());
      await tester.pump(_settle);

      expect(calls, 1);
      expect(find.byType(RadarChart), findsNothing);
    });

    testWidgets("is at least 48 dp with the default tooltip", (WidgetTester tester) async {
      await pumpApp(tester, _card(onHelp: () {}));

      final Size size = tester.getSize(find.ancestor(of: _helpIcon(), matching: find.byType(IconButton)));
      expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
      expect(find.byTooltip("custom.radar_chart_card.help"), findsOneWidget);
    });

    testWidgets("uses helpLabel as tooltip", (WidgetTester tester) async {
      await pumpApp(tester, _card(onHelp: () {}, helpLabel: "How to read"));

      expect(find.byTooltip("How to read"), findsOneWidget);
      expect(find.byTooltip("custom.radar_chart_card.help"), findsNothing);
    });

    testWidgets("fits a narrow card with a long title", (WidgetTester tester) async {
      await pumpApp(
        tester,
        RadarChartCard(
          axes: _axes,
          series: _series,
          title: "A rather long heading that needs to wrap on a narrow screen",
          initiallyExpanded: true,
          onHelp: () {},
        ),
        surfaceSize: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
      expect(_helpIcon(), findsOneWidget);
    });
  });

  group("colours", () {
    testWidgets("default series colours and card tokens (light)", (WidgetTester tester) async {
      await pumpApp(tester, _card(comparison: _comparison));
      final ColorScheme cs = _scheme(tester);
      final RadarChartData data = _data(tester);

      for (final RadarDataSet anchor in data.dataSets.sublist(0, 2)) {
        expect(anchor.fillColor, Colors.transparent);
        expect(anchor.borderColor, Colors.transparent);
        expect(anchor.entryRadius, 0);
      }
      expect(data.dataSets[2].borderColor, cs.tertiary);
      expect(data.dataSets[2].fillColor, cs.tertiary.withValues(alpha: 0.25));
      expect(data.dataSets[3].borderColor, cs.primary);
      expect(data.dataSets[3].fillColor, cs.primary.withValues(alpha: 0.20));
      expect(data.radarBorderData.color, cs.outlineVariant);
      expect(data.gridBorderData.color, cs.outlineVariant);
      expect(data.titleTextStyle?.color, cs.onSurfaceVariant);

      final Card card = tester.widget<Card>(find.byType(Card));
      expect(card.color, cs.surfaceContainerLowest);
      final RoundedRectangleBorder shape = card.shape! as RoundedRectangleBorder;
      expect(shape.side.color, cs.outlineVariant);
      expect(shape.borderRadius, BorderRadius.circular(24));

      expect(tester.widget<Text>(find.text(_title)).style?.color, cs.onSurface);
      expect(tester.widget<Icon>(find.byIcon(Icons.radar_rounded)).color, cs.primary);

      final Container tileBox = tester.widget<Container>(
        find.ancestor(of: find.byIcon(Icons.radar_rounded), matching: find.byType(Container)).first,
      );
      final BoxDecoration tile = tileBox.decoration! as BoxDecoration;
      expect(tile.color, cs.primary.withValues(alpha: 0.10));
      expect(tester.getSize(find.byWidget(tileBox)), const Size.square(32));

      final Divider divider = tester.widget<Divider>(find.byType(Divider));
      expect(divider.color, cs.outlineVariant);
    });

    testWidgets("RadarSeries.color is used as the stroke", (WidgetTester tester) async {
      final ColorScheme light = AppTheme.light().colorScheme;
      await pumpApp(
        tester,
        _card(
          series: RadarSeries(values: _series.values, color: light.secondary),
          comparison: RadarSeries(values: _comparison.values, color: light.error),
        ),
      );
      final RadarChartData data = _data(tester);

      expect(data.dataSets[2].borderColor, light.error);
      expect(data.dataSets[2].fillColor, light.error.withValues(alpha: 0.25));
      expect(data.dataSets[3].borderColor, light.secondary);
      expect(data.dataSets[3].fillColor, light.secondary.withValues(alpha: 0.20));
    });

    testWidgets("dark theme smoke test", (WidgetTester tester) async {
      await pumpApp(tester, _card(comparison: _comparison, onHelp: () {}), theme: AppTheme.dark());
      final ColorScheme cs = _scheme(tester);

      expect(cs.brightness, Brightness.dark);
      expect(tester.takeException(), isNull);
      expect(_data(tester).dataSets[2].borderColor, cs.tertiary);
      expect(_data(tester).dataSets[3].borderColor, cs.primary);
      expect(tester.widget<Card>(find.byType(Card)).color, cs.surfaceContainerLowest);
    });
  });

  group("motion", () {
    testWidgets("values animate over 500 ms with easeOut", (WidgetTester tester) async {
      await pumpApp(tester, _card());

      expect(_chart(tester).duration, const Duration(milliseconds: 500));
      expect(_chart(tester).curve, Curves.easeOut);
    });

    testWidgets("values change instantly under reduced motion", (WidgetTester tester) async {
      await pumpApp(tester, _reducedMotion(_card()));

      expect(_chart(tester).duration, Duration.zero);
    });

    testWidgets("toggling comparison fades the overlay and keeps the series", (WidgetTester tester) async {
      const List<double> main = <double>[0.8, 0.4, 0.6, 0.9, 0.2];
      await pumpApp(tester, _card());
      final ColorScheme cs = _scheme(tester);

      void expectMidFade() {
        final RadarChartData data = _painted(tester);
        expect(data.dataSets, hasLength(4));

        final RadarDataSet series = data.dataSets[3];
        expect(_values(series), main);
        expect(series.borderColor.toARGB32(), cs.primary.toARGB32());
        expect(series.borderWidth, 2);

        final RadarDataSet overlay = data.dataSets[2];
        expect(overlay.borderColor.a, allOf(greaterThan(0), lessThan(1)));
        expect(overlay.borderColor.withValues(alpha: 1).toARGB32(), cs.tertiary.toARGB32());
      }

      // Off -> on: the comparison fades in; the series does not move.
      await pumpApp(tester, _card(comparison: _comparison));
      await tester.pump(const Duration(milliseconds: 100));
      expectMidFade();
      await tester.pump(_settle);
      expect(_values(_painted(tester).dataSets[2]), <double>[0.5, 0.7, 0.3, 0.6, 0.4]);

      // On -> off: the comparison fades out; the series does not move.
      await pumpApp(tester, _card());
      await tester.pump(const Duration(milliseconds: 100));
      expectMidFade();
      await tester.pump(_settle);
      expect(_painted(tester).dataSets[2].borderColor.a, 0);
    });
  });

  group("accessibility", () {
    testWidgets("the chart lists one line per axis", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _card());

      final List<String> lines = tester.getSemantics(find.byType(RadarChart)).label.split("\n");
      expect(lines, List<String>.filled(_axes.length, "custom.radar_chart_card.axis_value"));
      handle.dispose();
    });

    testWidgets("the comparison follows its heading", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _card(comparison: _comparison));

      final List<String> lines = tester.getSemantics(find.byType(RadarChart)).label.split("\n");
      expect(lines, hasLength(_axes.length * 2 + 1));
      expect(lines[_axes.length], "custom.radar_chart_card.comparison");
      handle.dispose();
    });
  });

  // Keep last: EasyLocalization stores the loaded translations in a
  // singleton, so `.tr()` no longer returns raw keys after this group.
  group("localised", () {
    testWidgets("en: weight suffix and value lines", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalised(tester, _weightedCard(), const Locale("en"));

      final String weight = NumberFormat.percentPattern("en").format(0.35);
      expect(_data(tester).getTitle!(0, 0).text, "Speed ($weight)");

      final List<String> lines = tester.getSemantics(find.byType(RadarChart)).label.split("\n");
      expect(lines.first, "Speed ($weight): ${NumberFormat.percentPattern("en").format(0.8)}");
      expect(lines[1], "Power: ${NumberFormat.percentPattern("en").format(0.4)}");
      expect(lines[3], "Comparison");
      expect(find.byTooltip("Learn more"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("fr: locale-formatted percentages", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalised(tester, _weightedCard(), const Locale("fr"));

      final String weight = NumberFormat.percentPattern("fr").format(0.35);
      expect(weight, isNot("35%"));
      expect(_data(tester).getTitle!(0, 0).text, "Speed ($weight)");

      final List<String> lines = tester.getSemantics(find.byType(RadarChart)).label.split("\n");
      expect(lines.first, "Speed ($weight) : ${NumberFormat.percentPattern("fr").format(0.8)}");
      expect(lines[3], "Comparaison");
      expect(find.byTooltip("En savoir plus"), findsOneWidget);
      handle.dispose();
    });
  });
}

/// Three axes, the first weighted, with a comparison and a help button.
RadarChartCard _weightedCard() {
  return _card(
    axes: const <RadarAxis>[
      RadarAxis(key: "speed", label: "Speed", weight: 0.35),
      RadarAxis(key: "power", label: "Power"),
      RadarAxis(key: "range", label: "Range"),
    ],
    comparison: _comparison,
    onHelp: () {},
  );
}

/// Translations of the widget's chrome keys (same content as the i18n
/// fragment merged into assets/translations).
const Map<String, Map<String, dynamic>> _translations = <String, Map<String, dynamic>>{
  "fr": <String, dynamic>{
    "custom": <String, dynamic>{
      "radar_chart_card": <String, dynamic>{
        "help": "En savoir plus",
        "axis_weight": "{label} ({percent})",
        "axis_value": "{label} : {percent}",
        "comparison": "Comparaison",
      },
    },
  },
  "en": <String, dynamic>{
    "custom": <String, dynamic>{
      "radar_chart_card": <String, dynamic>{
        "help": "Learn more",
        "axis_weight": "{label} ({percent})",
        "axis_value": "{label}: {percent}",
        "comparison": "Comparison",
      },
    },
  },
};

/// Serves [_translations] instead of the asset bundle.
final class _MemoryLoader extends AssetLoader {
  const _MemoryLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async => _translations[locale.languageCode];
}

/// Pumps [child] in a MaterialApp under EasyLocalization at [locale].
Future<void> _pumpLocalised(WidgetTester tester, Widget child, Locale locale) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EasyLocalization.ensureInitialized();

  // The loader future completes with real async, outside the fake clock.
  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[Locale("fr"), Locale("en")],
        path: "memory",
        assetLoader: const _MemoryLoader(),
        fallbackLocale: const Locale("fr"),
        startLocale: locale,
        saveLocale: false,
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
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await tester.pump();
}

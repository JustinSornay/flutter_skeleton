// confidence_badge_test.dart
//
// Widget tests for ConfidenceBadge: the default and custom icon, the tone
// colours of the icon and the label, the label style, the tooltip contract
// (hint vs default, tap trigger, 5 s duration), the 48 dp hit area, the single
// semantics node, overflow in narrow and unbounded parents, the dark theme and
// the real fr / en strings with the locale's floored percent. The pure level
// bucketing is in test/unit/widgets/confidence_badge_level_test.dart.

import "dart:convert";
import "dart:io";

import "package:easy_localization/easy_localization.dart";
// Localization.load is the only way to empty the translations singleton that
// EasyLocalization fills; see the "localized" group's tearDown.
// ignore: implementation_imports
import "package:easy_localization/src/localization.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/data/locales.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/ConfidenceBadge/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _labelKey = "custom.confidence_badge.label";
const String _tooltipKey = "custom.confidence_badge.tooltip";
const String _hint = "Only a few samples back this value";

Finder _inBadge(Finder matching) {
  return find.descendant(of: find.byType(ConfidenceBadge), matching: matching);
}

Tooltip _tooltip(WidgetTester tester) => tester.widget<Tooltip>(_inBadge(find.byType(Tooltip)));

Text _label(WidgetTester tester) => tester.widget<Text>(_inBadge(find.byType(Text)));

Icon _icon(WidgetTester tester) => tester.widget<Icon>(_inBadge(find.byType(Icon)));

Color _toneForeground(WidgetTester tester, StatusTone tone) {
  return StatusTones.colorsOf(tester.element(find.byType(ConfidenceBadge)), tone).foreground;
}

/// Lets the tap tooltip hide and its timers expire.
Future<void> _finishTooltipTimers(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

/// Copy of the widget's i18n fragment (`custom.confidence_badge.*`), used only
/// until the fragment is merged into assets/translations. Keep it in sync.
const Map<String, Map<String, String>> _fragment = <String, Map<String, String>>{
  "fr": <String, String>{
    "title": "Fiabilité des données",
    "high": "Élevée",
    "moderate": "Modérée",
    "low": "Faible",
    "label": "{title} : {level}",
    "tooltip": "{title} : {level} ({percent})",
  },
  "en": <String, String>{
    "title": "Data reliability",
    "high": "High",
    "moderate": "Moderate",
    "low": "Low",
    "label": "{title}: {level}",
    "tooltip": "{title}: {level} ({percent})",
  },
};

/// Reads the real `<path>/<lang>.json` once it holds `custom.confidence_badge`,
/// so the expectations below check the shipped strings; until then it serves
/// [_fragment]. Synchronous I/O completes inside the fake-async test zone.
final class _TranslationsLoader extends AssetLoader {
  const _TranslationsLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final File file = File("$path/${locale.languageCode}.json");
    final Map<String, dynamic> assets = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final Object? custom = assets["custom"];
    if (custom is Map<String, dynamic> && custom.containsKey("confidence_badge")) return assets;
    return <String, dynamic>{
      "custom": <String, dynamic>{"confidence_badge": _fragment[locale.languageCode]},
    };
  }
}

Future<void> _pumpLocalized(WidgetTester tester, Locale locale, Widget child) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const <Locale>[Locale("fr"), Locale("en")],
      path: AppLocales.path,
      fallbackLocale: const Locale("fr"),
      startLocale: locale,
      saveLocale: false,
      assetLoader: const _TranslationsLoader(),
      child: Builder(
        builder: (BuildContext context) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.light(),
          home: Scaffold(body: Center(child: child)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group("structure", () {
    testWidgets("renders the shield icon (14 dp) before the label", (WidgetTester tester) async {
      await pumpApp(tester, const ConfidenceBadge(value: 0.9));

      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
      expect(_icon(tester).size, 14);
      expect(find.text(_labelKey), findsOneWidget);
      expect(
        tester.getTopRight(find.byIcon(Icons.shield_outlined)).dx + kDefaultPadding / 2,
        moreOrLessEquals(tester.getTopLeft(find.text(_labelKey)).dx),
      );
    });

    testWidgets("a custom icon replaces the shield", (WidgetTester tester) async {
      await pumpApp(tester, const ConfidenceBadge(value: 0.9, icon: Icons.verified_outlined));

      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsNothing);
    });

    testWidgets("label is labelMedium / w600 on one line with an ellipsis", (WidgetTester tester) async {
      await pumpApp(tester, const ConfidenceBadge(value: 0.9));

      final Text text = _label(tester);
      final TextStyle? labelMedium = Theme.of(tester.element(find.byType(ConfidenceBadge))).textTheme.labelMedium;
      expect(text.style?.fontSize, labelMedium?.fontSize);
      expect(text.style?.fontWeight, FontWeight.w600);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });
  });

  group("tones (light)", () {
    final Map<double, StatusTone> cases = <double, StatusTone>{
      0.90: StatusTone.success,
      0.65: StatusTone.warning,
      0.42: StatusTone.danger,
    };
    for (final MapEntry<double, StatusTone> entry in cases.entries) {
      testWidgets("${entry.key} colours the icon and the label with ${entry.value.name}", (WidgetTester tester) async {
        await pumpApp(tester, ConfidenceBadge(value: entry.key));

        final Color expected = _toneForeground(tester, entry.value);
        expect(_icon(tester).color, expected);
        expect(_label(tester).style?.color, expected);
      });
    }

    testWidgets("custom thresholds change the tone", (WidgetTester tester) async {
      await pumpApp(tester, const ConfidenceBadge(value: 0.85, highAt: 0.9, moderateAt: 0.6));

      expect(_icon(tester).color, _toneForeground(tester, StatusTone.warning));
    });

    testWidgets("the three tones are distinct", (WidgetTester tester) async {
      await pumpApp(tester, const ConfidenceBadge(value: 0.9));

      final Set<Color> colours = <Color>{
        _toneForeground(tester, StatusTone.success),
        _toneForeground(tester, StatusTone.warning),
        _toneForeground(tester, StatusTone.danger),
      };
      expect(colours, hasLength(3));
    });
  });

  group("tooltip", () {
    testWidgets("defaults to the tooltip key when no hint is given", (WidgetTester tester) async {
      await pumpApp(tester, const ConfidenceBadge(value: 0.9));

      expect(_tooltip(tester).message, _tooltipKey);
    });

    testWidgets("the hint replaces the default tooltip", (WidgetTester tester) async {
      await pumpApp(tester, const ConfidenceBadge(value: 0.9, hint: _hint));

      expect(_tooltip(tester).message, _hint);
    });

    testWidgets("an empty hint falls back to the default tooltip", (WidgetTester tester) async {
      await pumpApp(tester, const ConfidenceBadge(value: 0.9, hint: ""));

      expect(_tooltip(tester).message, _tooltipKey);
    });

    testWidgets("opens on tap, immediately, for 5 s", (WidgetTester tester) async {
      await pumpApp(tester, const ConfidenceBadge(value: 0.42, hint: _hint));

      final Tooltip tooltip = _tooltip(tester);
      expect(tooltip.triggerMode, TooltipTriggerMode.tap);
      expect(tooltip.waitDuration, Duration.zero);
      expect(tooltip.showDuration, const Duration(seconds: 5));

      expect(find.text(_hint), findsNothing);
      await tester.tap(find.byType(ConfidenceBadge));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(_hint), findsOneWidget);

      await _finishTooltipTimers(tester);
      expect(find.text(_hint), findsNothing);
    });
  });

  group("accessibility", () {
    testWidgets("hit area is at least 48 x 48", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: ConfidenceBadge(value: 0.9)));

      final Size size = tester.getSize(find.byType(ConfidenceBadge));
      expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
    });

    testWidgets("one semantics node carries the label and the tooltip", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const ConfidenceBadge(value: 0.9, hint: _hint));

      final SemanticsNode node = tester.getSemantics(find.bySemanticsLabel(_labelKey));
      expect(node.label, _labelKey);
      expect(node.tooltip, _hint);
      // The visible text is not read a second time.
      expect(find.bySemanticsLabel(_labelKey), findsOneWidget);
      handle.dispose();
    });
  });

  group("layout", () {
    testWidgets("a long label ellipsises in a narrow box without overflow", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Center(
          child: SizedBox(
            width: 120,
            child: ConfidenceBadge(value: 0.65, title: "A rather long title for a narrow column"),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(ConfidenceBadge)).width, lessThanOrEqualTo(120));
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text(_labelKey), matching: find.byType(RichText)),
      );
      expect(paragraph.didExceedMaxLines, isTrue);
    });

    testWidgets("sits in a Row without a Flexible (unbounded width)", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Row(children: <Widget>[ConfidenceBadge(value: 0.9), Text("after")]),
      );

      expect(tester.takeException(), isNull);
      expect(find.text("after"), findsOneWidget);
    });
  });

  group("dark theme", () {
    testWidgets("smoke: tones resolve from the dark StatusTones", (WidgetTester tester) async {
      await pumpApp(tester, const ConfidenceBadge(value: 0.65), theme: AppTheme.dark());

      final StatusTones tones = Theme.of(tester.element(find.byType(ConfidenceBadge))).extension<StatusTones>()!;
      expect(_icon(tester).color, tones.warning.foreground);
      expect(_label(tester).style?.color, tones.warning.foreground);
      expect(tester.takeException(), isNull);
    });
  });

  group("localized", () {
    // EasyLocalization keeps its translations in a singleton that outlives the
    // test; empty it so the raw-key tests pass in any order.
    tearDown(() {
      Localization.load(const Locale("fr"));
    });

    testWidgets("fr: label and default tooltip with the French percent format", (WidgetTester tester) async {
      await _pumpLocalized(tester, const Locale("fr"), const ConfidenceBadge(value: 0.9));

      expect(find.text("Fiabilité des données : Élevée"), findsOneWidget);
      final String percent = NumberFormat.percentPattern("fr").format(0.9);
      expect(percent, isNot("90%"));
      expect(_tooltip(tester).message, "Fiabilité des données : Élevée ($percent)");
    });

    testWidgets("en: label and default tooltip with the English percent format", (WidgetTester tester) async {
      await _pumpLocalized(tester, const Locale("en"), const ConfidenceBadge(value: 0.65));

      expect(find.text("Data reliability: Moderate"), findsOneWidget);
      expect(_tooltip(tester).message, "Data reliability: Moderate (65%)");
    });

    testWidgets("en: a custom title reaches the label, the tooltip and the semantics", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(tester, const Locale("en"), const ConfidenceBadge(value: 0.2, title: "Source quality"));

      expect(find.text("Source quality: Low"), findsOneWidget);
      expect(_tooltip(tester).message, "Source quality: Low (20%)");
      expect(find.bySemanticsLabel("Source quality: Low"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("en: the percentage uses the clamped value", (WidgetTester tester) async {
      await _pumpLocalized(tester, const Locale("en"), const ConfidenceBadge(value: 1.5));

      expect(_tooltip(tester).message, "Data reliability: High (100%)");
    });

    testWidgets("en: the percentage is floored below a threshold", (WidgetTester tester) async {
      await _pumpLocalized(tester, const Locale("en"), const ConfidenceBadge(value: 0.7999));

      expect(_tooltip(tester).message, "Data reliability: Moderate (79%)");
    });

    testWidgets("en: flooring is exact for whole percents", (WidgetTester tester) async {
      // 0.29 * 100 is 28.999… in binary floating point.
      await _pumpLocalized(tester, const Locale("en"), const ConfidenceBadge(value: 0.29));

      expect(_tooltip(tester).message, "Data reliability: Low (29%)");
    });

    testWidgets("fr: the percentage is floored below a threshold", (WidgetTester tester) async {
      await _pumpLocalized(tester, const Locale("fr"), const ConfidenceBadge(value: 0.4999));

      final String percent = NumberFormat.percentPattern("fr").format(0.49);
      expect(_tooltip(tester).message, "Fiabilité des données : Faible ($percent)");
    });

    testWidgets("en: the hint still wins over the translated tooltip", (WidgetTester tester) async {
      await _pumpLocalized(tester, const Locale("en"), const ConfidenceBadge(value: 0.9, hint: _hint));

      expect(_tooltip(tester).message, _hint);
      expect(find.text("Data reliability: High"), findsOneWidget);
    });
  });
}

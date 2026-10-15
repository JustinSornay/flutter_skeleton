// score_banner_test.dart
//
// Widget tests for ScoreBanner: the message and the default / custom value
// label, a long value label capped with an ellipsis, clamping, the tone
// colours for every StatusTone in the light and dark themes (background,
// text, icon circle, tone-derived bar with its measured contrast, link), the
// default and overridden icon, the note pill in its own tone, the optional
// link (tap, label override, 48 dp hit area, semantics, no Material
// ancestor), the semantics tree, and the real fr / en strings (with the
// clamped default value) through an in-memory EasyLocalization loader. The
// localized tests reset the easy_localization singleton, so the raw-key
// tests pass in any order.

import "dart:math" as math;

import "package:easy_localization/easy_localization.dart";
// Localization.load is the only way to empty the translations singleton that
// EasyLocalization fills; see _pumpLocalized.
// ignore: implementation_imports
import "package:easy_localization/src/localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/ScoreBanner/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _message = "The result meets every target.";
const String _valueKey = "custom.score_banner.value";
const String _valueSemanticsKey = "custom.score_banner.value_semantics";
const String _linkKey = "custom.score_banner.link";

Finder _inBanner(Finder matching) {
  return find.descendant(of: find.byType(ScoreBanner), matching: matching);
}

LinearProgressIndicator _indicator(WidgetTester tester) {
  return tester.widget<LinearProgressIndicator>(_inBanner(find.byType(LinearProgressIndicator)));
}

Text _text(WidgetTester tester, String data) => tester.widget<Text>(_inBanner(find.text(data)));

BuildContext _context(WidgetTester tester) => tester.element(find.byType(ScoreBanner));

ToneColors _colors(WidgetTester tester, StatusTone tone) => StatusTones.colorsOf(_context(tester), tone);

/// The banner's own box: the first DecoratedBox under the widget.
BoxDecoration _bannerDecoration(WidgetTester tester) {
  final DecoratedBox box = tester.widget<DecoratedBox>(_inBanner(find.byType(DecoratedBox)).first);
  return box.decoration as BoxDecoration;
}

/// Fill of the circle holding [icon].
Color? _circleColor(WidgetTester tester, IconData icon) {
  final Container circle = tester.widget<Container>(
    find.ancestor(of: _inBanner(find.byIcon(icon)), matching: find.byType(Container)).first,
  );
  return (circle.decoration as BoxDecoration?)?.color;
}

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

ScoreBanner _banner({
  double value = 0.72,
  StatusTone tone = StatusTone.success,
  IconData? icon,
  String? valueLabel,
  ScoreBannerNote? note,
  VoidCallback? onLink,
  String? linkLabel,
}) {
  return ScoreBanner(
    message: _message,
    value: value,
    tone: tone,
    icon: icon,
    valueLabel: valueLabel,
    note: note,
    onLink: onLink,
    linkLabel: linkLabel,
  );
}

Future<void> _pumpBanner(WidgetTester tester, ScoreBanner banner, {ThemeData? theme}) {
  return pumpApp(
    tester,
    Padding(padding: const EdgeInsets.all(kDefaultPadding * 2), child: banner),
    theme: theme,
  );
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
        "score_banner": <String, dynamic>{
          "value": "{value} / 100",
          "value_semantics": fr ? "Score : {value} sur 100" : "Score: {value} out of 100",
          "link": fr ? "Pourquoi ce résultat ?" : "Why this result?",
        },
      },
    };
  }
}

/// Pumps [child] in an app localized with [_MemoryLoader].
///
/// EasyLocalization keeps its translations in a process-wide singleton that
/// outlives the test; the tear-down empties it so every later `.tr()` returns
/// the raw key again, whatever the test order.
Future<void> _pumpLocalized(WidgetTester tester, Locale locale, Widget child) async {
  addTearDown(() => Localization.load(const Locale("fr")));
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
          home: Scaffold(body: Center(child: child)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _noop() {}

void main() {
  group("ScoreBanner content", () {
    testWidgets("shows the message and the default value label", (WidgetTester tester) async {
      await _pumpBanner(tester, _banner());

      expect(_inBanner(find.text(_message)), findsOneWidget);
      expect(_inBanner(find.text(_valueKey)), findsOneWidget);
      expect(_indicator(tester).value, 0.72);
    });

    testWidgets("a custom valueLabel replaces the default", (WidgetTester tester) async {
      await _pumpBanner(tester, _banner(valueLabel: "72 %"));

      expect(_inBanner(find.text("72 %")), findsOneWidget);
      expect(_inBanner(find.text(_valueKey)), findsNothing);
    });

    testWidgets("the message wraps in a narrow banner without overflow", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const SizedBox(
          width: 220,
          child: ScoreBanner(
            message: "A long message that needs several lines to fit in a narrow banner.",
            value: 0.5,
            tone: StatusTone.info,
            note: ScoreBannerNote(label: "A caveat that is also rather long"),
            onLink: _noop,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets("a long valueLabel is cut at half the row, the semantics keep it whole", (WidgetTester tester) async {
      const String longLabel = "Very high: 92 out of 100 on the reference scale";
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const SizedBox(
          width: 220,
          child: ScoreBanner(message: _message, value: 0.92, tone: StatusTone.success, valueLabel: longLabel),
        ),
      );
      final Text text = _text(tester, longLabel);
      final double rowWidth = tester.getSize(find.ancestor(of: find.text(longLabel), matching: find.byType(Row)).first).width;

      expect(tester.takeException(), isNull);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.getSize(find.text(longLabel)).width, lessThanOrEqualTo(rowWidth / 2));
      expect(tester.getSize(find.byType(LinearProgressIndicator)).width, greaterThan(0));
      expect(find.bySemanticsLabel(longLabel), findsOneWidget);
      handle.dispose();
    });
  });

  group("ScoreBanner clamping", () {
    final Map<double, double> cases = <double, double>{
      1.4: 1.0,
      -0.2: 0.0,
      0.42: 0.42,
      double.nan: 0.0,
      double.infinity: 1.0,
    };
    for (final MapEntry<double, double> entry in cases.entries) {
      testWidgets("value ${entry.key} → bar ${entry.value}", (WidgetTester tester) async {
        await _pumpBanner(tester, _banner(value: entry.key));

        expect(_indicator(tester).value, entry.value);
      });
    }
  });

  group("ScoreBanner tone colours", () {
    final Map<String, ThemeData Function()> themes = <String, ThemeData Function()>{
      "light": AppTheme.light,
      "dark": AppTheme.dark,
    };
    for (final MapEntry<String, ThemeData Function()> theme in themes.entries) {
      for (final StatusTone tone in StatusTone.values) {
        testWidgets("${tone.name} (${theme.key})", (WidgetTester tester) async {
          await _pumpBanner(tester, _banner(tone: tone, onLink: () {}), theme: theme.value());
          final ToneColors colors = _colors(tester, tone);
          final LinearProgressIndicator bar = _indicator(tester);
          final Icon glyph = tester.widget<Icon>(_inBanner(find.byIcon(tone.icon)));

          expect(_bannerDecoration(tester).color, colors.container);
          expect(_text(tester, _message).style?.color, colors.onContainer);
          expect(_text(tester, _valueKey).style?.color, colors.onContainer);
          expect(_text(tester, _linkKey).style?.color, colors.onContainer);
          expect(_text(tester, _linkKey).style?.decorationColor, colors.onContainer);
          expect(_circleColor(tester, tone.icon), colors.onContainer);
          expect(glyph.color, colors.container);
          expect(bar.valueColor?.value, colors.onContainer);
          expect(bar.backgroundColor, colors.onContainer.withValues(alpha: 0.18));

          // The track shows on the banner and the fill on both.
          final Color track = Color.alphaBlend(bar.backgroundColor!, colors.container);
          expect(_contrast(track, colors.container), greaterThanOrEqualTo(1.25));
          expect(_contrast(colors.onContainer, track), greaterThanOrEqualTo(3));
          expect(_contrast(colors.onContainer, colors.container), greaterThanOrEqualTo(4.5));
        });
      }
    }

    testWidgets("the bar has radius 999 and is 5 dp thick", (WidgetTester tester) async {
      await _pumpBanner(tester, _banner());
      final ClipRRect clip = tester.widget<ClipRRect>(
        find.ancestor(of: find.byType(LinearProgressIndicator), matching: find.byType(ClipRRect)).first,
      );

      expect(clip.borderRadius, BorderRadius.circular(999));
      expect(_indicator(tester).minHeight, 5);
    });

    testWidgets("the banner has an 8 dp radius", (WidgetTester tester) async {
      await _pumpBanner(tester, _banner());

      expect(_bannerDecoration(tester).borderRadius, BorderRadius.circular(kDefaultPadding));
    });
  });

  group("ScoreBanner icon", () {
    for (final StatusTone tone in StatusTone.values) {
      testWidgets("defaults to the ${tone.name} tone icon", (WidgetTester tester) async {
        await _pumpBanner(tester, _banner(tone: tone));

        expect(_inBanner(find.byIcon(tone.icon)), findsOneWidget);
      });
    }

    testWidgets("an explicit icon overrides the tone icon", (WidgetTester tester) async {
      await _pumpBanner(tester, _banner(tone: StatusTone.success, icon: Icons.star_rounded));

      expect(_inBanner(find.byIcon(Icons.star_rounded)), findsOneWidget);
      expect(_inBanner(find.byIcon(StatusTone.success.icon)), findsNothing);
      expect(_circleColor(tester, Icons.star_rounded), _colors(tester, StatusTone.success).onContainer);
    });
  });

  group("ScoreBanner note", () {
    const String noteLabel = "Moderate reliability";

    testWidgets("no note row when note is null", (WidgetTester tester) async {
      await _pumpBanner(tester, _banner(tone: StatusTone.success));

      expect(_inBanner(find.byIcon(StatusTone.warning.icon)), findsNothing);
      expect(_inBanner(find.byIcon(StatusTone.danger.icon)), findsNothing);
    });

    for (final StatusTone noteTone in <StatusTone>[StatusTone.warning, StatusTone.danger]) {
      testWidgets("a ${noteTone.name} note renders in its own tone", (WidgetTester tester) async {
        await _pumpBanner(
          tester,
          _banner(tone: StatusTone.success, note: ScoreBannerNote(label: noteLabel, tone: noteTone)),
        );
        final ToneColors colors = _colors(tester, noteTone);
        final Icon icon = tester.widget<Icon>(_inBanner(find.byIcon(noteTone.icon)));
        final DecoratedBox pill = tester.widget<DecoratedBox>(
          find.ancestor(of: find.text(noteLabel), matching: find.byType(DecoratedBox)).first,
        );
        final BoxDecoration decoration = pill.decoration as BoxDecoration;

        expect(icon.color, colors.onContainer);
        expect(_text(tester, noteLabel).style?.color, colors.onContainer);
        expect(decoration.color, colors.container);
        expect(decoration.borderRadius, BorderRadius.circular(999));
      });
    }

    test("the note tone defaults to warning", () {
      expect(const ScoreBannerNote(label: noteLabel).tone, StatusTone.warning);
    });
  });

  group("ScoreBanner link", () {
    testWidgets("hidden when onLink is null", (WidgetTester tester) async {
      await _pumpBanner(tester, _banner());

      expect(find.text(_linkKey), findsNothing);
      expect(_inBanner(find.byType(InkWell)), findsNothing);
    });

    testWidgets("tapping the link calls onLink once", (WidgetTester tester) async {
      int taps = 0;
      await _pumpBanner(tester, _banner(onLink: () => taps++));

      await tester.tap(find.text(_linkKey));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets("linkLabel overrides the default label", (WidgetTester tester) async {
      await _pumpBanner(tester, _banner(onLink: () {}, linkLabel: "See details"));

      expect(find.text("See details"), findsOneWidget);
      expect(find.text(_linkKey), findsNothing);
      expect(_text(tester, "See details").style?.decoration, TextDecoration.underline);
    });

    testWidgets("the hit area is at least 48 dp", (WidgetTester tester) async {
      await _pumpBanner(tester, _banner(onLink: () {}, linkLabel: "Go"));
      final Size size = tester.getSize(find.ancestor(of: find.text("Go"), matching: find.byType(InkWell)));

      expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
      expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
    });

    testWidgets("meets the tap target guidelines", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBanner(tester, _banner(onLink: () {}));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets("exposes link and button semantics with a tap action", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBanner(tester, _banner(onLink: () {}));

      expect(
        tester.getSemantics(find.text(_linkKey)),
        isSemantics(label: _linkKey, isLink: true, isButton: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets("works without a Material ancestor", (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Center(child: _banner(onLink: () => taps++)),
        ),
      );

      expect(tester.takeException(), isNull);
      await tester.tap(find.text(_linkKey));
      await tester.pump();
      expect(taps, 1);
    });
  });

  group("ScoreBanner semantics", () {
    testWidgets("exposes the message and the value semantics label once", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBanner(tester, _banner());

      expect(find.bySemanticsLabel(_message), findsOneWidget);
      expect(find.bySemanticsLabel(_valueSemanticsKey), findsOneWidget);
      // The visible value text and the bar are folded into that one node.
      expect(find.bySemanticsLabel(_valueKey), findsNothing);
      handle.dispose();
    });

    testWidgets("a custom valueLabel is the bar's semantics label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBanner(tester, _banner(valueLabel: "7 of 10"));

      expect(find.bySemanticsLabel("7 of 10"), findsOneWidget);
      expect(find.bySemanticsLabel(_valueSemanticsKey), findsNothing);
      handle.dispose();
    });

    testWidgets("the note is one node labelled with its text", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBanner(tester, _banner(note: const ScoreBannerNote(label: "Low reliability")));

      expect(find.bySemanticsLabel("Low reliability"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("the decorative icon circle has no semantics", (WidgetTester tester) async {
      await _pumpBanner(tester, _banner(tone: StatusTone.success));

      expect(
        find.ancestor(of: _inBanner(find.byIcon(StatusTone.success.icon)), matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
    });
  });

  testWidgets("dark theme smoke test with every part", (WidgetTester tester) async {
    await _pumpBanner(
      tester,
      _banner(
        tone: StatusTone.warning,
        note: const ScoreBannerNote(label: "Low reliability", tone: StatusTone.danger),
        onLink: () {},
      ),
      theme: AppTheme.dark(),
    );

    expect(tester.takeException(), isNull);
    expect(_bannerDecoration(tester).color, _colors(tester, StatusTone.warning).container);
    expect(find.text("Low reliability"), findsOneWidget);
    expect(find.text(_linkKey), findsOneWidget);
  });

  group("ScoreBanner real strings", () {
    final Map<Locale, List<String>> expected = <Locale, List<String>>{
      const Locale("fr"): <String>["72 / 100", "Score : 72 sur 100", "Pourquoi ce résultat ?"],
      const Locale("en"): <String>["72 / 100", "Score: 72 out of 100", "Why this result?"],
    };
    for (final MapEntry<Locale, List<String>> entry in expected.entries) {
      testWidgets("${entry.key.languageCode}: value, value semantics and link", (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await _pumpLocalized(
          tester,
          entry.key,
          ScoreBanner(message: _message, value: 0.724, tone: StatusTone.success, onLink: () {}),
        );

        expect(find.text(entry.value[0]), findsOneWidget);
        expect(find.bySemanticsLabel(entry.value[1]), findsOneWidget);
        expect(find.text(entry.value[2]), findsOneWidget);
        handle.dispose();
      });
    }

    final Map<double, String> clamped = <double, String>{1.4: "100 / 100", -0.2: "0 / 100"};
    for (final MapEntry<double, String> entry in clamped.entries) {
      testWidgets("en: the default value text uses the clamped value (${entry.key})", (WidgetTester tester) async {
        await _pumpLocalized(
          tester,
          const Locale("en"),
          ScoreBanner(message: _message, value: entry.key, tone: StatusTone.success),
        );

        expect(find.text(entry.value), findsOneWidget);
      });
    }
  });
}

// qualitative_score_bar_test.dart
//
// Widget tests for QualitativeScoreBar: the resolved label and its absence of
// numbers, the bar fill (clamped) and shared bar tokens, the tone colours of
// the label and the fill, the no-data state (default key, custom label, NaN,
// empty scale), the label style and gap, the single semantics node with and
// without a prefix, rebuilds, the empty-scale error, the dark theme and the
// real fr / en strings.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/QualitativeScoreBar/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _noDataKey = "custom.qualitative_score_bar.no_data";
const String _semanticsKey = "custom.qualitative_score_bar.semantics_label";

const List<ScoreLevel> _scale = <ScoreLevel>[
  ScoreLevel(min: 0.7, label: "Good", tone: StatusTone.success),
  ScoreLevel(min: 0.4, label: "Fair", tone: StatusTone.warning),
  ScoreLevel(min: 0.0, label: "Poor", tone: StatusTone.danger),
];

Finder _inBar(Finder matching) {
  return find.descendant(of: find.byType(QualitativeScoreBar), matching: matching);
}

Text _label(WidgetTester tester) => tester.widget<Text>(_inBar(find.byType(Text)));

LinearProgressIndicator _indicator(WidgetTester tester) {
  return tester.widget<LinearProgressIndicator>(_inBar(find.byType(LinearProgressIndicator)));
}

Color? _fill(WidgetTester tester) {
  final Animation<Color?>? valueColor = _indicator(tester).valueColor;
  return valueColor?.value;
}

BuildContext _context(WidgetTester tester) => tester.element(find.byType(QualitativeScoreBar));

Color _toneForeground(WidgetTester tester, StatusTone tone) {
  return StatusTones.colorsOf(_context(tester), tone).foreground;
}

Future<void> _pumpBar(
  WidgetTester tester, {
  required double? value,
  List<ScoreLevel> levels = _scale,
  String? noDataLabel,
  String? semanticsLabel,
  ThemeData? theme,
}) {
  return pumpApp(
    tester,
    Padding(
      padding: const EdgeInsets.all(kDefaultPadding * 2),
      child: QualitativeScoreBar(
        value: value,
        levels: levels,
        noDataLabel: noDataLabel,
        semanticsLabel: semanticsLabel,
      ),
    ),
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
        "qualitative_score_bar": <String, dynamic>{
          "no_data": fr ? "Données insuffisantes" : "Insufficient data",
          "semantics_label": fr ? "{prefix} : {level}" : "{prefix}: {level}",
        },
      },
    };
  }
}

Future<void> _pumpLocalized(WidgetTester tester, Locale locale, Widget child) async {
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
          home: Scaffold(body: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group("level label", () {
    testWidgets("shows the label of the resolved step", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.9);
      expect(find.text("Good"), findsOneWidget);
      expect(find.text("Fair"), findsNothing);
      expect(find.text("Poor"), findsNothing);
    });

    testWidgets("never shows a number or a percent sign", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.9);
      final Iterable<Text> texts = tester.widgetList<Text>(_inBar(find.byType(Text)));
      expect(texts, hasLength(1));
      for (final Text text in texts) {
        expect(text.data, isNot(matches(RegExp("[0-9%]"))));
      }
    });

    testWidgets("a value on a boundary takes that step, just below takes the lower one", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.7);
      expect(find.text("Good"), findsOneWidget);

      await _pumpBar(tester, value: 0.6999);
      expect(find.text("Fair"), findsOneWidget);
    });

    testWidgets("the scale may be given in any order", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.5, levels: _scale.reversed.toList());
      expect(find.text("Fair"), findsOneWidget);
    });

    testWidgets("a value below every step shows the lowest step", (WidgetTester tester) async {
      await _pumpBar(
        tester,
        value: 0.1,
        levels: const <ScoreLevel>[
          ScoreLevel(min: 0.5, label: "Upper", tone: StatusTone.success),
          ScoreLevel(min: 0.2, label: "Lower", tone: StatusTone.danger),
        ],
      );
      expect(find.text("Lower"), findsOneWidget);
      expect(_label(tester).style?.color, _toneForeground(tester, StatusTone.danger));
    });

    testWidgets("updates when the value changes", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.9);
      expect(find.text("Good"), findsOneWidget);

      await _pumpBar(tester, value: 0.1);
      expect(find.text("Poor"), findsOneWidget);
      expect(_indicator(tester).value, 0.1);
    });

    testWidgets("label style: titleMedium at 15 sp, w800", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.9);
      final TextStyle? style = _label(tester).style;
      final TextStyle? titleMedium = Theme.of(_context(tester)).textTheme.titleMedium;
      expect(style?.fontSize, 15);
      expect(style?.fontWeight, FontWeight.w800);
      expect(style?.fontFamily, titleMedium?.fontFamily);
    });
  });

  group("tones", () {
    testWidgets("label and fill share the step's tone foreground", (WidgetTester tester) async {
      final Map<double, StatusTone> cases = <double, StatusTone>{
        0.9: StatusTone.success,
        0.5: StatusTone.warning,
        0.2: StatusTone.danger,
      };
      for (final MapEntry<double, StatusTone> entry in cases.entries) {
        await _pumpBar(tester, value: entry.key);
        final Color expected = _toneForeground(tester, entry.value);
        expect(_label(tester).style?.color, expected, reason: "label at ${entry.key}");
        expect(_fill(tester), expected, reason: "fill at ${entry.key}");
      }
    });

    testWidgets("a step without a tone uses the neutral foreground", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.5, levels: const <ScoreLevel>[ScoreLevel(min: 0, label: "Plain")]);
      final Color neutral = Theme.of(_context(tester)).colorScheme.onSurfaceVariant;
      expect(_toneForeground(tester, StatusTone.neutral), neutral);
      expect(_label(tester).style?.color, neutral);
      expect(_fill(tester), neutral);
    });
  });

  group("bar", () {
    testWidgets("fills to the value", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.42);
      expect(_indicator(tester).value, 0.42);
    });

    testWidgets("clamps the fill to [0, 1]", (WidgetTester tester) async {
      await _pumpBar(tester, value: 1.4);
      expect(_indicator(tester).value, 1.0);
      expect(find.text("Good"), findsOneWidget);

      await _pumpBar(tester, value: -0.5);
      expect(_indicator(tester).value, 0.0);
      expect(find.text("Poor"), findsOneWidget);
    });

    testWidgets("uses the shared bar tokens: track, radius 999, 5 dp", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.5);
      final LinearProgressIndicator indicator = _indicator(tester);
      expect(indicator.backgroundColor, Theme.of(_context(tester)).colorScheme.surfaceContainerHighest);
      expect(indicator.minHeight, 5);
      final ClipRRect clip = tester.widget<ClipRRect>(_inBar(find.byType(ClipRRect)));
      expect(clip.borderRadius, BorderRadius.circular(999));
      expect(tester.getSize(_inBar(find.byType(LinearProgressIndicator))).height, 5);
    });

    testWidgets("is determinate and spans the available width", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.5);
      expect(_indicator(tester).value, isNotNull);
      final double barWidth = tester.getSize(_inBar(find.byType(LinearProgressIndicator))).width;
      final double widgetWidth = tester.getSize(find.byType(QualitativeScoreBar)).width;
      expect(barWidth, widgetWidth);
    });

    testWidgets("sits kDefaultPadding below the label", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.5);
      final double labelBottom = tester.getBottomLeft(_inBar(find.byType(Text))).dy;
      final double barTop = tester.getTopLeft(_inBar(find.byType(LinearProgressIndicator))).dy;
      expect(barTop - labelBottom, kDefaultPadding);
    });

    testWidgets("wraps its content vertically", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.5);
      final double height = tester.getSize(find.byType(QualitativeScoreBar)).height;
      final double labelHeight = tester.getSize(_inBar(find.byType(Text))).height;
      expect(height, labelHeight + kDefaultPadding + 5);
    });
  });

  group("no data", () {
    testWidgets("null shows the default key, an empty bar and the neutral tone", (WidgetTester tester) async {
      await _pumpBar(tester, value: null);
      expect(find.text(_noDataKey), findsOneWidget);
      expect(_indicator(tester).value, 0.0);
      final Color neutral = Theme.of(_context(tester)).colorScheme.onSurfaceVariant;
      expect(_label(tester).style?.color, neutral);
      expect(_fill(tester), neutral);
    });

    testWidgets("noDataLabel replaces the default text", (WidgetTester tester) async {
      await _pumpBar(tester, value: null, noDataLabel: "Not rated yet");
      expect(find.text("Not rated yet"), findsOneWidget);
      expect(find.text(_noDataKey), findsNothing);
    });

    testWidgets("noDataLabel is ignored when there is a value", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.9, noDataLabel: "Not rated yet");
      expect(find.text("Good"), findsOneWidget);
      expect(find.text("Not rated yet"), findsNothing);
    });

    testWidgets("NaN is treated as no data", (WidgetTester tester) async {
      await _pumpBar(tester, value: double.nan);
      expect(find.text(_noDataKey), findsOneWidget);
      expect(_indicator(tester).value, 0.0);
    });

    testWidgets("an empty scale is accepted when there is no value", (WidgetTester tester) async {
      await _pumpBar(tester, value: null, levels: const <ScoreLevel>[]);
      expect(tester.takeException(), isNull);
      expect(find.text(_noDataKey), findsOneWidget);
    });

    testWidgets("an empty scale with a value is an error", (WidgetTester tester) async {
      await _pumpBar(tester, value: 0.5, levels: const <ScoreLevel>[]);
      expect(tester.takeException(), isArgumentError);
    });
  });

  group("semantics", () {
    testWidgets("one node with the level label and no percentage", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBar(tester, value: 0.9);
      final SemanticsNode node = tester.getSemantics(find.byType(QualitativeScoreBar));
      expect(node.label, "Good");
      expect(node.value, isEmpty);
      expect(node.childrenCount, 0);
      expect(find.bySemanticsLabel(RegExp("[0-9%]")), findsNothing);
      handle.dispose();
    });

    testWidgets("semanticsLabel prefixes the level through the i18n key", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBar(tester, value: 0.9, semanticsLabel: "Quality");
      expect(tester.getSemantics(find.byType(QualitativeScoreBar)).label, _semanticsKey);
      handle.dispose();
    });

    testWidgets("an empty semanticsLabel is ignored", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBar(tester, value: 0.5, semanticsLabel: "");
      expect(tester.getSemantics(find.byType(QualitativeScoreBar)).label, "Fair");
      handle.dispose();
    });

    testWidgets("the no-data state is announced", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBar(tester, value: null, noDataLabel: "Not rated yet");
      expect(tester.getSemantics(find.byType(QualitativeScoreBar)).label, "Not rated yet");
      handle.dispose();
    });
  });

  group("localized", () {
    const Widget bar = QualitativeScoreBar(value: 0.9, levels: _scale, semanticsLabel: "Quality");
    const Widget empty = QualitativeScoreBar(value: null, levels: _scale);

    testWidgets("fr strings", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(tester, const Locale("fr"), const Column(children: <Widget>[bar, empty]));
      expect(find.bySemanticsLabel("Quality : Good"), findsOneWidget);
      expect(find.text("Données insuffisantes"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("en strings", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(tester, const Locale("en"), const Column(children: <Widget>[bar, empty]));
      expect(find.bySemanticsLabel("Quality: Good"), findsOneWidget);
      expect(find.text("Insufficient data"), findsOneWidget);
      handle.dispose();
    });
  });

  testWidgets("renders under the dark theme with the dark tokens", (WidgetTester tester) async {
    await _pumpBar(tester, value: 0.9, theme: AppTheme.dark());
    expect(tester.takeException(), isNull);
    final ThemeData theme = Theme.of(_context(tester));
    expect(theme.brightness, Brightness.dark);
    expect(_indicator(tester).backgroundColor, theme.colorScheme.surfaceContainerHighest);
    final Color success = _toneForeground(tester, StatusTone.success);
    expect(success, StatusTones.fromScheme(theme.colorScheme).success.foreground);
    expect(_label(tester).style?.color, success);
    expect(_fill(tester), success);
  });
}

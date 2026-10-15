// comparison_bar_test.dart
//
// Widget tests for ComparisonBar: label and sublabel (two-line cap), the
// changed and unchanged readouts (fallback template under pumpApp, real fr /
// en templates through an in-memory EasyLocalization), unchanged decided on
// raw values, the gradient segment, dot positions, lowerIsBetter, clamping,
// the direction tone of the connector and its tone icon, default and custom
// colours, the single semantics node, a translated template in another
// order, the max > min assert, the scaled-down readout and the dark theme.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/ComparisonBar/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _betterKey = "custom.comparison_bar.semantics_better";
const String _worseKey = "custom.comparison_bar.semantics_worse";
const String _unchangedKey = "custom.comparison_bar.semantics_unchanged";

/// Surface of the positional tests: track width = 400 - 108 - 8 - 8 - 80.
const Size _surface = Size(400, 200);
const double _trackWidth = 196;

String _percent(double value) => "${value.toStringAsFixed(0)}%";

ComparisonBar _bar({
  double baseline = 62,
  double comparison = 78,
  double max = 100,
  String? sublabel,
  bool lowerIsBetter = false,
  Color? baselineColor,
  Color? comparisonColor,
}) {
  return ComparisonBar(
    label: "Throughput",
    sublabel: sublabel,
    baselineValue: baseline,
    comparisonValue: comparison,
    max: max,
    lowerIsBetter: lowerIsBetter,
    formatValue: _percent,
    baselineColor: baselineColor,
    comparisonColor: comparisonColor,
  );
}

ComparisonBar _barWithLabels(String label, String sublabel) {
  return ComparisonBar(
    label: label,
    sublabel: sublabel,
    baselineValue: 62,
    comparisonValue: 78,
    max: 100,
    formatValue: _percent,
  );
}

Future<void> _pumpBar(WidgetTester tester, ComparisonBar bar, {Size surfaceSize = _surface, ThemeData? theme}) {
  return pumpApp(
    tester,
    Align(alignment: Alignment.topLeft, child: bar),
    surfaceSize: surfaceSize,
    theme: theme,
  );
}

Finder _inBar(Finder matching) {
  return find.descendant(of: find.byType(ComparisonBar), matching: matching);
}

BuildContext _context(WidgetTester tester) => tester.element(find.byType(ComparisonBar));

ColorScheme _scheme(WidgetTester tester) => Theme.of(_context(tester)).colorScheme;

BoxDecoration? _decorationOf(Widget widget) {
  if (widget is! DecoratedBox) return null;
  final Decoration decoration = widget.decoration;
  return decoration is BoxDecoration ? decoration : null;
}

/// The ringed dot filled with [color].
Finder _dot(Color color) {
  return _inBar(
    find.byWidgetPredicate((Widget widget) {
      final BoxDecoration? decoration = _decorationOf(widget);
      return decoration?.shape == BoxShape.circle && decoration?.color == color;
    }),
  );
}

/// The gradient segment between the dots.
Finder get _segment {
  return _inBar(find.byWidgetPredicate((Widget widget) => _decorationOf(widget)?.gradient != null));
}

/// The full-width track.
Finder _track(Color color) {
  return _inBar(
    find.byWidgetPredicate((Widget widget) {
      final BoxDecoration? decoration = _decorationOf(widget);
      return decoration?.shape == BoxShape.rectangle && decoration?.color == color;
    }),
  );
}

/// The direction icon of [tone] after the readout.
Finder _toneIcon(StatusTone tone) => _inBar(find.byIcon(tone.icon));

/// Colour of the direction icon of [tone].
Color? _toneIconColor(WidgetTester tester, StatusTone tone) => tester.widget<Icon>(_toneIcon(tone)).color;

/// Colour of the ring around the dot found by [dot].
Color? _ringColor(WidgetTester tester, Finder dot) {
  final BoxBorder? border = _decorationOf(tester.widget(dot))?.border;
  return border is Border ? border.top.color : null;
}

List<Color> _gradientColors(WidgetTester tester) {
  final BoxDecoration? decoration = _decorationOf(tester.widget(_segment));
  final Gradient? gradient = decoration?.gradient;
  return gradient is LinearGradient ? gradient.colors : const <Color>[];
}

/// The readout spans, in order.
List<TextSpan> _readoutSpans(WidgetTester tester) {
  final Text text = tester.widget<Text>(
    _inBar(find.byWidgetPredicate((Widget widget) => widget is Text && widget.textSpan != null)),
  );
  final InlineSpan? root = text.textSpan;
  final List<InlineSpan> children = root is TextSpan ? root.children ?? const <InlineSpan>[] : const <InlineSpan>[];
  return children.whereType<TextSpan>().toList();
}

TextSpan _spanWithText(WidgetTester tester, String text) {
  return _readoutSpans(tester).firstWhere((TextSpan span) => span.text == text);
}

/// Style of the readout span showing [text].
TextStyle _spanStyle(WidgetTester tester, String text) {
  return _spanWithText(tester, text).style ?? const TextStyle();
}

/// Style of a plain [Text] showing [text].
TextStyle _textStyle(WidgetTester tester, String text) {
  return tester.widget<Text>(find.text(text)).style ?? const TextStyle();
}

/// In-memory translations matching the widget's i18n fragment, so the real
/// strings can be checked before the fragment is merged into assets.
/// [readout] replaces the changed template, to prove the view reads the key.
final class _MemoryLoader extends AssetLoader {
  const _MemoryLoader({this.readout = "{baseline} → {comparison}"});

  final String readout;

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final bool fr = locale.languageCode == "fr";
    return <String, dynamic>{
      "custom": <String, dynamic>{
        "comparison_bar": <String, dynamic>{
          "readout": readout,
          "readout_unchanged": "{value} =",
          "semantics_better": fr
              ? "{label} : de {from} à {to}, en amélioration"
              : "{label}: from {from} to {to}, better",
          "semantics_worse": fr
              ? "{label} : de {from} à {to}, en dégradation"
              : "{label}: from {from} to {to}, worse",
          "semantics_unchanged": fr ? "{label} : {value}, inchangé" : "{label}: {value}, unchanged",
        },
      },
    };
  }
}

Future<void> _pumpLocalized(
  WidgetTester tester,
  Locale locale,
  Widget child, {
  AssetLoader loader = const _MemoryLoader(),
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const <Locale>[Locale("fr"), Locale("en")],
      path: "memory",
      fallbackLocale: const Locale("fr"),
      startLocale: locale,
      saveLocale: false,
      assetLoader: loader,
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
  group("labels", () {
    testWidgets("renders the label without a sublabel", (WidgetTester tester) async {
      await _pumpBar(tester, _bar());

      expect(find.text("Throughput"), findsOneWidget);
      expect(_inBar(find.byType(Text)), findsNWidgets(2));
    });

    testWidgets("renders the sublabel under the label", (WidgetTester tester) async {
      await _pumpBar(tester, _bar(sublabel: "per hour"));

      expect(find.text("Throughput"), findsOneWidget);
      expect(find.text("per hour"), findsOneWidget);
      expect(tester.getTopLeft(find.text("per hour")).dy, greaterThan(tester.getTopLeft(find.text("Throughput")).dy));
    });

    testWidgets("uses onSurface / onSurfaceVariant and the original weights", (WidgetTester tester) async {
      await _pumpBar(tester, _bar(sublabel: "per hour"));
      final ColorScheme cs = _scheme(tester);

      final TextStyle label = _textStyle(tester, "Throughput");
      final TextStyle sublabel = _textStyle(tester, "per hour");
      expect(label.color, cs.onSurface);
      expect(label.fontWeight, FontWeight.w700);
      expect(sublabel.color, cs.onSurfaceVariant);
      expect(sublabel.fontWeight, FontWeight.w600);
    });
  });

  group("changed readout", () {
    testWidgets("shows baseline → comparison with a gradient segment", (WidgetTester tester) async {
      await _pumpBar(tester, _bar());

      expect(find.text("62% → 78%"), findsOneWidget);
      expect(find.textContaining("="), findsNothing);
      expect(_segment, findsOneWidget);
    });

    testWidgets("colours the connector with the success tone when better", (WidgetTester tester) async {
      await _pumpBar(tester, _bar());

      expect(
        _spanStyle(tester, " → ").color,
        StatusTones.colorsOf(_context(tester), StatusTone.success).foreground,
      );
    });

    testWidgets("colours the connector with the danger tone when worse", (WidgetTester tester) async {
      await _pumpBar(tester, _bar(baseline: 78, comparison: 55));

      expect(find.text("78% → 55%"), findsOneWidget);
      expect(
        _spanStyle(tester, " → ").color,
        StatusTones.colorsOf(_context(tester), StatusTone.danger).foreground,
      );
    });

    testWidgets("follows the readout with the success icon when better", (WidgetTester tester) async {
      await _pumpBar(tester, _bar());

      expect(_toneIcon(StatusTone.success), findsOneWidget);
      expect(_toneIcon(StatusTone.danger), findsNothing);
      expect(
        _toneIconColor(tester, StatusTone.success),
        StatusTones.colorsOf(_context(tester), StatusTone.success).foreground,
      );
      expect(
        tester.getRect(_toneIcon(StatusTone.success)).left,
        greaterThanOrEqualTo(tester.getRect(find.text("62% → 78%")).right),
      );
    });

    testWidgets("shows the danger icon instead when worse", (WidgetTester tester) async {
      await _pumpBar(tester, _bar(baseline: 78, comparison: 55));

      expect(_toneIcon(StatusTone.danger), findsOneWidget);
      expect(_toneIcon(StatusTone.success), findsNothing);
      expect(
        _toneIconColor(tester, StatusTone.danger),
        StatusTones.colorsOf(_context(tester), StatusTone.danger).foreground,
      );
    });

    testWidgets("styles the values with their dot colours and weights", (WidgetTester tester) async {
      await _pumpBar(tester, _bar());
      final ColorScheme cs = _scheme(tester);

      final TextStyle baseline = _spanStyle(tester, "62%");
      final TextStyle comparison = _spanStyle(tester, "78%");
      expect(baseline.color, cs.onSurfaceVariant);
      expect(baseline.fontWeight, FontWeight.w700);
      expect(comparison.color, cs.primary);
      expect(comparison.fontWeight, FontWeight.w800);
    });
  });

  group("unchanged readout", () {
    testWidgets("shows value = and no segment for equal values", (WidgetTester tester) async {
      await _pumpBar(tester, _bar(baseline: 70, comparison: 70));

      expect(find.text("70% ="), findsOneWidget);
      expect(find.textContaining("→"), findsNothing);
      expect(_segment, findsNothing);
      expect(_spanStyle(tester, " =").fontStyle, FontStyle.italic);
      expect(_spanStyle(tester, " =").color, _scheme(tester).onSurfaceVariant);
      expect(_inBar(find.byType(Icon)), findsNothing);
    });

    testWidgets("treats values within 0.5 % of the range as unchanged", (WidgetTester tester) async {
      await _pumpBar(tester, _bar(baseline: 70, comparison: 70.3));

      expect(find.text("70% ="), findsOneWidget);
      expect(_segment, findsNothing);
    });

    testWidgets("treats a 1 % gap as a change", (WidgetTester tester) async {
      await _pumpBar(tester, _bar(baseline: 70, comparison: 71));

      expect(find.text("70% → 71%"), findsOneWidget);
      expect(_segment, findsOneWidget);
    });

    testWidgets("decides on the raw values when both dots clamp to the same end", (WidgetTester tester) async {
      await _pumpBar(tester, _bar(baseline: 150, comparison: 200));
      final ColorScheme cs = _scheme(tester);

      expect(tester.getCenter(_dot(cs.onSurfaceVariant)).dx, moreOrLessEquals(tester.getCenter(_dot(cs.primary)).dx));
      expect(find.text("150% → 200%"), findsOneWidget);
      expect(find.textContaining("="), findsNothing);
      expect(
        _spanStyle(tester, " → ").color,
        StatusTones.colorsOf(_context(tester), StatusTone.success).foreground,
      );
      expect(_toneIcon(StatusTone.success), findsOneWidget);
    });

    testWidgets("reads a lower raw value as better when both clamp with lowerIsBetter", (WidgetTester tester) async {
      await _pumpBar(tester, _bar(baseline: 150, comparison: 120, lowerIsBetter: true));
      final ColorScheme cs = _scheme(tester);
      final Rect track = tester.getRect(_track(cs.surfaceContainerHighest));

      expect(tester.getCenter(_dot(cs.onSurfaceVariant)).dx, moreOrLessEquals(track.left));
      expect(tester.getCenter(_dot(cs.primary)).dx, moreOrLessEquals(track.left));
      expect(find.text("150% → 120%"), findsOneWidget);
      expect(
        _spanStyle(tester, " → ").color,
        StatusTones.colorsOf(_context(tester), StatusTone.success).foreground,
      );
      expect(_toneIcon(StatusTone.success), findsOneWidget);
    });
  });

  group("track", () {
    testWidgets("places the dots in proportion on the track", (WidgetTester tester) async {
      await _pumpBar(tester, _bar(baseline: 25, comparison: 75));
      final ColorScheme cs = _scheme(tester);
      final Rect track = tester.getRect(_track(cs.surfaceContainerHighest));

      expect(track.width, moreOrLessEquals(_trackWidth));
      expect(tester.getCenter(_dot(cs.onSurfaceVariant)).dx, moreOrLessEquals(track.left + track.width * 0.25));
      expect(tester.getCenter(_dot(cs.primary)).dx, moreOrLessEquals(track.left + track.width * 0.75));
      expect(tester.getRect(_segment).left, moreOrLessEquals(track.left + track.width * 0.25));
      expect(tester.getRect(_segment).right, moreOrLessEquals(track.left + track.width * 0.75));
    });

    testWidgets("runs the gradient from the left dot colour to the right one", (WidgetTester tester) async {
      await _pumpBar(tester, _bar(baseline: 78, comparison: 55));
      final ColorScheme cs = _scheme(tester);

      expect(_gradientColors(tester), <Color>[cs.primary, cs.onSurfaceVariant]);
    });

    testWidgets("lowerIsBetter flips the axis and the tone", (WidgetTester tester) async {
      await _pumpBar(tester, _bar(baseline: 4, comparison: 2, max: 12, lowerIsBetter: true));
      final ColorScheme cs = _scheme(tester);
      final Rect track = tester.getRect(_track(cs.surfaceContainerHighest));

      final double baselineX = tester.getCenter(_dot(cs.onSurfaceVariant)).dx;
      final double comparisonX = tester.getCenter(_dot(cs.primary)).dx;
      expect(comparisonX, greaterThan(baselineX));
      expect(baselineX, moreOrLessEquals(track.left + track.width * (1 - 4 / 12)));
      expect(comparisonX, moreOrLessEquals(track.left + track.width * (1 - 2 / 12)));
      expect(_gradientColors(tester), <Color>[cs.onSurfaceVariant, cs.primary]);
      expect(
        _spanStyle(tester, " → ").color,
        StatusTones.colorsOf(_context(tester), StatusTone.success).foreground,
      );
      expect(_toneIcon(StatusTone.success), findsOneWidget);
    });

    testWidgets("without lowerIsBetter a lower comparison sits left and reads worse", (WidgetTester tester) async {
      await _pumpBar(tester, _bar(baseline: 4, comparison: 2, max: 12));
      final ColorScheme cs = _scheme(tester);

      expect(tester.getCenter(_dot(cs.primary)).dx, lessThan(tester.getCenter(_dot(cs.onSurfaceVariant)).dx));
      expect(
        _spanStyle(tester, " → ").color,
        StatusTones.colorsOf(_context(tester), StatusTone.danger).foreground,
      );
      expect(_toneIcon(StatusTone.danger), findsOneWidget);
    });

    testWidgets("clamps the dot but shows the raw value", (WidgetTester tester) async {
      await _pumpBar(tester, _bar(baseline: 50, comparison: 150));
      final ColorScheme cs = _scheme(tester);
      final Rect track = tester.getRect(_track(cs.surfaceContainerHighest));

      expect(tester.getCenter(_dot(cs.primary)).dx, moreOrLessEquals(track.right));
      expect(find.text("50% → 150%"), findsOneWidget);
    });

    testWidgets("rings the dots with cs.surface", (WidgetTester tester) async {
      await _pumpBar(tester, _bar());
      final ColorScheme cs = _scheme(tester);

      expect(_ringColor(tester, _dot(cs.primary)), cs.surface);
      expect(tester.getSize(_dot(cs.primary)), const Size.square(10));
    });
  });

  group("colours", () {
    testWidgets("custom colours override dots, gradient and values", (WidgetTester tester) async {
      final ColorScheme light = AppTheme.light().colorScheme;
      await _pumpBar(tester, _bar(baselineColor: light.secondary, comparisonColor: light.error));

      expect(_dot(light.secondary), findsOneWidget);
      expect(_dot(light.error), findsOneWidget);
      expect(_gradientColors(tester), <Color>[light.secondary, light.error]);
      expect(_spanStyle(tester, "62%").color, light.secondary);
      expect(_spanStyle(tester, "78%").color, light.error);
    });
  });

  group("semantics", () {
    testWidgets("exposes one better summary node and hides the glyphs", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBar(tester, _bar());

      expect(find.bySemanticsLabel(_betterKey), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp("→")), findsNothing);
      expect(find.bySemanticsLabel("Throughput"), findsNothing);
      handle.dispose();
    });

    testWidgets("uses the worse key when the comparison is worse", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBar(tester, _bar(baseline: 78, comparison: 55));

      expect(find.bySemanticsLabel(_worseKey), findsOneWidget);
      handle.dispose();
    });

    testWidgets("uses the unchanged key for equal values", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBar(tester, _bar(baseline: 70, comparison: 70));

      expect(find.bySemanticsLabel(_unchangedKey), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp("=")), findsNothing);
      handle.dispose();
    });
  });

  group("constraints", () {
    test("asserts max > min", () {
      expect(
        () => ComparisonBar(label: "x", baselineValue: 1, comparisonValue: 2, min: 5, max: 5, formatValue: _percent),
        throwsAssertionError,
      );
    });

    testWidgets("scales a long readout and its icon down into the value column", (WidgetTester tester) async {
      const String readoutText = "1234567 units → 7654321 units";
      await _pumpBar(
        tester,
        ComparisonBar(
          label: "Throughput",
          baselineValue: 1234567,
          comparisonValue: 7654321,
          max: 10000000,
          formatValue: (double value) => "${value.toStringAsFixed(0)} units",
        ),
        surfaceSize: const Size(240, 200),
      );

      expect(tester.takeException(), isNull);
      final Finder readout = find.text(readoutText);
      final Rect icon = tester.getRect(_toneIcon(StatusTone.success));
      // The paragraph is laid out unscaled, wider than the 80 dp column…
      expect(tester.getSize(readout).width, greaterThan(80));
      // …and painted scaled down inside it, icon included.
      expect(tester.getRect(readout).width, lessThan(80));
      expect(tester.getRect(readout).left, greaterThanOrEqualTo(240 - 80));
      expect(icon.right, lessThanOrEqualTo(240));
    });

    testWidgets("caps the label and the sublabel at two lines with an ellipsis", (WidgetTester tester) async {
      const String longLabel = "A rather long label that needs more than two lines to be shown in full";
      const String longSublabel = "with a long second line as well, long enough to need a third line";
      await _pumpBar(tester, _barWithLabels(longLabel, longSublabel), surfaceSize: const Size(240, 200));

      expect(tester.takeException(), isNull);
      for (final String text in <String>[longLabel, longSublabel]) {
        final Text widget = tester.widget<Text>(find.text(text));
        expect(widget.maxLines, 2, reason: text);
        expect(widget.overflow, TextOverflow.ellipsis, reason: text);
        expect(tester.renderObject<RenderParagraph>(find.text(text)).didExceedMaxLines, isTrue, reason: text);
      }
    });

    testWidgets("renders under the dark theme", (WidgetTester tester) async {
      await _pumpBar(tester, _bar(sublabel: "per hour"), theme: AppTheme.dark());
      final ColorScheme cs = _scheme(tester);

      expect(tester.takeException(), isNull);
      expect(cs.brightness, Brightness.dark);
      expect(_dot(cs.primary), findsOneWidget);
      expect(
        _spanStyle(tester, " → ").color,
        StatusTones.colorsOf(_context(tester), StatusTone.success).foreground,
      );
      expect(
        _toneIconColor(tester, StatusTone.success),
        StatusTones.colorsOf(_context(tester), StatusTone.success).foreground,
      );
    });
  });

  // Last: EasyLocalization keeps the loaded translations in a singleton, so
  // pumpApp tests that follow would read them instead of the raw keys.
  group("localized", () {
    Widget bar({double comparison = 78, String? sublabel}) {
      return ComparisonBar(
        label: "Throughput",
        sublabel: sublabel,
        baselineValue: 62,
        comparisonValue: comparison,
        max: 100,
        formatValue: _percent,
      );
    }

    testWidgets("reads the fr summary and renders the fr template", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(tester, const Locale("fr"), bar(sublabel: "par heure"));

      expect(find.text("62% → 78%"), findsOneWidget);
      expect(find.bySemanticsLabel("Throughput (par heure) : de 62% à 78%, en amélioration"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("reads the en summaries", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(tester, const Locale("en"), bar(comparison: 40));

      expect(find.bySemanticsLabel("Throughput: from 62% to 40%, worse"), findsOneWidget);

      await _pumpLocalized(tester, const Locale("en"), bar(comparison: 62));
      expect(find.text("62% ="), findsOneWidget);
      expect(find.bySemanticsLabel("Throughput: 62%, unchanged"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("styles the runs of a translated template", (WidgetTester tester) async {
      await _pumpLocalized(
        tester,
        const Locale("en"),
        bar(),
        loader: const _MemoryLoader(readout: "{comparison} vs {baseline}"),
      );

      expect(find.text("78% vs 62%"), findsOneWidget);
      expect(_spanStyle(tester, "78%").color, _scheme(tester).primary);
      expect(
        _spanStyle(tester, " vs ").color,
        StatusTones.colorsOf(_context(tester), StatusTone.success).foreground,
      );
    });
  });
}

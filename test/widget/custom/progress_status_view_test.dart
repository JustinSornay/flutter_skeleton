// progress_status_view_test.dart
//
// Widget tests for ProgressStatusView: the shared ring / bar value and the
// locale-aware percentage, clamping, the percentage fitting inside the ring
// at 2x text scale, the title / subtitle, the details pill (empty entries
// skipped), the optional Cancel button and its tap target, the semantics (one
// progress node, live-region step text), colours and text styles, layout
// (narrow, wide, short) and the dark theme.

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/ProgressStatusView/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:intl/intl.dart";

import "../../helpers/widget_test_helpers.dart";

const String _title = "Building the export…";
const String _subtitle = "Collecting rows";
const String _cancelKey = "custom.progress_status_view.cancel";

Finder _inView(Finder matching) {
  return find.descendant(of: find.byType(ProgressStatusView), matching: matching);
}

CircularProgressIndicator _ring(WidgetTester tester) {
  return tester.widget<CircularProgressIndicator>(_inView(find.byType(CircularProgressIndicator)));
}

LinearProgressIndicator _bar(WidgetTester tester) {
  return tester.widget<LinearProgressIndicator>(_inView(find.byType(LinearProgressIndicator)));
}

/// The details pill: the only bordered Container in the view.
final Finder _pill = _inView(
  find.byWidgetPredicate((Widget widget) {
    final Decoration? decoration = widget is Container ? widget.decoration : null;
    return decoration is BoxDecoration && decoration.border != null;
  }),
);

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(ProgressStatusView))).colorScheme;
}

Future<void> _pump(
  WidgetTester tester, {
  double progress = 0.45,
  String? subtitle = _subtitle,
  List<String> details = const <String>[],
  VoidCallback? onCancel,
  Size? surfaceSize,
  ThemeData? theme,
}) {
  return pumpApp(
    tester,
    ProgressStatusView(
      progress: progress,
      title: _title,
      subtitle: subtitle,
      details: details,
      onCancel: onCancel,
    ),
    surfaceSize: surfaceSize,
    theme: theme,
  );
}

/// Pumps a full (100 %) view in [lang] at 2x text scale and checks that the
/// percentage is laid out on one line at its full width (neither wrapped nor
/// cut) and drawn, after scaling, inside the ring: within its box inset by
/// twice the 6 dp stroke, every corner inside the inner circle.
Future<void> _expectFullPercentFitsRing(WidgetTester tester, String lang) async {
  await pumpApp(
    tester,
    Builder(
      builder: (BuildContext context) => Localizations.override(
        context: context,
        locale: Locale(lang),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
          child: const ProgressStatusView(progress: 1, title: _title),
        ),
      ),
    ),
  );
  expect(tester.takeException(), isNull);

  final Finder percent = _inView(find.text(NumberFormat.percentPattern(lang).format(1)));
  expect(percent, findsOneWidget);
  final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(percent);
  expect(paragraph.didExceedMaxLines, isFalse);
  expect(paragraph.size.width, closeTo(paragraph.getMaxIntrinsicWidth(double.infinity), 0.01));

  final Rect ring = tester.getRect(_inView(find.byType(CircularProgressIndicator)));
  final Rect inner = ring.deflate(6 * 2);
  final Rect text = tester.getRect(percent);
  expect(text.left, greaterThanOrEqualTo(inner.left - 0.01));
  expect(text.top, greaterThanOrEqualTo(inner.top - 0.01));
  expect(text.right, lessThanOrEqualTo(inner.right + 0.01));
  expect(text.bottom, lessThanOrEqualTo(inner.bottom + 0.01));
  for (final Offset corner in <Offset>[text.topLeft, text.topRight, text.bottomLeft, text.bottomRight]) {
    expect((corner - ring.center).distance, lessThanOrEqualTo(ring.width / 2 - 6));
  }
}

/// Checks the Cancel button's colours, label style (`labelLarge`, w600) and
/// 8 dp radius.
void _expectCancelStyle(WidgetTester tester, ColorScheme cs) {
  final ButtonStyle? style = tester.widget<OutlinedButton>(find.byType(OutlinedButton)).style;
  expect(style?.foregroundColor?.resolve(<WidgetState>{}), cs.onSurfaceVariant);
  expect(style?.side?.resolve(<WidgetState>{}), BorderSide(color: cs.outline));
  final TextStyle? label = style?.textStyle?.resolve(<WidgetState>{});
  expect(label?.fontWeight, FontWeight.w600);
  expect(label?.fontSize, Theme.of(tester.element(find.byType(OutlinedButton))).textTheme.labelLarge?.fontSize);
  expect(
    style?.shape?.resolve(<WidgetState>{}),
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}

void main() {
  group("progress", () {
    testWidgets("ring and bar share the value; the percentage is centred in the ring", (WidgetTester tester) async {
      await _pump(tester);

      expect(_ring(tester).value, 0.45);
      expect(_bar(tester).value, 0.45);
      expect(_inView(find.text("45%")), findsOneWidget);
      expect(tester.getCenter(find.text("45%")), tester.getCenter(find.byType(CircularProgressIndicator)));
      expect(tester.getSize(find.byType(CircularProgressIndicator)), const Size.square(96));
    });

    testWidgets("rounds the percentage and updates on rebuild", (WidgetTester tester) async {
      await _pump(tester, progress: 0.456);
      expect(_inView(find.text("46%")), findsOneWidget);

      await _pump(tester, progress: 0.9);
      expect(_inView(find.text("90%")), findsOneWidget);
      expect(_inView(find.text("46%")), findsNothing);
      expect(_ring(tester).value, 0.9);
      expect(_bar(tester).value, 0.9);
    });

    testWidgets("clamps below 0, above 1 and NaN", (WidgetTester tester) async {
      await _pump(tester, progress: -0.2);
      expect(_ring(tester).value, 0.0);
      expect(_bar(tester).value, 0.0);
      expect(_inView(find.text("0%")), findsOneWidget);

      await _pump(tester, progress: 1.7);
      expect(_ring(tester).value, 1.0);
      expect(_bar(tester).value, 1.0);
      expect(_inView(find.text("100%")), findsOneWidget);

      await _pump(tester, progress: double.nan);
      expect(_ring(tester).value, 0.0);
      expect(_inView(find.text("0%")), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("formats the percentage for the ambient locale", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => Localizations.override(
            context: context,
            locale: const Locale("fr"),
            child: const ProgressStatusView(progress: 0.45, title: _title),
          ),
        ),
      );

      final String expected = NumberFormat.percentPattern("fr").format(0.45);
      expect(expected, isNot("45%"));
      expect(expected, contains("45"));
      expect(_inView(find.text(expected)), findsOneWidget);
    });

    for (final String lang in <String>["en", "fr"]) {
      testWidgets("at 2x text scale the 100 % text stays on one line inside the ring ($lang)", (
        WidgetTester tester,
      ) {
        return _expectFullPercentFitsRing(tester, lang);
      });
    }

    testWidgets("is not animated: pumpAndSettle completes", (WidgetTester tester) async {
      await _pump(tester);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group("title and subtitle", () {
    testWidgets("renders both, title above subtitle", (WidgetTester tester) async {
      await _pump(tester);

      expect(_inView(find.text(_title)), findsOneWidget);
      expect(_inView(find.text(_subtitle)), findsOneWidget);
      expect(
        tester.getBottomLeft(find.text(_title)).dy,
        lessThan(tester.getTopLeft(find.text(_subtitle)).dy),
      );
      expect(
        tester.getBottomLeft(find.text(_subtitle)).dy,
        lessThan(tester.getTopLeft(find.byType(LinearProgressIndicator)).dy),
      );
    });

    testWidgets("a null or empty subtitle renders no Text", (WidgetTester tester) async {
      await _pump(tester, subtitle: null);
      // Percentage + title only.
      expect(_inView(find.byType(Text)), findsNWidgets(2));

      await _pump(tester, subtitle: "");
      expect(_inView(find.byType(Text)), findsNWidgets(2));
    });
  });

  group("details pill", () {
    testWidgets("joins the entries with a middle dot in one Text", (WidgetTester tester) async {
      await _pump(tester, details: const <String>["A", "B", "C"]);

      expect(_pill, findsOneWidget);
      expect(find.descendant(of: _pill, matching: find.text("A · B · C")), findsOneWidget);
      expect(
        tester.getBottomLeft(find.byType(LinearProgressIndicator)).dy,
        lessThan(tester.getTopLeft(_pill).dy),
      );
    });

    testWidgets("a single entry still shows the pill", (WidgetTester tester) async {
      await _pump(tester, details: const <String>["12 items"]);

      expect(_pill, findsOneWidget);
      expect(find.descendant(of: _pill, matching: find.text("12 items")), findsOneWidget);
    });

    testWidgets("an empty list shows no pill", (WidgetTester tester) async {
      await _pump(tester);
      expect(_pill, findsNothing);
    });

    testWidgets("skips empty entries; only empty entries show no pill", (WidgetTester tester) async {
      await _pump(tester, details: const <String>["A", "", "B", ""]);
      expect(_pill, findsOneWidget);
      expect(find.descendant(of: _pill, matching: find.text("A · B")), findsOneWidget);

      await _pump(tester, details: const <String>[""]);
      expect(_pill, findsNothing);
      // Percentage + title + subtitle only.
      expect(_inView(find.byType(Text)), findsNWidgets(3));
    });
  });

  group("cancel", () {
    testWidgets("tapping the button calls onCancel once", (WidgetTester tester) async {
      int taps = 0;
      await _pump(tester, onCancel: () => taps++);

      expect(find.descendant(of: find.byType(OutlinedButton), matching: find.text(_cancelKey)), findsOneWidget);
      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets("no button when onCancel is null", (WidgetTester tester) async {
      await _pump(tester);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.text(_cancelKey), findsNothing);
    });

    testWidgets("is at least 48 dp and meets the tap-target guidelines", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, onCancel: () {}, details: const <String>["A"]);

      final Size size = tester.getSize(find.byType(OutlinedButton));
      expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
      // The visible surface itself (not only the padded hit area) is 48 dp tall.
      final Finder surface = find.descendant(of: find.byType(OutlinedButton), matching: find.byType(Material));
      expect(tester.getSize(surface).height, greaterThanOrEqualTo(kMinTapTarget));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets("is separated from the bar by kSectionGap without details", (WidgetTester tester) async {
      await _pump(tester, onCancel: () {});
      final double gap = tester.getTopLeft(find.byType(OutlinedButton)).dy -
          tester.getBottomLeft(find.byType(LinearProgressIndicator)).dy;
      expect(gap, kSectionGap);
    });
  });

  group("semantics", () {
    testWidgets("one progress node: label title, value the percentage", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, onCancel: () {});

      expect(find.semantics.byLabel(_title), findsOneWidget);
      expect(
        find.semantics.byPredicate((SemanticsNode node) => node.label == _title && node.value == "45%"),
        findsOneWidget,
      );
      // Neither indicator adds its own progress node.
      expect(find.semantics.byPredicate((SemanticsNode node) => node.value.isNotEmpty), findsOneWidget);
      expect(
        find.semantics.byPredicate(
          (SemanticsNode node) => node.getSemanticsData().role == SemanticsRole.progressBar,
        ),
        findsNothing,
      );
      handle.dispose();
    });

    testWidgets("title and subtitle form one live-region node", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester);

      final SemanticsData data = tester.getSemantics(find.text(_subtitle)).getSemanticsData();
      expect(data.flagsCollection.isLiveRegion, isTrue);
      expect(data.label, "$_title\n$_subtitle");
      expect(
        find.semantics.byPredicate((SemanticsNode node) => node.getSemanticsData().flagsCollection.isLiveRegion),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group("colours and styles", () {
    testWidgets("use ColorScheme tokens", (WidgetTester tester) async {
      await _pump(tester, details: const <String>["A", "B"], onCancel: () {});
      final ColorScheme cs = _scheme(tester);

      expect(_ring(tester).color, cs.primary);
      expect(_ring(tester).backgroundColor, cs.surfaceContainerHighest);
      expect(_ring(tester).strokeWidth, 6);
      expect(_bar(tester).color, cs.primary);
      expect(_bar(tester).backgroundColor, cs.surfaceContainerHighest);
      expect(_bar(tester).minHeight, 6);
      expect(tester.getSize(find.byType(LinearProgressIndicator)).height, 6);
      final Finder clip = _inView(find.byType(ClipRRect));
      expect(tester.widget<ClipRRect>(clip).borderRadius, BorderRadius.circular(999));
      expect(find.descendant(of: clip, matching: find.byType(LinearProgressIndicator)), findsOneWidget);

      final TextStyle? percent = tester.widget<Text>(find.text("45%")).style;
      expect(percent?.color, cs.onSurface);
      expect(percent?.fontWeight, FontWeight.w800);
      final TextStyle? title = tester.widget<Text>(find.text(_title)).style;
      expect(title?.color, cs.onSurface);
      expect(title?.fontWeight, FontWeight.w700);
      expect(tester.widget<Text>(find.text(_subtitle)).style?.color, cs.onSurfaceVariant);

      final BoxDecoration pill = tester.widget<Container>(_pill).decoration! as BoxDecoration;
      expect(pill.color, cs.surfaceContainer);
      expect(pill.border, Border.all(color: cs.outlineVariant));
      expect(pill.borderRadius, BorderRadius.circular(999));
      final TextStyle? pillText = tester.widget<Text>(find.text("A · B")).style;
      expect(pillText?.color, cs.onSurfaceVariant);
      expect(pillText?.fontWeight, FontWeight.w500);

      _expectCancelStyle(tester, cs);
    });

    testWidgets("dark theme smoke test", (WidgetTester tester) async {
      final ThemeData dark = AppTheme.dark();
      await _pump(tester, details: const <String>["A"], onCancel: () {}, theme: dark);
      final ColorScheme cs = _scheme(tester);

      expect(cs.brightness, Brightness.dark);
      expect(_ring(tester).color, dark.colorScheme.primary);
      expect(_bar(tester).backgroundColor, dark.colorScheme.surfaceContainerHighest);
      expect(tester.widget<Text>(find.text(_title)).style?.color, dark.colorScheme.onSurface);
      expect(tester.takeException(), isNull);
    });
  });

  group("layout", () {
    testWidgets("fits a 320 px wide surface with long content", (WidgetTester tester) async {
      await pumpApp(
        tester,
        ProgressStatusView(
          progress: 0.45,
          title: "A rather long step title that has to wrap on a narrow phone screen",
          subtitle: _subtitle,
          details: const <String>["First fact with words", "Second fact with words", "Third fact"],
          onCancel: () {},
        ),
        surfaceSize: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(LinearProgressIndicator)).width, 320 - kDefaultPadding * 8);
    });

    testWidgets("is centred and capped at kContentMaxWidth on a wide surface", (WidgetTester tester) async {
      await _pump(tester, onCancel: () {}, surfaceSize: const Size(1400, 900));

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(LinearProgressIndicator)).width, kContentMaxWidth - kDefaultPadding * 8);
      expect(tester.getCenter(find.byType(LinearProgressIndicator)).dx, 700);
      expect(tester.getCenter(find.byType(CircularProgressIndicator)).dx, 700);
    });

    testWidgets("scrolls without overflow in a short area", (WidgetTester tester) async {
      int taps = 0;
      await _pump(
        tester,
        details: const <String>["A"],
        onCancel: () => taps++,
        surfaceSize: const Size(320, 240),
      );
      expect(tester.takeException(), isNull);

      await tester.dragUntilVisible(
        find.byType(OutlinedButton),
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      );
      await tester.tap(find.byType(OutlinedButton));
      expect(taps, 1);
    });
  });
}

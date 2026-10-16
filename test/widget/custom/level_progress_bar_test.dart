// level_progress_bar_test.dart
//
// Widget tests for LevelProgressBar: the header and label row, the segment
// count and fill colours, label alignment under the segments, the counter
// (shown, hidden, styled runs, how it shares the header row with the label,
// the gap in LTR and RTL), the next-level card (visibility, chips, defaults
// and overrides), the call-to-action (callback, 48 dp, hidden), the summary
// semantics node, the asserts, rebuilds, a narrow layout in light and dark
// themes, and the real counter / semantics strings through an in-memory
// EasyLocalization. The localized tests reset the easy_localization
// singleton, so the raw-key tests pass in any order.

import "package:easy_localization/easy_localization.dart" hide TextDirection;
// Localization.load is the only way to empty the translations singleton that
// EasyLocalization fills; see _pumpLocalized.
// ignore: implementation_imports
import "package:easy_localization/src/localization.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/LevelProgressBar/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const List<String> _levels = <String>["A", "B", "C"];
const String _counterKey = "custom.level_progress_bar.counter";
const String _semanticsKey = "custom.level_progress_bar.semantics";
const String _nextTitleKey = "custom.level_progress_bar.next_title";
const String _nextActionKey = "custom.level_progress_bar.next_action";

/// The 12 dp label–counter gap, plus under 1 dp of slack: the label's width
/// is rounded up when the header reserves it.
final Matcher _gapRange = inInclusiveRange(kDefaultPadding * 1.5, kDefaultPadding * 1.5 + 1);

Finder _inBar(Finder matching) {
  return find.descendant(of: find.byType(LevelProgressBar), matching: matching);
}

Finder _segment(int index) => find.byKey(ValueKey<String>("level_progress_bar.segment.$index"));

Finder _segments() {
  return find.byWidgetPredicate(
    (Widget widget) =>
        widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>).value.startsWith("level_progress_bar.segment."),
  );
}

Color? _segmentColor(WidgetTester tester, int index) {
  final DecoratedBox box = tester.widget<DecoratedBox>(_segment(index));
  return (box.decoration as BoxDecoration).color;
}

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(LevelProgressBar))).colorScheme;
}

/// Style of the label-row [Text] showing [text] (the last match: the header
/// comes first when it shows the same label).
TextStyle _labelStyle(WidgetTester tester, String text) {
  return tester.widget<Text>(_inBar(find.text(text)).last).style ?? const TextStyle();
}

/// The [TextSpan] child of the counter showing exactly [text].
TextSpan _span(WidgetTester tester, String text) {
  final Iterable<Text> rich = tester.widgetList<Text>(_inBar(find.byType(Text))).where(
    (Text widget) => widget.textSpan != null,
  );
  for (final Text widget in rich) {
    final List<InlineSpan> children = (widget.textSpan! as TextSpan).children ?? const <InlineSpan>[];
    for (final InlineSpan child in children) {
      if (child is TextSpan && child.text == text) return child;
    }
  }
  throw StateError("No counter span \"$text\"");
}

/// The paragraph drawn by the [Text] that [text] finds.
RenderParagraph _paragraph(WidgetTester tester, Finder text) {
  return tester.renderObject<RenderParagraph>(find.descendant(of: text, matching: find.byType(RichText)));
}

/// Style of the counter's root span (the plain runs).
TextStyle _counterBaseStyle(WidgetTester tester) {
  final Text widget = tester.widgetList<Text>(_inBar(find.byType(Text))).firstWhere(
    (Text text) => text.textSpan != null,
  );
  return widget.textSpan!.style ?? const TextStyle();
}

Future<void> _pumpBar(
  WidgetTester tester,
  LevelProgressBar bar, {
  ThemeData? theme,
  Size? surfaceSize,
  TextDirection textDirection = TextDirection.ltr,
}) {
  return pumpApp(
    tester,
    Directionality(
      textDirection: textDirection,
      child: Padding(padding: const EdgeInsets.all(kDefaultPadding * 2), child: bar),
    ),
    theme: theme,
    surfaceSize: surfaceSize,
  );
}

/// In-memory translations matching the widget's i18n fragment, so the real
/// strings can be checked before the fragment is merged into assets.
/// [counter] replaces the counter template, to prove the view reads the key.
final class _MemoryLoader extends AssetLoader {
  const _MemoryLoader({this.counter});

  final String? counter;

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final bool fr = locale.languageCode == "fr";
    return <String, dynamic>{
      "custom": <String, dynamic>{
        "level_progress_bar": <String, dynamic>{
          "next_title": fr ? "Au niveau suivant :" : "At the next level:",
          "next_action": fr ? "Passer au niveau supérieur" : "Move up a level",
          "semantics": fr ? "Niveau {current} sur {count} : {label}" : "Level {current} of {count}: {label}",
          "counter": counter ?? "{count}/{total} {label}",
        },
      },
    };
  }
}

/// Pumps [child] under EasyLocalization with [loader]. The loaded
/// translations live in a singleton that outlives the test; the tear-down
/// empties it so every later `.tr()` returns the raw key again, whatever the
/// test order.
Future<void> _pumpLocalized(
  WidgetTester tester,
  Locale locale,
  Widget child, {
  AssetLoader loader = const _MemoryLoader(),
}) async {
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
  group("header and labels", () {
    testWidgets("shows the current level in the header and every level below", (WidgetTester tester) async {
      await _pumpBar(tester, const LevelProgressBar(levels: _levels, currentIndex: 1));

      expect(_inBar(find.text("A")), findsOneWidget);
      expect(_inBar(find.text("B")), findsNWidgets(2));
      expect(_inBar(find.text("C")), findsOneWidget);
      expect(
        tester.getTopLeft(_inBar(find.text("B")).first).dy,
        lessThan(tester.getTopLeft(_inBar(find.text("A"))).dy),
      );
    });

    testWidgets("header uses onSurface w700", (WidgetTester tester) async {
      await _pumpBar(tester, const LevelProgressBar(levels: _levels, currentIndex: 1));
      final TextStyle style = tester.widget<Text>(_inBar(find.text("B")).first).style ?? const TextStyle();

      expect(style.color, _scheme(tester).onSurface);
      expect(style.fontWeight, FontWeight.w700);
      expect(style.fontSize, 13);
    });

    testWidgets("reached labels use primary, the others onSurfaceVariant", (WidgetTester tester) async {
      await _pumpBar(tester, const LevelProgressBar(levels: _levels, currentIndex: 1));
      final ColorScheme cs = _scheme(tester);

      expect(_labelStyle(tester, "A").color, cs.primary);
      expect(_labelStyle(tester, "B").color, cs.primary);
      expect(_labelStyle(tester, "C").color, cs.onSurfaceVariant);
      expect(_labelStyle(tester, "C").fontWeight, FontWeight.w600);
      expect(_labelStyle(tester, "C").fontSize, 10);
    });
  });

  group("segments", () {
    testWidgets("renders one segment per level", (WidgetTester tester) async {
      await _pumpBar(tester, const LevelProgressBar(levels: <String>["1", "2", "3", "4", "5"], currentIndex: 0));

      expect(_segments(), findsNWidgets(5));
    });

    testWidgets("fills segments up to the current level", (WidgetTester tester) async {
      await _pumpBar(tester, const LevelProgressBar(levels: _levels, currentIndex: 1));
      final ColorScheme cs = _scheme(tester);

      expect(_segmentColor(tester, 0), cs.primary);
      expect(_segmentColor(tester, 1), cs.primary);
      expect(_segmentColor(tester, 2), cs.surfaceContainerHighest);
    });

    testWidgets("fills every segment at the last level", (WidgetTester tester) async {
      await _pumpBar(tester, const LevelProgressBar(levels: _levels, currentIndex: 2));
      final ColorScheme cs = _scheme(tester);

      for (int i = 0; i < _levels.length; i++) {
        expect(_segmentColor(tester, i), cs.primary);
      }
    });

    testWidgets("segments are 6 dp pills with a 4 dp gap", (WidgetTester tester) async {
      await _pumpBar(tester, const LevelProgressBar(levels: _levels, currentIndex: 0));
      final DecoratedBox box = tester.widget<DecoratedBox>(_segment(0));

      expect((box.decoration as BoxDecoration).borderRadius, BorderRadius.circular(999));
      expect(tester.getSize(_segment(0)).height, 6);
      expect(tester.getTopLeft(_segment(1)).dx - tester.getTopRight(_segment(0)).dx, 4);
      expect(tester.getSize(_segment(0)).width, tester.getSize(_segment(2)).width);
    });

    testWidgets("each label spans exactly its segment", (WidgetTester tester) async {
      await _pumpBar(tester, const LevelProgressBar(levels: _levels, currentIndex: 0));

      expect(tester.getTopLeft(_inBar(find.text("A")).last).dx, tester.getTopLeft(_segment(0)).dx);
      expect(tester.getTopLeft(_inBar(find.text("B"))).dx, tester.getTopLeft(_segment(1)).dx);
      expect(tester.getTopLeft(_inBar(find.text("C"))).dx, tester.getTopLeft(_segment(2)).dx);
      expect(tester.getSize(_inBar(find.text("C"))).width, tester.getSize(_segment(2)).width);
    });

    testWidgets("rebuilds with a new current level", (WidgetTester tester) async {
      await _pumpBar(tester, const LevelProgressBar(levels: _levels, currentIndex: 0));
      await _pumpBar(tester, const LevelProgressBar(levels: _levels, currentIndex: 2));
      final ColorScheme cs = _scheme(tester);

      expect(_segmentColor(tester, 2), cs.primary);
      expect(_inBar(find.text("C")), findsNWidgets(2));
    });
  });

  group("counter", () {
    testWidgets("is shown when count and total are set", (WidgetTester tester) async {
      await _pumpBar(
        tester,
        const LevelProgressBar(levels: _levels, currentIndex: 1, count: 9, total: 12, countLabel: "items"),
      );

      // pumpApp: .tr() returns the raw key, which has no {count} to split.
      expect(_inBar(find.text(_counterKey)), findsOneWidget);
      expect(_counterBaseStyle(tester).color, _scheme(tester).onSurfaceVariant);
    });

    testWidgets("is end-aligned in the header", (WidgetTester tester) async {
      await _pumpBar(tester, const LevelProgressBar(levels: _levels, currentIndex: 1, count: 1, total: 2));

      expect(
        tester.getTopRight(_inBar(find.text(_counterKey))).dx,
        tester.getTopRight(find.byType(LevelProgressBar)).dx,
      );
    });

    testWidgets("uses the space a short label leaves free", (WidgetTester tester) async {
      // The raw key is wider than half the row but fits next to "A".
      await _pumpBar(
        tester,
        const LevelProgressBar(levels: <String>["A", "B"], currentIndex: 0, count: 1, total: 2),
        surfaceSize: const Size(640, 480),
      );
      final Finder counter = _inBar(find.text(_counterKey));
      final Finder label = _inBar(find.text("A")).first;

      expect(tester.getSize(counter).width, greaterThan(tester.getSize(find.byType(LevelProgressBar)).width / 2));
      expect(_paragraph(tester, counter).didExceedMaxLines, isFalse);
      expect(_paragraph(tester, label).didExceedMaxLines, isFalse);
      expect(tester.getTopRight(counter).dx, tester.getTopRight(find.byType(LevelProgressBar)).dx);
    });

    testWidgets("keeps 12 dp after a short label when it fills the row", (WidgetTester tester) async {
      await _pumpBar(
        tester,
        const LevelProgressBar(levels: <String>["A", "B"], currentIndex: 0, count: 1, total: 2),
        surfaceSize: const Size(320, 480),
      );
      final Finder counter = _inBar(find.text(_counterKey));
      final Finder label = _inBar(find.text("A")).first;

      expect(_paragraph(tester, counter).didExceedMaxLines, isTrue);
      expect(_paragraph(tester, label).didExceedMaxLines, isFalse);
      expect(tester.getTopLeft(counter).dx - tester.getTopRight(label).dx, _gapRange);
      expect(tester.getTopRight(counter).dx, tester.getTopRight(find.byType(LevelProgressBar)).dx);
    });

    testWidgets("keeps the 12 dp gap between the texts in RTL", (WidgetTester tester) async {
      await _pumpBar(
        tester,
        const LevelProgressBar(levels: <String>["A", "B"], currentIndex: 0, count: 1, total: 2),
        surfaceSize: const Size(320, 480),
        textDirection: TextDirection.rtl,
      );
      final Finder counter = _inBar(find.text(_counterKey));
      final Finder label = _inBar(find.text("A")).first;
      final Rect bar = tester.getRect(find.byType(LevelProgressBar));

      expect(tester.getTopRight(label).dx, bar.right);
      expect(tester.getTopLeft(counter).dx, bar.left);
      expect(tester.getTopLeft(label).dx - tester.getTopRight(counter).dx, _gapRange);
    });

    testWidgets("shares the row in halves when both texts are long", (WidgetTester tester) async {
      const String long = "A very long level label that cannot fit in half of the width";
      await _pumpBar(
        tester,
        const LevelProgressBar(levels: <String>[long, "B"], currentIndex: 0, count: 1, total: 2),
        surfaceSize: const Size(320, 480),
      );
      final Finder counter = _inBar(find.text(_counterKey));
      final Finder label = _inBar(find.text(long)).first;
      final double half = (tester.getSize(find.byType(LevelProgressBar)).width - kDefaultPadding * 1.5) / 2;

      expect(tester.takeException(), isNull);
      expect(tester.getSize(label).width, half);
      expect(tester.getSize(counter).width, half);
      expect(_paragraph(tester, label).didExceedMaxLines, isTrue);
      expect(_paragraph(tester, counter).didExceedMaxLines, isTrue);
    });

    testWidgets("is hidden when count or total is null", (WidgetTester tester) async {
      await _pumpBar(tester, const LevelProgressBar(levels: _levels, currentIndex: 1, total: 12));
      expect(_inBar(find.text(_counterKey)), findsNothing);

      await _pumpBar(tester, const LevelProgressBar(levels: _levels, currentIndex: 1, count: 9));
      expect(_inBar(find.text(_counterKey)), findsNothing);
    });
  });

  group("next-level card", () {
    testWidgets("is shown with chips when nextItems is set below the last level", (WidgetTester tester) async {
      await _pumpBar(
        tester,
        const LevelProgressBar(levels: _levels, currentIndex: 0, nextItems: <String>["Export", "Sharing"]),
      );

      expect(_inBar(find.text(_nextTitleKey)), findsOneWidget);
      expect(_inBar(find.text("Export")), findsOneWidget);
      expect(_inBar(find.text("Sharing")), findsOneWidget);
      expect(
        tester.getTopLeft(_inBar(find.text(_nextTitleKey))).dy,
        greaterThan(tester.getBottomLeft(_inBar(find.text("A")).last).dy),
      );
    });

    testWidgets("chips use primary text on a primary tint", (WidgetTester tester) async {
      await _pumpBar(tester, const LevelProgressBar(levels: _levels, currentIndex: 0, nextItems: <String>["Export"]));
      final ColorScheme cs = _scheme(tester);
      final Text chip = tester.widget<Text>(_inBar(find.text("Export")));
      final DecoratedBox pill = tester.widget<DecoratedBox>(
        find.ancestor(of: find.text("Export"), matching: find.byType(DecoratedBox)).first,
      );

      expect(chip.style?.color, cs.primary);
      expect((pill.decoration as BoxDecoration).color, cs.primary.withValues(alpha: 0.10));
    });

    testWidgets("is hidden when nextItems is null", (WidgetTester tester) async {
      await _pumpBar(tester, LevelProgressBar(levels: _levels, currentIndex: 0, onNextLevel: () {}));

      expect(_inBar(find.text(_nextTitleKey)), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets("is hidden at the last level even with nextItems", (WidgetTester tester) async {
      await _pumpBar(
        tester,
        LevelProgressBar(levels: _levels, currentIndex: 2, nextItems: const <String>["Export"], onNextLevel: () {}),
      );

      expect(_inBar(find.text(_nextTitleKey)), findsNothing);
      expect(_inBar(find.text("Export")), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets("an empty list shows the card without chips", (WidgetTester tester) async {
      await _pumpBar(tester, const LevelProgressBar(levels: _levels, currentIndex: 0, nextItems: <String>[]));

      expect(_inBar(find.text(_nextTitleKey)), findsOneWidget);
      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets("nextTitle and nextActionLabel override the defaults", (WidgetTester tester) async {
      await _pumpBar(
        tester,
        LevelProgressBar(
          levels: _levels,
          currentIndex: 0,
          nextItems: const <String>[],
          nextTitle: "Coming next",
          nextActionLabel: "Go further",
          onNextLevel: () {},
        ),
      );

      expect(_inBar(find.text("Coming next")), findsOneWidget);
      expect(_inBar(find.text("Go further")), findsOneWidget);
      expect(_inBar(find.text(_nextTitleKey)), findsNothing);
      expect(_inBar(find.text(_nextActionKey)), findsNothing);
    });
  });

  group("call to action", () {
    testWidgets("calls onNextLevel once per tap and is at least 48 dp high", (WidgetTester tester) async {
      int taps = 0;
      await _pumpBar(
        tester,
        LevelProgressBar(levels: _levels, currentIndex: 0, nextItems: const <String>["Export"], onNextLevel: () => taps++),
      );

      expect(find.widgetWithText(FilledButton, _nextActionKey), findsOneWidget);
      expect(tester.getSize(find.byType(FilledButton)).height, greaterThanOrEqualTo(kMinTapTarget));
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets("spans the card width", (WidgetTester tester) async {
      await _pumpBar(
        tester,
        LevelProgressBar(levels: _levels, currentIndex: 0, nextItems: const <String>[], onNextLevel: () {}),
      );

      expect(
        tester.getSize(find.byType(FilledButton)).width,
        tester.getSize(find.byType(LevelProgressBar)).width - 2 * kDefaultPadding * 1.5,
      );
    });

    testWidgets("is hidden without onNextLevel", (WidgetTester tester) async {
      await _pumpBar(tester, const LevelProgressBar(levels: _levels, currentIndex: 0, nextItems: <String>["Export"]));

      expect(find.byType(FilledButton), findsNothing);
      expect(_inBar(find.text(_nextActionKey)), findsNothing);
    });
  });

  group("semantics", () {
    testWidgets("one summary node with the label key and the counter value", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBar(tester, const LevelProgressBar(levels: _levels, currentIndex: 1, count: 9, total: 12));

      final Finder summary = find.bySemanticsLabel(_semanticsKey);
      expect(summary, findsOneWidget);
      expect(tester.getSemantics(summary).value, _counterKey);
      expect(find.bySemanticsLabel("A"), findsNothing);
      handle.dispose();
    });

    testWidgets("no value without a counter; the card stays readable", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBar(
        tester,
        LevelProgressBar(levels: _levels, currentIndex: 0, nextItems: const <String>["Export"], onNextLevel: () {}),
      );

      expect(tester.getSemantics(find.bySemanticsLabel(_semanticsKey)).value, isEmpty);
      expect(find.bySemanticsLabel("Export"), findsOneWidget);
      expect(find.bySemanticsLabel(_nextActionKey), findsOneWidget);
      handle.dispose();
    });
  });

  group("asserts", () {
    testWidgets("empty levels fail at build", (WidgetTester tester) async {
      await _pumpBar(tester, const LevelProgressBar(levels: <String>[], currentIndex: 0));

      expect(tester.takeException(), isAssertionError);
    });

    testWidgets("a currentIndex past the last level fails at build", (WidgetTester tester) async {
      await _pumpBar(tester, const LevelProgressBar(levels: _levels, currentIndex: 3));

      expect(tester.takeException(), isAssertionError);
    });

    testWidgets("a negative currentIndex fails at build", (WidgetTester tester) async {
      await _pumpBar(tester, const LevelProgressBar(levels: _levels, currentIndex: -1));

      expect(tester.takeException(), isAssertionError);
    });
  });

  group("layout", () {
    const String long = "A very long level label that cannot fit in a third of the width";

    for (final (String name, ThemeData Function() theme) in <(String, ThemeData Function())>[
      ("light", AppTheme.light),
      ("dark", AppTheme.dark),
    ]) {
      testWidgets("no overflow at 320 dp with long texts ($name)", (WidgetTester tester) async {
        await _pumpBar(
          tester,
          LevelProgressBar(
            levels: const <String>[long, long, long, long],
            currentIndex: 1,
            count: 123456,
            total: 999999,
            countLabel: "a rather long counter label that goes on and on",
            nextItems: const <String>[long, "Short", long],
            nextTitle: long,
            nextActionLabel: long,
            onNextLevel: () {},
          ),
          theme: theme(),
          surfaceSize: const Size(320, 640),
        );

        expect(tester.takeException(), isNull);
        expect(_segmentColor(tester, 1), _scheme(tester).primary);
        expect(_segmentColor(tester, 2), _scheme(tester).surfaceContainerHighest);
      });
    }
  });

  group("localized", () {
    const LevelProgressBar bar = LevelProgressBar(
      levels: _levels,
      currentIndex: 1,
      count: 9,
      total: 12,
      countLabel: "items",
      nextItems: <String>[],
    );

    testWidgets("renders the en counter with an emphasised count", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(tester, const Locale("en"), bar);
      final ColorScheme cs = _scheme(tester);

      expect(find.text("9/12 items"), findsOneWidget);
      expect(_span(tester, "9").style?.color, cs.primary);
      expect(_span(tester, "9").style?.fontWeight, FontWeight.w800);
      expect(_span(tester, "/12 items").style, isNull);
      expect(_counterBaseStyle(tester).color, cs.onSurfaceVariant);
      expect(find.text("At the next level:"), findsOneWidget);

      final Finder summary = find.bySemanticsLabel("Level 2 of 3: B");
      expect(summary, findsOneWidget);
      expect(tester.getSemantics(summary).value, "9/12 items");
      handle.dispose();
    });

    testWidgets("renders the fr strings", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(
        tester,
        const Locale("fr"),
        LevelProgressBar(levels: _levels, currentIndex: 0, nextItems: const <String>[], onNextLevel: () {}),
      );

      expect(find.text("Au niveau suivant :"), findsOneWidget);
      expect(find.text("Passer au niveau supérieur"), findsOneWidget);
      expect(find.bySemanticsLabel("Niveau 1 sur 3 : A"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("a short counter leaves the rest of the row to a long label", (WidgetTester tester) async {
      const String long = "A level label longer than half of the row width";
      await _pumpLocalized(
        tester,
        const Locale("en"),
        const LevelProgressBar(levels: <String>[long, "B"], currentIndex: 0, count: 9, total: 12),
      );
      final Finder label = _inBar(find.text(long)).first;

      expect(find.text("9/12"), findsOneWidget);
      expect(tester.getSize(label).width, greaterThan(tester.getSize(find.byType(LevelProgressBar)).width / 2));
      expect(_paragraph(tester, label).didExceedMaxLines, isFalse);
      expect(_paragraph(tester, _inBar(find.text("9/12"))).didExceedMaxLines, isFalse);
    });

    testWidgets("drops the trailing space without countLabel", (WidgetTester tester) async {
      await _pumpLocalized(
        tester,
        const Locale("en"),
        const LevelProgressBar(levels: _levels, currentIndex: 1, count: 9, total: 12),
      );

      expect(find.text("9/12"), findsOneWidget);
    });

    testWidgets("styles the count wherever the template puts it", (WidgetTester tester) async {
      await _pumpLocalized(
        tester,
        const Locale("en"),
        bar,
        loader: const _MemoryLoader(counter: "{label}: {count} of {total}"),
      );

      expect(find.text("items: 9 of 12"), findsOneWidget);
      expect(_span(tester, "items: ").style, isNull);
      expect(_span(tester, "9").style?.color, _scheme(tester).primary);
      expect(_span(tester, " of 12").style, isNull);
    });
  });
}

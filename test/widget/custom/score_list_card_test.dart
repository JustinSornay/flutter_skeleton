// score_list_card_test.dart
//
// Widget tests for ScoreListCard: header (title, optional icon), the loading
// skeleton (row count, pulse, reduced motion, loading label), loaded rows
// (subtitle, caption, default and custom score labels, bar clamping, tone
// colours in light and dark), empty and error states (custom texts, retry,
// live region), row taps and semantics (score value with the shipped
// strings), the 48 dp row height, bar tracks of equal width whatever the
// labels and text scale, overflow-free long texts, the card's theme animation
// under reduced motion, the ValueKey reload contract and dispose safety.

import "dart:async";
import "dart:convert";
import "dart:io";

import "package:easy_localization/easy_localization.dart" hide TextDirection;
// ignore: implementation_imports
import "package:easy_localization/src/localization.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/data/locales.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/core/decorators/SkeletonPulse/index.dart";
import "package:flutter_skeleton/widgets/custom/ScoreListCard/index.dart";
import "package:flutter_skeleton/widgets/custom/SkeletonBlock/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../helpers/widget_test_helpers.dart";

const String _title = "TOP ITEMS";
const String _scoreKey = "custom.score_list_card.score_semantics";

/// Item type of the tests: the card only sees it through entryOf.
final class _Item {
  final String name;
  final double value;
  final String? note;
  final String? caption;

  const _Item(this.name, this.value, {this.note, this.caption});
}

const _Item _alpha = _Item("Alpha", 0.734, note: "first", caption: "Very good");
const _Item _beta = _Item("Beta", 0.41);

ScoreListEntry _entry(_Item item) {
  return ScoreListEntry(title: item.name, score: item.value, subtitle: item.note, caption: item.caption);
}

Future<List<_Item>> Function() _returns(List<_Item> items) {
  return () async => items;
}

ScoreListCard<_Item> _card({
  required Future<List<_Item>> Function() load,
  ScoreListEntry Function(_Item item) entryOf = _entry,
  ValueChanged<_Item>? onItemTap,
  IconData? icon,
  Key? key,
}) {
  return ScoreListCard<_Item>(
    key: key,
    title: _title,
    icon: icon,
    load: load,
    entryOf: entryOf,
    onItemTap: onItemTap,
  );
}

/// Pumps [card] and lets its load future settle.
Future<void> _pumpLoaded(WidgetTester tester, Widget card, {ThemeData? theme}) async {
  await pumpApp(tester, card, theme: theme);
  await tester.pump();
}

/// Pumps [card] with reduced motion requested by the platform.
Future<void> _pumpReducedMotion(WidgetTester tester, Widget card) async {
  await pumpApp(
    tester,
    Builder(
      builder: (BuildContext context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: card,
      ),
    ),
  );
}

/// Pumps [card] at [scale] times the text size and lets its load settle.
Future<void> _pumpTextScale(WidgetTester tester, Widget card, double scale) async {
  await pumpApp(
    tester,
    Builder(
      builder: (BuildContext context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: card,
      ),
    ),
  );
  await tester.pump();
}

/// Reads the shipped `assets/translations/<lang>.json`, so the expectations
/// check the real strings. Synchronous I/O completes under the fake-async
/// clock.
final class _AssetFileLoader extends AssetLoader {
  const _AssetFileLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final File file = File("$path/${locale.languageCode}.json");
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
}

/// Pumps [card] under EasyLocalization with the shipped translations and
/// lets its load settle. The loaded translations live in a singleton that
/// outlives the test; the tear-down empties it so every later `.tr()` returns
/// the raw key again, whatever the test order.
Future<void> _pumpLocalized(WidgetTester tester, Locale locale, Widget card) async {
  addTearDown(() => Localization.load(const Locale("fr")));
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await EasyLocalization.ensureInitialized();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const <Locale>[Locale("fr"), Locale("en")],
      path: AppLocales.path,
      fallbackLocale: const Locale("fr"),
      startLocale: locale,
      saveLocale: false,
      assetLoader: const _AssetFileLoader(),
      child: Builder(
        builder: (BuildContext context) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.light(),
          home: Scaffold(body: card),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

LinearProgressIndicator _bar(WidgetTester tester, String title) {
  final Finder row = find.ancestor(of: find.text(title), matching: find.byType(Column)).first;
  return tester.widget<LinearProgressIndicator>(
    find.descendant(of: row, matching: find.byType(LinearProgressIndicator)),
  );
}

/// Laid-out width of every bar track, in row order.
List<double> _trackWidths(WidgetTester tester) {
  return find
      .byType(LinearProgressIndicator)
      .evaluate()
      .map((Element bar) => (bar.renderObject! as RenderBox).size.width)
      .toList();
}

Color? _fill(LinearProgressIndicator bar) => (bar.valueColor! as AlwaysStoppedAnimation<Color>).value;

Color? _textColor(WidgetTester tester, String text) => tester.widget<Text>(find.text(text)).style?.color;

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(ScoreListCard<_Item>))).colorScheme;

void main() {
  group("header", () {
    testWidgets("renders the title as a semantic header", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLoaded(tester, _card(load: _returns(<_Item>[_alpha])));

      expect(find.text(_title), findsOneWidget);
      expect(
        tester.getSemantics(find.text(_title)),
        matchesSemantics(isHeader: true, label: _title, textDirection: TextDirection.ltr),
      );
      handle.dispose();
    });

    testWidgets("renders the icon only when one is given", (WidgetTester tester) async {
      await _pumpLoaded(tester, _card(load: _returns(<_Item>[_alpha])));
      expect(find.byType(Icon), findsNothing);

      await _pumpLoaded(tester, _card(load: _returns(<_Item>[_alpha]), icon: Icons.star_outline));
      expect(find.byIcon(Icons.star_outline), findsOneWidget);
    });
  });

  group("loading", () {
    testWidgets("shows 3 pulsing 48 dp skeleton rows while load is pending", (WidgetTester tester) async {
      final Completer<List<_Item>> pending = Completer<List<_Item>>();
      await pumpApp(tester, _card(load: () => pending.future));
      await tester.pump(const Duration(milliseconds: 100));

      final Finder blocks = find.descendant(of: find.byType(SkeletonPulse), matching: find.byType(SkeletonBlock));
      expect(blocks, findsNWidgets(3));
      expect(tester.getSize(blocks.first).height, 48);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets("shows skeletonRowCount rows", (WidgetTester tester) async {
      final Completer<List<_Item>> pending = Completer<List<_Item>>();
      await pumpApp(
        tester,
        ScoreListCard<_Item>(
          title: _title,
          load: () => pending.future,
          entryOf: _entry,
          skeletonRowCount: 5,
        ),
      );

      expect(find.byType(SkeletonBlock), findsNWidgets(5));
    });

    testWidgets("announces the loading state", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final Completer<List<_Item>> pending = Completer<List<_Item>>();
      await pumpApp(tester, _card(load: () => pending.future));

      expect(find.bySemanticsLabel("custom.score_list_card.loading"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("is static under reduced motion and lets pumpAndSettle finish", (WidgetTester tester) async {
      final Completer<List<_Item>> pending = Completer<List<_Item>>();
      await _pumpReducedMotion(tester, _card(load: () => pending.future));
      await tester.pumpAndSettle();

      expect(find.byType(SkeletonPulse), findsNothing);
      expect(find.byType(SkeletonBlock), findsNWidgets(3));
    });
  });

  group("loaded", () {
    testWidgets("renders one row per item with its texts", (WidgetTester tester) async {
      await _pumpLoaded(tester, _card(load: _returns(<_Item>[_alpha, _beta])));

      expect(find.byType(SkeletonBlock), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("first"), findsOneWidget);
      expect(find.text("73"), findsOneWidget);
      expect(find.text("Very good"), findsOneWidget);
      expect(find.text("Beta"), findsOneWidget);
      expect(find.text("41"), findsOneWidget);
    });

    testWidgets("hides an empty subtitle and an empty caption", (WidgetTester tester) async {
      await _pumpLoaded(
        tester,
        _card(
          load: _returns(<_Item>[const _Item("Gamma", 0.5, note: "", caption: "")]),
        ),
      );

      // Header + title + score only.
      expect(find.byType(Text), findsNWidgets(3));
      expect(find.text("Gamma"), findsOneWidget);
      expect(find.text("50"), findsOneWidget);
    });

    testWidgets("a custom scoreLabel replaces the default", (WidgetTester tester) async {
      await _pumpLoaded(
        tester,
        _card(
          load: _returns(<_Item>[_alpha]),
          entryOf: (_Item item) => ScoreListEntry(title: item.name, score: item.value, scoreLabel: "7.3/10"),
        ),
      );

      expect(find.text("7.3/10"), findsOneWidget);
      expect(find.text("73"), findsNothing);
    });

    testWidgets("clamps the bar to [0, 1] but keeps the raw label", (WidgetTester tester) async {
      await _pumpLoaded(
        tester,
        _card(load: _returns(<_Item>[const _Item("High", 1.4), const _Item("Low", -0.2)])),
      );

      expect(_bar(tester, "High").value, 1.0);
      expect(find.text("140"), findsOneWidget);
      expect(_bar(tester, "Low").value, 0.0);
      expect(find.text("-20"), findsOneWidget);
    });

    testWidgets("a non-finite score draws an empty bar and a dash", (WidgetTester tester) async {
      await _pumpLoaded(
        tester,
        _card(
          load: _returns(<_Item>[
            const _Item("Unknown", double.nan),
            const _Item("Above", double.infinity),
            const _Item("Below", double.negativeInfinity),
          ]),
        ),
      );

      expect(_bar(tester, "Unknown").value, 0.0);
      expect(_bar(tester, "Above").value, 0.0);
      expect(_bar(tester, "Below").value, 0.0);
      expect(find.text("—"), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  });

  group("tone", () {
    testWidgets("defaults to the primary colour on a surfaceContainerHighest track", (WidgetTester tester) async {
      await _pumpLoaded(tester, _card(load: _returns(<_Item>[_alpha])));
      final ColorScheme cs = _scheme(tester);
      final LinearProgressIndicator bar = _bar(tester, "Alpha");

      expect(_fill(bar), cs.primary);
      expect(bar.backgroundColor, cs.surfaceContainerHighest);
      expect(bar.minHeight, 6);
      expect(_textColor(tester, "73"), cs.primary);
    });

    testWidgets("uses the tone foreground for the bar and the score", (WidgetTester tester) async {
      await _pumpLoaded(
        tester,
        _card(
          load: _returns(<_Item>[_alpha]),
          entryOf: (_Item item) => ScoreListEntry(title: item.name, score: item.value, tone: StatusTone.danger),
        ),
      );
      final Color danger = StatusTones.colorsOf(tester.element(find.text("Alpha")), StatusTone.danger).foreground;

      expect(_fill(_bar(tester, "Alpha")), danger);
      expect(_textColor(tester, "73"), danger);
    });

    testWidgets("renders under the dark theme", (WidgetTester tester) async {
      await _pumpLoaded(
        tester,
        _card(
          load: _returns(<_Item>[_alpha]),
          entryOf: (_Item item) => ScoreListEntry(title: item.name, score: item.value, tone: StatusTone.success),
        ),
        theme: AppTheme.dark(),
      );
      final BuildContext context = tester.element(find.text("Alpha"));

      expect(tester.takeException(), isNull);
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(_fill(_bar(tester, "Alpha")), StatusTones.colorsOf(context, StatusTone.success).foreground);
      expect(_textColor(tester, "Alpha"), Theme.of(context).colorScheme.onSurface);
    });
  });

  group("empty", () {
    testWidgets("shows the built-in empty text", (WidgetTester tester) async {
      await _pumpLoaded(tester, _card(load: _returns(<_Item>[])));

      expect(find.text("custom.score_list_card.empty"), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets("a custom emptyText replaces it", (WidgetTester tester) async {
      await _pumpLoaded(
        tester,
        ScoreListCard<_Item>(title: _title, load: _returns(<_Item>[]), entryOf: _entry, emptyText: "Nothing yet"),
      );

      expect(find.text("Nothing yet"), findsOneWidget);
      expect(find.text("custom.score_list_card.empty"), findsNothing);
    });
  });

  group("error", () {
    Future<List<_Item>> failing() async => throw StateError("boom");

    testWidgets("shows the built-in error text and a retry button", (WidgetTester tester) async {
      await _pumpLoaded(tester, _card(load: failing));

      expect(tester.takeException(), isNull);
      expect(find.text("custom.score_list_card.load_error"), findsOneWidget);
      expect(find.text("custom.score_list_card.retry"), findsOneWidget);
      expect(find.byIcon(StatusTone.danger.icon), findsOneWidget);
      expect(find.text("custom.score_list_card.empty"), findsNothing);
    });

    testWidgets("announces the error text as a live region", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLoaded(tester, _card(load: failing));

      expect(
        tester.getSemantics(find.text("custom.score_list_card.load_error")),
        isSemantics(label: "custom.score_list_card.load_error", isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets("a custom errorText replaces it", (WidgetTester tester) async {
      await _pumpLoaded(
        tester,
        ScoreListCard<_Item>(title: _title, load: failing, entryOf: _entry, errorText: "Could not load"),
      );

      expect(find.text("Could not load"), findsOneWidget);
      expect(find.text("custom.score_list_card.load_error"), findsNothing);
    });

    testWidgets("the retry button is at least 48 dp tall", (WidgetTester tester) async {
      await _pumpLoaded(tester, _card(load: failing));

      final Size size = tester.getSize(find.byType(TextButton));
      expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
      expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
    });

    testWidgets("retry shows the skeleton then the new result", (WidgetTester tester) async {
      int calls = 0;
      final Completer<List<_Item>> second = Completer<List<_Item>>();
      Future<List<_Item>> load() {
        calls++;
        return calls == 1 ? Future<List<_Item>>.error(StateError("boom")) : second.future;
      }

      await _pumpLoaded(tester, _card(load: load));
      await tester.tap(find.text("custom.score_list_card.retry"));
      await tester.pump();

      expect(calls, 2);
      expect(find.byType(SkeletonBlock), findsNWidgets(3));
      expect(find.text("custom.score_list_card.load_error"), findsNothing);

      second.complete(<_Item>[_beta]);
      await tester.pump();

      expect(find.text("Beta"), findsOneWidget);
      expect(find.byType(SkeletonBlock), findsNothing);
    });
  });

  group("tap", () {
    testWidgets("calls onItemTap with the tapped item", (WidgetTester tester) async {
      final List<_Item> tapped = <_Item>[];
      await _pumpLoaded(tester, _card(load: _returns(<_Item>[_alpha, _beta]), onItemTap: tapped.add));

      await tester.tap(find.text("Beta"));
      await tester.pump();

      expect(tapped, <_Item>[_beta]);
      expect(find.byType(InkWell), findsNWidgets(2));
    });

    testWidgets("rows are inert without onItemTap", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLoaded(tester, _card(load: _returns(<_Item>[_beta])));

      expect(find.byType(InkWell), findsNothing);
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp("^Beta"))),
        matchesSemantics(label: "Beta, $_scoreKey"),
      );
      handle.dispose();
    });

    testWidgets("tappable rows are buttons with a tap action", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<_Item> tapped = <_Item>[];
      await _pumpLoaded(tester, _card(load: _returns(<_Item>[_beta]), onItemTap: tapped.add));

      expect(tester.getSemantics(find.bySemanticsLabel(RegExp("^Beta"))), matchesSemantics(label: "Beta, $_scoreKey", isButton: true, hasTapAction: true));

      tester.semantics.tap(find.semantics.byLabel(RegExp("^Beta")));
      expect(tapped, <_Item>[_beta]);
      handle.dispose();
    });
  });

  group("semantics", () {
    testWidgets("the default label joins title, subtitle, score and caption", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLoaded(tester, _card(load: _returns(<_Item>[_alpha])));

      expect(
        find.bySemanticsLabel("Alpha, first, $_scoreKey, Very good"),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets("the default label carries the score text with real strings", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLocalized(tester, const Locale("en"), _card(load: _returns(<_Item>[_alpha, _beta])));

      expect(find.bySemanticsLabel("Alpha, first, score 73, Very good"), findsOneWidget);
      expect(find.bySemanticsLabel("Beta, score 41"), findsOneWidget);
      handle.dispose();
    });

    testWidgets("a custom semanticLabel replaces it", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpLoaded(
        tester,
        _card(
          load: _returns(<_Item>[_alpha]),
          entryOf: (_Item item) => ScoreListEntry(title: item.name, score: item.value, semanticLabel: "Alpha scores 73"),
        ),
      );

      expect(find.bySemanticsLabel("Alpha scores 73"), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(_scoreKey)), findsNothing);
      handle.dispose();
    });
  });

  group("layout", () {
    testWidgets("every row is at least kMinTapTarget tall, even with small text", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // At half the text size the row content is shorter than kMinTapTarget,
      // so only the row's own minimum height keeps it at 48 dp.
      await _pumpTextScale(tester, _card(load: _returns(<_Item>[_alpha, _beta]), onItemTap: (_Item _) {}), 0.5);

      expect(tester.getSize(find.bySemanticsLabel(RegExp("^Alpha"))).height, greaterThanOrEqualTo(kMinTapTarget));
      expect(tester.getSize(find.bySemanticsLabel(RegExp("^Beta"))).height, greaterThanOrEqualTo(kMinTapTarget));
      handle.dispose();
    });

    for (final double scale in <double>[1.0, 2.0]) {
      testWidgets("every bar track has the same width at text scale $scale", (WidgetTester tester) async {
        await _pumpTextScale(
          tester,
          _card(load: _returns(<_Item>[const _Item("Full", 1.0), const _Item("Tiny", 0.09)])),
          scale,
        );

        expect(find.text("100"), findsOneWidget);
        expect(find.text("9"), findsOneWidget);
        final List<double> widths = _trackWidths(tester);
        expect(widths, hasLength(2));
        expect(widths.last, widths.first);
        expect(tester.renderObject<RenderParagraph>(find.text("100")).didExceedMaxLines, isFalse);
      });
    }

    testWidgets("custom labels of different widths keep the tracks aligned", (WidgetTester tester) async {
      await _pumpLoaded(
        tester,
        _card(
          load: _returns(<_Item>[const _Item("Ten", 1.0), const _Item("Nine", 0.9), const _Item("One", 0.1)]),
          entryOf: (_Item item) => ScoreListEntry(
            title: item.name,
            score: item.value,
            scoreLabel: "${(item.value * 10).round()}/10",
          ),
        ),
      );

      final List<double> widths = _trackWidths(tester);
      expect(widths, hasLength(3));
      expect(widths.toSet(), hasLength(1));
      // The slot fits the widest label, so it is not ellipsised.
      expect(tester.renderObject<RenderParagraph>(find.text("10/10")).didExceedMaxLines, isFalse);
      expect(tester.getSize(find.text("10/10")).width, greaterThan(kDefaultPadding * 4));
    });

    testWidgets("long texts ellipsise or wrap without overflow", (WidgetTester tester) async {
      final String long = List<String>.filled(40, "word").join(" ");
      final String longScore = List<String>.filled(10, "word").join(" ");
      await _pumpLoaded(
        tester,
        SizedBox(
          width: 280,
          child: _card(
            load: _returns(<_Item>[_Item(long, 0.5, note: long, caption: long)]),
            entryOf: (_Item item) => ScoreListEntry(
              title: item.name,
              score: item.value,
              subtitle: item.note,
              caption: item.caption,
              scoreLabel: longScore,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.widget<Text>(find.text(long).first).maxLines, 1);
      final Text score = tester.widget<Text>(find.text(longScore));
      expect(score.maxLines, 1);
      expect(score.overflow, TextOverflow.ellipsis);
      expect(tester.getSize(find.text(longScore)).width, lessThanOrEqualTo(kDefaultPadding * 12));
      expect(tester.getSize(find.byType(LinearProgressIndicator)).width, greaterThan(kDefaultPadding * 12));
      // The caption wraps instead of overflowing.
      expect(tester.widget<Text>(find.text(long).last).maxLines, isNull);
      expect(tester.getSize(find.text(long).last).height, greaterThan(tester.getSize(find.text(long).first).height));
    });
  });

  group("motion", () {
    testWidgets("the card's theme animation follows resolveMotion", (WidgetTester tester) async {
      Material card() => tester.widget<Material>(
            find.descendant(of: find.byType(ScoreListCard<_Item>), matching: find.byType(Material)).first,
          );

      await _pumpLoaded(tester, _card(load: _returns(<_Item>[_alpha])));
      expect(card().animationDuration, kThemeChangeDuration);

      await _pumpReducedMotion(tester, _card(load: _returns(<_Item>[_alpha])));
      expect(card().animationDuration, Duration.zero);
    });
  });

  group("reload contract", () {
    testWidgets("loads once per ValueKey", (WidgetTester tester) async {
      int calls = 0;
      Future<List<_Item>> load() async {
        calls++;
        return calls == 1 ? <_Item>[_alpha] : <_Item>[_beta];
      }

      await _pumpLoaded(tester, _card(key: const ValueKey<String>("a"), load: load));
      await _pumpLoaded(tester, _card(key: const ValueKey<String>("a"), load: load));
      expect(calls, 1);
      expect(find.text("Alpha"), findsOneWidget);

      await _pumpLoaded(tester, _card(key: const ValueKey<String>("b"), load: load));
      expect(calls, 2);
      expect(find.text("Beta"), findsOneWidget);
      expect(find.text("Alpha"), findsNothing);
    });
  });

  group("dispose", () {
    testWidgets("a load settling after unmount is dropped", (WidgetTester tester) async {
      final Completer<List<_Item>> ok = Completer<List<_Item>>();
      await pumpApp(tester, _card(load: () => ok.future));
      await pumpApp(tester, const SizedBox.shrink());

      ok.complete(<_Item>[_alpha]);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets("a load failing after unmount is dropped", (WidgetTester tester) async {
      final Completer<List<_Item>> failing = Completer<List<_Item>>();
      await pumpApp(tester, _card(load: () => failing.future));
      await pumpApp(tester, const SizedBox.shrink());

      failing.completeError(StateError("late"));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}

// async_summary_card_test.dart
//
// Widget tests for AsyncSummaryCard: the announced skeleton (pulsing, static
// under reduced motion), the loaded header / body / footnote / badge /
// trailing slot (a long badge capped without overflow, an empty one hidden
// with its gap), **bold** markup, the error state (a live region) and its
// retry, reloads on a
// reloadKey change (and none on a new closure alone), stale-result and
// dispose safety, StatusTones badge colours, plus a dark-theme smoke test.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/core/decorators/SkeletonPulse/index.dart";
import "package:flutter_skeleton/widgets/custom/AsyncSummaryCard/index.dart";
import "package:flutter_skeleton/widgets/custom/PillBadge/index.dart";
import "package:flutter_skeleton/widgets/custom/SkeletonBlock/index.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _title = "Summary";
const String _loadingKey = "custom.async_summary_card.loading";
const String _unavailableKey = "custom.async_summary_card.unavailable";
const String _retryKey = "custom.async_summary_card.retry";
const ValueKey<String> _trailingKey = ValueKey<String>("trailing");

/// Records load calls; each call waits on its own completer.
final class _FakeLoad {
  final List<Completer<AsyncSummary>> pending = <Completer<AsyncSummary>>[];

  int get calls => pending.length;

  Future<AsyncSummary> call() {
    final Completer<AsyncSummary> completer = Completer<AsyncSummary>();
    pending.add(completer);
    return completer.future;
  }
}

/// Optional card parameters used by the tests.
typedef _CardOptions = ({
  Object? reloadKey,
  Widget? headerTrailing,
  String? errorMessage,
  bool parseBold,
  IconData icon,
});

const _CardOptions _defaults = (
  reloadKey: null,
  headerTrailing: null,
  errorMessage: null,
  parseBold: true,
  icon: Icons.auto_awesome_rounded,
);

AsyncSummaryCard _card(Future<AsyncSummary> Function() load, [_CardOptions options = _defaults]) {
  return AsyncSummaryCard(
    title: _title,
    load: load,
    reloadKey: options.reloadKey,
    headerTrailing: options.headerTrailing,
    errorMessage: options.errorMessage,
    parseBold: options.parseBold,
    icon: options.icon,
  );
}

/// Pumps a card, resolves its first load with [summary] and returns the fake.
Future<_FakeLoad> _pumpLoaded(
  WidgetTester tester,
  AsyncSummary summary, {
  _CardOptions options = _defaults,
  ThemeData? theme,
}) async {
  final _FakeLoad fake = _FakeLoad();
  await pumpApp(tester, _card(fake.call, options), theme: theme);
  fake.pending.single.complete(summary);
  await tester.pump();
  return fake;
}

Finder _textButton(String label) {
  return find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((Widget w) => w is TextButton));
}

/// Pumps a card whose load (driven by [fake]) uses [key] as its reloadKey.
Future<void> _pumpWithKey(WidgetTester tester, _FakeLoad fake, Object key) {
  return pumpApp(
    tester,
    _card(() => fake.call(), (
      reloadKey: key,
      headerTrailing: null,
      errorMessage: null,
      parseBold: true,
      icon: Icons.auto_awesome_rounded,
    )),
  );
}

void main() {
  _loadingTests();
  _loadedTests();
  _boldTests();
  _errorTests();
  _reloadTests();
  _lifecycleTests();
  _toneTests();
}

void _loadingTests() {
  group("loading", () {
    testWidgets("shows the announced pulsing skeleton and calls load once", (WidgetTester tester) async {
      final _FakeLoad fake = _FakeLoad();
      await pumpApp(tester, _card(fake.call));
      await tester.pump(const Duration(milliseconds: 100));

      expect(fake.calls, 1);
      expect(find.bySemanticsLabel(_loadingKey), findsOneWidget);
      expect(find.byType(SkeletonPulse), findsOneWidget);
      expect(find.byType(SkeletonBlock), findsNWidgets(4));
      expect(find.text(_title), findsNothing);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
    });

    testWidgets("skeleton lines keep the source sizes", (WidgetTester tester) async {
      await pumpApp(tester, _card(_FakeLoad().call), surfaceSize: const Size(400, 400));
      await tester.pump();

      final List<Size> sizes = tester.widgetList<SkeletonBlock>(find.byType(SkeletonBlock)).map(
        (SkeletonBlock b) => tester.getSize(find.byWidget(b)),
      ).toList();
      // 400 - 2 × 16 padding = 368 for the full-width lines.
      expect(sizes, <Size>[const Size(368, 14), const Size(368, 14), const Size(200, 14), const Size(140, 12)]);
    });

    testWidgets("is static under reduced motion (no ticker, settles)", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: _card(_FakeLoad().call),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SkeletonPulse), findsNothing);
      expect(find.byType(SkeletonBlock), findsNWidgets(4));
      expect(find.bySemanticsLabel(_loadingKey), findsOneWidget);
    });
  });
}

void _loadedTests() {
  group("loaded", () {
    testWidgets("shows icon, title, badge, trailing, body and footnote", (WidgetTester tester) async {
      await _pumpLoaded(
        tester,
        const AsyncSummary(
          text: "Plain body.",
          footnote: "Generated note",
          badge: AsyncSummaryBadge(label: "High", tone: StatusTone.success),
        ),
        options: (
          reloadKey: null,
          headerTrailing: const SizedBox(key: ValueKey<String>("trailing"), width: 24, height: 24),
          errorMessage: null,
          parseBold: true,
          icon: Icons.auto_awesome_rounded,
        ),
      );

      expect(find.bySemanticsLabel(_loadingKey), findsNothing);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
      expect(find.text(_title), findsOneWidget);
      expect(find.text("High"), findsOneWidget);
      expect(find.byKey(const ValueKey<String>("trailing")), findsOneWidget);
      expect(find.text("Plain body."), findsOneWidget);
      expect(find.text("Generated note"), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);

      // Badge then trailing, both right of the title.
      final double badgeX = tester.getCenter(find.byType(StatusPill)).dx;
      final double trailingX = tester.getCenter(find.byKey(const ValueKey<String>("trailing"))).dx;
      expect(tester.getCenter(find.text(_title)).dx, lessThan(badgeX));
      expect(badgeX, lessThan(trailingX));
    });

    testWidgets("title is a semantic header and the icon is decorative", (WidgetTester tester) async {
      await _pumpLoaded(tester, const AsyncSummary(text: "Body"));

      expect(tester.getSemantics(find.text(_title)), isSemantics(label: _title, isHeader: true));
      final Icon icon = tester.widget<Icon>(find.byIcon(Icons.auto_awesome_rounded));
      expect(icon.semanticLabel, isNull);
    });

    testWidgets("hides the badge, the footnote and the trailing slot when absent", (WidgetTester tester) async {
      await _pumpLoaded(tester, const AsyncSummary(text: "Body", footnote: ""));

      expect(find.byType(StatusPill), findsNothing);
      final Finder texts = find.descendant(of: find.byType(AsyncSummaryCard), matching: find.byType(Text));
      expect(texts, findsNWidgets(2)); // title + body only
    });

    testWidgets("uses a custom header icon", (WidgetTester tester) async {
      await _pumpLoaded(
        tester,
        const AsyncSummary(text: "Body"),
        options: (
          reloadKey: null,
          headerTrailing: null,
          errorMessage: null,
          parseBold: true,
          icon: Icons.lightbulb_outline,
        ),
      );

      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
    });

    testWidgets("a long title wraps instead of overflowing", (WidgetTester tester) async {
      final _FakeLoad fake = _FakeLoad();
      await pumpApp(
        tester,
        AsyncSummaryCard(title: "A very long header title " * 4, load: fake.call),
        surfaceSize: const Size(320, 600),
      );
      fake.pending.single.complete(
        const AsyncSummary(text: "Body", badge: AsyncSummaryBadge(label: "Medium")),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text("Medium"), findsOneWidget);
    });

    testWidgets("a long badge label is capped and ellipsised instead of overflowing", (WidgetTester tester) async {
      const String longLabel = "A rather long badge label that is long";
      final _FakeLoad fake = _FakeLoad();
      await pumpApp(tester, _card(fake.call), surfaceSize: const Size(320, 600));
      fake.pending.single.complete(
        const AsyncSummary(text: "Body", badge: AsyncSummaryBadge(label: longLabel)),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      final Rect badge = tester.getRect(find.byType(StatusPill));
      expect(badge.width, kDefaultPadding * 20);
      expect(badge.right, 320 - kDefaultPadding * 2); // flush right, inside the header padding
      expect(tester.renderObject<RenderParagraph>(find.text(longLabel)).didExceedMaxLines, isTrue);
      expect(find.bySemanticsLabel(longLabel), findsOneWidget);
      expect(tester.getTopLeft(find.text(_title)).dx, lessThan(badge.left));
    });

    testWidgets("a badge with an empty label is hidden with its gap", (WidgetTester tester) async {
      await _pumpLoaded(
        tester,
        const AsyncSummary(text: "Body", badge: AsyncSummaryBadge(label: "")),
        options: (
          reloadKey: null,
          headerTrailing: const SizedBox(key: _trailingKey, width: 24, height: 24),
          errorMessage: null,
          parseBold: true,
          icon: Icons.auto_awesome_rounded,
        ),
      );

      expect(find.byType(StatusPill), findsNothing);
      final double gap = tester.getTopLeft(find.byKey(_trailingKey)).dx - tester.getTopRight(find.text(_title)).dx;
      expect(gap, kDefaultPadding);
    });
  });
}

void _boldTests() {
  group("bold markup", () {
    testWidgets("renders **x** in w700 without markers", (WidgetTester tester) async {
      await _pumpLoaded(tester, const AsyncSummary(text: "a **b** c"));

      expect(find.text("a b c"), findsOneWidget);
      expect(find.textContaining("**"), findsNothing);
      expect(find.bySemanticsLabel("a b c"), findsOneWidget);

      final TextSpan root = tester.widget<Text>(find.text("a b c")).textSpan! as TextSpan;
      final List<TextSpan> spans = root.children!.cast<TextSpan>();
      expect(spans.map((TextSpan s) => s.text), <String>["a ", "b", " c"]);
      expect(spans[1].style?.fontWeight, FontWeight.w700);
      expect(spans[0].style, isNull);
      expect(spans[2].style, isNull);
    });

    testWidgets("keeps an unmatched ** literal", (WidgetTester tester) async {
      await _pumpLoaded(tester, const AsyncSummary(text: "**x** and ** alone"));

      expect(find.text("x and ** alone"), findsOneWidget);
    });

    testWidgets("parseBold false renders the asterisks", (WidgetTester tester) async {
      await _pumpLoaded(
        tester,
        const AsyncSummary(text: "a **b** c"),
        options: (
          reloadKey: null,
          headerTrailing: null,
          errorMessage: null,
          parseBold: false,
          icon: Icons.auto_awesome_rounded,
        ),
      );

      expect(find.text("a **b** c"), findsOneWidget);
    });
  });
}

void _errorTests() {
  group("error", () {
    testWidgets("shows the default message and a 48 dp retry button", (WidgetTester tester) async {
      final _FakeLoad fake = _FakeLoad();
      await pumpApp(tester, _card(fake.call));
      fake.pending.single.completeError(StateError("boom"));
      await tester.pump();

      expect(find.text(_unavailableKey), findsOneWidget);
      expect(
        tester.getSemantics(find.text(_unavailableKey)),
        isSemantics(label: _unavailableKey, isLiveRegion: true),
      );
      expect(find.text(_title), findsNothing);
      final Size size = tester.getSize(_textButton(_retryKey));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets("a synchronous throw also shows the error state", (WidgetTester tester) async {
      await pumpApp(tester, _card(() => throw StateError("sync")));
      await tester.pump();

      expect(find.text(_unavailableKey), findsOneWidget);
    });

    testWidgets("uses a custom error message", (WidgetTester tester) async {
      final _FakeLoad fake = _FakeLoad();
      await pumpApp(
        tester,
        _card(fake.call, (
          reloadKey: null,
          headerTrailing: null,
          errorMessage: "Nothing to show",
          parseBold: true,
          icon: Icons.auto_awesome_rounded,
        )),
      );
      fake.pending.single.completeError(StateError("boom"));
      await tester.pump();

      expect(find.text("Nothing to show"), findsOneWidget);
      expect(find.text(_unavailableKey), findsNothing);
    });

    testWidgets("retry reloads through the skeleton", (WidgetTester tester) async {
      final _FakeLoad fake = _FakeLoad();
      await pumpApp(tester, _card(fake.call));
      fake.pending.single.completeError(StateError("boom"));
      await tester.pump();

      await tester.tap(find.text(_retryKey));
      await tester.pump();
      expect(fake.calls, 2);
      expect(find.bySemanticsLabel(_loadingKey), findsOneWidget);
      expect(find.text(_unavailableKey), findsNothing);

      fake.pending[1].complete(const AsyncSummary(text: "Recovered"));
      await tester.pump();
      expect(find.text("Recovered"), findsOneWidget);
    });
  });
}

void _reloadTests() {
  group("reloadKey", () {
    testWidgets("a different key reloads through the skeleton", (WidgetTester tester) async {
      final _FakeLoad fake = _FakeLoad();
      await _pumpWithKey(tester, fake, 1);
      fake.pending[0].complete(const AsyncSummary(text: "First"));
      await tester.pump();
      expect(find.text("First"), findsOneWidget);

      await _pumpWithKey(tester, fake, 2);
      expect(fake.calls, 2);
      expect(find.bySemanticsLabel(_loadingKey), findsOneWidget);
      expect(find.text("First"), findsNothing);

      fake.pending[1].complete(const AsyncSummary(text: "Second"));
      await tester.pump();
      expect(find.text("Second"), findsOneWidget);
    });

    testWidgets("an equal key with a new closure does not reload", (WidgetTester tester) async {
      final _FakeLoad fake = _FakeLoad();
      await _pumpWithKey(tester, fake, (1, "a"));
      fake.pending[0].complete(const AsyncSummary(text: "Kept"));
      await tester.pump();

      await _pumpWithKey(tester, fake, (1, "a"));
      await tester.pump();
      expect(fake.calls, 1);
      expect(find.text("Kept"), findsOneWidget);
    });

    testWidgets("drops a superseded result that arrives last", (WidgetTester tester) async {
      final _FakeLoad fake = _FakeLoad();
      await _pumpWithKey(tester, fake, 1);
      await _pumpWithKey(tester, fake, 2);

      fake.pending[1].complete(const AsyncSummary(text: "New"));
      await tester.pump();
      fake.pending[0].complete(const AsyncSummary(text: "Old"));
      await tester.pump();

      expect(find.text("New"), findsOneWidget);
      expect(find.text("Old"), findsNothing);
    });

    testWidgets("drops a superseded result or error that arrives first", (WidgetTester tester) async {
      final _FakeLoad fake = _FakeLoad();
      await _pumpWithKey(tester, fake, 1);
      await _pumpWithKey(tester, fake, 2);
      await _pumpWithKey(tester, fake, 3);

      fake.pending[0].complete(const AsyncSummary(text: "Old"));
      fake.pending[1].completeError(StateError("stale"));
      await tester.pump();
      expect(find.text("Old"), findsNothing);
      expect(find.text(_unavailableKey), findsNothing);
      expect(find.bySemanticsLabel(_loadingKey), findsOneWidget);

      fake.pending[2].complete(const AsyncSummary(text: "Latest"));
      await tester.pump();
      expect(find.text("Latest"), findsOneWidget);
    });
  });
}

void _lifecycleTests() {
  group("dispose", () {
    testWidgets("a result after unmount is ignored", (WidgetTester tester) async {
      final _FakeLoad fake = _FakeLoad();
      await pumpApp(tester, _card(fake.call));
      await tester.pumpWidget(const SizedBox.shrink());

      fake.pending.single.complete(const AsyncSummary(text: "Late"));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets("an error after unmount is ignored", (WidgetTester tester) async {
      final _FakeLoad fake = _FakeLoad();
      await pumpApp(tester, _card(fake.call));
      await tester.pumpWidget(const SizedBox.shrink());

      fake.pending.single.completeError(StateError("late"));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}

void _toneTests() {
  group("badge tones", () {
    testWidgets("a toned badge is a dense StatusPill with StatusTones colours", (WidgetTester tester) async {
      await _pumpLoaded(
        tester,
        const AsyncSummary(text: "Body", badge: AsyncSummaryBadge(label: "High", tone: StatusTone.success)),
      );

      final StatusPill pill = tester.widget<StatusPill>(find.byType(StatusPill));
      expect(pill.tone, StatusTone.success);
      expect(pill.dense, isTrue);
      final ToneColors colors = StatusTones.colorsOf(tester.element(find.byType(StatusPill)), StatusTone.success);
      final PillBadge badge = tester.widget<PillBadge>(find.byType(PillBadge));
      expect(badge.backgroundColor, colors.container);
      expect(badge.color, colors.onContainer);
    });

    testWidgets("a badge without tone is neutral", (WidgetTester tester) async {
      await _pumpLoaded(tester, const AsyncSummary(text: "Body", badge: AsyncSummaryBadge(label: "Low")));

      expect(tester.widget<StatusPill>(find.byType(StatusPill)).tone, StatusTone.neutral);
      final ColorScheme cs = Theme.of(tester.element(find.byType(StatusPill))).colorScheme;
      expect(tester.widget<PillBadge>(find.byType(PillBadge)).backgroundColor, cs.surfaceContainerHighest);
    });

    testWidgets("the badge is announced once with its semantics label", (WidgetTester tester) async {
      await _pumpLoaded(
        tester,
        const AsyncSummary(
          text: "Body",
          badge: AsyncSummaryBadge(label: "High", tone: StatusTone.success, semanticsLabel: "Level: high"),
        ),
      );

      expect(find.bySemanticsLabel("Level: high"), findsOneWidget);
      expect(find.bySemanticsLabel("High"), findsNothing);
    });

    testWidgets("dark theme smoke test", (WidgetTester tester) async {
      await _pumpLoaded(
        tester,
        const AsyncSummary(
          text: "Dark **body**",
          footnote: "Note",
          badge: AsyncSummaryBadge(label: "Medium", tone: StatusTone.warning),
        ),
        theme: AppTheme.dark(),
      );

      expect(tester.takeException(), isNull);
      expect(find.text("Dark body"), findsOneWidget);
      final ToneColors colors = StatusTones.colorsOf(tester.element(find.byType(StatusPill)), StatusTone.warning);
      expect(Theme.of(tester.element(find.byType(StatusPill))).brightness, Brightness.dark);
      expect(tester.widget<PillBadge>(find.byType(PillBadge)).backgroundColor, colors.container);
    });
  });
}

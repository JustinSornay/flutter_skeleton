// status_pill_group_test.dart
//
// Widget tests for StatusPillGroup: the loading slot (16 dp Loader in a
// one-row 32 dp box at the default text scale), loaded items rendered as
// StatusPill widgets in a Wrap (order, icons, tones, fill and text colours,
// semantics, empty labels skipped, wrapping), the empty list, the failure pill
// (sync and async throws, errorLabel override, live region, own width under a
// tight parent), the load-once / ValueKey reload contract, dispose safety and
// the dark theme. One function per group keeps main() small.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";
import "package:flutter_skeleton/widgets/custom/StatusPillGroup/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _unavailableKey = "custom.status_pill_group.unavailable";

const StatusPillGroupItem _good = StatusPillGroupItem(
  label: "99.8 % up",
  icon: Icons.check_circle_outline,
  tone: StatusTone.success,
);

const StatusPillGroupItem _slow = StatusPillGroupItem(
  label: "1.2 s",
  icon: Icons.speed_outlined,
  tone: StatusTone.warning,
);

const StatusPillGroupItem _usage = StatusPillGroupItem(
  label: "42 / ∞",
  icon: Icons.data_usage_outlined,
  tone: StatusTone.primary,
);

Future<List<StatusPillGroupItem>> Function() _returns(List<StatusPillGroupItem> items) {
  return () async => items;
}

Future<List<StatusPillGroupItem>> _failsAsync() async {
  throw StateError("boom");
}

Future<List<StatusPillGroupItem>> _failsSync() {
  throw StateError("sync boom");
}

/// Pumps [group] and lets its load future settle (no pumpAndSettle: the
/// Loader spins forever).
Future<void> _pumpLoaded(WidgetTester tester, Widget group, {ThemeData? theme}) async {
  await pumpApp(tester, group, theme: theme);
  await tester.pump();
}

Finder _inGroup(Finder matching) {
  return find.descendant(of: find.byType(StatusPillGroup), matching: matching);
}

List<StatusPill> _pills(WidgetTester tester) {
  return tester.widgetList<StatusPill>(_inGroup(find.byType(StatusPill))).toList();
}

ToneColors _tone(WidgetTester tester, StatusTone tone) {
  return StatusTones.colorsOf(tester.element(find.byType(StatusPillGroup)), tone);
}

Color? _textColor(WidgetTester tester, String text) => tester.widget<Text>(find.text(text)).style?.color;

/// Fill of the pill showing [label] (the decorated Container of its PillBadge).
Color? _fillColor(WidgetTester tester, String label) {
  final Finder pill = find.ancestor(of: find.text(label), matching: find.byType(StatusPill));
  final Container box = tester.widget<Container>(find.descendant(of: pill, matching: find.byType(Container)).first);
  return (box.decoration as BoxDecoration?)?.color;
}

void main() {
  group("loading", _loadingTests);
  group("loaded", _loadedTests);
  group("error", _errorTests);
  group("lifecycle", _lifecycleTests);
  group("dark theme", _darkThemeTests);
}

void _loadingTests() {
  testWidgets("shows one 16 dp Loader in a 32 dp slot and no pill", (WidgetTester tester) async {
    final Completer<List<StatusPillGroupItem>> pending = Completer<List<StatusPillGroupItem>>();
    await pumpApp(tester, StatusPillGroup(load: () => pending.future));

    expect(_inGroup(find.byType(Loader)), findsOneWidget);
    expect(tester.widget<Loader>(find.byType(Loader)).size, kDefaultPadding * 2);
    expect(tester.getSize(_inGroup(find.byType(SizedBox)).first).height, kDefaultPadding * 4);
    expect(_inGroup(find.byType(StatusPill)), findsNothing);
    expect(find.bySemanticsLabel("common.loading"), findsOneWidget);

    pending.complete(<StatusPillGroupItem>[]);
    await tester.pump();
  });

  testWidgets("at the default text scale the loading slot is as tall as a pill row", (WidgetTester tester) async {
    await _pumpLoaded(tester, StatusPillGroup(load: _returns(<StatusPillGroupItem>[_good])));

    expect(tester.getSize(find.byType(StatusPill)).height, kDefaultPadding * 4);
  });
}

void _loadedTests() {
  testWidgets("renders every item as a StatusPill, in order, in an 8 dp Wrap", (WidgetTester tester) async {
    await _pumpLoaded(tester, StatusPillGroup(load: _returns(<StatusPillGroupItem>[_good, _slow, _usage])));

    final List<StatusPill> pills = _pills(tester);
    expect(pills.map((StatusPill p) => p.label), <String>[_good.label, _slow.label, _usage.label]);
    expect(pills.map((StatusPill p) => p.icon), <IconData?>[_good.icon, _slow.icon, _usage.icon]);
    expect(pills.map((StatusPill p) => p.tone), <StatusTone>[_good.tone, _slow.tone, _usage.tone]);
    expect(pills.every((StatusPill p) => !p.dense && p.letter == null), isTrue);

    final Wrap wrap = tester.widget<Wrap>(_inGroup(find.byType(Wrap)));
    expect(wrap.spacing, kDefaultPadding);
    expect(wrap.runSpacing, kDefaultPadding);
    expect(_inGroup(find.byType(Loader)), findsNothing);
  });

  testWidgets("an item without icon draws no icon; default tone is neutral", (WidgetTester tester) async {
    await _pumpLoaded(
      tester,
      StatusPillGroup(load: _returns(<StatusPillGroupItem>[const StatusPillGroupItem(label: "Idle")])),
    );

    expect(_pills(tester).single.tone, StatusTone.neutral);
    expect(_inGroup(find.byType(Icon)), findsNothing);
    expect(find.text("Idle"), findsOneWidget);
  });

  testWidgets("pills paint the tone onContainer colour on its container", (WidgetTester tester) async {
    await _pumpLoaded(tester, StatusPillGroup(load: _returns(<StatusPillGroupItem>[_good, _slow, _usage])));

    for (final StatusPillGroupItem item in <StatusPillGroupItem>[_good, _slow, _usage]) {
      final ToneColors colors = _tone(tester, item.tone);
      expect(_fillColor(tester, item.label), colors.container);
      expect(_textColor(tester, item.label), colors.onContainer);
      expect(tester.widget<Icon>(find.byIcon(item.icon!)).color, colors.onContainer);
    }
  });

  testWidgets("each pill is one semantics node: semanticsLabel, else label", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await _pumpLoaded(
      tester,
      StatusPillGroup(
        load: _returns(<StatusPillGroupItem>[
          _good,
          const StatusPillGroupItem(label: "245 ms", semanticsLabel: "Average delay 245 milliseconds"),
        ]),
      ),
    );

    expect(find.bySemanticsLabel(_good.label), findsOneWidget);
    expect(find.bySemanticsLabel("Average delay 245 milliseconds"), findsOneWidget);
    expect(find.bySemanticsLabel("245 ms"), findsNothing);
    handle.dispose();
  });

  testWidgets("items with an empty label are skipped", (WidgetTester tester) async {
    await _pumpLoaded(
      tester,
      StatusPillGroup(load: _returns(<StatusPillGroupItem>[_good, const StatusPillGroupItem(label: ""), _slow])),
    );

    expect(_pills(tester).map((StatusPill p) => p.label), <String>[_good.label, _slow.label]);
  });

  testWidgets("wraps onto a second run in a narrow parent without overflow", (WidgetTester tester) async {
    await _pumpLoaded(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 160,
          child: StatusPillGroup(load: _returns(<StatusPillGroupItem>[_good, _slow, _usage])),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final double firstTop = tester.getTopLeft(find.text(_good.label)).dy;
    final double lastTop = tester.getTopLeft(find.text(_usage.label)).dy;
    expect(lastTop, greaterThan(firstTop));
  });

  testWidgets("an empty list renders nothing", (WidgetTester tester) async {
    await _pumpLoaded(tester, StatusPillGroup(load: _returns(<StatusPillGroupItem>[])));

    expect(_inGroup(find.byType(StatusPill)), findsNothing);
    expect(_inGroup(find.byType(Loader)), findsNothing);
    expect(_inGroup(find.byType(Wrap)), findsNothing);
    expect(tester.getSize(find.byType(StatusPillGroup)), Size.zero);
  });
}

void _errorTests() {
  testWidgets("an async failure shows one neutral error pill with the built-in key", (WidgetTester tester) async {
    await _pumpLoaded(tester, const StatusPillGroup(load: _failsAsync));

    final StatusPill pill = _pills(tester).single;
    expect(pill.label, _unavailableKey);
    expect(pill.icon, Icons.error_outline);
    expect(pill.tone, StatusTone.neutral);
    expect(find.text(_unavailableKey), findsOneWidget);
    expect(_inGroup(find.byType(Loader)), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("a synchronous throw is caught the same way", (WidgetTester tester) async {
    await _pumpLoaded(tester, const StatusPillGroup(load: _failsSync));

    expect(find.text(_unavailableKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("errorLabel overrides the built-in text", (WidgetTester tester) async {
    await _pumpLoaded(tester, const StatusPillGroup(load: _failsAsync, errorLabel: "Oops"));

    expect(find.text("Oops"), findsOneWidget);
    expect(find.text(_unavailableKey), findsNothing);
  });

  testWidgets("an empty errorLabel shows nothing on failure", (WidgetTester tester) async {
    await _pumpLoaded(tester, const StatusPillGroup(load: _failsAsync, errorLabel: ""));

    expect(find.text(_unavailableKey), findsNothing);
    expect(_inGroup(find.byType(Text)), findsNothing);
  });

  testWidgets("the error pill is announced as a live region", (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await _pumpLoaded(tester, const StatusPillGroup(load: _failsAsync));

    expect(
      tester.getSemantics(find.bySemanticsLabel(_unavailableKey)),
      isSemantics(label: _unavailableKey, isLiveRegion: true),
    );
    handle.dispose();
  });

  testWidgets("in a stretched parent the error pill keeps its own width", (WidgetTester tester) async {
    await _pumpLoaded(
      tester,
      const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[StatusPillGroup(load: _failsAsync)],
      ),
    );

    final double groupWidth = tester.getSize(find.byType(StatusPillGroup)).width;
    expect(groupWidth, tester.view.physicalSize.width / tester.view.devicePixelRatio);
    expect(tester.getSize(find.byType(StatusPill)).width, lessThan(groupWidth));
    expect(tester.getTopLeft(find.byType(StatusPill)).dx, tester.getTopLeft(find.byType(StatusPillGroup)).dx);
  });
}

void _lifecycleTests() {
  testWidgets("loads once; a new closure with the same key does not reload", (WidgetTester tester) async {
    int calls = 0;
    Future<List<StatusPillGroupItem>> load() async {
      calls++;
      return <StatusPillGroupItem>[_good];
    }

    Future<List<StatusPillGroupItem>> otherLoad() async {
      calls++;
      return <StatusPillGroupItem>[_slow];
    }

    await _pumpLoaded(tester, StatusPillGroup(key: const ValueKey<String>("a"), load: load));
    expect(calls, 1);

    await _pumpLoaded(tester, StatusPillGroup(key: const ValueKey<String>("a"), load: otherLoad));
    expect(calls, 1);
    expect(find.text(_good.label), findsOneWidget);

    await _pumpLoaded(tester, StatusPillGroup(key: const ValueKey<String>("b"), load: load));
    expect(calls, 2);
  });

  testWidgets("completing after unmount is ignored (success and failure)", (WidgetTester tester) async {
    final Completer<List<StatusPillGroupItem>> ok = Completer<List<StatusPillGroupItem>>();
    final Completer<List<StatusPillGroupItem>> ko = Completer<List<StatusPillGroupItem>>();
    await pumpApp(
      tester,
      Column(
        children: <Widget>[
          StatusPillGroup(load: () => ok.future),
          StatusPillGroup(load: () => ko.future),
        ],
      ),
    );

    await pumpApp(tester, const SizedBox.shrink());
    ok.complete(<StatusPillGroupItem>[_good]);
    ko.completeError(StateError("late"));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(StatusPillGroup), findsNothing);
  });
}

void _darkThemeTests() {
  testWidgets("every tone renders with its dark tone colours", (WidgetTester tester) async {
    final List<StatusPillGroupItem> items = <StatusPillGroupItem>[
      for (final StatusTone tone in StatusTone.values)
        StatusPillGroupItem(label: tone.name, icon: tone.icon, tone: tone),
    ];
    await _pumpLoaded(tester, StatusPillGroup(load: _returns(items)), theme: AppTheme.dark());

    expect(Theme.of(tester.element(find.byType(StatusPillGroup))).brightness, Brightness.dark);
    expect(_pills(tester), hasLength(StatusTone.values.length));
    for (final StatusTone tone in StatusTone.values) {
      expect(_fillColor(tester, tone.name), _tone(tester, tone).container);
      expect(_textColor(tester, tone.name), _tone(tester, tone).onContainer);
    }
    expect(tester.takeException(), isNull);
  });
}

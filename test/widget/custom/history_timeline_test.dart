// history_timeline_test.dart
//
// Widget tests for HistoryTimeline: one caption per entry, the empty state,
// the 48 dp strip and hit boxes, date-proportional and equal-date placement,
// the track line and the current dot's halo, the "+N earlier" pill
// (collapse, inline expand, semantics, 48 dp target with the ink on the
// bordered pill only, no overlap with the dots), tap routing to
// onTapCurrent / onTapPast, pointers on dots closer than 24 dp reaching the
// dot under them (taps, hover, tooltip placement, same-date entries), inert
// dots when a callback is null, semantics and tooltip text (default and
// custom hints, empty labels), the default MMMd caption for the ambient
// locale, mouse hover, stale exits, the hover reset on didUpdateWidget, and a
// dark-theme smoke test.

import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/HistoryTimeline/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:intl/intl.dart";

import "../../helpers/widget_test_helpers.dart";

const Size _surface = Size(800, 300);

/// Where the test mouse rests: below the strip, away from every dot.
const Offset _away = Offset(400, 250);
const String _currentKey = "custom.history_timeline.current";
const String _resumeKey = "custom.history_timeline.resume_here";
const String _olderKey = "custom.history_timeline.older";
const String _showOlderKey = "custom.history_timeline.show_older";

/// A history entry of the fixture.
@immutable
final class _Entry {
  const _Entry(this.id, this.date, this.label);

  final String id;
  final DateTime date;
  final String label;
}

/// Entries in the order of [days] (pass them newest first), dated
/// `day` March 2026 (UTC) and labelled `e<day>`.
List<_Entry> _entries(List<int> days) {
  return days
      .map((int day) => _Entry("$day", DateTime.utc(2026, 3, day), "e$day"))
      .toList(growable: false);
}

/// An entry dated [day] [month] 2026 (UTC), labelled [label] or `e<day>`.
_Entry _on(int month, int day, [String? label]) {
  return _Entry("$month-$day", DateTime.utc(2026, month, day), label ?? "e$day");
}

/// Newest first: 31 and 30 March (8 dp apart on the axis, nudged to 12 dp),
/// 15 and 14 February (also 8 dp apart, mid-strip) and 1 January.
List<_Entry> _cluster() {
  return <_Entry>[_on(3, 31), _on(3, 30), _on(2, 15), _on(2, 14), _on(1, 1)];
}

/// A timeline over [items] whose captions are `d<day of month>`.
HistoryTimeline<_Entry> _timeline(
  List<_Entry> items, {
  int maxVisible = 6,
  ValueChanged<_Entry>? onTapCurrent,
  ValueChanged<_Entry>? onTapPast,
  String Function(_Entry item)? labelOf,
  String? currentHint,
  String? pastHint,
}) {
  return HistoryTimeline<_Entry>(
    items: items,
    dateOf: (_Entry entry) => entry.date,
    labelOf: labelOf ?? (_Entry entry) => entry.label,
    onTapCurrent: onTapCurrent,
    onTapPast: onTapPast,
    maxVisible: maxVisible,
    dateLabelOf: (DateTime date) => "d${date.day}",
    currentHint: currentHint,
    pastHint: pastHint,
  );
}

/// The 48 dp hit box of the dot captioned [caption].
Finder _hitBox(String caption) {
  return find.ancestor(of: find.text(caption), matching: find.byType(GestureDetector)).first;
}

/// Centre of the visible circle of the dot captioned [caption].
Offset _circleCentre(WidgetTester tester, String caption) {
  return tester.getCenter(find.descendant(of: _hitBox(caption), matching: find.byType(DecoratedBox)));
}

/// The visible circle of the dot whose tooltip reads [message].
Finder _circleWithTooltip(String message) {
  return find.descendant(
    of: find.byWidgetPredicate((Widget widget) => widget is Tooltip && widget.message == message),
    matching: find.byType(DecoratedBox),
  );
}

BoxDecoration _dot(WidgetTester tester, String caption) {
  final Finder box = find.descendant(of: _hitBox(caption), matching: find.byType(DecoratedBox));
  return tester.widget<DecoratedBox>(box).decoration as BoxDecoration;
}

Tooltip _tooltip(WidgetTester tester, String caption) {
  return tester.widget<Tooltip>(find.ancestor(of: find.text(caption), matching: find.byType(Tooltip)));
}

MouseRegion _mouseRegion(WidgetTester tester, String caption) {
  return tester.widget<MouseRegion>(
    find.ancestor(of: find.text(caption), matching: find.byType(MouseRegion)).first,
  );
}

Finder _pill() => find.textContaining("+");

/// The track line: the only ColoredBox of the timeline.
Finder _track() {
  return find.descendant(of: find.byType(HistoryTimeline<_Entry>), matching: find.byType(ColoredBox));
}

ColorScheme _scheme(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(HistoryTimeline<_Entry>))).colorScheme;
}

/// A mouse pointer resting at [_away]; removed at the end of the test.
Future<TestGesture> _mouse(WidgetTester tester) async {
  final TestGesture mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: _away);
  addTearDown(mouse.removePointer);
  return mouse;
}

/// Moves [mouse] away and lets the tooltip's dismiss timers run out.
Future<void> _parkMouse(WidgetTester tester, TestGesture mouse) async {
  await mouse.moveTo(_away);
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group("layout", () {
    testWidgets("shows one caption per entry and no pill when the entries fit", (WidgetTester tester) async {
      await pumpApp(tester, _timeline(_entries(<int>[9, 6, 3])), surfaceSize: _surface);

      for (final String caption in <String>["d9", "d6", "d3"]) {
        expect(find.text(caption), findsOneWidget);
      }
      expect(_pill(), findsNothing);
    });

    testWidgets("renders an empty kMinTapTarget-tall box for no entries", (WidgetTester tester) async {
      await pumpApp(tester, _timeline(const <_Entry>[]), surfaceSize: _surface);

      expect(tester.getSize(find.byType(HistoryTimeline<_Entry>)).height, kMinTapTarget);
      expect(find.byType(Tooltip), findsNothing);
      expect(_pill(), findsNothing);
    });

    testWidgets("is kMinTapTarget tall with 48 dp hit boxes", (WidgetTester tester) async {
      await pumpApp(tester, _timeline(_entries(<int>[9, 6, 3])), surfaceSize: _surface);

      expect(tester.getSize(find.byType(HistoryTimeline<_Entry>)).height, kMinTapTarget);
      for (final String caption in <String>["d9", "d6", "d3"]) {
        final Size size = tester.getSize(_hitBox(caption));
        expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
        expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
      }
    });

    testWidgets("places the oldest entry left, the current right, the rest by date", (WidgetTester tester) async {
      await pumpApp(tester, _timeline(_entries(<int>[21, 11, 1])), surfaceSize: _surface);

      final double oldest = tester.getCenter(_hitBox("d1")).dx;
      final double middle = tester.getCenter(_hitBox("d11")).dx;
      final double current = tester.getCenter(_hitBox("d21")).dx;
      expect(oldest, kMinTapTarget / 2);
      expect(current, _surface.width - kMinTapTarget / 2);
      expect(middle, moreOrLessEquals((oldest + current) / 2, epsilon: 1));
    });

    testWidgets("spreads equal dates evenly with the current entry rightmost", (WidgetTester tester) async {
      final DateTime same = DateTime.utc(2026, 3, 5);
      final List<_Entry> items = <_Entry>[
        _Entry("a", same, "first"),
        _Entry("b", same, "second"),
        _Entry("c", same, "third"),
      ];
      await pumpApp(tester, _timeline(items), surfaceSize: _surface);

      // Tooltips in paint order: oldest first.
      final List<Tooltip> tooltips = tester.widgetList<Tooltip>(find.byType(Tooltip)).toList();
      final List<double> xs = tooltips
          .map((Tooltip tooltip) => tester.getCenter(find.byWidget(tooltip)).dx)
          .toList();
      expect(xs, hasLength(3));
      expect(xs[0], lessThan(xs[1]));
      expect(xs[1], lessThan(xs[2]));
      expect(tooltips.last.message, "first · $_currentKey");
      expect(tooltips.first.message, "third · $_resumeKey");
    });

    testWidgets("draws the outlineVariant track only for two or more dots", (WidgetTester tester) async {
      await pumpApp(tester, _timeline(_entries(<int>[9, 6, 3])), surfaceSize: _surface);
      expect(_track(), findsOneWidget);
      expect(tester.widget<ColoredBox>(_track()).color, _scheme(tester).outlineVariant);

      await pumpApp(tester, _timeline(_entries(<int>[9])), surfaceSize: _surface);
      expect(_track(), findsNothing);
    });

    testWidgets("gives the current dot a halo and past dots none", (WidgetTester tester) async {
      await pumpApp(tester, _timeline(_entries(<int>[9, 6, 3])), surfaceSize: _surface);

      expect(_dot(tester, "d9").boxShadow, isNotEmpty);
      expect(_dot(tester, "d6").boxShadow, isNull);
      expect(_dot(tester, "d3").boxShadow, isNull);
    });
  });

  group("overflow pill", () {
    testWidgets("collapses the oldest entries and expands inline", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _timeline(_entries(<int>[8, 7, 6, 5, 4, 3, 2, 1])),
        surfaceSize: _surface,
      );

      expect(find.text("+2 $_olderKey"), findsOneWidget);
      for (final String caption in <String>["d8", "d7", "d6", "d5", "d4", "d3"]) {
        expect(find.text(caption), findsOneWidget);
      }
      expect(find.text("d2"), findsNothing);
      expect(find.text("d1"), findsNothing);

      await tester.tap(_pill());
      await tester.pump();

      expect(_pill(), findsNothing);
      for (int day = 1; day <= 8; day++) {
        expect(find.text("d$day"), findsOneWidget);
      }
    });

    testWidgets("is a 48 dp button labelled show_older", (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpApp(
        tester,
        _timeline(_entries(<int>[8, 7, 6, 5, 4, 3, 2, 1])),
        surfaceSize: _surface,
      );

      final Size size = tester.getSize(find.bySemanticsLabel(_showOlderKey));
      expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
      expect(
        tester.getSemantics(find.bySemanticsLabel(_showOlderKey)),
        isSemantics(label: _showOlderKey, isButton: true, hasTapAction: true),
      );
      semantics.dispose();
    });

    testWidgets("draws its ink on the bordered pill, not on the whole target", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _timeline(_entries(<int>[8, 7, 6, 5, 4, 3, 2, 1])),
        surfaceSize: _surface,
      );

      final Finder ink = find.ancestor(of: _pill(), matching: find.byType(InkWell));
      final Finder border = find.ancestor(of: _pill(), matching: find.byType(DecoratedBox)).first;
      expect(tester.getRect(ink), tester.getRect(border));
      expect(tester.getSize(ink).height, lessThan(kMinTapTarget));
    });

    testWidgets("a tap around the pill, inside its 48 dp target, expands the strip", (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpApp(
        tester,
        _timeline(_entries(<int>[8, 7, 6, 5, 4, 3, 2, 1])),
        surfaceSize: _surface,
      );

      final Rect target = tester.getRect(find.bySemanticsLabel(_showOlderKey));
      final Rect pill = tester.getRect(find.ancestor(of: _pill(), matching: find.byType(InkWell)));
      expect(target.top, lessThan(pill.top));
      await tester.tapAt(Offset(pill.center.dx, (target.top + pill.top) / 2));
      await tester.pump();

      expect(_pill(), findsNothing);
      expect(find.text("d1"), findsOneWidget);
      semantics.dispose();
    });

    testWidgets("keeps every dot left of the pill", (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpApp(
        tester,
        _timeline(_entries(<int>[8, 7, 6, 5, 4, 3, 2, 1])),
        surfaceSize: _surface,
      );

      final double pillLeft = tester.getRect(find.bySemanticsLabel(_showOlderKey)).left;
      expect(tester.getRect(_hitBox("d8")).right, lessThanOrEqualTo(pillLeft));
      semantics.dispose();
    });
  });

  group("taps", () {
    testWidgets("tapping the current dot calls onTapCurrent only", (WidgetTester tester) async {
      final List<_Entry> items = _entries(<int>[9, 6, 3]);
      final List<_Entry> current = <_Entry>[];
      final List<_Entry> past = <_Entry>[];
      await pumpApp(
        tester,
        _timeline(items, onTapCurrent: current.add, onTapPast: past.add),
        surfaceSize: _surface,
      );

      await tester.tap(_hitBox("d9"));
      await tester.pump();

      expect(current, <_Entry>[items[0]]);
      expect(past, isEmpty);
    });

    testWidgets("tapping a past dot calls onTapPast with that entry", (WidgetTester tester) async {
      final List<_Entry> items = _entries(<int>[9, 6, 3]);
      final List<_Entry> current = <_Entry>[];
      final List<_Entry> past = <_Entry>[];
      await pumpApp(
        tester,
        _timeline(items, onTapCurrent: current.add, onTapPast: past.add),
        surfaceSize: _surface,
      );

      await tester.tap(find.text("d6"));
      await tester.pump();

      expect(past, <_Entry>[items[1]]);
      expect(current, isEmpty);
    });

    testWidgets("dots without a callback are inert", (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpApp(tester, _timeline(_entries(<int>[9, 6, 3])), surfaceSize: _surface);

      await tester.tap(_hitBox("d9"));
      await tester.tap(_hitBox("d3"));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(_mouseRegion(tester, "d9").cursor, MouseCursor.defer);
      expect(_mouseRegion(tester, "d3").cursor, MouseCursor.defer);
      expect(
        tester.getSemantics(find.bySemanticsLabel("e3, d3")),
        isSemantics(isButton: false, hasTapAction: false),
      );
      semantics.dispose();
    });

    testWidgets("only the dots with a callback are interactive", (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final List<_Entry> past = <_Entry>[];
      await pumpApp(tester, _timeline(_entries(<int>[9, 6, 3]), onTapPast: past.add), surfaceSize: _surface);

      expect(_mouseRegion(tester, "d9").cursor, MouseCursor.defer);
      expect(_mouseRegion(tester, "d6").cursor, SystemMouseCursors.click);
      expect(
        tester.getSemantics(find.bySemanticsLabel("e9, d9")),
        isSemantics(isButton: false, hasTapAction: false),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel("e6, d6")),
        isSemantics(isButton: true, hasTapAction: true),
      );
      semantics.dispose();
    });
  });

  group("close dots", () {
    testWidgets("a tap on a dot reaches it when a neighbour is closer than 24 dp", (WidgetTester tester) async {
      final List<_Entry> items = _cluster();
      final List<_Entry> current = <_Entry>[];
      final List<_Entry> past = <_Entry>[];
      await pumpApp(
        tester,
        _timeline(items, onTapCurrent: current.add, onTapPast: past.add),
        surfaceSize: _surface,
      );
      final Offset d31 = _circleCentre(tester, "d31");
      final Offset d30 = _circleCentre(tester, "d30");
      final Offset d15 = _circleCentre(tester, "d15");
      final Offset d14 = _circleCentre(tester, "d14");
      expect(d31.dx - d30.dx, lessThan(kMinTapTarget / 2));
      expect(d15.dx - d14.dx, lessThan(kMinTapTarget / 2));

      for (final Offset centre in <Offset>[d30, d14, d15, d31]) {
        await tester.tapAt(centre);
        await tester.pump();
      }

      expect(past, <_Entry>[items[1], items[3], items[2]]);
      expect(current, <_Entry>[items[0]]);
    });

    testWidgets("hover highlights the dot under the mouse, not its newer neighbour", (WidgetTester tester) async {
      await pumpApp(tester, _timeline(_cluster(), onTapPast: (_Entry _) {}), surfaceSize: _surface);
      final ColorScheme cs = _scheme(tester);
      final TestGesture mouse = await _mouse(tester);

      await mouse.moveTo(_circleCentre(tester, "d30"));
      await tester.pump();
      expect(_dot(tester, "d30").color, cs.primary);

      await mouse.moveTo(_circleCentre(tester, "d14"));
      await tester.pump();
      expect(_dot(tester, "d14").color, cs.primary);
      expect(_dot(tester, "d15").color, cs.surface);
      expect(_dot(tester, "d30").color, cs.surface);

      await mouse.moveTo(_circleCentre(tester, "d15"));
      await tester.pump();
      expect(_dot(tester, "d15").color, cs.primary);
      expect(_dot(tester, "d14").color, cs.surface);

      await _parkMouse(tester, mouse);
    });

    testWidgets("the caption and tooltip are centred on a dot whose hit box is cut", (WidgetTester tester) async {
      await pumpApp(tester, _timeline(_cluster()), surfaceSize: _surface);
      final Offset d14 = _circleCentre(tester, "d14");
      expect(tester.getCenter(_hitBox("d14")).dx, isNot(moreOrLessEquals(d14.dx, epsilon: 1)));
      expect(tester.getCenter(find.text("d14")).dx, moreOrLessEquals(d14.dx, epsilon: 0.5));
      final TestGesture mouse = await _mouse(tester);

      await mouse.moveTo(d14);
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getCenter(find.text("e14 · $_resumeKey")).dx, moreOrLessEquals(d14.dx, epsilon: 0.5));

      await _parkMouse(tester, mouse);
    });

    testWidgets("entries with the same date are nudged apart and each stays reachable", (WidgetTester tester) async {
      final List<_Entry> items = <_Entry>[_on(3, 31, "b"), _on(3, 31, "a"), _on(1, 1, "c")];
      final List<_Entry> current = <_Entry>[];
      final List<_Entry> past = <_Entry>[];
      await pumpApp(
        tester,
        _timeline(items, onTapCurrent: current.add, onTapPast: past.add),
        surfaceSize: _surface,
      );
      final Rect older = tester.getRect(_circleWithTooltip("a · $_resumeKey"));
      final Rect newer = tester.getRect(_circleWithTooltip("b · $_currentKey"));
      expect(older.right, lessThanOrEqualTo(newer.left));

      await tester.tapAt(older.center);
      await tester.pump();
      await tester.tapAt(newer.center);
      await tester.pump();

      expect(past, <_Entry>[items[1]]);
      expect(current, <_Entry>[items[0]]);
    });
  });

  group("semantics and tooltip", () {
    testWidgets("announce the label, caption, hint and current state", (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpApp(
        tester,
        _timeline(_entries(<int>[9, 6]), onTapCurrent: (_Entry _) {}, onTapPast: (_Entry _) {}),
        surfaceSize: _surface,
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel("e9, d9")),
        isSemantics(label: "e9, d9", hint: _currentKey, isSelected: true, isButton: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel("e6, d6")),
        isSemantics(label: "e6, d6", hint: _resumeKey, isSelected: false, isButton: true),
      );
      expect(_tooltip(tester, "d9").message, "e9 · $_currentKey");
      expect(_tooltip(tester, "d6").message, "e6 · $_resumeKey");
      semantics.dispose();
    });

    testWidgets("custom hints replace the defaults", (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpApp(
        tester,
        _timeline(_entries(<int>[9, 6]), currentHint: "Now", pastHint: "Restore"),
        surfaceSize: _surface,
      );

      expect(_tooltip(tester, "d9").message, "e9 · Now");
      expect(_tooltip(tester, "d6").message, "e6 · Restore");
      expect(tester.getSemantics(find.bySemanticsLabel("e6, d6")), isSemantics(hint: "Restore"));
      semantics.dispose();
    });

    testWidgets("an empty label shows the hint alone", (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpApp(
        tester,
        _timeline(_entries(<int>[9, 6]), labelOf: (_Entry entry) => ""),
        surfaceSize: _surface,
      );

      expect(_tooltip(tester, "d9").message, _currentKey);
      expect(_tooltip(tester, "d6").message, _resumeKey);
      expect(tester.getSemantics(find.bySemanticsLabel("d6")), isSemantics(label: "d6", hint: _resumeKey));
      semantics.dispose();
    });

    testWidgets("the default caption is MMMd for the ambient locale", (WidgetTester tester) async {
      await initializeDateFormatting("fr");
      final DateTime date = DateTime.utc(2026, 3, 5);
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => Localizations.override(
            context: context,
            locale: const Locale("fr"),
            child: HistoryTimeline<_Entry>(
              items: <_Entry>[_Entry("a", date, "a")],
              dateOf: (_Entry entry) => entry.date,
              labelOf: (_Entry entry) => entry.label,
            ),
          ),
        ),
        surfaceSize: _surface,
      );

      expect(find.text(DateFormat.MMMd("fr").format(date)), findsOneWidget);
      expect(find.text(DateFormat.MMMd("en_US").format(date)), findsNothing);
    });
  });

  group("hover", () {
    testWidgets("a mouse over a tappable past dot paints it primary", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _timeline(_entries(<int>[9, 6, 3]), onTapPast: (_Entry _) {}),
        surfaceSize: _surface,
      );
      final ColorScheme cs = _scheme(tester);
      expect(_dot(tester, "d3").color, cs.surface);
      expect((_dot(tester, "d3").border! as Border).top.color, cs.onSurfaceVariant);

      final TestGesture mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(_hitBox("d3")));
      await tester.pump();
      expect(_dot(tester, "d3").color, cs.primary);
      expect((_dot(tester, "d3").border! as Border).top.color, cs.primary);
      expect(_dot(tester, "d6").color, cs.surface);

      await _parkMouse(tester, mouse);
      expect(_dot(tester, "d3").color, cs.surface);
    });

    testWidgets("an exit reported by another dot leaves the hovered dot highlighted", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _timeline(_entries(<int>[9, 6, 3]), onTapPast: (_Entry _) {}),
        surfaceSize: _surface,
      );
      final ColorScheme cs = _scheme(tester);
      final TestGesture mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(_hitBox("d3")));
      await tester.pump();

      _mouseRegion(tester, "d6").onExit!(const PointerExitEvent());
      await tester.pump();
      expect(_dot(tester, "d3").color, cs.primary);

      _mouseRegion(tester, "d3").onExit!(const PointerExitEvent());
      await tester.pump();
      expect(_dot(tester, "d3").color, cs.surface);

      await _parkMouse(tester, mouse);
    });

    testWidgets("expanding the strip under a resting mouse highlights the dot now under it", (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpApp(
        tester,
        _timeline(_entries(<int>[8, 7, 6, 5, 4, 3, 2, 1]), onTapPast: (_Entry _) {}),
        surfaceSize: _surface,
      );
      final ColorScheme cs = _scheme(tester);
      final TestGesture mouse = await _mouse(tester);
      final Offset at = tester.getCenter(_hitBox("d3"));
      await mouse.moveTo(at);
      await tester.pump();
      expect(_dot(tester, "d3").color, cs.primary);

      // Expand without the mouse (keyboard or screen reader), then let the
      // post-frame mouse update rebuild the strip.
      tester.semantics.tap(find.semantics.byLabel(_showOlderKey));
      await tester.pump();
      await tester.pump();

      final List<String> under = <String>[];
      for (int day = 1; day <= 7; day++) {
        final bool hovered = tester.getRect(_hitBox("d$day")).contains(at);
        if (hovered) under.add("d$day");
        expect(_dot(tester, "d$day").color, hovered ? cs.primary : cs.surface, reason: "d$day");
      }
      expect(under, hasLength(1));

      await _parkMouse(tester, mouse);
      semantics.dispose();
    });

    testWidgets("an inert past dot does not react to hover", (WidgetTester tester) async {
      await pumpApp(tester, _timeline(_entries(<int>[9, 6, 3])), surfaceSize: _surface);
      final ColorScheme cs = _scheme(tester);

      final TestGesture mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(_hitBox("d3")));
      await tester.pump();
      expect(_dot(tester, "d3").color, cs.surface);

      await _parkMouse(tester, mouse);
    });

    testWidgets("new items reset the hover without range errors", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _timeline(_entries(<int>[9, 6, 3]), onTapPast: (_Entry _) {}),
        surfaceSize: _surface,
      );
      final ColorScheme cs = _scheme(tester);
      final TestGesture mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(_hitBox("d3")));
      await tester.pump();
      expect(_dot(tester, "d3").color, cs.primary);

      await pumpApp(tester, _timeline(_entries(<int>[9, 6, 3]), onTapPast: (_Entry _) {}), surfaceSize: _surface);
      expect(_dot(tester, "d3").color, cs.surface);

      await pumpApp(tester, _timeline(_entries(<int>[9]), onTapPast: (_Entry _) {}), surfaceSize: _surface);
      expect(tester.takeException(), isNull);
      expect(find.text("d9"), findsOneWidget);

      await _parkMouse(tester, mouse);
    });
  });

  group("theme", () {
    testWidgets("renders under the dark theme", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _timeline(_entries(<int>[8, 7, 6, 5, 4, 3, 2, 1])),
        surfaceSize: _surface,
        theme: AppTheme.dark(),
      );

      final ColorScheme cs = _scheme(tester);
      expect(cs.brightness, Brightness.dark);
      expect(_dot(tester, "d8").color, cs.primary);
      expect(_dot(tester, "d7").color, cs.surface);
      expect(find.text("+2 $_olderKey"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

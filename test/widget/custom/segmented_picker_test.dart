// segmented_picker_test.dart
//
// Widget tests for SegmentedPicker: segments and second lines, the
// upper-cased caption, selection with enum and String values, the empty
// selection, ColorScheme text colours, the cs.primary outline of the selected
// pill (>= 3:1 on the track, same text room either way) and >= 4.5:1 text,
// locked segments (opacity, icon, onLockedTap, inert without callback, no
// icon, text clear of the icon, top-end corner in LTR and RTL), disabled
// options, button semantics and the "unavailable" hint, 48 dp targets,
// reduced motion, narrow and large-text layouts, no Material ancestor, the
// dark theme and the empty-options assert.

import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/SegmentedPicker/index.dart";
import "package:flutter_skeleton/widgets/custom/_base/choice_option.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

/// Without EasyLocalization in the tree, `.tr()` returns the raw key.
const String _unavailableKey = "custom.segmented_picker.unavailable";

enum _Period { short, mid, long }

const List<ChoiceOption<_Period>> _options = <ChoiceOption<_Period>>[
  ChoiceOption<_Period>(value: _Period.short, label: "Short", description: "Line A"),
  ChoiceOption<_Period>(value: _Period.mid, label: "Mid", description: "Line B"),
  ChoiceOption<_Period>(value: _Period.long, label: "Long"),
];

void _ignore(_Period _) {}

/// Records the callbacks of one picker.
final class _Calls {
  final List<_Period> selected = <_Period>[];
  final List<_Period> locked = <_Period>[];
}

SegmentedPicker<_Period> _picker(
  _Calls calls, {
  List<ChoiceOption<_Period>> options = _options,
  _Period? selected = _Period.mid,
  String? label,
  Set<_Period>? enabledValues,
  IconData? lockedIcon = Icons.lock_outline_rounded,
  bool lockedTappable = true,
}) {
  return SegmentedPicker<_Period>(
    options: options,
    selected: selected,
    onSelected: calls.selected.add,
    label: label,
    enabledValues: enabledValues,
    lockedIcon: lockedIcon,
    onLockedTap: lockedTappable ? calls.locked.add : null,
  );
}

/// The InkWell of the segment showing [label].
Finder _segment(String label) {
  return find.ancestor(of: find.text(label), matching: find.byType(InkWell));
}

InkWell _inkWell(WidgetTester tester, String label) => tester.widget<InkWell>(_segment(label));

Opacity _opacity(WidgetTester tester, String label) {
  return tester.widget<Opacity>(find.ancestor(of: find.text(label), matching: find.byType(Opacity)));
}

AnimatedContainer _pill(WidgetTester tester, String label) {
  return tester.widget<AnimatedContainer>(
    find.ancestor(of: find.text(label), matching: find.byType(AnimatedContainer)),
  );
}

Color? _pillColor(WidgetTester tester, String label) {
  return (_pill(tester, label).decoration! as BoxDecoration).color;
}

Border _border(WidgetTester tester, String label) {
  return (_pill(tester, label).decoration! as BoxDecoration).border! as Border;
}

Color? _textColor(WidgetTester tester, String text) => tester.widget<Text>(find.text(text)).style?.color;

/// Colour of the track (the only Material inside the picker).
Color? _trackColor(WidgetTester tester) {
  return tester
      .widget<Material>(find.descendant(of: find.byType(SegmentedPicker<_Period>), matching: find.byType(Material)))
      .color;
}

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Checks, with "Mid" selected and "Short" unselected, that the selection
/// has a non-fill cue (a cs.primary outline at >= 3:1 against the track, a
/// transparent outline of the same width elsewhere) and that every line is
/// opaque and reads at >= 4.5:1 on its background.
void _expectReadableSelection(WidgetTester tester) {
  final ColorScheme cs = _scheme(tester);
  final Color track = _trackColor(tester)!;
  final Color pill = _pillColor(tester, "Mid")!;

  final Border outline = _border(tester, "Mid");
  expect(outline.isUniform, isTrue);
  expect(outline.top.color, cs.primary);
  expect(outline.top.width, 1.5);
  expect(_contrast(outline.top.color, track), greaterThanOrEqualTo(3));
  expect(_border(tester, "Short").top.color, Colors.transparent);
  expect(_border(tester, "Short").top.width, 1.5);

  final Map<String, Color> backgrounds = <String, Color>{
    "Mid": pill,
    "Line B": pill,
    "Short": track,
    "Line A": track,
  };
  backgrounds.forEach((String text, Color background) {
    final Color color = _textColor(tester, text)!;
    expect(color.a, 1, reason: text);
    expect(_contrast(color, background), greaterThanOrEqualTo(4.5), reason: text);
  });
}

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(SegmentedPicker<_Period>))).colorScheme;

void main() {
  group("SegmentedPicker layout", () {
    testWidgets("renders one segment per option, in order", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls()));

      expect(find.byType(InkWell), findsNWidgets(3));
      final double short = tester.getCenter(find.text("Short")).dx;
      final double mid = tester.getCenter(find.text("Mid")).dx;
      final double long = tester.getCenter(find.text("Long")).dx;
      expect(short < mid && mid < long, isTrue);
    });

    testWidgets("segments share the track width equally", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls()));

      final double width = tester.getSize(_segment("Short")).width;
      expect(tester.getSize(_segment("Mid")).width, width);
      expect(tester.getSize(_segment("Long")).width, width);
    });

    testWidgets("draws the description only when it is set", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls()));

      expect(find.text("Line A"), findsOneWidget);
      expect(find.text("Line B"), findsOneWidget);
      expect(
        find.descendant(of: _segment("Long"), matching: find.byType(Text)),
        findsOneWidget,
      );
    });

    testWidgets("draws the caption upper-cased above the track", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls(), label: "Period"));

      expect(find.text("PERIOD"), findsOneWidget);
      expect(find.text("Period"), findsNothing);
      expect(tester.getBottomLeft(find.text("PERIOD")).dy, lessThan(tester.getTopLeft(_segment("Short")).dy));
    });

    testWidgets("draws no caption when label is null", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls()));

      // 3 labels + 2 descriptions, nothing else.
      expect(find.byType(Text), findsNWidgets(5));
    });

    testWidgets("ignores the icon and trailing fields", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _picker(
          _Calls(),
          options: const <ChoiceOption<_Period>>[
            ChoiceOption<_Period>(value: _Period.short, label: "Short", icon: Icons.star, trailing: "9"),
          ],
        ),
      );

      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.text("9"), findsNothing);
    });

    testWidgets("asserts that options is not empty", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls(), options: const <ChoiceOption<_Period>>[]));

      expect(tester.takeException(), isAssertionError);
    });

    testWidgets("the constructor is const", (WidgetTester tester) async {
      await pumpApp(tester, const SegmentedPicker<_Period>(options: _options, selected: null, onSelected: _ignore));

      expect(find.text("Short"), findsOneWidget);
    });
  });

  group("SegmentedPicker selection", () {
    testWidgets("tapping a segment reports its enum value once", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _picker(calls));

      await tester.tap(find.text("Long"));
      await tester.pump();

      expect(calls.selected, <_Period>[_Period.long]);
      expect(calls.locked, isEmpty);
    });

    testWidgets("tapping the selected segment reports it again", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _picker(calls));

      await tester.tap(find.text("Mid"));
      await tester.pump();

      expect(calls.selected, <_Period>[_Period.mid]);
    });

    testWidgets("works with String values", (WidgetTester tester) async {
      final List<String> picked = <String>[];
      await pumpApp(
        tester,
        SegmentedPicker<String>(
          options: const <ChoiceOption<String>>[
            ChoiceOption<String>(value: "a", label: "First"),
            ChoiceOption<String>(value: "b", label: "Second"),
          ],
          selected: "a",
          onSelected: picked.add,
        ),
      );

      await tester.tap(find.text("Second"));
      await tester.pump();

      expect(picked, <String>["b"]);
    });

    testWidgets("only the selected segment gets the pill", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls()));
      final ColorScheme cs = _scheme(tester);

      expect(_pillColor(tester, "Mid"), cs.surface);
      expect(_border(tester, "Mid").top.color, cs.primary);
      expect((_pill(tester, "Mid").decoration! as BoxDecoration).boxShadow, isNotEmpty);
      expect(_pillColor(tester, "Short"), Colors.transparent);
      expect(_border(tester, "Short").top.color, Colors.transparent);
      expect((_pill(tester, "Short").decoration! as BoxDecoration).boxShadow, isNull);
    });

    testWidgets("the selection is outlined and every line is readable", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls()));

      _expectReadableSelection(tester);
    });

    testWidgets("the outline leaves the text room unchanged when the selection changes", (WidgetTester tester) async {
      const List<ChoiceOption<_Period>> longOptions = <ChoiceOption<_Period>>[
        ChoiceOption<_Period>(value: _Period.short, label: "A label too long for its segment"),
        ChoiceOption<_Period>(value: _Period.mid, label: "Mid"),
      ];
      Widget narrow(_Period selected) {
        return Center(
          child: SizedBox(width: 160, child: _picker(_Calls(), options: longOptions, selected: selected)),
        );
      }

      await pumpApp(tester, narrow(_Period.mid));
      final Rect unselected = tester.getRect(find.text("A label too long for its segment"));

      await pumpApp(tester, narrow(_Period.short));
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.getRect(find.text("A label too long for its segment")), unselected);
    });

    testWidgets("a null selection highlights nothing", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _picker(_Calls(), selected: null));
      final ColorScheme cs = _scheme(tester);

      for (final String label in <String>["Short", "Mid", "Long"]) {
        expect(_pillColor(tester, label), isNot(cs.surface));
        expect(tester.getSemantics(find.text(label)), isSemantics(isSelected: false));
      }
      handle.dispose();
    });

    testWidgets("text colours come from the ColorScheme", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls()));
      final ColorScheme cs = _scheme(tester);

      expect(_textColor(tester, "Mid"), cs.primary);
      expect(_textColor(tester, "Line B"), cs.primary);
      expect(_textColor(tester, "Short"), cs.onSurfaceVariant);
      expect(_textColor(tester, "Line A"), cs.onSurfaceVariant);
    });
  });

  group("SegmentedPicker locked segments", () {
    testWidgets("a value outside enabledValues is dimmed with the locked icon", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls(), enabledValues: <_Period>{_Period.short, _Period.mid}));

      expect(_opacity(tester, "Long").opacity, 0.35);
      expect(_opacity(tester, "Short").opacity, 1);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(
        find.descendant(of: _segment("Long"), matching: find.byIcon(Icons.lock_outline_rounded)),
        findsOneWidget,
      );
    });

    testWidgets("tapping a locked segment calls onLockedTap, not onSelected", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _picker(calls, enabledValues: <_Period>{_Period.short}));

      await tester.tap(find.text("Long"));
      await tester.pump();

      expect(calls.locked, <_Period>[_Period.long]);
      expect(calls.selected, isEmpty);
    });

    testWidgets("a locked segment without onLockedTap is inert", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(tester, _picker(calls, enabledValues: <_Period>{_Period.short}, lockedTappable: false));

      expect(_inkWell(tester, "Long").onTap, isNull);
      expect(_inkWell(tester, "Long").mouseCursor, SystemMouseCursors.basic);
      await tester.tap(find.text("Long"), warnIfMissed: false);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(calls.selected, isEmpty);
      expect(calls.locked, isEmpty);
    });

    testWidgets("a null lockedIcon dims without an icon", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls(), enabledValues: <_Period>{_Period.short}, lockedIcon: null));

      expect(_opacity(tester, "Long").opacity, 0.35);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets("a custom lockedIcon replaces the default", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls(), enabledValues: <_Period>{_Period.short}, lockedIcon: Icons.block));

      expect(find.byIcon(Icons.block), findsNWidgets(2));
      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
    });

    testWidgets("the text keeps clear of the locked icon on a narrow track", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Center(
          child: SizedBox(
            width: 200,
            child: SegmentedPicker<int>(
              options: <ChoiceOption<int>>[
                for (int i = 0; i < 3; i++)
                  ChoiceOption<int>(value: i, label: "Medium term $i", description: "Second line $i"),
              ],
              selected: 0,
              onSelected: (int _) {},
              enabledValues: const <int>{0, 2},
            ),
          ),
        ),
      );

      final Rect icon = tester.getRect(find.byIcon(Icons.lock_outline_rounded));
      expect(icon.overlaps(tester.getRect(find.text("Medium term 1"))), isFalse);
      expect(icon.overlaps(tester.getRect(find.text("Second line 1"))), isFalse);
      // The reserved room is symmetric, so the text stays centred.
      expect(
        tester.getCenter(find.text("Medium term 1")).dx,
        closeTo(tester.getCenter(_segment("Medium term 1")).dx, 0.01),
      );
    });

    testWidgets("the locked icon sits in the top-end corner in LTR and RTL", (WidgetTester tester) async {
      for (final TextDirection direction in TextDirection.values) {
        await pumpApp(
          tester,
          Directionality(
            textDirection: direction,
            child: _picker(_Calls(), enabledValues: <_Period>{_Period.short, _Period.mid}),
          ),
        );

        final Rect segment = tester.getRect(_segment("Long"));
        final Rect icon = tester.getRect(find.byIcon(Icons.lock_outline_rounded));
        final bool atEnd = direction == TextDirection.ltr
            ? icon.center.dx > segment.center.dx
            : icon.center.dx < segment.center.dx;
        expect(atEnd, isTrue, reason: direction.name);
        expect(icon.center.dy, lessThan(segment.center.dy), reason: direction.name);
        expect(segment.contains(icon.topLeft) && segment.contains(icon.bottomRight), isTrue, reason: direction.name);
      }
    });

    testWidgets("a null enabledValues locks nothing", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls()));

      expect(find.byType(Icon), findsNothing);
      for (final String label in <String>["Short", "Mid", "Long"]) {
        expect(_opacity(tester, label).opacity, 1);
        expect(_inkWell(tester, label).mouseCursor, SystemMouseCursors.click);
      }
    });
  });

  group("SegmentedPicker disabled options", () {
    testWidgets("a disabled option is dimmed, inert and has no icon", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await pumpApp(
        tester,
        _picker(
          calls,
          options: const <ChoiceOption<_Period>>[
            ChoiceOption<_Period>(value: _Period.short, label: "Short"),
            ChoiceOption<_Period>(value: _Period.mid, label: "Mid", enabled: false),
          ],
          selected: null,
          enabledValues: <_Period>{_Period.short},
        ),
      );

      expect(_opacity(tester, "Mid").opacity, 0.35);
      expect(_inkWell(tester, "Mid").onTap, isNull);
      expect(find.byType(Icon), findsNothing);
      await tester.tap(find.text("Mid"), warnIfMissed: false);
      await tester.pump();

      expect(calls.selected, isEmpty);
      expect(calls.locked, isEmpty);
    });
  });

  group("SegmentedPicker accessibility", () {
    testWidgets("each segment is a labelled button in an exclusive group", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _picker(_Calls()));

      expect(
        tester.getSemantics(find.text("Mid")),
        isSemantics(
          label: "Mid, Line B",
          isButton: true,
          isSelected: true,
          isEnabled: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.text("Long")),
        isSemantics(label: "Long", isSelected: false, isEnabled: true),
      );
      handle.dispose();
    });

    testWidgets("semanticsLabel replaces the spoken label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        _picker(
          _Calls(),
          options: const <ChoiceOption<_Period>>[
            ChoiceOption<_Period>(value: _Period.short, label: "S", description: "x", semanticsLabel: "Spoken"),
          ],
        ),
      );

      expect(tester.getSemantics(find.text("S")), isSemantics(label: "Spoken"));
      handle.dispose();
    });

    testWidgets("unavailable segments expose the unavailable hint", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _picker(_Calls(), enabledValues: <_Period>{_Period.short}));

      expect(
        tester.getSemantics(find.text("Long")),
        isSemantics(hint: _unavailableKey, isEnabled: false, hasTapAction: true),
      );
      expect(tester.getSemantics(find.text("Short")), isSemantics(hint: "", isEnabled: true));
      handle.dispose();
    });

    testWidgets("segments are at least 48 dp and meet the tap target guidelines", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _picker(_Calls(), enabledValues: <_Period>{_Period.short}, label: "Period"));

      for (final String label in <String>["Short", "Mid", "Long"]) {
        final Size size = tester.getSize(_segment(label));
        expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
        expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
      }
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group("SegmentedPicker motion", () {
    testWidgets("the pill animates over 160 ms", (WidgetTester tester) async {
      await pumpApp(tester, _picker(_Calls()));

      expect(_pill(tester, "Mid").duration, const Duration(milliseconds: 160));
    });

    testWidgets("reduced motion makes the pill instant", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: _picker(_Calls()),
          ),
        ),
      );

      expect(_pill(tester, "Mid").duration, Duration.zero);
    });
  });

  group("SegmentedPicker constrained layouts", () {
    testWidgets("long labels ellipsize on a narrow track", (WidgetTester tester) async {
      const String longText = "A very long segment label that cannot fit";
      await pumpApp(
        tester,
        Center(
          child: SizedBox(
            width: 200,
            child: SegmentedPicker<int>(
              options: <ChoiceOption<int>>[
                for (int i = 0; i < 4; i++)
                  ChoiceOption<int>(value: i, label: "$longText $i", description: "$longText too"),
              ],
              selected: 1,
              onSelected: (int _) {},
              enabledValues: const <int>{0, 1, 2},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final Text text = tester.widget<Text>(find.text("$longText 0"));
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.maxLines, 1);
    });

    testWidgets("large text grows every segment to the same height", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(3)),
            child: _picker(_Calls()),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final double height = tester.getSize(_segment("Short")).height;
      expect(height, greaterThan(kMinTapTarget));
      expect(tester.getSize(_segment("Long")).height, height);
    });

    testWidgets("works without a Material ancestor", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: Center(child: _picker(calls))),
      );

      await tester.tap(find.text("Short"));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(calls.selected, <_Period>[_Period.short]);
    });
  });

  group("SegmentedPicker dark theme", () {
    testWidgets("renders with the dark ColorScheme", (WidgetTester tester) async {
      await pumpApp(
        tester,
        _picker(_Calls(), label: "Period", enabledValues: <_Period>{_Period.short, _Period.mid}),
        theme: AppTheme.dark(),
      );
      final ColorScheme cs = _scheme(tester);

      expect(tester.takeException(), isNull);
      expect(cs.brightness, Brightness.dark);
      expect(_pillColor(tester, "Mid"), cs.surface);
      expect(_textColor(tester, "Mid"), cs.primary);
      expect(_textColor(tester, "Short"), cs.onSurfaceVariant);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      _expectReadableSelection(tester);
    });
  });
}

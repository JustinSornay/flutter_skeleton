// comparison_picker_test.dart
//
// Widget tests for ComparisonPicker: locked-A mode (default slot A, locked
// dot following slot A, whole-row slot-B toggle, slot A moved away),
// radio mode (header, A / B toggles, disabled opposite radio with its dimmed
// dot and forbidden cursor, initial slots, one id in both slots), read-only,
// the secondary section (divider label, add button, loading placeholder under
// normal and reduced motion, hidden when empty), item content (subtitle,
// plain value, tone pill and tone label, long values at 320 dp), 48 dp
// targets, semantics, and ColorScheme / StatusTones tokens in light and dark
// themes.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/core/decorators/SkeletonPulse/index.dart";
import "package:flutter_skeleton/widgets/custom/ComparisonPicker/index.dart";
import "package:flutter_skeleton/widgets/custom/SkeletonBlock/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _selectA = "custom.comparison_picker.select_a";
const String _selectB = "custom.comparison_picker.select_b";
const String _lockedA = "custom.comparison_picker.locked_a";
const String _slotAKey = "custom.comparison_picker.slot_a";
const String _slotBKey = "custom.comparison_picker.slot_b";
const String _secondaryKey = "custom.comparison_picker.secondary";
const String _addKey = "custom.comparison_picker.add";
const String _loadingKey = "custom.comparison_picker.loading";

const ComparisonPickerItem _p1 = ComparisonPickerItem(
  id: "p1",
  label: "First item",
  valueLabel: "67 %",
  tone: StatusTone.success,
);
const ComparisonPickerItem _p2 = ComparisonPickerItem(id: "p2", label: "Second item", subtitle: "Second line");
const ComparisonPickerItem _s1 = ComparisonPickerItem(id: "s1", label: "Third item", valueLabel: "4.2");
const ComparisonPickerItem _s2 = ComparisonPickerItem(
  id: "s2",
  label: "Fourth item",
  valueLabel: "31 %",
  tone: StatusTone.warning,
);

/// Records every onChanged call as (slotA, slotB).
final class _Calls {
  final List<(String?, String?)> values = <(String?, String?)>[];

  void add(String? slotA, String? slotB) => values.add((slotA, slotB));
}

/// The default groups: radio mode (two primary items) and two secondary items.
const List<ComparisonPickerItem> _primary = <ComparisonPickerItem>[_p1, _p2];
const List<ComparisonPickerItem> _secondary = <ComparisonPickerItem>[_s1, _s2];

/// The locked-A primary group.
const List<ComparisonPickerItem> _locked = <ComparisonPickerItem>[_p1];

Future<void> _pump(WidgetTester tester, ComparisonPicker picker, {ThemeData? theme}) {
  return pumpApp(tester, SingleChildScrollView(child: picker), theme: theme);
}

/// The Material of the row showing [label].
Finder _row(String label) => find.ancestor(of: find.text(label), matching: find.byType(Material)).first;

/// The A or B radio (or the slot-B toggle node) of the row showing [label].
Finder _control(String label, String semanticsLabel) {
  return find.descendant(of: _row(label), matching: find.bySemanticsLabel(semanticsLabel)).first;
}

/// The two dash runs of the secondary divider.
final Finder _dashes = find.byWidgetPredicate(
  (Widget widget) => widget is CustomPaint && widget.painter != null && widget.size == const Size.fromHeight(1),
);

Color? _rowFill(WidgetTester tester, String label) => tester.widget<Material>(_row(label)).color;

/// The decoration of the first slot dot (radio or locked dot) of the row
/// showing [label].
BoxDecoration _dot(WidgetTester tester, String label) {
  final Finder dots = find.descendant(
    of: _row(label),
    matching: find.byWidgetPredicate(
      (Widget widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).shape == BoxShape.circle,
    ),
  );
  return tester.widget<DecoratedBox>(dots.first).decoration as BoxDecoration;
}

/// Mouse regions showing the forbidden cursor under [control].
Finder _forbiddenCursor(Finder control) {
  return find.descendant(
    of: control,
    matching: find.byWidgetPredicate(
      (Widget widget) => widget is MouseRegion && widget.cursor == SystemMouseCursors.forbidden,
    ),
  );
}

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(ComparisonPicker))).colorScheme;

Matcher _radio({required bool checked, required bool enabled}) {
  return isSemantics(
    hasCheckedState: true,
    isChecked: checked,
    isInMutuallyExclusiveGroup: true,
    hasEnabledState: true,
    isEnabled: enabled,
  );
}

void main() {
  group("locked-A mode (one primary item)", () {
    testWidgets("hides the header, locks slot A and does not report at mount", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pump(
        tester,
        ComparisonPicker(primary: _locked, secondary: _secondary, onChanged: calls.add, headerLabel: "Items"),
      );

      expect(find.text(_slotAKey), findsNothing);
      expect(find.text("Items"), findsNothing);
      expect(find.bySemanticsLabel(_selectA), findsNothing);
      expect(find.descendant(of: _row(_p1.label), matching: find.bySemanticsLabel(_lockedA)), findsWidgets);
      expect(_dot(tester, _p1.label).color, _scheme(tester).primary);
      expect(_rowFill(tester, _p1.label), _scheme(tester).primaryContainer);
      expect(calls.values, isEmpty);
    });

    testWidgets("tapping a secondary row toggles slot B", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pump(tester, ComparisonPicker(primary: _locked, secondary: _secondary, onChanged: calls.add));

      await tester.tap(find.text(_s1.label));
      await tester.pump();
      expect(calls.values, <(String?, String?)>[("p1", "s1")]);
      expect(_rowFill(tester, _s1.label), _scheme(tester).tertiaryContainer);
      expect(tester.getSemantics(_control(_s1.label, _selectB)), _radio(checked: true, enabled: true));

      await tester.tap(find.text(_s1.label));
      await tester.pump();
      expect(calls.values.last, ("p1", null));
      expect(_rowFill(tester, _s1.label), _scheme(tester).surface);
      expect(tester.getSemantics(_control(_s1.label, _selectB)), _radio(checked: false, enabled: true));
    });

    testWidgets("picking another secondary row moves slot B", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pump(tester, ComparisonPicker(primary: _locked, secondary: _secondary, onChanged: calls.add));

      await tester.tap(find.text(_s1.label));
      await tester.pump();
      await tester.tap(find.text(_s2.label));
      await tester.pump();

      expect(calls.values.last, ("p1", "s2"));
      expect(_rowFill(tester, _s1.label), _scheme(tester).surface);
    });

    testWidgets("an explicit initialSlotA wins over the primary item", (WidgetTester tester) async {
      await _pump(
        tester,
        const ComparisonPicker(primary: _locked, secondary: _secondary, onChanged: _ignore, initialSlotA: "s2"),
      );

      expect(_rowFill(tester, _p1.label), _scheme(tester).surface);
      expect(_rowFill(tester, _s2.label), _scheme(tester).primaryContainer);
    });

    testWidgets("the primary dot is an unlabelled empty ring while slot A is elsewhere", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pump(
        tester,
        ComparisonPicker(primary: _locked, secondary: _secondary, onChanged: calls.add, initialSlotA: "s2"),
      );

      expect(find.bySemanticsLabel(_lockedA), findsNothing);
      expect(_dot(tester, _p1.label).color, Colors.transparent);
      expect(_dot(tester, _p1.label).border, Border.all(color: _scheme(tester).outline, width: 1.5));

      // Toggling B on the row holding slot A moves it to slot B and empties A.
      await tester.tap(find.text(_s2.label));
      await tester.pump();
      expect(calls.values, <(String?, String?)>[(null, "s2")]);
      expect(_rowFill(tester, _s2.label), _scheme(tester).tertiaryContainer);
      expect(_rowFill(tester, _p1.label), _scheme(tester).surface);
      expect(find.bySemanticsLabel(_lockedA), findsNothing);
      expect(_dot(tester, _p1.label).color, Colors.transparent);
    });

    testWidgets("slot A is not defaulted when primary shrinks to one item after mount", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      ComparisonPicker picker(List<ComparisonPickerItem> primary) {
        return ComparisonPicker(primary: primary, secondary: _secondary, onChanged: calls.add);
      }

      await _pump(tester, picker(_primary));
      await _pump(tester, picker(_locked));

      expect(find.bySemanticsLabel(_lockedA), findsNothing);
      expect(_dot(tester, _p1.label).color, Colors.transparent);
      await tester.tap(find.text(_s1.label));
      await tester.pump();
      expect(calls.values, <(String?, String?)>[(null, "s1")]);
    });
  });

  group("radio mode (0 or 2+ primary items)", () {
    testWidgets("shows the A / B header with the header label", (WidgetTester tester) async {
      await _pump(
        tester,
        const ComparisonPicker(primary: _primary, secondary: _secondary, onChanged: _ignore, headerLabel: "Items"),
      );

      expect(find.text(_slotAKey), findsOneWidget);
      expect(find.text(_slotBKey), findsOneWidget);
      expect(find.text("Items"), findsOneWidget);
    });

    testWidgets("shows only the badges without a header label", (WidgetTester tester) async {
      await _pump(tester, const ComparisonPicker(primary: _primary, secondary: _secondary, onChanged: _ignore));

      expect(find.text(_slotAKey), findsOneWidget);
      expect(find.text(_slotBKey), findsOneWidget);
    });

    testWidgets("A and B radios toggle the slots", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pump(tester, ComparisonPicker(primary: _primary, secondary: _secondary, onChanged: calls.add));

      await tester.tap(_control(_p1.label, _selectA));
      await tester.pump();
      expect(calls.values.last, ("p1", null));

      await tester.tap(_control(_s1.label, _selectB));
      await tester.pump();
      expect(calls.values.last, ("p1", "s1"));

      await tester.tap(_control(_p1.label, _selectA));
      await tester.pump();
      expect(calls.values.last, (null, "s1"));
      expect(calls.values, hasLength(3));
    });

    testWidgets("picking another row for a slot moves the slot", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pump(
        tester,
        ComparisonPicker(primary: _primary, secondary: _secondary, onChanged: calls.add, initialSlotA: "p1"),
      );

      await tester.tap(_control(_p2.label, _selectA));
      await tester.pump();

      expect(calls.values.last, ("p2", null));
      expect(_rowFill(tester, _p1.label), _scheme(tester).surface);
      expect(_rowFill(tester, _p2.label), _scheme(tester).primaryContainer);
    });

    testWidgets("the other slot's radio is disabled on a row holding a slot", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pump(
        tester,
        ComparisonPicker(primary: _primary, secondary: _secondary, onChanged: calls.add, initialSlotA: "p1"),
      );

      expect(tester.getSemantics(_control(_p1.label, _selectA)), _radio(checked: true, enabled: true));
      expect(tester.getSemantics(_control(_p1.label, _selectB)), _radio(checked: false, enabled: false));

      await tester.tap(_control(_p1.label, _selectB), warnIfMissed: false);
      await tester.pump();
      expect(calls.values, isEmpty);
    });

    testWidgets("a disabled radio is dimmed with a forbidden cursor", (WidgetTester tester) async {
      await _pump(
        tester,
        const ComparisonPicker(primary: _primary, secondary: _secondary, onChanged: _ignore, initialSlotA: "p1"),
      );

      final Finder disabled = _control(_p1.label, _selectB);
      final Finder enabled = _control(_p1.label, _selectA);
      expect(tester.widget<Opacity>(find.descendant(of: disabled, matching: find.byType(Opacity))).opacity, 0.28);
      expect(_forbiddenCursor(disabled), findsOneWidget);
      expect(find.descendant(of: enabled, matching: find.byType(Opacity)), findsNothing);
      expect(_forbiddenCursor(enabled), findsNothing);
      expect(_dot(tester, _p1.label).color, _scheme(tester).primary);
    });

    testWidgets("an id held by both initial slots leaves both when its A radio is tapped", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pump(
        tester,
        ComparisonPicker(
          primary: _primary,
          secondary: _secondary,
          onChanged: calls.add,
          initialSlotA: "p1",
          initialSlotB: "p1",
        ),
      );

      await tester.tap(_control(_p1.label, _selectA));
      await tester.pump();
      expect(calls.values, <(String?, String?)>[(null, null)]);
      expect(_rowFill(tester, _p1.label), _scheme(tester).surface);
    });

    testWidgets("reflects initialSlotA and initialSlotB on the first frame", (WidgetTester tester) async {
      await _pump(
        tester,
        const ComparisonPicker(
          primary: _primary,
          secondary: _secondary,
          onChanged: _ignore,
          initialSlotA: "p2",
          initialSlotB: "s2",
        ),
      );

      expect(tester.getSemantics(_control(_p2.label, _selectA)), _radio(checked: true, enabled: true));
      expect(tester.getSemantics(_control(_s2.label, _selectB)), _radio(checked: true, enabled: true));
      expect(tester.getSemantics(_control(_p1.label, _selectA)), _radio(checked: false, enabled: true));
      expect(_rowFill(tester, _p2.label), _scheme(tester).primaryContainer);
      expect(_rowFill(tester, _s2.label), _scheme(tester).tertiaryContainer);
    });

    testWidgets("an empty primary group is radio mode too", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pump(
        tester,
        ComparisonPicker(primary: const <ComparisonPickerItem>[], secondary: _secondary, onChanged: calls.add),
      );

      expect(find.text(_slotAKey), findsOneWidget);
      await tester.tap(_control(_s2.label, _selectA));
      await tester.pump();
      expect(calls.values.last, ("s2", null));
    });

    testWidgets("every radio has a 48 dp hit area", (WidgetTester tester) async {
      await _pump(tester, const ComparisonPicker(primary: _primary, secondary: _secondary, onChanged: _ignore));

      for (final String label in <String>[_p1.label, _p2.label, _s1.label, _s2.label]) {
        for (final String slot in <String>[_selectA, _selectB]) {
          final Size size = tester.getSize(_control(label, slot));
          expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
          expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
        }
      }
    });
  });

  group("read-only", () {
    testWidgets("radios are disabled and never report", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pump(
        tester,
        ComparisonPicker(
          primary: _primary,
          secondary: _secondary,
          onChanged: calls.add,
          readOnly: true,
          initialSlotA: "p1",
        ),
      );

      expect(tester.getSemantics(_control(_p1.label, _selectA)), _radio(checked: true, enabled: false));
      expect(tester.getSemantics(_control(_p2.label, _selectA)), _radio(checked: false, enabled: false));
      await tester.tap(_control(_p2.label, _selectA), warnIfMissed: false);
      await tester.tap(_control(_s1.label, _selectB), warnIfMissed: false);
      await tester.pump();
      expect(calls.values, isEmpty);
    });

    testWidgets("locked-A rows are not tappable", (WidgetTester tester) async {
      final _Calls calls = _Calls();
      await _pump(
        tester,
        ComparisonPicker(primary: _locked, secondary: _secondary, onChanged: calls.add, readOnly: true),
      );

      expect(tester.getSemantics(_control(_s1.label, _selectB)), _radio(checked: false, enabled: false));
      await tester.tap(find.text(_s1.label));
      await tester.pump();
      expect(calls.values, isEmpty);
    });

    testWidgets("hides the add button", (WidgetTester tester) async {
      await _pump(
        tester,
        ComparisonPicker(primary: _primary, secondary: _secondary, onChanged: _ignore, readOnly: true, onAdd: () {}),
      );

      expect(find.text(_addKey), findsNothing);
      expect(find.byIcon(Icons.add_circle_outline), findsNothing);
    });
  });

  group("secondary section", () {
    testWidgets("defaults the divider label to the built-in key", (WidgetTester tester) async {
      await _pump(tester, const ComparisonPicker(primary: _primary, secondary: _secondary, onChanged: _ignore));

      expect(find.text(_secondaryKey), findsOneWidget);
    });

    testWidgets("secondaryLabel replaces the divider label", (WidgetTester tester) async {
      await _pump(
        tester,
        const ComparisonPicker(
          primary: _primary,
          secondary: _secondary,
          onChanged: _ignore,
          secondaryLabel: "More options",
        ),
      );

      expect(find.text("More options"), findsOneWidget);
      expect(find.text(_secondaryKey), findsNothing);
    });

    testWidgets("is hidden when empty, not loading and without add button", (WidgetTester tester) async {
      await _pump(
        tester,
        const ComparisonPicker(primary: _primary, secondary: <ComparisonPickerItem>[], onChanged: _ignore),
      );

      expect(find.text(_secondaryKey), findsNothing);
      expect(_dashes, findsNothing);
    });

    testWidgets("the divider draws dashes on both sides of its label", (WidgetTester tester) async {
      await _pump(tester, const ComparisonPicker(primary: _primary, secondary: _secondary, onChanged: _ignore));

      expect(_dashes, findsNWidgets(2));
    });

    testWidgets("loading shows the divider and 3 pulsing placeholder rows", (WidgetTester tester) async {
      await _pump(
        tester,
        const ComparisonPicker(primary: _primary, secondary: _secondary, onChanged: _ignore, secondaryLoading: true),
      );

      expect(find.text(_secondaryKey), findsOneWidget);
      expect(find.byType(SkeletonBlock), findsNWidgets(3));
      expect(find.byType(SkeletonPulse), findsOneWidget);
      expect(find.text(_s1.label), findsNothing);
      expect(find.text(_s2.label), findsNothing);
      expect(find.bySemanticsLabel(_loadingKey), findsWidgets);

      await tester.pump(const Duration(milliseconds: 750));
      expect(tester.takeException(), isNull);
    });

    testWidgets("loading rows are static under reduced motion", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: ComparisonPicker(
            primary: <ComparisonPickerItem>[_p1, _p2],
            onChanged: _ignore,
            secondaryLoading: true,
          ),
        ),
      );

      expect(find.byType(SkeletonBlock), findsNWidgets(3));
      expect(find.byType(SkeletonPulse), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets("the add button shows the default label and calls onAdd once", (WidgetTester tester) async {
      int taps = 0;
      await _pump(
        tester,
        ComparisonPicker(primary: _primary, secondary: _secondary, onChanged: _ignore, onAdd: () => taps++),
      );

      expect(find.text(_addKey), findsOneWidget);
      await tester.tap(find.text(_addKey));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets("the add button uses addLabel, shows with an empty group and is 48 dp tall", (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await _pump(
        tester,
        ComparisonPicker(
          primary: _primary,
          secondary: const <ComparisonPickerItem>[],
          onChanged: _ignore,
          onAdd: () => taps++,
          addLabel: "Add one",
        ),
      );

      expect(find.text(_secondaryKey), findsOneWidget);
      expect(find.text("Add one"), findsOneWidget);
      expect(find.text(_addKey), findsNothing);
      final Finder button = find.ancestor(of: find.text("Add one"), matching: find.byType(InkWell)).first;
      expect(tester.getSize(button).height, greaterThanOrEqualTo(kMinTapTarget));
      expect(
        tester.getSemantics(find.ancestor(of: find.text("Add one"), matching: find.byType(Semantics)).first),
        isSemantics(label: "Add one", isButton: true, hasTapAction: true),
      );

      await tester.tap(button);
      await tester.pump();
      expect(taps, 1);
    });
  });

  group("item content", () {
    testWidgets("renders subtitle and value texts, and omits missing fields", (WidgetTester tester) async {
      await _pump(tester, const ComparisonPicker(primary: _primary, secondary: _secondary, onChanged: _ignore));

      expect(find.text("Second line"), findsOneWidget);
      expect(find.text("67 %"), findsOneWidget);
      expect(find.text("4.2"), findsOneWidget);
      expect(find.text("31 %"), findsOneWidget);
      // _p2 has no value: its row holds only its label and subtitle.
      expect(find.descendant(of: _row(_p2.label), matching: find.byType(Text)), findsNWidgets(2));
    });

    testWidgets("a toned value is a StatusTones pill with the tone icon", (WidgetTester tester) async {
      await _pump(tester, const ComparisonPicker(primary: _primary, secondary: _secondary, onChanged: _ignore));

      expect(find.byIcon(StatusTone.success.icon), findsOneWidget);
      expect(find.byIcon(StatusTone.warning.icon), findsOneWidget);
      final ToneColors colors = StatusTones.colorsOf(tester.element(find.byType(ComparisonPicker)), StatusTone.success);
      final DecoratedBox pill = tester.widget<DecoratedBox>(
        find.ancestor(of: find.text("67 %"), matching: find.byType(DecoratedBox)).first,
      );
      expect((pill.decoration as BoxDecoration).color, colors.container);
      expect(tester.widget<Text>(find.text("67 %")).style?.color, colors.onContainer);
    });

    testWidgets("a plain value uses the row text colour", (WidgetTester tester) async {
      await _pump(tester, const ComparisonPicker(primary: _primary, secondary: _secondary, onChanged: _ignore));

      expect(find.descendant(of: _row(_s1.label), matching: find.byType(Icon)), findsNothing);
      expect(tester.widget<Text>(find.text("4.2")).style?.color, _scheme(tester).onSurface);
    });

    testWidgets("a row reads its texts as one node", (WidgetTester tester) async {
      await _pump(tester, const ComparisonPicker(primary: _primary, secondary: _secondary, onChanged: _ignore));

      expect(tester.getSemantics(find.text(_p2.label)), isSemantics(label: "${_p2.label}\nSecond line"));
    });

    testWidgets("a toned row reads its tone label with the value", (WidgetTester tester) async {
      await _pump(
        tester,
        const ComparisonPicker(
          primary: <ComparisonPickerItem>[
            ComparisonPickerItem(
              id: "t1",
              label: "One",
              valueLabel: "67 %",
              tone: StatusTone.danger,
              toneLabel: "High",
            ),
            ComparisonPickerItem(id: "t2", label: "Two", tone: StatusTone.success, toneLabel: "Good"),
          ],
          onChanged: _ignore,
        ),
      );

      // With a value, the tone label is the icon's spoken label only.
      expect(find.text("High"), findsNothing);
      expect(tester.getSemantics(find.text("One")), isSemantics(label: "One\nHigh\n67 %"));
      // Without a value, the tone label is the pill text, read once.
      expect(find.text("Good"), findsOneWidget);
      expect(find.byIcon(StatusTone.success.icon), findsOneWidget);
      expect(tester.getSemantics(find.text("Two")), isSemantics(label: "Two\nGood"));
    });

    test("a tone without valueLabel or toneLabel is rejected", () {
      ComparisonPickerItem toned(String? toneLabel) {
        return ComparisonPickerItem(id: "x", label: "X", tone: StatusTone.success, toneLabel: toneLabel);
      }

      expect(() => toned(null), throwsAssertionError);
      expect(toned("Good").toneLabel, "Good");
    });

    testWidgets("long values end with an ellipsis instead of overflowing at 320 dp", (WidgetTester tester) async {
      const String long = "Not available for this period";
      await pumpApp(
        tester,
        const SingleChildScrollView(
          child: ComparisonPicker(
            primary: <ComparisonPickerItem>[
              ComparisonPickerItem(id: "l1", label: "One", valueLabel: long),
              ComparisonPickerItem(id: "l2", label: "Two", valueLabel: long, tone: StatusTone.warning),
            ],
            onChanged: _ignore,
          ),
        ),
        surfaceSize: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(long), findsNWidgets(2));
      for (final Text text in tester.widgetList<Text>(find.text(long))) {
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);
      }
      for (final String label in <String>["One", "Two"]) {
        // The value takes at most half the text area; the label keeps the rest.
        final Finder value = find.descendant(of: _row(label), matching: find.text(long));
        final double textArea = tester
            .getSize(find.descendant(of: _row(label), matching: find.byType(LayoutBuilder)))
            .width;
        expect(tester.getSize(value).width, lessThanOrEqualTo(textArea / 2));
        expect(tester.getRect(value).right, lessThanOrEqualTo(320));
      }
    });
  });

  group("theming", () {
    testWidgets("selected rows use the slot containers and borders", (WidgetTester tester) async {
      await _pump(
        tester,
        const ComparisonPicker(
          primary: _primary,
          secondary: _secondary,
          onChanged: _ignore,
          initialSlotA: "p1",
          initialSlotB: "s1",
        ),
      );
      final ColorScheme cs = _scheme(tester);

      final ShapeBorder? shapeA = tester.widget<Material>(_row(_p1.label)).shape;
      final ShapeBorder? shapeB = tester.widget<Material>(_row(_s1.label)).shape;
      final ShapeBorder? shapeIdle = tester.widget<Material>(_row(_p2.label)).shape;
      expect((shapeA! as RoundedRectangleBorder).side.color, cs.primary);
      expect((shapeB! as RoundedRectangleBorder).side.color, cs.tertiary);
      expect((shapeIdle! as RoundedRectangleBorder).side.color, cs.outlineVariant);
      expect(tester.widget<Text>(find.text(_p1.label)).style?.color, cs.onPrimaryContainer);
      expect(tester.widget<Text>(find.text(_s1.label)).style?.color, cs.onTertiaryContainer);
    });

    testWidgets("dark theme smoke test", (WidgetTester tester) async {
      await _pump(
        tester,
        ComparisonPicker(
          primary: _primary,
          secondary: _secondary,
          onChanged: _ignore,
          initialSlotA: "p1",
          initialSlotB: "s2",
          headerLabel: "Items",
          onAdd: () {},
        ),
        theme: AppTheme.dark(),
      );
      final ColorScheme cs = _scheme(tester);

      expect(tester.takeException(), isNull);
      expect(cs.brightness, Brightness.dark);
      expect(_rowFill(tester, _p1.label), cs.primaryContainer);
      expect(_rowFill(tester, _s2.label), cs.tertiaryContainer);
      final ToneColors warning = StatusTones.colorsOf(
        tester.element(find.byType(ComparisonPicker)),
        StatusTone.warning,
      );
      expect(tester.widget<Text>(find.text("31 %")).style?.color, warning.onContainer);
    });
  });
}

void _ignore(String? slotA, String? slotB) {}

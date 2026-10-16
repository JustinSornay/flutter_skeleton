// edit_fields_sheet_test.dart
//
// Widget tests for EditFieldsSheet: header and field rendering, dirty
// detection while typing, trimmed submit values, the busy state and the
// single-submit guard, inline errors and retry, the callbacks of the
// content-only widget, field-set changes on rebuild (text, focus and input
// follow the field id), and the show() helper (result, cancel, scrim, save
// completing during the closing animation, landscape with the keyboard open,
// reduced motion), plus dark-theme and small-surface smoke tests.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/EditFieldsSheet/index.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _cancelKey = "custom.edit_fields_sheet.cancel";
const String _saveKey = "custom.edit_fields_sheet.save";
const String _defaultError = "custom.edit_fields_sheet.save_failed";

const List<EditSheetField> _fields = <EditSheetField>[
  EditSheetField(id: "name", label: "Name", hint: "Who to contact", initialValue: "Initial name"),
  EditSheetField(
    id: "comment",
    label: "Comment",
    hint: "Anything to remember",
    minLines: 4,
    maxLines: null,
    maxLength: 20,
  ),
];

/// Records onSubmit calls; each call waits on its own completer unless the
/// fake resolves immediately.
final class _FakeSubmit {
  final bool immediate;
  final List<Map<String, String>> calls = <Map<String, String>>[];
  final List<Completer<void>> pending = <Completer<void>>[];

  _FakeSubmit({this.immediate = false});

  Future<void> call(Map<String, String> values) {
    calls.add(values);
    if (immediate) return Future<void>.value();
    final Completer<void> completer = Completer<void>();
    pending.add(completer);
    return completer.future;
  }
}

final class _Log {
  final List<Map<String, String>> saved = <Map<String, String>>[];
  int cancelled = 0;
}

Finder _field(String label) {
  return find.descendant(
    of: find.ancestor(of: find.text(label.toUpperCase()), matching: find.byType(MergeSemantics)),
    matching: find.byType(TextField),
  );
}

bool _enabled(WidgetTester tester, Finder button) {
  return tester.widget<ButtonStyleButton>(button).onPressed != null;
}

Finder get _saveButton => find.byType(FilledButton);
Finder get _cancelButton => find.byType(OutlinedButton);

Future<_Log> _pumpSheet(
  WidgetTester tester,
  _FakeSubmit submit, {
  List<EditSheetField> fields = _fields,
  String? subtitle = "Edit the details",
  String? Function(Object error)? errorMessage,
  ThemeData? theme,
  Size? surfaceSize,
}) async {
  final _Log log = _Log();
  await pumpApp(
    tester,
    EditFieldsSheet(
      title: "Item details",
      subtitle: subtitle,
      fields: fields,
      onSubmit: submit.call,
      onSaved: log.saved.add,
      onCancel: () => log.cancelled++,
      errorMessage: errorMessage,
    ),
    theme: theme,
    surfaceSize: surfaceSize,
  );
  return log;
}

void main() {
  group("rendering", () {
    testWidgets("renders the header, uppercase labels, hints and initial values", (WidgetTester tester) async {
      await _pumpSheet(tester, _FakeSubmit());

      expect(find.text("Item details"), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text("Item details"),
          matching: find.byWidgetPredicate((Widget w) => w is Semantics && (w.properties.header ?? false)),
        ),
        findsOneWidget,
      );
      expect(find.text("Edit the details"), findsOneWidget);
      expect(find.text("NAME"), findsOneWidget);
      expect(find.text("COMMENT"), findsOneWidget);
      expect(find.text("Initial name"), findsOneWidget);
      expect(find.text("Who to contact"), findsOneWidget);
      expect(find.text("Anything to remember"), findsOneWidget);
      expect(find.text(_cancelKey), findsOneWidget);
      expect(find.text(_saveKey), findsOneWidget);
      expect(find.byType(Loader), findsNothing);
    });

    testWidgets("omits the subtitle when null or empty", (WidgetTester tester) async {
      await _pumpSheet(tester, _FakeSubmit(), subtitle: null);
      expect(find.text("Edit the details"), findsNothing);

      await _pumpSheet(tester, _FakeSubmit(), subtitle: "");
      expect(find.byType(Text).evaluate().where((Element e) => (e.widget as Text).data == ""), isEmpty);
    });

    testWidgets("each text field is labelled with its field label", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpSheet(tester, _FakeSubmit());

      final SemanticsData name = tester.getSemantics(_field("Name")).getSemanticsData();
      expect(name.label, contains("Name"));
      expect(name.label, isNot(contains("NAME")));
      expect(name.flagsCollection.isTextField, isTrue);
      expect(name.value, "Initial name");
      expect(tester.getSemantics(_field("Comment")).label, contains("Comment"));
      handle.dispose();
    });

    testWidgets("a maxLength field shows a counter and caps the input", (WidgetTester tester) async {
      await _pumpSheet(tester, _FakeSubmit());

      expect(find.text("0/20"), findsOneWidget);
      await tester.enterText(_field("Comment"), "x" * 30);
      await tester.pump();
      expect(tester.widget<TextField>(_field("Comment")).controller!.text, "x" * 20);
      expect(find.text("20/20"), findsOneWidget);
    });

    testWidgets("a multi-line field is taller than a single-line one; targets are 48 dp", (WidgetTester tester) async {
      await _pumpSheet(tester, _FakeSubmit());

      final double single = tester.getSize(_field("Name")).height;
      final double multi = tester.getSize(_field("Comment")).height;
      expect(single, greaterThanOrEqualTo(kMinTapTarget));
      expect(multi, greaterThan(single * 2));
      expect(tester.getSize(_saveButton).height, greaterThanOrEqualTo(kMinTapTarget));
      expect(tester.getSize(_cancelButton).height, greaterThanOrEqualTo(kMinTapTarget));
    });

    testWidgets("custom labels replace the default button strings", (WidgetTester tester) async {
      await pumpApp(
        tester,
        EditFieldsSheet(
          title: "Item details",
          fields: _fields,
          onSubmit: _FakeSubmit().call,
          onSaved: (Map<String, String> values) {},
          onCancel: () {},
          submitLabel: "Apply",
          cancelLabel: "Back",
        ),
      );

      expect(find.text("Apply"), findsOneWidget);
      expect(find.text("Back"), findsOneWidget);
      expect(find.text(_saveKey), findsNothing);
      expect(find.text(_cancelKey), findsNothing);
    });
  });

  group("dirty state", () {
    testWidgets("typing enables save; restoring the initial text disables it again", (WidgetTester tester) async {
      await _pumpSheet(tester, _FakeSubmit());
      expect(_enabled(tester, _saveButton), isFalse);
      expect(_enabled(tester, _cancelButton), isTrue);

      await tester.enterText(_field("Name"), "Other name");
      await tester.pump();
      expect(_enabled(tester, _saveButton), isTrue);

      await tester.enterText(_field("Name"), "Initial name");
      await tester.pump();
      expect(_enabled(tester, _saveButton), isFalse);
    });

    testWidgets("whitespace-only changes count as changes (untrimmed comparison)", (WidgetTester tester) async {
      await _pumpSheet(tester, _FakeSubmit());

      await tester.enterText(_field("Name"), "Initial name ");
      await tester.pump();
      expect(_enabled(tester, _saveButton), isTrue);
    });
  });

  group("submit", () {
    testWidgets("save submits every field once, trimmed and keyed by id", (WidgetTester tester) async {
      final _FakeSubmit submit = _FakeSubmit(immediate: true);
      final _Log log = await _pumpSheet(tester, submit);

      await tester.enterText(_field("Comment"), "  remember this  ");
      await tester.pump();
      await tester.tap(_saveButton);
      await tester.pump();

      const Map<String, String> expected = <String, String>{"name": "Initial name", "comment": "remember this"};
      expect(submit.calls, <Map<String, String>>[expected]);
      expect(log.saved, <Map<String, String>>[expected]);
      expect(log.cancelled, 0);
      // Never closes itself: the host decides.
      expect(find.text("Item details"), findsOneWidget);
      expect(find.byType(Loader), findsNothing);
    });

    testWidgets("disables the form and ignores repeat taps while the submit runs", (WidgetTester tester) async {
      final _FakeSubmit submit = _FakeSubmit();
      final _Log log = await _pumpSheet(tester, submit);

      await tester.enterText(_field("Name"), "Other");
      await tester.pump();
      await tester.tap(_saveButton);
      await tester.pump();

      expect(find.byType(Loader), findsOneWidget);
      expect(find.text(_saveKey), findsNothing);
      expect(_enabled(tester, _saveButton), isFalse);
      expect(_enabled(tester, _cancelButton), isFalse);
      for (final TextField field in tester.widgetList<TextField>(find.byType(TextField))) {
        expect(field.enabled, isFalse);
      }

      await tester.tap(_saveButton, warnIfMissed: false);
      await tester.pump();
      expect(submit.calls, hasLength(1));
      expect(log.saved, isEmpty);

      submit.pending.single.complete();
      await tester.pump();
      expect(find.byType(Loader), findsNothing);
      expect(log.saved, <Map<String, String>>[
        <String, String>{"name": "Other", "comment": ""},
      ]);
      expect(log.cancelled, 0);
    });

    testWidgets("a failure shows the default message in a live region and re-enables the form", (WidgetTester tester) async {
      final _FakeSubmit submit = _FakeSubmit();
      final _Log log = await _pumpSheet(tester, submit);

      await tester.enterText(_field("Name"), "Other");
      await tester.pump();
      await tester.tap(_saveButton);
      await tester.pump();
      submit.pending.single.completeError(StateError("boom"));
      await tester.pump();

      expect(find.text(_defaultError), findsOneWidget);
      expect(find.textContaining("boom"), findsNothing);
      expect(
        find.ancestor(
          of: find.text(_defaultError),
          matching: find.byWidgetPredicate((Widget w) => w is Semantics && (w.properties.liveRegion ?? false)),
        ),
        findsOneWidget,
      );
      expect(log.saved, isEmpty);
      expect(_enabled(tester, _saveButton), isTrue);
      expect(_enabled(tester, _cancelButton), isTrue);
      expect(tester.widget<TextField>(_field("Name")).enabled, isTrue);
      expect(find.text("Other"), findsOneWidget);

      // The next attempt clears the error, then succeeds.
      await tester.tap(_saveButton);
      await tester.pump();
      expect(find.text(_defaultError), findsNothing);
      submit.pending.last.complete();
      await tester.pump();
      expect(submit.calls, hasLength(2));
      expect(log.saved, hasLength(1));
    });

    testWidgets("errorMessage maps the error; a null result falls back to the default", (WidgetTester tester) async {
      final _FakeSubmit submit = _FakeSubmit();
      await _pumpSheet(
        tester,
        submit,
        errorMessage: (Object error) => error is StateError ? "mapped: ${error.message}" : null,
      );

      await tester.enterText(_field("Name"), "Other");
      await tester.pump();
      await tester.tap(_saveButton);
      await tester.pump();
      submit.pending.last.completeError(StateError("boom"));
      await tester.pump();
      expect(find.text("mapped: boom"), findsOneWidget);

      await tester.tap(_saveButton);
      await tester.pump();
      submit.pending.last.completeError(Exception("other"));
      await tester.pump();
      expect(find.text("mapped: boom"), findsNothing);
      expect(find.text(_defaultError), findsOneWidget);
    });

    testWidgets("cancel calls onCancel only", (WidgetTester tester) async {
      final _FakeSubmit submit = _FakeSubmit();
      final _Log log = await _pumpSheet(tester, submit);

      await tester.tap(_cancelButton);
      await tester.pump();

      expect(log.cancelled, 1);
      expect(submit.calls, isEmpty);
      expect(log.saved, isEmpty);
    });
  });

  testWidgets("a rebuild keeps edited text and follows a changed field set", (WidgetTester tester) async {
    final _FakeSubmit submit = _FakeSubmit(immediate: true);
    final ValueNotifier<List<EditSheetField>> fields = ValueNotifier<List<EditSheetField>>(_fields);
    addTearDown(fields.dispose);
    final List<Map<String, String>> saved = <Map<String, String>>[];
    await pumpApp(
      tester,
      ValueListenableBuilder<List<EditSheetField>>(
        valueListenable: fields,
        builder: (BuildContext context, List<EditSheetField> value, Widget? child) => EditFieldsSheet(
          title: "Item details",
          fields: value,
          onSubmit: submit.call,
          onSaved: saved.add,
          onCancel: () {},
        ),
      ),
    );

    await tester.enterText(_field("Name"), "Edited");
    await tester.pump();
    fields.value = <EditSheetField>[
      _fields.first,
      const EditSheetField(id: "code", label: "Code", initialValue: "A1"),
    ];
    await tester.pump();

    expect(find.text("COMMENT"), findsNothing);
    expect(find.text("CODE"), findsOneWidget);
    expect(find.text("Edited"), findsOneWidget);
    expect(find.text("A1"), findsOneWidget);

    await tester.tap(_saveButton);
    await tester.pump();
    expect(submit.calls.single, <String, String>{"name": "Edited", "code": "A1"});
  });

  testWidgets("focus and typing stay with a field when fields are inserted or removed before it", (WidgetTester tester) async {
    final ValueNotifier<List<EditSheetField>> fields = ValueNotifier<List<EditSheetField>>(_fields);
    addTearDown(fields.dispose);
    await pumpApp(
      tester,
      ValueListenableBuilder<List<EditSheetField>>(
        valueListenable: fields,
        builder: (BuildContext context, List<EditSheetField> value, Widget? child) => EditFieldsSheet(
          title: "Item details",
          fields: value,
          onSubmit: _FakeSubmit().call,
          onSaved: (Map<String, String> values) {},
          onCancel: () {},
        ),
      ),
    );
    bool hasFocus(String label) {
      final Finder editable = find.descendant(of: _field(label), matching: find.byType(EditableText));
      return tester.state<EditableTextState>(editable).widget.focusNode.hasFocus;
    }

    String textOf(String label) => tester.widget<TextField>(_field(label)).controller!.text;

    await tester.showKeyboard(_field("Comment"));
    tester.testTextInput.enterText("typed in comment");
    await tester.pump();

    fields.value = <EditSheetField>[const EditSheetField(id: "code", label: "Code"), ..._fields];
    await tester.pump();
    expect(hasFocus("Comment"), isTrue);
    expect(hasFocus("Name"), isFalse);
    expect(hasFocus("Code"), isFalse);
    tester.testTextInput.enterText("next keystroke");
    await tester.pump();
    expect(textOf("Comment"), "next keystroke");
    expect(textOf("Name"), "Initial name");
    expect(textOf("Code"), "");

    fields.value = <EditSheetField>[_fields.last];
    await tester.pump();
    expect(hasFocus("Comment"), isTrue);
    tester.testTextInput.enterText("after removal");
    await tester.pump();
    expect(textOf("Comment"), "after removal");
  });

  group("show()", () {
    Future<Future<Map<String, String>?>> openSheet(
      WidgetTester tester,
      _FakeSubmit submit, {
      Size? surfaceSize,
      bool reduceMotion = false,
    }) async {
      late Future<Map<String, String>?> result;
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
            child: Builder(
              builder: (BuildContext context) => TextButton(
                onPressed: () {
                  result = EditFieldsSheet.show(
                    context: context,
                    title: "Item details",
                    subtitle: "Edit the details",
                    fields: _fields,
                    onSubmit: submit.call,
                  );
                },
                child: const Text("open"),
              ),
            ),
          ),
        ),
        surfaceSize: surfaceSize,
      );
      if (reduceMotion) {
        await tester.tap(find.text("open"));
        await tester.pump();
        return result;
      }
      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets("opens a bottom sheet with the host drag handle and resolves with the saved values", (WidgetTester tester) async {
      final _FakeSubmit submit = _FakeSubmit(immediate: true);
      final Future<Map<String, String>?> result = await openSheet(tester, submit);

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(tester.widget<BottomSheet>(find.byType(BottomSheet)).showDragHandle, isTrue);
      expect(find.text("Item details"), findsOneWidget);

      await tester.enterText(_field("Name"), " Saved ");
      await tester.pump();
      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(await result, <String, String>{"name": "Saved", "comment": ""});
    });

    testWidgets("cancel resolves to null without submitting", (WidgetTester tester) async {
      final _FakeSubmit submit = _FakeSubmit(immediate: true);
      final Future<Map<String, String>?> result = await openSheet(tester, submit);

      await tester.tap(_cancelButton);
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(await result, isNull);
      expect(submit.calls, isEmpty);
    });

    testWidgets("a scrim tap resolves to null", (WidgetTester tester) async {
      final Future<Map<String, String>?> result = await openSheet(tester, _FakeSubmit());

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(await result, isNull);
    });

    testWidgets("a save completing during the closing animation does not pop the page", (WidgetTester tester) async {
      final _FakeSubmit submit = _FakeSubmit();
      final Future<Map<String, String>?> result = await openSheet(tester, submit);

      await tester.enterText(_field("Name"), "Other");
      await tester.pump();
      await tester.tap(_saveButton);
      await tester.pump();
      await tester.tapAt(const Offset(10, 10));
      await tester.pump(const Duration(milliseconds: 50));
      // Still mounted mid-exit, so onSaved runs: only the isCurrent guard
      // keeps it from popping the page underneath.
      expect(find.byType(BottomSheet), findsOneWidget);

      submit.pending.single.complete();
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text("open"), findsOneWidget);
      expect(await result, isNull);
    });

    testWidgets("header scrolls and the action bar stays visible in landscape with the keyboard open", (WidgetTester tester) async {
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      addTearDown(tester.view.resetViewInsets);
      await openSheet(tester, _FakeSubmit(), surfaceSize: const Size(780, 360));

      expect(tester.takeException(), isNull);
      expect(
        find.descendant(of: find.byType(SingleChildScrollView), matching: find.text("Item details")),
        findsOneWidget,
      );
      expect(tester.getRect(_saveButton).bottom, lessThanOrEqualTo(360 - 180));
    });

    testWidgets("skips the sheet animation when the platform reduces motion", (WidgetTester tester) async {
      await openSheet(tester, _FakeSubmit(), reduceMotion: true);

      final ModalRoute<Object?> route = ModalRoute.of(tester.element(find.text("Item details")))!;
      expect(route.animation!.status, AnimationStatus.completed);

      await tester.tap(_cancelButton);
      await tester.pump();
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  testWidgets("dark theme smoke test", (WidgetTester tester) async {
    final _FakeSubmit submit = _FakeSubmit();
    await _pumpSheet(tester, submit, theme: AppTheme.dark());

    await tester.enterText(_field("Name"), "Other");
    await tester.pump();
    await tester.tap(_saveButton);
    await tester.pump();
    expect(find.byType(Loader), findsOneWidget);
    submit.pending.single.completeError(Exception("x"));
    await tester.pump();
    expect(find.text(_defaultError), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("many fields scroll on a short surface without overflow", (WidgetTester tester) async {
    await _pumpSheet(
      tester,
      _FakeSubmit(),
      surfaceSize: const Size(360, 480),
      fields: <EditSheetField>[
        for (int i = 0; i < 8; i++) EditSheetField(id: "f$i", label: "Field $i"),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    final Finder formScrollable = find
        .descendant(of: find.byType(SingleChildScrollView), matching: find.byType(Scrollable))
        .first;
    final Rect form = tester.getRect(find.byType(SingleChildScrollView));
    expect(tester.getRect(find.text("FIELD 7")).top, greaterThan(form.bottom));
    // The action bar stays pinned under the scrolling fields.
    expect(tester.getRect(_saveButton).top, greaterThanOrEqualTo(form.bottom));

    await tester.scrollUntilVisible(find.text("FIELD 7"), 100, scrollable: formScrollable);
    expect(tester.getRect(find.text("FIELD 7")).bottom, lessThanOrEqualTo(form.bottom));
  });
}

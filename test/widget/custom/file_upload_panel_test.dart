// file_upload_panel_test.dart
//
// Widget tests for FileUploadPanel: optional header, the picker seam
// (arguments, cancel, failure, late results), the file list and its
// semantics, the upload flow (progress, success, read error, failure and
// retry, readable files only), disposal safety, tap targets on every
// platform, live regions, reduced motion and a dark-theme smoke test. The
// picker and the upload are fake closures.

import "dart:async";
import "dart:typed_data";

import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/FileUploadPanel/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _pick = "custom.file_upload_panel.pick";
const String _clear = "custom.file_upload_panel.clear";
const String _submit = "custom.file_upload_panel.submit";
const String _uploading = "custom.file_upload_panel.uploading";
const String _success = "custom.file_upload_panel.success";
const String _failed = "custom.file_upload_panel.failed";
const String _readError = "custom.file_upload_panel.read_error";

final SelectedFile _readable = SelectedFile(
  name: "report.csv",
  size: 1536,
  bytes: Uint8List.fromList(<int>[1, 2, 3]),
);
const SelectedFile _unreadable = SelectedFile(name: "notes.txt", size: 512);

/// Fake picker: records each call and throws [error] when set, resolves with
/// [result], or waits on a completer when [pending] is true.
final class _FakePicker {
  List<SelectedFile>? result;
  Object? error;
  final bool pending;
  final List<({List<String>? extensions, bool multiple})> calls =
      <({List<String>? extensions, bool multiple})>[];
  final List<Completer<List<SelectedFile>?>> waiting = <Completer<List<SelectedFile>?>>[];

  _FakePicker({this.result, this.pending = false});

  Future<List<SelectedFile>?> call({List<String>? allowedExtensions, required bool allowMultiple}) {
    calls.add((extensions: allowedExtensions, multiple: allowMultiple));
    final Object? error = this.error;
    if (error != null) return Future<List<SelectedFile>?>.error(error);
    if (!pending) return Future<List<SelectedFile>?>.value(result);
    final Completer<List<SelectedFile>?> completer = Completer<List<SelectedFile>?>();
    waiting.add(completer);
    return completer.future;
  }
}

/// Fake upload: records each call and waits on its own completer.
final class _FakeUpload {
  final List<List<SelectedFile>> calls = <List<SelectedFile>>[];
  final List<Completer<void>> pending = <Completer<void>>[];

  Future<void> call(List<SelectedFile> files) {
    calls.add(files);
    final Completer<void> completer = Completer<void>();
    pending.add(completer);
    return completer.future;
  }
}

final class _Harness {
  final _FakePicker picker;
  final _FakeUpload upload = _FakeUpload();
  int successes = 0;
  final List<Object> errors = <Object>[];

  _Harness(this.picker);

  FileUploadPanel panel({
    String? title,
    String? hint,
    List<String>? allowedExtensions,
    bool allowMultiple = true,
  }) {
    return FileUploadPanel(
      pickFiles: picker.call,
      onUpload: upload.call,
      onSuccess: () => successes++,
      onError: errors.add,
      title: title,
      hint: hint,
      allowedExtensions: allowedExtensions,
      allowMultiple: allowMultiple,
    );
  }
}

Future<_Harness> _pumpPanel(
  WidgetTester tester, {
  _FakePicker? picker,
  String? title,
  String? hint,
  List<String>? allowedExtensions,
  bool allowMultiple = true,
  ThemeData? theme,
}) async {
  final _Harness harness = _Harness(picker ?? _FakePicker());
  await pumpApp(
    tester,
    SingleChildScrollView(
      child: harness.panel(
        title: title,
        hint: hint,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
      ),
    ),
    theme: theme,
  );
  return harness;
}

Finder _pickButton() => find.byWidgetPredicate((Widget w) => w is OutlinedButton);
Finder _clearButton() => find.byWidgetPredicate((Widget w) => w is TextButton);
Finder _submitButton() => find.byWidgetPredicate((Widget w) => w is FilledButton);

VoidCallback? _onPressed(WidgetTester tester, Finder finder) {
  return tester.widget<ButtonStyleButton>(finder).onPressed;
}

Future<void> _tapPick(WidgetTester tester) async {
  await tester.tap(_pickButton());
  await tester.pump();
}

Future<void> _tapSubmit(WidgetTester tester) async {
  await tester.tap(_submitButton());
  await tester.pump();
}

Finder _liveRegionAround(Finder of) {
  return find.ancestor(
    of: of,
    matching: find.byWidgetPredicate((Widget w) => w is Semantics && (w.properties.liveRegion ?? false)),
  );
}

Color _toneForeground(WidgetTester tester, StatusTone tone) {
  return StatusTones.colorsOf(tester.element(find.byType(FileUploadPanel)), tone).foreground;
}

void main() {
  group("header", () {
    testWidgets("renders the title as a header and the hint", (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _pumpPanel(tester, title: "Import files", hint: "Pick one or more files.");

      expect(find.text("Import files"), findsOneWidget);
      expect(find.text("Pick one or more files."), findsOneWidget);
      expect(
        tester.getSemantics(find.text("Import files")),
        matchesSemantics(label: "Import files", isHeader: true),
      );
      semantics.dispose();
    });

    testWidgets("omits the header when title and hint are null", (WidgetTester tester) async {
      await _pumpPanel(tester);

      expect(find.byType(Text), findsNWidgets(2));
      expect(find.text(_pick), findsOneWidget);
      expect(find.text(_submit), findsOneWidget);
    });

    testWidgets("renders a hint without a title", (WidgetTester tester) async {
      await _pumpPanel(tester, hint: "Only the hint");

      expect(find.text("Only the hint"), findsOneWidget);
      expect(find.byType(Text), findsNWidgets(3));
    });
  });

  group("picking", () {
    testWidgets("forwards allowedExtensions and allowMultiple to the picker", (WidgetTester tester) async {
      final _Harness harness = await _pumpPanel(
        tester,
        picker: _FakePicker(result: <SelectedFile>[_readable]),
        allowedExtensions: <String>["csv"],
        allowMultiple: false,
      );

      await _tapPick(tester);

      expect(harness.picker.calls, hasLength(1));
      expect(harness.picker.calls.single.extensions, <String>["csv"]);
      expect(harness.picker.calls.single.multiple, isFalse);
    });

    testWidgets("defaults to any file type and multi-select", (WidgetTester tester) async {
      final _Harness harness = await _pumpPanel(tester, picker: _FakePicker(result: <SelectedFile>[_readable]));

      await _tapPick(tester);

      expect(harness.picker.calls.single.extensions, isNull);
      expect(harness.picker.calls.single.multiple, isTrue);
    });

    testWidgets("lists the picked files with their size and a clear action", (WidgetTester tester) async {
      await _pumpPanel(tester, picker: _FakePicker(result: <SelectedFile>[_readable, _unreadable]));
      expect(find.text(_clear), findsNothing);

      await _tapPick(tester);

      expect(find.text("report.csv"), findsOneWidget);
      expect(find.text("notes.txt"), findsOneWidget);
      // Without EasyLocalization in the tree, .tr() returns the raw key.
      expect(find.text("custom.file_upload_panel.size_kb"), findsOneWidget);
      expect(find.text("custom.file_upload_panel.size_bytes"), findsOneWidget);
      expect(find.text(_clear), findsOneWidget);
    });

    testWidgets("gives each file row one semantics label", (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _pumpPanel(tester, picker: _FakePicker(result: <SelectedFile>[_readable]));

      await _tapPick(tester);

      expect(
        find.bySemanticsLabel("report.csv, custom.file_upload_panel.size_kb"),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets("a cancelled pick keeps the selection and the state", (WidgetTester tester) async {
      final _Harness harness = await _pumpPanel(tester, picker: _FakePicker(result: <SelectedFile>[_readable]));
      await _tapPick(tester);

      harness.picker.result = null;
      await _tapPick(tester);

      expect(harness.picker.calls, hasLength(2));
      expect(find.text("report.csv"), findsOneWidget);
      expect(_onPressed(tester, _submitButton()), isNotNull);
    });

    testWidgets("a throwing picker reports the error and keeps the selection", (WidgetTester tester) async {
      final _Harness harness = await _pumpPanel(tester, picker: _FakePicker(result: <SelectedFile>[_readable]));
      await _tapPick(tester);

      final StateError failure = StateError("picker failed");
      harness.picker.error = failure;
      await _tapPick(tester);

      expect(tester.takeException(), isNull);
      expect(harness.errors, <Object>[failure]);
      expect(find.text("report.csv"), findsOneWidget);
      expect(_onPressed(tester, _pickButton()), isNotNull);
      expect(_onPressed(tester, _submitButton()), isNotNull);
    });

    testWidgets("a picker failing after unmount calls no callback", (WidgetTester tester) async {
      final _Harness harness = await _pumpPanel(tester, picker: _FakePicker(pending: true));
      await _tapPick(tester);

      await pumpApp(tester, const SizedBox.shrink());
      harness.picker.waiting.single.completeError(StateError("late"));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(harness.errors, isEmpty);
    });

    testWidgets("a new pick replaces the selection", (WidgetTester tester) async {
      final _Harness harness = await _pumpPanel(tester, picker: _FakePicker(result: <SelectedFile>[_readable]));
      await _tapPick(tester);

      harness.picker.result = <SelectedFile>[_unreadable];
      await _tapPick(tester);

      expect(find.text("report.csv"), findsNothing);
      expect(find.text("notes.txt"), findsOneWidget);
    });
  });

  group("buttons", () {
    testWidgets("submit is disabled without files and enabled after a pick", (WidgetTester tester) async {
      await _pumpPanel(tester, picker: _FakePicker(result: <SelectedFile>[_readable]));
      expect(_onPressed(tester, _submitButton()), isNull);
      expect(_onPressed(tester, _pickButton()), isNotNull);

      await _tapPick(tester);

      expect(_onPressed(tester, _submitButton()), isNotNull);
    });

    testWidgets("clear empties the list and returns to idle", (WidgetTester tester) async {
      await _pumpPanel(tester, picker: _FakePicker(result: <SelectedFile>[_unreadable]));
      await _tapPick(tester);
      await _tapSubmit(tester);
      expect(find.text(_readError), findsOneWidget);

      await tester.tap(_clearButton());
      await tester.pump();

      expect(find.text("notes.txt"), findsNothing);
      expect(find.text(_readError), findsNothing);
      expect(find.text(_clear), findsNothing);
      expect(_onPressed(tester, _submitButton()), isNull);
    });

    // Every platform: desktop themes default to compact density and a
    // shrink-wrapped tap target, which would lower the buttons to 40 dp.
    testWidgets(
      "pick, clear and submit are at least kMinTapTarget tall",
      (WidgetTester tester) async {
        await _pumpPanel(tester, picker: _FakePicker(result: <SelectedFile>[_readable]));
        await _tapPick(tester);

        for (final Finder button in <Finder>[_pickButton(), _clearButton(), _submitButton()]) {
          final Size size = tester.getSize(button);
          expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
          expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
        }
      },
      variant: TargetPlatformVariant.all(),
    );
  });

  group("upload", () {
    testWidgets("shows progress in a live region and disables every button while uploading",
        (WidgetTester tester) async {
      final _Harness harness = await _pumpPanel(tester, picker: _FakePicker(result: <SelectedFile>[_readable]));
      await _tapPick(tester);

      await _tapSubmit(tester);

      expect(harness.upload.calls, hasLength(1));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text(_uploading), findsOneWidget);
      expect(_liveRegionAround(find.text(_uploading)), findsWidgets);
      expect(_onPressed(tester, _pickButton()), isNull);
      expect(_onPressed(tester, _clearButton()), isNull);
      expect(_onPressed(tester, _submitButton()), isNull);

      harness.upload.pending.single.complete();
      await tester.pump();
    });

    testWidgets("shows the success line and calls onSuccess once", (WidgetTester tester) async {
      final _Harness harness = await _pumpPanel(tester, picker: _FakePicker(result: <SelectedFile>[_readable]));
      await _tapPick(tester);
      await _tapSubmit(tester);

      harness.upload.pending.single.complete();
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text(_success), findsOneWidget);
      expect(find.byIcon(StatusTone.success.icon), findsOneWidget);
      expect(_liveRegionAround(find.text(_success)), findsWidgets);
      expect(
        tester.widget<Text>(find.text(_success)).style?.color,
        _toneForeground(tester, StatusTone.success),
      );
      expect(harness.successes, 1);
      expect(harness.errors, isEmpty);
      expect(_onPressed(tester, _submitButton()), isNull);
      expect(_onPressed(tester, _pickButton()), isNotNull);
      expect(_onPressed(tester, _clearButton()), isNotNull);
    });

    testWidgets("a new pick after a success resets to idle and enables submit", (WidgetTester tester) async {
      final _Harness harness = await _pumpPanel(tester, picker: _FakePicker(result: <SelectedFile>[_readable]));
      await _tapPick(tester);
      await _tapSubmit(tester);
      harness.upload.pending.single.complete();
      await tester.pump();

      await _tapPick(tester);

      expect(find.text(_success), findsNothing);
      expect(_onPressed(tester, _submitButton()), isNotNull);
    });

    testWidgets("uploads only the readable files", (WidgetTester tester) async {
      final _Harness harness = await _pumpPanel(tester, picker: _FakePicker(result: <SelectedFile>[_readable, _unreadable]));
      await _tapPick(tester);

      await _tapSubmit(tester);

      final List<SelectedFile> sent = harness.upload.calls.single;
      expect(sent, hasLength(1));
      expect(sent.single.name, "report.csv");
      expect(sent.single.bytes, <int>[1, 2, 3]);

      harness.upload.pending.single.complete();
      await tester.pump();
    });

    testWidgets("shows a read error without calling onUpload when no file is readable",
        (WidgetTester tester) async {
      final _Harness harness = await _pumpPanel(tester, picker: _FakePicker(result: <SelectedFile>[_unreadable]));
      await _tapPick(tester);

      await _tapSubmit(tester);

      expect(find.text(_readError), findsOneWidget);
      expect(find.byIcon(StatusTone.danger.icon), findsOneWidget);
      expect(harness.upload.calls, isEmpty);
      expect(harness.errors, isEmpty);
      expect(harness.successes, 0);
    });

    testWidgets("shows the failure line, reports the error and allows a retry", (WidgetTester tester) async {
      final _Harness harness = await _pumpPanel(tester, picker: _FakePicker(result: <SelectedFile>[_readable]));
      await _tapPick(tester);
      await _tapSubmit(tester);

      final Exception boom = Exception("boom");
      harness.upload.pending.single.completeError(boom);
      await tester.pump();

      expect(find.text(_failed), findsOneWidget);
      expect(find.byIcon(StatusTone.danger.icon), findsOneWidget);
      expect(_liveRegionAround(find.text(_failed)), findsWidgets);
      expect(
        tester.widget<Text>(find.text(_failed)).style?.color,
        _toneForeground(tester, StatusTone.danger),
      );
      expect(harness.errors, <Object>[boom]);
      expect(harness.successes, 0);
      expect(_onPressed(tester, _submitButton()), isNotNull);

      await _tapSubmit(tester);
      expect(harness.upload.calls, hasLength(2));
      expect(find.text(_failed), findsNothing);
      expect(find.text(_uploading), findsOneWidget);

      harness.upload.pending.last.complete();
      await tester.pump();
      expect(find.text(_success), findsOneWidget);
      expect(harness.successes, 1);
    });

    testWidgets("ignores a pick that resolves while an upload runs", (WidgetTester tester) async {
      final _Harness harness = await _pumpPanel(tester, picker: _FakePicker(pending: true));
      await _tapPick(tester);
      harness.picker.waiting.single.complete(<SelectedFile>[_readable]);
      await tester.pump();

      await _tapPick(tester);
      await _tapSubmit(tester);
      harness.picker.waiting.last.complete(<SelectedFile>[_unreadable]);
      await tester.pump();

      expect(find.text("report.csv"), findsOneWidget);
      expect(find.text("notes.txt"), findsNothing);
      expect(find.text(_uploading), findsOneWidget);

      harness.upload.pending.single.complete();
      await tester.pump();
      expect(find.text(_success), findsOneWidget);
    });

    testWidgets("omits the progress bar under reduced motion", (WidgetTester tester) async {
      final _Harness harness = _Harness(_FakePicker(result: <SelectedFile>[_readable]));
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: harness.panel(),
          ),
        ),
      );
      await _tapPick(tester);

      await _tapSubmit(tester);

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text(_uploading), findsOneWidget);
      expect(_liveRegionAround(find.text(_uploading)), findsWidgets);

      harness.upload.pending.single.complete();
      await tester.pump();
    });
  });

  group("disposal", () {
    Future<void> unmount(WidgetTester tester) async {
      await pumpApp(tester, const SizedBox.shrink());
    }

    testWidgets("a pick resolving after unmount is ignored", (WidgetTester tester) async {
      final _Harness harness = await _pumpPanel(tester, picker: _FakePicker(pending: true));
      await _tapPick(tester);

      await unmount(tester);
      harness.picker.waiting.single.complete(<SelectedFile>[_readable]);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets("an upload succeeding after unmount calls no callback", (WidgetTester tester) async {
      final _Harness harness = await _pumpPanel(tester, picker: _FakePicker(result: <SelectedFile>[_readable]));
      await _tapPick(tester);
      await _tapSubmit(tester);

      await unmount(tester);
      harness.upload.pending.single.complete();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(harness.successes, 0);
    });

    testWidgets("an upload failing after unmount calls no callback", (WidgetTester tester) async {
      final _Harness harness = await _pumpPanel(tester, picker: _FakePicker(result: <SelectedFile>[_readable]));
      await _tapPick(tester);
      await _tapSubmit(tester);

      await unmount(tester);
      harness.upload.pending.single.completeError(Exception("late"));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(harness.errors, isEmpty);
    });
  });

  group("theme", () {
    testWidgets("renders every state under AppTheme.dark() with tone colours", (WidgetTester tester) async {
      final _Harness harness = await _pumpPanel(
        tester,
        picker: _FakePicker(result: <SelectedFile>[_readable, _unreadable]),
        title: "Import files",
        hint: "Pick one or more files.",
        theme: AppTheme.dark(),
      );
      await _tapPick(tester);
      await _tapSubmit(tester);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      harness.upload.pending.single.complete();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text(_success), findsOneWidget);
      expect(
        tester.widget<Text>(find.text(_success)).style?.color,
        StatusTones.fromScheme(AppTheme.dark().colorScheme).success.foreground,
      );
    });

    // The test font draws every glyph one em wide, so the raw size key alone
    // needs about 350 dp: 480 dp is the narrowest surface that fits it.
    testWidgets("ellipsizes a long file name without overflow", (WidgetTester tester) async {
      await _pumpPanel(
        tester,
        picker: _FakePicker(result: <SelectedFile>[
          SelectedFile(
            name: "a-very-long-file-name-that-does-not-fit-on-one-line-at-all.csv",
            size: 5 * 1024 * 1024,
            bytes: Uint8List(1),
          ),
        ]),
        title: "Import files",
      );
      tester.view.physicalSize = const Size(480, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pump();

      await _tapPick(tester);

      expect(tester.takeException(), isNull);
      expect(find.text("custom.file_upload_panel.size_mb"), findsOneWidget);
      final Text name = tester.widget<Text>(
        find.text("a-very-long-file-name-that-does-not-fit-on-one-line-at-all.csv"),
      );
      expect(name.maxLines, 1);
      expect(name.overflow, TextOverflow.ellipsis);
    });
  });
}

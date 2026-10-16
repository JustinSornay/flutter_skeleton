// async_picker_sheet_test.dart
//
// Widget tests for AsyncPickerSheet<T>: header and body rendering, the
// transparent ink Material, the single-submit guard while busy (announced as
// a live region), inline errors and retry, the callbacks of the content-only
// widget (including a late pick after disposal), and the show() helper
// (result, close, barrier, keyboard insets, close while a submit is pending,
// a submit settling after the sheet is disposed), plus a dark / small-surface
// smoke test.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/custom/AsyncPickerSheet/index.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const String _defaultError = "custom.async_picker_sheet.submit_failed";
const String _closeTooltip = "custom.async_picker_sheet.close";

/// Picker body used by every test: one tappable row per value.
Widget _picker(BuildContext context, ValueChanged<String> onPicked) {
  return ListView(
    children: <Widget>[
      for (final String value in <String>["alpha", "beta", "gamma"])
        ListTile(title: Text(value), onTap: () => onPicked(value)),
    ],
  );
}

/// Records onSubmit calls; each call waits on its own completer unless the
/// fake resolves immediately.
final class _FakeSubmit {
  final bool immediate;
  final List<String> calls = <String>[];
  final List<Completer<void>> pending = <Completer<void>>[];

  _FakeSubmit({this.immediate = false});

  Future<void> call(String value) {
    calls.add(value);
    if (immediate) return Future<void>.value();
    final Completer<void> completer = Completer<void>();
    pending.add(completer);
    return completer.future;
  }
}

Finder _semanticsAncestor(Finder of, bool Function(SemanticsProperties p) test) {
  return find.ancestor(
    of: of,
    matching: find.byWidgetPredicate((Widget w) => w is Semantics && test(w.properties)),
  );
}

void main() {
  group("content-only widget", () {
    Future<({List<String> submitted, List<int> closed})> pumpSheet(
      WidgetTester tester,
      _FakeSubmit submit, {
      String? Function(Object error)? errorMessage,
    }) async {
      final List<String> submitted = <String>[];
      final List<int> closed = <int>[];
      await pumpApp(
        tester,
        AsyncPickerSheet<String>(
          title: "Pick one",
          builder: _picker,
          onSubmit: submit.call,
          onSubmitted: submitted.add,
          onClose: () => closed.add(1),
          errorMessage: errorMessage,
        ),
      );
      return (submitted: submitted, closed: closed);
    }

    testWidgets("renders the title as a header, the close button and the body", (WidgetTester tester) async {
      await pumpSheet(tester, _FakeSubmit());

      expect(find.text("Pick one"), findsOneWidget);
      expect(_semanticsAncestor(find.text("Pick one"), (SemanticsProperties p) => p.header ?? false), findsOneWidget);
      expect(find.byTooltip(_closeTooltip), findsOneWidget);
      expect(find.text("alpha"), findsOneWidget);
      expect(find.text("gamma"), findsOneWidget);
      expect(find.byType(Loader), findsNothing);
    });

    testWidgets("paints its own transparent Material for the body's ink", (WidgetTester tester) async {
      await pumpSheet(tester, _FakeSubmit());

      final Finder materials = find.ancestor(of: find.byType(ListTile).first, matching: find.byType(Material));
      final Material nearest = tester.widget<Material>(materials.first);
      expect(nearest.type, MaterialType.transparency);
      expect(
        find.descendant(of: find.byType(AsyncPickerSheet<String>), matching: find.byWidget(nearest)),
        findsOneWidget,
      );
    });

    testWidgets("a pick submits once and reports the value", (WidgetTester tester) async {
      final _FakeSubmit submit = _FakeSubmit(immediate: true);
      final ({List<String> submitted, List<int> closed}) log = await pumpSheet(tester, submit);

      await tester.tap(find.text("beta"));
      await tester.pump();

      expect(submit.calls, <String>["beta"]);
      expect(log.submitted, <String>["beta"]);
      expect(log.closed, isEmpty);
      // Never pops by itself: the host decides.
      expect(find.text("Pick one"), findsOneWidget);
      expect(find.byType(Loader), findsNothing);
    });

    testWidgets("ignores picks while the submit runs and shows the loader", (WidgetTester tester) async {
      final _FakeSubmit submit = _FakeSubmit();
      late ValueChanged<String> onPicked;
      final List<String> submitted = <String>[];
      await pumpApp(
        tester,
        AsyncPickerSheet<String>(
          title: "Pick one",
          builder: (BuildContext context, ValueChanged<String> picked) {
            onPicked = picked;
            return _picker(context, picked);
          },
          onSubmit: submit.call,
          onSubmitted: submitted.add,
          onClose: () {},
        ),
      );

      await tester.tap(find.text("alpha"));
      await tester.pump();
      expect(find.byType(Loader), findsOneWidget);

      // The overlay absorbs taps…
      await tester.tap(find.text("beta"), warnIfMissed: false);
      await tester.pump();
      // …and the guard ignores direct picks.
      onPicked("gamma");
      await tester.pump();
      expect(submit.calls, <String>["alpha"]);

      submit.pending.single.complete();
      await tester.pump();
      expect(find.byType(Loader), findsNothing);
      expect(submitted, <String>["alpha"]);
    });

    testWidgets("announces the busy loader as a live region", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final _FakeSubmit submit = _FakeSubmit();
      await pumpSheet(tester, submit);

      await tester.tap(find.text("alpha"));
      await tester.pump();

      expect(_semanticsAncestor(find.byType(Loader), (SemanticsProperties p) => p.liveRegion ?? false), findsOneWidget);
      expect(tester.getSemantics(find.byType(Loader)), isSemantics(label: "common.loading", isLiveRegion: true));

      submit.pending.single.complete();
      await tester.pump();
      handle.dispose();
    });

    testWidgets("ignores a late pick once the widget is disposed", (WidgetTester tester) async {
      final _FakeSubmit submit = _FakeSubmit();
      late ValueChanged<String> onPicked;
      final List<String> submitted = <String>[];
      await pumpApp(
        tester,
        AsyncPickerSheet<String>(
          title: "Pick one",
          builder: (BuildContext context, ValueChanged<String> picked) {
            onPicked = picked;
            return _picker(context, picked);
          },
          onSubmit: submit.call,
          onSubmitted: submitted.add,
          onClose: () {},
        ),
      );

      // The host replaces the sheet; the caller's body calls back afterwards.
      await pumpApp(tester, const SizedBox.shrink());
      onPicked("late");
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(submit.calls, isEmpty);
      expect(submitted, isEmpty);
    });

    testWidgets("a failure keeps the sheet and shows the mapped message in a live region", (WidgetTester tester) async {
      final _FakeSubmit submit = _FakeSubmit();
      final ({List<String> submitted, List<int> closed}) log = await pumpSheet(
        tester,
        submit,
        errorMessage: (Object error) => "mapped: $error",
      );

      await tester.tap(find.text("alpha"));
      await tester.pump();
      submit.pending.single.completeError("conflict");
      await tester.pump();

      expect(find.text("mapped: conflict"), findsOneWidget);
      expect(_semanticsAncestor(find.text("mapped: conflict"), (SemanticsProperties p) => p.liveRegion ?? false), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byType(Loader), findsNothing);
      expect(log.submitted, isEmpty);
      expect(find.text("alpha"), findsOneWidget);
    });

    testWidgets("falls back to the default message without a mapper", (WidgetTester tester) async {
      final _FakeSubmit submit = _FakeSubmit();
      await pumpSheet(tester, submit);

      await tester.tap(find.text("alpha"));
      await tester.pump();
      submit.pending.single.completeError(StateError("boom"));
      await tester.pump();

      expect(find.text(_defaultError), findsOneWidget);
    });

    testWidgets("falls back to the default message when the mapper returns null", (WidgetTester tester) async {
      final _FakeSubmit submit = _FakeSubmit();
      await pumpSheet(tester, submit, errorMessage: (Object error) => null);

      await tester.tap(find.text("alpha"));
      await tester.pump();
      submit.pending.single.completeError("unmapped");
      await tester.pump();

      expect(find.text(_defaultError), findsOneWidget);
    });

    testWidgets("picking again clears the error and retries", (WidgetTester tester) async {
      final _FakeSubmit submit = _FakeSubmit();
      final ({List<String> submitted, List<int> closed}) log = await pumpSheet(tester, submit);

      await tester.tap(find.text("alpha"));
      await tester.pump();
      submit.pending.first.completeError("down");
      await tester.pump();
      expect(find.text(_defaultError), findsOneWidget);

      await tester.tap(find.text("gamma"));
      await tester.pump();
      expect(find.text(_defaultError), findsNothing);
      expect(submit.calls, <String>["alpha", "gamma"]);

      submit.pending.last.complete();
      await tester.pump();
      expect(log.submitted, <String>["gamma"]);
    });

    testWidgets("the close button calls onClose, even while busy", (WidgetTester tester) async {
      final _FakeSubmit submit = _FakeSubmit();
      final ({List<String> submitted, List<int> closed}) log = await pumpSheet(tester, submit);

      await tester.tap(find.byTooltip(_closeTooltip));
      await tester.pump();
      expect(log.closed, hasLength(1));

      await tester.tap(find.text("alpha"));
      await tester.pump();
      await tester.tap(find.byTooltip(_closeTooltip));
      await tester.pump();
      expect(log.closed, hasLength(2));

      submit.pending.single.complete();
      await tester.pump();
    });

    testWidgets("close button keeps a 48 dp target", (WidgetTester tester) async {
      await pumpSheet(tester, _FakeSubmit());

      final Size size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }, variant: TargetPlatformVariant.all());
  });

  group("show()", () {
    Future<void> pumpLauncher(
      WidgetTester tester,
      void Function(BuildContext context) open, {
      ThemeData? theme,
      Size? surfaceSize,
    }) async {
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => Center(
            child: TextButton(onPressed: () => open(context), child: const Text("open")),
          ),
        ),
        theme: theme,
        surfaceSize: surfaceSize,
      );
      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();
    }

    ({bool done, String? value}) result = (done: false, value: null);

    void track(Future<String?> future) {
      result = (done: false, value: null);
      unawaited(future.then((String? value) => result = (done: true, value: value)));
    }

    testWidgets("resolves with the submitted value and closes", (WidgetTester tester) async {
      final _FakeSubmit submit = _FakeSubmit();
      await pumpLauncher(tester, (BuildContext context) {
        track(AsyncPickerSheet.show<String>(context: context, title: "Pick one", builder: _picker, onSubmit: submit.call));
      });
      expect(find.text("Pick one"), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);

      await tester.tap(find.text("beta"));
      await tester.pump();
      expect(find.byType(Loader), findsOneWidget);
      submit.pending.single.complete();
      await tester.pumpAndSettle();

      expect(find.text("Pick one"), findsNothing);
      expect(find.text("open"), findsOneWidget);
      expect(result, (done: true, value: "beta"));
    });

    testWidgets("stays open on failure, then resolves with the retried value", (WidgetTester tester) async {
      final _FakeSubmit submit = _FakeSubmit();
      await pumpLauncher(tester, (BuildContext context) {
        track(AsyncPickerSheet.show<String>(
          context: context,
          title: "Pick one",
          builder: _picker,
          onSubmit: submit.call,
          errorMessage: (Object error) => "already there",
        ));
      });

      await tester.tap(find.text("alpha"));
      await tester.pump();
      submit.pending.first.completeError("exists");
      await tester.pumpAndSettle();
      expect(find.text("already there"), findsOneWidget);
      expect(find.text("Pick one"), findsOneWidget);
      expect(result.done, isFalse);

      await tester.tap(find.text("gamma"));
      await tester.pump();
      submit.pending.last.complete();
      await tester.pumpAndSettle();
      expect(find.text("Pick one"), findsNothing);
      expect(result, (done: true, value: "gamma"));
    });

    testWidgets("the close button resolves null without submitting", (WidgetTester tester) async {
      final _FakeSubmit submit = _FakeSubmit();
      await pumpLauncher(tester, (BuildContext context) {
        track(AsyncPickerSheet.show<String>(context: context, title: "Pick one", builder: _picker, onSubmit: submit.call));
      });

      await tester.tap(find.byTooltip(_closeTooltip));
      await tester.pumpAndSettle();

      expect(find.text("Pick one"), findsNothing);
      expect(find.text("open"), findsOneWidget);
      expect(result, (done: true, value: null));
      expect(submit.calls, isEmpty);
    });

    testWidgets("a barrier tap resolves null without submitting", (WidgetTester tester) async {
      final _FakeSubmit submit = _FakeSubmit();
      await pumpLauncher(tester, (BuildContext context) {
        track(AsyncPickerSheet.show<String>(context: context, title: "Pick one", builder: _picker, onSubmit: submit.call));
      });

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text("Pick one"), findsNothing);
      expect(result, (done: true, value: null));
      expect(submit.calls, isEmpty);
    });

    testWidgets("follows the keyboard: the body ends above the view insets", (WidgetTester tester) async {
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      final _FakeSubmit submit = _FakeSubmit();
      await pumpLauncher(
        tester,
        (BuildContext context) {
          track(AsyncPickerSheet.show<String>(context: context, title: "Pick one", builder: _picker, onSubmit: submit.call));
        },
        surfaceSize: const Size(400, 800),
      );

      expect(find.text("Pick one"), findsOneWidget);
      // The body stops at the keyboard edge instead of running under it.
      expect(tester.getRect(find.byType(ListView)).bottom, moreOrLessEquals(800 - 300));
      expect(tester.takeException(), isNull);
    });

    for (final bool fails in <bool>[false, true]) {
      testWidgets("closing while a submit is pending never pops the page and resolves null (${fails ? "failure" : "success"})", (WidgetTester tester) async {
        final _FakeSubmit submit = _FakeSubmit();
        await pumpLauncher(tester, (BuildContext context) {
          track(AsyncPickerSheet.show<String>(context: context, title: "Pick one", builder: _picker, onSubmit: submit.call));
        });

        await tester.tap(find.text("alpha"));
        await tester.pump();
        await tester.tap(find.byTooltip(_closeTooltip));
        await tester.pump();
        // The submit settles during the closing animation.
        if (fails) {
          submit.pending.single.completeError("late");
        } else {
          submit.pending.single.complete();
        }
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text("Pick one"), findsNothing);
        expect(find.text("open"), findsOneWidget);
        // Documented: closing does not cancel the call, and show() resolves
        // null even when it succeeds.
        expect(submit.calls, <String>["alpha"]);
        expect(result, (done: true, value: null));
      });

      testWidgets("a submit that settles after the sheet is disposed is dropped (${fails ? "failure" : "success"})", (WidgetTester tester) async {
        final _FakeSubmit submit = _FakeSubmit();
        await pumpLauncher(tester, (BuildContext context) {
          track(AsyncPickerSheet.show<String>(context: context, title: "Pick one", builder: _picker, onSubmit: submit.call));
        });

        await tester.tap(find.text("alpha"));
        await tester.pump();
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        // The sheet is gone (state disposed) while the call is still running.
        expect(find.byType(AsyncPickerSheet<String>), findsNothing);

        if (fails) {
          submit.pending.single.completeError("late");
        } else {
          submit.pending.single.complete();
        }
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(submit.calls, <String>["alpha"]);
        expect(find.text("open"), findsOneWidget);
        expect(result, (done: true, value: null));
      });
    }

    testWidgets("renders under the dark theme on a small surface with an error", (WidgetTester tester) async {
      final _FakeSubmit submit = _FakeSubmit();
      await pumpLauncher(
        tester,
        (BuildContext context) {
          track(AsyncPickerSheet.show<String>(
            context: context,
            title: "A rather long title that has to wrap on a narrow surface",
            builder: _picker,
            onSubmit: submit.call,
            heightFactor: 0.5,
          ));
        },
        theme: AppTheme.dark(),
        surfaceSize: const Size(360, 640),
      );

      await tester.tap(find.text("alpha"));
      await tester.pump();
      submit.pending.single.completeError("down");
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(_defaultError), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });
}

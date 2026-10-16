// snap_bottom_sheet_test.dart
//
// Widget tests for SnapBottomSheet: header and body built with an attached
// scroll controller, initial height from the controller, pass-through taps
// above the sheet, a collapsed height that fits the handle and the header
// (and clips a grip taller than its limit), moves from code (animation,
// single notification, setSnap / stepDown), the handle (tap cycle, keyboard,
// 48 dp target, semantics and hints), grip and header drags (nearest height,
// fling direction, no notification for passed heights), body drags written
// back into the controller (also when they interrupt a move from code or
// the host rebuilds mid-drag), reduced motion (also a move during a list
// fling), a body whose list attaches late or is rebuilt (moves replayed,
// not during a grip drag), controller swaps (listeners moved and removed),
// fraction changes under a listening host, theme tokens under the light and
// dark themes, and the fraction asserts.

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/SnapBottomSheet/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

const Size _surface = Size(360, 800);
const double _parentHeight = 800;
const double _collapsedHeight = 0.09 * _parentHeight;
const double _midHeight = 0.45 * _parentHeight;
const double _fullHeight = 0.95 * _parentHeight;

const String _handleKey = "custom.snap_bottom_sheet.handle";
const String _expandKey = "custom.snap_bottom_sheet.expand";
const String _collapseKey = "custom.snap_bottom_sheet.collapse";

SnapBottomSheetController _controller([SheetSnap initialSnap = SheetSnap.mid]) {
  final SnapBottomSheetController controller = SnapBottomSheetController(initialSnap: initialSnap);
  addTearDown(controller.dispose);
  return controller;
}

/// Counts the notifications of [controller].
ValueGetter<int> _countNotifications(SnapBottomSheetController controller) {
  int count = 0;
  controller.addListener(() => count++);
  return () => count;
}

Widget _list(BuildContext context, ScrollController scrollController) {
  return ListView.builder(
    controller: scrollController,
    itemCount: 40,
    itemBuilder: (BuildContext context, int index) {
      return SizedBox(height: kMinTapTarget, child: Text("Item $index"));
    },
  );
}

Future<void> _pump(
  WidgetTester tester,
  SnapBottomSheetController controller, {
  Widget? header,
  ThemeData? theme,
  bool reduceMotion = false,
  Size surface = _surface,
  Widget Function(BuildContext context, ScrollController scrollController) builder = _list,
}) async {
  final Widget sheet = SnapBottomSheet(
    controller: controller,
    header: header,
    builder: builder,
  );
  await pumpApp(
    tester,
    Builder(
      builder: (BuildContext context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: sheet,
      ),
    ),
    surfaceSize: surface,
    theme: theme,
  );
  await tester.pumpAndSettle();
}

Finder _sheetBox() {
  return find.descendant(of: find.byType(SnapBottomSheet), matching: find.byType(DecoratedBox)).first;
}

double _sheetHeight(WidgetTester tester) => tester.getSize(_sheetBox()).height;

Offset _handleCenter(WidgetTester tester) {
  return tester.getRect(_sheetBox()).topCenter + const Offset(0, kMinTapTarget / 2);
}

Future<void> _tapHandle(WidgetTester tester) async {
  await tester.tapAt(_handleCenter(tester));
  await tester.pumpAndSettle();
}

/// Drags from [start] by [total] in [steps] equal moves, one frame each.
Future<void> _slowDrag(WidgetTester tester, Offset start, double total, int steps) async {
  final TestGesture gesture = await tester.startGesture(start);
  for (int i = 0; i < steps; i++) {
    await gesture.moveBy(Offset(0, total / steps));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  group("SnapBottomSheetController", () {
    test("starts at mid by default and at the given snap otherwise", () {
      expect(_controller().snap, SheetSnap.mid);
      expect(_controller(SheetSnap.full).snap, SheetSnap.full);
    });

    test("setSnap notifies on change only", () {
      final SnapBottomSheetController controller = _controller();
      final ValueGetter<int> count = _countNotifications(controller);

      controller.setSnap(SheetSnap.mid);
      expect(count(), 0);
      controller.setSnap(SheetSnap.full);
      expect(count(), 1);
      expect(controller.snap, SheetSnap.full);
    });

    test("stepDown goes full → mid → collapsed, then returns false", () {
      final SnapBottomSheetController controller = _controller(SheetSnap.full);

      expect(controller.stepDown(), isTrue);
      expect(controller.snap, SheetSnap.mid);
      expect(controller.stepDown(), isTrue);
      expect(controller.snap, SheetSnap.collapsed);
      expect(controller.stepDown(), isFalse);
      expect(controller.snap, SheetSnap.collapsed);
    });
  });

  group("layout", () {
    testWidgets("renders the header and a body attached to the sheet's scroll controller", (
      WidgetTester tester,
    ) async {
      ScrollController? received;
      await _pump(
        tester,
        _controller(),
        header: const Text("Header"),
        builder: (BuildContext context, ScrollController scrollController) {
          received = scrollController;
          return _list(context, scrollController);
        },
      );

      expect(find.text("Header"), findsOneWidget);
      expect(find.text("Item 0"), findsOneWidget);
      expect(received?.hasClients, isTrue);
      // The header sits right below the 48 dp handle.
      expect(tester.getTopLeft(find.text("Header")).dy, tester.getRect(_sheetBox()).top + kMinTapTarget);
    });

    for (final (SheetSnap snap, double height) in <(SheetSnap, double)>[
      (SheetSnap.collapsed, _collapsedHeight),
      (SheetSnap.mid, _midHeight),
      (SheetSnap.full, _fullHeight),
    ]) {
      testWidgets("starts at the controller's height (${snap.name})", (WidgetTester tester) async {
        await _pump(tester, _controller(snap));

        expect(_sheetHeight(tester), moreOrLessEquals(height));
        expect(tester.getRect(_sheetBox()).bottom, _parentHeight);
      });
    }

    testWidgets("taps above the sheet reach the background", (WidgetTester tester) async {
      int backgroundTaps = 0;
      await pumpApp(
        tester,
        Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => backgroundTaps++,
              ),
            ),
            SnapBottomSheet(controller: _controller(), builder: _list),
          ],
        ),
        surfaceSize: _surface,
      );
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(180, 100));
      expect(backgroundTaps, 1);
      await tester.tap(find.text("Item 0"));
      expect(backgroundTaps, 1);
    });

    for (final double height in <double>[640, 667, 800]) {
      testWidgets("the default collapsed height shows a one-line header in full (${height.toInt()} dp)", (
        WidgetTester tester,
      ) async {
        final SnapBottomSheetController controller = _controller(SheetSnap.collapsed);
        final ValueGetter<int> count = _countNotifications(controller);
        await _pump(
          tester,
          controller,
          surface: Size(360, height),
          header: const SizedBox(height: 32, child: Text("Header")),
        );

        final Rect sheet = tester.getRect(_sheetBox());
        final Rect header = tester.getRect(find.text("Header"));
        expect(header.top, greaterThanOrEqualTo(sheet.top));
        expect(header.bottom, lessThanOrEqualTo(sheet.bottom + 1e-6));
        // Handle (48) + header (32), or the default fraction when larger.
        expect(sheet.height, moreOrLessEquals(height * 0.09 > 80 ? height * 0.09 : 80));
        expect(controller.snap, SheetSnap.collapsed);
        expect(count(), 0);
      });
    }

    testWidgets("the collapsed height follows the header, and a grip drag stops there", (
      WidgetTester tester,
    ) async {
      final SnapBottomSheetController controller = _controller(SheetSnap.collapsed);
      await _pump(
        tester,
        controller,
        header: const SizedBox(height: kMinTapTarget, child: Text("Header")),
      );
      // Handle (48) + header (48) is above the default 0.09 × 800 = 72 dp.
      expect(_sheetHeight(tester), moreOrLessEquals(2 * kMinTapTarget));

      controller.setSnap(SheetSnap.mid);
      await tester.pumpAndSettle();
      await tester.dragFrom(_handleCenter(tester), const Offset(0, 700));
      await tester.pumpAndSettle();
      expect(controller.snap, SheetSnap.collapsed);
      expect(_sheetHeight(tester), moreOrLessEquals(2 * kMinTapTarget));
    });

    testWidgets("a header that grows after a move raises the collapsed height without notifying", (
      WidgetTester tester,
    ) async {
      final SnapBottomSheetController controller = _controller();
      double headerHeight = 32;
      late StateSetter setHostState;
      await pumpApp(
        tester,
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            setHostState = setState;
            // The host rebuilds whenever the controller notifies.
            return ListenableBuilder(
              listenable: controller,
              builder: (BuildContext context, Widget? child) {
                return SnapBottomSheet(
                  controller: controller,
                  collapsedFraction: 0.05,
                  header: SizedBox(height: headerHeight, child: const Text("Header")),
                  builder: _list,
                );
              },
            );
          },
        ),
        surfaceSize: _surface,
      );
      await tester.pumpAndSettle();
      controller.setSnap(SheetSnap.collapsed);
      await tester.pumpAndSettle();
      expect(_sheetHeight(tester), moreOrLessEquals(kMinTapTarget + 32));
      final ValueGetter<int> count = _countNotifications(controller);

      setHostState(() => headerHeight = 64);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_sheetHeight(tester), moreOrLessEquals(kMinTapTarget + 64));
      expect(controller.snap, SheetSnap.collapsed);
      expect(count(), 0);
    });

    testWidgets("a grip taller than half-way to mid is clipped without overflowing", (WidgetTester tester) async {
      await _pump(
        tester,
        _controller(SheetSnap.collapsed),
        header: const SizedBox(height: 400, child: Text("Header")),
      );

      expect(tester.takeException(), isNull);
      // Capped at half-way between collapsed (0.09) and mid (0.45).
      expect(_sheetHeight(tester), moreOrLessEquals(0.27 * _parentHeight));
    });
  });

  group("moves from code", () {
    testWidgets("setSnap animates over 320 ms to each height", (WidgetTester tester) async {
      final SnapBottomSheetController controller = _controller();
      await _pump(tester, controller);

      controller.setSnap(SheetSnap.full);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      expect(_sheetHeight(tester), inExclusiveRange(_midHeight, _fullHeight));
      await tester.pump(const Duration(milliseconds: 170));
      expect(_sheetHeight(tester), moreOrLessEquals(_fullHeight));

      controller.setSnap(SheetSnap.collapsed);
      await tester.pumpAndSettle();
      expect(_sheetHeight(tester), moreOrLessEquals(_collapsedHeight));
    });

    testWidgets("a move past another height notifies once", (WidgetTester tester) async {
      final SnapBottomSheetController controller = _controller(SheetSnap.full);
      await _pump(tester, controller);
      final ValueGetter<int> count = _countNotifications(controller);

      // Frame time (µs) at which the 320 ms easeOutCubic move full → collapsed
      // is closest to mid, computed like the animation does (Cubic.transform
      // is approximate, so the closest integer microsecond is searched).
      double sizeAt(int microseconds) {
        final double t = (microseconds / 1e6) / (320000 / 1e6);
        return 0.95 + (0.09 - 0.95) * Curves.easeOutCubic.transform(t);
      }

      int atMid = 0;
      for (int us = 0; us <= 320000; us++) {
        if ((sizeAt(us) - 0.45).abs() < (sizeAt(atMid) - 0.45).abs()) atMid = us;
      }
      // Within the snap tolerance, so the sheet passes "at" mid on that frame.
      expect(sizeAt(atMid), moreOrLessEquals(0.45, epsilon: SnapBottomSheetStops.tolerance));

      controller.setSnap(SheetSnap.collapsed);
      await tester.pump();
      await tester.pump(Duration(microseconds: atMid));
      expect(
        _sheetHeight(tester),
        moreOrLessEquals(_midHeight, epsilon: SnapBottomSheetStops.tolerance * _parentHeight),
      );
      expect(controller.snap, SheetSnap.collapsed);

      await tester.pumpAndSettle();
      expect(count(), 1);
      expect(controller.snap, SheetSnap.collapsed);
      expect(_sheetHeight(tester), moreOrLessEquals(_collapsedHeight));
    });

    testWidgets("stepDown moves the sheet one height down", (WidgetTester tester) async {
      final SnapBottomSheetController controller = _controller(SheetSnap.full);
      await _pump(tester, controller);

      expect(controller.stepDown(), isTrue);
      await tester.pumpAndSettle();
      expect(_sheetHeight(tester), moreOrLessEquals(_midHeight));

      expect(controller.stepDown(), isTrue);
      await tester.pumpAndSettle();
      expect(_sheetHeight(tester), moreOrLessEquals(_collapsedHeight));

      expect(controller.stepDown(), isFalse);
      await tester.pumpAndSettle();
      expect(_sheetHeight(tester), moreOrLessEquals(_collapsedHeight));
    });
  });

  group("handle", () {
    testWidgets("a tap cycles collapsed → mid → full → collapsed", (WidgetTester tester) async {
      final SnapBottomSheetController controller = _controller(SheetSnap.collapsed);
      await _pump(tester, controller);

      await _tapHandle(tester);
      expect(controller.snap, SheetSnap.mid);
      expect(_sheetHeight(tester), moreOrLessEquals(_midHeight));

      await _tapHandle(tester);
      expect(controller.snap, SheetSnap.full);
      expect(_sheetHeight(tester), moreOrLessEquals(_fullHeight));

      await _tapHandle(tester);
      expect(controller.snap, SheetSnap.collapsed);
      expect(_sheetHeight(tester), moreOrLessEquals(_collapsedHeight));
    });

    testWidgets("is a focusable 48 dp button with a label and an expand / collapse hint", (WidgetTester tester) async {
      // testWidgets enables semantics (semanticsEnabled defaults to true) and
      // disposes that handle itself, also when an expectation fails.
      final SnapBottomSheetController controller = _controller();
      await _pump(tester, controller);

      final Finder handle = find.bySemanticsLabel(_handleKey);
      expect(handle, findsOneWidget);
      expect(tester.getSize(handle).height, greaterThanOrEqualTo(kMinTapTarget));
      expect(
        tester.getSemantics(handle),
        matchesSemantics(
          label: _handleKey,
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          onTapHint: _expandKey,
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

      controller.setSnap(SheetSnap.full);
      await tester.pumpAndSettle();
      expect(tester.getSemantics(handle), matchesSemantics(
        label: _handleKey,
        isButton: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
        onTapHint: _collapseKey,
      ));
    });

    testWidgets("takes keyboard focus, and Enter / Space cycle the height", (WidgetTester tester) async {
      final SnapBottomSheetController controller = _controller(SheetSnap.collapsed);
      await _pump(tester, controller);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final BuildContext? focused = FocusManager.instance.primaryFocus?.context;
      expect(focused, isNotNull);
      expect(
        find.ancestor(of: find.byWidget(focused!.widget), matching: find.bySemanticsLabel(_handleKey)),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(controller.snap, SheetSnap.mid);
      expect(_sheetHeight(tester), moreOrLessEquals(_midHeight));

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(controller.snap, SheetSnap.full);
      expect(_sheetHeight(tester), moreOrLessEquals(_fullHeight));
    });
  });

  group("grip drags", () {
    testWidgets("dragging the handle settles on the nearest height and updates the controller", (
      WidgetTester tester,
    ) async {
      final SnapBottomSheetController controller = _controller();
      await _pump(tester, controller);

      await tester.dragFrom(_handleCenter(tester), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(controller.snap, SheetSnap.collapsed);
      expect(_sheetHeight(tester), moreOrLessEquals(_collapsedHeight));

      await tester.dragFrom(_handleCenter(tester), const Offset(0, -620));
      await tester.pumpAndSettle();
      expect(controller.snap, SheetSnap.full);
      expect(_sheetHeight(tester), moreOrLessEquals(_fullHeight));
    });

    testWidgets("a short drag returns to the starting height", (WidgetTester tester) async {
      final SnapBottomSheetController controller = _controller();
      await _pump(tester, controller);
      final ValueGetter<int> count = _countNotifications(controller);

      await _slowDrag(tester, _handleCenter(tester), -80, 8);

      expect(controller.snap, SheetSnap.mid);
      expect(count(), 0);
      expect(_sheetHeight(tester), moreOrLessEquals(_midHeight));
    });

    testWidgets("a fling settles on the next height in its direction", (WidgetTester tester) async {
      final SnapBottomSheetController controller = _controller(SheetSnap.collapsed);
      await _pump(tester, controller);

      await tester.flingFrom(_handleCenter(tester), const Offset(0, -60), 1000);
      await tester.pumpAndSettle();

      expect(controller.snap, SheetSnap.mid);
      expect(_sheetHeight(tester), moreOrLessEquals(_midHeight));
    });

    testWidgets("dragging the header moves the sheet too", (WidgetTester tester) async {
      final SnapBottomSheetController controller = _controller();
      await _pump(tester, controller, header: const SizedBox(height: kMinTapTarget, child: Text("Header")));

      await tester.drag(find.text("Header"), const Offset(0, -320));
      await tester.pumpAndSettle();

      expect(controller.snap, SheetSnap.full);
      expect(_sheetHeight(tester), moreOrLessEquals(_fullHeight));
    });

    testWidgets("a slow drag past mid notifies once, with the resting height", (WidgetTester tester) async {
      final SnapBottomSheetController controller = _controller(SheetSnap.full);
      await _pump(tester, controller);
      final ValueGetter<int> count = _countNotifications(controller);

      await _slowDrag(tester, _handleCenter(tester), 700, 70);

      expect(count(), 1);
      expect(controller.snap, SheetSnap.collapsed);
      expect(_sheetHeight(tester), moreOrLessEquals(_collapsedHeight));
    });
  });

  group("body drags", () {
    testWidgets("dragging the list up from mid settles at full and updates the controller", (
      WidgetTester tester,
    ) async {
      final SnapBottomSheetController controller = _controller();
      await _pump(tester, controller);

      await tester.drag(find.text("Item 1"), const Offset(0, -320));
      await tester.pumpAndSettle();

      expect(_sheetHeight(tester), moreOrLessEquals(_fullHeight));
      expect(controller.snap, SheetSnap.full);
    });

    testWidgets("dragging the list down from full settles at mid, then stepDown collapses", (
      WidgetTester tester,
    ) async {
      final SnapBottomSheetController controller = _controller(SheetSnap.full);
      await _pump(tester, controller);

      await tester.drag(find.text("Item 1"), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(_sheetHeight(tester), moreOrLessEquals(_midHeight));
      expect(controller.snap, SheetSnap.mid);

      expect(controller.stepDown(), isTrue);
      await tester.pumpAndSettle();
      expect(_sheetHeight(tester), moreOrLessEquals(_collapsedHeight));
    });

    testWidgets("a slow list drag past mid notifies once, with the resting height", (WidgetTester tester) async {
      final SnapBottomSheetController controller = _controller(SheetSnap.full);
      await _pump(tester, controller);
      final ValueGetter<int> count = _countNotifications(controller);

      await _slowDrag(tester, tester.getCenter(find.text("Item 1")), 700, 70);

      expect(count(), 1);
      expect(controller.snap, SheetSnap.collapsed);
      expect(_sheetHeight(tester), moreOrLessEquals(_collapsedHeight));
    });

    testWidgets("a drag interrupting a move from code writes back where the sheet rests", (
      WidgetTester tester,
    ) async {
      final SnapBottomSheetController controller = _controller();
      await _pump(tester, controller);

      controller.setSnap(SheetSnap.full);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.drag(find.text("Item 1"), const Offset(0, 600));
      await tester.pumpAndSettle();

      expect(_sheetHeight(tester), moreOrLessEquals(_collapsedHeight));
      expect(controller.snap, SheetSnap.collapsed);
    });

    testWidgets("a host rebuild during a list drag keeps the sheet under the finger", (WidgetTester tester) async {
      final SnapBottomSheetController controller = _controller();
      late StateSetter setHostState;
      await pumpApp(
        tester,
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            setHostState = setState;
            return SnapBottomSheet(controller: controller, builder: _list);
          },
        ),
        surfaceSize: _surface,
      );
      await tester.pumpAndSettle();

      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text("Item 1")));
      await gesture.moveBy(const Offset(0, -40));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(milliseconds: 16));
      final double before = _sheetHeight(tester);
      expect(before, greaterThan(_midHeight));

      setHostState(() {});
      await tester.pump(const Duration(milliseconds: 16));
      for (int i = 0; i < 4; i++) {
        await gesture.moveBy(const Offset(0, -20));
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(_sheetHeight(tester), moreOrLessEquals(before + 80));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.snap, SheetSnap.mid);
    });
  });

  group("reduced motion", () {
    testWidgets("a move from code jumps within one frame", (WidgetTester tester) async {
      final SnapBottomSheetController controller = _controller();
      await _pump(tester, controller, reduceMotion: true);

      controller.setSnap(SheetSnap.full);
      await tester.pump();

      expect(_sheetHeight(tester), moreOrLessEquals(_fullHeight));
    });

    testWidgets("a list fling snaps without an assertion", (WidgetTester tester) async {
      final SnapBottomSheetController controller = _controller();
      await _pump(tester, controller, reduceMotion: true);

      await tester.fling(find.text("Item 1"), const Offset(0, -200), 2000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_sheetHeight(tester), moreOrLessEquals(_fullHeight));
      expect(controller.snap, SheetSnap.full);
    });

    testWidgets("a move from code during a list fling notifies once", (WidgetTester tester) async {
      final SnapBottomSheetController controller = _controller(SheetSnap.full);
      late ScrollController scroll;
      await _pump(
        tester,
        controller,
        reduceMotion: true,
        builder: (BuildContext context, ScrollController scrollController) {
          scroll = scrollController;
          return _list(context, scrollController);
        },
      );
      final List<SheetSnap> seen = <SheetSnap>[];
      controller.addListener(() => seen.add(controller.snap));

      await tester.fling(find.text("Item 1"), const Offset(0, -200), 2000);
      await tester.pump();
      expect(scroll.position.isScrollingNotifier.value, isTrue);

      controller.setSnap(SheetSnap.collapsed);
      await tester.pumpAndSettle();

      expect(seen, <SheetSnap>[SheetSnap.collapsed]);
      expect(_sheetHeight(tester), moreOrLessEquals(_collapsedHeight));
    });
  });

  group("body attached late", () {
    /// A body that shows a placeholder until [loaded] is true, then the list.
    Widget Function(BuildContext context, ScrollController scrollController) lateList(ValueNotifier<bool> loaded) {
      return (BuildContext context, ScrollController scrollController) {
        return ValueListenableBuilder<bool>(
          valueListenable: loaded,
          builder: (BuildContext context, bool isLoaded, Widget? child) {
            return isLoaded ? _list(context, scrollController) : const Center(child: Text("Placeholder"));
          },
        );
      };
    }

    ValueNotifier<bool> loadedNotifier(bool initial) {
      final ValueNotifier<bool> loaded = ValueNotifier<bool>(initial);
      addTearDown(loaded.dispose);
      return loaded;
    }

    testWidgets("a move requested before the list attaches is applied once it does", (WidgetTester tester) async {
      final SnapBottomSheetController controller = _controller();
      final ValueNotifier<bool> loaded = loadedNotifier(false);
      await _pump(tester, controller, builder: lateList(loaded));
      final ValueGetter<int> count = _countNotifications(controller);

      controller.setSnap(SheetSnap.full);
      await tester.pumpAndSettle();
      // Nothing to drive the sheet yet.
      expect(_sheetHeight(tester), moreOrLessEquals(_midHeight));

      loaded.value = true;
      await tester.pumpAndSettle();
      expect(_sheetHeight(tester), moreOrLessEquals(_fullHeight));
      expect(controller.snap, SheetSnap.full);
      expect(count(), 1);

      expect(controller.stepDown(), isTrue);
      await tester.pumpAndSettle();
      expect(_sheetHeight(tester), moreOrLessEquals(_midHeight));
      expect(controller.snap, SheetSnap.mid);
    });

    testWidgets("handle taps before the list attaches are applied once it does", (WidgetTester tester) async {
      final SnapBottomSheetController controller = _controller(SheetSnap.collapsed);
      final ValueNotifier<bool> loaded = loadedNotifier(false);
      await _pump(tester, controller, builder: lateList(loaded));

      await _tapHandle(tester);
      await _tapHandle(tester);
      expect(controller.snap, SheetSnap.full);

      loaded.value = true;
      await tester.pumpAndSettle();
      expect(_sheetHeight(tester), moreOrLessEquals(_fullHeight));
    });

    testWidgets("a move cut short by a rebuilt list resumes on the new list", (WidgetTester tester) async {
      final SnapBottomSheetController controller = _controller();
      final ValueNotifier<bool> loaded = loadedNotifier(true);
      await _pump(tester, controller, builder: lateList(loaded));

      controller.setSnap(SheetSnap.full);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Detaching the list stops the move part-way.
      loaded.value = false;
      await tester.pumpAndSettle();
      expect(_sheetHeight(tester), inExclusiveRange(_midHeight, _fullHeight));

      loaded.value = true;
      await tester.pumpAndSettle();
      expect(_sheetHeight(tester), moreOrLessEquals(_fullHeight));
      expect(controller.snap, SheetSnap.full);
    });

    testWidgets("a list rebuilt during a grip drag leaves the sheet under the finger", (WidgetTester tester) async {
      final SnapBottomSheetController controller = _controller();
      final ValueNotifier<int> listKey = ValueNotifier<int>(0);
      addTearDown(listKey.dispose);
      await _pump(
        tester,
        controller,
        builder: (BuildContext context, ScrollController scrollController) {
          return ValueListenableBuilder<int>(
            valueListenable: listKey,
            builder: (BuildContext context, int key, Widget? child) {
              return KeyedSubtree(key: ValueKey<int>(key), child: _list(context, scrollController));
            },
          );
        },
      );

      final TestGesture gesture = await tester.startGesture(_handleCenter(tester));
      await gesture.moveBy(const Offset(0, -40));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveBy(const Offset(0, -40));
      await tester.pump(const Duration(milliseconds: 16));
      final double before = _sheetHeight(tester);
      expect(before, greaterThan(_midHeight));

      listKey.value = 1;
      // Rebuild, then enough frames for a (wrong) move to show.
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(_sheetHeight(tester), moreOrLessEquals(before));

      await gesture.moveBy(const Offset(0, -40));
      await tester.pump(const Duration(milliseconds: 16));
      expect(_sheetHeight(tester), moreOrLessEquals(before + 40));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.snap, SheetSnap.mid);
      expect(_sheetHeight(tester), moreOrLessEquals(_midHeight));
    });
  });

  group("controller swap", () {
    testWidgets("listens to the new controller only and moves to its height", (WidgetTester tester) async {
      final SnapBottomSheetController first = _controller();
      final SnapBottomSheetController second = _controller(SheetSnap.collapsed);
      late StateSetter setHostState;
      SnapBottomSheetController current = first;
      await pumpApp(
        tester,
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            setHostState = setState;
            return SnapBottomSheet(controller: current, builder: _list);
          },
        ),
        surfaceSize: _surface,
      );
      await tester.pumpAndSettle();
      // Move first, so the sheet no longer sits at its initial height.
      first.setSnap(SheetSnap.full);
      await tester.pumpAndSettle();
      expect(_sheetHeight(tester), moreOrLessEquals(_fullHeight));

      setHostState(() => current = second);
      await tester.pumpAndSettle();
      expect(_sheetHeight(tester), moreOrLessEquals(_collapsedHeight));
      // ignore: invalid_use_of_protected_member
      expect(first.hasListeners, isFalse);

      first.setSnap(SheetSnap.mid);
      await tester.pumpAndSettle();
      expect(_sheetHeight(tester), moreOrLessEquals(_collapsedHeight));

      second.setSnap(SheetSnap.full);
      await tester.pumpAndSettle();
      expect(_sheetHeight(tester), moreOrLessEquals(_fullHeight));

      await tester.pumpWidget(const SizedBox.shrink());
      // ignore: invalid_use_of_protected_member
      expect(second.hasListeners, isFalse);
    });
  });

  group("fraction change", () {
    testWidgets("keeps the controller's height, without notifying a listening host", (WidgetTester tester) async {
      final SnapBottomSheetController controller = _controller(SheetSnap.full);
      double mid = 0.45;
      double full = 0.95;
      late StateSetter setHostState;
      await pumpApp(
        tester,
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            setHostState = setState;
            // The host rebuilds whenever the controller notifies.
            return ListenableBuilder(
              listenable: controller,
              builder: (BuildContext context, Widget? child) {
                return SnapBottomSheet(
                  controller: controller,
                  midFraction: mid,
                  fullFraction: full,
                  builder: _list,
                );
              },
            );
          },
        ),
        surfaceSize: _surface,
      );
      await tester.pumpAndSettle();
      controller.setSnap(SheetSnap.mid);
      await tester.pumpAndSettle();
      final ValueGetter<int> count = _countNotifications(controller);

      // The current height (0.45) is above the new full height: clamped.
      setHostState(() {
        mid = 0.3;
        full = 0.4;
      });
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(count(), 0);
      expect(controller.snap, SheetSnap.mid);
      expect(_sheetHeight(tester), moreOrLessEquals(0.3 * _parentHeight));

      controller.setSnap(SheetSnap.full);
      await tester.pumpAndSettle();
      expect(_sheetHeight(tester), moreOrLessEquals(0.4 * _parentHeight));
    });
  });

  group("theme", () {
    for (final (String name, ThemeData theme) in <(String, ThemeData)>[
      ("light", AppTheme.light()),
      ("dark", AppTheme.dark()),
    ]) {
      testWidgets("uses ColorScheme tokens ($name)", (WidgetTester tester) async {
        await _pump(tester, _controller(), theme: theme);
        final ColorScheme cs = theme.colorScheme;

        final BoxDecoration sheet = tester.widget<DecoratedBox>(_sheetBox()).decoration as BoxDecoration;
        expect(sheet.color, cs.surfaceContainerLow);
        expect(sheet.boxShadow?.single.color, cs.shadow.withValues(alpha: 0.08));

        final Finder pill = find.descendant(
          of: find.byType(SnapBottomSheet),
          matching: find.byWidgetPredicate(
            (Widget widget) =>
                widget is DecoratedBox &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).color == cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        );
        expect(pill, findsOneWidget);
        expect(tester.getSize(pill), const Size(40, 4));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group("asserts", () {
    test("rejects unordered or out-of-range fractions", () {
      final SnapBottomSheetController controller = _controller();

      expect(
        () => SnapBottomSheet(controller: controller, builder: _list, midFraction: 0.05),
        throwsAssertionError,
      );
      expect(
        () => SnapBottomSheet(controller: controller, builder: _list, fullFraction: 1.2),
        throwsAssertionError,
      );
      expect(
        () => SnapBottomSheet(controller: controller, builder: _list, collapsedFraction: 0),
        throwsAssertionError,
      );
      expect(
        () => SnapBottomSheet(controller: controller, builder: _list, midFraction: 0.95),
        throwsAssertionError,
      );
    });
  });
}

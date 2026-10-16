// polygon_editor_panel_test.dart
//
// Widget tests for PolygonEditorPanel (lib/widgets/custom/PolygonEditorPanel/):
// empty state and hint, label overrides, button enabled states, undo / reset,
// tap to add (also under the hint), the save lifecycle (success, failure,
// re-entrancy, unmount while pending), initialPoints read once, 48 dp
// targets, a long save label at phone width with large text, and light /
// dark theming. Tiles come from an in-memory
// TileProvider, so no network is used.

import "dart:async";
import "dart:typed_data";

import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";
import "package:flutter_skeleton/widgets/custom/MapPolygonEditor/index.dart";
import "package:flutter_skeleton/widgets/custom/PolygonEditorPanel/index.dart";
import "package:flutter_test/flutter_test.dart";
import "package:latlong2/latlong.dart";

import "../../helpers/widget_test_helpers.dart";

const String _kHintKey = "custom.polygon_editor_panel.hint";
const String _kResetKey = "custom.polygon_editor_panel.reset";
const String _kUndoKey = "custom.polygon_editor_panel.undo";
const String _kSaveKey = "custom.polygon_editor_panel.save";

/// Wide enough for the raw i18n keys that `.tr()` returns in tests (the test
/// font draws every glyph as wide as the font size).
const Size _kPanelSize = Size(1800, 800);
const Size _kSurfaceSize = Size(1800, 900);

/// Phone width. The heights leave room for the raw Reset / Undo keys, which
/// wrap to many more lines in the test font than real labels do.
const double _kPhoneWidth = 360;

/// A save label far wider than half of a phone-width bar.
const String _kLongSaveLabel = "Save and continue";

/// Longer than flutter_map's 250 ms double-tap window, so a tap resolves.
const Duration _kTapSettle = Duration(milliseconds: 400);

/// 1×1 transparent PNG.
final Uint8List _kTransparentPng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

/// Serves every tile from memory (no network).
final class _MemoryTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(_kTransparentPng);
  }
}

/// Three vertices around the origin.
const List<LatLng> _kTriangle = <LatLng>[
  LatLng(10, -10),
  LatLng(10, 10),
  LatLng(-10, 0),
];

/// Records the panel's callbacks.
final class _Calls {
  final List<List<LatLng>> saved = <List<LatLng>>[];
  final List<Object> errors = <Object>[];
  int onSavedCount = 0;
}

TileLayer _tileLayer() {
  return TileLayer(
    urlTemplate: "https://tiles.example.test/{z}/{x}/{y}.png",
    userAgentPackageName: "com.example.test",
    tileProvider: _MemoryTileProvider(),
  );
}

Widget _panel({
  required _Calls calls,
  Key? key,
  List<LatLng>? initialPoints,
  Future<void> Function(List<LatLng> points)? onSave,
  String? hint,
  String? saveLabel,
  Size size = _kPanelSize,
}) {
  return Center(
    child: SizedBox.fromSize(
      size: size,
      child: PolygonEditorPanel(
        key: key,
        tileLayer: _tileLayer(),
        initialPoints: initialPoints,
        hint: hint,
        saveLabel: saveLabel,
        onSave:
            onSave ??
            (List<LatLng> points) async {
              calls.saved.add(points);
            },
        onSaved: () => calls.onSavedCount++,
        onSaveError: calls.errors.add,
      ),
    ),
  );
}

/// Pumps [panel] and lets the map become ready (post-frame callback).
Future<void> _pump(
  WidgetTester tester,
  Widget panel, {
  ThemeData? theme,
  Size surfaceSize = _kSurfaceSize,
}) async {
  await pumpApp(tester, panel, theme: theme, surfaceSize: surfaceSize);
  await tester.pump();
  await tester.pump();
}

ButtonStyleButton _tool(WidgetTester tester, String label) {
  return tester.widget<ButtonStyleButton>(
    find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate(
        (Widget widget) => widget is ButtonStyleButton,
      ),
    ),
  );
}

bool _enabled(WidgetTester tester, String label) {
  return _tool(tester, label).onPressed != null;
}

FilledButton _saveButton(WidgetTester tester) {
  return tester.widget<FilledButton>(find.byType(FilledButton));
}

Rect _mapRect(WidgetTester tester) {
  return tester.getRect(find.byType(MapPolygonEditor));
}

void main() {
  group("PolygonEditorPanel", () {
    testWidgets("empty: shows the hint and disables every action", (
      WidgetTester tester,
    ) async {
      await _pump(tester, _panel(calls: _Calls()));

      expect(find.text(_kHintKey), findsOneWidget);
      expect(find.text(_kResetKey), findsOneWidget);
      expect(find.text(_kUndoKey), findsOneWidget);
      expect(find.text(_kSaveKey), findsOneWidget);
      expect(_enabled(tester, _kResetKey), isFalse);
      expect(_enabled(tester, _kUndoKey), isFalse);
      expect(_saveButton(tester).onPressed, isNull);
      expect(find.byType(Loader), findsNothing);
    });

    testWidgets("hint and saveLabel replace the default strings", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _panel(calls: _Calls(), hint: "Draw it", saveLabel: "Confirm"),
      );

      expect(find.text("Draw it"), findsOneWidget);
      expect(find.text("Confirm"), findsOneWidget);
      expect(find.text(_kHintKey), findsNothing);
      expect(find.text(_kSaveKey), findsNothing);
    });

    testWidgets("3 initial points: no hint, every action enabled", (
      WidgetTester tester,
    ) async {
      await _pump(tester, _panel(calls: _Calls(), initialPoints: _kTriangle));

      expect(find.text(_kHintKey), findsNothing);
      expect(_enabled(tester, _kResetKey), isTrue);
      expect(_enabled(tester, _kUndoKey), isTrue);
      expect(_saveButton(tester).onPressed, isNotNull);
    });

    testWidgets("2 points: save disabled; undo then reset empty the map", (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        _panel(calls: _Calls(), initialPoints: _kTriangle.sublist(0, 2)),
      );

      expect(_enabled(tester, _kUndoKey), isTrue);
      expect(_enabled(tester, _kResetKey), isTrue);
      expect(_saveButton(tester).onPressed, isNull);

      await tester.tap(find.text(_kUndoKey));
      await tester.pump();
      expect(find.text(_kHintKey), findsNothing);
      expect(_enabled(tester, _kUndoKey), isTrue);
      expect(_saveButton(tester).onPressed, isNull);

      await tester.tap(find.text(_kResetKey));
      await tester.pump();
      expect(find.text(_kHintKey), findsOneWidget);
      expect(_enabled(tester, _kResetKey), isFalse);
      expect(_enabled(tester, _kUndoKey), isFalse);
      expect(_saveButton(tester).onPressed, isNull);
    });

    testWidgets("undo removes the last vertex only", (
      WidgetTester tester,
    ) async {
      final _Calls calls = _Calls();
      await _pump(
        tester,
        _panel(
          calls: calls,
          initialPoints: <LatLng>[..._kTriangle, const LatLng(-10, -20)],
        ),
      );

      await tester.tap(find.text(_kUndoKey));
      await tester.pump();
      await tester.tap(find.text(_kSaveKey));
      await tester.pump();

      expect(calls.saved, <List<LatLng>>[_kTriangle]);
    });

    testWidgets("tapping the map adds vertices, also under the hint", (
      WidgetTester tester,
    ) async {
      await _pump(tester, _panel(calls: _Calls()));
      final Offset center = _mapRect(tester).center;

      // First tap right on the hint pill: it must reach the map.
      await tester.tapAt(tester.getCenter(find.text(_kHintKey)));
      await tester.pump(_kTapSettle);
      expect(find.text(_kHintKey), findsNothing);
      expect(_enabled(tester, _kUndoKey), isTrue);
      expect(_saveButton(tester).onPressed, isNull);

      await tester.tapAt(center + const Offset(-120, 60));
      await tester.pump(_kTapSettle);
      expect(_saveButton(tester).onPressed, isNull);

      await tester.tapAt(center + const Offset(120, 60));
      await tester.pump(_kTapSettle);
      expect(_saveButton(tester).onPressed, isNotNull);
    });

    testWidgets("save success: Loader while pending, then onSaved", (
      WidgetTester tester,
    ) async {
      final _Calls calls = _Calls();
      final Completer<void> completer = Completer<void>();
      final List<List<LatLng>> received = <List<LatLng>>[];
      await _pump(
        tester,
        _panel(
          calls: calls,
          initialPoints: _kTriangle,
          onSave: (List<LatLng> points) {
            received.add(points);
            return completer.future;
          },
        ),
      );

      await tester.tap(find.text(_kSaveKey));
      await tester.pump();

      expect(find.byType(Loader), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(received, <List<LatLng>>[_kTriangle]);
      expect(
        () => received.single.add(const LatLng(0, 0)),
        throwsUnsupportedError,
      );
      expect(calls.onSavedCount, 0);

      completer.complete();
      await tester.pump();

      expect(calls.onSavedCount, 1);
      expect(calls.errors, isEmpty);
      expect(find.byType(Loader), findsNothing);
      expect(_saveButton(tester).onPressed, isNotNull);
    });

    testWidgets("save failure: onSaveError gets the error, button returns", (
      WidgetTester tester,
    ) async {
      final _Calls calls = _Calls();
      final StateError error = StateError("x");
      await _pump(
        tester,
        _panel(
          calls: calls,
          initialPoints: _kTriangle,
          onSave: (List<LatLng> points) async {
            throw error;
          },
        ),
      );

      await tester.tap(find.text(_kSaveKey));
      await tester.pump();

      expect(calls.errors, hasLength(1));
      expect(calls.errors.single, same(error));
      expect(calls.onSavedCount, 0);
      expect(find.byType(Loader), findsNothing);
      expect(_saveButton(tester).onPressed, isNotNull);
    });

    testWidgets("a second save while one is pending is ignored", (
      WidgetTester tester,
    ) async {
      final _Calls calls = _Calls();
      final Completer<void> completer = Completer<void>();
      int saveCount = 0;
      await _pump(
        tester,
        _panel(
          calls: calls,
          initialPoints: _kTriangle,
          onSave: (List<LatLng> points) {
            saveCount++;
            return completer.future;
          },
        ),
      );
      final VoidCallback save = _saveButton(tester).onPressed!;

      save();
      await tester.pump();
      save();
      await tester.pump();
      expect(saveCount, 1);

      completer.complete();
      await tester.pump();
      expect(calls.onSavedCount, 1);
    });

    for (final bool fails in <bool>[false, true]) {
      testWidgets(
        "unmounted while pending (fails: $fails): no callback, no error",
        (WidgetTester tester) async {
          final _Calls calls = _Calls();
          final Completer<void> completer = Completer<void>();
          await _pump(
            tester,
            _panel(
              calls: calls,
              initialPoints: _kTriangle,
              onSave: (List<LatLng> points) => completer.future,
            ),
          );

          await tester.tap(find.text(_kSaveKey));
          await tester.pump();
          await pumpApp(tester, const SizedBox.shrink());

          if (fails) {
            completer.completeError(StateError("late"));
          } else {
            completer.complete();
          }
          await tester.pump();

          expect(tester.takeException(), isNull);
          expect(calls.onSavedCount, 0);
          expect(calls.errors, isEmpty);
        },
      );
    }

    testWidgets("initialPoints are read once; a new key reloads them", (
      WidgetTester tester,
    ) async {
      final _Calls calls = _Calls();
      const Key first = ValueKey<String>("first");
      await _pump(
        tester,
        _panel(
          calls: calls,
          key: first,
          initialPoints: _kTriangle.sublist(0, 2),
        ),
      );
      expect(_saveButton(tester).onPressed, isNull);

      await _pump(
        tester,
        _panel(calls: calls, key: first, initialPoints: _kTriangle),
      );
      expect(_saveButton(tester).onPressed, isNull);

      await _pump(
        tester,
        _panel(
          calls: calls,
          key: const ValueKey<String>("second"),
          initialPoints: _kTriangle,
        ),
      );
      expect(_saveButton(tester).onPressed, isNotNull);
    });

    for (final (int scale, double height) in <(int, double)>[
      (1, 640),
      (2, 1000),
    ]) {
      testWidgets(
        "phone width, ${scale}x text, long saveLabel: Save is capped at half "
        "the bar, nothing overflows",
        (WidgetTester tester) async {
          final Size size = Size(_kPhoneWidth, height);
          await _pump(
            tester,
            Builder(
              builder: (BuildContext context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale.toDouble())),
                child: _panel(
                  calls: _Calls(),
                  initialPoints: _kTriangle,
                  saveLabel: _kLongSaveLabel,
                  size: size,
                ),
              ),
            ),
            surfaceSize: size,
          );

          expect(tester.takeException(), isNull);
          // The whole label stays readable (it wraps, it is not cut).
          expect(find.text(_kLongSaveLabel), findsOneWidget);
          final Rect save = tester.getRect(find.byType(FilledButton));
          expect(save.width, lessThanOrEqualTo(_kPhoneWidth / 2));
          expect(save.right, lessThanOrEqualTo(_kPhoneWidth));
          for (final String label in <String>[_kResetKey, _kUndoKey]) {
            final Rect tool = tester.getRect(
              find.ancestor(
                of: find.text(label),
                matching: find.byType(TextButton),
              ),
            );
            expect(
              tool.width,
              greaterThanOrEqualTo(_kPhoneWidth / 2 - kDefaultPadding * 3),
            );
            expect(tool.right, lessThanOrEqualTo(save.left));
          }
          expect(
            tester.getRect(find.byType(MapPolygonEditor)).height,
            greaterThan(0),
          );
        },
      );
    }

    testWidgets("reset, undo, save and the Loader slot are 48 dp tall", (
      WidgetTester tester,
    ) async {
      final Completer<void> completer = Completer<void>();
      await _pump(
        tester,
        _panel(
          calls: _Calls(),
          initialPoints: _kTriangle,
          onSave: (List<LatLng> points) => completer.future,
        ),
      );

      for (final String label in <String>[_kResetKey, _kUndoKey]) {
        final Size size = tester.getSize(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(TextButton),
          ),
        );
        expect(size.height, greaterThanOrEqualTo(kMinTapTarget));
        expect(size.width, greaterThanOrEqualTo(kMinTapTarget));
      }
      final Size saveSize = tester.getSize(find.byType(FilledButton));
      expect(saveSize.height, greaterThanOrEqualTo(kMinTapTarget));
      expect(saveSize.width, greaterThanOrEqualTo(kMinTapTarget));

      await tester.tap(find.text(_kSaveKey));
      await tester.pump();
      final Size slot = tester.getSize(
        find
            .ancestor(of: find.byType(Loader), matching: find.byType(SizedBox))
            .first,
      );
      expect(slot.height, greaterThanOrEqualTo(kMinTapTarget));

      completer.complete();
      await tester.pump();
    });

    for (final (String name, ThemeData Function() theme)
        in <(String, ThemeData Function())>[
          ("light", AppTheme.light),
          ("dark", AppTheme.dark),
        ]) {
      testWidgets("$name theme: hint pill and action bar use scheme tokens", (
        WidgetTester tester,
      ) async {
        final ThemeData data = theme();
        await _pump(tester, _panel(calls: _Calls()), theme: data);

        expect(tester.takeException(), isNull);
        final ColorScheme cs = data.colorScheme;
        final DecoratedBox pill = tester.widget<DecoratedBox>(
          find
              .ancestor(
                of: find.text(_kHintKey),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect((pill.decoration as BoxDecoration).color, cs.inverseSurface);
        expect(
          tester.widget<Text>(find.text(_kHintKey)).style?.color,
          cs.onInverseSurface,
        );
        final DecoratedBox bar = tester.widget<DecoratedBox>(
          find
              .ancestor(
                of: find.text(_kResetKey),
                matching: find.byWidgetPredicate(
                  (Widget widget) =>
                      widget is DecoratedBox &&
                      widget.decoration is BoxDecoration &&
                      (widget.decoration as BoxDecoration).border != null,
                ),
              )
              .first,
        );
        final BoxDecoration barDecoration = bar.decoration as BoxDecoration;
        expect(barDecoration.color, cs.surface);
        expect((barDecoration.border! as Border).top.color, cs.outlineVariant);
      });
    }
  });
}

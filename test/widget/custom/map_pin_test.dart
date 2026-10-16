// map_pin_test.dart
//
// Widget tests for MapPin: box size and proportional wick geometry, default
// ColorScheme fill / outline / shadow, colour overrides, the optional shadow,
// image semantics (own node inside a labelled host), repaint scheduling when
// the look changes on the same element, the caller-driven drop squash
// (before, during and after the squash window, top edge anchored), reduced
// motion and the dark theme.

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/custom/MapPin/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

/// Drop progress at the squash peak: 4/7 + half of the 3/7 window.
const double _peak = 4 / 7 + 1.5 / 7;

Finder _inPin(Finder matching) {
  return find.descendant(of: find.byType(MapPin), matching: matching);
}

Finder get _paint => _inPin(find.byType(CustomPaint));

Finder get _transform => _inPin(find.byType(Transform));

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(MapPin))).colorScheme;

Color _shadow(ColorScheme cs) => cs.shadow.withValues(alpha: 0.12);

Color _outline(ColorScheme cs) => cs.onPrimary.withValues(alpha: 0.25);

Future<void> _pumpPin(WidgetTester tester, MapPin pin, {ThemeData? theme}) {
  return pumpApp(tester, Center(child: pin), theme: theme);
}

/// Pumps [pin] under a MediaQuery that asks to reduce motion.
Future<void> _pumpReducedMotion(WidgetTester tester, MapPin pin) {
  return pumpApp(
    tester,
    Builder(
      builder: (BuildContext context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: Center(child: pin),
      ),
    ),
  );
}

/// Pumps whatever MapPin [pin] holds, so a test can rebuild the same element
/// with new parameters by assigning `pin.value`.
Future<void> _pumpSwappable(WidgetTester tester, ValueNotifier<MapPin> pin) {
  return pumpApp(
    tester,
    Center(
      child: ValueListenableBuilder<MapPin>(
        valueListenable: pin,
        builder: (BuildContext context, MapPin value, Widget? child) => value,
      ),
    ),
  );
}

/// Rebuilds with [next] in place of the current pin, stops after the build
/// phase and reports whether the painter scheduled a repaint, then runs a
/// full frame (layout, paint, semantics) to finish the interrupted one.
Future<bool> _repaintsAfterSwap(WidgetTester tester, ValueNotifier<MapPin> pin, MapPin next) async {
  pin.value = next;
  await tester.pump(null, EnginePhase.build);
  final bool needsPaint = tester.renderObject<RenderCustomPaint>(_paint).debugNeedsPaint;
  tester.binding.scheduleFrame();
  await tester.pump();
  return needsPaint;
}

ValueNotifier<MapPin> _notifier(MapPin initial) {
  final ValueNotifier<MapPin> notifier = ValueNotifier<MapPin>(initial);
  addTearDown(notifier.dispose);
  return notifier;
}

Matrix4 _matrix(WidgetTester tester) => tester.widget<Transform>(_transform).transform;

AnimationController _controller(double value) {
  final AnimationController controller = AnimationController(vsync: const TestVSync(), value: value);
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  group("geometry", () {
    testWidgets("renders a 28 x 40 box by default", (WidgetTester tester) async {
      await _pumpPin(tester, const MapPin());

      expect(MapPin.defaultSize, const Size(28, 40));
      expect(tester.getSize(_paint), MapPin.defaultSize);
    });

    testWidgets("honours a custom size", (WidgetTester tester) async {
      await _pumpPin(tester, const MapPin(size: Size(42, 60)));

      expect(tester.getSize(_paint), const Size(42, 60));
    });

    testWidgets("head circle fills the width and the wick tip reaches the bottom centre",
        (WidgetTester tester) async {
      await _pumpPin(tester, const MapPin(showShadow: false));
      final ColorScheme cs = _scheme(tester);

      expect(
        _paint,
        paints
          ..circle(x: 14, y: 14, radius: 14, color: cs.primary, style: PaintingStyle.fill)
          ..circle(x: 14, y: 14, radius: 14)
          ..path(
            color: cs.primary,
            includes: const <Offset>[Offset(14, 25), Offset(14, 38.5)],
            excludes: const <Offset>[Offset(8, 25), Offset(20, 25), Offset(12, 38.5)],
          ),
      );
    });

    testWidgets("wick scales with the width", (WidgetTester tester) async {
      await _pumpPin(tester, const MapPin(size: Size(42, 60), showShadow: false));

      // Half-width 42 * 5 / 28 = 7.5, starting at y = 42 * 24 / 28 = 36.
      expect(
        _paint,
        paints
          ..circle(x: 21, y: 21, radius: 21)
          ..circle(x: 21, y: 21, radius: 21)
          ..path(
            includes: const <Offset>[Offset(14, 37), Offset(28, 37), Offset(21, 59)],
            excludes: const <Offset>[Offset(13, 37), Offset(29, 37), Offset(19, 59)],
          ),
      );
    });
  });

  group("colours", () {
    testWidgets("defaults: shadow, primary head, onPrimary outline, primary wick", (WidgetTester tester) async {
      await _pumpPin(tester, const MapPin());
      final ColorScheme cs = _scheme(tester);

      expect(
        find.byType(MapPin),
        paints
          ..path(color: _shadow(cs), hasMaskFilter: true)
          ..circle(color: cs.primary, style: PaintingStyle.fill)
          ..circle(color: _outline(cs), strokeWidth: 1.5, style: PaintingStyle.stroke)
          ..path(color: cs.primary, hasMaskFilter: false),
      );
    });

    testWidgets("the shadow follows the pin shape, offset by 2 dp", (WidgetTester tester) async {
      await _pumpPin(tester, const MapPin());

      expect(
        _paint,
        paints
          ..path(
            hasMaskFilter: true,
            includes: const <Offset>[Offset(14, 16), Offset(14, 41)],
            excludes: const <Offset>[Offset(1, 41), Offset(27, 41)],
          ),
      );
    });

    testWidgets("color overrides the head and the wick", (WidgetTester tester) async {
      await _pumpPin(tester, const MapPin());
      final ColorScheme cs = _scheme(tester);

      await _pumpPin(tester, MapPin(color: cs.tertiary));

      expect(
        _paint,
        paints
          ..path(color: _shadow(cs))
          ..circle(color: cs.tertiary, style: PaintingStyle.fill)
          ..circle(color: _outline(cs), style: PaintingStyle.stroke)
          ..path(color: cs.tertiary),
      );
    });

    testWidgets("outlineColor overrides the stroked head outline", (WidgetTester tester) async {
      await _pumpPin(tester, const MapPin());
      final ColorScheme cs = _scheme(tester);

      await _pumpPin(tester, MapPin(outlineColor: cs.outline));

      expect(
        _paint,
        paints
          ..circle(color: cs.primary, style: PaintingStyle.fill)
          ..circle(color: cs.outline, strokeWidth: 1.5, style: PaintingStyle.stroke),
      );
    });

    testWidgets("showShadow: false draws no shadow path", (WidgetTester tester) async {
      await _pumpPin(tester, const MapPin(showShadow: false));
      final ColorScheme cs = _scheme(tester);

      expect(_paint, paintsExactlyCountTimes(#drawPath, 1));
      expect(_paint, paintsExactlyCountTimes(#drawCircle, 2));
      expect(_paint, isNot(paints..path(color: _shadow(cs))));
      expect(_paint, paints..path(color: cs.primary, hasMaskFilter: false));
    });

    testWidgets("with the shadow, two paths and two circles are drawn", (WidgetTester tester) async {
      await _pumpPin(tester, const MapPin());

      expect(_paint, paintsExactlyCountTimes(#drawPath, 2));
      expect(_paint, paintsExactlyCountTimes(#drawCircle, 2));
    });

    testWidgets("dark theme uses the dark scheme tokens", (WidgetTester tester) async {
      final ThemeData dark = AppTheme.dark();
      final ColorScheme cs = dark.colorScheme;
      await _pumpPin(tester, const MapPin(), theme: dark);

      expect(cs.brightness, Brightness.dark);
      expect(cs.primary, isNot(AppTheme.light().colorScheme.primary));
      expect(
        _paint,
        paints
          ..path(color: _shadow(cs))
          ..circle(color: cs.primary, style: PaintingStyle.fill)
          ..circle(color: _outline(cs), style: PaintingStyle.stroke)
          ..path(color: cs.primary),
      );
    });
  });

  group("semantics", () {
    testWidgets("default label is the chrome key, as an image node", (WidgetTester tester) async {
      await _pumpPin(tester, const MapPin());

      expect(find.bySemanticsLabel("custom.map_pin.label"), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(MapPin)),
        isSemantics(label: "custom.map_pin.label", isImage: true),
      );
    });

    testWidgets("semanticLabel overrides the default", (WidgetTester tester) async {
      await _pumpPin(tester, const MapPin(semanticLabel: "Selected point"));

      expect(find.bySemanticsLabel("Selected point"), findsOneWidget);
      expect(find.bySemanticsLabel("custom.map_pin.label"), findsNothing);
    });

    testWidgets("ExcludeSemantics hides a decorative copy", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: ExcludeSemantics(child: MapPin())));

      expect(find.bySemanticsLabel("custom.map_pin.label"), findsNothing);
    });

    testWidgets("keeps its own node inside a labelled host", (WidgetTester tester) async {
      await pumpApp(tester, Semantics(label: "host", child: const Center(child: MapPin())));

      expect(find.bySemanticsLabel("custom.map_pin.label"), findsOneWidget);
      expect(find.bySemanticsLabel("host"), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(MapPin)),
        isSemantics(label: "custom.map_pin.label", isImage: true),
      );
    });
  });

  group("repaint", () {
    testWidgets("a new color schedules a repaint", (WidgetTester tester) async {
      final ValueNotifier<MapPin> pin = _notifier(const MapPin());
      await _pumpSwappable(tester, pin);
      final ColorScheme cs = _scheme(tester);

      expect(await _repaintsAfterSwap(tester, pin, MapPin(color: cs.tertiary)), isTrue);
      expect(_paint, paints..circle(color: cs.tertiary, style: PaintingStyle.fill));
    });

    testWidgets("a new outlineColor schedules a repaint", (WidgetTester tester) async {
      final ValueNotifier<MapPin> pin = _notifier(const MapPin());
      await _pumpSwappable(tester, pin);
      final ColorScheme cs = _scheme(tester);

      expect(await _repaintsAfterSwap(tester, pin, MapPin(outlineColor: cs.outline)), isTrue);
      expect(
        _paint,
        paints
          ..circle(color: cs.primary, style: PaintingStyle.fill)
          ..circle(color: cs.outline, style: PaintingStyle.stroke),
      );
    });

    testWidgets("toggling showShadow schedules a repaint", (WidgetTester tester) async {
      final ValueNotifier<MapPin> pin = _notifier(const MapPin());
      await _pumpSwappable(tester, pin);

      expect(await _repaintsAfterSwap(tester, pin, const MapPin(showShadow: false)), isTrue);
      expect(_paint, paintsExactlyCountTimes(#drawPath, 1));
    });

    testWidgets("an unchanged look does not repaint", (WidgetTester tester) async {
      final ValueNotifier<MapPin> pin = _notifier(const MapPin());
      await _pumpSwappable(tester, pin);

      expect(await _repaintsAfterSwap(tester, pin, const MapPin(semanticLabel: "Selected point")), isFalse);
      expect(find.bySemanticsLabel("Selected point"), findsOneWidget);
    });
  });

  group("drop animation", () {
    testWidgets("without an animation there is no transform", (WidgetTester tester) async {
      await _pumpPin(tester, const MapPin());

      expect(_transform, findsNothing);
    });

    testWidgets("no deformation before the squash window", (WidgetTester tester) async {
      await _pumpPin(tester, const MapPin(dropAnimation: AlwaysStoppedAnimation<double>(0.5)));

      final Matrix4 matrix = _matrix(tester);
      expect(matrix.storage[0], 1.0);
      expect(matrix.storage[5], 1.0);
    });

    testWidgets("squash peaks at +15 % X / -18 % Y, anchored at the top", (WidgetTester tester) async {
      await _pumpPin(tester, const MapPin(dropAnimation: AlwaysStoppedAnimation<double>(_peak)));

      final Matrix4 matrix = _matrix(tester);
      expect(matrix.storage[0], closeTo(1.15, 1e-9));
      expect(matrix.storage[5], closeTo(0.82, 1e-9));
      expect(tester.widget<Transform>(_transform).alignment, Alignment.topCenter);

      final Rect box = tester.getRect(find.byType(MapPin));
      final Rect drawn = tester.getRect(_paint);
      expect(drawn.top, closeTo(box.top, 1e-6));
      expect(drawn.center.dx, closeTo(box.center.dx, 1e-6));
      expect(drawn.width, closeTo(28 * 1.15, 1e-6));
      expect(drawn.height, closeTo(40 * 0.82, 1e-6));
    });

    testWidgets("the pin is back to full size at the end", (WidgetTester tester) async {
      await _pumpPin(tester, const MapPin(dropAnimation: AlwaysStoppedAnimation<double>(1)));

      final Matrix4 matrix = _matrix(tester);
      expect(matrix.storage[0], closeTo(1.0, 1e-9));
      expect(matrix.storage[5], closeTo(1.0, 1e-9));
    });

    testWidgets("values past the end are clamped (no inverted squash)", (WidgetTester tester) async {
      await _pumpPin(tester, const MapPin(dropAnimation: AlwaysStoppedAnimation<double>(1.2)));

      final Matrix4 matrix = _matrix(tester);
      expect(matrix.storage[0], closeTo(1.0, 1e-9));
      expect(matrix.storage[5], closeTo(1.0, 1e-9));
    });

    testWidgets("follows the caller's controller", (WidgetTester tester) async {
      final AnimationController controller = _controller(0);
      await _pumpPin(tester, MapPin(dropAnimation: controller));
      expect(_matrix(tester).storage[5], 1.0);

      controller.value = _peak;
      await tester.pump();
      expect(_matrix(tester).storage[5], closeTo(0.82, 1e-9));

      controller.value = 1;
      await tester.pump();
      expect(_matrix(tester).storage[5], closeTo(1.0, 1e-9));
    });

    testWidgets("reduced motion renders the static pin", (WidgetTester tester) async {
      final AnimationController controller = _controller(_peak);
      await _pumpReducedMotion(tester, MapPin(dropAnimation: controller));

      expect(_transform, findsNothing);
      expect(tester.getSize(_paint), MapPin.defaultSize);
    });
  });
}

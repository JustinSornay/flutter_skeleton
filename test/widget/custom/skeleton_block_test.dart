// skeleton_block_test.dart
//
// Widget tests for SkeletonBlock: fixed and parent-driven sizes, default and
// custom corner radius, the cs.surfaceContainerHighest fill in the light and
// dark themes, composition with SkeletonPulse (with and without reduced
// motion) and the absence of text / semantics.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/widgets/core/decorators/SkeletonPulse/index.dart";
import "package:flutter_skeleton/widgets/custom/SkeletonBlock/index.dart";
import "package:flutter_test/flutter_test.dart";

import "../../helpers/widget_test_helpers.dart";

Finder _inBlock(Finder matching) {
  return find.descendant(of: find.byType(SkeletonBlock), matching: matching);
}

BoxDecoration _decoration(WidgetTester tester) {
  final Container container = tester.widget<Container>(_inBlock(find.byType(Container)));
  return container.decoration! as BoxDecoration;
}

ColorScheme _scheme(WidgetTester tester) => Theme.of(tester.element(find.byType(SkeletonBlock))).colorScheme;

Finder _pulseOpacity() {
  return find.descendant(of: find.byType(SkeletonPulse), matching: find.byType(Opacity));
}

void main() {
  group("size", () {
    testWidgets("uses the given width and height", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: SkeletonBlock(width: 120, height: 16)));

      expect(tester.getSize(find.byType(SkeletonBlock)), const Size(120, 16));
    });

    testWidgets("takes its width from the parent when width is null", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Center(child: SizedBox(width: 300, child: SkeletonBlock(height: 20))),
      );

      expect(tester.getSize(find.byType(SkeletonBlock)), const Size(300, 20));
    });

    testWidgets("fills the cross axis of a stretched Column", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Center(
          child: SizedBox(
            width: 240,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[SkeletonBlock(height: 12)],
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(SkeletonBlock)), const Size(240, 12));
    });
  });

  group("radius", () {
    testWidgets("defaults to 8", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: SkeletonBlock(width: 40, height: 40)));

      expect(_decoration(tester).borderRadius, BorderRadius.circular(8));
    });

    testWidgets("uses 999 for a pill", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Center(child: SkeletonBlock(width: 80, height: 24, borderRadius: 999)),
      );

      expect(_decoration(tester).borderRadius, BorderRadius.circular(999));
    });

    testWidgets("uses 0 for edge-to-edge media", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Center(child: SkeletonBlock(width: 200, height: 100, borderRadius: 0)),
      );

      expect(_decoration(tester).borderRadius, BorderRadius.circular(0));
    });
  });

  group("theme", () {
    testWidgets("fills with surfaceContainerHighest in the light theme", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: SkeletonBlock(width: 40, height: 16)));

      expect(_decoration(tester).color, _scheme(tester).surfaceContainerHighest);
      expect(_scheme(tester).brightness, Brightness.light);
    });

    testWidgets("fills with surfaceContainerHighest in the dark theme", (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Center(child: SkeletonBlock(width: 40, height: 16)),
        theme: AppTheme.dark(),
      );

      expect(_scheme(tester).brightness, Brightness.dark);
      expect(_decoration(tester).color, AppTheme.dark().colorScheme.surfaceContainerHighest);
    });
  });

  group("composition with SkeletonPulse", () {
    testWidgets("pulses the block through an Opacity", (WidgetTester tester) async {
      await pumpApp(tester, const Center(child: SkeletonPulse(child: SkeletonBlock(width: 100, height: 16))));

      expect(_pulseOpacity(), findsOneWidget);
      final double start = tester.widget<Opacity>(_pulseOpacity()).opacity;

      await tester.pump(const Duration(milliseconds: 750));

      expect(tester.widget<Opacity>(_pulseOpacity()).opacity, isNot(start));
      expect(find.byType(SkeletonBlock), findsOneWidget);
    });

    testWidgets("renders the block without Opacity under reduced motion", (WidgetTester tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: const Center(child: SkeletonPulse(child: SkeletonBlock(width: 100, height: 16))),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 750));

      expect(_pulseOpacity(), findsNothing);
      expect(tester.getSize(find.byType(SkeletonBlock)), const Size(100, 16));
    });
  });

  group("accessibility", () {
    testWidgets("is decorative: no text and no semantics", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const Center(child: SkeletonBlock(width: 100, height: 16)));

      expect(_inBlock(find.byType(Text)), findsNothing);
      expect(_inBlock(find.byType(Semantics)), findsNothing);
      expect(tester.getSemantics(find.byType(SkeletonBlock)).label, isEmpty);
      handle.dispose();
    });
  });
}

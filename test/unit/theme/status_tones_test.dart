// status_tones_test.dart
//
// Unit tests for the StatusTones theme extension (lib/theme/status_tones.dart).
// Covers: WCAG AA contrast (>= 4.5:1) of every tone in AppTheme.light() and
//         AppTheme.dark(), registration in AppTheme, resolve() mapping,
//         of() fallback when the extension is missing, copyWith, lerp endpoints.

import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_test/flutter_test.dart";

/// WCAG 2.x contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Captures the [BuildContext] of a widget pumped under [theme].
Future<BuildContext> _contextUnder(WidgetTester tester, ThemeData theme) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (BuildContext context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  final Map<String, ThemeData> themes = <String, ThemeData>{
    "light": AppTheme.light(),
    "dark": AppTheme.dark(),
  };

  // ---------------------------------------------------------------------------
  // Contrast
  // ---------------------------------------------------------------------------
  themes.forEach((String name, ThemeData theme) {
    group("contrast ($name)", () {
      final ColorScheme cs = theme.colorScheme;
      final StatusTones tones = theme.extension<StatusTones>()!;

      for (final StatusTone tone in StatusTone.values) {
        final ToneColors colors = tones.resolve(tone, cs);

        test("${tone.name} foreground on surface >= 4.5:1", () {
          expect(_contrast(colors.foreground, cs.surface), greaterThanOrEqualTo(4.5));
        });

        test("${tone.name} foreground on surfaceContainerHighest >= 4.5:1", () {
          expect(
            _contrast(colors.foreground, cs.surfaceContainerHighest),
            greaterThanOrEqualTo(4.5),
          );
        });

        test("${tone.name} onContainer on container >= 4.5:1", () {
          expect(_contrast(colors.onContainer, colors.container), greaterThanOrEqualTo(4.5));
        });
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Registration and resolve()
  // ---------------------------------------------------------------------------
  group("AppTheme", () {
    test("registers StatusTones built from its colour scheme", () {
      for (final ThemeData theme in themes.values) {
        expect(theme.extension<StatusTones>(), StatusTones.fromScheme(theme.colorScheme));
      }
    });

    test("light and dark tones differ", () {
      expect(
        AppTheme.light().extension<StatusTones>(),
        isNot(AppTheme.dark().extension<StatusTones>()),
      );
    });
  });

  group("resolve", () {
    final ColorScheme cs = AppTheme.light().colorScheme;
    final StatusTones tones = StatusTones.fromScheme(cs);

    test("neutral and primary read the colour scheme", () {
      expect(
        tones.resolve(StatusTone.neutral, cs),
        ToneColors(
          foreground: cs.onSurfaceVariant,
          container: cs.surfaceContainerHighest,
          onContainer: cs.onSurface,
        ),
      );
      expect(
        tones.resolve(StatusTone.primary, cs),
        ToneColors(
          foreground: cs.primary,
          container: cs.primaryContainer,
          onContainer: cs.onPrimaryContainer,
        ),
      );
    });

    test("seeded tones and danger return the extension fields", () {
      expect(tones.resolve(StatusTone.info, cs), tones.info);
      expect(tones.resolve(StatusTone.success, cs), tones.success);
      expect(tones.resolve(StatusTone.warning, cs), tones.warning);
      expect(tones.resolve(StatusTone.danger, cs), tones.danger);
    });

    test("danger uses the error roles", () {
      expect(
        tones.danger,
        ToneColors(foreground: cs.error, container: cs.errorContainer, onContainer: cs.onErrorContainer),
      );
    });

    test("every tone has a distinct icon", () {
      final Set<IconData> icons = StatusTone.values.map((StatusTone t) => t.icon).toSet();
      expect(icons, hasLength(StatusTone.values.length));
    });
  });

  // ---------------------------------------------------------------------------
  // of() / colorsOf()
  // ---------------------------------------------------------------------------
  group("of", () {
    testWidgets("returns the registered extension", (WidgetTester tester) async {
      final ThemeData theme = AppTheme.dark();
      final BuildContext context = await _contextUnder(tester, theme);
      expect(StatusTones.of(context), same(theme.extension<StatusTones>()));
    });

    testWidgets("falls back to fromScheme when the extension is missing", (WidgetTester tester) async {
      final ColorScheme cs = ColorScheme.fromSeed(seedColor: AppTheme.seed);
      final BuildContext context = await _contextUnder(tester, ThemeData(colorScheme: cs));
      expect(StatusTones.of(context), StatusTones.fromScheme(cs));
    });

    testWidgets("colorsOf resolves against the ambient scheme", (WidgetTester tester) async {
      final ThemeData theme = AppTheme.light();
      final BuildContext context = await _contextUnder(tester, theme);
      expect(
        StatusTones.colorsOf(context, StatusTone.primary).foreground,
        theme.colorScheme.primary,
      );
      expect(
        StatusTones.colorsOf(context, StatusTone.warning),
        theme.extension<StatusTones>()!.warning,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // copyWith / lerp
  // ---------------------------------------------------------------------------
  group("copyWith and lerp", () {
    final StatusTones light = AppTheme.light().extension<StatusTones>()!;
    final StatusTones dark = AppTheme.dark().extension<StatusTones>()!;

    test("copyWith replaces only the given fields", () {
      final StatusTones copy = light.copyWith(info: dark.info);
      expect(copy.info, dark.info);
      expect(copy.success, light.success);
      expect(copy.warning, light.warning);
      expect(copy.danger, light.danger);
    });

    test("lerp at t = 0 returns the start", () {
      expect(light.lerp(dark, 0), light);
    });

    test("lerp at t = 1 returns the end", () {
      expect(light.lerp(dark, 1), dark);
    });

    test("lerp with a null other returns this", () {
      expect(light.lerp(null, 0.5), same(light));
    });

    test("ToneColors.lerp interpolates each colour", () {
      final ToneColors mid = ToneColors.lerp(light.info, dark.info, 0.5);
      expect(mid.foreground, Color.lerp(light.info.foreground, dark.info.foreground, 0.5));
      expect(mid.container, Color.lerp(light.info.container, dark.info.container, 0.5));
      expect(mid.onContainer, Color.lerp(light.info.onContainer, dark.info.onContainer, 0.5));
    });
  });
}

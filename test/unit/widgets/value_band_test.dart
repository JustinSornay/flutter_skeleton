// value_band_test.dart
//
// Unit tests for ValueBand (lib/widgets/custom/_base/value_band.dart).
// Covers: defaults, the from < to assertion, resolveColor() from the tone
//         container or the explicit colour override.

import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/app_theme.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/custom/_base/value_band.dart";
import "package:flutter_test/flutter_test.dart";

/// Pumps a themed tree and returns the result of [read] in its context.
Future<T> _read<T>(WidgetTester tester, ThemeData theme, T Function(BuildContext) read) async {
  late T result;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (BuildContext context) {
          result = read(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return result;
}

void main() {
  test("defaults to the neutral tone with no colour or label", () {
    const ValueBand band = ValueBand(from: 0, to: 10);
    expect(band.tone, StatusTone.neutral);
    expect(band.color, isNull);
    expect(band.label, isNull);
  });

  test("asserts from < to", () {
    expect(() => ValueBand(from: 5, to: 5), throwsAssertionError);
    expect(() => ValueBand(from: 6, to: 5), throwsAssertionError);
  });

  testWidgets("resolveColor uses the tone container", (WidgetTester tester) async {
    final ThemeData theme = AppTheme.light();
    const ValueBand band = ValueBand(from: 0, to: 1, tone: StatusTone.warning);
    final Color color = await _read(tester, theme, band.resolveColor);
    expect(color, theme.extension<StatusTones>()!.warning.container);
  });

  testWidgets("resolveColor follows the theme brightness", (WidgetTester tester) async {
    final ThemeData theme = AppTheme.dark();
    const ValueBand band = ValueBand(from: 0, to: 1, tone: StatusTone.neutral);
    final Color color = await _read(tester, theme, band.resolveColor);
    expect(color, theme.colorScheme.surfaceContainerHighest);
  });

  testWidgets("an explicit colour overrides the tone", (WidgetTester tester) async {
    final ThemeData theme = AppTheme.light();
    final ValueBand band = ValueBand(
      from: 0,
      to: 1,
      tone: StatusTone.danger,
      color: theme.colorScheme.tertiary,
    );
    final Color color = await _read(tester, theme, band.resolveColor);
    expect(color, theme.colorScheme.tertiary);
  });
}

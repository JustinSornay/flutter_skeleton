// status_tones.dart
//
// Semantic status tones (neutral, primary, info, success, warning, danger)
// shared by every tone-aware widget. [StatusTones] is a ThemeExtension
// registered by AppTheme._build (app_theme.dart); widgets read it through
// `StatusTones.colorsOf(context, tone)` and never declare their own tone enums.
//
// Theme files are the only place hex colour values may live.

import "package:flutter/material.dart";

/// Semantic colour role shared by every tone-aware widget.
///
/// Always paired with text or an icon, never colour alone.
enum StatusTone {
  neutral(Icons.remove_circle_outline),
  primary(Icons.radio_button_checked),
  info(Icons.info_outline),
  success(Icons.check_circle_outline),
  warning(Icons.warning_amber_rounded),
  danger(Icons.error_outline);

  const StatusTone(this.icon);

  /// Non-colour glyph for the tone, the default icon of tone-aware widgets.
  final IconData icon;
}

/// The three colours of one tone.
@immutable
final class ToneColors {
  const ToneColors({
    required this.foreground,
    required this.container,
    required this.onContainer,
  });

  /// Text / icon / stroke on `cs.surface` … `cs.surfaceContainerHighest`
  /// (>= 4.5:1).
  final Color foreground;

  /// Tinted fill (pills, banners, cells, bands).
  final Color container;

  /// Text / icon on [container] (>= 4.5:1).
  final Color onContainer;

  /// Interpolates each colour of [a] and [b] with [Color.lerp].
  static ToneColors lerp(ToneColors a, ToneColors b, double t) {
    return ToneColors(
      foreground: Color.lerp(a.foreground, b.foreground, t)!,
      container: Color.lerp(a.container, b.container, t)!,
      onContainer: Color.lerp(a.onContainer, b.onContainer, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ToneColors &&
        other.foreground == foreground &&
        other.container == container &&
        other.onContainer == onContainer;
  }

  @override
  int get hashCode => Object.hash(foreground, container, onContainer);
}

/// Theme extension holding the colours of the seeded tones.
///
/// `neutral` and `primary` are read straight from the [ColorScheme] by
/// [resolve]; `danger` reuses the scheme's error roles.
@immutable
final class StatusTones extends ThemeExtension<StatusTones> {
  const StatusTones({
    required this.info,
    required this.success,
    required this.warning,
    required this.danger,
  });

  final ToneColors info;
  final ToneColors success;
  final ToneColors warning;
  final ToneColors danger;

  static const Color successSeed = Color(0xFF047857);
  static const Color infoSeed = Color(0xFF1565C0);
  static const Color warningSeed = Color(0xFFC2410C);

  /// success / info / warning: `ColorScheme.fromSeed(seedColor: seed,
  /// brightness: scheme.brightness, dynamicSchemeVariant: fidelity)` →
  /// (primary, primaryContainer, onPrimaryContainer), with the matching
  /// [successSeed], [infoSeed] or [warningSeed].
  /// danger: (scheme.error, scheme.errorContainer, scheme.onErrorContainer).
  factory StatusTones.fromScheme(ColorScheme scheme) {
    return StatusTones(
      info: _seeded(infoSeed, scheme.brightness),
      success: _seeded(successSeed, scheme.brightness),
      warning: _seeded(warningSeed, scheme.brightness),
      danger: ToneColors(
        foreground: scheme.error,
        container: scheme.errorContainer,
        onContainer: scheme.onErrorContainer,
      ),
    );
  }

  static ToneColors _seeded(Color seed, Brightness brightness) {
    final ColorScheme tonal = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    return ToneColors(
      foreground: tonal.primary,
      container: tonal.primaryContainer,
      onContainer: tonal.onPrimaryContainer,
    );
  }

  /// Registered extension, or `StatusTones.fromScheme(Theme.of(context).colorScheme)`
  /// when absent. Never throws.
  static StatusTones of(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.extension<StatusTones>() ?? StatusTones.fromScheme(theme.colorScheme);
  }

  /// neutral → (cs.onSurfaceVariant, cs.surfaceContainerHighest, cs.onSurface)
  /// primary → (cs.primary, cs.primaryContainer, cs.onPrimaryContainer)
  /// info / success / warning / danger → the fields above.
  ToneColors resolve(StatusTone tone, ColorScheme scheme) {
    return switch (tone) {
      StatusTone.neutral => ToneColors(
          foreground: scheme.onSurfaceVariant,
          container: scheme.surfaceContainerHighest,
          onContainer: scheme.onSurface,
        ),
      StatusTone.primary => ToneColors(
          foreground: scheme.primary,
          container: scheme.primaryContainer,
          onContainer: scheme.onPrimaryContainer,
        ),
      StatusTone.info => info,
      StatusTone.success => success,
      StatusTone.warning => warning,
      StatusTone.danger => danger,
    };
  }

  /// Shorthand used by widgets.
  static ToneColors colorsOf(BuildContext context, StatusTone tone) =>
      of(context).resolve(tone, Theme.of(context).colorScheme);

  @override
  StatusTones copyWith({
    ToneColors? info,
    ToneColors? success,
    ToneColors? warning,
    ToneColors? danger,
  }) {
    return StatusTones(
      info: info ?? this.info,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  StatusTones lerp(covariant ThemeExtension<StatusTones>? other, double t) {
    if (other is! StatusTones) return this;
    return StatusTones(
      info: ToneColors.lerp(info, other.info, t),
      success: ToneColors.lerp(success, other.success, t),
      warning: ToneColors.lerp(warning, other.warning, t),
      danger: ToneColors.lerp(danger, other.danger, t),
    );
  }

  // Value equality keeps ThemeData equality stable when AppTheme is rebuilt.
  @override
  bool operator ==(Object other) {
    return other is StatusTones &&
        other.info == info &&
        other.success == success &&
        other.warning == warning &&
        other.danger == danger;
  }

  @override
  int get hashCode => Object.hash(info, success, warning, danger);
}

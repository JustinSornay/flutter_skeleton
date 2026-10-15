// delta_badge.dart
//
// Private cell of DataTableColumnSpec.delta: a dense PillBadge "▲ value" in
// the success tone or "▼ value" in the danger tone, or a muted "—" for zero,
// NaN or a change below the neutral threshold. Each case has a spoken label
// instead of the glyphs.

part of "../index.dart";

/// Neutral dash font size.
const double _neutralFontSize = 12;

final class _DeltaBadge extends StatelessWidget {
  /// Signed change.
  final double value;

  /// Formats the absolute value; null uses a one-decimal percentage.
  final String Function(double absValue)? format;

  /// Changes with a smaller magnitude render as neutral (zero always does).
  final double neutralThreshold;

  const _DeltaBadge({required this.value, required this.format, required this.neutralThreshold});

  @override
  Widget build(BuildContext context) {
    if (value.isNaN || value == 0 || value.abs() < neutralThreshold) return _neutral(context);

    final bool up = value > 0;
    final StatusTone tone = up ? StatusTone.success : StatusTone.danger;
    final ToneColors colors = StatusTones.colorsOf(context, tone);
    final String amount = _format(context, value.abs());
    final String arrow = up ? "▲" : "▼";
    final String key = up ? "custom.filterable_data_table.delta_up" : "custom.filterable_data_table.delta_down";

    return PillBadge(
      label: "$arrow $amount",
      tone: tone,
      color: colors.onContainer,
      backgroundColor: colors.container,
      dense: true,
      semanticsLabel: key.tr(namedArgs: <String, String>{"value": amount}),
    );
  }

  Widget _neutral(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Text(
      "—",
      semanticsLabel: "custom.filterable_data_table.delta_none".tr(),
      style: theme.textTheme.labelMedium?.copyWith(
        fontSize: _neutralFontSize,
        fontWeight: FontWeight.w400,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// [absValue] through [format], else as a one-decimal percentage for the
  /// ambient locale (an unknown locale falls back to intl's default).
  String _format(BuildContext context, double absValue) {
    final String Function(double absValue)? custom = format;
    if (custom != null) return custom(absValue);

    final String? tag = Localizations.maybeLocaleOf(context)?.toLanguageTag();
    final String? locale = Intl.verifiedLocale(tag, NumberFormat.localeExists, onFailure: (String _) => null);
    return NumberFormat.decimalPercentPattern(locale: locale, decimalDigits: 1).format(absValue);
  }
}

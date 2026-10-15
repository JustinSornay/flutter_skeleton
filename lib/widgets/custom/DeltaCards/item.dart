// item.dart
//
// Value classes of DeltaCards: DeltaTrend (direction of a change, which
// picks the default caption key) and DeltaCardItem (one card), with the
// numeric and categorical factories that derive the value text, the trend
// and the StatusTone from raw before / after values. Pure Dart, no
// BuildContext.

part of "index.dart";

/// Direction of a change. Picks the default trend caption of a card when
/// [DeltaCardItem.trendLabel] is null or empty.
enum DeltaTrend {
  /// The value went up. Caption `custom.delta_cards.increase`.
  increase("custom.delta_cards.increase"),

  /// The value went down. Caption `custom.delta_cards.decrease`.
  decrease("custom.delta_cards.decrease"),

  /// No change. Caption `custom.delta_cards.stable`.
  stable("custom.delta_cards.stable"),

  /// A categorical value changed. Caption `custom.delta_cards.shift`.
  shift("custom.delta_cards.shift");

  const DeltaTrend(this.captionKey);

  /// Translation key of the default caption.
  final String captionKey;
}

/// One card of [DeltaCards]: a metric name, its pre-formatted value and the
/// trend of the change, with the [StatusTone] giving its meaning.
@immutable
final class DeltaCardItem {
  /// Metric name, already localised. Shown upper-cased; announced as given.
  final String label;

  /// Value shown prominently, already formatted and localised. Empty → "—".
  final String value;

  /// Direction of the change; picks the default caption.
  final DeltaTrend trend;

  /// Meaning of the change, tint of the caption: typically `success`
  /// (favourable or stable), `warning`, `danger` (adverse) or `neutral` (no
  /// judgement, `cs.onSurfaceVariant`).
  final StatusTone tone;

  /// Caption under the value, already localised. Null or empty → the
  /// translated [DeltaTrend.captionKey] of [trend].
  final String? trendLabel;

  const DeltaCardItem({
    required this.label,
    required this.value,
    this.trend = DeltaTrend.stable,
    this.tone = StatusTone.neutral,
    this.trendLabel,
  });

  /// Card for a numeric change: `delta = after - before`, rounded to
  /// [fractionDigits] (0 to 20).
  ///
  /// - [trend] comes from the ROUNDED delta (> 0 increase, < 0 decrease,
  ///   0 stable), so a rounded "0.0" is never shown as a rise.
  /// - [value] is "↑ +3.3", "↓ -45" or "= 0.0" (decimal point, no grouping)
  ///   followed by [unit] as given: pass "°X" or " ms" with the leading
  ///   space you want. A magnitude of 1e21 or more is written in exponential
  ///   notation ("↑ +1e+21"). For locale-aware digits, format the value
  ///   yourself and use the main constructor.
  /// - The change is adverse when it rises and [higherIsWorse], or when it
  ///   falls and not [higherIsWorse]; an adverse change takes [adverseTone],
  ///   any other change (stable included) takes `StatusTone.success`.
  ///
  /// [before] and [after] must be finite.
  factory DeltaCardItem.numeric({
    required String label,
    required num before,
    required num after,
    String unit = "",
    int fractionDigits = 1,
    bool higherIsWorse = false,
    StatusTone adverseTone = StatusTone.danger,
    String? trendLabel,
  }) {
    assert(fractionDigits >= 0 && fractionDigits <= 20, "fractionDigits must be within 0..20");
    assert(before.isFinite && after.isFinite, "before and after must be finite");

    // Doubles throughout: on the native VM int arithmetic would overflow
    // (10^19, or a large int delta times the scale) and flip the sign.
    final double scale = math.pow(10.0, fractionDigits).toDouble();
    final double steps = ((after.toDouble() - before.toDouble()) * scale).roundToDouble();
    final DeltaTrend trend = steps > 0
        ? DeltaTrend.increase
        : steps < 0
            ? DeltaTrend.decrease
            : DeltaTrend.stable;
    final bool adverse = trend == (higherIsWorse ? DeltaTrend.increase : DeltaTrend.decrease);
    final String magnitude = (steps.abs() / scale).toStringAsFixed(fractionDigits);

    return DeltaCardItem(
      label: label,
      value: "${_numericPrefix(trend)}$magnitude$unit",
      trend: trend,
      tone: adverse ? adverseTone : StatusTone.success,
      trendLabel: trendLabel,
    );
  }

  /// Card for a categorical change, compared with `==`.
  ///
  /// - [trend] is `shift` when [before] != [after], `stable` otherwise.
  /// - [value] is the display label of the new category, shown as given.
  /// - A change takes [adverseTone] when [changeIsAdverse] (the default);
  ///   no change, or a change that is not adverse, takes
  ///   `StatusTone.success`.
  factory DeltaCardItem.categorical({
    required String label,
    required Object? before,
    required Object? after,
    required String value,
    bool changeIsAdverse = true,
    StatusTone adverseTone = StatusTone.danger,
    String? trendLabel,
  }) {
    final bool changed = before != after;

    return DeltaCardItem(
      label: label,
      value: value,
      trend: changed ? DeltaTrend.shift : DeltaTrend.stable,
      tone: changed && changeIsAdverse ? adverseTone : StatusTone.success,
      trendLabel: trendLabel,
    );
  }
}

/// Arrow and sign written before the magnitude of a numeric change:
/// "↑ +", "↓ -" or "= ".
String _numericPrefix(DeltaTrend trend) {
  return switch (trend) {
    DeltaTrend.increase => "↑ +",
    DeltaTrend.decrease => "↓ -",
    DeltaTrend.stable || DeltaTrend.shift => "= ",
  };
}

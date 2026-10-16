// index.dart
//
// TrendSplitSection — two cards side by side comparing a "rising" list with a
// "falling" list of labelled signed values (top movers and losers, metrics
// that improved or got worse versus a baseline). Each value is a StatusPill.
// Declares the TrendEntry value class; the tree lives in view.dart.

import "dart:math" as math;

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/utils/formatters/intl_locale.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";

part "view.dart";

/// One labelled signed value shown in a [TrendSplitSection] column.
@immutable
final class TrendEntry {
  /// Row text, already localised (one line, ellipsized).
  final String label;

  /// Signed change. With the default format it is a fraction:
  /// `0.18` → `"+18.0%"`.
  final double delta;

  const TrendEntry({required this.label, required this.delta});
}

/// Two cards side by side: [rising] entries on the left, [falling] entries
/// on the right.
///
/// - Each card has a tinted header with an arrow icon
///   (`Icons.trending_up_rounded` / `Icons.trending_down_rounded`) and the
///   uppercased title, then one row per entry: the label (one line, ellipsis)
///   and a dense [StatusPill] showing the formatted delta. Rows are
///   separated by dividers. An empty list shows [emptyLabel].
/// - The pill arrow follows the sign of the value, like the text, never the
///   column: `Icons.arrow_upward_rounded` for a positive delta,
///   `Icons.arrow_downward_rounded` for a negative one, and no arrow when the
///   delta is zero or formats like zero (`format(delta) == format(0)`). A
///   mis-sorted entry therefore reads "↓ -5.0%" in the rising card.
/// - The pill takes the width it needs and the label gets the rest, but the
///   label always keeps at least 32 dp: at a large text scale in a narrow
///   host the pill text ellipsizes instead of overflowing (the row still
///   announces the full value). Rows measure their width with a
///   `LayoutBuilder`, so the section cannot sit under an intrinsic-size
///   parent (`IntrinsicWidth`, `IntrinsicHeight`).
/// - Tones: rising uses [StatusTone.success] and falling uses
///   [StatusTone.danger]; [higherIsBetter] `false` swaps them (costs, risk).
///   The tone stays per column. It colours the header icon (`foreground`,
///   next to the header title) and the pill (`onContainer` on `container`,
///   around the signed text), never colour alone.
/// - [format] turns a delta into the pill text; by default
///   [TrendSplitSection.defaultFormat] for the ambient locale.
///
/// Built-in strings (used when the matching parameter is null):
/// `custom.trend_split_section.rising`, `.falling` and `.empty`.
///
/// Accessibility: each title is a header node labelled with the title as
/// given (not uppercased); the icons are decorative; each row is one merged
/// node reading the label and the formatted delta.
///
/// Nothing is interactive. The host decides when the section is shown. No
/// tooltip, so no `Overlay` ancestor is needed.
final class TrendSplitSection extends StatelessWidget with _ViewMixin {
  /// Entries of the left card.
  final List<TrendEntry> rising;

  /// Entries of the right card.
  final List<TrendEntry> falling;

  /// Left header title, uppercased when drawn. Null →
  /// `custom.trend_split_section.rising`.
  final String? risingTitle;

  /// Right header title, uppercased when drawn. Null →
  /// `custom.trend_split_section.falling`.
  final String? fallingTitle;

  /// Placeholder of an empty card. Null → `custom.trend_split_section.empty`.
  final String? emptyLabel;

  /// Pill text for a delta. Null → [TrendSplitSection.defaultFormat] with the
  /// ambient locale.
  final String Function(double delta)? format;

  /// `true` (default): rising is success, falling is danger. `false` swaps
  /// the two tones.
  final bool higherIsBetter;

  const TrendSplitSection({
    super.key,
    required this.rising,
    required this.falling,
    this.risingTitle,
    this.fallingTitle,
    this.emptyLabel,
    this.format,
    this.higherIsBetter = true,
  });

  /// [delta] as a signed one-decimal percentage (intl percent pattern for
  /// [locale]; an unknown or null locale falls back to intl's default):
  /// `0.18` → `"+18.0%"`, `-0.14` → `"-14.0%"`, `0` → `"0.0%"`. The sign
  /// comes from the value, never from the column, and is read on the rounded
  /// value: a delta that rounds to zero (`0.00001`, `-0.00001`, `-0.0`) is
  /// the unsigned `"0.0%"`, and the `+` is added only above it.
  static String defaultFormat(double delta, {String? locale}) {
    final String? verified = numberLocale(locale);
    final NumberFormat percent = NumberFormat.decimalPercentPattern(locale: verified, decimalDigits: 1);
    final String zero = percent.format(0);
    if (percent.format(delta.abs()) == zero) return zero;
    final String text = percent.format(delta);
    return delta > 0 ? "+$text" : text;
  }

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

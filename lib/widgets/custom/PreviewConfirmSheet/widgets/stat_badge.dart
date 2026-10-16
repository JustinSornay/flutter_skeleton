// stat_badge.dart
//
// _StatBadge — one PreviewStat: its small label above a composed pill, an
// outlined PillBadge (optional tone dot) or a tone-filled StatusPill (tone
// icon, none for neutral), showing "value" or "value · caption". A delta
// stat's number is formatted here for the ambient locale. The whole stat is
// one semantics node ("label: value[, caption]" by default).

part of "../index.dart";

/// Gap between the label and the pill.
const double _labelGap = kDefaultPadding / 2;

/// Dot glyph of a tone-coded outlined pill (about 9 dp inside PillBadge's
/// fixed 14 dp icon box).
const IconData _dotIcon = Icons.fiber_manual_record;

final class _StatBadge extends StatelessWidget {
  final PreviewStat stat;

  const _StatBadge({required this.stat});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String value = _value(context);

    return Semantics(
      label: _semanticsLabel(value),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            stat.label,
            style: (theme.textTheme.labelSmall ?? const TextStyle(fontSize: 11)).copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: _labelGap),
          _pill(value),
        ],
      ),
    );
  }

  /// [PreviewStat.value], or a delta stat's change formatted with intl
  /// `NumberFormat.decimalPatternDigits` for the ambient locale, with an
  /// explicit sign ("+0,13" in French). An unknown locale falls back to
  /// intl's default.
  String _value(BuildContext context) {
    final double? delta = stat._delta;
    if (delta == null) return stat.value;
    final String? locale = numberLocaleOf(context);
    final NumberFormat format = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: stat._fractionDigits,
    );
    final String digits = format.format(delta);
    return delta > 0 ? "${format.symbols.PLUS_SIGN}$digits" : digits;
  }

  /// The caption, or null when it is null or empty.
  String? _caption() {
    final String? caption = stat.caption;
    return (caption == null || caption.isEmpty) ? null : caption;
  }

  /// [PreviewStat.semanticsLabel], else "label: value[, caption]", with the
  /// displayed [value].
  String _semanticsLabel(String value) {
    final String? custom = stat.semanticsLabel;
    if (custom != null && custom.isNotEmpty) return custom;
    final String? caption = _caption();
    final String base = "${stat.label}: $value";
    return caption == null ? base : "$base, $caption";
  }

  /// Tone-filled StatusPill when tinted (no icon for neutral, which carries
  /// no status), else an outlined PillBadge. [value] is the displayed value.
  Widget _pill(String value) {
    final String? caption = _caption();
    final String text = caption == null ? value : "$value · $caption";
    final StatusTone? tone = stat.tone;
    if (stat.tinted) {
      final StatusTone resolved = tone ?? StatusTone.neutral;
      return StatusPill(
        label: text,
        tone: resolved,
        icon: resolved == StatusTone.neutral ? null : resolved.icon,
      );
    }
    return PillBadge(
      label: text,
      tone: tone ?? StatusTone.neutral,
      icon: tone == null ? null : _dotIcon,
      outlined: true,
    );
  }
}

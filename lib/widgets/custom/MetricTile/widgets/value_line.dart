// value_line.dart
//
// _ValueLine — MetricTile's value row: the optional StatusTone.icon of a
// value tone, the 16 / w700 value (ellipsized, tone-tinted) and the smaller
// muted unit (capped, ellipsized) on the same baseline, or the muted "—"
// placeholder when there is no value.

part of "../index.dart";

/// Gap between the value and its unit (2 dp).
const double _unitGap = kDefaultPadding / 4;

/// Widest a unit gets before it is ellipsized (48 dp).
const double _unitMaxWidth = kDefaultPadding * 6;

/// Size of the value tone icon.
const double _toneIconSize = 12;

/// Gap between the value tone icon and the value (4 dp).
const double _toneIconGap = kDefaultPadding / 2;

final class _ValueLine extends StatelessWidget {
  /// Formatted value; null shows the placeholder.
  final String? value;

  /// Unit after the value; null hides it.
  final String? unit;

  /// Tint of the value; null → `cs.onSurface`. A non-neutral tone also draws
  /// its [StatusTone.icon] before the value.
  final StatusTone? tone;

  /// Line limit of the value; null → no limit.
  final int? maxLines;

  const _ValueLine({required this.value, required this.unit, required this.tone, required this.maxLines});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String? current = value;
    final StatusTone? valueTone = tone;
    if (current == null) {
      return Text(_noValue, style: _valueStyle(cs.onSurfaceVariant));
    }

    final Color color = valueTone == null ? cs.onSurface : StatusTones.colorsOf(context, valueTone).foreground;
    final String? suffix = unit;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        // A status tint is paired with the tone glyph, never colour alone.
        if (valueTone != null && valueTone != StatusTone.neutral) ...<Widget>[
          Icon(valueTone.icon, size: _toneIconSize, color: color),
          const SizedBox(width: _toneIconGap),
        ],
        Flexible(
          child: Text(current, maxLines: maxLines, overflow: _overflow(maxLines), style: _valueStyle(color)),
        ),
        if (suffix != null) ...<Widget>[
          const SizedBox(width: _unitGap),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _unitMaxWidth),
            child: Text(
              suffix,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }

  TextStyle _valueStyle(Color color) {
    return TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color);
  }
}

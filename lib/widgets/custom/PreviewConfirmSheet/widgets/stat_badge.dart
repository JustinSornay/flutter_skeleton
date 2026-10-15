// stat_badge.dart
//
// _StatBadge — one PreviewStat: a small caption above a composed pill, an
// outlined PillBadge (optional tone dot) or a tone-filled StatusPill (tone
// icon). The whole stat is one semantics node ("label: value" by default).

part of "../index.dart";

/// Gap between the caption and the pill.
const double _captionGap = kDefaultPadding / 2;

/// Dot glyph of a tone-coded outlined pill (about 9 dp inside PillBadge's
/// fixed 14 dp icon box).
const IconData _dotIcon = Icons.fiber_manual_record;

final class _StatBadge extends StatelessWidget {
  final PreviewStat stat;

  const _StatBadge({required this.stat});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? semanticsLabel = stat.semanticsLabel;

    return Semantics(
      label: (semanticsLabel == null || semanticsLabel.isEmpty) ? "${stat.label}: ${stat.value}" : semanticsLabel,
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
          const SizedBox(height: _captionGap),
          _pill(),
        ],
      ),
    );
  }

  /// Tone-filled StatusPill when tinted, else an outlined PillBadge.
  Widget _pill() {
    final StatusTone? tone = stat.tone;
    if (stat.tinted) {
      final StatusTone resolved = tone ?? StatusTone.neutral;
      return StatusPill(label: stat.value, tone: resolved, icon: resolved.icon);
    }
    return PillBadge(
      label: stat.value,
      tone: tone ?? StatusTone.neutral,
      icon: tone == null ? null : _dotIcon,
      outlined: true,
    );
  }
}

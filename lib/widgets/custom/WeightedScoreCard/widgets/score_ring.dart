// score_ring.dart
//
// _ScoreRing — the circular score of a WeightedScoreCard: a ring stroked in
// the tone foreground around the tone icon, the score text and "/ 100".
// Read by screen readers as one node with the given label, or hidden from
// them when there is no label (no score yet).

part of "../index.dart";

final class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    required this.text,
    required this.tone,
    required this.size,
    required this.semanticsLabel,
  });

  /// Score text ("68", "…" or "—").
  final String text;

  /// Tone of a loaded score; null draws a muted ring without icon.
  final StatusTone? tone;

  /// Diameter of the ring.
  final double size;

  /// Screen-reader label of the whole ring; null hides the ring from screen
  /// readers.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final StatusTone? tone = this.tone;
    final Color color = tone == null ? cs.onSurfaceVariant : StatusTones.colorsOf(context, tone).foreground;

    final Widget ring = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (tone != null) Icon(tone.icon, size: 14, color: color),
          Text(
            text,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color),
          ),
          Text(
            "/ 100",
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
    final String? label = semanticsLabel;
    if (label == null) return ExcludeSemantics(child: ring);
    return Semantics(container: true, excludeSemantics: true, label: label, child: ring);
  }
}

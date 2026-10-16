// alert_chip.dart
//
// _AlertChip — the full-width danger chip of a WeightedScoreCard shown when
// the score is under the alert threshold: warning icon + text on the danger
// container, announced as a live region.

part of "../index.dart";

final class _AlertChip extends StatelessWidget {
  const _AlertChip({
    required this.text,
    required this.semanticsLabel,
  });

  /// Visible chip text.
  final String text;

  /// Announcement read before [text].
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final ToneColors colors = StatusTones.colorsOf(context, StatusTone.danger);

    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticsLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.container,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 1.5, vertical: kDefaultPadding * 0.75),
          child: Row(
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, size: 14, color: colors.onContainer),
              const SizedBox(width: kDefaultPadding * 0.75),
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.onContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

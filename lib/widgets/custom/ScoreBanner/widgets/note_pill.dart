// note_pill.dart
//
// Private caveat pill of ScoreBanner: the note tone's icon and label in
// `onContainer` on its `container` fill (radius 999), so the text keeps the
// tone's contrast on any banner tone. One semantics node labelled with the
// note text; the icon is not announced.

part of "../index.dart";

/// Size of the note icon.
const double _noteIconSize = 14;

final class _NotePill extends StatelessWidget {
  final ScoreBannerNote note;

  const _NotePill({required this.note});

  @override
  Widget build(BuildContext context) {
    final ToneColors colors = StatusTones.colorsOf(context, note.tone);
    final TextStyle textStyle = Theme.of(context).textTheme.labelSmall ?? const TextStyle();

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: note.label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.container,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: kDefaultPadding,
            vertical: kDefaultPadding / 4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(note.tone.icon, size: _noteIconSize, color: colors.onContainer),
              const SizedBox(width: kDefaultPadding / 2),
              Flexible(
                child: Text(
                  note.label,
                  style: textStyle.copyWith(fontWeight: FontWeight.w600, color: colors.onContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

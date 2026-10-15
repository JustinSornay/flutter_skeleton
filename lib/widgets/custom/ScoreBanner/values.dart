// values.dart
//
// Value class of ScoreBanner: ScoreBannerNote, the optional caveat line drawn
// under the score bar (label + tone). No UI here.

part of "index.dart";

/// Caveat drawn under the score bar of a [ScoreBanner] (e.g. a reliability
/// warning). The host decides whether to show it and what it says.
///
/// Rendered as a small pill in the note's own [tone], independent of the
/// banner tone: `container` fill, with the tone's [StatusTone.icon] and the
/// [label] in `onContainer`.
@immutable
final class ScoreBannerNote {
  /// Text of the note, already localised; also its semantics label.
  final String label;

  /// Colour family and icon of the note.
  final StatusTone tone;

  const ScoreBannerNote({required this.label, this.tone = StatusTone.warning});
}

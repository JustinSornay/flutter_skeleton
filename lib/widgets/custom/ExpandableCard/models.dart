// models.dart
//
// Value classes of ExpandableCard: the header badge, one action of the
// expanded body's action row, and one titled section of the expanded body.

part of "index.dart";

/// Status pill shown next to an [ExpandableCard] title.
@immutable
final class ExpandableCardBadge {
  /// Status text, already localised; rendered uppercase, announced as given.
  final String label;

  /// Semantic tone giving the pill's fill and text colour.
  final StatusTone tone;

  const ExpandableCardBadge({
    required this.label,
    this.tone = StatusTone.neutral,
  });
}

/// Compact icon + label button in the [ExpandableCard] action row.
@immutable
final class ExpandableCardAction {
  /// Leading glyph.
  final IconData icon;

  /// Visible text and accessible name, already localised.
  final String label;

  /// Tap handler. Null renders the action disabled (for example when the
  /// user is not allowed to run it).
  final VoidCallback? onPressed;

  /// Fills the button with `cs.error` and moves it to the trailing edge, for
  /// delete, discard and similar actions.
  final bool destructive;

  const ExpandableCardAction({
    required this.icon,
    required this.label,
    this.onPressed,
    this.destructive = false,
  });
}

/// One block of the [ExpandableCard] expanded body.
@immutable
final class ExpandableCardSection {
  /// Optional caption above [child], rendered uppercase. Hidden when null or
  /// empty.
  final String? title;

  /// Section content, built by the host.
  final Widget child;

  const ExpandableCardSection({
    this.title,
    required this.child,
  });
}

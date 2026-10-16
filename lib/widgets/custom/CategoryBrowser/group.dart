// group.dart
//
// Value class of CategoryBrowser: CategoryBrowserGroup<T>, one accordion
// group (stable key, header texts, icon, ChoiceOption<T> entries, expandable
// flag). No UI here.

part of "index.dart";

/// One group of a [CategoryBrowser].
@immutable
final class CategoryBrowserGroup<T> {
  /// Stable identifier: tracks which group is open and is reported by
  /// `CategoryBrowser.onOpenChanged`. Unique within the browser.
  final String key;

  /// Header title, already localised.
  final String title;

  /// Header second line composed by the host (for example a count summary).
  /// When null, a non-expandable group shows its first entry's label and an
  /// expandable group shows no second line.
  final String? subtitle;

  /// Leading header icon; null shows [Icons.category].
  final IconData? icon;

  /// Selectable entries. Rendered fields: `label`, `description`,
  /// `trailing`, `enabled`, `semanticsLabel` (see [ExpandableGroupTile]).
  final List<ChoiceOption<T>> entries;

  /// `false` turns the group into a direct row: a tap selects
  /// `entries.first.value` instead of opening a body.
  final bool expandable;

  const CategoryBrowserGroup({
    required this.key,
    required this.title,
    required this.entries,
    this.subtitle,
    this.icon,
    this.expandable = true,
  });
}

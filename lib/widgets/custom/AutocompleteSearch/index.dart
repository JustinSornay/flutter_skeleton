// index.dart
//
// AutocompleteSearch — a typed, debounced search field built on SearchField.
// It sends the query to an injected async lookup and shows the matches in a
// dropdown anchored under the field (OverlayPortal). State lives in
// view_model.dart, the field and dropdown in view.dart, and the tappable row
// frame in widgets/suggestion_row.dart.

import "dart:async";

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/SearchField/index.dart";

part "view_model.dart";
part "view.dart";
part "widgets/suggestion_row.dart";

/// Debounced search field with an async suggestion dropdown.
///
/// - [search]: async lookup, called with the trimmed query once it is at
///   least [minQueryLength] characters long and [debounce] has passed since
///   the last keystroke. It is the injected seam: the host passes a service
///   method. Only the response to the latest call is used, so a slow older
///   response never overwrites newer results and never reopens the dropdown
///   after the query was shortened, a suggestion was picked or the dropdown
///   was dismissed.
/// - [itemBuilder]: content of one suggestion row. The widget wraps it in a
///   tappable frame at least [kMinTapTarget] tall, announced as a button,
///   with a default text style (13, `cs.onSurface`, at most 2 lines) and a
///   default icon theme (16, `cs.primary`).
/// - [onSelected]: called with the suggestion the user taps. The dropdown
///   closes and the field is cleared, unless [selectionLabel] is set.
/// - [selectionLabel]: when non-null, the field shows `selectionLabel(item)`
///   after a pick instead of being cleared.
/// - [onError]: receives what [search] threw. The dropdown closes and the
///   spinner stops, unless a newer search is already waiting. Errors from an
///   outdated call, or arriving after the widget is unmounted, are dropped.
/// - [hintText]: placeholder, already localised by the host. Defaults to
///   `custom.autocomplete_search.hint`.
/// - [noResultsText]: shown in the dropdown when [search] returns an empty
///   list. Defaults to `custom.autocomplete_search.no_results`.
/// - [minQueryLength] (default 2) and [debounce] (default 500 ms): shortening
///   the query below [minQueryLength] cancels the pending call and closes the
///   dropdown.
/// - [dropdownWidth] (default 320) and [dropdownMaxHeight] (default 280): the
///   list scrolls past that height.
///
/// The [SearchField] shows its spinner from the first qualifying keystroke
/// until the latest call settles. Previous results stay visible meanwhile.
/// Tapping outside the field and the dropdown closes the dropdown and drops
/// any pending call; the field text is kept. Tapping the field while the
/// dropdown is closed and no call is pending searches its text again (after
/// [debounce]) when it is at least [minQueryLength] long. That brings
/// dismissed results back, retries after an error, and also searches a
/// [selectionLabel] left by a pick. A tap inside the dropdown keeps it open
/// and keeps the field focused, so on desktop and web the user can go on
/// typing. The dropdown carries a live region announcing the result count
/// (`custom.autocomplete_search.results`) or the empty-result text.
///
/// Built-in strings: `custom.autocomplete_search.hint`,
/// `custom.autocomplete_search.no_results`,
/// `custom.autocomplete_search.results` (`{count}`).
///
/// Needs an `Overlay` ancestor (a routed page or a modal): the dropdown is an
/// [OverlayPortal] and the inner text field shows its selection handles
/// there. Do not mount it in the shell `Layout`, which sits above the
/// Navigator and has no Overlay.
final class AutocompleteSearch<T> extends StatefulWidget {
  /// Async lookup called with the trimmed query.
  final Future<List<T>> Function(String query) search;

  /// Builds the content of one suggestion row.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Called with the picked suggestion.
  final ValueChanged<T> onSelected;

  /// Text the field shows after a pick; null clears the field.
  final String Function(T item)? selectionLabel;

  /// Receives what [search] threw.
  final ValueChanged<Object>? onError;

  /// Placeholder; defaults to `custom.autocomplete_search.hint`.
  final String? hintText;

  /// Empty-result text; defaults to `custom.autocomplete_search.no_results`.
  final String? noResultsText;

  /// Minimum trimmed query length before [search] runs.
  final int minQueryLength;

  /// Quiet period after the last keystroke before [search] runs.
  final Duration debounce;

  /// Width of the dropdown.
  final double dropdownWidth;

  /// Maximum height of the dropdown; the list scrolls past it.
  final double dropdownMaxHeight;

  const AutocompleteSearch({
    super.key,
    required this.search,
    required this.itemBuilder,
    required this.onSelected,
    this.selectionLabel,
    this.onError,
    this.hintText,
    this.noResultsText,
    this.minQueryLength = 2,
    this.debounce = const Duration(milliseconds: 500),
    this.dropdownWidth = 320,
    this.dropdownMaxHeight = 280,
  }) : assert(minQueryLength > 0);

  @override
  State<AutocompleteSearch<T>> createState() => _AutocompleteSearchState<T>();
}

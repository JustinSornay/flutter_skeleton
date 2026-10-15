// index.dart
//
// LocationBar — a "pick a place" bar typed on the caller's place value. It
// composes AutocompleteSearch (debounced search with a suggestion dropdown),
// an optional "use my current location" row, and EditableValueRow for the
// chosen place. Declares the LocationSuggestion value class. State lives in
// view_model.dart, the tree in view.dart and the private pieces in widgets/.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/AutocompleteSearch/index.dart";
import "package:flutter_skeleton/widgets/custom/EditableValueRow/index.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";

part "view_model.dart";
part "view.dart";
part "widgets/current_reminder.dart";
part "widgets/hint_line.dart";
part "widgets/locate_row.dart";
part "widgets/suggestion_tile.dart";

/// One place offered by a [LocationBar]: a row of the search dropdown, or the
/// result of [LocationBar.onUseCurrentLocation]. The caller maps its own
/// search or positioning result to it.
@immutable
final class LocationSuggestion<T> {
  /// Payload handed back through [LocationBar.onSelected] (coordinates, a
  /// place id, a DTO…).
  final T value;

  /// Bold first line of the dropdown row.
  final String title;

  /// Muted second line of the dropdown row; hidden when null or empty.
  final String? subtitle;

  /// Small tonal pill next to [title], already localised; hidden when null
  /// or empty.
  final String? badge;

  /// Screen-reader label of the dropdown row. When null the row reads its
  /// visible texts ([title], [badge], [subtitle]).
  final String? semanticsLabel;

  const LocationSuggestion({
    required this.value,
    required this.title,
    this.subtitle,
    this.badge,
    this.semanticsLabel,
  });
}

/// Visual mode of a [LocationBar].
enum _LocationBarMode {
  /// No place yet: search field, current-location row, alternative hint.
  empty,

  /// A place is chosen: compact [EditableValueRow].
  selected,

  /// Re-picking: search field, current-location row, Cancel and a reminder
  /// of the place currently chosen.
  editing,
}

/// Place picker with three modes, driven by [value]:
///
/// - **empty** ([value] is null): a search field, an optional "my location"
///   row and an optional [alternativeHint].
/// - **selected** ([value] is non-null): an [EditableValueRow] showing
///   [title] and [subtitle]. Tapping it clears the row away and opens the
///   search again (editing mode), with an empty field that gets focus after
///   a frame.
/// - **editing**: the search field, the "my location" row, the
///   [alternativeHint] next to a Cancel button and, when [value] is set, a
///   "Currently: title (subtitle)" reminder. Focusing the field in empty mode
///   (tap or keyboard) also enters editing.
///
/// Parameters:
/// - [search]: async lookup handed to [AutocompleteSearch]. It is called with
///   the trimmed query once it has at least 2 characters, 500 ms after the
///   last keystroke; only the latest call's response is shown, and an empty
///   list shows the dropdown's "no results" text.
/// - [onSelected]: called with the picked suggestion (from the dropdown or
///   from [onUseCurrentLocation]); the bar switches to the selected mode. The
///   host is expected to pass the new [value], [title] and [subtitle].
/// - [value]: the chosen place; null means empty mode. It is compared with
///   `!=` when the widget updates, so `T` should implement `==` (or the host
///   should keep the same instance). A new value while editing (picked
///   elsewhere, e.g. on a map) returns the bar to the selected mode; a null
///   value returns the selected mode to the empty mode.
/// - [title]: name of the chosen place; `custom.location_bar.unknown_place`
///   when null or empty. [subtitle]: its second line (e.g. host-formatted
///   coordinates), hidden when null or empty.
/// - [hintText]: search placeholder; defaults to
///   `custom.location_bar.placeholder`.
/// - [alternativeHint]: optional text naming another way to pick a place
///   (e.g. "or tap the map"), shown with a touch icon; hidden when null.
/// - [onEditingStarted] / [onEditingCancelled]: fired when the bar enters
///   editing and when the user presses Cancel (so the host can, for example,
///   toggle a targeting mode).
/// - [onUseCurrentLocation]: "use my current location" action. When null the
///   row is hidden. While its future runs, the row ignores taps, is announced
///   as disabled and shows a [Loader] (when the platform asks to reduce
///   motion, a static hourglass icon with the same `common.loading` label). A
///   non-null result is selected like a dropdown pick; null leaves the bar
///   as it is. The result is dropped when the user picks a suggestion or
///   cancels in the meantime, when the host changes the mode by changing
///   [value], or after unmount.
/// - [onError]: receives what [search] or [onUseCurrentLocation] threw.
///
/// Built-in strings: `custom.location_bar.placeholder`, `.cancel`,
/// `.currently_at` (`{name}`), `.unknown_place`, `.my_location`,
/// `.modify_semantics` (label of the Edit chip), plus the shared
/// `common.loading` (label of the reduced-motion busy icon, as on [Loader]).
///
/// Needs an `Overlay` ancestor (a routed page or a modal): the search
/// dropdown is an `OverlayPortal` and the text field shows its selection
/// handles there. Do not mount it in the shell `Layout`, which sits above the
/// Navigator and has no Overlay. It also needs a [Material] ancestor for the
/// ink of its tappable rows.
final class LocationBar<T> extends StatefulWidget {
  /// Async suggestion lookup, called with the trimmed query.
  final Future<List<LocationSuggestion<T>>> Function(String query) search;

  /// Called with the picked suggestion.
  final ValueChanged<LocationSuggestion<T>> onSelected;

  /// The chosen place; null means empty mode.
  final T? value;

  /// Name of the chosen place; `custom.location_bar.unknown_place` when null
  /// or empty.
  final String? title;

  /// Second line of the chosen place; hidden when null or empty.
  final String? subtitle;

  /// Search placeholder; defaults to `custom.location_bar.placeholder`.
  final String? hintText;

  /// Text naming another way to pick a place; hidden when null.
  final String? alternativeHint;

  /// Fired when the bar enters editing mode.
  final VoidCallback? onEditingStarted;

  /// Fired when the user cancels editing.
  final VoidCallback? onEditingCancelled;

  /// "Use my current location" action; the row is hidden when null.
  final Future<LocationSuggestion<T>?> Function()? onUseCurrentLocation;

  /// Receives what [search] or [onUseCurrentLocation] threw.
  final ValueChanged<Object>? onError;

  const LocationBar({
    super.key,
    required this.search,
    required this.onSelected,
    this.value,
    this.title,
    this.subtitle,
    this.hintText,
    this.alternativeHint,
    this.onEditingStarted,
    this.onEditingCancelled,
    this.onUseCurrentLocation,
    this.onError,
  });

  @override
  State<LocationBar<T>> createState() => _LocationBarState<T>();
}

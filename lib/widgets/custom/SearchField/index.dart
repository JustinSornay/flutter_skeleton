// index.dart
//
// SearchField — rounded search input: a leading search icon that turns into
// a Loader while loading, a focus border and glow animated through
// resolveMotion, and an optional accessible clear button. The caller owns the
// controller. State lives in view_model.dart, the tree in view.dart and the
// clear button in widgets/clear_button.dart.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";

part "view_model.dart";
part "view.dart";
part "widgets/clear_button.dart";

/// Rounded search text field with an animated focus state, an optional
/// loading spinner and an optional clear button.
///
/// - [controller]: owned by the caller. The widget listens to it (to show or
///   hide the clear button) and never disposes it. Swapping it for another
///   controller is supported.
/// - [focusNode]: optional. When null the widget creates its own node and
///   disposes it; a node passed by the caller is never disposed.
/// - [hintText]: placeholder, already localised by the host. Defaults to
///   `custom.search_field.hint` ("Rechercher…" / "Search…").
/// - [onChanged]: called on every keystroke.
/// - [onClear]: when non-null, a clear (×) button shows while the field has
///   text. The widget does not clear the controller itself: the caller clears
///   it (and re-runs its query if needed). The button is a [kMinTapTarget]
///   square announced as a button labelled `custom.search_field.clear`.
/// - [autofocus]: requests focus on mount.
/// - [loading]: swaps the leading search icon for a 16 dp [Loader].
///
/// The field is [kMinTapTarget] tall. Focus animates the border
/// (`cs.outlineVariant` → `cs.primary`) and a soft `cs.primary` glow over
/// `resolveMotion(context, kMotionShort)`, so reduced motion makes it instant.
///
/// Needs an `Overlay` ancestor (a routed page or a modal): the inner
/// [TextField] shows its selection handles and context menu there. The
/// widget adds no overlay of its own (no `Tooltip`).
final class SearchField extends StatefulWidget {
  /// Text controller owned by the caller.
  final TextEditingController controller;

  /// Optional focus node; an internal one is created when null.
  final FocusNode? focusNode;

  /// Placeholder; defaults to `custom.search_field.hint`.
  final String? hintText;

  /// Called on every keystroke.
  final ValueChanged<String>? onChanged;

  /// Shows the clear button while the field has text; the caller clears.
  final VoidCallback? onClear;

  /// Requests focus on mount.
  final bool autofocus;

  /// Replaces the search icon with a [Loader].
  final bool loading;

  const SearchField({
    super.key,
    required this.controller,
    this.hintText,
    this.focusNode,
    this.onChanged,
    this.onClear,
    this.autofocus = false,
    this.loading = false,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

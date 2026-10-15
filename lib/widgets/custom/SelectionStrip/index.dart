// index.dart
//
// SelectionStrip — compact full-width band that summarises the active
// selection or context ("● <prefix> <value> <detail> ...... [Edit]"). Purely
// presentational: the host formats every string and decides what the edit
// action opens through [SelectionStrip.onEdit]. The tree lives in view.dart.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "view.dart";

/// Full-width strip summarising the active selection, with an optional edit
/// action: `● <prefix> <value> <detail> ...... [Edit]`.
///
/// - Band: `cs.primary` at 8 % with a 1 dp `cs.outlineVariant` bottom
///   divider, 16 dp horizontal padding, at least [kMinTapTarget] tall.
/// - Leading dot: 8 dp `cs.primary` circle, decorative (not read).
/// - Text: one line, ellipsized as a whole so a long [value] uses all the
///   free width.
///   - [prefix]: `textTheme.labelSmall` w500, `cs.onSurfaceVariant`.
///   - [value]: `textTheme.labelMedium` w700, `cs.primary`.
///   - [detail]: `textTheme.labelSmall` w700, `cs.primary` at 85 %.
/// - Edit action (only when [onEdit] is set): underlined `labelSmall` w600
///   `cs.primary` link at the end of the row. Its hit area is at least
///   [kMinTapTarget] × [kMinTapTarget]; its label is one line, ellipsized
///   past 128 dp. Focus, hover and keyboard activation come from an
///   [InkWell] on the strip's own transparent [Material].
///
/// Accessibility: the strip is one semantics group whose label is the
/// visible text; the edit action is a child button labelled
/// [editSemanticsLabel] (default `custom.selection_strip.edit_semantics`,
/// "{action} : {value}", so the visible link text stays in the accessible
/// name).
///
/// Content strings are already localised (and numbers formatted) by the
/// host. The widget never navigates: [onEdit] does (open a picker sheet,
/// `context.go(...)`, …). Needs a bounded width; no `Overlay` ancestor is
/// needed.
final class SelectionStrip extends StatelessWidget with _ViewMixin {
  /// Main text, e.g. "Last 30 days".
  final String value;

  /// Muted lead-in before [value]. Null shows the built-in
  /// `custom.selection_strip.prefix` ("Affichage :" / "Viewing:"); an empty
  /// string hides it.
  final String? prefix;

  /// Secondary text after [value], already formatted by the host
  /// (e.g. "(12 items)", "(+2.7 %)"). Hidden when null or empty.
  final String? detail;

  /// Called when the edit action is tapped. Null hides the action and makes
  /// the strip a read-only context banner.
  final VoidCallback? onEdit;

  /// Visible text of the edit action. Null shows the built-in
  /// `custom.selection_strip.edit` ("Modifier" / "Change").
  final String? editLabel;

  /// Accessible label of the edit action. Null builds
  /// `custom.selection_strip.edit_semantics` from the visible edit text and
  /// [value].
  final String? editSemanticsLabel;

  const SelectionStrip({
    super.key,
    required this.value,
    this.prefix,
    this.detail,
    this.onEdit,
    this.editLabel,
    this.editSemanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

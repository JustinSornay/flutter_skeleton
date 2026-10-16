// index.dart
//
// EditableValueRow — compact read-only summary of a value the user already
// picked: an icon badge, a title, an optional subtitle and an "Edit" chip.
// Purely presentational: the host wraps it in an InkWell / card and decides
// what the tap does. The tree lives in view.dart, the chip in
// widgets/edit_chip.dart.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "view.dart";
part "widgets/edit_chip.dart";

/// Compact row showing a selected value with an edit affordance.
///
/// Renders: [icon] tinted badge · [title] + optional [subtitle] · a
/// "✏ Edit" chip.
///
/// The widget is purely presentational and has no gesture of its own: the
/// host owns the tap (clear the value, reopen a picker, enter edit mode…) by
/// wrapping the row in an [InkWell] or a card whose hit area is at least
/// [kMinTapTarget] tall. Wrap it with padding so the row plus padding
/// reaches that height.
///
/// - [icon]: shown in a 32×32 badge (`cs.primary` on `cs.primary` at 7 %).
/// - [title]: primary text, one line with an ellipsis, `cs.onSurface`.
/// - [subtitle]: secondary text, one line with an ellipsis,
///   `cs.onSurfaceVariant`. Hidden when null or empty.
/// - [subtitleItalic]: renders [subtitle] in italic (scientific names, codes…).
/// - [editLabel]: visible chip text. Defaults to
///   `custom.editable_value_row.edit` ("Modifier" / "Edit").
/// - [semanticsLabel]: accessible label of the chip (announced as a button).
///   Defaults to `custom.editable_value_row.edit_semantics`, filled with the
///   visible chip text and [title] ("Modifier : Bordeaux"), so the visible
///   text stays part of the accessible name. The chip's own text is excluded
///   from semantics so it is not announced twice.
///
/// Content strings ([title], [subtitle], [editLabel], [semanticsLabel]) are
/// already localised by the host. No `Overlay` ancestor is needed.
final class EditableValueRow extends StatelessWidget with _ViewMixin {
  /// Icon in the leading badge.
  final IconData icon;

  /// Primary text: one line, ellipsis.
  final String title;

  /// Secondary text: one line, ellipsis. Hidden when null or empty.
  final String? subtitle;

  /// Renders [subtitle] in italic.
  final bool subtitleItalic;

  /// Visible chip text; defaults to `custom.editable_value_row.edit`.
  final String? editLabel;

  /// Accessible label of the chip; defaults to
  /// `custom.editable_value_row.edit_semantics` ("{action} : {value}").
  final String? semanticsLabel;

  const EditableValueRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleItalic = false,
    this.editLabel,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

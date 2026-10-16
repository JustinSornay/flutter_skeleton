// index.dart
//
// ExplainerSheet — content for a modal or bottom sheet that explains a
// result: a title, up to maxItems toned contributing items (dot, label,
// optional caption, optional trailing value), a success-toned row when there
// is none, an optional badge slot and an optional "learn more" link. The tree
// lives in view.dart, the rows in widgets/. Value class: ExplainerItem.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "view.dart";
part "widgets/empty_row.dart";
part "widgets/item_row.dart";
part "widgets/tone_dot.dart";

/// One contributing item of an [ExplainerSheet].
@immutable
final class ExplainerItem {
  /// Row label, already localised by the host. Always shown, so the [tone]
  /// is never conveyed by colour alone.
  final String label;

  /// Colours the leading dot and [value] with the tone `foreground`.
  final StatusTone tone;

  /// Optional preformatted trailing text (e.g. "−12 %"), painted in the tone
  /// `foreground`. Hidden when null or empty.
  final String? value;

  /// Optional italic line under [label] (e.g. a source). Hidden when null or
  /// empty.
  final String? caption;

  const ExplainerItem({
    required this.label,
    required this.tone,
    this.value,
    this.caption,
  });
}

/// Content panel explaining a result, hosted in a modal bottom sheet or an
/// `AppModal`.
///
/// Renders, top to bottom:
/// - [title] (`textTheme.titleMedium`, w700, `cs.onSurface`, centred, header
///   semantics). Null → `custom.explainer_sheet.title`.
/// - the first [maxItems] of [items] in the given order (the host sorts
///   them), separated by `cs.outlineVariant` dividers. Each full-width row
///   shows an 8 dp dot in the item tone `foreground`, the label
///   (`bodyMedium`, w600, `cs.onSurface`), the optional italic caption under
///   it (`labelSmall`, `cs.onSurfaceVariant`) and the optional trailing value
///   (`labelMedium`, w700, tone `foreground`). Each row is one merged
///   semantics node ("label, caption, value").
/// - when [items] is empty, a single row with a success dot and [emptyLabel]
///   in the success `foreground` (null → `custom.explainer_sheet.empty`).
/// - [badge], centred under the list, when non-null.
/// - when [onLearnMore] is non-null, a centred [TextButton] link
///   (`cs.primary`, w600, at least [kMinTapTarget] tall) labelled
///   [learnMoreLabel] (null → `custom.explainer_sheet.learn_more`).
///
/// Content only: no drag handle, no background, no route handling. The host
/// mounts it with `showModalBottomSheet(showDragHandle: true, …)` or
/// `ModalProvider.show(AppModal(...))`, and closes it itself in
/// [onLearnMore] before navigating (e.g. `Navigator.of(sheetContext).pop()`
/// or `modalProvider.dismiss()`). The content scrolls when the available
/// height is too short.
///
/// Needs neither a `Material` nor an `Overlay` ancestor: the link's
/// [TextButton] brings its own `Material` for the ink, and there is no
/// tooltip or popup. Content strings are parameters, already localised by
/// the host.
final class ExplainerSheet extends StatelessWidget with _ViewMixin {
  /// Rows in display order. Only the first [maxItems] are rendered.
  final List<ExplainerItem> items;

  /// Maximum number of rows rendered (default 3, must be positive).
  final int maxItems;

  /// Sheet title. Null → `custom.explainer_sheet.title`.
  final String? title;

  /// Label of the success row shown when [items] is empty. Null →
  /// `custom.explainer_sheet.empty`.
  final String? emptyLabel;

  /// Optional widget centred under the list (e.g. a reliability badge).
  final Widget? badge;

  /// Link text. Null → `custom.explainer_sheet.learn_more`.
  final String? learnMoreLabel;

  /// Called once per link tap. The link is hidden when null.
  final VoidCallback? onLearnMore;

  const ExplainerSheet({
    super.key,
    required this.items,
    this.maxItems = 3,
    this.title,
    this.emptyLabel,
    this.badge,
    this.learnMoreLabel,
    this.onLearnMore,
  }) : assert(maxItems > 0, "maxItems must be positive");

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

// index.dart
//
// CollapsibleSectionCard — controlled accordion card for any content. The
// parent owns the open state; the card draws a header (optional icon tile,
// overline, title, collapsed-only subtitle, always-visible summary slot and
// a rotating chevron) and cross-fades the body in under a divider. The card
// and body live in view.dart, the header in widgets/section_header.dart.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "view.dart";
part "widgets/section_header.dart";

/// Controlled accordion card: the parent owns [isOpen] and flips it in
/// [onToggle].
///
/// Card: `Card(elevation: 0)`, `cs.surfaceContainerLowest`, radius 24 and a
/// `cs.outlineVariant` border.
///
/// Header (at least [kMinTapTarget] tall, one button semantics node whose
/// expanded state follows [isOpen]):
/// - optional leading [icon] in a 32 dp tile (`cs.primary` at 10 % behind a
///   16 dp `cs.primary` icon);
/// - optional [overline] in uppercase (`labelSmall` w700,
///   `cs.onSurfaceVariant`); screen readers get the original casing;
/// - [title] (`titleSmall` w800, `cs.onSurface`, one line, ellipsis) followed,
///   only while collapsed, by `· subtitle` (`titleSmall` w500, `cs.primary`,
///   one line, ellipsis);
/// - optional [summary] widget, kept in both states so the key result reads
///   without expanding;
/// - a `cs.onSurfaceVariant` chevron that turns half a turn when open.
///
/// Body: when [isOpen], a `cs.outlineVariant` divider then [body], aligned
/// to the start edge, cross-faded in with `AnimatedCrossFade`. The hidden
/// body is neither hit-testable nor in the semantics tree.
///
/// Motion: the chevron rotation and the cross-fade use
/// `resolveMotion(context, kMotionShort)` with `Curves.easeInOut`. Under
/// reduced motion the rotation is instant and the body is shown or hidden
/// at once (kept mounted offstage while hidden, like the animated path).
/// Switching the reduced-motion setting while the card is mounted rebuilds
/// [body] from scratch (its local state is lost), so hosts should keep
/// important state above the card.
///
/// Content strings ([title], [overline], [subtitle]) are already localised
/// by the host; the only built-in strings are the screen-reader tap hints
/// `custom.collapsible_section_card.expand` / `.collapse`. The widget uses
/// no tooltip or other overlay: no `Overlay` ancestor is needed.
final class CollapsibleSectionCard extends StatelessWidget with _ViewMixin {
  /// Main heading (always visible).
  final String title;

  /// Whether [body] is expanded. Owned by the parent.
  final bool isOpen;

  /// Called when the header is tapped; the parent toggles [isOpen].
  final VoidCallback onToggle;

  /// Content shown under the divider when [isOpen] is true.
  final Widget body;

  /// Optional leading icon, rendered in a 32 dp tinted tile. Null shows no
  /// tile.
  final IconData? icon;

  /// Optional short label above the title, rendered uppercase (for example
  /// "Step 1"). Hidden when null or empty.
  final String? overline;

  /// Optional inline context next to the title ("Title · subtitle"), shown
  /// only while collapsed. Hidden when null or empty.
  final String? subtitle;

  /// Optional widget kept in the header in both states (badge, count chip…).
  final Widget? summary;

  const CollapsibleSectionCard({
    super.key,
    required this.title,
    required this.isOpen,
    required this.onToggle,
    required this.body,
    this.icon,
    this.overline,
    this.subtitle,
    this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

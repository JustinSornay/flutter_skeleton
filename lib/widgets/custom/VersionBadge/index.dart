// index.dart
//
// VersionBadge — outlined pill naming a version (of a model, dataset, API,
// document revision, …) and whether it is the current one. When the host
// passes [VersionBadgeDetails] and onShowDetails, a tap builds a details
// panel (widgets/details_panel.dart) and hands it to the host, which mounts
// it. The pill is a PillBadge; the tree lives in view.dart.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/PillBadge/index.dart";

part "view.dart";
part "widgets/details_panel.dart";

/// Size of a [VersionBadge].
enum VersionBadgeSize {
  /// Dense pill: 8 / 4 dp padding.
  compact,

  /// Regular pill: 12 / 8 dp padding.
  large,
}

/// Text content and action of the panel built by a [VersionBadge] tap.
@immutable
final class VersionBadgeDetails {
  /// Panel heading (18 / w600), e.g. "Computed with release 2.4".
  final String title;

  /// Explanatory paragraph (14, line height 1.4).
  final String body;

  /// Warning callout (13, warning-tone container fill, radius 8), shown only
  /// when the badge is not current. Null or empty → no callout.
  final String? outdatedNotice;

  /// Label of the "learn more" button. Null or empty →
  /// `custom.version_badge.learn_more`.
  final String? learnMoreLabel;

  /// Called by the "learn more" button. Null → no button.
  final VoidCallback? onLearnMore;

  const VersionBadgeDetails({
    required this.title,
    required this.body,
    this.outdatedNotice,
    this.learnMoreLabel,
    this.onLearnMore,
  });
}

/// Outlined pill: a leading icon and [label], coloured by [isCurrent].
///
/// - Current: `StatusTone.primary` foreground (`cs.primary`) and
///   [Icons.verified_outlined]. Outdated: `StatusTone.neutral` foreground
///   (`cs.onSurfaceVariant`) and [Icons.history]. The state is carried by the
///   icon and the accessible label, never by colour alone.
/// - Rendered as `PillBadge(outlined: true, dense: size == compact)`: 11 sp /
///   w700 label on one line, 14 dp icon, `cs.surfaceContainerHigh` fill and a
///   1 dp `cs.outlineVariant` border.
///
/// Tappable only when both [details] and [onShowDetails] are set. A tap then
/// calls [onShowDetails] once with a ready-built panel (title, body, the
/// outdated notice when not current, the optional "learn more" button),
/// which resolves its theme where the host mounts it, typically:
///
/// ```dart
/// onShowDetails: (Widget panel) {
///   final ModalProvider modal = context.read<ModalProvider>();
///   modal.show(AppModal(isVisible: true, onDismiss: modal.dismiss, child: panel));
/// },
/// ```
///
/// The panel draws no drag handle, so it also fits
/// `showModalBottomSheet(showDragHandle: true, …)`. When tappable, the hit
/// area grows to [kMinTapTarget] (48 × 48) with the pill centred inside it,
/// and the semantics node is a button.
///
/// Accessibility: one semantics node labelled [semanticsLabel], or by default
/// "[label], " followed by `custom.version_badge.current` /
/// `custom.version_badge.outdated`.
///
/// No tooltip or other overlay, so no `Overlay` ancestor is needed. Content
/// strings ([label], [VersionBadgeDetails]) are already localised by the host.
final class VersionBadge extends StatelessWidget with _ViewMixin {
  /// Visible text, already formatted and localised (e.g. "v2.4").
  final String label;

  /// Whether this is the current version (see the class doc for the cues).
  final bool isCurrent;

  /// Pill padding: [VersionBadgeSize.compact] (default) or
  /// [VersionBadgeSize.large].
  final VersionBadgeSize size;

  /// Content of the details panel. Null → the badge is not tappable.
  final VersionBadgeDetails? details;

  /// Receives the built details panel on tap; the host mounts it. Null → the
  /// badge is not tappable.
  final void Function(Widget panel)? onShowDetails;

  /// Screen-reader label. Null or empty → "[label], current / outdated".
  final String? semanticsLabel;

  const VersionBadge({
    super.key,
    required this.label,
    this.isCurrent = true,
    this.size = VersionBadgeSize.compact,
    this.details,
    this.onShowDetails,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

// index.dart
//
// QuotaBar — compact "used / limit" meter for any capped resource: a title
// with a two-tone count above a 5 dp pill bar, and a "limit reached" row with
// an optional call to action. A null limit collapses it to one
// "title … unlimited" row. Pure presentation: numbers, labels and the action
// come from parameters; the derived state lives here, the tree in view.dart.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/widgets/constants.dart";

part "view.dart";

/// Compact quota meter for a capped resource (saved items, seats, storage
/// slots, daily requests, uploads…).
///
/// Limited mode ([limit] set):
/// - Header row: [title] on the left (13/w700, `cs.onSurface`, one line with
///   ellipsis) and the count on the right: [displayedUsed] (13/w800, [tone]
///   foreground) followed by `/limit` (13/w400, `cs.onSurfaceVariant`).
/// - Bar: 8 dp below the header, 5 dp thick, spanning the available width
///   (the parent must bound it). Shared bar tokens: track
///   `cs.surfaceContainerHighest`, radius 999, fill = [tone] foreground.
/// - Tone: [StatusTone.primary] below [warningThreshold],
///   [StatusTone.warning] from it, [StatusTone.danger] at the limit. The
///   colour is always paired with the visible count text.
/// - At the limit: a row below the bar with [limitReachedLabel] (12/w600,
///   danger foreground, announced as a live region) and, when both
///   [actionLabel] and [onAction] are set, an underlined text button
///   (12/w700, `cs.primary`, ≥ 48×48 dp target) calling [onAction].
///
/// Unlimited mode ([limit] null): a single row with [title] on the left and
/// [unlimitedLabel] (12/w600, `cs.primary`) on the right; no count, bar or
/// footer. Each side takes at most half the row and ellipsizes on one line.
///
/// Accessibility: the header and bar (or the unlimited row) form one
/// semantics node whose label is [title] and whose value is
/// `custom.quota_bar.usage_value` (or [unlimitedLabel]).
///
/// Overlay-free (no tooltip, no menu, no animation): it needs no `Overlay`
/// ancestor. Content strings ([title], [actionLabel] and the overrides) are
/// already localised by the host.
final class QuotaBar extends StatelessWidget with _ViewMixin {
  /// Header label, also the semantics label of the meter.
  final String title;

  /// Current consumption; clamped to `[0, limit]` for display.
  final int used;

  /// Maximum allowed. Null renders the unlimited row (no bar, no footer);
  /// 0 renders an empty bar at the limit.
  final int? limit;

  /// Ratio in `[0, 1]` from which the bar and the count use
  /// [StatusTone.warning].
  final double warningThreshold;

  /// Text of the "limit reached" row. Null → `custom.quota_bar.limit_reached`.
  final String? limitReachedLabel;

  /// Text of the unlimited row. Null → `custom.quota_bar.unlimited`.
  final String? unlimitedLabel;

  /// Label of the call to action shown at the limit (e.g. "Upgrade",
  /// "Free up space"). The action renders only with [onAction].
  final String? actionLabel;

  /// Called when the call to action is tapped. The action renders only with
  /// [actionLabel].
  final VoidCallback? onAction;

  const QuotaBar({
    super.key,
    required this.title,
    required this.used,
    this.limit,
    this.warningThreshold = 0.8,
    this.limitReachedLabel,
    this.unlimitedLabel,
    this.actionLabel,
    this.onAction,
  }) : assert(limit == null || limit >= 0),
       assert(warningThreshold >= 0 && warningThreshold <= 1);

  /// True when [limit] is null.
  bool get isUnlimited => limit == null;

  /// [used] clamped to `[0, limit]` (to `0..` when unlimited).
  int get displayedUsed {
    final int floor = used < 0 ? 0 : used;
    final int? max = limit;
    return max != null && floor > max ? max : floor;
  }

  /// Filled share of the bar in `[0, 1]`; 0 when unlimited or when
  /// [limit] is 0.
  double get ratio {
    final int? max = limit;
    if (max == null || max == 0) return 0;
    return displayedUsed / max;
  }

  /// True when the quota is used up (always with a [limit] of 0).
  bool get isAtLimit {
    final int? max = limit;
    return max != null && displayedUsed >= max;
  }

  /// True from [warningThreshold] on, limit included.
  bool get isWarning => isAtLimit || (!isUnlimited && ratio >= warningThreshold);

  /// Tone of the count, the bar fill and the "limit reached" text.
  StatusTone get tone {
    if (isAtLimit) return StatusTone.danger;
    if (isWarning) return StatusTone.warning;
    return StatusTone.primary;
  }

  /// True when the call to action is rendered.
  bool get showAction => isAtLimit && actionLabel != null && onAction != null;

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

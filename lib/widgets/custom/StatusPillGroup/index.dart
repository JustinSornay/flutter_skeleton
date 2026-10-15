// index.dart
//
// StatusPillGroup — wrapping row of StatusPill widgets loaded once through an
// injected async callback: a small Loader while waiting, one neutral
// "unavailable" pill when the load fails, nothing for an empty list.
//
// StatusPillGroupItem (the content of one pill, plus the toneFromThresholds
// helper) is declared here, the load lifecycle lives in view_model.dart and
// the tree in view.dart.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/theme/status_tones.dart";
import "package:flutter_skeleton/utils/load_state.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";
import "package:flutter_skeleton/widgets/custom/StatusPill/index.dart";
import "package:logger/logger.dart";

part "view_model.dart";
part "view.dart";

/// Content of one pill of a [StatusPillGroup], built by the host from its own
/// data (labels already localised and formatted).
@immutable
final class StatusPillGroupItem {
  /// Visible text, already localised and formatted (e.g. "99.8 % uptime").
  /// The text always accompanies the tone colour. Empty → the item is
  /// skipped.
  final String label;

  /// Optional 14 dp leading icon. Null → no icon. Pass `tone.icon` for the
  /// tone's own glyph.
  final IconData? icon;

  /// Semantic tone of the pill (`onContainer` on `container` from
  /// [StatusTones]).
  final StatusTone tone;

  /// Screen-reader label. Null or empty → [label].
  final String? semanticsLabel;

  const StatusPillGroupItem({
    required this.label,
    this.icon,
    this.tone = StatusTone.neutral,
    this.semanticsLabel,
  });

  /// Picks [StatusTone.success], [StatusTone.warning] or [StatusTone.danger]
  /// for [value] against two thresholds.
  ///
  /// - [higherIsBetter] true: `value >= success` → success, `value >= warning`
  ///   → warning, else danger (asserts `success >= warning`).
  /// - [higherIsBetter] false: `value < success` → success, `value < warning`
  ///   → warning, else danger (asserts `success <= warning`).
  /// - A NaN value → [StatusTone.neutral] (unknown, never a false alarm).
  ///
  /// Example: a rate in percent `toneFromThresholds(rate, success: 99.5,
  /// warning: 95)`; a duration in ms `toneFromThresholds(ms, success: 300,
  /// warning: 1000, higherIsBetter: false)`.
  static StatusTone toneFromThresholds(
    double value, {
    required double success,
    required double warning,
    bool higherIsBetter = true,
  }) {
    assert(
      higherIsBetter ? success >= warning : success <= warning,
      "success must be the better threshold of the two",
    );
    if (value.isNaN) return StatusTone.neutral;
    if (higherIsBetter) {
      if (value >= success) return StatusTone.success;
      return value >= warning ? StatusTone.warning : StatusTone.danger;
    }
    if (value < success) return StatusTone.success;
    return value < warning ? StatusTone.warning : StatusTone.danger;
  }
}

/// Wrapping row of status pills (health, quota, sync or job summaries) whose
/// content is loaded once by the host.
///
/// - [load]: fetches the items once, when the state is created. The host
///   does the fetching and the computing, and builds each
///   [StatusPillGroupItem] (label, icon, tone). To reload with new
///   parameters, give the widget a `ValueKey` holding every parameter that
///   should trigger a refetch (same contract as `Listing`): a new [load]
///   closure alone never reloads.
/// - While loading: a `Loader` (16 dp, announced as `common.loading`)
///   centred in a 32 dp slot, the height of one pill row.
/// - Loaded: every item as a [StatusPill] (default padding), in order, in a
///   [Wrap] with 8 dp spacing and run spacing; items with an empty label are
///   skipped. An empty list renders `SizedBox.shrink()`.
/// - Load failure (thrown synchronously or asynchronously): the error is
///   logged with `Logger().e` and never escapes the widget; one neutral pill
///   with `Icons.error_outline` shows [errorLabel], else
///   `custom.status_pill_group.unavailable`. It is a live region, so screen
///   readers announce it.
///
/// No tooltip and no overlay, so no `Overlay` ancestor is needed: the widget
/// works anywhere in the tree, including `Layout`.
final class StatusPillGroup extends StatefulWidget {
  /// Fetches the pills. Called once per state.
  final Future<List<StatusPillGroupItem>> Function() load;

  /// Text of the failure pill. Null → `custom.status_pill_group.unavailable`;
  /// empty → nothing is shown on failure.
  final String? errorLabel;

  const StatusPillGroup({
    super.key,
    required this.load,
    this.errorLabel,
  });

  @override
  State<StatusPillGroup> createState() => _StatusPillGroupState();
}

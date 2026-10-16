// view.dart
//
// _ViewMixin — tree of StatusPillGroup, picked by an exhaustive switch on the
// load state: a centred Loader in a one-row slot, a live-region neutral
// failure pill, nothing for an empty list, or the items as StatusPill widgets
// in a Wrap (items with an empty label are skipped, so they leave no gap).
// The failure pill sits in a Wrap too, so it keeps its own width like the
// loaded pills even under a tight parent width.

part of "index.dart";

/// Height of the loading slot: one default StatusPill row at the default
/// text scale (32 dp).
const double _rowHeight = kDefaultPadding * 4;

/// Diameter of the loading indicator (16 dp).
const double _loaderSize = kDefaultPadding * 2;

mixin _ViewMixin {
  Widget render(BuildContext context, _StatusPillGroupState state) {
    return switch (state.items) {
      Idle<List<StatusPillGroupItem>>() || Loading<List<StatusPillGroupItem>>() => const SizedBox(
          height: _rowHeight,
          child: Center(child: Loader(size: _loaderSize)),
        ),
      LoadError<List<StatusPillGroupItem>>() => Wrap(
          children: <Widget>[
            Semantics(
              liveRegion: true,
              child: StatusPill(
                label: state.widget.errorLabel ?? "custom.status_pill_group.unavailable".tr(),
                icon: Icons.error_outline,
              ),
            ),
          ],
        ),
      Loaded<List<StatusPillGroupItem>>(:final List<StatusPillGroupItem> data) when data.isEmpty =>
        const SizedBox.shrink(),
      Loaded<List<StatusPillGroupItem>>(:final List<StatusPillGroupItem> data) => Wrap(
          spacing: kDefaultPadding,
          runSpacing: kDefaultPadding,
          children: <Widget>[
            for (final StatusPillGroupItem item in data)
              if (item.label.isNotEmpty)
                StatusPill(
                  label: item.label,
                  icon: item.icon,
                  tone: item.tone,
                  semanticsLabel: item.semanticsLabel,
                ),
          ],
        ),
    };
  }
}

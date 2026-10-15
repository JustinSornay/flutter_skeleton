// view.dart
//
// Tree of SegmentedPicker: the optional upper-cased caption, then the
// tinted track (a Material for ink) holding one _Segment per option
// (widgets/segment.dart). Resolves each option's availability and tap
// callback. Colours come from the ColorScheme only.

part of "index.dart";

/// Caption font size (small uppercase label above the track).
const double _captionFontSize = 9;

/// Caption letter spacing.
const double _captionLetterSpacing = 1.2;

/// Inner padding of the track around the segments.
const double _trackPadding = kDefaultPadding / 2;

/// Corner radius of the track.
const double _trackRadius = 8;

mixin _ViewMixin<T> {
  Widget render(BuildContext context, SegmentedPicker<T> widget) {
    assert(widget.options.isNotEmpty, "SegmentedPicker needs at least one option");
    final String? label = widget.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (label != null) ...<Widget>[
          _caption(context, label),
          const SizedBox(height: kDefaultPadding),
        ],
        _track(context, widget),
      ],
    );
  }

  /// Small muted caption, upper-cased.
  Widget _caption(BuildContext context, String label) {
    final ThemeData theme = Theme.of(context);

    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        fontSize: _captionFontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: _captionLetterSpacing,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Tinted rounded track; IntrinsicHeight gives every segment the height of
  /// the tallest one (at least kMinTapTarget) under any text scale.
  Widget _track(BuildContext context, SegmentedPicker<T> widget) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(_trackRadius),
      child: Padding(
        padding: const EdgeInsets.all(_trackPadding),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final ChoiceOption<T> option in widget.options)
                Expanded(child: _segment(widget, option)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _segment(SegmentedPicker<T> widget, ChoiceOption<T> option) {
    final _Availability availability = _availabilityOf(widget, option);

    return _Segment(
      label: option.label,
      description: option.description,
      semanticsLabel: option.semanticsLabel,
      selected: option.value == widget.selected,
      availability: availability,
      lockedIcon: widget.lockedIcon,
      onTap: _onTapOf(widget, option.value, availability),
    );
  }

  /// Disabled options win over locks: they ignore taps entirely.
  _Availability _availabilityOf(SegmentedPicker<T> widget, ChoiceOption<T> option) {
    if (!option.enabled) return _Availability.disabled;
    final Set<T>? enabledValues = widget.enabledValues;
    if (enabledValues != null && !enabledValues.contains(option.value)) {
      return _Availability.locked;
    }
    return _Availability.selectable;
  }

  /// Null when the segment is inert (disabled, or locked without onLockedTap).
  VoidCallback? _onTapOf(SegmentedPicker<T> widget, T value, _Availability availability) {
    final ValueChanged<T>? onLockedTap = widget.onLockedTap;

    return switch (availability) {
      _Availability.selectable => () => widget.onSelected(value),
      _Availability.locked => onLockedTap == null ? null : () => onLockedTap(value),
      _Availability.disabled => null,
    };
  }
}

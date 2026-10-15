// view.dart
//
// Tree of ExpandableGroupTile: the bordered card, the header (widgets/
// group_header.dart) and, in accordion mode, the animated body with a divider
// and one _EntryRow per entry (widgets/entry_row.dart). Colours come from the
// ColorScheme only.

part of "index.dart";

/// Card corner radius, shared with CollapsibleSectionCard.
const double _cardRadius = 24;

mixin _ViewMixin<T> {
  Widget render(BuildContext context, ExpandableGroupTile<T> widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _GroupHeader(
            title: widget.title,
            subtitle: _subtitle(widget),
            subtitleSemanticsLabel: _usesEntrySubtitle(widget) ? widget.entries.first.semanticsLabel : null,
            icon: widget.icon,
            expandable: widget.expandable,
            isOpen: widget.isOpen,
            onTap: _headerTap(widget),
          ),
          if (widget.expandable) _body(context, widget, cs),
        ],
      ),
    );
  }

  /// Whether the header's second line falls back to the first entry (direct
  /// mode, no explicit subtitle, at least one entry).
  bool _usesEntrySubtitle(ExpandableGroupTile<T> widget) {
    return widget.subtitle == null && !widget.expandable && widget.entries.isNotEmpty;
  }

  /// Explicit subtitle, else the first entry's label in direct mode.
  String? _subtitle(ExpandableGroupTile<T> widget) {
    return _usesEntrySubtitle(widget) ? widget.entries.first.label : widget.subtitle;
  }

  /// Toggle in accordion mode; select the first entry in direct mode, or
  /// nothing when there is no enabled first entry.
  VoidCallback? _headerTap(ExpandableGroupTile<T> widget) {
    if (widget.expandable) return widget.onToggle;
    if (widget.entries.isEmpty || !widget.entries.first.enabled) return null;
    final T value = widget.entries.first.value;
    return () => widget.onSelected(value);
  }

  /// Divider + entry rows when open, an empty full-width box when closed.
  /// Under reduced motion the body is swapped without AnimatedSize, which
  /// asserts when its duration is zero.
  Widget _body(BuildContext context, ExpandableGroupTile<T> widget, ColorScheme cs) {
    final Duration duration = resolveMotion(context, kMotionShort);
    final Widget content = widget.isOpen
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Divider(height: 1, thickness: 1, color: cs.outlineVariant),
              for (final ChoiceOption<T> entry in widget.entries)
                _EntryRow<T>(entry: entry, onSelected: widget.onSelected),
            ],
          )
        : const SizedBox(width: double.infinity);
    if (duration == Duration.zero) return content;

    return AnimatedSize(
      duration: duration,
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}

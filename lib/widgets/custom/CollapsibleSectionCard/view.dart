// view.dart
//
// Tree of CollapsibleSectionCard: the bordered card, the header
// (widgets/section_header.dart) and the body cross-faded in under a divider.
// Colours come from the ColorScheme only.

part of "index.dart";

/// Card corner radius.
const double _cardRadius = 24;

mixin _ViewMixin {
  Widget render(BuildContext context, CollapsibleSectionCard widget) {
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
        // Stretch gives the body slot the card's full width even while the
        // body is closed or collapsing, so the body never relayouts at width
        // 0 and the reveal does not grow from the centre.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SectionHeader(
            title: widget.title,
            isOpen: widget.isOpen,
            onToggle: widget.onToggle,
            icon: widget.icon,
            overline: widget.overline,
            subtitle: widget.subtitle,
            summary: widget.summary,
          ),
          _body(context, widget, cs),
        ],
      ),
    );
  }

  /// Empty box when closed; divider + padded body when open. Under reduced
  /// motion the body is swapped without AnimatedCrossFade, whose inner
  /// AnimatedSize asserts when its duration is zero; the hidden body stays
  /// mounted (offstage) so its state survives, as in the animated path.
  /// Flipping reduced motion while mounted swaps the wrapper type, so the
  /// body subtree is rebuilt then (documented on the class).
  Widget _body(BuildContext context, CollapsibleSectionCard widget, ColorScheme cs) {
    final Duration duration = resolveMotion(context, kMotionShort);
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Divider(height: 1, thickness: 1, color: cs.outlineVariant),
        Padding(
          // The divider already separates the body: a smaller top inset
          // keeps the content close to the header.
          padding: const EdgeInsets.fromLTRB(
            kDefaultPadding * 2,
            kDefaultPadding,
            kDefaultPadding * 2,
            kDefaultPadding * 2,
          ),
          child: widget.body,
        ),
      ],
    );
    if (duration == Duration.zero) {
      return Visibility(visible: widget.isOpen, maintainState: true, child: content);
    }

    return AnimatedCrossFade(
      duration: duration,
      sizeCurve: Curves.easeInOut,
      crossFadeState: widget.isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: const SizedBox.shrink(),
      secondChild: content,
    );
  }
}

// view.dart
//
// Tree of SectionBlock: the header row (decorative index badge + title /
// caption column with a single header semantics node) followed by the
// content child. Colours come from the ColorScheme only.

part of "index.dart";

/// Minimum diameter of the index badge at the default text scale.
const double _badgeMinSize = 30;

/// Horizontal inner padding of the badge, so long labels never touch its edge.
const EdgeInsets _badgePadding = EdgeInsets.symmetric(horizontal: kDefaultPadding / 2);

/// Gap between the badge and the title column (12 dp).
const double _badgeGap = kDefaultPadding * 1.5;

/// Gap between the title and the caption (4 dp).
const double _captionGap = kDefaultPadding / 2;

/// Gap between the header row and the content child (16 dp).
const double _childGap = kDefaultPadding * 2;

/// Line height of the caption paragraph.
const double _captionHeight = 1.5;

mixin _ViewMixin {
  Widget render(BuildContext context, SectionBlock widget) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ExcludeSemantics(child: _badge(context, widget)),
            const SizedBox(width: _badgeGap),
            Expanded(child: _heading(context, widget)),
          ],
        ),
        const SizedBox(height: _childGap),
        widget.child,
      ],
    );
  }

  /// Primary-filled badge: a circle for short labels, a stadium for longer ones.
  /// The minimum diameter follows the text scale so short labels stay round.
  Widget _badge(BuildContext context, SectionBlock widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double minSize = MediaQuery.textScalerOf(context).scale(_badgeMinSize);
    return Container(
      constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
      padding: _badgePadding,
      decoration: ShapeDecoration(color: cs.primary, shape: const StadiumBorder()),
      alignment: Alignment.center,
      child: Text(
        widget.indexLabel,
        style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w800),
      ),
    );
  }

  /// Title (single header node `"<index>. <title>"`) and the optional caption.
  Widget _heading(BuildContext context, SectionBlock widget) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? caption = widget.caption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          container: true,
          header: true,
          label: "${widget.indexLabel}. ${widget.title}",
          excludeSemantics: true,
          child: Text(
            widget.title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface),
          ),
        ),
        if (caption != null) ...<Widget>[
          const SizedBox(height: _captionGap),
          Text(
            caption,
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: _captionHeight),
          ),
        ],
      ],
    );
  }
}

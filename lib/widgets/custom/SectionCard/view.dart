// view.dart
//
// Tree of SectionCard: a clipped panel holding a transparent Material (ink
// surface for the rows), the header-semantics title, a hairline divider and
// the caller's rows; the border is painted above them. Colours come from the
// ColorScheme only.

part of "index.dart";

/// Corner radius of the panel.
const double _cardRadius = 12;

/// Width of the panel border; the content is inset by the same amount.
const double _borderWidth = 1;

/// Title padding: 16 dp on the top and sides, 12 dp above the divider.
const EdgeInsets _titlePadding = EdgeInsets.fromLTRB(
  kDefaultPadding * 2,
  kDefaultPadding * 2,
  kDefaultPadding * 2,
  kDefaultPadding * 1.5,
);

/// Tracking of the section label.
const double _titleLetterSpacing = 1.4;

mixin _ViewMixin {
  Widget render(BuildContext context, SectionCard widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(_borderWidth),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      // Foreground, so row fills and ink never cover the rounded corners.
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant, width: _borderWidth),
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        animationDuration: resolveMotion(context, kThemeChangeDuration),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _title(context, widget.title),
            const Divider(height: 1),
            ...widget.children,
          ],
        ),
      ),
    );
  }

  /// Section label exposed as a semantic header.
  Widget _title(BuildContext context, String title) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      container: true,
      header: true,
      child: Padding(
        padding: _titlePadding,
        child: Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: _titleLetterSpacing,
          ),
        ),
      ),
    );
  }
}

// view.dart
//
// Tree of ContextHeader: icon + (title | skeleton | nothing) over the
// subtitle, an optional 48 dp change link at the end, and a divider below.

part of "index.dart";

/// Size of the leading icon.
const double _iconSize = 22;

/// Gap between the title and the subtitle.
const double _titleGap = 2;

/// Font size of the title.
const double _titleFontSize = 18;

/// Dimensions of the title placeholder.
const double _skeletonWidth = 120;
const double _skeletonHeight = 14;

/// Corner radius of the title placeholder (text-line convention).
const double _skeletonRadius = 4;

/// Corner radius of the link's ink splash.
const double _linkRadius = 4;

mixin _ViewMixin {
  Widget render(BuildContext context, ContextHeader widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final VoidCallback? onChange = widget.onChange;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        kDefaultPadding * 2,
        kDefaultPadding,
        kDefaultPadding * 2,
        0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(widget.icon, size: _iconSize, color: cs.primary),
              const SizedBox(width: kDefaultPadding),
              Expanded(child: _texts(context, widget)),
              if (onChange != null) _link(context, widget, onChange),
            ],
          ),
          const SizedBox(height: kDefaultPadding),
          const Divider(height: 1),
        ],
      ),
    );
  }

  /// Title (or its placeholder) over the subtitle.
  Widget _texts(BuildContext context, ContextHeader widget) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? title = widget.title;
    final TextStyle subtitleStyle = (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: cs.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (title == null) ...<Widget>[
          _placeholder(context),
          const SizedBox(height: _titleGap),
        ] else if (title.isNotEmpty) ...<Widget>[
          _title(context, title),
          const SizedBox(height: _titleGap),
        ],
        Text(widget.subtitle, style: subtitleStyle),
      ],
    );
  }

  /// Style of the title, shared with the placeholder so both take the same
  /// line height.
  TextStyle _titleStyle(ThemeData theme) {
    return (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontSize: _titleFontSize,
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurface,
    );
  }

  Widget _title(BuildContext context, String title) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _titleStyle(Theme.of(context)),
    );
  }

  /// Pulsing text-line placeholder, centred in a slot one title line tall
  /// (measured with the title's style and the ambient text scaler, as the
  /// Text would lay it out), so the subtitle keeps its position when the
  /// title arrives. Under reduced motion the block is static and
  /// SkeletonPulse is not mounted, so its repeating controller never runs.
  Widget _placeholder(BuildContext context) {
    const Widget block = SkeletonBlock(
      width: _skeletonWidth,
      height: _skeletonHeight,
      borderRadius: _skeletonRadius,
    );
    final TextPainter painter = TextPainter(
      text: TextSpan(style: DefaultTextStyle.of(context).style.merge(_titleStyle(Theme.of(context)))),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    final double lineHeight = painter.preferredLineHeight;
    painter.dispose();
    return Semantics(
      label: "custom.context_header.loading".tr(),
      child: SizedBox(
        height: lineHeight,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: MediaQuery.disableAnimationsOf(context) ? block : const SkeletonPulse(child: block),
        ),
      ),
    );
  }

  /// Trailing text link with a 48 × 48 minimum hit area. The visible text is
  /// excluded (not the InkWell) so the node keeps its tap action while
  /// carrying a single label.
  Widget _link(BuildContext context, ContextHeader widget, VoidCallback onChange) {
    final ThemeData theme = Theme.of(context);
    final String label = widget.changeLabel ?? "custom.context_header.change".tr();
    final TextStyle style = (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
      color: theme.colorScheme.primary,
    );

    return Semantics(
      container: true,
      button: true,
      label: widget.changeSemanticsLabel ?? label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onChange,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(_linkRadius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: kMinTapTarget,
              minHeight: kMinTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
              child: Center(
                // Size to the text (the Row and Column give unbounded
                // constraints); the 48 dp minimum then centres it.
                widthFactor: 1,
                heightFactor: 1,
                child: ExcludeSemantics(child: Text(label, style: style)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// view.dart
//
// Tree of ContextHeader: icon + (title | skeleton | nothing) over the
// subtitle, an optional 48 dp change link at the end (capped in width and
// level with the first text line), and a divider below.

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

/// Largest share of the row the change link may take; a longer label ends
/// with an ellipsis and the title column keeps the rest.
const double _linkMaxWidthFactor = 0.4;

mixin _ViewMixin {
  Widget render(BuildContext context, ContextHeader widget) {
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
          if (onChange == null)
            _row(context, widget, null)
          else
            // Only a header with a link reads its width (to cap the link), so
            // a header without one still reports intrinsic sizes.
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double maxLinkWidth = math.max(kMinTapTarget, constraints.maxWidth * _linkMaxWidthFactor);
                return _row(context, widget, _link(context, widget, onChange, maxLinkWidth));
              },
            ),
          const SizedBox(height: kDefaultPadding),
          const Divider(height: 1),
        ],
      ),
    );
  }

  /// Icon, then the texts, then the optional trailing [link].
  Widget _row(BuildContext context, ContextHeader widget, Widget? link) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(widget.icon, size: _iconSize, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: kDefaultPadding),
        Expanded(child: _texts(context, widget)),
        ?link,
      ],
    );
  }

  /// Title (or its placeholder) over the subtitle.
  Widget _texts(BuildContext context, ContextHeader widget) {
    final String? title = widget.title;

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
        Text(widget.subtitle, style: _subtitleStyle(Theme.of(context))),
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

  TextStyle _subtitleStyle(ThemeData theme) {
    return (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  TextStyle _linkStyle(ThemeData theme) {
    return (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
      color: theme.colorScheme.primary,
    );
  }

  /// Height of one line of [style] as a Text here lays it out (ambient
  /// default text style and text scaler).
  double _lineHeight(BuildContext context, TextStyle style) {
    final TextPainter painter = TextPainter(
      text: TextSpan(style: DefaultTextStyle.of(context).style.merge(style)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    );
    final double height = painter.preferredLineHeight;
    painter.dispose();
    return height;
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
  /// (measured as the Text would lay it out), so the subtitle keeps its
  /// position when the title arrives. Under reduced motion the block is
  /// static and SkeletonPulse is not mounted, so its repeating controller
  /// never runs.
  Widget _placeholder(BuildContext context) {
    const Widget block = SkeletonBlock(
      width: _skeletonWidth,
      height: _skeletonHeight,
      borderRadius: _skeletonRadius,
    );
    return Semantics(
      label: "custom.context_header.loading".tr(),
      child: SizedBox(
        height: _lineHeight(context, _titleStyle(Theme.of(context))),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: MediaQuery.disableAnimationsOf(context) ? block : const SkeletonPulse(child: block),
        ),
      ),
    );
  }

  /// Trailing text link with a 48 × 48 minimum hit area, at most
  /// [maxWidth] wide (one line, ellipsis). The label is centred on the first
  /// text line (the title slot, or the subtitle when the title is empty).
  /// The visible text is excluded (not the InkWell) so the node keeps its tap
  /// action while carrying a single, complete label.
  Widget _link(BuildContext context, ContextHeader widget, VoidCallback onChange, double maxWidth) {
    final ThemeData theme = Theme.of(context);
    final String label = widget.changeLabel ?? "custom.context_header.change".tr();
    final TextStyle style = _linkStyle(theme);
    final TextStyle firstLineStyle = widget.title == "" ? _subtitleStyle(theme) : _titleStyle(theme);
    final double labelTop = math.max(0.0, (_lineHeight(context, firstLineStyle) - _lineHeight(context, style)) / 2);

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
            constraints: BoxConstraints(
              minWidth: kMinTapTarget,
              minHeight: kMinTapTarget,
              maxWidth: maxWidth,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(kDefaultPadding, labelTop, kDefaultPadding, 0),
              child: Align(
                // Size to the text (the Row gives unbounded constraints) and
                // sit at the top; the 48 dp minimum keeps the hit area.
                alignment: Alignment.topCenter,
                widthFactor: 1,
                heightFactor: 1,
                child: ExcludeSemantics(
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

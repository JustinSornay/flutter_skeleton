// view.dart
//
// Tree of ExpandableCard: the bordered Material shell, the header
// (widgets/card_header.dart), the always-visible preview or its skeleton
// bar, and the animated, height-capped, scrollable body holding the action
// row (widgets/action_button.dart), the titled sections and the free body
// slot. Colours come from the ColorScheme only.

part of "index.dart";

/// Card corner radius.
const double _cardRadius = 10;

/// Card border width.
const double _borderWidth = 0.5;

/// Height of the preview skeleton bar.
const double _previewSkeletonHeight = kDefaultPadding * 3;

/// Corner radius of the preview skeleton bar.
const double _previewSkeletonRadius = 4;

/// Vertical gap between the blocks of the expanded body.
const double _blockGap = kDefaultPadding * 1.5;

/// Horizontal gap between action buttons and between the action groups.
const double _actionGap = kDefaultPadding / 2;

/// Duration of the body's size animation (before resolveMotion).
const Duration _sizeDuration = Duration(milliseconds: 220);

/// Duration of the body's cross-fade (before resolveMotion).
const Duration _fadeDuration = Duration(milliseconds: 180);

/// Section caption size and letter spacing.
const double _captionSize = 9;
const double _captionTracking = 0.5;

mixin _ViewMixin {
  Widget render(BuildContext context, _ExpandableCardState state) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ExpandableCard widget = state.widget;
    final bool expanded = state._expanded;

    return Material(
      color: expanded ? cs.surfaceContainerLow : cs.surfaceContainerLowest,
      animationDuration: resolveMotion(context, kThemeChangeDuration),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(
          color: expanded ? cs.tertiaryContainer : cs.outlineVariant,
          width: _borderWidth,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // Stretch gives the preview and the body the card's full width, also
        // while the body is collapsed or animating.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _CardHeader(
            title: widget.title,
            subtitle: widget.subtitle,
            badge: widget.badge,
            primaryValue: widget.primaryValue,
            secondaryValue: widget.secondaryValue,
            expanded: expanded,
            onToggle: state._toggle,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              kDefaultPadding * 2,
              0,
              kDefaultPadding * 2,
              kDefaultPadding * 1.5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ?_preview(widget),
                _animatedBody(context, widget, expanded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Skeleton bar while loading, else the host preview (null when absent).
  Widget? _preview(ExpandableCard widget) {
    if (widget.previewLoading) {
      return const SkeletonPulse(
        child: SkeletonBlock(
          height: _previewSkeletonHeight,
          borderRadius: _previewSkeletonRadius,
        ),
      );
    }
    return widget.preview;
  }

  /// Body revealed with AnimatedSize + AnimatedCrossFade. Under reduced
  /// motion both wrappers are skipped (AnimatedSize asserts during layout
  /// with a zero duration): the body is shown or hidden at once and kept
  /// mounted offstage while hidden, like the hidden cross-fade child.
  Widget _animatedBody(BuildContext context, ExpandableCard widget, bool expanded) {
    final Duration sizeDuration = resolveMotion(context, _sizeDuration);
    final Widget content = _bodyContent(context, widget);
    if (sizeDuration == Duration.zero) {
      return Visibility(visible: expanded, maintainState: true, child: content);
    }

    return AnimatedSize(
      duration: sizeDuration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedCrossFade(
        duration: resolveMotion(context, _fadeDuration),
        sizeCurve: Curves.easeOutCubic,
        firstCurve: Curves.easeOut,
        secondCurve: Curves.easeIn,
        crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: const SizedBox(width: double.infinity),
        secondChild: content,
      ),
    );
  }

  /// Height-capped scrollable column: action row, sections, free body, each
  /// preceded by a gap. Empty when the host gave no body content.
  Widget _bodyContent(BuildContext context, ExpandableCard widget) {
    final Widget? body = widget.body;
    final List<Widget> blocks = <Widget>[
      if (widget.actions.isNotEmpty) _actionRow(widget.actions),
      for (final ExpandableCardSection section in widget.sections) _section(context, section),
      ?body,
    ];
    if (blocks.isEmpty) return const SizedBox(width: double.infinity);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.bodyMaxHeight),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final Widget block in blocks) ...<Widget>[
              const SizedBox(height: _blockGap),
              block,
            ],
          ],
        ),
      ),
    );
  }

  /// Neutral actions wrap from the start edge. Destructive ones sit at the
  /// trailing edge of the same line when both groups fit side by side, else
  /// they start a line of their own under the neutral group. Without neutral
  /// actions they wrap from the trailing edge.
  ///
  /// Each group is a Wrap laid out within the full width, so neither can
  /// overflow. A Row would hand the non-flex destructive group an unbounded
  /// width, and a LayoutBuilder cap would drop the card's intrinsic sizes.
  Widget _actionRow(List<ExpandableCardAction> actions) {
    final List<Widget> neutral = <Widget>[
      for (final ExpandableCardAction action in actions)
        if (!action.destructive) _ActionButton(action: action),
    ];
    final List<Widget> destructive = <Widget>[
      for (final ExpandableCardAction action in actions)
        if (action.destructive) _ActionButton(action: action),
    ];
    if (neutral.isEmpty) {
      return Wrap(alignment: WrapAlignment.end, spacing: _actionGap, children: destructive);
    }

    // spaceBetween pushes the destructive group to the trailing edge while
    // it shares the neutral group's line; alone on its line it starts there.
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: _actionGap,
      children: <Widget>[
        Wrap(spacing: _actionGap, children: neutral),
        if (destructive.isNotEmpty) Wrap(spacing: _actionGap, children: destructive),
      ],
    );
  }

  /// Optional uppercase caption (a semantics header read in its original
  /// casing) above the section child.
  Widget _section(BuildContext context, ExpandableCardSection section) {
    final String? title = section.title;
    if (title == null || title.isEmpty) return section.child;

    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextStyle? base = Theme.of(context).textTheme.labelSmall;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: kDefaultPadding / 2),
          child: Semantics(
            header: true,
            child: Text(
              title.toUpperCase(),
              semanticsLabel: title,
              style: (base ?? const TextStyle()).copyWith(
                fontSize: _captionSize,
                fontWeight: FontWeight.w800,
                letterSpacing: _captionTracking,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
        section.child,
      ],
    );
  }
}

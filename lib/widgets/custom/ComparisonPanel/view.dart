// view.dart
//
// Tree of ComparisonPanel: the bordered card holding the summary header
// (widgets/summary_header.dart) and the animated detail section
// (widgets/detail_section.dart), then the action row
// (widgets/action_row.dart). Colours come from the ColorScheme only.

part of "index.dart";

/// Card corner radius.
const double _cardRadius = 12;

/// Width of the card border.
const double _cardBorderWidth = 1.5;

mixin _ViewMixin {
  Widget render(BuildContext context, ComparisonPanel widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Material(
          color: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardRadius),
            side: BorderSide(color: cs.tertiary, width: _cardBorderWidth),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _SummaryHeader(
                current: widget.current,
                candidate: widget.candidate,
                isExpanded: widget.isExpanded,
                icon: widget.icon,
                onToggle: widget._hasDetail ? widget.onToggle : null,
              ),
              _detail(context, widget),
            ],
          ),
        ),
        const SizedBox(height: kDefaultPadding * 1.5),
        _ActionRow(
          onCancel: widget.onCancel,
          onConfirm: widget.onConfirm,
          cancelLabel: widget.cancelLabel ?? "custom.comparison_panel.cancel".tr(),
          confirmLabel: widget.confirmLabel ?? "custom.comparison_panel.confirm".tr(),
          confirmIcon: widget.icon,
        ),
      ],
    );
  }

  /// The detail section when expanded (and not empty), else an empty box,
  /// revealed with [AnimatedSize]. Under reduced motion the section is
  /// swapped at once, without the AnimatedSize wrapper.
  Widget _detail(BuildContext context, ComparisonPanel widget) {
    final Widget content = widget.isExpanded && widget._hasDetail
        ? _DetailSection(
            current: widget.current,
            candidate: widget.candidate,
            metrics: widget.metrics,
            change: widget.change,
          )
        : const SizedBox.shrink();
    final Duration duration = resolveMotion(context, kMotionShort);
    if (duration == Duration.zero) return content;

    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: content,
    );
  }
}

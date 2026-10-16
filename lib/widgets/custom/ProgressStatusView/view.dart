// view.dart
//
// Layout of ProgressStatusView: the percentage ring (one semantics node:
// title + percentage; the centred text scales down to stay inside the ring),
// the live-region title / subtitle group, the linear bar (excluded from
// semantics), then the optional details pill (widgets/details_pill.dart,
// empty entries skipped) and Cancel button. Colours come from the
// ColorScheme only.

part of "index.dart";

/// Ring diameter.
const double _ringSize = kDefaultPadding * 12;

/// Stroke of the ring and thickness of the bar.
const double _strokeWidth = 6;

mixin _ViewMixin {
  Widget render(BuildContext context, ProgressStatusView widget) {
    final double fraction = ProgressStatusView._fraction(widget.progress);
    final VoidCallback? onCancel = widget.onCancel;
    final List<String> facts = widget.details.where((String fact) => fact.isNotEmpty).toList();

    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding * 4,
              vertical: kDefaultPadding * 6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _ring(context, widget.title, fraction),
                const SizedBox(height: kSectionGap),
                _heading(context, widget.title, widget.subtitle),
                const SizedBox(height: kDefaultPadding * 2),
                _bar(context, fraction),
                if (facts.isNotEmpty) ...<Widget>[
                  const SizedBox(height: kDefaultPadding * 1.5),
                  _DetailsPill(details: facts),
                ],
                if (onCancel != null) ...<Widget>[
                  const SizedBox(height: kSectionGap),
                  _cancelButton(context, onCancel),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 96 dp ring with the percentage in its centre, read as one node
  /// (label: [title], value: the percentage text). The percentage stays on
  /// one line and scales down to fit inside the stroke at large text scales.
  Widget _ring(BuildContext context, String title, double fraction) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String percent = _percent(context, fraction);

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: title,
      value: percent,
      child: SizedBox.square(
        dimension: _ringSize,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            SizedBox.square(
              dimension: _ringSize,
              child: CircularProgressIndicator(
                value: fraction,
                strokeWidth: _strokeWidth,
                backgroundColor: cs.surfaceContainerHighest,
                color: cs.primary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(_strokeWidth * 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  percent,
                  maxLines: 1,
                  softWrap: false,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Title and optional subtitle in a live region, so a step change is
  /// announced.
  Widget _heading(BuildContext context, String title, String? subtitle) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool hasSubtitle = subtitle != null && subtitle.isNotEmpty;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          if (hasSubtitle) ...<Widget>[
            const SizedBox(height: kDefaultPadding / 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  /// Full-width rounded bar mirroring the ring; excluded from semantics so the
  /// progress is announced once.
  Widget _bar(BuildContext context, double fraction) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: fraction,
          minHeight: _strokeWidth,
          backgroundColor: cs.surfaceContainerHighest,
          color: cs.primary,
        ),
      ),
    );
  }

  /// Outlined Cancel button, at least [kMinTapTarget] square.
  Widget _cancelButton(BuildContext context, VoidCallback onCancel) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return OutlinedButton(
      onPressed: onCancel,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(kMinTapTarget, kMinTapTarget),
        foregroundColor: cs.onSurfaceVariant,
        side: BorderSide(color: cs.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      child: Text("custom.progress_status_view.cancel".tr()),
    );
  }

  /// [fraction] (already in `[0, 1]`) as a percentage for the ambient locale;
  /// an unknown locale falls back to intl's default.
  String _percent(BuildContext context, double fraction) {
    final String? locale = numberLocaleOf(context);
    return NumberFormat.percentPattern(locale).format(fraction);
  }
}

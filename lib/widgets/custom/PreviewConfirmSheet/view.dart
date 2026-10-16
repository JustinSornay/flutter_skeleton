// view.dart
//
// _ViewMixin — widget tree of PreviewConfirmSheet: the image header
// (widgets/image_header.dart), then a padded column with the title, the
// optional subtitle, the stat wrap (widgets/stat_badge.dart), the confirm
// button and the optional cancel button, all in a scroll view.

part of "index.dart";

/// Gap between the heading and the stats.
const double _statsGap = kDefaultPadding * 2;

/// Gap between the content and the buttons.
const double _actionsGap = kDefaultPadding * 3;

/// Minimum size of both buttons.
const Size _buttonMinimumSize = Size(kMinTapTarget, kMinTapTarget);

mixin _ViewMixin {
  Widget render(BuildContext context, PreviewConfirmSheet widget) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ImageHeader(
            image: widget.image,
            placeholderIcon: widget.placeholderIcon,
            semanticLabel: widget.imageSemanticLabel,
          ),
          Padding(
            padding: const EdgeInsets.all(kDefaultPadding * 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ..._heading(Theme.of(context), widget),
                if (widget.stats.isNotEmpty) ...<Widget>[
                  const SizedBox(height: _statsGap),
                  Wrap(
                    spacing: kDefaultPadding,
                    runSpacing: kDefaultPadding,
                    children: <Widget>[
                      for (final PreviewStat stat in widget.stats) _StatBadge(stat: stat),
                    ],
                  ),
                ],
                const SizedBox(height: _actionsGap),
                ..._actions(widget),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Title (header semantics) and the optional subtitle.
  List<Widget> _heading(ThemeData theme, PreviewConfirmSheet widget) {
    final ColorScheme cs = theme.colorScheme;
    final String? subtitle = widget.subtitle;
    return <Widget>[
      Semantics(
        header: true,
        child: Text(
          widget.title,
          style: (theme.textTheme.titleLarge ?? const TextStyle()).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
      ),
      if (subtitle != null && subtitle.isNotEmpty)
        Text(
          subtitle,
          style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
            fontSize: 13,
            fontStyle: widget.italicSubtitle ? FontStyle.italic : FontStyle.normal,
            color: cs.onSurfaceVariant,
          ),
        ),
    ];
  }

  /// Full-width confirm button and, when `onCancel` is set, the cancel one.
  List<Widget> _actions(PreviewConfirmSheet widget) {
    final VoidCallback? onCancel = widget.onCancel;
    return <Widget>[
      FilledButton(
        onPressed: widget.onConfirm,
        style: FilledButton.styleFrom(
          minimumSize: _buttonMinimumSize,
          // Desktop platforms default to a compact density (8 dp shorter)
          // and a shrink-wrapped tap target, which would leave a 40 dp button.
          visualDensity: VisualDensity.standard,
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        child: Text(
          _labelOr(widget.confirmLabel, "custom.preview_confirm_sheet.confirm"),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      if (onCancel != null) ...<Widget>[
        const SizedBox(height: kDefaultPadding),
        TextButton(
          onPressed: onCancel,
          style: TextButton.styleFrom(
            minimumSize: _buttonMinimumSize,
            visualDensity: VisualDensity.standard,
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          child: Text(_labelOr(widget.cancelLabel, "custom.preview_confirm_sheet.cancel")),
        ),
      ],
    ];
  }

  /// [label], or the translation of [key] when it is null or empty.
  String _labelOr(String? label, String key) {
    return (label == null || label.isEmpty) ? key.tr() : label;
  }
}

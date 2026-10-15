// view.dart
//
// Tree of SelectionStrip: a cs.primary-tinted band with a bottom divider
// holding a decorative dot, the one-line "prefix value detail" text and, when
// onEdit is set, an underlined edit link with a 48 dp hit area.

part of "index.dart";

/// Opacity of `cs.primary` for the band background.
const double _fillAlpha = 0.08;

/// Opacity of `cs.primary` for the detail text.
const double _detailAlpha = 0.85;

/// Diameter of the leading dot.
const double _dotSize = kDefaultPadding;

/// Widest the edit action may grow before its label is ellipsized.
const double _editMaxWidth = kDefaultPadding * 16;

/// Corner radius of the edit action's ink highlight.
const BorderRadius _editRadius = BorderRadius.all(Radius.circular(kDefaultPadding / 2));

mixin _ViewMixin {
  Widget render(BuildContext context, SelectionStrip widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final VoidCallback? onEdit = widget.onEdit;

    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 2),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: _fillAlpha),
          border: Border(bottom: BorderSide(color: cs.outlineVariant)),
        ),
        // Transparent Material so the edit ink paints above the tinted band.
        child: Material(
          type: MaterialType.transparency,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTapTarget),
            child: Row(
              children: <Widget>[
                ExcludeSemantics(child: _dot(cs)),
                const SizedBox(width: kDefaultPadding),
                Expanded(child: _summary(context, widget)),
                if (onEdit != null) ...<Widget>[
                  const SizedBox(width: kDefaultPadding),
                  _editAction(context, widget, onEdit),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(ColorScheme cs) {
    return SizedBox.square(
      dimension: _dotSize,
      child: DecoratedBox(
        decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
      ),
    );
  }

  Widget _summary(BuildContext context, SelectionStrip widget) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final TextStyle small = theme.textTheme.labelSmall ?? const TextStyle();
    final TextStyle valueStyle = (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w700,
      color: cs.primary,
    );
    final String prefix = widget.prefix ?? "custom.selection_strip.prefix".tr();
    final String detail = widget.detail ?? "";

    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          if (prefix.isNotEmpty) ...<InlineSpan>[
            TextSpan(
              text: prefix,
              style: small.copyWith(fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
            ),
            const TextSpan(text: " "),
          ],
          TextSpan(text: widget.value, style: valueStyle),
          if (detail.isNotEmpty) ...<InlineSpan>[
            const TextSpan(text: " "),
            TextSpan(
              text: detail,
              style: small.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.primary.withValues(alpha: _detailAlpha),
              ),
            ),
          ],
        ],
      ),
      // Root style: separators and the ellipsis match the value.
      style: valueStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _editAction(BuildContext context, SelectionStrip widget, VoidCallback onEdit) {
    final ThemeData theme = Theme.of(context);
    final Color color = theme.colorScheme.primary;
    final String label = widget.editLabel ?? "custom.selection_strip.edit".tr();
    final String semanticsLabel = widget.editSemanticsLabel ??
        "custom.selection_strip.edit_semantics".tr(
          namedArgs: <String, String>{"action": label, "value": widget.value},
        );

    return Semantics(
      container: true,
      button: true,
      child: InkWell(
        onTap: onEdit,
        borderRadius: _editRadius,
        child: Semantics(
          label: semanticsLabel,
          excludeSemantics: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: kMinTapTarget,
              minHeight: kMinTapTarget,
              maxWidth: _editMaxWidth,
            ),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                    decoration: TextDecoration.underline,
                    decorationColor: color,
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

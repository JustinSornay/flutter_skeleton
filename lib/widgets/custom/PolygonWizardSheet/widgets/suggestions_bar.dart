// suggestions_bar.dart
//
// _SuggestionsBar — the suggestion rows of the PolygonWizardSheet polygon
// step on a cs.surfaceContainerLow panel: a _ProgressLine while
// loadSuggestions runs, then one titled, horizontally scrolling row of
// chips per non-empty group. Hidden when there is nothing to show.
// _SuggestionChip is a 32 dp pill in a 48 dp target; the imported one is
// tinted cs.primary. A chip that cannot act (sheet locked, fewer than 3
// points) is disabled: no tap, muted, announced as disabled.

part of "../index.dart";

/// Panel corner radius.
const double _kPanelRadius = 12;

/// Visible height of a suggestion pill.
const double _kChipHeight = 32;

/// Widest chip label before it is ellipsized.
const double _kChipLabelMaxWidth = 120;

/// Colour change of a suggestion pill.
const Duration _kChipMotion = Duration(milliseconds: 160);

/// Background opacity of the imported suggestion pill.
const double _kImportedAlpha = 0.12;

/// Opacity of a disabled pill's text, icon and border (Material's disabled
/// content opacity).
const double _kDisabledAlpha = 0.38;

final class _SuggestionsBar extends StatelessWidget {
  final _PolygonWizardSheetState state;

  const _SuggestionsBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final List<PolygonSuggestionGroup> groups = state.suggestionGroups
        .where((PolygonSuggestionGroup group) => group.suggestions.isNotEmpty)
        .toList();
    if (groups.isEmpty && !state.suggestionsLoading) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: kDefaultPadding * 1.5),
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(_kPanelRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (state.suggestionsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: kDefaultPadding * 1.5),
              child: _ProgressLine(),
            ),
          for (final PolygonSuggestionGroup group in groups)
            _group(context, group),
        ],
      ),
    );
  }

  Widget _group(BuildContext context, PolygonSuggestionGroup group) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding * 1.5,
          ),
          child: Semantics(
            header: true,
            child: Text(
              group.title,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding * 1.5,
          ),
          child: Row(
            children: <Widget>[
              for (final PolygonSuggestion suggestion in group.suggestions)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: kDefaultPadding,
                  ),
                  child: _SuggestionChip(
                    label: suggestion.label,
                    imported: state.importedId == suggestion.id,
                    onTap: !state.busy && suggestion.points.length >= 3
                        ? () => state.toggleSuggestion(suggestion)
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _SuggestionChip extends StatelessWidget {
  final String label;
  final bool imported;

  /// Null disables the chip.
  final VoidCallback? onTap;

  const _SuggestionChip({
    required this.label,
    required this.imported,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool enabled = onTap != null;
    final double alpha = enabled ? 1 : _kDisabledAlpha;
    final Color foreground = (imported ? cs.primary : cs.onSurface).withValues(
      alpha: alpha,
    );
    final Color iconColor = (imported ? cs.primary : cs.onSurfaceVariant)
        .withValues(alpha: alpha);
    final Color borderColor = (imported ? cs.primary : cs.outlineVariant)
        .withValues(alpha: alpha);
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      selected: imported,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: kMinTapTarget,
            minHeight: kMinTapTarget,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: AnimatedContainer(
              duration: resolveMotion(context, _kChipMotion),
              height: _kChipHeight,
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding * 1.5,
              ),
              decoration: BoxDecoration(
                color: imported
                    ? cs.primary.withValues(alpha: _kImportedAlpha)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: borderColor,
                  width: imported ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.pentagon_outlined, size: 14, color: iconColor),
                  const SizedBox(width: kDefaultPadding * 0.75),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _kChipLabelMaxWidth,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

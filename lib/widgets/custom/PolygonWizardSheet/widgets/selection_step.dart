// selection_step.dart
//
// _SelectionStep — the selection step of PolygonWizardSheet. Single mode:
// the header above the host's picker, then above a _BusyIndicator while the
// pick resolves, then the picked item as an EditableValueRow card (tap to
// pick again). Multi mode: the header, an AnimatedSize band of removable
// chips with a count, a _ProgressLine while a pick resolves and the host's
// picker, which stays mounted across picks. A failed pick shows an inline
// error.

part of "../index.dart";

/// Selection card corner radius.
const double _kCardRadius = 12;

/// Chip band size change.
const Duration _kBandMotion = Duration(milliseconds: 200);

final class _SelectionStep extends StatelessWidget {
  final _PolygonWizardSheetState state;
  final PolygonWizardStep step;

  const _SelectionStep({required this.state, required this.step});

  @override
  Widget build(BuildContext context) {
    if (state.widget.allowMultipleSelections) return _multiple(context);
    final PolygonFormSelection? selected = state.selections.firstOrNull;
    if (selected != null) return _card(context, selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _header(),
        Expanded(
          child: state.resolving
              ? const Center(child: _BusyIndicator())
              : _picker(),
        ),
      ],
    );
  }

  /// Step header plus the failed-pick error.
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kDefaultPadding * 2,
        kDefaultPadding * 2,
        kDefaultPadding * 2,
        kDefaultPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _StepHeader(step: step),
          if (state.selectionFailed)
            _InlineError(
              text: "custom.polygon_wizard_sheet.selection_error".tr(),
              padding: const EdgeInsets.only(top: kDefaultPadding),
            ),
        ],
      ),
    );
  }

  /// The host's picker, rebuilt with the current selections and polygon.
  Widget _picker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 2),
      child: Builder(
        builder: (BuildContext context) {
          final PolygonWizardPickerBuilder? builder =
              state.widget.pickerBuilder;
          if (builder == null) return const SizedBox.shrink();
          return builder(
            context,
            state.onPicked,
            state.selectedIds,
            state.polygon.points,
          );
        },
      ),
    );
  }

  /// Single mode: the picked item; tapping it shows the picker again.
  Widget _card(BuildContext context, PolygonFormSelection selected) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kDefaultPadding * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _StepHeader(step: step),
          const SizedBox(height: kDefaultPadding * 2),
          Material(
            color: cs.surfaceContainerLowest,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_kCardRadius),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: InkWell(
              onTap: state.busy ? null : state.clearSelections,
              child: Padding(
                padding: const EdgeInsets.all(kDefaultPadding * 1.5),
                child: EditableValueRow(
                  icon: state.widget.selectionIcon,
                  title: selected.title,
                  subtitle: selected.subtitle,
                  subtitleItalic: selected.subtitleItalic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Multi mode: chips above a picker that stays mounted.
  Widget _multiple(BuildContext context) {
    final bool hasSelections = state.selections.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _header(),
        AnimatedSize(
          duration: resolveMotion(context, _kBandMotion),
          curve: Curves.easeInOut,
          alignment: AlignmentDirectional.topStart,
          child: hasSelections ? _band(context) : const SizedBox.shrink(),
        ),
        if (hasSelections || state.resolving)
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        // A thin line instead of a spinner keeps the picker (and its scroll
        // position) mounted while a pick resolves; as the last child it keeps
        // its element when the rows above it come and go.
        if (state.resolving)
          const _ProgressLine(backgroundColor: Colors.transparent),
        Expanded(child: _picker()),
      ],
    );
  }

  /// The count and the removable chips.
  Widget _band(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kDefaultPadding * 2,
        0,
        kDefaultPadding * 2,
        kDefaultPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "custom.polygon_wizard_sheet.selected_count".tr(
              namedArgs: <String, String>{
                "count": "${state.selections.length}",
              },
            ),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: kDefaultPadding / 2),
          Wrap(
            spacing: kDefaultPadding * 0.75,
            children: <Widget>[
              for (final PolygonFormSelection selection in state.selections)
                _SelectionChip(
                  label: selection.title,
                  onRemove: state.busy
                      ? null
                      : () => state.removeSelection(selection.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

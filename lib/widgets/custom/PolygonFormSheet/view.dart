// view.dart
//
// _ViewMixin — widget tree of PolygonFormSheet: the header (title + close)
// and a divider above either the host's picker (picker phase) or the
// scrolling form (selection card, draw section, crossing hint, name field,
// inline error and submit button). Once shown, the form stays mounted
// (hidden) behind the picker.

part of "index.dart";

/// Height of the selection section while the picked item loads.
const double _kSelectionLoadingHeight = 56;

/// Name field corner radius.
const double _kFieldRadius = 12;

mixin _ViewMixin {
  Widget render(BuildContext context, _PolygonFormSheetState state) {
    final PolygonFormSheet widget = state.widget;
    final PolygonFormPickerBuilder? pickerBuilder = widget.pickerBuilder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SheetHeader(title: widget.title, onClose: widget.onClose),
        const Divider(height: 1),
        Expanded(
          child: pickerBuilder == null
              ? _formPhase(context, state)
              : _phases(context, state, pickerBuilder),
        ),
      ],
    );
  }

  /// The picker over the form. The form is built from the first pick on and
  /// then only hidden (no focus, no tickers, no semantics) while the picker
  /// shows, so the map keeps its camera.
  Widget _phases(
    BuildContext context,
    _PolygonFormSheetState state,
    PolygonFormPickerBuilder pickerBuilder,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (state.formShown)
          Visibility(
            visible: !state.showsPicker,
            maintainState: true,
            child: _formPhase(context, state),
          ),
        if (state.showsPicker) _pickerPhase(context, state, pickerBuilder),
      ],
    );
  }

  /// The host's picker, under an inline error when the last pick failed.
  Widget _pickerPhase(
    BuildContext context,
    _PolygonFormSheetState state,
    PolygonFormPickerBuilder pickerBuilder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (state.selection.hasError)
          _errorText(
            context,
            "custom.polygon_form_sheet.selection_error".tr(),
            padding: const EdgeInsets.fromLTRB(
              kDefaultPadding * 2,
              kDefaultPadding,
              kDefaultPadding * 2,
              0,
            ),
          ),
        Expanded(
          child: Builder(
            builder: (BuildContext context) =>
                pickerBuilder(context, state.onPicked),
          ),
        ),
      ],
    );
  }

  Widget _formPhase(BuildContext context, _PolygonFormSheetState state) {
    final PolygonFormSheet widget = state.widget;
    final bool busy = state.busy;
    return ListView(
      padding: const EdgeInsets.all(kDefaultPadding * 2),
      children: <Widget>[
        if (state.hasPicker) ...<Widget>[
          _SectionLabel(
            text: widget.selectionLabel ??
                "custom.polygon_form_sheet.selection_label".tr(),
          ),
          const SizedBox(height: kDefaultPadding),
          _selection(state),
          const SizedBox(height: kDefaultPadding * 3),
        ],
        _DrawSection(
          label: widget.drawLabel ?? "custom.polygon_form_sheet.draw_label".tr(),
          controller: state.polygon,
          shapeValid: state.shapeValid,
          tileLayer: widget.tileLayer,
          initialCenter: widget.initialCenter,
          initialZoom: widget.initialZoom,
          attribution: widget.attribution,
        ),
        if (state.edgesCross)
          _errorText(
            context,
            "custom.polygon_form_sheet.crossing_edges".tr(),
            padding: const EdgeInsets.only(top: kDefaultPadding),
          ),
        const SizedBox(height: kDefaultPadding * 3),
        _nameField(context, state),
        const SizedBox(height: kDefaultPadding * 3),
        if (state.submission.hasError)
          _errorText(
            context,
            widget.submitErrorText ??
                "custom.polygon_form_sheet.submit_error".tr(),
            padding: const EdgeInsets.only(bottom: kDefaultPadding * 1.5),
          ),
        _SubmitButton(
          label: widget.submitLabel ?? "custom.polygon_form_sheet.submit".tr(),
          busy: busy,
          onPressed: state.canSubmit ? state.submit : null,
        ),
        const SizedBox(height: kDefaultPadding * 3),
      ],
    );
  }

  /// The picked item card, or a [Loader] while it resolves.
  Widget _selection(_PolygonFormSheetState state) {
    return switch (state.selection) {
      Loaded<PolygonFormSelection>(:final PolygonFormSelection data) =>
        _SelectionCard(
          selection: data,
          icon: state.widget.selectionIcon,
          onTap: state.busy ? null : state.changeSelection,
        ),
      _ => const SizedBox(
        height: _kSelectionLoadingHeight,
        child: Center(child: Loader()),
      ),
    };
  }

  /// The optional name field under its section label.
  Widget _nameField(BuildContext context, _PolygonFormSheetState state) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final TextStyle? style = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      color: cs.onSurface,
    );
    // Label and field form one semantics node, so the field is announced
    // with its label.
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SectionLabel(
            text: state.widget.nameLabel ??
                "custom.polygon_form_sheet.name_label".tr(),
          ),
          const SizedBox(height: kDefaultPadding),
          TextField(
            controller: state.nameController,
            style: style,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: state.widget.nameHint,
              hintStyle: style?.copyWith(color: cs.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_kFieldRadius),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding * 2,
                vertical: kDefaultPadding * 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Error line announced as a live region.
  Widget _errorText(
    BuildContext context,
    String text, {
    required EdgeInsets padding,
  }) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Padding(
        padding: padding,
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}

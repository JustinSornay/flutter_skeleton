// view.dart
//
// _ViewMixin — widget tree of EditFieldsSheet: the header and the field
// blocks (keyed by field id) scroll together; the inline error after a failed
// save and the action bar, which rebuilds on every edit to follow the dirty
// state, stay pinned below them.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, _EditFieldsSheetState state) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final EditFieldsSheet widget = state.widget;
    final bool busy = state.busy;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kDefaultPadding * 3,
        kDefaultPadding,
        kDefaultPadding * 3,
        kDefaultPadding * 3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _SheetHeader(title: widget.title, subtitle: widget.subtitle),
                  for (final EditSheetField field in widget.fields) ...<Widget>[
                    const SizedBox(height: kDefaultPadding * 2),
                    _FieldBlock(
                      key: ValueKey<String>(field.id),
                      field: field,
                      controller: state.controllerFor(field),
                      enabled: !busy,
                    ),
                  ],
                ],
              ),
            ),
          ),
          switch (state.submission) {
            LoadError<void>(:final String? message) => Semantics(
              liveRegion: true,
              container: true,
              child: Padding(
                padding: const EdgeInsets.only(top: kDefaultPadding),
                child: Text(
                  message ?? "",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.error),
                ),
              ),
            ),
            _ => const SizedBox.shrink(),
          },
          const SizedBox(height: kDefaultPadding * 2),
          ListenableBuilder(
            listenable: state.textChanges,
            builder: (BuildContext context, Widget? child) => _ActionBar(
              cancelLabel: widget.cancelLabel ?? "custom.edit_fields_sheet.cancel".tr(),
              submitLabel: widget.submitLabel ?? "custom.edit_fields_sheet.save".tr(),
              busy: busy,
              onCancel: busy ? null : widget.onCancel,
              onSubmit: busy || !state.isDirty ? null : state.save,
            ),
          ),
        ],
      ),
    );
  }
}

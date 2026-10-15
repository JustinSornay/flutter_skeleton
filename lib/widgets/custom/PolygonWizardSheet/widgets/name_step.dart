// name_step.dart
//
// _NameStep — the name step of PolygonWizardSheet: the step header above an
// autofocused text field (nameLabel placeholder, radius 12). Typing rebuilds
// the sheet so Next follows the field.

part of "../index.dart";

/// Name field corner radius.
const double _kFieldRadius = 12;

final class _NameStep extends StatelessWidget {
  final _PolygonWizardSheetState state;
  final PolygonWizardStep step;

  const _NameStep({required this.state, required this.step});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final TextStyle? style = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      color: cs.onSurface,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kDefaultPadding * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _StepHeader(step: step),
          const SizedBox(height: kDefaultPadding * 2),
          TextField(
            controller: state.nameController,
            autofocus: true,
            enabled: !state.busy,
            style: style,
            textInputAction: TextInputAction.done,
            onChanged: state.onNameChanged,
            decoration: InputDecoration(
              hintText:
                  state.widget.nameLabel ??
                  "custom.polygon_wizard_sheet.name_label".tr(),
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
}

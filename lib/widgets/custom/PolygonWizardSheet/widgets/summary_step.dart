// summary_step.dart
//
// _SummaryStep — the recap step of PolygonWizardSheet: the centred header
// (16 dp title) above a bordered card (cs.surfaceContainerLowest,
// cs.outlineVariant) with one row per available datum: the typed name, the
// selected titles joined with ", " and the vertex count. Each _SummaryRow is
// one semantics node; its label is ellipsized past _kLabelWidthFactor of the
// row, the value takes the rest.

part of "../index.dart";

/// Summary card corner radius.
const double _kSummaryRadius = 12;

/// Widest a summary row label grows, as a fraction of the row.
const double _kLabelWidthFactor = 0.4;

final class _SummaryStep extends StatelessWidget {
  final _PolygonWizardSheetState state;
  final PolygonWizardStep step;

  const _SummaryStep({required this.state, required this.step});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<Widget> rows = _rows();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        kDefaultPadding * 2,
        kDefaultPadding,
        kDefaultPadding * 2,
        kDefaultPadding * 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _StepHeader(step: step, centered: true, titleSize: 16),
          if (rows.isNotEmpty) ...<Widget>[
            const SizedBox(height: kDefaultPadding * 2),
            DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(_kSummaryRadius),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int i = 0; i < rows.length; i++) ...<Widget>[
                    if (i > 0) Divider(height: 1, color: cs.outlineVariant),
                    rows[i],
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _rows() {
    final PolygonWizardSheet widget = state.widget;
    final String name = state.nameController.text.trim();
    final List<PolygonFormSelection> selections = state.selections;
    final int vertices = state.polygon.length;
    return <Widget>[
      if (name.isNotEmpty)
        _SummaryRow(
          icon: Icons.label_outline_rounded,
          label:
              widget.nameLabel ?? "custom.polygon_wizard_sheet.name_label".tr(),
          value: name,
        ),
      if (selections.isNotEmpty)
        _SummaryRow(
          icon: widget.selectionIcon,
          label:
              widget.selectionLabel ??
              "custom.polygon_wizard_sheet.selection_label".tr(),
          value: selections
              .map((PolygonFormSelection selection) => selection.title)
              .join(", "),
        ),
      if (vertices >= 3)
        _SummaryRow(
          icon: Icons.pentagon_outlined,
          label: "custom.polygon_wizard_sheet.points_label".tr(),
          value: "custom.polygon_wizard_sheet.points_count".tr(
            namedArgs: <String, String>{"count": "$vertices"},
          ),
        ),
    ];
  }
}

final class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding * 2,
          vertical: kDefaultPadding * 1.5,
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) => Row(
            children: <Widget>[
              Icon(icon, size: 16, color: cs.primary),
              const SizedBox(width: kDefaultPadding),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * _kLabelWidthFactor,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: kDefaultPadding * 2),
              Expanded(child: _value(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _value(ThemeData theme) {
    return Text(
      value,
      textAlign: TextAlign.end,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

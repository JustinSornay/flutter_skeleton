// change_callout.dart
//
// _ChangeCallout — the "label : from → to" highlight at the bottom of a
// ComparisonPanel detail section: `cs.primaryContainer` box, leading icon,
// and the runs of the localized template (controllers/callout_template.dart)
// with the from / to values emphasised.

part of "../index.dart";

final class _ChangeCallout extends StatelessWidget {
  const _ChangeCallout({required this.change});

  final ComparisonChange change;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<_CalloutRun> runs = _CalloutTemplate.runs("custom.comparison_panel.callout".tr(), change);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 1.25, vertical: kDefaultPadding),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      child: Row(
        children: <Widget>[
          Icon(change.icon, size: 14, color: cs.onPrimaryContainer),
          const SizedBox(width: kDefaultPadding),
          Flexible(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onPrimaryContainer),
                children: <InlineSpan>[
                  for (final _CalloutRun run in runs)
                    TextSpan(
                      text: run.text,
                      style: run.emphasis ? const TextStyle(fontWeight: FontWeight.w800) : null,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

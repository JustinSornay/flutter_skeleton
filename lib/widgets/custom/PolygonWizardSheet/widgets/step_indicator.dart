// step_indicator.dart
//
// _StepIndicator — segmented progress of PolygonWizardSheet: one bar per
// step (active cs.primary 4 dp, done cs.primary at 55 %, pending
// cs.outlineVariant 3 dp, colour change animated through resolveMotion)
// with the step title under it. Screen readers get one live node: "Step
// {current} of {total}: {title}".

part of "../index.dart";

/// Colour change of a segment.
const Duration _kSegmentMotion = Duration(milliseconds: 350);

/// Opacity of a completed segment.
const double _kDoneAlpha = 0.55;

final class _StepIndicator extends StatelessWidget {
  final List<PolygonWizardStep> steps;
  final int current;

  const _StepIndicator({required this.steps, required this.current});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: "custom.polygon_wizard_sheet.step_semantics".tr(
        namedArgs: <String, String>{
          "current": "${current + 1}",
          "total": "${steps.length}",
          "title": steps[current].title,
        },
      ),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding * 2,
            vertical: kDefaultPadding / 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = 0; i < steps.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: i < steps.length - 1 ? kDefaultPadding / 2 : 0,
                    ),
                    child: _segment(context, i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _segment(BuildContext context, int index) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final bool active = index == current;
    final bool done = index < current;
    final Color target = active
        ? cs.primary
        : (done
              ? cs.primary.withValues(alpha: _kDoneAlpha)
              : cs.outlineVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TweenAnimationBuilder<Color?>(
          tween: ColorTween(begin: cs.outlineVariant, end: target),
          duration: resolveMotion(context, _kSegmentMotion),
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, Color? color, Widget? child) =>
              SizedBox(
                height: active ? 4 : 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color ?? target,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
        ),
        const SizedBox(height: kDefaultPadding / 2),
        Text(
          steps[index].title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            fontWeight: active
                ? FontWeight.w700
                : (done ? FontWeight.w500 : FontWeight.w400),
            color: active || done ? cs.primary : cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

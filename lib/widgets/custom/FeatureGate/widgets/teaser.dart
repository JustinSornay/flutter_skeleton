// teaser.dart
//
// Private teaser of FeatureGate (GateDisplayMode.teaser): a blurred,
// dimmed mock (the host's builder or a generic placeholder of a label and
// two bars), out of reach of pointer, keyboard focus and screen readers,
// under a blurred cs.scrim, with a centred pill (badge + label). The pill
// takes part in sizing, so the teaser is never shorter than it. It never
// builds the gate's real child.

part of "../index.dart";

/// Blur sigma of the mock preview.
const double _previewBlur = 3;

/// Blur sigma of the backdrop behind the scrim.
const double _backdropBlur = 2;

/// Opacity of the cs.scrim overlay.
const double _scrimAlpha = 0.3;

/// Opacity of the pill's cs.shadow.
const double _pillShadowAlpha = 0.06;

/// Corner radius of the teaser and of its pill.
const double _teaserRadius = 12;

/// Minimum teaser height: a margin around the pill over a tiny mock. The
/// pill itself sizes the teaser when it is taller (large text scales).
const double _teaserMinHeight = kDefaultPadding * 6;

/// Width factor of the placeholder's second bar.
const double _shortBarFactor = 0.6;

final class _Teaser extends StatelessWidget {
  final String label;

  /// The lock badge, at the start of the pill.
  final Widget badge;

  /// Host mock content; null → [_TeaserPlaceholder].
  final WidgetBuilder? builder;

  const _Teaser({required this.label, required this.badge, required this.builder});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final WidgetBuilder? builder = this.builder;
    final Widget preview = builder == null ? _TeaserPlaceholder(label: label) : builder(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(_teaserRadius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _teaserMinHeight),
        // Non-positioned children size the Stack: the teaser is as tall as
        // the taller of the mock and the pill, and the scrim covers both.
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // The SizedBox makes the teaser fill the parent's width.
            SizedBox(
              width: double.infinity,
              // Inert for pointer, screen readers and keyboard focus (Tab).
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: ExcludeFocus(
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: _previewBlur, sigmaY: _previewBlur),
                      child: Opacity(opacity: _dimmedOpacity, child: preview),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: _backdropBlur, sigmaY: _backdropBlur),
                child: ColoredBox(color: cs.scrim.withValues(alpha: _scrimAlpha)),
              ),
            ),
            _pill(context, cs),
          ],
        ),
      ),
    );
  }

  /// Opaque pill (badge + label) centred over the scrim.
  Widget _pill(BuildContext context, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding * 1.5,
        vertical: kDefaultPadding,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(_teaserRadius),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: cs.shadow.withValues(alpha: _pillShadowAlpha),
            blurRadius: kDefaultPadding / 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          badge,
          const SizedBox(width: kDefaultPadding),
          Flexible(
            child: ExcludeSemantics(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic mock shown when the host gives no teaser builder: the label and
/// two bars standing in for content.
final class _TeaserPlaceholder extends StatelessWidget {
  final String label;

  const _TeaserPlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: kDefaultPadding),
          _bar(cs, 1),
          const SizedBox(height: kDefaultPadding * 0.75),
          _bar(cs, _shortBarFactor),
        ],
      ),
    );
  }

  /// One placeholder bar, [widthFactor] of the available width.
  Widget _bar(ColorScheme cs, double widthFactor) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: SizedBox(
        height: kDefaultPadding,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          ),
        ),
      ),
    );
  }
}

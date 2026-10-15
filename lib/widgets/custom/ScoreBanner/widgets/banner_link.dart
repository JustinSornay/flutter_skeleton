// banner_link.dart
//
// Private underlined link of ScoreBanner: an InkWell on its own transparent
// Material (so the ink paints above the banner fill) with a 48 dp minimum hit
// area and its own link + button semantics node.

part of "../index.dart";

final class _BannerLink extends StatelessWidget {
  final String label;

  /// Text and underline colour (the tone onContainer).
  final Color color;

  final VoidCallback onTap;

  const _BannerLink({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = Theme.of(context).textTheme.labelMedium ?? const TextStyle();

    // A container keeps the link flags on this node instead of merging them
    // into the banner's node.
    return Semantics(
      container: true,
      link: true,
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
          mouseCursor: SystemMouseCursors.click,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: kMinTapTarget, minHeight: kMinTapTarget),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: kDefaultPadding),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: 1,
                child: Text(
                  label,
                  style: textStyle.copyWith(
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

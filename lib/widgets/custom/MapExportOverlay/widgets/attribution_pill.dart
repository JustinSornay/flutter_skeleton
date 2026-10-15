// attribution_pill.dart
//
// Private attribution pill of MapExportOverlay: the joined source credits on
// a small translucent inverse-surface pill. Wraps (centred) when the line is
// wider than the overlay.

part of "../index.dart";

/// Corner radius of the pill.
const double _pillRadius = 4;

/// Font size of the credits.
const double _creditsFontSize = 9;

final class _AttributionPill extends StatelessWidget {
  /// Credits line, already joined.
  final String text;

  const _AttributionPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.inverseSurface.withValues(alpha: _chipAlpha),
        borderRadius: BorderRadius.circular(_pillRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding,
          vertical: kDefaultPadding / 2,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: _overlayTextStyle(
            context,
            fontSize: _creditsFontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

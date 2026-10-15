// image_header.dart
//
// _ImageHeader — full-width hero of PreviewConfirmSheet: the host image at
// 180 dp (cover), or the decorative icon placeholder (_Placeholder) at
// 120 dp when there is no image and at 180 dp when the image fails to load.

part of "../index.dart";

/// Height of the hero image, and of the placeholder replacing a failed one.
const double _imageHeight = 180;

/// Height of the placeholder shown when there is no image.
const double _placeholderHeight = kDefaultPadding * 15;

/// Size of the placeholder icon.
const double _placeholderIconSize = kDefaultPadding * 6;

final class _ImageHeader extends StatelessWidget {
  final ImageProvider? image;
  final IconData placeholderIcon;
  final String? semanticLabel;

  const _ImageHeader({
    required this.image,
    required this.placeholderIcon,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final ImageProvider? provider = image;
    if (provider == null) {
      return _Placeholder(icon: placeholderIcon, height: _placeholderHeight);
    }
    final String? label = semanticLabel;
    final bool hasLabel = label != null && label.isNotEmpty;

    return SizedBox(
      height: _imageHeight,
      child: Image(
        image: provider,
        fit: BoxFit.cover,
        semanticLabel: hasLabel ? label : null,
        excludeFromSemantics: !hasLabel,
        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
          return _Placeholder(icon: placeholderIcon, height: _imageHeight);
        },
      ),
    );
  }
}

/// Decorative `cs.surfaceContainerHighest` box with a centred muted icon.
final class _Placeholder extends StatelessWidget {
  final IconData icon;
  final double height;

  const _Placeholder({required this.icon, required this.height});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: ColoredBox(
          color: cs.surfaceContainerHighest,
          child: Center(
            child: Icon(icon, size: _placeholderIconSize, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

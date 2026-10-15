// thumbnail.dart
//
// _Thumbnail — ThumbnailMetricCard's 56 × 56 rounded picture: the host image
// scaled to cover the box, or the placeholder icon on cs.surfaceContainerHighest
// when there is no image or it fails to load. Excluded from semantics.

part of "../index.dart";

/// Side of the thumbnail (56 dp).
const double _thumbnailSize = kDefaultPadding * 7;

/// Corner radius of the thumbnail.
const double _thumbnailRadius = kDefaultPadding;

/// Size of the placeholder icon.
const double _placeholderIconSize = 24;

final class _Thumbnail extends StatelessWidget {
  /// Picture to show; null → placeholder.
  final ImageProvider<Object>? image;

  /// Icon of the placeholder.
  final IconData placeholderIcon;

  const _Thumbnail({required this.image, required this.placeholderIcon});

  @override
  Widget build(BuildContext context) {
    final ImageProvider<Object>? provider = image;

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_thumbnailRadius),
        child: SizedBox.square(
          dimension: _thumbnailSize,
          child: provider == null
              ? _placeholder(context)
              : Image(
                  image: provider,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (BuildContext context, Object _, StackTrace? _) => _placeholder(context),
                ),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return ColoredBox(
      color: cs.surfaceContainerHighest,
      child: Center(
        child: Icon(placeholderIcon, size: _placeholderIconSize, color: cs.onSurfaceVariant),
      ),
    );
  }
}

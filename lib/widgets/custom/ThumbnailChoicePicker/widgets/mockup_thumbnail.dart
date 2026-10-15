// mockup_thumbnail.dart
//
// _MockupThumbnail — the built-in thumbnail of ThumbnailChoice.scheme: a
// miniature app (top bar, sidebar, an accent line and two text lines)
// coloured from a ColorScheme, optionally over a background image under a
// surface veil. Purely decorative: its card excludes it from semantics.

part of "../index.dart";

// Drawing dimensions of the miniature (tuned for the default 96 × 64 frame),
// not layout spacing. They fit any frame of at least kMinTapTarget sides.

/// Height of the top bar.
const double _topBarHeight = 10;

/// Width of the sidebar and gap between the sidebar and the content.
const double _sidebarWidth = 15;
const double _sidebarGap = 3;

/// Padding around the content lines.
const double _contentPadding = 4;

/// Height, corner radius and vertical gap of the content lines.
const double _lineHeight = 4;
const double _lineRadius = 2;
const double _lineGap = 3;

/// Widths of the accent line and of the short last line, as a fraction of
/// the content width (52 and 38 of 66 dp at the default size).
const double _accentLineFactor = 0.8;
const double _shortLineFactor = 0.58;

/// Image variant: opacity of the surface veil over the image and of the
/// translucent chrome.
const double _veilAlpha = 0.42;
const double _imageTopBarAlpha = 0.89;
const double _imageSidebarAlpha = 0.75;
const double _imageLineAlpha = 0.7;

final class _MockupThumbnail extends StatelessWidget {
  const _MockupThumbnail({required this.scheme, required this.backgroundImage});

  final ColorScheme scheme;

  /// Drawn under a surface veil when set.
  final ImageProvider<Object>? backgroundImage;

  @override
  Widget build(BuildContext context) {
    final ImageProvider<Object>? image = backgroundImage;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ColoredBox(color: scheme.surface),
        if (image != null) ...<Widget>[
          Image(
            image: image,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: _imageError,
          ),
          ColoredBox(color: scheme.surface.withValues(alpha: _veilAlpha)),
        ],
        _chrome(hasImage: image != null),
      ],
    );
  }

  /// A failed image leaves the plain surface visible.
  static Widget _imageError(BuildContext context, Object error, StackTrace? stackTrace) {
    return const SizedBox.shrink();
  }

  /// Top bar over a row of the sidebar and the content lines.
  Widget _chrome({required bool hasImage}) {
    final Color topBar = hasImage
        ? scheme.surfaceContainerHigh.withValues(alpha: _imageTopBarAlpha)
        : scheme.surfaceContainerHigh;
    final Color sidebar = hasImage
        ? scheme.surfaceContainer.withValues(alpha: _imageSidebarAlpha)
        : scheme.surfaceContainer;
    final Color line = hasImage ? scheme.surface.withValues(alpha: _imageLineAlpha) : scheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(height: _topBarHeight, child: ColoredBox(color: topBar)),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(width: _sidebarWidth, child: ColoredBox(color: sidebar)),
              const SizedBox(width: _sidebarGap),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(_contentPadding),
                  child: _lines(line),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Accent line, full-width line and short line, vertically centred.
  Widget _lines(Color line) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        FractionallySizedBox(widthFactor: _accentLineFactor, child: _line(scheme.primary)),
        const SizedBox(height: _lineGap),
        _line(line),
        const SizedBox(height: _lineGap),
        FractionallySizedBox(widthFactor: _shortLineFactor, child: _line(line)),
      ],
    );
  }

  Widget _line(Color color) {
    return SizedBox(
      height: _lineHeight,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(_lineRadius),
        ),
      ),
    );
  }
}

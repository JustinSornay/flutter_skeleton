// thumbnail_choice.dart
//
// Value class of ThumbnailChoicePicker: ThumbnailChoice<T>, one option (a
// shared ChoiceOption<T>) plus what its thumbnail shows — either a
// caller-supplied preview widget or the built-in mini app mockup drawn from
// a ColorScheme. No UI here.

part of "index.dart";

/// One option of a [ThumbnailChoicePicker]: the [option] it selects and the
/// content of its thumbnail.
@immutable
final class ThumbnailChoice<T> {
  /// Option whose thumbnail shows [preview], sized to fill the frame and
  /// clipped to its rounded corners.
  const ThumbnailChoice({
    required this.option,
    required Widget this.preview,
  })  : scheme = null,
        backgroundImage = null;

  /// Option whose thumbnail is the built-in mini app mockup coloured from
  /// [scheme] (for example `AppTheme.dark().colorScheme`): body `surface`,
  /// top bar `surfaceContainerHigh`, sidebar `surfaceContainer`, an accent
  /// line in `primary` and two text lines in `outlineVariant`.
  ///
  /// When [backgroundImage] is set it is drawn with [BoxFit.cover] under a
  /// `surface` veil (42 % opacity) and the chrome turns translucent (top bar
  /// 89 %, sidebar 75 %, text lines `surface` at 70 %). While the image
  /// loads, or if it fails, the plain `surface` shows instead.
  const ThumbnailChoice.scheme({
    required this.option,
    required ColorScheme this.scheme,
    this.backgroundImage,
  }) : preview = null;

  /// Value, caption, enabled state and spoken label of the card.
  final ChoiceOption<T> option;

  /// Caller-supplied thumbnail content; null for a mockup.
  final Widget? preview;

  /// Colours of the built-in mockup; null for a custom [preview].
  final ColorScheme? scheme;

  /// Optional image behind the mockup chrome.
  final ImageProvider<Object>? backgroundImage;
}

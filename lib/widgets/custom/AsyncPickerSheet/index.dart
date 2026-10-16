// index.dart
//
// AsyncPickerSheet<T> — sheet content for picking one value and committing it
// with an async call. Header (title + close button), an inline error banner
// and a caller-built picker body that a busy overlay covers while the call
// runs. State lives in view_model.dart, the tree in view.dart and the private
// pieces in widgets/.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/utils/load_state.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/custom/Loader/index.dart";

part "view_model.dart";
part "view.dart";
part "widgets/busy_body.dart";
part "widgets/error_banner.dart";
part "widgets/sheet_header.dart";

/// Builds the picker body. Call [onPicked] with the chosen value to submit it.
typedef AsyncPickerBodyBuilder<T> = Widget Function(
  BuildContext context,
  ValueChanged<T> onPicked,
);

/// Sheet content that lets the user pick one value of type [T] and commits it
/// with [onSubmit].
///
/// - [title]: header text, already localised by the host.
/// - [builder]: the picker that fills the space under the header (list,
///   search, tabs…). It receives an `onPicked` callback to call with the
///   chosen value. Hiding values that cannot be picked is the builder's job.
/// - [onSubmit]: commits the picked value. Repeat picks are ignored while it
///   runs; a translucent overlay with a [Loader] covers the body and blocks
///   taps. Throw to keep the sheet open: an inline error banner (live region)
///   then shows [errorMessage] for that error, or the default
///   `custom.async_picker_sheet.submit_failed` message when [errorMessage] is
///   null or returns null. Picking again clears the banner and retries.
/// - [onSubmitted]: called with the value once [onSubmit] completed, if the
///   widget is still mounted. The host closes the sheet here.
/// - [onClose]: the close button, enabled even while [onSubmit] runs. The
///   widget never pops a route itself.
///
/// Closing while [onSubmit] runs does not cancel the call. When the call
/// settles during the host's closing animation, [onSubmitted] still fires.
/// Once the widget is disposed, the outcome is dropped: [onSubmitted] is not
/// called even if the call succeeds. A host that lets the user close while
/// busy must not read a missing [onSubmitted] as "nothing was committed".
/// It should refresh its own data instead.
///
/// Content only: no drag handle, no background, no route handling. Host it
/// with [AsyncPickerSheet.show] (modal bottom sheet with the M3 drag handle,
/// resolves with the submitted value) or inside `AppModal`. The body is
/// `Expanded`, so the widget needs a bounded height. It paints its own
/// transparent [Material] for the body's ink (row ripples, tile colours).
///
/// The close button has a [Tooltip]: the widget needs an [Overlay] ancestor
/// (a routed page or a modal).
///
/// Built-in strings: `custom.async_picker_sheet.close` (close tooltip) and
/// `custom.async_picker_sheet.submit_failed` (default error message).
final class AsyncPickerSheet<T> extends StatefulWidget {
  final String title;
  final AsyncPickerBodyBuilder<T> builder;
  final Future<void> Function(T value) onSubmit;
  final ValueChanged<T> onSubmitted;
  final VoidCallback onClose;
  final String? Function(Object error)? errorMessage;

  const AsyncPickerSheet({
    super.key,
    required this.title,
    required this.builder,
    required this.onSubmit,
    required this.onSubmitted,
    required this.onClose,
    this.errorMessage,
  });

  /// Opens the sheet in a modal bottom sheet (`showDragHandle: true`,
  /// `cs.surfaceContainerLow`, top radius 16) sized to [heightFactor] of the
  /// height left above the keyboard. The sheet follows the keyboard, so a
  /// search field in the body never hides the last rows.
  ///
  /// Resolves with the submitted value, or null when the sheet is closed (close
  /// button, scrim tap, drag) before a submit succeeds. Closing while a submit
  /// runs does not cancel it. The result is then null even if that submit
  /// succeeds later, so refresh the host's data instead of relying on a
  /// non-null result alone. Uses `<V>` so the static method does not shadow
  /// the class's `<T>`.
  static Future<V?> show<V>({
    required BuildContext context,
    required String title,
    required AsyncPickerBodyBuilder<V> builder,
    required Future<void> Function(V value) onSubmit,
    String? Function(Object error)? errorMessage,
    double heightFactor = 0.9,
  }) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return showModalBottomSheet<V>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (BuildContext sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: FractionallySizedBox(
          heightFactor: heightFactor,
          child: AsyncPickerSheet<V>(
            title: title,
            builder: builder,
            onSubmit: onSubmit,
            errorMessage: errorMessage,
            onSubmitted: (V value) => _popSheet<V>(sheetContext, value),
            onClose: () => _popSheet<V>(sheetContext, null),
          ),
        ),
      ),
    );
  }

  /// Pops the sheet's own route, only while it is still the current route
  /// (a submit that completes during the closing animation must not pop the
  /// page underneath).
  static void _popSheet<V>(BuildContext sheetContext, V? result) {
    final ModalRoute<Object?>? route = ModalRoute.of(sheetContext);
    if (route == null || !route.isCurrent) return;
    Navigator.of(sheetContext).pop<V>(result);
  }

  @override
  State<AsyncPickerSheet<T>> createState() => _AsyncPickerSheetState<T>();
}

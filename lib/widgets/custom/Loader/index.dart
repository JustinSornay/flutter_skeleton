// index.dart
//
// Loader — the app's standard indeterminate progress indicator with an
// accessible label. Use it instead of a bare CircularProgressIndicator.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";

part "view.dart";

/// Accessible circular loading indicator.
final class Loader extends StatelessWidget with _ViewMixin {
  /// Diameter in logical pixels.
  final double size;

  const Loader({
    super.key,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

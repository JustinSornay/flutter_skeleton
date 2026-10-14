// index.dart
//
// OfflineBanner — a full-width banner that slides down from the top of the
// screen whenever the device loses internet connectivity.
//
// Watches ConnectivityProvider.isOffline and delegates all visual logic to
// _ViewMixin (view.dart). It collapses to zero height while online.
//
// Related:
//   view.dart                            — slide + fade animation, Semantics liveRegion
//   providers/connectivity_provider.dart — isOffline source of truth

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/providers/connectivity_provider.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:provider/provider.dart";

part "view.dart";

/// Full-width offline indicator that animates in from the top when the device
/// loses connectivity and animates out when it reconnects.
final class OfflineBanner extends StatelessWidget with _ViewMixin {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

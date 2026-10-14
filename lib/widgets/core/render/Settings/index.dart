// index.dart
//
// Settings — demo render widget: language selection (EasyLocalization
// persists the choice) and an "About" dialog mounted through ModalProvider.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/providers/modal_provider.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:flutter_skeleton/widgets/layout/AppModal/index.dart";
import "package:provider/provider.dart";

part "view.dart";

/// Application settings.
final class Settings extends StatelessWidget with _ViewMixin {
  const Settings({super.key});

  /// Switches the UI language. EasyLocalization saves it for the next launch.
  Future<void> selectLanguage(BuildContext context, String languageCode) {
    return context.setLocale(Locale(languageCode));
  }

  /// Mounts the About dialog as a global modal overlay.
  void showAbout(BuildContext context) {
    final ModalProvider modal = context.read<ModalProvider>();
    modal.show(_aboutModal(context, modal.dismiss));
  }

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

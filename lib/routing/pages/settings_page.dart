// settings_page.dart
//
// Route `/settings` — application settings.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/routing/templates/FullPageTemplate/index.dart";
import "package:flutter_skeleton/widgets/core/render/Settings/index.dart";

/// Settings page.
final class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FullPageTemplate(
      title: "settings.title".tr(),
      child: const Settings(),
    );
  }
}

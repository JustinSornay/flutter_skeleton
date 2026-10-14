// not_found_page.dart
//
// Rendered by GoRouter's errorBuilder for any location that matches no route,
// and by route builders that receive an invalid path parameter.

import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter_skeleton/widgets/constants.dart";
import "package:go_router/go_router.dart";

/// 404 page with a way back home.
final class NotFoundPage extends StatelessWidget {
  final String? attemptedPath;

  const NotFoundPage({super.key, this.attemptedPath});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding * 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                "404",
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: kDefaultPadding),
              Text(
                "not_found.title".tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (attemptedPath != null) ...<Widget>[
                const SizedBox(height: kDefaultPadding),
                Text(
                  attemptedPath!,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    fontFamily: "monospace",
                  ),
                ),
              ],
              const SizedBox(height: kDefaultPadding * 4),
              FilledButton(
                onPressed: () => context.go("/"),
                child: Text("not_found.back_home".tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

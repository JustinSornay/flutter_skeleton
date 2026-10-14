// nav_items.dart
//
// Static navigation configuration consumed by AppHeader. Add an entry here
// (and the matching GoRoute in routing/router/router.dart) to expose a new
// top-level page in the header.

import "package:flutter/material.dart";

/// A top-level navigation entry shown in the AppHeader.
final class NavItem {
  /// Route path passed to `context.go()`.
  final String path;

  /// Translation key of the visible label.
  final String labelKey;

  final IconData icon;

  const NavItem({
    required this.path,
    required this.labelKey,
    required this.icon,
  });

  /// True when [location] belongs to this entry. The root route uses an exact
  /// match so it does not light up for every path.
  bool isActive(String location) {
    return path == "/" ? location == "/" : location.startsWith(path);
  }
}

/// Ordered header navigation entries.
const List<NavItem> kNavItems = <NavItem>[
  NavItem(path: "/", labelKey: "nav.home", icon: Icons.checklist_rounded),
  NavItem(path: "/settings", labelKey: "nav.settings", icon: Icons.settings_outlined),
];

// view.dart
//
// _ViewMixin — rendering for AppHeader.
//
// Wide (≥ kNavBreakpoint): title on the left, one TextButton per nav entry.
// Narrow: title on the left, a menu button listing the same entries.
// The active entry is emphasised with the primary colour AND a bolder weight
// so the state never relies on colour alone.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, _AppHeaderState state) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool isWide = MediaQuery.sizeOf(context).width >= kNavBreakpoint;

    return Semantics(
      container: true,
      header: true,
      child: Container(
        height: kAppHeaderHeight,
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 2),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          border: Border(bottom: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          children: <Widget>[
            _title(context, cs),
            const Spacer(),
            if (isWide)
              for (final NavItem item in kNavItems)
                _navLink(context, cs, item, isActive: item.isActive(state.currentPath))
            else
              _navMenu(context, state.currentPath),
          ],
        ),
      ),
    );
  }

  Widget _title(BuildContext context, ColorScheme cs) {
    return InkWell(
      onTap: () => context.go("/"),
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinTapTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
          child: Center(
            widthFactor: 1,
            child: Text(
              "app.title".tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: cs.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navLink(BuildContext context, ColorScheme cs, NavItem item, {required bool isActive}) {
    return Padding(
      padding: const EdgeInsets.only(left: kDefaultPadding),
      child: TextButton.icon(
        onPressed: () => context.go(item.path),
        style: TextButton.styleFrom(
          minimumSize: const Size(kMinTapTarget, kMinTapTarget),
          foregroundColor: isActive ? cs.primary : cs.onSurfaceVariant,
          backgroundColor: isActive ? cs.primaryContainer.withValues(alpha: 0.4) : null,
        ),
        icon: Icon(item.icon, size: 18),
        label: Text(
          item.labelKey.tr().toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 0.8,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _navMenu(BuildContext context, String currentPath) {
    return PopupMenuButton<String>(
      tooltip: "nav.menu".tr(),
      icon: const Icon(Icons.menu_rounded),
      onSelected: (String path) => context.go(path),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        for (final NavItem item in kNavItems)
          CheckedPopupMenuItem<String>(
            value: item.path,
            checked: item.isActive(currentPath),
            child: Text(item.labelKey.tr()),
          ),
      ],
    );
  }
}

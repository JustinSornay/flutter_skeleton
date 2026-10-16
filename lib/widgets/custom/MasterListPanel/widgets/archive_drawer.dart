// archive_drawer.dart
//
// _ArchiveDrawer — stateless pull-up drawer pinned to the bottom of
// MasterListPanel, listing archived items. Its snap (closed / mid / full) is
// owned by the panel view-model: closed is a 48 dp "Archived (n)" pill, mid
// and full are 42 % and 80 % of the panel height with a down chevron on the
// handle, then a title and the dimmed archived rows (_ArchivedRow) scrolled
// together. The drawer is tap-driven, so it draws no drag grip. Only the
// 48 dp handle is fixed, which fits the smallest snap height. The height
// animates through resolveMotion; the content is laid out at the target
// height and clipped while the drawer grows, so it never overflows.

part of "../index.dart";

/// Height animation of the drawer.
const Duration _drawerMotion = Duration(milliseconds: 260);

/// Top corner radius of the drawer.
const BorderRadius _drawerRadius = BorderRadius.vertical(top: Radius.circular(16));

/// Opacity of archived rows (dimmed look).
const double _archivedOpacity = 0.78;

final class _ArchiveDrawer extends StatelessWidget {
  final _DrawerSnap snap;

  /// Height of the panel; must be finite.
  final double panelHeight;

  /// Archived items of the active tab.
  final List<MasterListItem> items;

  final String title;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelect;

  const _ArchiveDrawer({
    required this.snap,
    required this.panelHeight,
    required this.items,
    required this.title,
    required this.onToggle,
    required this.onSelect,
  });

  bool get _open => snap != _DrawerSnap.closed;

  double get _height => switch (snap) {
        _DrawerSnap.closed => kMinTapTarget,
        _DrawerSnap.mid => math.max(kMinTapTarget, panelHeight * 0.42),
        _DrawerSnap.full => math.max(kMinTapTarget, panelHeight * 0.80),
      };

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double height = _height;
    return AnimatedContainer(
      duration: resolveMotion(context, _drawerMotion),
      curve: Curves.easeOutCubic,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: _drawerRadius,
        boxShadow: <BoxShadow>[
          BoxShadow(color: cs.shadow.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: height,
          maxHeight: height,
          child: Column(
            children: <Widget>[
              _handle(context),
              if (_open) Expanded(child: _content(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _handle(BuildContext context) {
    final String pill = "custom.master_list_panel.archived_pill".tr(
      namedArgs: <String, String>{"count": "${items.length}"},
    );
    return Semantics(
      container: true,
      button: true,
      expanded: _open,
      label: pill,
      onTap: onToggle,
      excludeSemantics: true,
      child: InkWell(
        onTap: onToggle,
        child: SizedBox(
          height: kMinTapTarget,
          width: double.infinity,
          child: Center(child: _open ? _chevron(context) : _pill(context, pill)),
        ),
      ),
    );
  }

  /// Open state of the handle: a tap affordance, not a drag grip.
  Widget _chevron(BuildContext context) {
    return Icon(Icons.keyboard_arrow_down, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant);
  }

  Widget _pill(BuildContext context, String text) {
    final ThemeData theme = Theme.of(context);
    final Color color = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.inventory_2_outlined, size: 14, color: color),
        const SizedBox(width: kDefaultPadding * 0.75),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: color),
          ),
        ),
        const SizedBox(width: kDefaultPadding * 0.75),
        Icon(Icons.keyboard_arrow_up, size: 14, color: color),
      ],
    );
  }

  Widget _title(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(kDefaultPadding * 2, kDefaultPadding / 2, kDefaultPadding * 2, kDefaultPadding),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          header: true,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  /// Title + archived rows (or the empty text), scrolled together.
  Widget _content(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(child: _title(context)),
        if (items.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: _empty(context))
        else
          SliverList.builder(
            itemCount: items.length,
            itemBuilder: (BuildContext context, int index) {
              final MasterListItem item = items[index];
              return _ArchivedRow(key: ValueKey<String>(item.id), item: item, onTap: () => onSelect(item.id));
            },
          ),
      ],
    );
  }

  Widget _empty(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Text(
        "custom.master_list_panel.archived_empty".tr(),
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// Dimmed archive drawer row: title + trailing, optional caption.
final class _ArchivedRow extends StatelessWidget {
  final MasterListItem item;
  final VoidCallback onTap;

  const _ArchivedRow({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? caption = item.archivedCaption;
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: Opacity(
          opacity: _archivedOpacity,
          child: InkWell(
            onTap: onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cs.outlineVariant))),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: kMinTapTarget),
                child: Padding(
                  padding: _rowPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _TitleLine(title: item.title, trailing: item.trailing),
                      if (caption != null) ...<Widget>[
                        const SizedBox(height: kDefaultPadding / 4),
                        Text(
                          caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

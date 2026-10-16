// view.dart
//
// _ViewMixin — tree of MasterListPanel: a rounded cs.surfaceContainerLow
// Material panel stacking the column (create button, tab bar, body, space
// reserved for the closed drawer) under the archive drawer pinned to the
// bottom. The body is an exhaustive switch on the load state: pulsing
// skeleton rows, error + retry, empty state or the selectable rows.

part of "index.dart";

/// Corner radius of the panel.
const double _panelRadius = 12;

/// Number of skeleton rows while loading.
const int _skeletonRows = 5;

/// Small vertical gap (4 dp) between stacked texts.
const double _textGap = kDefaultPadding / 2;

mixin _ViewMixin {
  Widget render(BuildContext context, _MasterListPanelState state) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final MasterListPanel widget = state.widget;
    final TabController? tabController = state.tabController;
    return Material(
      color: cs.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_panelRadius),
        side: BorderSide(color: cs.outlineVariant, width: 0.5),
      ),
      child: SizedBox(
        width: widget.width,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) => Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Column(
                children: <Widget>[
                  if (widget.onCreate != null) _createButton(context, state),
                  if (tabController != null) _tabBar(context, state, tabController),
                  Expanded(child: _body(context, state)),
                  if (state.drawerVisible) const SizedBox(height: kMinTapTarget),
                ],
              ),
              if (state.drawerVisible) _drawer(state, constraints.maxHeight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawer(_MasterListPanelState state, double panelHeight) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: TapRegion(
        onTapOutside: (PointerDownEvent _) => state.closeDrawer(),
        child: _ArchiveDrawer(
          snap: state.snap,
          panelHeight: panelHeight,
          items: state.archivedItems,
          title: state.archivedTitle,
          onToggle: state.cycleSnap,
          onSelect: state.widget.onSelect,
        ),
      ),
    );
  }

  Widget _createButton(BuildContext context, _MasterListPanelState state) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kDefaultPadding * 1.5,
        kDefaultPadding * 1.5,
        kDefaultPadding * 1.5,
        kDefaultPadding,
      ),
      child: SizedBox(
        height: kMinTapTarget,
        width: double.infinity,
        child: FilledButton(
          onPressed: state.create,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 2),
            textStyle: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.add, size: 16),
              const SizedBox(width: _textGap),
              Flexible(child: Text(state.createLabel, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBar(BuildContext context, _MasterListPanelState state, TabController controller) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return TabBar(
      controller: controller,
      onTap: state.selectTab,
      indicatorColor: cs.primary,
      indicatorWeight: 2,
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: cs.primary,
      unselectedLabelColor: cs.onSurfaceVariant,
      labelStyle: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8),
      labelPadding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      dividerColor: cs.outlineVariant,
      dividerHeight: 1,
      tabs: <Widget>[
        for (final MasterListTab tab in state.widget.tabs)
          Tab(
            child: Text(
              "custom.master_list_panel.tab_label".tr(
                namedArgs: <String, String>{"label": tab.label, "count": "${state.countFor(tab.id)}"},
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _body(BuildContext context, _MasterListPanelState state) {
    final MasterListPanel widget = state.widget;
    return switch (widget.state) {
      Idle<List<MasterListItem>>() || Loading<List<MasterListItem>>() => _skeleton(context),
      LoadError<List<MasterListItem>>() => _errorState(context, widget.onRetry),
      Loaded<List<MasterListItem>>() => _list(context, state),
    };
  }

  Widget _list(BuildContext context, _MasterListPanelState state) {
    final MasterListPanel widget = state.widget;
    final List<MasterListItem> items = state.activeItems;
    if (items.isEmpty) return _emptyState(context, widget);
    final Color divider = Theme.of(context).colorScheme.outlineVariant;
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (BuildContext context, int index) => Divider(height: 1, thickness: 1, color: divider),
      itemBuilder: (BuildContext context, int index) {
        final MasterListItem item = items[index];
        return _ItemRow(
          key: ValueKey<String>(item.id),
          item: item,
          selected: item.id == widget.selectedId,
          maxVisibleTags: widget.maxVisibleTags,
          onTap: () => widget.onSelect(item.id),
        );
      },
    );
  }

  Widget _skeleton(BuildContext context) {
    final Color divider = Theme.of(context).colorScheme.outlineVariant;
    return Semantics(
      label: "custom.master_list_panel.loading".tr(),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _skeletonRows,
        separatorBuilder: (BuildContext context, int index) => Divider(height: 1, thickness: 1, color: divider),
        itemBuilder: (BuildContext context, int index) => const SkeletonPulse(child: _SkeletonRow()),
      ),
    );
  }

  Widget _errorState(BuildContext context, VoidCallback? onRetry) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return _centered(<Widget>[
      Text(
        "custom.master_list_panel.error_title".tr(),
        textAlign: TextAlign.center,
        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.error),
      ),
      const SizedBox(height: _textGap),
      Text(
        "custom.master_list_panel.error_hint".tr(),
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
      ),
      if (onRetry != null) ...<Widget>[
        const SizedBox(height: kDefaultPadding * 1.5),
        OutlinedButton(
          onPressed: onRetry,
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.primary,
            side: BorderSide(color: cs.primary),
            minimumSize: const Size(kMinTapTarget, kMinTapTarget),
            textStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text("custom.master_list_panel.retry".tr()),
        ),
      ],
    ]);
  }

  Widget _emptyState(BuildContext context, MasterListPanel widget) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? message = widget.emptyMessage;
    return _centered(<Widget>[
      Text(
        widget.emptyTitle ?? "custom.master_list_panel.empty_title".tr(),
        textAlign: TextAlign.center,
        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
      ),
      if (message != null) ...<Widget>[
        const SizedBox(height: _textGap),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    ]);
  }

  /// Centred, scrollable column so short panels never overflow.
  Widget _centered(List<Widget> children) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 2.5, vertical: kDefaultPadding * 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

// view_model.dart
//
// _MasterListPanelState — local UI state of MasterListPanel: the optional
// TabController (created only with 2+ tabs, recreated when the tab count or
// the reduced-motion setting changes, index clamped), the active tab, and the
// archive drawer snap. Derives the active / archived item lists filtered by
// the active tab. The item list itself is owned by the host.

part of "index.dart";

/// Snap points of the archive drawer.
enum _DrawerSnap { closed, mid, full }

final class _MasterListPanelState extends State<MasterListPanel> with TickerProviderStateMixin, _ViewMixin {
  /// Tab bar controller; null when fewer than 2 tabs are given.
  TabController? tabController;

  /// Index of the active tab in [MasterListPanel.tabs] (0 without tabs).
  int _tabIndex = 0;

  /// Current snap of the archive drawer.
  _DrawerSnap snap = _DrawerSnap.closed;

  bool get _showTabs => widget.tabs.length >= 2;

  /// Active tab, or null when the tab bar is hidden.
  MasterListTab? get activeTab => _showTabs ? widget.tabs[_tabIndex] : null;

  /// Items of a `Loaded` state, else an empty list.
  List<MasterListItem> get _items => widget.state.dataOrNull ?? const <MasterListItem>[];

  bool _inActiveTab(MasterListItem item) {
    final MasterListTab? tab = activeTab;
    return tab == null || item.tabId == tab.id;
  }

  /// Non-archived items of the active tab.
  List<MasterListItem> get activeItems =>
      _items.where((MasterListItem item) => !item.archived && _inActiveTab(item)).toList();

  /// Archived items of the active tab.
  List<MasterListItem> get archivedItems =>
      _items.where((MasterListItem item) => item.archived && _inActiveTab(item)).toList();

  /// Number of non-archived items tagged with [tabId].
  int countFor(String tabId) =>
      _items.where((MasterListItem item) => !item.archived && item.tabId == tabId).length;

  /// The drawer shows only for a loaded list, when the host allows it.
  bool get drawerVisible => widget.showArchived && widget.state is Loaded<List<MasterListItem>>;

  String get createLabel => activeTab?.createLabel ?? widget.createLabel ?? "custom.master_list_panel.create".tr();

  String get archivedTitle =>
      activeTab?.archivedTitle ?? widget.archivedTitle ?? "custom.master_list_panel.archived_title".tr();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTabController();
  }

  @override
  void didUpdateWidget(MasterListPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!drawerVisible) snap = _DrawerSnap.closed;
    _syncTabController();
  }

  /// Keeps [tabController] matching the tab count and the motion setting.
  void _syncTabController() {
    final int length = _showTabs ? widget.tabs.length : 0;
    _tabIndex = length == 0 ? 0 : math.min(_tabIndex, length - 1);
    final TabController? current = tabController;
    if (length == 0) {
      current?.dispose();
      tabController = null;
      return;
    }
    final Duration duration = resolveMotion(context, kTabScrollDuration);
    if (current != null && current.length == length && current.animationDuration == duration) return;
    current?.dispose();
    tabController = TabController(
      length: length,
      initialIndex: _tabIndex,
      animationDuration: duration,
      vsync: this,
    );
  }

  /// Tab bar tap: switches the filter and notifies the host on a change.
  void selectTab(int index) {
    if (index == _tabIndex) return;
    setState(() => _tabIndex = index);
    widget.onTabChanged?.call(widget.tabs[index].id);
  }

  /// Create button tap, with the active tab id.
  void create() => widget.onCreate?.call(activeTab?.id);

  /// Drawer handle tap: closed → mid → full → closed.
  void cycleSnap() {
    setState(() {
      snap = switch (snap) {
        _DrawerSnap.closed => _DrawerSnap.mid,
        _DrawerSnap.mid => _DrawerSnap.full,
        _DrawerSnap.full => _DrawerSnap.closed,
      };
    });
  }

  /// Tap outside the drawer: closes it.
  void closeDrawer() {
    if (snap == _DrawerSnap.closed) return;
    setState(() => snap = _DrawerSnap.closed);
  }

  @override
  void dispose() {
    tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}

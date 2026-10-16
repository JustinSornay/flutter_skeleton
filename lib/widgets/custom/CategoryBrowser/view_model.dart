// view_model.dart
//
// _CategoryBrowserState — the open group key, the list's ScrollController
// (external or owned), one GlobalKey per group tile (pruned when groups
// disappear) and the reveal scroll that brings a toggled group into view
// once the tiles have stopped resizing, unless the user scrolls first.

part of "index.dart";

/// Duration of the reveal scroll.
const Duration _kRevealDuration = Duration(milliseconds: 300);

/// Where the revealed group lands: 0.1 puts its top a tenth of the free
/// viewport space (viewport minus tile height) below the top edge.
const double _kRevealAlignment = 0.1;

/// Frames the reveal waits at most for the layout to settle.
const int _kMaxSettleFrames = 30;

final class _CategoryBrowserState<T> extends State<CategoryBrowser<T>> with _ViewMixin<T> {
  /// Key of the open group; null when every group is closed.
  String? openKey;

  /// Controller created on demand when the host passes none.
  ScrollController? _ownController;

  /// Scroll targets, one per group key.
  final Map<String, GlobalKey<State<StatefulWidget>>> _tileKeys = <String, GlobalKey<State<StatefulWidget>>>{};

  /// Pending reveal, waiting for the tiles' resize time.
  Timer? _revealTimer;

  /// Bumped by every toggle and user scroll; a pending reveal with an older
  /// token is dropped.
  int _revealToken = 0;

  /// The host's controller, else the browser's own one.
  ScrollController get scrollController => widget.scrollController ?? (_ownController ??= ScrollController());

  @override
  void initState() {
    super.initState();
    assert(_hasUniqueKeys(widget.groups), "CategoryBrowser group keys must be unique");
    openKey = _openable(widget.initialOpenKey);
  }

  @override
  void didUpdateWidget(CategoryBrowser<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(_hasUniqueKeys(widget.groups), "CategoryBrowser group keys must be unique");
    openKey = _openable(openKey);
    final Set<String> keys = widget.groups.map((CategoryBrowserGroup<T> group) => group.key).toSet();
    _tileKeys.removeWhere((String key, GlobalKey<State<StatefulWidget>> _) => !keys.contains(key));
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }

  /// Scroll target of the tile showing the group [key].
  GlobalKey<State<StatefulWidget>> keyFor(String key) {
    return _tileKeys.putIfAbsent(key, () => GlobalKey<State<StatefulWidget>>(debugLabel: key));
  }

  /// Opens [group] (closing any other one) or closes it when already open,
  /// reports the new open key and scrolls the group into view.
  void toggle(CategoryBrowserGroup<T> group) {
    setState(() => openKey = openKey == group.key ? null : group.key);
    widget.onOpenChanged?.call(openKey);
    _scheduleReveal(group.key);
  }

  /// Drops a pending reveal as soon as the user scrolls the list: the
  /// user's gesture wins over a scroll aimed at the tapped group. A drag
  /// (or fling) is caught when it starts, before it has moved the list; a
  /// mouse wheel by its user scroll direction. Scrolls not driven by the
  /// user (the reveal itself, the host's controller) carry neither and are
  /// ignored. The notification keeps bubbling.
  bool onScroll(ScrollNotification notification) {
    final bool byUser =
        (notification is ScrollStartNotification && notification.dragDetails != null) ||
        (notification is UserScrollNotification && notification.direction != ScrollDirection.idle);
    if (byUser) {
      _revealTimer?.cancel();
      _revealToken++;
    }
    return false;
  }

  /// [key] when it names an expandable group, else null.
  String? _openable(String? key) {
    final bool exists = widget.groups.any((CategoryBrowserGroup<T> group) => group.key == key && group.expandable);
    return exists ? key : null;
  }

  bool _hasUniqueKeys(List<CategoryBrowserGroup<T>> groups) {
    return groups.map((CategoryBrowserGroup<T> group) => group.key).toSet().length == groups.length;
  }

  /// Scrolls the group [key] into view once the tiles have stopped
  /// resizing. Scrolling right away would aim at a layout that is still
  /// changing: a group closing above shifts the target up, and a group
  /// growing at the end of the list has not yet extended the scroll range.
  ///
  /// Under reduced motion the tiles resize instantly, so the next frame is
  /// final. Otherwise the reveal waits for the tiles' resize time
  /// (ExpandableGroupTile animates over kMotionShort), then for two
  /// consecutive frames with the same layout. A newer toggle supersedes a
  /// pending reveal and a user scroll cancels it ([onScroll]).
  void _scheduleReveal(String key) {
    final int token = ++_revealToken;
    final Duration settle = resolveMotion(context, kMotionShort);
    _revealTimer?.cancel();
    if (settle == Duration.zero) {
      _afterNextFrame(() => _reveal(token, key));
      return;
    }
    _revealTimer = Timer(settle, () {
      _afterNextFrame(() => _revealWhenSettled(token, key, null, _kMaxSettleFrames));
    });
  }

  /// Runs [callback] after the next frame, scheduling one if needed.
  void _afterNextFrame(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((Duration _) => callback());
    WidgetsBinding.instance.scheduleFrame();
  }

  /// Compares the layout of [key] with the [previous] frame's; reveals when
  /// it is unchanged (or [framesLeft] runs out), else checks again after the
  /// next frame.
  void _revealWhenSettled(int token, String key, (double, double)? previous, int framesLeft) {
    if (!mounted || token != _revealToken) return;
    final (double, double)? layout = _layoutOf(key);
    if (layout == null) return;
    if (layout == previous || framesLeft == 0) {
      _reveal(token, key);
      return;
    }
    _afterNextFrame(() => _revealWhenSettled(token, key, layout, framesLeft - 1));
  }

  /// Scroll offset that would reveal the tile [key], and the list's scroll
  /// range; null when the tile is not laid out.
  (double, double)? _layoutOf(String key) {
    final BuildContext? tileContext = _tileKeys[key]?.currentContext;
    final RenderObject? box = tileContext?.findRenderObject();
    final ScrollableState? scrollable = tileContext == null ? null : Scrollable.maybeOf(tileContext);
    if (box == null || scrollable == null) return null;
    final double offset = RenderAbstractViewport.of(box).getOffsetToReveal(box, _kRevealAlignment).offset;
    return (offset, scrollable.position.maxScrollExtent);
  }

  void _reveal(int token, String key) {
    final BuildContext? tileContext = _tileKeys[key]?.currentContext;
    if (!mounted || token != _revealToken || tileContext == null) return;
    unawaited(
      Scrollable.ensureVisible(
        tileContext,
        duration: resolveMotion(context, _kRevealDuration),
        curve: Curves.easeInOut,
        alignment: _kRevealAlignment,
      ),
    );
  }
}

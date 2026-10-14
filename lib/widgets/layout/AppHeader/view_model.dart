// view_model.dart
//
// _AppHeaderState — keeps [currentPath] in sync with the router.
//
// Subscribes to GoRouter.routerDelegate once (didChangeDependencies) and
// unsubscribes in dispose so the listener never outlives the header.

part of "index.dart";

final class _AppHeaderState extends State<AppHeader> with _ViewMixin {
  GoRouterDelegate? _delegate;

  /// Path of the current location, used to highlight the active nav entry.
  String currentPath = "/";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final GoRouterDelegate delegate = GoRouter.of(context).routerDelegate;
    if (identical(delegate, _delegate)) return;
    _delegate?.removeListener(_onRouteChange);
    _delegate = delegate..addListener(_onRouteChange);
    currentPath = delegate.currentConfiguration.uri.path;
  }

  @override
  void dispose() {
    _delegate?.removeListener(_onRouteChange);
    super.dispose();
  }

  void _onRouteChange() {
    final String path = _delegate?.currentConfiguration.uri.path ?? "/";
    if (path == currentPath || !mounted) return;
    setState(() => currentPath = path);
  }

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

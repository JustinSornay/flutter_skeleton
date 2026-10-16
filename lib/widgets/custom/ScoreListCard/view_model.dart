// view_model.dart
//
// _ScoreListCardState — load lifecycle of ScoreListCard as a
// LoadState<List<T>>: Loading from creation, then Loaded or LoadError. The
// error is logged and swallowed; retry() goes back to Loading and calls the
// host's load again. Every update after the await is guarded by `mounted`.

part of "index.dart";

final class _ScoreListCardState<T> extends State<ScoreListCard<T>> with _ViewMixin<T> {
  /// Current load state, rendered by the view with an exhaustive switch.
  LoadState<List<T>> items = Loading<List<T>>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Only the host's [ScoreListCard.load] sits inside the try, so a framework
  /// error from the `Loaded` update is never mistaken for a load failure.
  Future<void> _load() async {
    final List<T> result;
    try {
      result = await widget.load();
    } catch (e) {
      Logger().e("ScoreListCard._load: $e");
      if (!mounted) return;
      setState(() => items = LoadError<List<T>>("$e"));
      return;
    }
    if (!mounted) return;
    setState(() => items = Loaded<List<T>>(result));
  }

  /// Error state's retry: back to the skeleton and a fresh [ScoreListCard.load].
  void retry() {
    setState(() => items = Loading<List<T>>());
    _load();
  }

  /// Tap handler of the row showing [item], or null when the rows are inert.
  VoidCallback? tapOf(T item) {
    final ValueChanged<T>? onItemTap = widget.onItemTap;
    if (onItemTap == null) return null;
    return () => onItemTap(item);
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}

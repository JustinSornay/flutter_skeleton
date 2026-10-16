// view_model.dart
//
// _StatusPillGroupState — load lifecycle of StatusPillGroup as a
// LoadState<List<StatusPillGroupItem>>: Loading from creation, then Loaded or
// LoadError. The error is logged and swallowed; every update after the await
// is guarded by `mounted`.

part of "index.dart";

final class _StatusPillGroupState extends State<StatusPillGroup> with _ViewMixin {
  /// Current load state, rendered by the view with an exhaustive switch.
  LoadState<List<StatusPillGroupItem>> items = const Loading<List<StatusPillGroupItem>>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Only the host's [StatusPillGroup.load] sits inside the try, so a
  /// framework error from the `Loaded` update is never mistaken for a load
  /// failure.
  Future<void> _load() async {
    final List<StatusPillGroupItem> result;
    try {
      result = await widget.load();
    } catch (e) {
      Logger().e("StatusPillGroup._load: $e");
      if (!mounted) return;
      setState(() => items = LoadError<List<StatusPillGroupItem>>("$e"));
      return;
    }
    if (!mounted) return;
    setState(() => items = Loaded<List<StatusPillGroupItem>>(result));
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}

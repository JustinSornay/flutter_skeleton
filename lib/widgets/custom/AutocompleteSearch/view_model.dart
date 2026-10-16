// view_model.dart
//
// _AutocompleteSearchState — owns the text controller, the debounce timer and
// the dropdown's OverlayPortalController. Each call to the host's search gets
// an id; only the latest id may update the results, which keeps slow, older
// responses from overwriting newer ones or reopening a closed dropdown.

part of "index.dart";

final class _AutocompleteSearchState<T> extends State<AutocompleteSearch<T>>
    with _ViewMixin<T> {
  final TextEditingController _controller = TextEditingController();
  final LayerLink _link = LayerLink();
  final OverlayPortalController _portal = OverlayPortalController();

  /// Shared by the field's and the dropdown's TapRegion: a tap in either one
  /// is "inside".
  final Object _tapGroup = Object();

  /// Results of the latest settled call.
  List<T> _results = <T>[];

  /// True from a qualifying keystroke until the latest call settles.
  bool _isLoading = false;

  Timer? _debounceTimer;

  /// Id of the latest call; bumped to invalidate any call in flight.
  int _requestId = 0;

  /// Whether a debounced call is still waiting to start.
  bool get _hasPendingCall => _debounceTimer?.isActive ?? false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounceTimer?.cancel();
    final String query = value.trim();
    if (query.length < widget.minQueryLength) {
      _close();
      return;
    }
    if (!_isLoading) setState(() => _isLoading = true);
    _debounceTimer = Timer(widget.debounce, () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    final int id = ++_requestId;
    try {
      final List<T> results = await widget.search(query);
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = results;
        _isLoading = _hasPendingCall;
      });
      _portal.show();
    } catch (error) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _results = <T>[];
        _isLoading = _hasPendingCall;
      });
      _portal.hide();
      widget.onError?.call(error);
    }
  }

  void _select(T item) {
    _close();
    final String Function(T item)? selectionLabel = widget.selectionLabel;
    if (selectionLabel == null) {
      _controller.clear();
    } else {
      final String label = selectionLabel(item);
      _controller.value = TextEditingValue(
        text: label,
        selection: TextSelection.collapsed(offset: label.length),
      );
    }
    widget.onSelected(item);
  }

  /// Tap outside the field and the dropdown.
  void _onTapOutside(PointerDownEvent event) {
    if (_portal.isShowing || _isLoading) _close();
  }

  /// Tap on the field or inside the dropdown. While the dropdown is closed
  /// (so the tap is on the field) and no call is pending, a long enough
  /// query is searched again: dismissed results come back.
  void _onTapInside(PointerDownEvent event) {
    if (_portal.isShowing || _isLoading) return;
    if (_controller.text.trim().length < widget.minQueryLength) return;
    _onQueryChanged(_controller.text);
  }

  /// Cancels the pending call, invalidates the one in flight, stops the
  /// spinner and closes the dropdown. The field text is kept.
  void _close() {
    _debounceTimer?.cancel();
    _requestId++;
    setState(() {
      _results = <T>[];
      _isLoading = false;
    });
    _portal.hide();
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}

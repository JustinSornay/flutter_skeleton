// view_model.dart
//
// _LocationBarState — owns the visual mode (empty / selected / editing), the
// focus anchor around the search field, the field generation (bumped to
// rebuild the field empty) and the current-location call (busy flag plus a
// call id so an outdated result is dropped). didUpdateWidget follows the
// host's value: new value while editing or in empty mode → selected; null
// value while selected → empty.
//
// The search layout keeps one switcher key in empty and editing modes, and
// AnimatedSwitcher reuses an outgoing child whose key matches the new one:
// going back from the selected row before the cross-fade ends revives the
// old search layout. Leaving the selected mode therefore bumps the generation
// so the field never comes back with old text or a pending search.

part of "index.dart";

final class _LocationBarState<T> extends State<LocationBar<T>> with _ViewMixin<T> {
  late _LocationBarMode _mode;

  /// Wraps the search field: reports when the field gains focus and lets the
  /// bar move focus into a freshly built field. Never focused itself.
  final FocusNode _fieldAnchor = FocusNode(
    debugLabel: "LocationBar field",
    canRequestFocus: false,
    skipTraversal: true,
  );

  /// Key of the search field; bumped to rebuild it empty (drops its text,
  /// its pending call and its results).
  int _fieldGeneration = 0;

  /// True while [LocationBar.onUseCurrentLocation] runs.
  bool _isLocating = false;

  /// Id of the latest current-location call; bumped to drop the one in
  /// flight.
  int _locateId = 0;

  @override
  void initState() {
    super.initState();
    _mode = widget.value == null ? _LocationBarMode.empty : _LocationBarMode.selected;
  }

  @override
  void didUpdateWidget(covariant LocationBar<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final _LocationBarMode next = _modeAfterUpdate(oldWidget);
    if (next == _mode) return;
    _switchMode(next);
    _dropLocate();
  }

  @override
  void dispose() {
    _fieldAnchor.dispose();
    super.dispose();
  }

  /// Mode implied by the host's new [LocationBar.value].
  _LocationBarMode _modeAfterUpdate(LocationBar<T> oldWidget) {
    final T? value = widget.value;
    if (value == null) {
      return _mode == _LocationBarMode.selected ? _LocationBarMode.empty : _mode;
    }
    final bool changedWhileEditing = _mode == _LocationBarMode.editing && value != oldWidget.value;
    if (_mode == _LocationBarMode.empty || changedWhileEditing) return _LocationBarMode.selected;
    return _mode;
  }

  /// Sets the mode; leaving the selected row rebuilds the search field empty.
  /// Call inside setState (or from didUpdateWidget).
  void _switchMode(_LocationBarMode next) {
    if (_mode == _LocationBarMode.selected) _fieldGeneration++;
    _mode = next;
  }

  /// Invalidates the current-location call in flight. Call inside setState
  /// (or from didUpdateWidget).
  void _dropLocate() {
    _locateId++;
    _isLocating = false;
  }

  /// Removes focus from the search field when it holds it.
  void _dropFieldFocus() {
    if (_fieldAnchor.hasFocus) FocusManager.instance.primaryFocus?.unfocus();
  }

  /// Focus entered the search field: empty mode becomes editing.
  void _onFieldFocusChange(bool focused) {
    if (!focused || _mode != _LocationBarMode.empty) return;
    setState(() => _mode = _LocationBarMode.editing);
    widget.onEditingStarted?.call();
  }

  /// Tap on the selected row: open the search and focus the new field.
  void _startEditing() {
    if (_mode != _LocationBarMode.selected) return;
    setState(() => _switchMode(_LocationBarMode.editing));
    widget.onEditingStarted?.call();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) => _focusField());
  }

  /// Focuses the text field, the only focusable node under the anchor while
  /// the fresh field's dropdown is closed.
  void _focusField() {
    if (!mounted || _mode != _LocationBarMode.editing) return;
    _fieldAnchor.traversalDescendants.firstOrNull?.requestFocus();
  }

  void _cancelEditing() {
    _dropFieldFocus();
    setState(() {
      _dropLocate();
      if (widget.value == null) {
        _mode = _LocationBarMode.empty;
        _fieldGeneration++;
      } else {
        _mode = _LocationBarMode.selected;
      }
    });
    widget.onEditingCancelled?.call();
  }

  void _select(LocationSuggestion<T> suggestion) {
    _dropFieldFocus();
    setState(() {
      _dropLocate();
      _mode = _LocationBarMode.selected;
    });
    widget.onSelected(suggestion);
  }

  Future<void> _useCurrentLocation() async {
    final Future<LocationSuggestion<T>?> Function()? locate = widget.onUseCurrentLocation;
    if (locate == null || _isLocating) return;
    final int id = ++_locateId;
    setState(() => _isLocating = true);
    LocationSuggestion<T>? found;
    Object? failure;
    try {
      found = await locate();
    } catch (error) {
      failure = error;
    }
    if (!mounted || id != _locateId) return;
    setState(() => _isLocating = false);
    if (failure != null) {
      widget.onError?.call(failure);
    } else if (found != null) {
      _select(found);
    }
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}

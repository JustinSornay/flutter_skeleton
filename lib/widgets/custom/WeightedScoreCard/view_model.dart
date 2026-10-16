// view_model.dart
//
// _WeightedScoreCardState — the weights (always adding up to 1), the
// debounce timer and the evaluation lifecycle as a
// LoadState<WeightedScoreResult>, plus the last settled result that keeps the
// alert chip in place during a re-evaluation. A request counter drops stale
// results; every update after an await is guarded with `mounted`. Assertion
// failures from the host's evaluator are reported, not only displayed.

part of "index.dart";

final class _WeightedScoreCardState extends State<WeightedScoreCard> with _ViewMixin {
  /// Current weight of each component, in [WeightedScoreCard.components] order.
  late List<double> weights;

  /// Latest evaluation, rendered by the view with an exhaustive switch.
  LoadState<WeightedScoreResult> evaluation = const Idle<WeightedScoreResult>();

  /// Result of the last settled evaluation: the loaded result, or null before
  /// the first one, after an error and after a components reset. Unlike
  /// [evaluation], it survives a re-evaluation, so the alert chip does not
  /// disappear and come back each time the debounce fires.
  WeightedScoreResult? lastResult;

  Timer? _debounce;

  /// Id of the latest evaluation; older results are ignored.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    weights = _defaultWeights();
    evaluation = const Loading<WeightedScoreResult>();
    unawaited(_request());
  }

  @override
  void didUpdateWidget(WeightedScoreCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sameIds(oldWidget.components, widget.components)) return;
    _debounce?.cancel();
    weights = _defaultWeights();
    evaluation = const Loading<WeightedScoreResult>();
    lastResult = null;
    unawaited(_request());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// Moves the weight at [index] to [value], rebalances the others and
  /// restarts the debounce timer.
  void onWeightChanged(int index, double value) {
    setState(() => weights = WeightedScoreMix.rebalance(weights, index, value));
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, _evaluate);
  }

  void _evaluate() {
    setState(() => evaluation = const Loading<WeightedScoreResult>());
    unawaited(_request());
  }

  /// Calls [WeightedScoreCard.evaluate] with the current weights and stores
  /// the outcome unless a newer request started or the card is gone.
  Future<void> _request() async {
    final int requestId = ++_requestId;
    final Map<String, double> mix = Map<String, double>.unmodifiable(<String, double>{
      for (int i = 0; i < widget.components.length; i++) widget.components[i].id: weights[i],
    });
    LoadState<WeightedScoreResult> next;
    try {
      next = Loaded<WeightedScoreResult>(await widget.evaluate(mix));
    } catch (error, stack) {
      // A broken contract (e.g. a score outside [0, 1]) is a host bug: surface
      // it to the developer instead of only showing the error text. Checked
      // with `is` because avoid_catching_errors forbids `on AssertionError`.
      if (error is AssertionError) _reportContractError(error, stack);
      next = LoadError<WeightedScoreResult>(error.toString());
    }
    if (!mounted || requestId != _requestId) return;
    setState(() {
      evaluation = next;
      lastResult = next.dataOrNull;
    });
  }

  static void _reportContractError(AssertionError error, StackTrace stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: "WeightedScoreCard",
        context: ErrorDescription("while evaluating a weight mix"),
      ),
    );
  }

  List<double> _defaultWeights() {
    final List<WeightedScoreComponent> components = widget.components;
    assert(components.length >= 2, "WeightedScoreCard needs at least two components");
    assert(
      components.map((WeightedScoreComponent component) => component.id).toSet().length == components.length,
      "WeightedScoreCard component ids must be unique",
    );
    return WeightedScoreMix.normalise(<double>[
      for (final WeightedScoreComponent component in components) component.defaultWeight,
    ]);
  }

  static bool _sameIds(List<WeightedScoreComponent> a, List<WeightedScoreComponent> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}

// view_model.dart
//
// _AsyncSummaryCardState — load lifecycle of AsyncSummaryCard as a
// LoadState<AsyncSummary>: Loading from creation, then Loaded or LoadError.
// Reloads on retry and when reloadKey changes. A request id drops results
// that a newer load superseded, and `mounted` guards every update after the
// await. Also holds the pure **bold** tokenizer the view renders.

part of "index.dart";

/// One run of body text, plain or bold.
typedef _TextRun = ({String text, bool bold});

final class _AsyncSummaryCardState extends State<AsyncSummaryCard> with _ViewMixin {
  /// `**x**` on one line, shortest match first.
  static final RegExp _boldPattern = RegExp(r"\*\*(.+?)\*\*");

  /// Current load state, rendered by the view with an exhaustive switch.
  LoadState<AsyncSummary> summary = const Loading<AsyncSummary>();

  /// Id of the latest load; a result is applied only while its id is current.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AsyncSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reloadKey == oldWidget.reloadKey) return;
    // build() always follows didUpdateWidget, so no setState is needed.
    summary = const Loading<AsyncSummary>();
    _load();
  }

  /// Error state's retry: back to the skeleton and a fresh [AsyncSummaryCard.load].
  void retry() {
    setState(() => summary = const Loading<AsyncSummary>());
    _load();
  }

  /// Only the host's [AsyncSummaryCard.load] sits inside the try, so a
  /// framework error from the `Loaded` update is never mistaken for a load
  /// failure.
  Future<void> _load() async {
    final int requestId = ++_requestId;
    final AsyncSummary result;
    try {
      result = await widget.load();
    } catch (e) {
      Logger().e("AsyncSummaryCard._load: $e");
      if (!_isCurrent(requestId)) return;
      setState(() => summary = LoadError<AsyncSummary>("$e"));
      return;
    }
    if (!_isCurrent(requestId)) return;
    setState(() => summary = Loaded<AsyncSummary>(result));
  }

  bool _isCurrent(int requestId) => mounted && requestId == _requestId;

  /// Splits [text] into plain and bold runs (markers removed), or returns it
  /// as one plain run when [AsyncSummaryCard.parseBold] is false.
  List<_TextRun> runsOf(String text) {
    if (!widget.parseBold) return <_TextRun>[(text: text, bold: false)];

    final List<_TextRun> runs = <_TextRun>[];
    int lastEnd = 0;
    for (final RegExpMatch match in _boldPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        runs.add((text: text.substring(lastEnd, match.start), bold: false));
      }
      runs.add((text: match.group(1) ?? "", bold: true));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) runs.add((text: text.substring(lastEnd), bold: false));
    return runs;
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}

// view_model.dart
//
// _ValueMatrixState — the load lifecycle (LoadState of the pivoted values,
// chunked loadColumn calls, a generation counter that drops superseded
// results, retry, reload when the row or column ids change), the sort column
// and direction, the default value formatter and the CSV export.

part of "index.dart";

final class _ValueMatrixState extends State<ValueMatrix> with _ViewMixin {
  /// rowId → columnId → value once loaded.
  LoadState<Map<String, Map<String, double>>> _state = const Loading<Map<String, Map<String, double>>>();

  /// Incremented by every load; a result from an older load is dropped.
  int _generation = 0;

  /// Id of the sort column; null keeps the rows order.
  String? _sortColumnId;

  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ValueMatrix oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(_rowIds(oldWidget), _rowIds(widget)) || !listEquals(_columnIds(oldWidget), _columnIds(widget))) {
      _state = const Loading<Map<String, Map<String, double>>>();
      _load();
    }
  }

  static List<String> _rowIds(ValueMatrix matrix) {
    return matrix.rows.map((ValueMatrixRow row) => row.id).toList(growable: false);
  }

  static List<String> _columnIds(ValueMatrix matrix) {
    return matrix.columns.map((ValueMatrixColumn column) => column.id).toList(growable: false);
  }

  /// Loads every column, [ValueMatrix.maxConcurrent] at a time, then pivots
  /// the results. A newer load (or dispose) makes this one a no-op.
  Future<void> _load() async {
    final int generation = ++_generation;
    final List<ValueMatrixColumn> columns = widget.columns;
    final Future<Map<String, double>> Function(String columnId) loadColumn = widget.loadColumn;
    // The constructor asserts > 0; clamp so a release build cannot spin.
    final int chunkSize = widget.maxConcurrent < 1 ? 1 : widget.maxConcurrent;
    final Map<String, Map<String, double>> byColumn = <String, Map<String, double>>{};
    try {
      for (int start = 0; start < columns.length; start += chunkSize) {
        final Iterable<ValueMatrixColumn> chunk = columns.skip(start).take(chunkSize);
        await Future.wait<void>(chunk.map((ValueMatrixColumn column) async {
          byColumn[column.id] = await loadColumn(column.id);
        }));
        if (!_isCurrent(generation)) return;
      }
      setState(() => _state = Loaded<Map<String, Map<String, double>>>(ValueMatrixTable.pivot(byColumn)));
    } catch (e) {
      Logger().e("ValueMatrix._load: $e");
      if (!_isCurrent(generation)) return;
      setState(() => _state = LoadError<Map<String, Map<String, double>>>("$e"));
    }
  }

  bool _isCurrent(int generation) => mounted && generation == _generation;

  /// Error state's retry: back to the Loader and a fresh load.
  void retry() {
    setState(() => _state = const Loading<Map<String, Map<String, double>>>());
    _load();
  }

  /// Header tap: sorts by [columnId] descending, or reverses the direction
  /// when it already is the sort column.
  void sortBy(String columnId) {
    setState(() {
      if (_sortColumnId == columnId) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnId = columnId;
        _sortAscending = false;
      }
    });
  }

  /// Sort direction of [columnId]: null when it is not the sort column.
  bool? sortAscendingOf(String columnId) => _sortColumnId == columnId ? _sortAscending : null;

  /// Pure view of the loaded values for the current rows and columns.
  ValueMatrixTable table(Map<String, Map<String, double>> values) {
    return ValueMatrixTable(rows: widget.rows, columns: widget.columns, values: values);
  }

  /// Visible rows in the current sort order.
  List<ValueMatrixRow> orderedRows(ValueMatrixTable table) {
    return table.sortedRows(_sortColumnId, ascending: _sortAscending);
  }

  /// [ValueMatrix.formatValue], else `NumberFormat("0.00")` for the ambient
  /// locale (intl's default when that locale has no number data).
  String Function(double value) formatter(BuildContext context) {
    final String Function(double value)? custom = widget.formatValue;
    if (custom != null) return custom;
    final String? tag = Localizations.maybeLocaleOf(context)?.toLanguageTag();
    final String? locale = Intl.verifiedLocale(tag, NumberFormat.localeExists, onFailure: (String _) => null);
    return NumberFormat("0.00", locale).format;
  }

  /// Builds the CSV of [table] in the current sort order and hands it to
  /// [ValueMatrix.onExport].
  Future<void> export(ValueMatrixTable table) async {
    final Future<void> Function(String csv)? onExport = widget.onExport;
    if (onExport == null) return;
    final String csv = table.toCsv(
      orderedRows(table),
      rowHeader: widget.rowHeaderLabel ?? "",
      format: formatter(context),
    );
    await onExport(csv);
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}

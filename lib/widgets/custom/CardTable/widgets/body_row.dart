// body_row.dart
//
// _BodyRow — one CardTable row: a cs.outlineVariant top border, then the
// row content (one semantics node, an InkWell at least kMinTapTarget tall
// when tappable) and, when given, the full-width detail slot under it,
// outside the tap target.

part of "../index.dart";

/// Padding of the detail slot: aligned with the cells, 8 dp below.
const EdgeInsets _detailPadding = EdgeInsets.fromLTRB(
  kDefaultPadding * 2,
  0,
  kDefaultPadding * 2,
  kDefaultPadding,
);

final class _BodyRow<T> extends StatelessWidget {
  /// Item shown by this row.
  final T row;

  /// Columns from left to right.
  final List<CardTableColumn<T>> columns;

  /// Row tap; null makes the row non-interactive.
  final ValueChanged<T>? onTap;

  /// Summary read before the cells' text; none when null.
  final String? semanticLabel;

  /// Full-width content under the row; none when null.
  final Widget? detail;

  const _BodyRow({
    required this.row,
    required this.columns,
    required this.onTap,
    required this.semanticLabel,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final Widget? extra = detail;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _content(context),
          if (extra != null) Padding(padding: _detailPadding, child: extra),
        ],
      ),
    );
  }

  /// The cells, wrapped in the row's semantics node and, when tappable, in
  /// an [InkWell] at least [kMinTapTarget] tall.
  Widget _content(BuildContext context) {
    final ValueChanged<T>? tap = onTap;
    final Widget cells = Padding(
      padding: _rowPadding,
      child: Row(
        children: _columnSlots<T>(
          columns,
          (CardTableColumn<T> column) => column.cellBuilder(context, row),
        ),
      ),
    );

    return Semantics(
      container: true,
      button: tap != null,
      label: semanticLabel,
      child: tap == null
          ? cells
          : InkWell(
              onTap: () => tap(row),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: kMinTapTarget),
                child: cells,
              ),
            ),
    );
  }
}

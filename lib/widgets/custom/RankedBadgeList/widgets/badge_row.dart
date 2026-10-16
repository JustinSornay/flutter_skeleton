// badge_row.dart
//
// _BadgeRow — one row of RankedBadgeList: the item's StatusPill ("label ·
// value", one semantics node) and, when the host gives a trailingBuilder, an
// 8 dp gap and the trailing widget. Both share the row width. An item with
// no text at all renders nothing.

part of "../index.dart";

/// Separator between the label and the value inside a badge.
const String _valueSeparator = " · ";

final class _BadgeRow extends StatelessWidget {
  final RankedBadgeItem item;

  /// Builds the optional widget after the badge.
  final Widget Function(BuildContext context, RankedBadgeItem item)? trailingBuilder;

  const _BadgeRow({required this.item, required this.trailingBuilder});

  @override
  Widget build(BuildContext context) {
    final Widget Function(BuildContext context, RankedBadgeItem item)? builder = trailingBuilder;
    final String text = _text();
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding),
      child: Row(
        children: <Widget>[
          Flexible(
            child: StatusPill(
              label: text,
              tone: item.tone,
              semanticsLabel: _semanticsLabel(),
            ),
          ),
          if (builder != null) ...<Widget>[
            const SizedBox(width: kDefaultPadding),
            Flexible(child: builder(context, item)),
          ],
        ],
      ),
    );
  }

  /// The value, or null when there is none to show.
  String? get _value {
    final String? value = item.valueLabel;
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Visible badge text: "label · value", or the non-empty part alone.
  String _text() {
    final String? value = _value;
    if (value == null) return item.label;
    if (item.label.isEmpty) return value;
    return "${item.label}$_valueSeparator$value";
  }

  /// Non-empty host label, else "label, value" (null lets StatusPill use the
  /// text).
  String? _semanticsLabel() {
    final String? host = item.semanticsLabel;
    if (host != null && host.isNotEmpty) return host;
    final String? value = _value;
    if (value == null || item.label.isEmpty) return null;
    return "${item.label}, $value";
  }
}

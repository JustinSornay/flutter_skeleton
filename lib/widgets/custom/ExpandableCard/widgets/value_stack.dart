// value_stack.dart
//
// Private trailing key values of the ExpandableCard header: nothing, one
// value (13 / w800, cs.primary) or two values stacked (11 / w800 each,
// cs.primary then cs.tertiary), at most 80 dp wide and wrapping (end
// aligned) beyond. Excluded from semantics by the header, which reads the
// values in its own node.

part of "../index.dart";

/// Size of a lone value.
const double _singleValueSize = 13;

/// Size of each value in a stack of two.
const double _stackedValueSize = 11;

/// Widest the value stack may get (80 dp). A longer value wraps instead of
/// being cut, so no figure is lost. A fixed cap (not a LayoutBuilder
/// fraction) keeps the card's intrinsic sizes available.
const double _valueMaxWidth = kDefaultPadding * 10;

final class _ValueStack extends StatelessWidget {
  final String? primary;

  final String? secondary;

  const _ValueStack({
    required this.primary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final String? first = _nonEmpty(primary);
    if (first == null) return const SizedBox.shrink();

    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextStyle base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final String? second = _nonEmpty(secondary);
    // A non-flex header child gets an unbounded width: the cap makes a long
    // value wrap instead of overflowing the header.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _valueMaxWidth),
      child: second == null
          ? Text(
              first,
              textAlign: TextAlign.end,
              style: base.copyWith(fontSize: _singleValueSize, fontWeight: FontWeight.w800, color: cs.primary),
            )
          : _stack(base, cs, first, second),
    );
  }

  /// Primary value above the secondary one, both 11 / w800.
  Widget _stack(TextStyle base, ColorScheme cs, String first, String second) {
    final TextStyle stacked = base.copyWith(fontSize: _stackedValueSize, fontWeight: FontWeight.w800);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(first, textAlign: TextAlign.end, style: stacked.copyWith(color: cs.primary)),
        Text(second, textAlign: TextAlign.end, style: stacked.copyWith(color: cs.tertiary)),
      ],
    );
  }
}

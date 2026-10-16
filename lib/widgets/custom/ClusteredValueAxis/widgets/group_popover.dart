// group_popover.dart
//
// _GroupPopover — the 260 dp card listing a pill's rows: cs.surface Material
// (radius 10, cs.outlineVariant border) under a soft cs.shadow, scrolling
// past 320 dp. The Material sits inside the shadow so the rows' ink shows.

part of "../index.dart";

final class _GroupPopover extends StatelessWidget {
  static const double _width = 260;
  static const double _maxHeight = 320;

  /// _PopoverRow widgets (and the reference divider).
  final List<Widget> rows;

  const _GroupPopover({required this.rows});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final BorderRadius radius = BorderRadius.circular(10);

    return SizedBox(
      width: _width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: <BoxShadow>[
            BoxShadow(color: cs.shadow.withValues(alpha: 0.14), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Material(
          color: cs.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: cs.outlineVariant)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: _maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(kDefaultPadding / 2),
              child: Column(mainAxisSize: MainAxisSize.min, children: rows),
            ),
          ),
        ),
      ),
    );
  }
}

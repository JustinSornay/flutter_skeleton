// ghost_node.dart
//
// Ghost node of MapPolygonEditor: a translucent dot showing where the next
// tap lands (mouse hover only). Purely visual: no hits, no semantics.

part of "../index.dart";

final class _GhostNode extends StatelessWidget {
  const _GhostNode();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

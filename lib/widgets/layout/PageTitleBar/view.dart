// view.dart
//
// _ViewMixin — rendering logic for PageTitleBar.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, PageTitleBar widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant),
        ),
      ),
      child: Row(
        children: <Widget>[
          if (widget.leading != null)
          ...<Widget>[
            widget.leading!,
            const SizedBox(width: kDefaultPadding),
          ],
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          if (widget.trailing != null)
          ...<Widget>[
            const SizedBox(width: kDefaultPadding),
            widget.trailing!,
          ],
        ],
      ),
    );
  }
}

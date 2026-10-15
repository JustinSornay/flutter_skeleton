// pill_shell.dart
//
// _PillShell — shared shell of the cluster and reference pills: a 30 dp
// stadium (minimum width = the layout's width estimate) centred in a
// kMinTapTarget-tall hit box with a stadium ink response, announced as an
// expandable button that is selected while it holds the selection. The
// pill joins the popover's tap-region group, and the open pill carries the
// CompositedTransformTarget the popover follows. _PillAnchor bundles what
// the pill needs from the axis state.

part of "../index.dart";

/// Height of a pill.
const double _kPillHeight = 30;

/// What a pill needs from the axis state.
@immutable
final class _PillAnchor {
  const _PillAnchor({required this.minWidth, required this.tapGroup, required this.onTap, this.link});

  /// Width estimate from ValueAxisLayout.itemRenderedWidth.
  final double minWidth;

  /// Tap-region group shared with the popover.
  final Object tapGroup;

  /// Toggles the popover.
  final VoidCallback onTap;

  /// Popover link, set only while this pill is open.
  final LayerLink? link;

  bool get open => link != null;
}

final class _PillShell extends StatelessWidget {
  final _PillAnchor anchor;

  /// Fill, border and shadows of the stadium.
  final BoxDecoration decoration;

  /// Row content, centred.
  final List<Widget> content;

  final String semanticsLabel;
  final String semanticsHint;

  /// Holds the selection (announced to screen readers).
  final bool selected;

  const _PillShell({
    required this.anchor,
    required this.decoration,
    required this.content,
    required this.semanticsLabel,
    required this.semanticsHint,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    Widget pill = Container(
      constraints: BoxConstraints(minWidth: anchor.minWidth),
      height: _kPillHeight,
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      decoration: decoration,
      child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: content),
    );
    final LayerLink? link = anchor.link;
    if (link != null) pill = CompositedTransformTarget(link: link, child: pill);

    return TapRegion(
      groupId: anchor.tapGroup,
      child: Semantics(
        container: true,
        excludeSemantics: true,
        button: true,
        expanded: anchor.open,
        selected: selected,
        label: semanticsLabel,
        hint: semanticsHint,
        onTap: anchor.onTap,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: anchor.onTap,
            customBorder: const StadiumBorder(),
            child: SizedBox(
              height: kMinTapTarget,
              child: Center(widthFactor: 1, child: pill),
            ),
          ),
        ),
      ),
    );
  }
}

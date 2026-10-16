// view.dart
//
// Tree of VersionBadge: a PillBadge whose tone and icon follow isCurrent,
// carrying the accessible label. When tappable it sits in a 48 dp button
// (Semantics + InkWell with a stadium ink) whose tap hands a _DetailsPanel
// to the host.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, VersionBadge widget) {
    final Widget pill = PillBadge(
      label: widget.label,
      tone: widget.isCurrent ? StatusTone.primary : StatusTone.neutral,
      icon: widget.isCurrent ? Icons.verified_outlined : Icons.history,
      outlined: true,
      dense: widget.size == VersionBadgeSize.compact,
      semanticsLabel: _semanticsLabel(widget),
    );

    final VersionBadgeDetails? details = widget.details;
    final void Function(Widget panel)? onShowDetails = widget.onShowDetails;
    if (details == null || onShowDetails == null) return pill;

    return Semantics(
      button: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: kMinTapTarget,
          minHeight: kMinTapTarget,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => onShowDetails(
              _DetailsPanel(details: details, isCurrent: widget.isCurrent),
            ),
            child: Center(widthFactor: 1, heightFactor: 1, child: pill),
          ),
        ),
      ),
    );
  }

  /// [VersionBadge.semanticsLabel], or "label, current / outdated".
  String _semanticsLabel(VersionBadge widget) {
    final String? custom = widget.semanticsLabel;
    if (custom != null && custom.isNotEmpty) return custom;
    final String state = widget.isCurrent
        ? "custom.version_badge.current".tr()
        : "custom.version_badge.outdated".tr();
    return "${widget.label}, $state";
  }
}

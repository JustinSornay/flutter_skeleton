// view.dart
//
// View layer for FullPageTemplate.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, FullPageTemplate widget) {
    return Column(
      children: <Widget>[
        PageTitleBar(
          title: widget.title,
          leading: widget.onBack == null
              ? null
              : IconButton(
                  tooltip: "common.back".tr(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: widget.onBack,
                ),
          trailing: widget.trailing,
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}

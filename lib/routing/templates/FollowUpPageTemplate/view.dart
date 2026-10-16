// view.dart
//
// View layer for FollowUpPageTemplate: title bar with back button, padded
// scrolling body, and the pinned action bar.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, FollowUpPageTemplate widget) {
    final Widget? actions = widget.actions;

    return Column(
      children: <Widget>[
        PageTitleBar(
          title: widget.title,
          leading: IconButton(
            tooltip: "common.back".tr(),
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: widget.onBack,
          ),
          trailing: widget.trailing,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(kDefaultPadding * 2),
            child: _centred(widget.child),
          ),
        ),
        if (actions != null) _actionBar(context, actions),
      ],
    );
  }

  Widget _centred(Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
        child: child,
      ),
    );
  }

  Widget _actionBar(BuildContext context, Widget actions) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding * 2),
          child: _centred(actions),
        ),
      ),
    );
  }
}

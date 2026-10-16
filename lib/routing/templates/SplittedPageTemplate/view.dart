// view.dart
//
// View layer for SplittedPageTemplate: title bar, then a Row (wide) or a
// Column (narrow) of the two panels with a 1 dp divider between them.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, SplittedPageTemplate widget) {
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
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return constraints.maxWidth >= kSplitBreakpoint ? _sideBySide(widget) : _stacked(widget);
            },
          ),
        ),
      ],
    );
  }

  Widget _sideBySide(SplittedPageTemplate widget) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(width: widget.primaryWidth, child: widget.primary),
        const VerticalDivider(width: 1),
        Expanded(child: widget.secondary),
      ],
    );
  }

  Widget _stacked(SplittedPageTemplate widget) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(child: widget.primary),
        const Divider(height: 1),
        Expanded(child: widget.secondary),
      ],
    );
  }
}

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, ModalConsumer widget) {
    final Widget? modal = context.watch<ModalProvider>().currentModal;
    return Stack(
      children: <Widget>[
        widget.child,
        if (modal != null)
          Positioned.fill(child: modal),
      ],
    );
  }
}

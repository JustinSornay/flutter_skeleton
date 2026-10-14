part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, Loader widget) {
    return Semantics(
      label: "common.loading".tr(),
      child: SizedBox.square(
        dimension: widget.size,
        child: const CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }
}

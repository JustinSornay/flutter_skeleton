part of "index.dart";

final class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin, _ViewMixin {
  late AnimationController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.controller == null) {
      _internalController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _internalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => render(context, widget, _internalController);
}

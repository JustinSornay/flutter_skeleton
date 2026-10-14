// view_model.dart
//
// _AnimatedModalState — animation lifecycle for AppModal.
//
// Owns the AnimationController, drives fade + scale animations, and resolves
// the duration against the reduced-motion setting before the first frame.

part of "index.dart";

final class _AnimatedModalState extends State<_AnimatedModal>
    with SingleTickerProviderStateMixin, _ViewMixin {
  late final AnimationController ctrl;
  late final Animation<double> fade;
  late final Animation<double> scale;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    ctrl = AnimationController(vsync: this, duration: _kModalMotion);
    fade = CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic);
    scale = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ctrl.duration = resolveMotion(context, _kModalMotion);
    if (!_started) {
      _started = true;
      if (widget.isVisible) ctrl.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedModal old) {
    super.didUpdateWidget(old);
    if (widget.isVisible != old.isVisible) {
      widget.isVisible ? ctrl.forward() : ctrl.reverse();
    }
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => render(context, this);
}

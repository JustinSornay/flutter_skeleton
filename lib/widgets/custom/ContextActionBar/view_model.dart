// view_model.dart
//
// _ContextActionBarState — owns one AnimationController for the whole bar and
// one CurvedAnimation per button. On enter each button follows its own
// Interval of the controller (the stagger). On exit every button follows the
// plain curve, so they leave together. Durations go through resolveMotion
// and are refreshed when the dependencies or the number of buttons change.

part of "index.dart";

/// Enter duration of one button.
const Duration _enterDuration = kMotionShort;

/// Exit duration of the whole bar (all buttons together).
const Duration _exitDuration = Duration(milliseconds: 160);

/// Delay between the enter starts of two consecutive buttons.
const Duration _stagger = Duration(milliseconds: 30);

/// Curve of each button's fade and slide.
const Curve _curve = Curves.easeOutCubic;

final class _ContextActionBarState extends State<ContextActionBar>
    with SingleTickerProviderStateMixin, _ViewMixin {
  late final AnimationController _controller;

  /// One animation per entry of `widget.actions`, in the same order.
  List<CurvedAnimation> _animations = <CurvedAnimation>[];

  /// Whether the first-mount enter animation has been decided.
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _animations = _buildAnimations(widget.actions.length);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncDurations();
    if (_started) return;
    _started = true;
    if (widget.visible) _controller.forward();
  }

  @override
  void didUpdateWidget(ContextActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actions.length != widget.actions.length) {
      // The controller keeps its value: a visible bar stays visible.
      _disposeAnimations();
      _animations = _buildAnimations(widget.actions.length);
      _syncDurations();
    }
    if (oldWidget.visible == widget.visible) return;
    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _disposeAnimations();
    _controller.dispose();
    super.dispose();
  }

  /// Total enter time: the last button starts `(count - 1)` staggers late.
  static Duration _enterTotal(int count) {
    return _enterDuration + _stagger * (count > 1 ? count - 1 : 0);
  }

  void _syncDurations() {
    _controller
      ..duration = resolveMotion(context, _enterTotal(widget.actions.length))
      ..reverseDuration = resolveMotion(context, _exitDuration);
  }

  /// Button `i` enters during `[i * stagger, i * stagger + enter]` of the
  /// total enter time and exits along the plain curve.
  List<CurvedAnimation> _buildAnimations(int count) {
    // Integer numerators keep the last end at exactly 1.0.
    final int total = _enterTotal(count).inMicroseconds;
    final int step = _stagger.inMicroseconds;
    final int span = _enterDuration.inMicroseconds;
    return <CurvedAnimation>[
      for (int i = 0; i < count; i++)
        CurvedAnimation(
          parent: _controller,
          curve: Interval(i * step / total, (i * step + span) / total, curve: _curve),
          reverseCurve: _curve,
        ),
    ];
  }

  void _disposeAnimations() {
    for (final CurvedAnimation animation in _animations) {
      animation.dispose();
    }
    _animations = <CurvedAnimation>[];
  }

  @override
  Widget build(BuildContext context) {
    return render(context, this);
  }
}

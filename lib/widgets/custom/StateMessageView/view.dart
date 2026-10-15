// view.dart
//
// Layout of StateMessageView: tone-tinted icon badge, live-region title /
// message group, then the optional gauge (widgets/gauge_bar.dart) and action
// buttons (widgets/action_button.dart) capped at actionsMaxWidth. Colours
// come from the ColorScheme and StatusTones only.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, StateMessageView widget) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final ToneColors colors = StatusTones.colorsOf(context, widget.tone);
    final String? message = widget.message;
    final bool hasMessage = message != null && message.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding * 4,
            vertical: kDefaultPadding * 6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ExcludeSemantics(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: colors.container, shape: BoxShape.circle),
                  child: Icon(widget.icon ?? widget.tone.icon, size: 32, color: colors.foreground),
                ),
              ),
              const SizedBox(height: kDefaultPadding * 2),
              Semantics(
                container: true,
                liveRegion: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Semantics(
                      header: true,
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    if (hasMessage) ...<Widget>[
                      const SizedBox(height: kDefaultPadding),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              ..._footer(widget, colors),
            ],
          ),
        ),
      ),
    );
  }

  /// Gap + width-capped column with the gauge and the buttons; empty when
  /// there is nothing to show.
  List<Widget> _footer(StateMessageView widget, ToneColors colors) {
    final StateMessageGauge? gauge = widget.gauge;
    final StateMessageAction? primary = widget.primaryAction;
    final StateMessageAction? secondary = widget.secondaryAction;
    if (gauge == null && primary == null && secondary == null) {
      return const <Widget>[];
    }

    return <Widget>[
      const SizedBox(height: kSectionGap),
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.actionsMaxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (gauge != null) _GaugeBar(gauge: gauge, color: colors.foreground),
            if (primary != null) _ActionButton(action: primary, filled: true),
            if (primary != null && secondary != null) const SizedBox(height: kDefaultPadding),
            if (secondary != null) _ActionButton(action: secondary, filled: false),
          ],
        ),
      ),
    ];
  }
}

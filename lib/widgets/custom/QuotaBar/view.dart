// view.dart
//
// Tree of QuotaBar: either the unlimited row (title + unlimited label), or a
// Column holding one semantics node (header row + 5 dp pill bar) and, at the
// limit, the live "limit reached" row with the optional text-button action.
// Colours come from the ColorScheme and StatusTones only.

part of "index.dart";

/// Bar thickness (5 dp, as in the original look).
const double _barHeight = 5;

mixin _ViewMixin {
  Widget render(BuildContext context, QuotaBar widget) {
    if (widget.isUnlimited) return _unlimitedRow(context, widget);

    final Color toneColor = StatusTones.colorsOf(context, widget.tone).foreground;
    final String usage = "custom.quota_bar.usage_value".tr(
      namedArgs: <String, String>{"used": "${widget.displayedUsed}", "limit": "${widget.limit}"},
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          container: true,
          excludeSemantics: true,
          label: widget.title,
          value: usage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _header(context, widget, toneColor),
              const SizedBox(height: kDefaultPadding),
              _bar(context, widget.ratio, toneColor),
            ],
          ),
        ),
        if (widget.isAtLimit) ...<Widget>[
          const SizedBox(height: kDefaultPadding),
          _limitRow(context, widget, toneColor),
        ],
      ],
    );
  }

  Widget _unlimitedRow(BuildContext context, QuotaBar widget) {
    final String label = widget.unlimitedLabel ?? "custom.quota_bar.unlimited".tr();

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: widget.title,
      value: label,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(child: _title(context, widget.title)),
          const SizedBox(width: kDefaultPadding),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(BuildContext context, String title) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _header(BuildContext context, QuotaBar widget, Color toneColor) {
    return Row(
      children: <Widget>[
        Expanded(child: _title(context, widget.title)),
        const SizedBox(width: kDefaultPadding),
        Text.rich(
          TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: "${widget.displayedUsed}",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: toneColor),
              ),
              TextSpan(
                text: "/${widget.limit}",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bar(BuildContext context, double ratio, Color fill) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: ratio,
        minHeight: _barHeight,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(fill),
      ),
    );
  }

  Widget _limitRow(BuildContext context, QuotaBar widget, Color toneColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(
          child: Semantics(
            liveRegion: true,
            child: Text(
              widget.limitReachedLabel ?? "custom.quota_bar.limit_reached".tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: toneColor),
            ),
          ),
        ),
        if (widget.showAction) ...<Widget>[
          const SizedBox(width: kDefaultPadding),
          Flexible(child: _action(context, widget.actionLabel ?? "", widget.onAction)),
        ],
      ],
    );
  }

  Widget _action(BuildContext context, String label, VoidCallback? onAction) {
    final Color primary = Theme.of(context).colorScheme.primary;

    return TextButton(
      onPressed: onAction,
      style: TextButton.styleFrom(
        foregroundColor: primary,
        minimumSize: const Size(kMinTapTarget, kMinTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: primary,
          decoration: TextDecoration.underline,
          decorationColor: primary,
        ),
      ),
    );
  }
}

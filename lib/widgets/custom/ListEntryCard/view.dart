// view.dart
//
// Tree of ListEntryCard: one merged semantics node (a button when tappable)
// over an optional InkWell on a transparent Material, holding the header row
// (titles, StatusPill, chevron) and the optional body. Colours come from the
// ColorScheme only; the pill takes its colours from StatusTones.

part of "index.dart";

/// Corner radius of the ink highlight.
const double _inkRadius = kDefaultPadding;

/// Inner padding: 16 dp vertical, 4 dp horizontal.
const EdgeInsets _padding = EdgeInsets.symmetric(
  vertical: kDefaultPadding * 2,
  horizontal: kDefaultPadding / 2,
);

/// Gap between the title and the subtitle (2 dp).
const double _subtitleGap = kDefaultPadding / 4;

/// Gap between the titles and the pill (8 dp).
const double _badgeGap = kDefaultPadding;

/// Widest the pill may grow before its label ellipsizes (120 dp).
const double _badgeMaxWidth = kDefaultPadding * 15;

/// Gap before the chevron (4 dp).
const double _chevronGap = kDefaultPadding / 2;

/// Size of the chevron icon.
const double _chevronSize = 18;

/// Gap between the header and the body (12 dp).
const double _bodyGap = kDefaultPadding * 1.5;

/// [value], or null when it is null or empty.
String? _nonEmpty(String? value) {
  return value == null || value.isEmpty ? null : value;
}

mixin _ViewMixin {
  Widget render(BuildContext context, ListEntryCard widget) {
    final VoidCallback? onTap = widget.onTap;
    final Widget content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kMinTapTarget),
      child: Padding(padding: _padding, child: _content(context, widget)),
    );

    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        label: _semanticsLabel(widget),
        hint: onTap == null ? null : "custom.list_entry_card.open_hint".tr(),
        child: onTap == null
            ? content
            : Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(_inkRadius),
                  child: content,
                ),
              ),
      ),
    );
  }

  /// [ListEntryCard.semanticsLabel], else the non-empty title, subtitle and
  /// badge joined with ", ".
  String _semanticsLabel(ListEntryCard widget) {
    final String? override = _nonEmpty(widget.semanticsLabel);
    if (override != null) return override;

    return <String?>[widget.title, widget.subtitle, widget.badgeLabel]
        .whereType<String>()
        .where((String part) => part.isNotEmpty)
        .join(", ");
  }

  Widget _content(BuildContext context, ListEntryCard widget) {
    final Widget? body = widget.body;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ExcludeSemantics(child: _header(context, widget)),
        if (body != null) ...<Widget>[
          const SizedBox(height: _bodyGap),
          body,
        ],
      ],
    );
  }

  Widget _header(BuildContext context, ListEntryCard widget) {
    final String? badgeLabel = _nonEmpty(widget.badgeLabel);
    final bool chevron = widget.onTap != null && widget.showChevron;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: _titles(context, widget)),
        if (badgeLabel != null) ...<Widget>[
          const SizedBox(width: _badgeGap),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _badgeMaxWidth),
            child: StatusPill(label: badgeLabel, tone: widget.badgeTone, dense: true),
          ),
        ],
        if (chevron) ...<Widget>[
          const SizedBox(width: _chevronGap),
          Icon(
            Icons.chevron_right,
            size: _chevronSize,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ],
    );
  }

  Widget _titles(BuildContext context, ListEntryCard widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String? subtitle = _nonEmpty(widget.subtitle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            letterSpacing: -0.2,
            height: 1.2,
          ),
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: _subtitleGap),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ],
    );
  }
}

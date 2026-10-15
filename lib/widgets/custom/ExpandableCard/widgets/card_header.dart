// card_header.dart
//
// Private header of ExpandableCard: title with an optional StatusPill
// badge (at the trailing end of the title's line, or on its own line under
// it when both do not fit), optional subtitle, the key value stack
// (widgets/value_stack.dart) and the round chevron. The whole header is one
// button semantics node with an expanded state, a value joining the visible
// details and a localised hint; it is the only part of the card that
// toggles it.

part of "../index.dart";

/// Chevron circle diameter.
const double _chevronSize = kDefaultPadding * 3;

/// Chevron glyph size.
const double _chevronIconSize = kDefaultPadding * 2;

/// Title text size.
const double _titleSize = 13;

/// Subtitle text size.
const double _subtitleSize = 10;

final class _CardHeader extends StatelessWidget {
  final String title;

  final String? subtitle;

  final ExpandableCardBadge? badge;

  final String? primaryValue;

  final String? secondaryValue;

  final bool expanded;

  final VoidCallback onToggle;

  const _CardHeader({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.primaryValue,
    required this.secondaryValue,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final String hint = expanded
        ? "custom.expandable_card.collapse".tr()
        : "custom.expandable_card.expand".tr();

    // One node for the whole header: the visible texts are folded into the
    // label and value, and the tap is exposed on the node itself.
    return Semantics(
      container: true,
      button: true,
      expanded: expanded,
      label: title,
      value: _semanticsValue(),
      hint: hint,
      onTap: onToggle,
      excludeSemantics: true,
      child: InkWell(
        onTap: onToggle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              kDefaultPadding * 2,
              kDefaultPadding * 2,
              kDefaultPadding * 2,
              kDefaultPadding,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: _texts(context)),
                const SizedBox(width: kDefaultPadding),
                _ValueStack(primary: primaryValue, secondary: secondaryValue),
                const SizedBox(width: kDefaultPadding),
                _chevron(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Subtitle, badge label and key values, joined for screen readers.
  String _semanticsValue() {
    final String? primary = _nonEmpty(primaryValue);
    final List<String?> parts = <String?>[
      _nonEmpty(subtitle),
      _nonEmpty(badge?.label),
      primary,
      if (primary != null) _nonEmpty(secondaryValue),
    ];
    return parts.whereType<String>().join(", ");
  }

  /// Title line (title + optional badge) above the optional subtitle.
  ///
  /// The title line is a Wrap: the badge sits at its trailing end while both
  /// fit side by side, else it starts a line of its own under the title. The
  /// badge is laid out within the full text column, so a long label is
  /// ellipsised by the pill instead of overflowing, and the title never gets
  /// squeezed by it. A Row would give the non-flex badge an unbounded width,
  /// and a LayoutBuilder cap would drop the card's intrinsic sizes.
  Widget _texts(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextStyle base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final ExpandableCardBadge? pill = badge;
    final String? line = _nonEmpty(subtitle);

    return Column(
      mainAxisSize: MainAxisSize.min,
      // Stretch gives the title Wrap the column's full width, so spaceBetween
      // can push the badge to its trailing edge.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: kDefaultPadding / 2,
          runSpacing: kDefaultPadding / 2,
          children: <Widget>[
            Text(
              title,
              style: base.copyWith(
                fontSize: _titleSize,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            if (pill != null && pill.label.isNotEmpty)
              StatusPill(
                label: pill.label.toUpperCase(),
                tone: pill.tone,
                dense: true,
                semanticsLabel: pill.label,
              ),
          ],
        ),
        if (line != null) ...<Widget>[
          const SizedBox(height: kDefaultPadding / 4),
          Text(
            line,
            style: base.copyWith(
              fontSize: _subtitleSize,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  /// Decorative 24 dp circle; the header node already carries the state.
  Widget _chevron(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      width: _chevronSize,
      height: _chevronSize,
      decoration: BoxDecoration(
        color: expanded ? cs.tertiary : cs.surfaceContainerLowest,
        border: Border.all(color: expanded ? cs.tertiary : cs.outlineVariant),
        shape: BoxShape.circle,
      ),
      child: Icon(
        expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
        size: _chevronIconSize,
        color: expanded ? cs.onTertiary : cs.onSurfaceVariant,
      ),
    );
  }
}

/// [text] when it holds at least one character, else null.
String? _nonEmpty(String? text) {
  return (text == null || text.isEmpty) ? null : text;
}

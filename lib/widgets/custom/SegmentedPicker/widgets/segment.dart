// segment.dart
//
// Private segment of SegmentedPicker: one equal-width cell with a label, an
// optional second line, the animated selected pill (outlined in cs.primary
// so the selection is not colour-only), the dimmed locked / disabled states
// with an optional top-end corner icon the text keeps clear of, and its
// button semantics.

part of "../index.dart";

/// How a segment reacts to taps.
enum _Availability {
  /// Tapping selects the value.
  selectable,

  /// Dimmed with the locked icon; tapping calls onLockedTap.
  locked,

  /// Dimmed and inert (the option is not enabled).
  disabled,
}

/// Selected pill fade (original 160 ms), resolved through resolveMotion.
const Duration _segmentMotion = Duration(milliseconds: 160);

/// Corner radius of a segment and of its selected pill.
const double _segmentRadius = 6;

/// Opacity of locked and disabled segments.
const double _unavailableOpacity = 0.35;

/// Main line font size.
const double _labelFontSize = 12;

/// Second line font size.
const double _descriptionFontSize = 9;

/// Gap between the main line and the second line.
const double _lineGap = 2;

/// Selected pill outline. Unselected segments keep a transparent outline of
/// the same width, so the text keeps the same room (an ellipsized label is
/// not cut differently) when the selection changes.
const double _pillBorderWidth = 1.5;

/// Selected pill shadow.
const double _pillShadowAlpha = 0.07;
const double _pillShadowBlur = 6;
const Offset _pillShadowOffset = Offset(0, 1);

/// Locked icon size and inset from the top-end corner.
const double _lockedIconSize = 11;
const double _lockedIconInset = kDefaultPadding / 2;

/// Horizontal room the text leaves on each side of a segment that shows the
/// locked icon: the icon plus a small gap, on both sides so the text stays
/// centred like in the other segments.
const double _lockedIconClearance = _lockedIconSize + kDefaultPadding / 4;

final class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.description,
    required this.semanticsLabel,
    required this.selected,
    required this.availability,
    required this.lockedIcon,
    required this.onTap,
  });

  final String label;
  final String? description;
  final String? semanticsLabel;
  final bool selected;
  final _Availability availability;

  /// Drawn only when [availability] is locked.
  final IconData? lockedIcon;

  /// Null when the segment is inert.
  final VoidCallback? onTap;

  bool get _selectable => availability == _Availability.selectable;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(_segmentRadius);

    return Semantics(
      container: true,
      button: true,
      enabled: _selectable,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: _spokenLabel(),
      hint: _selectable ? null : "custom.segmented_picker.unavailable".tr(),
      child: Opacity(
        opacity: _selectable ? 1 : _unavailableOpacity,
        child: InkWell(
          onTap: onTap,
          mouseCursor: onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTapTarget),
            child: AnimatedContainer(
              duration: resolveMotion(context, _segmentMotion),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
              decoration: _pill(Theme.of(context).colorScheme, radius),
              child: ExcludeSemantics(child: _content(context)),
            ),
          ),
        ),
      ),
    );
  }

  String _spokenLabel() {
    final String? description = this.description;
    return semanticsLabel ?? (description == null ? label : "$label, $description");
  }

  BoxDecoration _pill(ColorScheme cs, BorderRadius radius) {
    return BoxDecoration(
      color: selected ? cs.surface : Colors.transparent,
      border: Border.all(
        color: selected ? cs.primary : Colors.transparent,
        width: _pillBorderWidth,
      ),
      borderRadius: radius,
      boxShadow: selected
          ? <BoxShadow>[
              BoxShadow(
                color: cs.shadow.withValues(alpha: _pillShadowAlpha),
                blurRadius: _pillShadowBlur,
                offset: _pillShadowOffset,
              ),
            ]
          : null,
    );
  }

  Widget _content(BuildContext context) {
    final IconData? icon = availability == _Availability.locked ? lockedIcon : null;

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: icon == null ? 0 : _lockedIconClearance),
          child: _lines(context),
        ),
        if (icon != null)
          PositionedDirectional(
            top: _lockedIconInset,
            end: 0,
            child: Icon(
              icon,
              size: _lockedIconSize,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _lines(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Color color = selected ? cs.primary : cs.onSurfaceVariant;
    final String? description = this.description;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _line(
          label,
          theme.textTheme.labelMedium?.copyWith(
            fontSize: _labelFontSize,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        if (description != null) ...<Widget>[
          const SizedBox(height: _lineGap),
          _line(
            description,
            theme.textTheme.labelSmall?.copyWith(
              fontSize: _descriptionFontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ],
    );
  }

  Widget _line(String text, TextStyle? style) {
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}

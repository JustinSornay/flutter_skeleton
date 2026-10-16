// caption_style.dart
//
// StepRangeCaptions — pure choice of the font size, weight and ink of every
// StepRangeChart caption: the gutter (band labels, axis bounds) and the
// name / sublabel / value under each column. The painter
// (widgets/step_range_painter.dart) maps each ink to a colour resolved by
// view.dart. No widgets, so it is unit-tested on its own
// (test/unit/widgets/step_range_chart_captions_test.dart).

part of "../index.dart";

/// Which resolved colour a [StepRangeChart] caption is painted in.
@visibleForTesting
enum StepRangeInk {
  /// `cs.onSurfaceVariant`.
  label,

  /// The line colour ([StepRangeChart.color], default `cs.primary`).
  line,

  /// `cs.onSurface`.
  emphasized,

  /// `cs.onSurfaceVariant` at 50 %.
  muted,

  /// The band's tone `foreground` (`StatusTones.colorsOf(context, band.tone)`).
  tone,
}

/// Font size (design-viewport units), weight and ink of one caption.
@visibleForTesting
typedef StepRangeCaptionStyle = ({double fontSize, FontWeight fontWeight, StepRangeInk ink});

/// Caption styles of a [StepRangeChart].
@visibleForTesting
abstract final class StepRangeCaptions {
  static const double _smallSize = 7;
  static const double _nameSize = 9;
  static const double _valueSize = 10;
  static const double _largeValueSize = 11;

  /// A band label in the gutter: 7 / w700 in the band tone.
  static const StepRangeCaptionStyle bandLabel = (
    fontSize: _smallSize,
    fontWeight: FontWeight.w700,
    ink: StepRangeInk.tone,
  );

  /// An axis bound in the gutter: 7 / w700, [StepRangeInk.label].
  static const StepRangeCaptionStyle bound = (
    fontSize: _smallSize,
    fontWeight: FontWeight.w700,
    ink: StepRangeInk.label,
  );

  /// Column name: 9 / w700 ([StepRangeInk.label]), w800 in
  /// [StepRangeInk.line] when [selected], [StepRangeInk.muted] without a
  /// value.
  static StepRangeCaptionStyle name(StepRangeColumn column, {required bool selected}) {
    return (
      fontSize: _nameSize,
      fontWeight: _active(column, selected) ? FontWeight.w800 : FontWeight.w700,
      ink: _textInk(column, selected),
    );
  }

  /// Column sublabel: 7 / w600 in the name's ink; null when the column has
  /// no sublabel or an empty one (nothing is painted).
  static StepRangeCaptionStyle? sublabel(StepRangeColumn column, {required bool selected}) {
    final String? text = column.sublabel;
    if (text == null || text.isEmpty) return null;
    return (fontSize: _smallSize, fontWeight: FontWeight.w600, ink: _textInk(column, selected));
  }

  /// Column value: 10 / w800, 11 when [selected] or emphasized; ink
  /// [StepRangeInk.muted] without a value, else [StepRangeInk.line] when
  /// [selected], [StepRangeInk.emphasized] when emphasized,
  /// [StepRangeInk.label] otherwise.
  static StepRangeCaptionStyle value(StepRangeColumn column, {required bool selected}) {
    final bool active = _active(column, selected);
    final StepRangeInk ink;
    if (column.value == null) {
      ink = StepRangeInk.muted;
    } else if (active) {
      ink = StepRangeInk.line;
    } else {
      ink = column.emphasized ? StepRangeInk.emphasized : StepRangeInk.label;
    }
    return (
      fontSize: active || column.emphasized ? _largeValueSize : _valueSize,
      fontWeight: FontWeight.w800,
      ink: ink,
    );
  }

  /// A locked or valueless column is never shown as selected.
  static bool _active(StepRangeColumn column, bool selected) => selected && column.value != null;

  /// Ink of the name and the sublabel.
  static StepRangeInk _textInk(StepRangeColumn column, bool selected) {
    if (column.value == null) return StepRangeInk.muted;
    return _active(column, selected) ? StepRangeInk.line : StepRangeInk.label;
  }
}

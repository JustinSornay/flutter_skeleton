// view.dart
//
// Tree of SeverityBadge: a StatusPill in the level's tone with the level's
// icon, showing "label value" and announcing "label, value, level name"
// unless the host overrides the semantics label.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, SeverityBadge widget) {
    final SeverityLevel severity = widget.severity;
    final String? valueLabel = widget.valueLabel;
    final String? semanticsLabel = widget.semanticsLabel;

    return StatusPill(
      label: _join(<String>[widget.label, valueLabel ?? ""], " "),
      tone: severity.tone,
      icon: severity.tone.icon,
      semanticsLabel: (semanticsLabel == null || semanticsLabel.isEmpty)
          ? _join(<String>[widget.label, valueLabel ?? "", severity.semanticsKey.tr()], ", ")
          : semanticsLabel,
    );
  }

  /// Joins the non-empty [parts] with [separator].
  String _join(List<String> parts, String separator) {
    return parts.where((String part) => part.isNotEmpty).join(separator);
  }
}

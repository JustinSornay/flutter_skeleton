// view.dart
//
// Tree of StatusHeatmapRow: the surfaceContainerHigh card, the optional
// overline header and the row of equal-width cells (widgets/cell_view.dart).
// Resolves the default locale-aware two-decimal formatter.

part of "index.dart";

/// Corner radius of the card.
const double _cardRadius = 12;

/// Decimals of the default formatter.
const int _defaultDecimals = 2;

mixin _ViewMixin {
  Widget render(BuildContext context, StatusHeatmapRow widget) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final StatusHeatmapValueFormatter format = widget.formatValue ?? _defaultFormatter(context);
    final String? title = widget.title;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      padding: const EdgeInsets.all(kDefaultPadding * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (title != null) ...<Widget>[
            _title(title, cs),
            const SizedBox(height: kDefaultPadding),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: kDefaultPadding,
            children: <Widget>[
              for (final StatusHeatmapCell cell in widget.cells)
                Expanded(child: _CellView(cell: cell, format: format)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _title(String title, ColorScheme cs) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Two decimals for the ambient locale; an unknown locale falls back to
  /// intl's default.
  StatusHeatmapValueFormatter _defaultFormatter(BuildContext context) {
    final String? tag = Localizations.maybeLocaleOf(context)?.toLanguageTag();
    final String? locale = Intl.verifiedLocale(tag, NumberFormat.localeExists, onFailure: (String _) => null);
    final NumberFormat format = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: _defaultDecimals,
    );
    return format.format;
  }
}

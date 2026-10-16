// next_level_card.dart
//
// "Next level" card of LevelProgressBar: a primary-tinted box with a title,
// one pill chip per item the next level adds, and an optional full-width
// call-to-action button (≥ kMinTapTarget high) that only calls back.

part of "../index.dart";

/// Inner padding of the card and gap above the button (12 dp).
const double _cardPadding = kDefaultPadding * 1.5;

/// Gap between chips, horizontally and between runs (4 dp).
const double _chipGap = kDefaultPadding / 2;

/// Tinted card listing what the next level adds.
final class _NextLevelCard extends StatelessWidget {
  const _NextLevelCard({
    required this.title,
    required this.items,
    required this.actionLabel,
    required this.onPressed,
  });

  /// Card title (already resolved, default or override).
  final String title;

  /// One chip each; none when empty.
  final List<String> items;

  /// Button label (already resolved, default or override).
  final String actionLabel;

  /// Button callback; null hides the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final TextStyle small = theme.textTheme.labelSmall ?? const TextStyle();
    final VoidCallback? pressed = onPressed;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(kDefaultPadding),
        border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(title, style: small.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: cs.primary)),
            if (items.isNotEmpty) ...<Widget>[
              const SizedBox(height: kDefaultPadding),
              Wrap(
                spacing: _chipGap,
                runSpacing: _chipGap,
                children: <Widget>[for (final String item in items) _chip(cs, small, item)],
              ),
            ],
            if (pressed != null) ...<Widget>[
              const SizedBox(height: _cardPadding),
              _button(theme, pressed),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(ColorScheme cs, TextStyle small, String item) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
        child: Text(item, style: small.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary)),
      ),
    );
  }

  Widget _button(ThemeData theme, VoidCallback pressed) {
    final TextStyle label = (theme.textTheme.labelLarge ?? const TextStyle()).copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w700,
    );
    return FilledButton(
      onPressed: pressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(kMinTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding * 2, vertical: kDefaultPadding),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kDefaultPadding)),
        textStyle: label,
      ),
      child: Text(actionLabel, textAlign: TextAlign.center),
    );
  }
}

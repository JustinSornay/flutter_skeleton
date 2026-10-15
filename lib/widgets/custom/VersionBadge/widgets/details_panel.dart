// details_panel.dart
//
// _DetailsPanel — content-only panel built by a VersionBadge tap: header
// title, body paragraph, the warning-tone outdated notice (not current only)
// and the optional "learn more" TextButton, in a scroll view padded on the
// 8 dp grid. No drag handle: the host mounts it (AppModal, bottom sheet).

part of "../index.dart";

/// Gap between the title and the body (12 dp).
const double _titleGap = kDefaultPadding * 1.5;

/// Gap before the notice and before the button (16 dp).
const double _sectionGap = kDefaultPadding * 2;

final class _DetailsPanel extends StatelessWidget {
  final VersionBadgeDetails details;
  final bool isCurrent;

  const _DetailsPanel({required this.details, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final String? notice = details.outdatedNotice;
    final bool showNotice = !isCurrent && notice != null && notice.isNotEmpty;
    final VoidCallback? onLearnMore = details.onLearnMore;

    return Material(
      type: MaterialType.transparency,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(kDefaultPadding * 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                details.title,
                style: (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(height: _titleGap),
            Text(
              details.body,
              style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
                fontSize: 14,
                height: 1.4,
                color: cs.onSurface,
              ),
            ),
            if (showNotice) ...<Widget>[
              const SizedBox(height: _sectionGap),
              _notice(context, notice),
            ],
            if (onLearnMore != null) ...<Widget>[
              const SizedBox(height: _sectionGap),
              _learnMore(onLearnMore),
            ],
          ],
        ),
      ),
    );
  }

  /// Warning callout: onContainer text on the warning container fill.
  Widget _notice(BuildContext context, String notice) {
    final ToneColors colors = StatusTones.colorsOf(context, StatusTone.warning);
    final TextStyle base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();

    return Container(
      padding: const EdgeInsets.all(kDefaultPadding * 1.5),
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        notice,
        style: base.copyWith(fontSize: 13, color: colors.onContainer),
      ),
    );
  }

  Widget _learnMore(VoidCallback onLearnMore) {
    final String? label = details.learnMoreLabel;

    return TextButton.icon(
      onPressed: onLearnMore,
      style: TextButton.styleFrom(
        minimumSize: const Size(kMinTapTarget, kMinTapTarget),
        // Standard density keeps the 48 dp minimum on desktop, where the
        // adaptive (compact) density would shrink it to 40 dp.
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      icon: const Icon(Icons.open_in_new, size: 16),
      label: Text(
        label == null || label.isEmpty ? "custom.version_badge.learn_more".tr() : label,
      ),
    );
  }
}

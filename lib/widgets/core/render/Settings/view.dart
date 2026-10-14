// view.dart
//
// _ViewMixin — rendering for Settings and its About modal.

part of "index.dart";

mixin _ViewMixin {
  Widget render(BuildContext context, Settings widget) {
    final TextTheme text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(kDefaultPadding * 2),
      children: <Widget>[
        Text("settings.language".tr(), style: text.titleSmall),
        const SizedBox(height: kDefaultPadding),
        SegmentedButton<String>(
          segments: <ButtonSegment<String>>[
            for (final Locale locale in context.supportedLocales)
              ButtonSegment<String>(
                value: locale.languageCode,
                label: Text("language.${locale.languageCode}".tr()),
              ),
          ],
          selected: <String>{context.locale.languageCode},
          onSelectionChanged: (Set<String> selection) =>
              widget.selectLanguage(context, selection.first),
        ),
        const SizedBox(height: kSectionGap),
        const Divider(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline_rounded),
          title: Text("settings.about".tr()),
          onTap: () => widget.showAbout(context),
        ),
      ],
    );
  }

  Widget _aboutModal(BuildContext context, VoidCallback onClose) {
    final TextTheme text = Theme.of(context).textTheme;

    return AppModal(
      isVisible: true,
      onDismiss: onClose,
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding * 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("about.title".tr(), style: text.titleLarge),
            const SizedBox(height: kDefaultPadding),
            Text("about.body".tr(), style: text.bodyMedium),
            const SizedBox(height: kDefaultPadding * 2),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onClose,
                child: Text("common.close".tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// intl_locale.dart
//
// Locale lookups for intl formatters (NumberFormat, DateFormat): the
// locale to pass to a formatter so that an unsupported locale falls back to
// intl's default instead of throwing. Used by every widget and formatter that
// prints a number or a date.
//
// Date data must be loaded first: main.dart calls initializeDateFormatting()
// (package:intl/date_symbol_data_local.dart). Until then intl only knows
// en_US and dateLocale throws a LocaleDataException for any other locale.

import "package:flutter/widgets.dart";
import "package:intl/intl.dart";

/// The locale intl's number data has for [tag] (`"fr-FR"`, `"fr_FR"` and
/// `"fr"` all give `"fr"`; an unlisted region falls back to its language),
/// null for an unknown locale. A null [tag] means intl's current default
/// locale.
String? numberLocale(String? tag) {
  return Intl.verifiedLocale(tag, NumberFormat.localeExists, onFailure: (String _) => null);
}

/// Same as [numberLocale] for intl's date data (see the header: date data
/// must be initialized).
String? dateLocale(String? tag) {
  return Intl.verifiedLocale(tag, DateFormat.localeExists, onFailure: (String _) => null);
}

/// [numberLocale] of the locale of [context] (the nearest `Localizations`);
/// intl's current default locale when there is none.
String? numberLocaleOf(BuildContext context) {
  return numberLocale(Localizations.maybeLocaleOf(context)?.toLanguageTag());
}

/// [dateLocale] of the locale of [context]; intl's current default locale
/// when there is none.
String? dateLocaleOf(BuildContext context) {
  return dateLocale(Localizations.maybeLocaleOf(context)?.toLanguageTag());
}

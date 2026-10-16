// intl_locale_test.dart
//
// Tests for the intl locale lookups. The first test runs before date data is
// loaded and shows why main.dart calls initializeDateFormatting(); the rest
// run after it, as the app does.

import "package:flutter/widgets.dart";
import "package:flutter_skeleton/utils/formatters/intl_locale.dart";
import "package:flutter_test/flutter_test.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:intl/intl.dart" show DateFormat, Intl, NumberFormat;

Future<BuildContext> _contextWith(WidgetTester tester, Locale? locale) async {
  const Widget leaf = Directionality(textDirection: TextDirection.ltr, child: SizedBox());
  await tester.pumpWidget(
    locale == null
        ? leaf
        : Localizations(
            locale: locale,
            delegates: const <LocalizationsDelegate<dynamic>>[DefaultWidgetsLocalizations.delegate],
            child: leaf,
          ),
  );
  return tester.element(find.byType(SizedBox));
}

void main() {
  test("without initializeDateFormatting, dateLocale throws for any locale but en_US", () {
    expect(
      () => dateLocale("fr-FR"),
      throwsA(predicate((Object e) => e.toString().contains("initializeDateFormatting"))),
    );
    expect(dateLocale("en_US"), "en_US");
  });

  group("after initializeDateFormatting", () {
    setUpAll(initializeDateFormatting);

    test("number and date lookups accept every spelling of a supported locale", () {
      for (final String tag in <String>["fr-FR", "fr_FR", "fr"]) {
        expect(numberLocale(tag), "fr", reason: tag);
        expect(DateFormat.MMMd(dateLocale(tag)).format(DateTime(2026, 3, 9)), "9 mars", reason: tag);
      }
    });

    test("an unlisted region falls back to its language", () {
      expect(numberLocale("fr-ZZ"), "fr");
      expect(dateLocale("fr-ZZ"), "fr");
    });

    test("an unknown locale gives null, a null tag the current default", () {
      expect(numberLocale("xx-YY"), isNull);
      expect(dateLocale("xx-YY"), isNull);
      expect(numberLocale(null), Intl.getCurrentLocale());
    });

    testWidgets("the context variants read the nearest Localizations", (WidgetTester tester) async {
      final BuildContext context = await _contextWith(tester, const Locale("de", "DE"));

      expect(numberLocaleOf(context), "de");
      expect(NumberFormat.decimalPattern(numberLocaleOf(context)).format(1234.5), "1.234,5");
      expect(DateFormat.MMMd(dateLocaleOf(context)).format(DateTime(2026, 3, 9)), "9. März");
    });

    testWidgets("without Localizations the context variants use the current default", (WidgetTester tester) async {
      final BuildContext context = await _contextWith(tester, null);

      expect(numberLocaleOf(context), numberLocale(null));
      expect(dateLocaleOf(context), dateLocale(null));
    });
  });
}

// masked_digit_field_mask_test.dart
//
// Unit tests for DigitMask
// (lib/widgets/custom/MaskedDigitField/controllers/digit_mask.dart): slot
// counting, formatting with space / slash / bracket separators, truncation,
// non-digit filtering, the no-trailing-separator rule, digitsOf and the
// repeating sample used as the default hint.

import "package:flutter_skeleton/widgets/custom/MaskedDigitField/index.dart";
import "package:flutter_test/flutter_test.dart";

const DigitMask _spaced = DigitMask("# ## ## ## ##");
const DigitMask _date = DigitMask("##/##/####");
const DigitMask _bracketed = DigitMask("(###) ###-####");

void main() {
  group("maxDigits", () {
    test("counts the # slots", () {
      expect(_spaced.maxDigits, 9);
      expect(const DigitMask("### ########").maxDigits, 11);
      expect(_date.maxDigits, 8);
      expect(_bracketed.maxDigits, 10);
    });

    test("is 0 for a pattern without slots", () {
      expect(const DigitMask("").maxDigits, 0);
      expect(const DigitMask("--").maxDigits, 0);
    });
  });

  group("format", () {
    test("groups a full value with spaces", () {
      expect(_spaced.format("612345678"), "6 12 34 56 78");
    });

    test("formats partial values without a trailing separator", () {
      expect(_spaced.format(""), "");
      expect(_spaced.format("6"), "6");
      expect(_spaced.format("61"), "6 1");
      expect(_spaced.format("612"), "6 12");
    });

    test("drops digits beyond maxDigits", () {
      expect(_spaced.format("61234567899"), "6 12 34 56 78");
    });

    test("supports slash separators", () {
      expect(_date.format("01022024"), "01/02/2024");
      expect(_date.format("0102"), "01/02");
      expect(_date.format("010"), "01/0");
    });

    test("writes a leading separator once the first digit arrives", () {
      expect(_bracketed.format(""), "");
      expect(_bracketed.format("5"), "(5");
      expect(_bracketed.format("555"), "(555");
      expect(_bracketed.format("5551"), "(555) 1");
      expect(_bracketed.format("5551234567"), "(555) 123-4567");
    });

    test("ignores non-digit characters of the input", () {
      expect(_spaced.format("6a1+2"), "6 12");
      expect(_date.format("01/02/2024"), "01/02/2024");
      expect(_spaced.format("abc"), "");
    });

    test("never ends with a separator and round-trips the digits", () {
      const String digits = "5551234567";
      for (int length = 1; length <= digits.length; length++) {
        final String prefix = digits.substring(0, length);
        final String formatted = _bracketed.format(prefix);
        expect(formatted, matches(RegExp(r"\d$")), reason: prefix);
        expect(DigitMask.digitsOf(formatted), prefix, reason: prefix);
      }
    });

    test("a pattern without slots formats to an empty string", () {
      expect(const DigitMask("--").format("123"), "");
    });

    test("never writes a separator that follows the last slot", () {
      expect(const DigitMask("##-").format("12"), "12");
      expect(const DigitMask("##-").format("123"), "12");
    });
  });

  group("digitsOf", () {
    test("removes every non-digit character", () {
      expect(DigitMask.digitsOf("+33 6-12.34 ab"), "3361234");
      expect(DigitMask.digitsOf("(555) 123-4567"), "5551234567");
    });

    test("returns an empty string without digits", () {
      expect(DigitMask.digitsOf(""), "");
      expect(DigitMask.digitsOf("- /"), "");
    });
  });

  group("sample", () {
    test("fills the slots with 1234567890 and keeps separators", () {
      expect(_spaced.sample(), "1 23 45 67 89");
      expect(_date.sample(), "12/34/5678");
      expect(_bracketed.sample(), "(123) 456-7890");
    });

    test("repeats the sequence past ten slots", () {
      expect(const DigitMask("#### #### #### ####").sample(), "1234 5678 9012 3456");
      expect(const DigitMask("### ########").sample(), "123 45678901");
    });

    test("keeps a pattern without slots as is", () {
      expect(const DigitMask("").sample(), "");
      expect(const DigitMask("--").sample(), "--");
    });
  });
}

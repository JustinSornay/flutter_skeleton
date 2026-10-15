// file_upload_panel_size_test.dart
//
// Unit tests for FileUploadSize (FileUploadPanel's size formatting): unit
// thresholds at 1024 steps, at most one decimal, locale-aware separators and
// the fallback for an unknown or null locale.

import "package:flutter_skeleton/widgets/custom/FileUploadPanel/index.dart";
import "package:flutter_test/flutter_test.dart";

const String _bytes = "custom.file_upload_panel.size_bytes";
const String _kb = "custom.file_upload_panel.size_kb";
const String _mb = "custom.file_upload_panel.size_mb";

void main() {
  group("unit thresholds", () {
    test("below 1024 bytes uses the bytes key", () {
      final FileUploadSize size = FileUploadSize.of(512, locale: "en-US");
      expect(size.key, _bytes);
      expect(size.value, "512");
    });

    test("zero bytes", () {
      final FileUploadSize size = FileUploadSize.of(0, locale: "en-US");
      expect(size.key, _bytes);
      expect(size.value, "0");
    });

    test("1023 bytes is the last bytes value", () {
      final FileUploadSize size = FileUploadSize.of(1023, locale: "en-US");
      expect(size.key, _bytes);
      expect(size.value, "1,023");
    });

    test("1024 bytes switches to KB without a trailing decimal", () {
      final FileUploadSize size = FileUploadSize.of(1024, locale: "en-US");
      expect(size.key, _kb);
      expect(size.value, "1");
    });

    test("1536 bytes is 1.5 KB", () {
      final FileUploadSize size = FileUploadSize.of(1536, locale: "en-US");
      expect(size.key, _kb);
      expect(size.value, "1.5");
    });

    test("1 MiB switches to MB", () {
      final FileUploadSize size = FileUploadSize.of(1024 * 1024, locale: "en-US");
      expect(size.key, _mb);
      expect(size.value, "1");
    });

    test("3 MiB is 3 MB and large sizes stay in MB", () {
      expect(FileUploadSize.of(3 * 1024 * 1024, locale: "en-US").value, "3");
      final FileUploadSize large = FileUploadSize.of(2048 * 1024 * 1024, locale: "en-US");
      expect(large.key, _mb);
      expect(large.value, "2,048");
    });

    test("rounds to one decimal", () {
      // 1100 / 1024 = 1.074…
      expect(FileUploadSize.of(1100, locale: "en-US").value, "1.1");
    });
  });

  group("locale", () {
    test("uses the French decimal separator for a BCP 47 tag", () {
      expect(FileUploadSize.of(1536, locale: "fr-FR").value, "1,5");
    });

    test("accepts a language-only or intl-style locale name", () {
      expect(FileUploadSize.of(1536, locale: "fr").value, "1,5");
      expect(FileUploadSize.of(1536, locale: "de_DE").value, "1,5");
    });

    test("falls back without throwing for an unknown locale", () {
      expect(() => FileUploadSize.of(1536, locale: "zz-ZZ"), returnsNormally);
      expect(FileUploadSize.of(1536, locale: "zz-ZZ").key, _kb);
    });

    test("a null locale uses intl's current locale", () {
      final FileUploadSize size = FileUploadSize.of(1536);
      expect(size.key, _kb);
      expect(size.value, isNotEmpty);
    });
  });
}

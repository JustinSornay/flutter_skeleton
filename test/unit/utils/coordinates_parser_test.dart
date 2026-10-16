// coordinates_parser_test.dart
//
// Unit tests for parseCoordinates and formatCoordinates.

import "package:flutter_skeleton/utils/parsers/coordinates_parser.dart";
import "package:flutter_test/flutter_test.dart";
import "package:latlong2/latlong.dart";

void main() {
  group("parseCoordinates", () {
    test("parses comma and semicolon pairs, trimming spaces", () {
      expect(parseCoordinates("48.85,2.35"), const LatLng(48.85, 2.35));
      expect(parseCoordinates("  -33.86 ; 151.2 "), const LatLng(-33.86, 151.2));
    });

    test("accepts the range bounds", () {
      expect(parseCoordinates("-90,-180"), const LatLng(-90, -180));
      expect(parseCoordinates("90,180"), const LatLng(90, 180));
    });

    test("returns null for blank or malformed input", () {
      for (final String raw in <String>["", "   ", "48.85", "48.85,2.35,1", "abc,2.35", "48.85,", ",2.35"]) {
        expect(parseCoordinates(raw), isNull, reason: raw);
      }
    });

    test("returns null out of range", () {
      expect(parseCoordinates("90.1,0"), isNull);
      expect(parseCoordinates("0,-180.1"), isNull);
    });
  });

  group("formatCoordinates", () {
    test("uses 2 decimals and cardinal suffixes", () {
      expect(formatCoordinates(46.5, 2.3), "46.50°N  2.30°E");
      expect(formatCoordinates(-33.868, -70.25), "33.87°S  70.25°W");
    });

    test("treats zero as north and east", () {
      expect(formatCoordinates(0, 0), "0.00°N  0.00°E");
    });
  });
}

// coords_test.dart
//
// Unit tests for Coords: grid snapping and the canonical key segment.

import "package:flutter_skeleton/utils/coords.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("Coords.formatKey", () {
    test("rounds to 3 decimal places by default", () {
      expect(Coords.formatKey(48.8566, 2.3522), "48.857_2.352");
    });

    test("negative coordinates", () {
      expect(Coords.formatKey(-33.8688, 151.2093), "-33.869_151.209");
    });

    test("already-snapped values are stable", () {
      expect(Coords.formatKey(48.857, 2.352), "48.857_2.352");
    });

    test("always writes the requested number of decimals", () {
      expect(Coords.formatKey(0.0, 0.0), "0.000_0.000");
      expect(Coords.formatKey(48.8566, 2.3522, decimals: 1), "48.9_2.4");
    });

    test("both sides of zero share one key", () {
      expect(Coords.formatKey(-0.0001, -0.0001), "0.000_0.000");
      expect(Coords.formatKey(0.0001, 0.0001), "0.000_0.000");
    });
  });

  group("Coords.snapToGrid", () {
    test("rounds half away from zero", () {
      final (double lat, double lon) = Coords.snapToGrid(48.8565, 2.3525);
      expect(lat, closeTo(48.857, 0.0001));
      expect(lon, closeTo(2.353, 0.0001));
    });

    test("honours a custom resolution", () {
      final (double lat, double lon) = Coords.snapToGrid(48.8566, 2.3522, decimals: 2);
      expect(lat, closeTo(48.86, 1e-9));
      expect(lon, closeTo(2.35, 1e-9));
    });

    test("rejects out-of-range coordinates in debug", () {
      expect(() => Coords.snapToGrid(91, 0), throwsA(isA<AssertionError>()));
      expect(() => Coords.snapToGrid(0, -181), throwsA(isA<AssertionError>()));
    });
  });
}

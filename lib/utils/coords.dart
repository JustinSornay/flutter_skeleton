// coords.dart
//
// Coords — snaps latitude / longitude to a fixed decimal grid and builds the
// canonical "lat_lon" key segment from it. Use it for every cache key built
// from a location (local cache, and a backend cache when the server rounds
// the same way), so nearby points share one entry and keys stay aligned.
//
// Dart's double.round() returns an int, so a value just below zero snaps to
// 0.0 and is written "0.000". A server that must produce the same keys has to
// do the same (Go's math.Round + "%.3f" writes "-0.000" for -0.0001).

/// Grid snapping for geographic coordinates.
abstract final class Coords {
  /// Default number of decimals kept (3 ≈ 110 m in latitude).
  static const int defaultDecimals = 3;

  /// Rounds [lat] and [lon] to [decimals] decimal places (half away from
  /// zero, like [double.round]).
  static (double, double) snapToGrid(double lat, double lon, {int decimals = defaultDecimals}) {
    _checkRange(lat, lon);
    final double factor = _factor(decimals);
    return ((lat * factor).round() / factor, (lon * factor).round() / factor);
  }

  /// The canonical `"<lat>_<lon>"` key segment, snapped to [decimals] and
  /// always written with exactly [decimals] decimals (`48.857_2.352`).
  static String formatKey(double lat, double lon, {int decimals = defaultDecimals}) {
    final (double sLat, double sLon) = snapToGrid(lat, lon, decimals: decimals);
    return "${sLat.toStringAsFixed(decimals)}_${sLon.toStringAsFixed(decimals)}";
  }

  static double _factor(int decimals) {
    assert(decimals >= 0 && decimals <= 10, "decimals must be in [0, 10], got $decimals");
    double factor = 1;
    for (int i = 0; i < decimals; i++) {
      factor *= 10;
    }
    return factor;
  }

  static void _checkRange(double lat, double lon) {
    assert(lat >= -90.0 && lat <= 90.0, "lat must be in [-90, 90], got $lat");
    assert(lon >= -180.0 && lon <= 180.0, "lon must be in [-180, 180], got $lon");
  }
}

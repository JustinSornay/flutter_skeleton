// compass_point.dart
//
// CompassPoint: the 8-point compass rose and the bucketing of a bearing into
// it. No user-visible string lives here: the caller translates the stable
// enum `name` (e.g. "compass.${point.name}" → "NE"). `between` reads the
// initial great-circle bearing from latlong2 `Distance().bearing`.

import "package:latlong2/latlong.dart";

/// One of the 8 compass points, clockwise from north.
///
/// Each point owns a 45° sector centred on its bearing (north 0°, north-east
/// 45°, … north-west 315°), i.e. 22.5° on either side. A sector includes its
/// counter-clockwise boundary and excludes its clockwise one, so a bearing on
/// a boundary belongs to the point clockwise of it: north is
/// [337.5°, 22.5°), north-east [22.5°, 67.5°), east [67.5°, 112.5°), …,
/// north-west [292.5°, 337.5°). The boundaries are exact to the last bit:
/// the largest double below 22.5 is still north.
///
/// The declaration order (and so `index` and `name`) is part of the
/// contract: `name` is meant for translation keys.
enum CompassPoint {
  north,
  northEast,
  east,
  southEast,
  south,
  southWest,
  west,
  northWest;

  /// The point whose sector contains [degrees], a bearing clockwise from
  /// north. Any finite value is normalised modulo 360 first (-90 is west,
  /// 450 is east). Throws [ArgumentError] for NaN or infinity.
  static CompassPoint fromBearing(double degrees) {
    if (!degrees.isFinite) {
      throw ArgumentError.value(degrees, "degrees", "must be finite");
    }
    // degrees ≡ 45 · whole + offset (mod 360) with |offset| < 45. remainder()
    // never rounds (unlike adding 360 or 22.5), and turn - offset is an exact
    // multiple of 45, so no boundary moves by an ulp.
    final double turn = degrees.remainder(360);
    final double offset = turn.remainder(45);
    final int whole = (turn - offset) ~/ 45;
    final int sector = whole + (offset >= 22.5 ? 1 : 0) - (offset < -22.5 ? 1 : 0);
    return values[sector % values.length];
  }

  /// The point of the initial great-circle bearing from [from] to [to]
  /// (latlong2 `Distance().bearing`). Identical points give [north].
  static CompassPoint between(LatLng from, LatLng to) {
    // latlong2 rounds the bearing of identical points to 0° or 180°
    // depending on the latitude: pin the documented answer.
    if (from == to) return CompassPoint.north;
    return fromBearing(const Distance().bearing(from, to));
  }
}

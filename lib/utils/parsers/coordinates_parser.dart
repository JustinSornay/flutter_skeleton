// coordinates_parser.dart
//
// Parsing and display of geographic coordinates: raw user input
// ("48.85, 2.35") → LatLng, and a LatLng-free lat / lon pair → a short
// human-readable label with cardinal suffixes.

import "package:latlong2/latlong.dart";

/// Formats [lat] and [lon] with 2 decimals and cardinal suffixes (negative
/// latitude → S, negative longitude → W), separated by two spaces.
///
/// `formatCoordinates(46.5, -2.3)` → `"46.50°N  2.30°W"`. Not localised:
/// use intl `NumberFormat` when the decimal separator must follow the locale.
String formatCoordinates(double lat, double lon) {
  final String latLabel = "${lat.abs().toStringAsFixed(2)}°${lat >= 0 ? "N" : "S"}";
  final String lonLabel = "${lon.abs().toStringAsFixed(2)}°${lon >= 0 ? "E" : "W"}";
  return "$latLabel  $lonLabel";
}

/// Parses a raw `"lat,lon"` (or `"lat;lon"`) string typed by the user.
///
/// Returns null, never throws, when the input is blank, does not split into
/// exactly two decimal numbers, or is out of range (latitude −90…90,
/// longitude −180…180).
LatLng? parseCoordinates(String rawValue) {
  final String sanitized = rawValue.trim();
  if (sanitized.isEmpty) return null;

  final List<String> parts = sanitized
      .replaceAll(";", ",")
      .split(",")
      .map((String value) => value.trim())
      .where((String value) => value.isNotEmpty)
      .toList();
  if (parts.length != 2) return null;

  final double? lat = double.tryParse(parts.first);
  final double? lon = double.tryParse(parts.last);
  if (lat == null || lon == null) return null;
  if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;

  return LatLng(lat, lon);
}

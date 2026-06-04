import 'package:latlong2/latlong.dart';

class Office {
  final String id;
  final String name;
  final String type;
  final double lat;
  final double lng;
  final String address;
  final String description;
  final bool isAccessible;
  final bool hasHandicapParking;
  final bool hasRamp;
  final bool hasElevator;
  final String openingHours;
  final double rating;

  const Office({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    required this.address,
    required this.description,
    required this.isAccessible,
    required this.hasHandicapParking,
    required this.hasRamp,
    required this.hasElevator,
    required this.openingHours,
    this.rating = 4.5,
  });

  LatLng get position => LatLng(lat, lng);

  double get accessibilityScore {
    var score = 0.0;
    if (isAccessible) score += 4;
    if (hasRamp) score += 3;
    if (hasHandicapParking) score += 2;
    if (hasElevator) score += 1;
    return score;
  }
}

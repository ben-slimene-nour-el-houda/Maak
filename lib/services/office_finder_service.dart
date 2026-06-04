import 'package:latlong2/latlong.dart';

import '../models/office_model.dart';

class OfficeFinderService {
  static const LatLng userLocation = LatLng(36.8065, 10.1815);
  static final Distance _distance = const Distance();

  static List<Office> sortOffices(
    List<Office> offices, {
    bool accessibilityOnly = false,
    String query = '',
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    final filtered = offices.where((office) {
      if (accessibilityOnly && !office.isAccessible) return false;
      if (normalizedQuery.isEmpty) return true;
      final haystack = [
        office.name,
        office.address,
        office.description,
        office.type,
      ].join(' ').toLowerCase();
      return haystack.contains(normalizedQuery);
    }).toList();

    filtered.sort((a, b) {
      final accessibilityCompare =
          b.accessibilityScore.compareTo(a.accessibilityScore);
      if (accessibilityCompare != 0) return accessibilityCompare;

      final distanceCompare = distanceInKm(a).compareTo(distanceInKm(b));
      if (distanceCompare != 0) return distanceCompare;

      return b.rating.compareTo(a.rating);
    });

    return filtered;
  }

  static List<LatLng> buildAccessibleRoute(Office office) {
    final midpoint = LatLng(
      (userLocation.latitude + office.lat) / 2,
      (userLocation.longitude + office.lng) / 2 + (office.hasRamp ? 0.0008 : -0.0003),
    );
    final entrancePoint = LatLng(
      office.lat - (office.hasHandicapParking ? 0.0002 : 0.00035),
      office.lng - (office.hasRamp ? 0.0001 : 0.00025),
    );

    return [
      userLocation,
      midpoint,
      entrancePoint,
      office.position,
    ];
  }

  static double distanceInKm(Office office) {
    return _distance.as(LengthUnit.Kilometer, userLocation, office.position);
  }

  static bool shouldSuggestArNavigation(Office office) {
    return distanceInKm(office) <= 0.05;
  }
}

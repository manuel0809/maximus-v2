import 'dart:math';

class DistanceCalculatorService {
  // Calculate distance between two coordinates using Haversine formula
  // Returns distance in miles
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    const double kmToMiles = 0.621371;

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distanceKm = earthRadiusKm * c;

    return distanceKm * kmToMiles;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Mock coordinates for common locations (Florida region)
  static final Map<String, Map<String, double>> _locationCoordinates = {
    // Miami Area
    'Miami International Airport, FL': {
      'latitude': 25.7959,
      'longitude': -80.2870,
    },
    'Miami Beach, FL': {'latitude': 25.7907, 'longitude': -80.1300},
    'Downtown Miami, FL': {'latitude': 25.7617, 'longitude': -80.1918},
    'Brickell, Miami, FL': {'latitude': 25.7617, 'longitude': -80.1918},
    'South Beach, Miami, FL': {'latitude': 25.7823, 'longitude': -80.1304},
    'Coral Gables, FL': {'latitude': 25.7211, 'longitude': -80.2683},
    'Key Biscayne, FL': {'latitude': 25.6926, 'longitude': -80.1631},
    'Aventura, FL': {'latitude': 25.9565, 'longitude': -80.1395},
    'Port of Miami, FL': {'latitude': 25.7743, 'longitude': -80.1663},

    // Fort Lauderdale Area
    'Fort Lauderdale-Hollywood International Airport, FL': {
      'latitude': 26.0742,
      'longitude': -80.1506,
    },
    'Fort Lauderdale, FL': {'latitude': 26.1224, 'longitude': -80.1373},
    'Hollywood, FL': {'latitude': 26.0112, 'longitude': -80.1495},
    'Pompano Beach, FL': {'latitude': 26.2379, 'longitude': -80.1248},

    // Palm Beach Area
    'West Palm Beach, FL': {'latitude': 26.7153, 'longitude': -80.0534},
    'Boca Raton, FL': {'latitude': 26.3683, 'longitude': -80.1289},
    'Delray Beach, FL': {'latitude': 26.4615, 'longitude': -80.0728},

    // Orlando Area
    'Orlando International Airport, FL': {
      'latitude': 28.4294,
      'longitude': -81.3089,
    },
    'Orlando Downtown, FL': {'latitude': 28.5383, 'longitude': -81.3792},
    'Disney World, Orlando, FL': {'latitude': 28.3852, 'longitude': -81.5639},
    'Universal Studios, Orlando, FL': {
      'latitude': 28.4743,
      'longitude': -81.4677,
    },
  };

  // Mock coordinates for saved locations (in real app, these would come from geocoding API)
  static Map<String, Map<String, double>> getSavedLocationCoordinates() {
    return _locationCoordinates;
  }

  // Get coordinates for a location name (mock implementation)
  static Map<String, double>? getCoordinatesForLocation(String location) {
    return _locationCoordinates[location];
  }
}

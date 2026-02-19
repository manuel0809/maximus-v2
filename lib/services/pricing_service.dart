
class PricingService {
  static PricingService? _instance;
  static PricingService get instance => _instance ??= PricingService._();

  PricingService._();

  /// Calculates dynamic price based on business rules:
  /// 1. Seasonality (+20-40% in Dec, July, Easter)
  /// 2. Last Minute (-15% if booked within 48h of start)
  /// 3. Long Duration (-10% if duration > 7 days)
  double calculateDynamicPrice({
    required double basePrice,
    required DateTime pickupDate,
    required DateTime dropoffDate,
  }) {
    double multiplier = 1.0;

    // 1. Seasonality Check
    if (_isHighSeason(pickupDate)) {
      multiplier += 0.25; // +25% average for high season
    }

    // 2. Last Minute Check
    final hoursToPickup = pickupDate.difference(DateTime.now()).inHours;
    if (hoursToPickup >= 0 && hoursToPickup <= 48) {
      multiplier -= 0.15; // -15% for last minute
    }

    // 3. Long Duration Check
    final durationDays = dropoffDate.difference(pickupDate).inDays;
    if (durationDays >= 7) {
      multiplier -= 0.10; // -10% for long stays
    }

    return basePrice * multiplier;
  }

  bool _isHighSeason(DateTime date) {
    // High Season: December (12), July (7), and a simplified Easter (March/April approx)
    final month = date.month;
    
    if (month == 12 || month == 7) return true;
    
    // Simplified Easter/Spring Break check (March 15 - April 15)
    if (month == 3 && date.day >= 15) return true;
    if (month == 4 && date.day <= 15) return true;

    return false;
  }

  /// Get price breakdown for transparency
  Map<String, double> getPriceBreakdown({
    required double basePrice,
    required DateTime pickupDate,
    required DateTime dropoffDate,
  }) {
    double seasonality = 0;
    double lastMinute = 0;
    double longDuration = 0;

    if (_isHighSeason(pickupDate)) seasonality = basePrice * 0.25;
    
    final hoursToPickup = pickupDate.difference(DateTime.now()).inHours;
    if (hoursToPickup >= 0 && hoursToPickup <= 48) lastMinute = -basePrice * 0.15;

    final durationDays = dropoffDate.difference(pickupDate).inDays;
    if (durationDays >= 7) longDuration = -basePrice * 0.10;

    return {
      'base': basePrice,
      'seasonality': seasonality,
      'lastMinute': lastMinute,
      'longDuration': longDuration,
      'total': basePrice + seasonality + lastMinute + longDuration,
    };
  }
}

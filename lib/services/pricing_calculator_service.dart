class PricingCalculatorService {
  // Official rate configuration for BLACK service
  static const Map<String, dynamic> blackRates = {
    'baseFare': 15.00,
    'costPerMile': 4.50,
    'costPerMinute': 1.50,
    'automaticAdjustment': 0.80,
    'minimumFare': 65.00,
    'peakHourMultiplier': 1.20,
    'airportFee': 15.00,
    'hourlyRate': 85.00,
    'minimumHours': 2,
  };

  // Official rate configuration for BLACK SUV service
  static const Map<String, dynamic> blackSuvRates = {
    'baseFare': 20.00,
    'costPerMile': 5.50,
    'costPerMinute': 1.75,
    'automaticAdjustment': 0.85,
    'minimumFare': 85.00,
    'peakHourMultiplier': 1.20,
    'airportFee': 20.00,
    'hourlyRate': 110.00,
    'minimumHours': 2,
  };

  // Calculate price for BLACK service
  static double calculateBlackPrice({
    required double distanceMiles,
    required int durationMinutes,
    required bool isPeakHour,
    required bool isAirport,
  }) {
    // Step 1: Calculate subtotal
    final double baseFare = blackRates['baseFare'] as double;
    final double costPerMile = blackRates['costPerMile'] as double;
    final double costPerMinute = blackRates['costPerMinute'] as double;

    final double subtotal =
        baseFare +
        (distanceMiles * costPerMile) +
        (durationMinutes * costPerMinute);

    // Step 2: Apply automatic adjustment
    final double automaticAdjustment =
        blackRates['automaticAdjustment'] as double;
    double totalAdjusted = subtotal * automaticAdjustment;

    // Step 3: Apply minimum fare
    final double minimumFare = blackRates['minimumFare'] as double;
    if (totalAdjusted < minimumFare) {
      totalAdjusted = minimumFare;
    }

    // Step 4: Apply peak hour multiplier
    if (isPeakHour) {
      final double peakMultiplier = blackRates['peakHourMultiplier'] as double;
      totalAdjusted = totalAdjusted * peakMultiplier;
    }

    // Step 5: Add airport fee
    if (isAirport) {
      final double airportFee = blackRates['airportFee'] as double;
      totalAdjusted = totalAdjusted + airportFee;
    }

    return totalAdjusted;
  }

  // Calculate price for BLACK SUV service
  static double calculateBlackSuvPrice({
    required double distanceMiles,
    required int durationMinutes,
    required bool isPeakHour,
    required bool isAirport,
  }) {
    // Step 1: Calculate subtotal
    final double baseFare = blackSuvRates['baseFare'] as double;
    final double costPerMile = blackSuvRates['costPerMile'] as double;
    final double costPerMinute = blackSuvRates['costPerMinute'] as double;

    final double subtotal =
        baseFare +
        (distanceMiles * costPerMile) +
        (durationMinutes * costPerMinute);

    // Step 2: Apply automatic adjustment
    final double automaticAdjustment =
        blackSuvRates['automaticAdjustment'] as double;
    double totalAdjusted = subtotal * automaticAdjustment;

    // Step 3: Apply minimum fare
    final double minimumFare = blackSuvRates['minimumFare'] as double;
    if (totalAdjusted < minimumFare) {
      totalAdjusted = minimumFare;
    }

    // Step 4: Apply peak hour multiplier
    if (isPeakHour) {
      final double peakMultiplier =
          blackSuvRates['peakHourMultiplier'] as double;
      totalAdjusted = totalAdjusted * peakMultiplier;
    }

    // Step 5: Add airport fee
    if (isAirport) {
      final double airportFee = blackSuvRates['airportFee'] as double;
      totalAdjusted = totalAdjusted + airportFee;
    }

    return totalAdjusted;
  }

  // Calculate hourly service price for BLACK
  static double calculateBlackHourlyPrice({
    required int hours,
    required bool isPeakHour,
  }) {
    final double hourlyRate = blackRates['hourlyRate'] as double;
    final int minimumHours = blackRates['minimumHours'] as int;

    // Enforce minimum hours
    final int billedHours = hours < minimumHours ? minimumHours : hours;
    double total = billedHours * hourlyRate;

    // Apply peak hour multiplier
    if (isPeakHour) {
      final double peakMultiplier = blackRates['peakHourMultiplier'] as double;
      total = total * peakMultiplier;
    }

    return total;
  }

  // Calculate hourly service price for BLACK SUV
  static double calculateBlackSuvHourlyPrice({
    required int hours,
    required bool isPeakHour,
  }) {
    final double hourlyRate = blackSuvRates['hourlyRate'] as double;
    final int minimumHours = blackSuvRates['minimumHours'] as int;

    // Enforce minimum hours
    final int billedHours = hours < minimumHours ? minimumHours : hours;
    double total = billedHours * hourlyRate;

    // Apply peak hour multiplier
    if (isPeakHour) {
      final double peakMultiplier =
          blackSuvRates['peakHourMultiplier'] as double;
      total = total * peakMultiplier;
    }

    return total;
  }

  // Calculate dynamic price based on vehicle-specific rates (JSONB)
  static double calculateDynamicTransportPrice({
    required Map<String, dynamic> vehicle,
    required String serviceType, // black_suv, hourly, event
    double? distanceKm,
    int? hours,
    DateTime? serviceDateTime,
  }) {
    final rates = vehicle['service_rates'] as Map<String, dynamic>?;
    if (rates == null || !rates.containsKey(serviceType)) {
      // Fallback to legacy static rates if dynamic ones aren't found
      return 0.0; 
    }

    final serviceRates = rates[serviceType] as Map<String, dynamic>;

    switch (serviceType) {
      case 'black':
      case 'black_suv':
      case 'black_suv_regional':
        final regionalData = (serviceType.contains('regional') || serviceType == 'black' || serviceType == 'black_suv')
            ? (serviceRates[vehicle['region'] ?? 'miami_broward'] as Map<String, dynamic>?)
            : serviceRates;
        
        final base = (regionalData?['base'] ?? 0.0).toDouble();
        final perMile = (regionalData?['per_mile'] ?? regionalData?['per_km'] ?? 0.0).toDouble();
        final minTariff = (regionalData?['min_tariff'] ?? 0.0).toDouble();
        
        final dist = (distanceKm ?? 0.0).toDouble();
        double total = base + dist * perMile;
        return total < minTariff ? minTariff : total;

      case 'hourly_regional':
      case 'black_hourly':
        final regionalData = serviceRates[vehicle['region'] ?? 'miami_broward'] as Map<String, dynamic>?;
        if (regionalData == null) return 0.0;

        final unitRate = (regionalData['unit'] ?? 0.0).toDouble();
        final minHours = (regionalData['min_hours'] ?? 1) as int;
        final tiers = regionalData['tiers'] as Map<String, dynamic>?;
        
        final billedHours = (hours ?? minHours) < minHours ? minHours : (hours ?? minHours);
        
        double total = 0.0;
        if (tiers != null && tiers.containsKey('${billedHours}h')) {
          total = (tiers['${billedHours}h'] ?? 0.0).toDouble();
        } else {
          total = (billedHours * unitRate).toDouble();
        }

        if (serviceDateTime != null) {
          final hr = serviceDateTime.hour;
          final isWeekend = serviceDateTime.weekday >= 6;
          if (isWeekend && (hr >= 0 && hr < 6)) {
            total *= 1.30;
          } else if (hr >= 22 || hr < 6) {
            total *= 1.20;
          }
        }
        return total;

      case 'airport_fixed':
      case 'black_airport_fixed':
        final airport = (vehicle['metadata']?['airport'] ?? 'mia').toString().toLowerCase();
        final destination = vehicle['metadata']?['destination'];
        if (serviceRates.containsKey(airport)) {
          final airportRates = serviceRates[airport] as Map<String, dynamic>;
          if (destination != null && airportRates.containsKey(destination)) {
            return (airportRates[destination] ?? 0.0).toDouble();
          }
        }
        return 0.0;

      case 'inter_city':
      case 'black_inter_city':
        final route = vehicle['metadata']?['route'];
        if (route != null && serviceRates.containsKey(route)) {
          return (serviceRates[route] ?? 0.0).toDouble();
        }
        return 0.0;

      case 'event':
      case 'event_regional':
      case 'black_event':
        final regionalData = (serviceType.contains('regional') || serviceType.contains('black'))
            ? (serviceRates[vehicle['region'] ?? 'miami_broward'] as Map<String, dynamic>?)
            : serviceRates;
            
        final tiers = regionalData?['tiers'] as Map<String, dynamic>?;
        if (tiers != null && tiers.containsKey('${hours ?? 4}h')) {
          return (tiers['${hours ?? 4}h'] ?? 0.0).toDouble();
        }
        return 0.0;

      default:
        return 0.0;
    }
  }

  // Get pricing breakdown for UI (legacy pricing structure)
  static Map<String, dynamic> getPricingBreakdown({
    required String serviceType,
    required double distanceMiles,
    required int durationMinutes,
    required DateTime serviceDateTime,
    required bool isAirport,
  }) {
    final rates = serviceType == 'black_suv' ? blackSuvRates : blackRates;
    final isPeak = isPeakHour(serviceDateTime);

    final double baseFare = (rates['baseFare'] ?? 0.0).toDouble();
    final double costPerMile = (rates['costPerMile'] ?? 0.0).toDouble();
    final double costPerMinute = (rates['costPerMinute'] ?? 0.0).toDouble();
    final double adjustment = (rates['automaticAdjustment'] ?? 1.0).toDouble();

    final double distanceCost = distanceMiles * costPerMile;
    final double timeCost = durationMinutes * costPerMinute;
    final double subtotal = baseFare + distanceCost + timeCost;
    double totalAdjusted = subtotal * adjustment;

    double peakAdjustment = 0.0;
    if (isPeak) {
      final double peakMultiplier = (rates['peakHourMultiplier'] ?? 1.2).toDouble();
      final double totalWithPeak = totalAdjusted * peakMultiplier;
      peakAdjustment = totalWithPeak - totalAdjusted;
      totalAdjusted = totalWithPeak;
    }

    double airportFee = 0.0;
    if (isAirport) {
      airportFee = (rates['airportFee'] ?? 0.0).toDouble();
      totalAdjusted += airportFee;
    }

    return {
      'baseFare': baseFare,
      'distanceCost': distanceCost,
      'timeCost': timeCost,
      'subtotal': subtotal,
      'adjustedTotal': totalAdjusted - peakAdjustment - airportFee, // Result before final fees
      'peakHourAdjustment': peakAdjustment,
      'airportFee': airportFee,
      'total': totalAdjusted,
      'minimumFareApplied': totalAdjusted < (rates['minimumFare'] ?? 0.0).toDouble(),
    };
  }

  // Get dynamic pricing breakdown
  static Map<String, dynamic> getDynamicPricingBreakdown({
    required Map<String, dynamic> vehicle,
    required String serviceType,
    double? distanceKm,
    int? hours,
    DateTime? serviceDateTime,
  }) {
    final total = calculateDynamicTransportPrice(
      vehicle: vehicle,
      serviceType: serviceType,
      distanceKm: distanceKm,
      hours: hours,
      serviceDateTime: serviceDateTime,
    );

    final rates = vehicle['service_rates'] as Map<String, dynamic>?;
    final serviceRates = rates?[serviceType] as Map<String, dynamic>?;

    return {
      'total': total,
      'service_type': serviceType,
      'notes': serviceRates?['msg'] ?? '',
      'is_nightly': serviceDateTime != null && (serviceDateTime.hour >= 22 || serviceDateTime.hour < 6),
    };
  }

  // Determine if service time is during peak hours
  static bool isPeakHour(DateTime serviceDateTime) {
    final int hour = serviceDateTime.hour;
    final bool isWeekday =
        serviceDateTime.weekday >= 1 && serviceDateTime.weekday <= 5;

    // Peak hours: 7-9 AM and 5-8 PM on weekdays
    if (isWeekday && ((hour >= 7 && hour < 9) || (hour >= 17 && hour < 20))) {
      return true;
    }
    return false;
  }
}

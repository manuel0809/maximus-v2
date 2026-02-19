// lib/services/hourly_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class HourlyService {
  HourlyService._();
  static final HourlyService instance = HourlyService._();
  
  final _client = Supabase.instance.client;
  
  // ══════════════════════════════════════
  // TARIFAS POR VEHÍCULO (PREMIUM 2025) ✅
  // ══════════════════════════════════════
  Map<String, Map<String, dynamic>> getVehicleRates() {
    return {
      'suburban': {
        'name': 'Suburban RST 2026',
        'hourly_rate': 165.0,
        'min_hours': 4,
        'miles_per_hour': 25.0,
        'extra_mile_rate': 5.50,
        'packages': {
          4: 620.0,
          6: 900.0,
          8: 1180.0,
          10: 1450.0,
          12: 1700.0,
        },
      },
      'yukon': {
        'name': 'GMC Yukon 2026',
        'hourly_rate': 185.0,
        'min_hours': 4,
        'miles_per_hour': 25.0,
        'extra_mile_rate': 6.25,
        'packages': {
          4: 695.0,
          6: 1010.0,
          8: 1340.0,
          10: 1650.0,
          12: 1950.0,
        },
      },
      'escalade': {
        'name': 'Cadillac Escalade 2025',
        'hourly_rate': 225.0,
        'min_hours': 4,
        'miles_per_hour': 25.0,
        'extra_mile_rate': 7.50,
        'packages': {
          4: 840.0,
          6: 1230.0,
          8: 1620.0,
          10: 2000.0,
          12: 2350.0,
        },
      },
    };
  }
  
  // ══════════════════════════════════════
  // CALCULAR PRECIO (CON RECARGOS PREMIUM)
  // ══════════════════════════════════════
  Map<String, dynamic> calculatePrice({
    required String vehicleType,
    required int hours,
    required String zone,
    DateTime? bookingDateTime,
    bool isAirport = false,
    int additionalStops = 0,
  }) {
    final rates = getVehicleRates();
    // Normalize vehicleType to keys
    String normalizedType = vehicleType.toLowerCase();
    if (normalizedType.contains('suburban')) {
      normalizedType = 'suburban';
    } else if (normalizedType.contains('yukon')) {
      normalizedType = 'yukon';
    } else if (normalizedType.contains('escalade')) {
      normalizedType = 'escalade';
    } else {
      normalizedType = 'suburban'; // Default
    }

    final vehicleRates = rates[normalizedType]!;
    
    double basePrice = 0;
    final packagePrice = vehicleRates['packages'][hours];
    
    // Validar mínimo 4 horas
    if (hours < vehicleRates['min_hours']) {
      return {
        'error': 'Mínimo ${vehicleRates['min_hours']} horas para servicio por hora',
        'min_hours': vehicleRates['min_hours'],
      };
    }
    
    // Si hay paquete predefinido, usarlo (más barato)
    if (packagePrice != null) {
      basePrice = packagePrice;
    } else {
      // Si no, calcular por hora
      basePrice = hours * (vehicleRates['hourly_rate'] as double);
    }
    
    // Millas incluidas
    final milesPerHour = vehicleRates['miles_per_hour'] as double;
    final milesIncluded = milesPerHour * hours;
    
    // ══════════════════════════════════════
    // RECARGOS AUTOMÁTICOS
    // ══════════════════════════════════════
    double surchargePercent = 0;
    double fixedSurcharges = 0;
    bool isNightTime = false;
    bool isWeekendLateNight = false;
    bool isHighSeason = false;
    bool isSpecialEvent = false;
    bool isHoliday = false;
    List<String> surchargeReasons = [];
    
    if (bookingDateTime != null) {
      final hour = bookingDateTime.hour;
      final dayOfWeek = bookingDateTime.weekday;
      final month = bookingDateTime.month;
      final day = bookingDateTime.day;
      
      // Nocturno (10pm - 6am) +25%
      if (hour >= 22 || hour < 6) {
        isNightTime = true;
        surchargePercent += 0.25;
        surchargeReasons.add('Recargo nocturno (25%)');
      }
      
      // Madrugada fin de semana (Fri-Sat 2am-5am) +40%
      // Note: Friday night into Saturday morning (Sat 2am-5am) 
      // or Saturday night into Sunday morning (Sun 2am-5am)
      if ((dayOfWeek == 6 || dayOfWeek == 7) && hour >= 2 && hour < 5) {
        isWeekendLateNight = true;
        surchargePercent += 0.40;
        surchargeReasons.add('Madrugada fin de semana (40%)');
      }
      
      // Temporada alta Miami (Dic 15 - Abr 15)
      if ((month == 12 && day >= 15) || month <= 4) {
        isHighSeason = true;
        surchargePercent += 0.30;
        surchargeReasons.add('Temporada alta Miami (30%)');
      }
      
      // Temporada alta Orlando (Jun 1 - Ago 31)
      if (zone.toLowerCase() == 'orlando' && month >= 6 && month <= 8) {
        isHighSeason = true;
        surchargePercent += 0.30;
        surchargeReasons.add('Temporada alta Orlando (30%)');
      }
      
      // Eventos especiales
      final specialEvents = [
        {'month': 12, 'day': 1, 'endDay': 10, 'name': 'Art Basel'},
        {'month': 3, 'day': 20, 'endDay': 30, 'name': 'Ultra Music Festival'},
        {'month': 5, 'day': 1, 'endDay': 10, 'name': 'F1 Miami Grand Prix'},
        {'month': 2, 'day': 1, 'endDay': 15, 'name': 'Miami Boat Show'},
        {'month': 3, 'day': 1, 'endDay': 31, 'name': 'Spring Break'},
      ];
      
      for (var event in specialEvents) {
        if (month == event['month'] && 
            day >= (event['day'] as int) && 
            day <= (event['endDay'] as int)) {
          isSpecialEvent = true;
          surchargePercent += 0.50;
          surchargeReasons.add('Evento especial: ${event['name']} (50%)');
          break;
        }
      }
      
      // Días festivos
      final holidays = [
        {'month': 12, 'day': 25, 'name': 'Navidad'},
        {'month': 1, 'day': 1, 'name': 'Año Nuevo'},
        {'month': 7, 'day': 4, 'name': '4 de Julio'},
        {'month': 11, 'day': 28, 'name': 'Acción de Gracias'},
      ];
      
      for (var holiday in holidays) {
        if (month == holiday['month'] && day == holiday['day']) {
          isHoliday = true;
          surchargePercent += 0.40;
          surchargeReasons.add('Día festivo: ${holiday['name']} (40%)');
          break;
        }
      }
    }
    
    // Recargo aeropuerto (fijo)
    if (isAirport) {
      fixedSurcharges += 50.0;
    }
    
    // Paradas adicionales (fijo)
    if (additionalStops > 0) {
      fixedSurcharges += additionalStops * 75.0;
    }
    
    final surchargeAmount = basePrice * surchargePercent;
    final totalPrice = basePrice + surchargeAmount + fixedSurcharges;
    
    return {
      'vehicle_name': vehicleRates['name'],
      'vehicle_type': normalizedType,
      'hours': hours,
      'base_price': basePrice,
      'miles_included': milesIncluded,
      'extra_mile_rate': vehicleRates['extra_mile_rate'],
      'surcharge_percent': surchargePercent,
      'surcharge_amount': surchargeAmount,
      'fixed_surcharges': fixedSurcharges,
      'total_price': totalPrice,
      'is_night_time': isNightTime,
      'is_weekend_late_night': isWeekendLateNight,
      'is_high_season': isHighSeason,
      'is_special_event': isSpecialEvent,
      'is_holiday': isHoliday,
      'surcharge_reasons': surchargeReasons,
      'breakdown': {
        'hourly_rate': vehicleRates['hourly_rate'],
        'package_applied': packagePrice != null,
        'savings': packagePrice != null 
            ? (hours * (vehicleRates['hourly_rate'] as double)) - packagePrice 
            : 0,
        'min_hours_required': vehicleRates['min_hours'],
      },
    };
  }

  Future<void> createBooking(Map<String, dynamic> bookingData) async {
    // Implementation for Supabase insert
    await _client.from('hourly_bookings').insert(bookingData);
  }
}

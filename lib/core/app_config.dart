import 'package:flutter/foundation.dart';

enum AppFlavor {
  staff,
  client,
}

class AppConfig {
  static const String flavorString = String.fromEnvironment('APP_FLAVOR', defaultValue: 'client');
  
  static AppFlavor get flavor {
    if (flavorString == 'staff') {
      return AppFlavor.staff;
    }
    return AppFlavor.client;
  }

  static bool get isStaff => flavor == AppFlavor.staff;
  static bool get isClient => flavor == AppFlavor.client;

  static String get appTitle => isStaff ? 'Maximus Staff' : 'Maximus Client';
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CalendarService {
  static CalendarService? _instance;
  static CalendarService get instance => _instance ??= CalendarService._();

  CalendarService._();

  /// Generates a .ics file content from booking details
  String _generateICSContent({
    required String title,
    required String description,
    required String location,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    final String startStr = _formatDateTime(startTime);
    final String endStr = _formatDateTime(endTime);
    final String stampStr = _formatDateTime(DateTime.now());

    return '''BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Maximus Level Group//Booking System//EN
CALSCALE:GREGORIAN
METHOD:PUBLISH
BEGIN:VEVENT
UID:${stampStr}_${title.hashCode}
DTSTAMP:$stampStr
DTSTART:$startStr
DTEND:$endStr
SUMMARY:$title
DESCRIPTION:$description
LOCATION:$location
STATUS:CONFIRMED
SEQUENCE:0
BEGIN:VALARM
TRIGGER:-PT30M
DESCRIPTION:Recordatorio de Reserva Maximus
ACTION:DISPLAY
END:VALARM
END:VEVENT
END:VCALENDAR''';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.toUtc().year}'
        '${dt.toUtc().month.toString().padLeft(2, '0')}'
        '${dt.toUtc().day.toString().padLeft(2, '0')}T'
        '${dt.toUtc().hour.toString().padLeft(2, '0')}'
        '${dt.toUtc().minute.toString().padLeft(2, '0')}'
        '${dt.toUtc().second.toString().padLeft(2, '0')}Z';
  }

  /// Exports a booking to a .ics file and shares it
  Future<void> addToCalendar({
    required String title,
    required String description,
    required String location,
    required DateTime pickupDate,
  }) async {
    try {
      // Typically bookings are around 2-4 hours, we'll suggest 2 hours duration
      final endTime = pickupDate.add(const Duration(hours: 2));
      
      final icsContent = _generateICSContent(
        title: title,
        description: description,
        location: location,
        startTime: pickupDate,
        endTime: endTime,
      );

      if (kIsWeb) {
        // Handle web download - typically via anchor element
        // In Flutter web this needs a different approach or a package
        debugPrint('CalendarService: Web download not implemented yet');
        return;
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/reserva_maximus.ics');
      await file.writeAsString(icsContent);

      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/calendar')],
        subject: 'Reserva Maximus: $title',
      );

      if (result.status == ShareResultStatus.success) {
        debugPrint('CalendarService: Booking shared successfully');
      }
    } catch (e) {
      debugPrint('CalendarService: Error exporting to calendar: $e');
      rethrow;
    }
  }
}

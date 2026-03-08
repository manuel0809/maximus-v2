import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WhatsAppService {
  static WhatsAppService? _instance;
  static WhatsAppService get instance => _instance ??= WhatsAppService._();

  WhatsAppService._();

  static const String _adminPhoneKey = 'admin_whatsapp_phone';
  
  /// Get the configured admin WhatsApp phone number
  Future<String?> getAdminPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adminPhoneKey);
  }

  /// Save the admin WhatsApp phone number
  Future<void> setAdminPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminPhoneKey, phone);
  }

  /// Launch WhatsApp with a message to a specific number
  Future<void> sendInvitation({
    required String userPhone,
    required String userName,
    required String role,
    required String email,
  }) async {
    // Format the message
    final String message = Uri.encodeComponent(
      'Hola $userName, bienvenido a Maximus Transport. '
      'Has sido registrado como $role.\n\n'
      'Tu correo de acceso: $email\n\n'
      'Por favor descarga nuestra app y usa tus credenciales para comenzar.\n\n'
      'Saludos,\n'
      'Equipo Maximus'
    );

    // If no specific user phone provided, or for testing, we can use a fallback
    if (userPhone.isEmpty) return;

    // Remove non-numeric characters from phone
    final cleanPhone = userPhone.replaceAll(RegExp(r'\D'), '');
    
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanPhone?text=$message');

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch WhatsApp');
    }
  }

  /// Send booking confirmation with driver details
  Future<void> sendBookingConfirmation({
    required String userPhone,
    required String userName,
    required String bookingId,
    required String vehicle,
    required String pickupDate,
    String? driverName,
    String? driverPhone,
    String? driverProfileUrl,
  }) async {
    String driverInfo = '';
    if (driverName != null) {
      driverInfo = '\n\n👨‍✈️ Su Conductor: $driverName';
      if (driverPhone != null) {
        driverInfo += '\n📞 Contacto: $driverPhone';
      }
      if (driverProfileUrl != null) {
        driverInfo += '\n👤 Perfil: $driverProfileUrl';
      }
    }

    final String message = Uri.encodeComponent(
      '🌟 *Confirmación de Reserva Maximus*\n\n'
      'Hola $userName,\n'
      'Es un placer confirmarle que su reserva *$bookingId* está lista.\n\n'
      '🚗 *Vehículo:* $vehicle\n'
      '📅 *Fecha:* $pickupDate$driverInfo\n\n'
      'Gracias por elegir la excelencia.\n'
      '— *Maximus Level Group*'
    );

    if (userPhone.isEmpty) return;

    final cleanPhone = userPhone.replaceAll(RegExp(r'\D'), '');
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanPhone?text=$message');

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch WhatsApp');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/custom_app_bar.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  final String supportWhatsApp = AppConstants.supportWhatsApp;
  final String supportEmail = AppConstants.supportEmail;

  Future<void> _launchWhatsApp() async {
    final Uri url = Uri.parse('https://wa.me/$supportWhatsApp');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _launchEmail() async {
    final Uri url = Uri.parse('mailto:$supportEmail');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Soporte',
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactSection(theme),
            SizedBox(height: 4.h),
            Text(
              'Preguntas Frecuentes',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            _buildFAQList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            const Icon(Icons.support_agent, size: 48, color: Color(0xFF8B1538)),
            SizedBox(height: 2.h),
            Text(
              '¿Cómo podemos ayudarte?',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            const Text(
              'Nuestro equipo de conserjería está disponible 24/7 para asistirte.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _launchWhatsApp,
                    icon: const Icon(Icons.chat),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _launchEmail,
                    icon: const Icon(Icons.email),
                    label: const Text('Email'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQList(ThemeData theme) {
    final faqs = [
      {
        'q': '¿Cómo cancelo una reserva?',
        'a': 'Puedes cancelar una reserva desde la sección de "Bookings" hasta 24 horas antes del servicio sin penalización.'
      },
      {
        'q': '¿Qué incluye el servicio BLACK SUV?',
        'a': 'Incluye un vehículo de lujo, chófer profesional, agua embotellada, y wifi a bordo.'
      },
      {
        'q': '¿Cómo agrego una parada extra?',
        'a': 'Durante la reserva, activa el interruptor "Agregar parada" para introducir una ubicación intermedia.'
      },
       {
        'q': '¿Aceptan pagos con tarjeta?',
        'a': 'Sí, aceptamos todas las tarjetas de crédito principales y pagos digitales seguros.'
      },
    ];

    return Column(
      children: faqs.map((faq) => _buildFAQItem(theme, faq['q']!, faq['a']!)).toList(),
    );
  }

  Widget _buildFAQItem(ThemeData theme, String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
      children: [
        Padding(
          padding: EdgeInsets.all(4.w),
          child: Text(answer),
        ),
      ],
    );
  }
}

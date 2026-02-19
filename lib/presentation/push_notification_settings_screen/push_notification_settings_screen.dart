import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

import '../../services/notification_service.dart';
import '../../services/localization_service.dart';
import './widgets/settings_section_widget.dart';
import './widgets/settings_toggle_widget.dart';
import './widgets/settings_dropdown_widget.dart';

class PushNotificationSettingsScreen extends StatefulWidget {
  const PushNotificationSettingsScreen({super.key});

  @override
  State<PushNotificationSettingsScreen> createState() =>
      _PushNotificationSettingsScreenState();
}

class _PushNotificationSettingsScreenState
    extends State<PushNotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService.instance;
  Map<String, dynamic> preferences = {};
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      setState(() => isLoading = true);
      final data = await _notificationService.getPreferences();
      setState(() {
        preferences = data ?? {};
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar preferencias: $e')),
        );
      }
    }
  }

  Future<void> _savePreferences() async {
    try {
      setState(() => isSaving = true);
      await _notificationService.updatePreferences(preferences);
      setState(() => isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferencias guardadas exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  void _updatePreference(String key, dynamic value) {
    setState(() {
      preferences[key] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              localization.translate('settings_title'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            actions: [
              if (!isLoading)
                TextButton(
                  onPressed: isSaving ? null : _savePreferences,
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          localization.translate('save'),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
            ],
          ),
          body: isLoading
              ? Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                )
              : ListView(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  children: [
                    // Language Settings Section
                    SettingsSectionWidget(
                      title: localization.translate('language_settings'),
                      icon: Icons.language,
                      children: [
                        ListTile(
                          title: Text(
                            localization.translate('select_language'),
                            style: theme.textTheme.bodyLarge,
                          ),
                          subtitle: Text(
                            localization.currentLanguage == 'ES'
                                ? 'Español'
                                : 'English',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: DropdownButton<String>(
                            value: localization.currentLanguage,
                            underline: SizedBox(),
                            items: const [
                              DropdownMenuItem(
                                value: 'ES',
                                child: Text('🇪🇸 Español'),
                              ),
                              DropdownMenuItem(
                                value: 'EN',
                                child: Text('🇺🇸 English'),
                              ),
                            ],
                            onChanged: (value) async {
                              if (value != null) {
                                await localization.setLanguage(value);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        localization.translate(
                                          'language_changed',
                                        ),
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    // Booking Notifications Section
                    SettingsSectionWidget(
                      title: localization.translate('bookings_notifications'),
                      icon: Icons.event_note,
                      children: [
                        SettingsToggleWidget(
                          title: 'Confirmaciones de Reserva',
                          subtitle:
                              'Recibir confirmación cuando se crea una reserva',
                          value: preferences['booking_confirmations'] ?? true,
                          onChanged: (value) =>
                              _updatePreference('booking_confirmations', value),
                        ),
                        SettingsToggleWidget(
                          title: 'Cancelaciones',
                          subtitle: 'Notificar cuando se cancela una reserva',
                          value: preferences['booking_cancellations'] ?? true,
                          onChanged: (value) =>
                              _updatePreference('booking_cancellations', value),
                        ),
                        SettingsToggleWidget(
                          title: 'Modificaciones',
                          subtitle: 'Alertas de cambios en reservas existentes',
                          value: preferences['booking_modifications'] ?? true,
                          onChanged: (value) =>
                              _updatePreference('booking_modifications', value),
                        ),
                        SettingsToggleWidget(
                          title: 'Recibos de Pago',
                          subtitle: 'Confirmación de pagos procesados',
                          value:
                              preferences['booking_payment_receipts'] ?? true,
                          onChanged: (value) => _updatePreference(
                            'booking_payment_receipts',
                            value,
                          ),
                        ),
                        SettingsToggleWidget(
                          title: 'Actualizaciones de Estado',
                          subtitle: 'Cambios en el estado de la reserva',
                          value: preferences['booking_status_updates'] ?? true,
                          onChanged: (value) => _updatePreference(
                            'booking_status_updates',
                            value,
                          ),
                        ),
                        Divider(height: 2.h),
                        SettingsToggleWidget(
                          title: 'Sonido',
                          value: preferences['booking_sound_enabled'] ?? true,
                          onChanged: (value) =>
                              _updatePreference('booking_sound_enabled', value),
                        ),
                        SettingsToggleWidget(
                          title: 'Vibración',
                          value:
                              preferences['booking_vibration_enabled'] ?? true,
                          onChanged: (value) => _updatePreference(
                            'booking_vibration_enabled',
                            value,
                          ),
                        ),
                      ],
                    ),

                    // Driver Notifications Section
                    SettingsSectionWidget(
                      title: localization.translate('driver_notifications'),
                      icon: Icons.person_pin_circle,
                      children: [
                        SettingsToggleWidget(
                          title: 'Asignación de Conductor',
                          subtitle:
                              'Cuando se asigna un conductor a su servicio',
                          value:
                              preferences['driver_assignment_alerts'] ?? true,
                          onChanged: (value) => _updatePreference(
                            'driver_assignment_alerts',
                            value,
                          ),
                        ),
                        SettingsToggleWidget(
                          title: 'Notificaciones de Llegada',
                          subtitle: 'Cuando el conductor está cerca',
                          value:
                              preferences['driver_arrival_notifications'] ??
                              true,
                          onChanged: (value) => _updatePreference(
                            'driver_arrival_notifications',
                            value,
                          ),
                        ),
                        SettingsToggleWidget(
                          title: 'Actualizaciones de Ubicación',
                          subtitle: 'Seguimiento en tiempo real del conductor',
                          value: preferences['driver_location_updates'] ?? true,
                          onChanged: (value) => _updatePreference(
                            'driver_location_updates',
                            value,
                          ),
                        ),
                        SettingsToggleWidget(
                          title: 'Solicitudes de Comunicación',
                          subtitle: 'Mensajes del conductor',
                          value:
                              preferences['driver_communication_requests'] ??
                              true,
                          onChanged: (value) => _updatePreference(
                            'driver_communication_requests',
                            value,
                          ),
                        ),
                        SettingsDropdownWidget(
                          title: 'Tiempo de Anticipación',
                          subtitle: 'Notificar con anticipación',
                          value: preferences['driver_lead_time_minutes'] ?? 10,
                          options: const [
                            {'label': '5 minutos', 'value': 5},
                            {'label': '10 minutos', 'value': 10},
                            {'label': '15 minutos', 'value': 15},
                            {'label': '30 minutos', 'value': 30},
                          ],
                          onChanged: (value) => _updatePreference(
                            'driver_lead_time_minutes',
                            value,
                          ),
                        ),
                        Divider(height: 2.h),
                        SettingsToggleWidget(
                          title: 'Sonido',
                          value: preferences['driver_sound_enabled'] ?? true,
                          onChanged: (value) =>
                              _updatePreference('driver_sound_enabled', value),
                        ),
                        SettingsToggleWidget(
                          title: 'Vibración',
                          value:
                              preferences['driver_vibration_enabled'] ?? true,
                          onChanged: (value) => _updatePreference(
                            'driver_vibration_enabled',
                            value,
                          ),
                        ),
                      ],
                    ),

                    // Trip Completion Section
                    SettingsSectionWidget(
                      title: localization.translate(
                        'trip_completion_notifications',
                      ),
                      icon: Icons.check_circle,
                      children: [
                        SettingsToggleWidget(
                          title: 'Alertas de Finalización',
                          subtitle: 'Cuando el viaje se completa',
                          value: preferences['trip_completion_alerts'] ?? true,
                          onChanged: (value) => _updatePreference(
                            'trip_completion_alerts',
                            value,
                          ),
                        ),
                        SettingsToggleWidget(
                          title: 'Recordatorios de Calificación',
                          subtitle: 'Solicitud para calificar el servicio',
                          value: preferences['trip_rating_reminders'] ?? true,
                          onChanged: (value) =>
                              _updatePreference('trip_rating_reminders', value),
                        ),
                        SettingsToggleWidget(
                          title: 'Entrega de Recibo',
                          subtitle: 'Recibo digital del viaje',
                          value: preferences['trip_receipt_delivery'] ?? true,
                          onChanged: (value) =>
                              _updatePreference('trip_receipt_delivery', value),
                        ),
                        Divider(height: 2.h),
                        SettingsToggleWidget(
                          title: 'Sonido',
                          value: preferences['trip_sound_enabled'] ?? true,
                          onChanged: (value) =>
                              _updatePreference('trip_sound_enabled', value),
                        ),
                        SettingsToggleWidget(
                          title: 'Vibración',
                          value: preferences['trip_vibration_enabled'] ?? true,
                          onChanged: (value) => _updatePreference(
                            'trip_vibration_enabled',
                            value,
                          ),
                        ),
                      ],
                    ),

                    // Promotional Notifications Section
                    SettingsSectionWidget(
                      title: localization.translate(
                        'promotional_notifications',
                      ),
                      icon: Icons.local_offer,
                      children: [
                        SettingsToggleWidget(
                          title: 'Activar Promociones',
                          subtitle: 'Recibir ofertas y promociones especiales',
                          value: preferences['promo_enabled'] ?? true,
                          onChanged: (value) =>
                              _updatePreference('promo_enabled', value),
                        ),
                        SettingsDropdownWidget(
                          title: 'Frecuencia',
                          subtitle: 'Con qué frecuencia recibir promociones',
                          value: preferences['promo_frequency'] ?? 'immediate',
                          options: const [
                            {'label': 'Inmediato', 'value': 'immediate'},
                            {'label': 'Resumen Diario', 'value': 'daily'},
                            {'label': 'Resumen Semanal', 'value': 'weekly'},
                            {'label': 'Nunca', 'value': 'never'},
                          ],
                          onChanged: (value) =>
                              _updatePreference('promo_frequency', value),
                        ),
                        SettingsToggleWidget(
                          title: 'Descuentos',
                          subtitle: 'Ofertas de descuento',
                          value: preferences['promo_discounts'] ?? true,
                          onChanged: (value) =>
                              _updatePreference('promo_discounts', value),
                        ),
                        SettingsToggleWidget(
                          title: 'Nuevos Servicios',
                          subtitle: 'Anuncios de nuevos servicios',
                          value: preferences['promo_new_services'] ?? true,
                          onChanged: (value) =>
                              _updatePreference('promo_new_services', value),
                        ),
                        SettingsToggleWidget(
                          title: 'Eventos Especiales',
                          subtitle: 'Promociones de eventos',
                          value: preferences['promo_special_events'] ?? true,
                          onChanged: (value) =>
                              _updatePreference('promo_special_events', value),
                        ),
                        Divider(height: 2.h),
                        SettingsToggleWidget(
                          title: 'Sonido',
                          value: preferences['promo_sound_enabled'] ?? false,
                          onChanged: (value) =>
                              _updatePreference('promo_sound_enabled', value),
                        ),
                        SettingsToggleWidget(
                          title: 'Vibración',
                          value:
                              preferences['promo_vibration_enabled'] ?? false,
                          onChanged: (value) => _updatePreference(
                            'promo_vibration_enabled',
                            value,
                          ),
                        ),
                      ],
                    ),

                    // Advanced Settings Section
                    SettingsSectionWidget(
                      title: localization.translate('advanced_settings'),
                      icon: Icons.tune,
                      children: [
                        SettingsToggleWidget(
                          title: 'Horas de Silencio',
                          subtitle:
                              'Silenciar notificaciones en horarios específicos',
                          value: preferences['quiet_hours_enabled'] ?? false,
                          onChanged: (value) =>
                              _updatePreference('quiet_hours_enabled', value),
                        ),
                        if (preferences['quiet_hours_enabled'] == true) ...[
                          ListTile(
                            title: const Text('Hora de Inicio'),
                            subtitle: Text(
                              preferences['quiet_hours_start'] ?? '22:00',
                            ),
                            trailing: const Icon(Icons.access_time),
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(
                                  hour: 22,
                                  minute: 0,
                                ),
                              );
                              if (time != null) {
                                _updatePreference(
                                  'quiet_hours_start',
                                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                );
                              }
                            },
                          ),
                          ListTile(
                            title: const Text('Hora de Fin'),
                            subtitle: Text(
                              preferences['quiet_hours_end'] ?? '07:00',
                            ),
                            trailing: const Icon(Icons.access_time),
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(
                                  hour: 7,
                                  minute: 0,
                                ),
                              );
                              if (time != null) {
                                _updatePreference(
                                  'quiet_hours_end',
                                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                );
                              }
                            },
                          ),
                          SettingsToggleWidget(
                            title: 'Solo Días de Semana',
                            subtitle: 'Aplicar solo de lunes a viernes',
                            value:
                                preferences['quiet_hours_weekdays_only'] ??
                                false,
                            onChanged: (value) => _updatePreference(
                              'quiet_hours_weekdays_only',
                              value,
                            ),
                          ),
                        ],
                        SettingsToggleWidget(
                          title: 'Notificaciones Urgentes',
                          subtitle:
                              'Permitir notificaciones urgentes durante horas de silencio',
                          value:
                              preferences['bypass_quiet_hours_urgent'] ?? true,
                          onChanged: (value) => _updatePreference(
                            'bypass_quiet_hours_urgent',
                            value,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 2.h),
                  ],
                ),
        );
      },
    );
  }
}

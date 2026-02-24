import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../services/localization_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/custom_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool biometricEnabled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localization = Provider.of<LocalizationService>(context);
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      appBar: CustomAppBar(
        title: localization.translate('settings'),
      ),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          // Theme Toggle Section
          _buildSectionHeader(theme, 'APARIENCIA'),
          Container(
            margin: EdgeInsets.only(bottom: 1.h),
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: const Color(0xFFD4AF37),
                    ),
                    SizedBox(width: 3.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modo ${themeService.isDarkMode ? 'Oscuro' : 'Claro'}',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          themeService.isDarkMode ? 'Tema Negro Noir' : 'Tema Blanco Elegante',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: themeService.isDarkMode,
                  onChanged: (_) => themeService.toggleTheme(),
                  activeThumbColor: const Color(0xFFD4AF37),
                  activeTrackColor: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          const Divider(),
          _buildSectionHeader(theme, localization.translate('notification_settings')),
          SwitchListTile(
            title: const Text('Notificaciones Push'),
            subtitle: const Text('Recibe actualizaciones sobre tus reservas'),
            value: notificationsEnabled,
            onChanged: (val) => setState(() => notificationsEnabled = val),
            activeThumbColor: const Color(0xFF8B1538),
          ),
          const Divider(),
          _buildSectionHeader(theme, localization.translate('privacy_settings')),
          SwitchListTile(
            title: const Text('Acceso Biométrico'),
            subtitle: const Text('Usa FaceID o Huella para entrar'),
            value: biometricEnabled,
            onChanged: (val) => setState(() => biometricEnabled = val),
            activeThumbColor: const Color(0xFF8B1538),
          ),
          ListTile(
            title: Text(localization.translate('change_password')),
            leading: const Icon(Icons.lock_outline),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          _buildSectionHeader(theme, localization.translate('language_settings')),
          ListTile(
            title: Text(localization.translate('language')),
            subtitle: Text(localization.currentLanguage == 'ES' ? 'Español' : 'English'),
            leading: const Icon(Icons.language),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(localization),
          ),
          const Divider(),
          _buildSectionHeader(theme, localization.translate('about')),
          ListTile(
            title: const Text('Versión de la App'),
            subtitle: Text('${AppConstants.appVersion} (Build 2026)'),
          ),
          ListTile(
            title: const Text('Términos y Condiciones'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Política de Privacidad'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () {},
          ),
          SizedBox(height: 4.h),
          Center(
            child: Text(
              '© 2026 MAXIMUS LEVEL GROUP',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 1.w),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showLanguagePicker(LocalizationService localization) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Español'),
                trailing: localization.currentLanguage == 'ES' ? const Icon(Icons.check, color: Color(0xFF8B1538)) : null,
                onTap: () {
                  localization.setLanguage('ES');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('English'),
                trailing: localization.currentLanguage == 'EN' ? const Icon(Icons.check, color: Color(0xFF8B1538)) : null,
                onTap: () {
                  localization.setLanguage('EN');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

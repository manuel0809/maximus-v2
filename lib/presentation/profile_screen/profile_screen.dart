import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService.instance;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    final data = await _userService.getCurrentUser();
    if (mounted) {
      setState(() {
        userData = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Mi Perfil',
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  _buildProfileHeader(theme),
                  SizedBox(height: 4.h),
                  _buildMenuSection(theme),
                  SizedBox(height: 4.h),
                  _buildLogoutButton(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    final level = userData?['membership_level'] as String? ?? 'Bronce';
    final photoUrl = userData?['photo_url'] as String?;
    Color levelColor = const Color(0xFF8B1538);
    if (level == 'Plata') levelColor = Colors.grey;
    if (level == 'Oro') levelColor = Colors.amber;
    if (level == 'Platino') levelColor = const Color(0xFFB4B4B4);

    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 12.w,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null ? Icon(Icons.person, size: 15.w, color: theme.colorScheme.primary) : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFF8B1538), shape: BoxShape.circle),
                child: Icon(Icons.camera_alt, size: 4.w, color: Colors.white),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: levelColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: levelColor),
          ),
          child: Text(
            'Nivel $level',
            style: TextStyle(color: levelColor, fontWeight: FontWeight.bold, fontSize: 10.sp),
          ),
        ),
        SizedBox(height: 1.5.h),
        Text(
          userData?['full_name'] ?? 'Usuario',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          userData?['email'] ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildMenuSection(ThemeData theme) {
    return Column(
      children: [
        _buildMenuItem(
          theme,
          icon: Icons.edit_outlined,
          title: 'Editar Perfil',
          onTap: _showEditProfileDialog,
        ),
        _buildMenuItem(
          theme,
          icon: Icons.star_border,
          title: 'Programa de Fidelidad',
          onTap: () => Navigator.pushNamed(context, '/loyalty-dashboard-screen'),
        ),
        _buildMenuItem(
          theme,
          icon: Icons.history,
          title: 'Historial de Reservas',
          onTap: () => Navigator.pushNamed(context, '/payments-invoices-screen'),
        ),
        _buildMenuItem(
          theme,
          icon: Icons.folder_open_outlined,
          title: 'Mis Documentos',
          onTap: () => Navigator.pushNamed(context, '/my-documents-screen'),
        ),
        _buildMenuItem(
          theme,
          icon: Icons.settings_outlined,
          title: 'Configuración',
          onTap: () => Navigator.pushNamed(context, '/settings-screen'),
        ),
        _buildMenuItem(
          theme,
          icon: Icons.notifications_none,
          title: 'Notificaciones',
          onTap: () => Navigator.pushNamed(context, '/push-notification-settings-screen'),
        ),
      ],
    );
  }

  void _showEditProfileDialog() {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: userData?['full_name']);
    final phoneController = TextEditingController(text: userData?['phone']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre Completo')),
            SizedBox(height: 2.h),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Teléfono'), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (userData?['id'] != null) {
                await _userService.updateUserProfile(
                  userId: userData!['id'],
                  updates: {'full_name': nameController.text.trim(), 'phone': phoneController.text.trim()},
                );
                Navigator.pop(context);
                _loadUserData();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: theme.textTheme.bodyLarge),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(vertical: 0.5.h),
    );
  }

  Widget _buildLogoutButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          _userService.signOut();
          Navigator.pushNamedAndRemoveUntil(context, '/login-registration-screen', (route) => false);
        },
        icon: const Icon(Icons.logout),
        label: const Text('Cerrar Sesión'),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.error,
          side: BorderSide(color: theme.colorScheme.error),
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
        ),
      ),
    );
  }
}

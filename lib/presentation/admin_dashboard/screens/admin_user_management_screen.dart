import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/premium_card.dart';
import '../../../services/user_service.dart';
import '../../../core/constants/app_roles.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final UserService _userService = UserService.instance;
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      final data = await _userService.getUsers(query: searchQuery);
      setState(() {
        users = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(title: 'Gestión de Usuarios'),
      body: Column(
        children: [
          _buildSearchBar(theme),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _buildUserCard(theme, user);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateUserDialog,
        label: const Text('Nuevo Usuario'),
        icon: const Icon(Icons.person_add),
        backgroundColor: const Color(0xFF8B1538),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: TextField(
        onChanged: (value) {
          searchQuery = value;
          _loadUsers();
        },
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o email...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildUserCard(ThemeData theme, Map<String, dynamic> user) {
    final role = user['role'] ?? 'client';
    
    return PremiumCard(
      padding: EdgeInsets.all(4.w),
      borderRadius: 16,
      useGlassmorphism: true,
      opacity: 0.05,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Text(user['full_name']?[0] ?? 'U', style: TextStyle(color: theme.colorScheme.primary)),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['full_name'] ?? 'Usuario', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(user['email'] ?? '', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1538).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF8B1538).withValues(alpha: 0.2)),
                    ),
                    child: Text(role.toString().toUpperCase(), style: TextStyle(color: const Color(0xFF8B1538), fontSize: 7.sp, fontWeight: FontWeight.bold)),
                  ),
                  if (!(user['is_active'] as bool? ?? true)) ...[
                    SizedBox(height: 0.5.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.05),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () => _confirmApproval(user),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, size: 8.sp, color: const Color(0xFFD4AF37)),
                            SizedBox(width: 1.w),
                            Text(
                              'APROBAR',
                              style: TextStyle(
                                color: const Color(0xFFD4AF37),
                                fontSize: 7.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          Divider(height: 3.h, color: Colors.white.withValues(alpha: 0.1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(Icons.lock_reset, 'Pass', () => _showResetPasswordDialog(user)),
              _buildActionButton(Icons.admin_panel_settings, 'Rol', () => _showChangeRoleDialog(user)),
              _buildActionButton(Icons.trending_up, 'Nivel', () => _showLevelUpDialog(user)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFE8B4B8)),
          SizedBox(height: 0.5.h),
          Text(label, style: TextStyle(fontSize: 8.sp, color: Colors.white70)),
        ],
      ),
    );
  }

  void _showCreateUserDialog() {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'client';
    final formKey = GlobalKey<FormState>();
    bool isCreating = false;

    showDialog(
      context: context,
            builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final dialogNavigator = Navigator.of(context);
          final dialogMessenger = ScaffoldMessenger.of(context);
          return AlertDialog(
          title: const Text('Crear Nuevo Usuario'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                    validator: (v) => v?.contains('@') == true ? null : 'Email inválido',
                  ),
                  SizedBox(height: 2.h),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre Completo', prefixIcon: Icon(Icons.person)),
                    validator: (v) => v != null && v.length > 3 ? null : 'Requerido',
                  ),
                  SizedBox(height: 2.h),
                   TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone)),
                  ),
                  SizedBox(height: 2.h),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: 'Rol Inicial', prefixIcon: Icon(Icons.admin_panel_settings)),
                    items: const [
                      DropdownMenuItem(value: 'client', child: Text('Cliente')),
                      DropdownMenuItem(value: 'driver', child: Text('Conductor')),
                      DropdownMenuItem(value: 'assistant', child: Text('Asistente')),
                      DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                    ],
                    onChanged: (v) => setState(() => selectedRole = v!),
                  ),
                ],
              ),
            ),
          ),
            actions: [
            TextButton(onPressed: () => dialogNavigator.pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: isCreating ? null : () async {
                if (formKey.currentState!.validate()) {
                  setState(() => isCreating = true);
                  try {
                    AppRole roleEnum = AppRole.client;
                    if (selectedRole == 'driver') roleEnum = AppRole.driver;
                    if (selectedRole == 'assistant') roleEnum = AppRole.assistant;
                    if (selectedRole == 'admin') roleEnum = AppRole.admin;

                    await _userService.createUser(
                      email: emailController.text.trim(),
                      fullName: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      role: roleEnum,
                    );
                    if (!mounted) return;
                    dialogNavigator.pop();
                    _loadUsers();
                    dialogMessenger.showSnackBar(const SnackBar(content: Text('Usuario creado (Perfil). Solicite al usuario registrarse con este email.')));
                  } catch (e) {
                    if (!mounted) return;
                    setState(() => isCreating = false);
                    dialogMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: isCreating ? const CircularProgressIndicator(color: Colors.white) : const Text('Crear'),
            ),
          ],
        );
        }
      ),
    );
  }

  void _showResetPasswordDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) {
        final dialogNavigator = Navigator.of(context);
        final dialogMessenger = ScaffoldMessenger.of(context);
        return AlertDialog(
          title: const Text('Restablecer Contraseña'),
          content: Text('¿Enviar correo de recuperación a ${user['email']}?'),
          actions: [
            TextButton(onPressed: () => dialogNavigator.pop(), child: const Text('Cancelar')),
            TextButton(
              onPressed: () async {
                dialogNavigator.pop();
                try {
                  await _userService.sendPasswordResetEmail(user['email']);
                  if (!mounted) return;
                  dialogMessenger.showSnackBar(const SnackBar(content: Text('Correo enviado correctamente')));
                } catch (e) {
                  if (!mounted) return;
                  dialogMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  void _showChangeRoleDialog(Map<String, dynamic> user) {
    String selectedRole = user['role'] ?? 'client';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final dialogNavigator = Navigator.of(context);
          final dialogMessenger = ScaffoldMessenger.of(context);
          return AlertDialog(
          title: const Text('Cambiar Rol de Usuario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Usuario: ${user['full_name']}'),
              SizedBox(height: 2.h),
              DropdownButtonFormField<String>(
                initialValue: UserService.validRoles.contains(selectedRole) ? selectedRole : 'client',
                items: UserService.validRoles.map((role) {
                  return DropdownMenuItem(value: role, child: Text(role.toUpperCase()));
                }).toList(),
                onChanged: (v) => setState(() => selectedRole = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => dialogNavigator.pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                setState(() => isLoading = true);
                try {
                  await _userService.updateUserRoleByString(user['id'], selectedRole);
                  if (!mounted) return;
                  dialogNavigator.pop();
                  _loadUsers();
                  dialogMessenger.showSnackBar(const SnackBar(content: Text('Rol actualizado')));
                } catch (e) {
                  if (!mounted) return;
                  setState(() => isLoading = false);
                  dialogMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
        }
      ),
    );
  }

  void _showLevelUpDialog(Map<String, dynamic> user) {
    // Placeholder for gamification level logic
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Función de niveles próximamente')));
  }

  void _confirmApproval(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) {
        final dialogNavigator = Navigator.of(context);
        final dialogMessenger = ScaffoldMessenger.of(context);
        return AlertDialog(
        title: const Text('Aprobar Usuario'),
        content: Text('¿Desea activar la cuenta de ${user['full_name']}?'),
        actions: [
          TextButton(onPressed: () => dialogNavigator.pop(), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () async {
               dialogNavigator.pop();
               try {
                 await _userService.updateUserStatus(user['id'], true);
                 if (!mounted) return;
                 _loadUsers();
                 dialogMessenger.showSnackBar(const SnackBar(content: Text('Usuario aprobado y activado')));
               } catch (e) {
                 if (!mounted) return;
                 dialogMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
               }
            },
            child: const Text('Aprobar', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
      },
    );
  }
}

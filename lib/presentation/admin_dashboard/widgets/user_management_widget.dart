import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/user_service.dart';
import '../../../core/constants/app_roles.dart';
import '../../../services/whatsapp_service.dart';
import '../screens/user_profile_screen.dart';

class UserManagementWidget extends StatefulWidget {
  const UserManagementWidget({super.key});

  @override
  State<UserManagementWidget> createState() => _UserManagementWidgetState();
}

class _UserManagementWidgetState extends State<UserManagementWidget> {
  final UserService _userService = UserService.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _selectedRole = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getUsers(
        query: _searchController.text.trim(),
        roleFilter: _selectedRole,
      );
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar usuarios: $e')),
        );
      }
    }
  }

  void _navigateToProfile(String userId, String userName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userId: userId,
          userName: userName,
        ),
      ),
    );
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'client';
    bool sendWhatsApp = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrar Nuevo Usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre Completo', prefixIcon: Icon(Icons.person)),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Correo Electrónico', prefixIcon: Icon(Icons.email)),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Teléfono (WhatsApp)', prefixIcon: Icon(Icons.phone), hintText: '+1...'),
                  keyboardType: TextInputType.phone,
                ),
                sizeBoxHeight(2),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: 'Rol del Sistema'),
                  items: const [
                    DropdownMenuItem(value: 'client', child: Text('Cliente Regular')),
                    DropdownMenuItem(value: 'client_vip', child: Text('Cliente VIP ⭐')),
                    DropdownMenuItem(value: 'client_corp', child: Text('Cliente Corporativo 🏢')),
                    DropdownMenuItem(value: 'driver', child: Text('Conductor 🚗')),
                    DropdownMenuItem(value: 'dispatch', child: Text('Despachador (Dispatch)')),
                    DropdownMenuItem(value: 'mechanic', child: Text('Mecánico / Mantenimiento')),
                    DropdownMenuItem(value: 'booking_operator', child: Text('Operador de Reservas')),
                    DropdownMenuItem(value: 'assistant', child: Text('Asistente')),
                    DropdownMenuItem(value: 'ops_manager', child: Text('Gerente de Operaciones')),
                    DropdownMenuItem(value: 'fleet_manager', child: Text('Gerente de Flota')),
                    DropdownMenuItem(value: 'finance_manager', child: Text('Gerente Financiero')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrador')),
                    DropdownMenuItem(value: 'super_admin', child: Text('Super Admin (Dueño)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
                ),
                CheckboxListTile(
                  title: const Text('Enviar invitación por WhatsApp', style: TextStyle(fontSize: 12)),
                  value: sendWhatsApp,
                  onChanged: (val) => setDialogState(() => sendWhatsApp = val ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || emailController.text.isEmpty) return;
                
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                try {
                  await _userService.createUser(
                    email: emailController.text.trim(),
                    fullName: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    role: AppRole.fromString(selectedRole),
                    // Assuming we'll extend createUser or handle phone separately
                  );

                  if (sendWhatsApp && phoneController.text.isNotEmpty) {
                    await WhatsAppService.instance.sendInvitation(
                      userPhone: phoneController.text.trim(),
                      userName: nameController.text.trim(),
                      role: _getRoleLabel(selectedRole),
                      email: emailController.text.trim(),
                    );
                  }

                  if (!mounted) return;
                  navigator.pop();
                  _loadUsers();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Usuario registrado correctamente')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget sizeBoxHeight(double h) => SizedBox(height: h.h);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gestión de Usuarios',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showAddUserDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuevo Usuario'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1538),
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(width: 2.w),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Actualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        _buildFilters(theme),
        SizedBox(height: 2.h),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? Center(
                      child: Text(
                        'No se encontraron usuarios',
                        style: theme.textTheme.bodyLarge,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return _buildUserCard(theme, user);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
            ),
            onSubmitted: (_) => _loadUsers(),
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Todos')),
              DropdownMenuItem(value: 'client', child: Text('Clientes')),
              DropdownMenuItem(value: 'driver', child: Text('Conductores')),
              DropdownMenuItem(value: 'ops_manager', child: Text('Gerencia Operaciones')),
              DropdownMenuItem(value: 'fleet_manager', child: Text('Gerencia Flota')),
              DropdownMenuItem(value: 'finance_manager', child: Text('Gerencia Financiera')),
              DropdownMenuItem(value: 'admin', child: Text('Staff General')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedRole = value);
                _loadUsers();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(ThemeData theme, Map<String, dynamic> user) {
    final isActive = user['is_active'] == true;
    final role = user['role'] ?? 'client';
    final name = user['full_name'] ?? 'Sin Nombre';
    final email = user['email'] ?? 'Sin Email';

    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(role).withValues(alpha: 0.1),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              color: _getRoleColor(role),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.0),
            Text(email),
            SizedBox(height: 4.0),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: _getRoleColor(role).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    _getRoleLabel(role),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getRoleColor(role),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                Icon(
                  isActive ? Icons.check_circle : Icons.cancel,
                  size: 14,
                  color: isActive ? Colors.green : Colors.red,
                ),
                SizedBox(width: 4.0),
                Text(
                  isActive ? 'Activo' : 'Inactivo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isActive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () => _navigateToProfile(user['id'], name),
        ),
        onTap: () => _navigateToProfile(user['id'], name),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'superAdmin':
        return Colors.deepPurple;
      case 'admin':
        return Colors.red;
      case 'opsManager':
      case 'fleetManager':
      case 'financeManager':
        return Colors.orange;
      case 'driver':
        return Colors.blue;
      case 'clientVip':
        return Colors.amber;
      case 'clientCorp':
        return Colors.teal;
      default:
        return Colors.green;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'superAdmin':
        return 'Super Admin 👑';
      case 'admin':
        return 'Administrador';
      case 'opsManager':
        return 'Gerente Operaciones';
      case 'fleetManager':
        return 'Gerente Flota';
      case 'financeManager':
        return 'Gerente Financiero';
      case 'bookingOperator':
        return 'Operador Reservas';
      case 'assistant':
        return 'Asistente';
      case 'dispatch':
        return 'Dispatch';
      case 'mechanic':
        return 'Mecánico';
      case 'driver':
        return 'Conductor 🚗';
      case 'clientVip':
        return 'Cliente VIP ⭐';
      case 'clientCorp':
        return 'Cliente Corp 🏢';
      default:
        return 'Cliente';
    }
  }
}

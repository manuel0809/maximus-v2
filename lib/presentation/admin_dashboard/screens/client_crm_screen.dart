import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/user_service.dart';
import '../../../widgets/custom_app_bar.dart';

class ClientCRMScreen extends StatefulWidget {
  const ClientCRMScreen({super.key});

  @override
  State<ClientCRMScreen> createState() => _ClientCRMScreenState();
}

class _ClientCRMScreenState extends State<ClientCRMScreen> {
  final UserService _userService = UserService.instance;
  List<Map<String, dynamic>> clients = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final data = await _userService.getUsers(query: searchQuery, roleFilter: 'client');
      if (mounted) {
        setState(() {
          clients = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(title: 'Gestión de Clientes'),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: TextField(
              onChanged: (val) {
                setState(() => searchQuery = val);
                _loadClients();
              },
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o correo...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : clients.isEmpty
                    ? const Center(child: Text('No se encontraron clientes'))
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        itemCount: clients.length,
                        itemBuilder: (context, index) {
                          final client = clients[index];
                          return _buildClientTile(theme, client);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientTile(ThemeData theme, Map<String, dynamic> client) {
    final verifyStatus = client['verification_status'] ?? 'pending';
    Color statusColor = Colors.orange;
    if (verifyStatus == 'verified') statusColor = Colors.green;
    if (verifyStatus == 'rejected') statusColor = Colors.red;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Text(client['full_name']?[0] ?? 'C', style: TextStyle(color: theme.colorScheme.primary)),
        ),
        title: Text(client['full_name'] ?? 'Usuario Sin Nombre', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(client['email'] ?? 'Sin correo', style: TextStyle(fontSize: 9.sp)),
            SizedBox(height: 0.5.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.2.h),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                verifyStatus.toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 8.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showClientDetails(client),
      ),
    );
  }

  void _showClientDetails(Map<String, dynamic> client) {
     // Navigation to detailed profile or modal with history/notes
     showModalBottomSheet(
       context: context,
       isScrollControlled: true,
       builder: (context) => _buildClientDetailSheet(client),
     );
  }

  Widget _buildClientDetailSheet(Map<String, dynamic> client) {
    return Container(
      padding: EdgeInsets.all(6.w),
      height: 70.h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Detalle del Cliente', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          SizedBox(height: 3.h),
          _buildDetailRow('Teléfono:', client['phone'] ?? 'No registrado'),
          _buildDetailRow('Saldo Pendiente:', '\$0.00'),
          _buildDetailRow('Historial de Rentas:', '3 Finalizadas'),
          SizedBox(height: 3.h),
          const Text('Notas Internas', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 1.h),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Agregar observaciones sobre el comportamiento del cliente...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _userService.toggleUserLock(client['id'], client['is_active'] == true, 'Motivo de bloqueo');
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(client['is_active'] == false ? 'Desbloquear' : 'Bloquear Cliente'),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                     _userService.updateVerificationStatus(userId: client['id'], status: 'verified');
                     Navigator.pop(context);
                     _loadClients();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text('Verificar Licencia'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/branch_service.dart';
import '../../../widgets/custom_app_bar.dart';

class BranchManagementScreen extends StatefulWidget {
  const BranchManagementScreen({super.key});

  @override
  State<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
  final BranchService _branchService = BranchService.instance;
  List<Map<String, dynamic>> branches = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() => isLoading = true);
    final data = await _branchService.getBranches();
    if (mounted) {
      setState(() {
        branches = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Gestión de Sucursales'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(4.w),
              itemCount: branches.length,
              itemBuilder: (context, index) {
                final branch = branches[index];
                return _buildBranchCard(theme, branch);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBranchDialog(context),
        backgroundColor: const Color(0xFF8B1538),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBranchCard(ThemeData theme, Map<String, dynamic> branch) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: EdgeInsets.all(4.w),
        leading: CircleAvatar(
          backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
          child: Icon(Icons.location_city, color: theme.primaryColor),
        ),
        title: Text(branch['name'] ?? 'Sucursal', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(branch['address'] ?? 'Sin dirección'),
            SizedBox(height: 0.5.h),
            Text('Tel: ${branch['phone'] ?? 'N/A'}', style: TextStyle(fontSize: 9.sp)),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Editar')),
            const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
          ],
          onSelected: (val) {
             if (val == 'delete') _branchService.deleteBranch(branch['id']);
             _loadBranches();
          },
        ),
      ),
    );
  }

  void _showAddBranchDialog(BuildContext context) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Sucursal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Dirección')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await _branchService.createBranch({
                'name': nameController.text,
                'address': addressController.text,
                'created_at': DateTime.now().toIso8601String(),
              });
              if (mounted) {
                Navigator.pop(context);
                _loadBranches();
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

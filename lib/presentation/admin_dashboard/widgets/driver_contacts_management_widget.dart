import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/admin_service.dart';

class DriverContactsManagementWidget extends StatefulWidget {
  const DriverContactsManagementWidget({super.key});

  @override
  State<DriverContactsManagementWidget> createState() =>
      _DriverContactsManagementWidgetState();
}

class _DriverContactsManagementWidgetState
    extends State<DriverContactsManagementWidget> {
  final AdminService _adminService = AdminService.instance;
  List<Map<String, dynamic>> _driverContacts = [];
  List<Map<String, dynamic>> _drivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final contacts = await _adminService.getDriverContacts();
      final drivers = await _adminService.getDrivers();
      setState(() {
        _driverContacts = contacts;
        _drivers = drivers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
      }
    }
  }

  void _showAddEditDialog({Map<String, dynamic>? contact}) {
    final isEdit = contact != null;
    String? selectedDriverId = contact?['driver_id'];
    final phoneController = TextEditingController(
      text: contact?['phone_number'] ?? '',
    );
    final notesController = TextEditingController(
      text: contact?['notes'] ?? '',
    );
    bool isActive = contact?['is_active'] ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Editar Contacto' : 'Agregar Contacto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isEdit)
                      DropdownButtonFormField<String>(
                        initialValue: selectedDriverId,
                        decoration: const InputDecoration(
                          labelText: 'Conductor',
                          border: OutlineInputBorder(),
                        ),
                        items: _drivers.map((driver) {
                          return DropdownMenuItem<String>(
                            value: driver['id'],
                            child: Text(driver['full_name'] as String),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedDriverId = value);
                        },
                      ),
                    SizedBox(height: 2.h),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Teléfono',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 2.h),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notas (opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 2.h),
                    SwitchListTile(
                      title: const Text('Activo'),
                      value: isActive,
                      onChanged: (value) {
                        setDialogState(() => isActive = value);
                      },
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
                    if (selectedDriverId == null ||
                        phoneController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Por favor complete los campos requeridos',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      await _adminService.saveDriverContact(
                        driverId: selectedDriverId!,
                        phoneNumber: phoneController.text.trim(),
                        isActive: isActive,
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                      );

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEdit
                                  ? 'Contacto actualizado'
                                  : 'Contacto agregado',
                            ),
                          ),
                        );
                        _loadData();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  child: Text(isEdit ? 'Actualizar' : 'Agregar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteContact(String contactId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Está seguro de eliminar este contacto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.deleteDriverContact(contactId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Contacto eliminado')));
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

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
              'Contactos de Conductores',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_driverContacts.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(4.h),
              child: Text(
                'No hay contactos registrados',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _driverContacts.length,
            itemBuilder: (context, index) {
              final contact = _driverContacts[index];
              final driver = contact['driver'] as Map<String, dynamic>?;

              return Card(
                margin: EdgeInsets.only(bottom: 2.h),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: contact['is_active']
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.person,
                      color: contact['is_active']
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(
                    driver?['full_name'] ?? 'Conductor',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(contact['phone_number'] as String),
                      if (contact['notes'] != null)
                        Text(
                          contact['notes'] as String,
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showAddEditDialog(contact: contact),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                        onPressed: () => _deleteContact(contact['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

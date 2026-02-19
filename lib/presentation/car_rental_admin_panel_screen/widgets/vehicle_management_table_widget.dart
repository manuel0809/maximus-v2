import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../../services/supabase_service.dart';

class VehicleManagementTableWidget extends StatefulWidget {
  final List<Map<String, dynamic>> vehicles;
  final bool isLoading;
  final VoidCallback onVehicleUpdated;

  const VehicleManagementTableWidget({
    super.key,
    required this.vehicles,
    required this.isLoading,
    required this.onVehicleUpdated,
  });

  @override
  State<VehicleManagementTableWidget> createState() =>
      _VehicleManagementTableWidgetState();
}

class _VehicleManagementTableWidgetState
    extends State<VehicleManagementTableWidget> {
  String? editingVehicleId;
  late TextEditingController priceController;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    priceController = TextEditingController();
  }

  @override
  void dispose() {
    priceController.dispose();
    super.dispose();
  }

  void _startEditing(Map<String, dynamic> vehicle) {
    setState(() {
      editingVehicleId = vehicle['id'];
      priceController.text = vehicle['price_per_day']?.toString() ?? '0';
    });
  }

  void _cancelEditing() {
    setState(() {
      editingVehicleId = null;
      priceController.clear();
    });
  }

  Future<void> _savePrice(String vehicleId) async {
    final newPrice = double.tryParse(priceController.text);
    if (newPrice == null || newPrice <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingrese un precio válido')));
      return;
    }

    setState(() => isSaving = true);

    try {
      await SupabaseService.instance.client
          .from('vehicles')
          .update({'price_per_day': newPrice})
          .eq('id', vehicleId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Precio actualizado exitosamente')),
        );
        _cancelEditing();
        widget.onVehicleUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> _toggleAvailability(Map<String, dynamic> vehicle) async {
    final currentStatus = vehicle['is_available'] ?? false;
    try {
      await SupabaseService.instance.client
          .from('vehicles')
          .update({'is_available': !currentStatus})
          .eq('id', vehicle['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus
                  ? 'Vehículo marcado como no disponible'
                  : 'Vehículo marcado como disponible',
            ),
          ),
        );
        widget.onVehicleUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar disponibilidad: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.vehicles.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_car_outlined,
                size: 48.sp,
                color: Colors.grey[400],
              ),
              SizedBox(height: 2.h),
              Text(
                'No hay vehículos disponibles',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            const Color(0xFF8B1538).withAlpha(26),
          ),
          columns: [
            DataColumn(
              label: Text(
                'Vehículo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
              ),
            ),
            DataColumn(
              label: Text(
                'Categoría',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
              ),
            ),
            DataColumn(
              label: Text(
                'Año',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
              ),
            ),
            DataColumn(
              label: Text(
                'Precio/Día',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
              ),
            ),
            DataColumn(
              label: Text(
                'Disponible',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
              ),
            ),
            DataColumn(
              label: Text(
                'Acciones',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
              ),
            ),
          ],
          rows: widget.vehicles.map((vehicle) {
            final isEditing = editingVehicleId == vehicle['id'];
            final categoryName =
                vehicle['vehicle_categories']?['name'] ?? 'N/A';

            return DataRow(
              cells: [
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicle['brand']} ${vehicle['model']}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                      Text(
                        '${vehicle['seats']} asientos • ${vehicle['transmission']}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 1.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(categoryName).withAlpha(26),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      categoryName,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: _getCategoryColor(categoryName),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    vehicle['year']?.toString() ?? 'N/A',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
                DataCell(
                  isEditing
                      ? SizedBox(
                          width: 15.w,
                          child: TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            decoration: InputDecoration(
                              prefixText: '\$ ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 1.w,
                                vertical: 0.5.h,
                              ),
                            ),
                            style: TextStyle(fontSize: 12.sp),
                          ),
                        )
                      : Text(
                          '\$${vehicle['price_per_day']?.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8B1538),
                          ),
                        ),
                ),
                DataCell(
                  Switch(
                    value: vehicle['is_available'] ?? false,
                    onChanged: (_) => _toggleAvailability(vehicle),
                    activeThumbColor: const Color(0xFF2E7D32),
                  ),
                ),
                DataCell(
                  isEditing
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: isSaving
                                  ? null
                                  : () => _savePrice(vehicle['id']),
                              icon: isSaving
                                  ? SizedBox(
                                      width: 12.sp,
                                      height: 12.sp,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                      ),
                                    )
                                  : Icon(
                                      Icons.check,
                                      color: Colors.green,
                                      size: 18.sp,
                                    ),
                              tooltip: 'Guardar',
                            ),
                            IconButton(
                              onPressed: isSaving ? null : _cancelEditing,
                              icon: Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 18.sp,
                              ),
                              tooltip: 'Cancelar',
                            ),
                          ],
                        )
                      : IconButton(
                          onPressed: () => _startEditing(vehicle),
                          icon: Icon(
                            Icons.edit,
                            color: const Color(0xFF8B1538),
                            size: 18.sp,
                          ),
                          tooltip: 'Editar precio',
                        ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getCategoryColor(String name) {
    switch (name.toLowerCase()) {
      case 'económico':
        return const Color(0xFF2E7D32);
      case 'suv':
        return const Color(0xFF1976D2);
      case 'lujo':
        return const Color(0xFF8B1538);
      default:
        return Colors.grey;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/car_rental_service.dart';
import '../../../widgets/custom_app_bar.dart';
import './vehicle_form_screen.dart';

class FleetManagementScreen extends StatefulWidget {
  const FleetManagementScreen({super.key});

  @override
  State<FleetManagementScreen> createState() => _FleetManagementScreenState();
}

class _FleetManagementScreenState extends State<FleetManagementScreen> {
  final CarRentalService _carService = CarRentalService.instance;
  List<Map<String, dynamic>> vehicles = [];
  bool isLoading = true;
  String statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      final data = await _carService.getVehicles();
      if (mounted) {
        setState(() {
          vehicles = data;
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
    final filteredVehicles = vehicles.where((v) {
      if (statusFilter == 'all') return true;
      return v['status'] == statusFilter;
    }).toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Gestión de Flota',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _navigateToForm(null),
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: filteredVehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = filteredVehicles[index];
                      return _buildVehicleCard(theme, vehicle);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          _filterChip('Todos', 'all'),
          _filterChip('Disponible', 'available'),
          _filterChip('Rentado', 'rented'),
          _filterChip('Taller', 'maintenance'),
          _filterChip('Baja', 'out_of_service'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = statusFilter == value;
    return Padding(
      padding: EdgeInsets.only(right: 2.w),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => statusFilter = value);
        },
        selectedColor: const Color(0xFF8B1538).withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF8B1538) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildVehicleCard(ThemeData theme, Map<String, dynamic> vehicle) {
    final status = vehicle['status'] ?? 'unknown';
    final statusColor = status == 'available'
        ? Colors.green
        : status == 'rented'
            ? Colors.blue
            : status == 'maintenance'
                ? Colors.orange
                : Colors.red;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.only(bottom: 2.h),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                  vehicle['image_url'] ?? 'https://via.placeholder.com/300x150',
                  width: double.infinity,
                  height: 20.h,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 20.h,
                    color: Colors.grey[300],
                    child: const Icon(Icons.directions_car, size: 50, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          ListTile(
            title: Text(
              '${vehicle['brand']} ${vehicle['model']}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${vehicle['year']} • ${vehicle['plate'] ?? 'S/N Placa'} • ${vehicle['transmission']}'),
                SizedBox(height: 0.5.h),
                Text(
                  '\$${vehicle['price_per_day']}/día',
                  style: TextStyle(color: const Color(0xFF8B1538), fontWeight: FontWeight.bold, fontSize: 11.sp),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _navigateToForm(vehicle);
                } else if (value == 'delete') {
                  _confirmDelete(vehicle);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Editar')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: Colors.red))])),
              ],
            ),
            onTap: () => _navigateToForm(vehicle),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Vehículo'),
        content: Text('¿Estás seguro de que deseas eliminar el ${vehicle['brand']} ${vehicle['model']}? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => isLoading = true);
              try {
                await _carService.deleteVehicle(vehicle['id']);
                _loadVehicles();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehículo eliminado con éxito')));
              } catch (e) {
                setState(() => isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _navigateToForm(Map<String, dynamic>? vehicle) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleFormScreen(vehicle: vehicle),
      ),
    );
    if (result == true) {
      _loadVehicles();
    }
  }
}

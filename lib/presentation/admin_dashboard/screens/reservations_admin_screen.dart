import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/car_rental_service.dart';
import '../../../services/user_service.dart';
import '../../../widgets/custom_app_bar.dart';
import '../widgets/booking_request_card_widget.dart';
import '../widgets/additional_charges_dialog.dart';

class ReservationsAdminScreen extends StatefulWidget {
  const ReservationsAdminScreen({super.key});

  @override
  State<ReservationsAdminScreen> createState() => _ReservationsAdminScreenState();
}

class _ReservationsAdminScreenState extends State<ReservationsAdminScreen> {
  final CarRentalService _carService = CarRentalService.instance;
  List<Map<String, dynamic>> rentals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRentals();
  }

  Future<void> _loadRentals() async {
    // Note: This would typically use a Get All Rentals admin method
    // For now, using getUserRentals as a mock proxy if admin views all
    final data = await _carService.getUserRentals();
    if (mounted) {
      setState(() {
        rentals = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Control de Reservas',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddBookingDialog(context),
            tooltip: 'Nueva Reserva Manual',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(4.w),
              itemCount: rentals.length,
              itemBuilder: (context, index) {
                final rental = rentals[index];
                // Mapping rental schema to BookingRequestCard requirements
                final booking = {
                  'id': rental['id'],
                  'clientName': rental['profiles']?['full_name'] ?? 'Cliente',
                  'service': 'Alquiler de Coches',
                  'vehicle': '${rental['vehicles']?['brand']} ${rental['vehicles']?['model']}',
                  'date': rental['pickup_date'].toString().split(' ')[0],
                  'time': rental['pickup_date'].toString().split(' ')[1].substring(0, 5),
                  'status': rental['status'],
                  'priority': 'medium',
                  'amount': '\$${rental['total'] ?? rental['price_per_day']}',
                };

                return Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: BookingRequestCardWidget(
                    booking: booking,
                    onApprove: () => _carService.updateRentalStatus(rental['id'], 'confirmed').then((_) => _loadRentals()),
                    onModify: () {
                       // Logic to modify dates/vehicle
                    },
                    onReject: () => _carService.updateRentalStatus(rental['id'], 'cancelled').then((_) => _loadRentals()),
                    onChecklistPickup: rental['status'] == 'confirmed' ? () {} : null,
                    onChecklistReturn: rental['status'] == 'active' ? () => _showChargesDialog(rental) : null,
                  ),
                );
              },
            ),
    );
  }

  void _showChargesDialog(Map<String, dynamic> rental) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AdditionalChargesDialog(rental: rental),
    );
    if (result != null) {
      // Logic to finalize rental with charges
      _carService.updateRentalStatus(rental['id'], 'completed').then((_) => _loadRentals());
    }
  }

  void _showAddBookingDialog(BuildContext context) async {
    final clients = await UserService.instance.getUsers(roleFilter: 'client');
    final vehicles = await _carService.getVehicles(isAvailable: true);
    
    if (!context.mounted) return;

    String selectedClientId = clients.isNotEmpty ? clients[0]['id'] : '';
    String selectedVehicleId = vehicles.isNotEmpty ? vehicles[0]['id'] : '';
    String serviceType = 'Rental'; // Rental or Transport
    DateTime pickupDate = DateTime.now().add(const Duration(days: 1));
    DateTime dropoffDate = DateTime.now().add(const Duration(days: 3));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Crear Reserva Manual'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: serviceType,
                  decoration: const InputDecoration(labelText: 'Tipo de Servicio'),
                  items: const [
                    DropdownMenuItem(value: 'Rental', child: Text('Alquiler de Autos')),
                    DropdownMenuItem(value: 'Transport', child: Text('Transporte Personal')),
                  ],
                  onChanged: (val) => setDialogState(() => serviceType = val!),
                ),
                SizedBox(height: 2.h),
                DropdownButtonFormField<String>(
                  initialValue: selectedClientId,
                  decoration: const InputDecoration(labelText: 'Cliente'),
                  items: clients.map((c) => DropdownMenuItem(
                    value: c['id'].toString(),
                    child: Text(c['full_name'] ?? 'S/N'),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedClientId = val!),
                ),
                SizedBox(height: 2.h),
                if (serviceType == 'Rental')
                  DropdownButtonFormField<String>(
                    initialValue: selectedVehicleId,
                    decoration: const InputDecoration(labelText: 'Vehículo'),
                    items: vehicles.map((v) => DropdownMenuItem(
                      value: v['id'].toString(),
                      child: Text('${v['brand']} ${v['model']}'),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedVehicleId = val!),
                  ),
                SizedBox(height: 2.h),
                ListTile(
                  title: const Text('Fecha Inicio'),
                  subtitle: Text(pickupDate.toString().split(' ')[0]),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: pickupDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setDialogState(() => pickupDate = d);
                  },
                ),
                ListTile(
                  title: const Text('Fecha Fin'),
                  subtitle: Text(dropoffDate.toString().split(' ')[0]),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: dropoffDate,
                      firstDate: pickupDate,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setDialogState(() => dropoffDate = d);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    if (serviceType == 'Rental') {
                      // Manual override: we'd ideally pass the userId to createRental
                      // For now, let's simulate the entry in the DB
                      await _carService.createRental(
                        vehicleId: selectedVehicleId,
                        pickupDate: pickupDate,
                        dropoffDate: dropoffDate,
                        pickupLocation: 'Oficina Central',
                        dropoffLocation: 'Oficina Central',
                        pricePerDay: (vehicles.firstWhere((v) => v['id'] == selectedVehicleId)['price_per_day'] ?? 100).toDouble(),
                      );
                    }
                    if (!mounted) return;
                    navigator.pop();
                    _loadRentals();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Reserva creada con éxito')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
              },
              child: const Text('Crear Reserva'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/car_rental_service.dart';

class FleetAlertsWidget extends StatefulWidget {
  const FleetAlertsWidget({super.key});

  @override
  State<FleetAlertsWidget> createState() => _FleetAlertsWidgetState();
}

class _FleetAlertsWidgetState extends State<FleetAlertsWidget> {
  final CarRentalService _carRentalService = CarRentalService.instance;
  List<Map<String, dynamic>> alertingVehicles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => isLoading = true);
    try {
      final alerts = await _carRentalService.getVehicleAlerts();
      setState(() {
        alertingVehicles = alerts;
      });
    } catch (e) {
      // Silent error
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (alertingVehicles.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 3.w),
            const Text('Toda la flota está al día', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 2.w),
            Text(
              'Alertas de Flota (${alertingVehicles.length})',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.orange[800]),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: alertingVehicles.length,
          itemBuilder: (context, index) {
            final vehicle = alertingVehicles[index];
            final List<String> alerts = List<String>.from(vehicle['alerts'] ?? []);
            
            return Card(
              margin: EdgeInsets.only(bottom: 1.h),
              child: ListTile(
                leading: Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.directions_car, color: Colors.red),
                ),
                title: Text('${vehicle['brand']} ${vehicle['model']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Wrap(
                  spacing: 1.w,
                  children: alerts.map((a) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: a.contains('Vencido') ? Colors.red : Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(a, style: const TextStyle(color: Colors.white, fontSize: 10)),
                  )).toList(),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    // Navigate to vehicle details or maintenance log
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

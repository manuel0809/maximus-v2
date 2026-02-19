import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/car_rental_service.dart';
import '../../widgets/custom_app_bar.dart';

class ActiveRentalDashboard extends StatefulWidget {
  final Map<String, dynamic> rental;

  const ActiveRentalDashboard({super.key, required this.rental});

  @override
  State<ActiveRentalDashboard> createState() => _ActiveRentalDashboardState();
}

class _ActiveRentalDashboardState extends State<ActiveRentalDashboard> {
  final CarRentalService _rentalService = CarRentalService.instance;

  Future<void> _makeEmergencyCall() async {
    final Uri launchUri = Uri(scheme: 'tel', path: '911'); // Or company assistance number
    await launchUrl(launchUri);
  }

  Future<void> _openSupportChat() async {
    final Uri whatsappUri = Uri.parse('https://wa.me/1234567890'); // From AppConstants
    await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _showExtensionModal() async {
    int extraDays = 1;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.all(6.w),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Extender Renta', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 3.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => setModalState(() => extraDays = extraDays > 1 ? extraDays - 1 : 1),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$extraDays días extra', style: TextStyle(fontSize: 16.sp)),
                  IconButton(
                    onPressed: () => setModalState(() => extraDays++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Logic to request extension
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Solicitud de extensión enviada')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1538),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Solicitar Extensión'),
                ),
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicle = widget.rental['vehicles'];

    return Scaffold(
      appBar: CustomAppBar(title: 'Renta Activa'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            // Vehicle Status Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_car, size: 40, color: theme.colorScheme.primary),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${vehicle['brand']} ${vehicle['model']}',
                                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                              ),
                              Text('Placa: ${vehicle['plate'] ?? 'N/A'}', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        _buildStatusBadge('En curso'),
                      ],
                    ),
                    Divider(height: 4.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(Icons.calendar_today, 'Entrega', '15 Feb'),
                        _buildStatItem(Icons.speed, 'Km actual', '15,230'),
                        _buildStatItem(Icons.local_gas_station, 'Gas', '85%'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 3.h),

            // Map Simulation / GPS
            Container(
              height: 25.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  const Center(child: Text('Simulación de GPS en tiempo real')),
                  Positioned(
                    bottom: 2.h,
                    right: 4.w,
                    child: FloatingActionButton.small(
                      onPressed: () {},
                      child: const Icon(Icons.my_location),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 3.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    Icons.warning_amber_rounded,
                    'EMERGENCIA',
                    Colors.red,
                    _makeEmergencyCall,
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: _buildActionButton(
                    Icons.chat_bubble_outline,
                    'SOPORTE',
                    Colors.blue,
                    _openSupportChat,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: _buildActionButton(
                Icons.add_circle_outline,
                'EXTENDER RENTA',
                const Color(0xFF8B1538),
                _showExtensionModal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        SizedBox(height: 0.5.h),
        Text(label, style: TextStyle(fontSize: 8.sp, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatusBadge(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 2.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

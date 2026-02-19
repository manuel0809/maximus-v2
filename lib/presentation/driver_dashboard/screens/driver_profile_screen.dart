import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../widgets/custom_app_bar.dart';

class DriverProfileScreen extends StatelessWidget {
  final Map<String, dynamic> driver;

  const DriverProfileScreen({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicle = driver['vehicle'] ?? {};

    return Scaffold(
      appBar: CustomAppBar(title: 'Perfil del Conductor'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(theme),
            Padding(
              padding: EdgeInsets.all(5.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Estadísticas'),
                  _buildStatsGrid(),
                  SizedBox(height: 4.h),
                  _buildSectionTitle('Vehículo Asignado'),
                  _buildVehicleCard(theme, vehicle),
                  SizedBox(height: 4.h),
                  _buildSectionTitle('Documentación Verificada'),
                  _buildComplianceList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF8B1538),
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(driver['photo'] ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400'),
          ),
          SizedBox(height: 2.h),
          Text(
            driver['name'] ?? 'Carlos Rodríguez',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              Text(
                ' ${driver['rating'] ?? '4.9'} (1,247 viajes)',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem('Años', '5+'),
        _buildStatItem('Lealtad', 'Gold'),
        _buildStatItem('Calidad', '4.95'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF8B1538))),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildVehicleCard(ThemeData theme, Map<String, dynamic> vehicle) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.directions_car, size: 36),
        title: Text('${vehicle['make'] ?? 'Mercedes-Benz'} ${vehicle['model'] ?? 'S-Class'}'),
        subtitle: Text('Placa: ${vehicle['plate'] ?? 'ABC-1234'} • ${vehicle['color'] ?? 'Negro'}'),
        trailing: const Icon(Icons.verified, color: Colors.blue),
      ),
    );
  }

  Widget _buildComplianceList() {
    return Column(
      children: [
        _buildComplianceItem(Icons.badge, 'Licencia Comercial', 'Vigente'),
        _buildComplianceItem(Icons.security, 'Seguro de Pasajeros', 'Vigente'),
        _buildComplianceItem(Icons.health_and_safety, 'Antecedentes Penales', 'Verificado'),
      ],
    );
  }

  Widget _buildComplianceItem(IconData icon, String title, String status) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title),
      trailing: Text(status, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/car_rental_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/category_price_card_widget.dart';
import './widgets/vehicle_management_table_widget.dart';

class CarRentalAdminPanelScreen extends StatefulWidget {
  const CarRentalAdminPanelScreen({super.key});

  @override
  State<CarRentalAdminPanelScreen> createState() =>
      _CarRentalAdminPanelScreenState();
}

class _CarRentalAdminPanelScreenState extends State<CarRentalAdminPanelScreen> {
  final CarRentalService _rentalService = CarRentalService.instance;

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> vehicles = [];
  bool isLoadingCategories = true;
  bool isLoadingVehicles = true;
  String selectedTab = 'categories';
  String? selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadCategories(), _loadVehicles()]);
  }

  Future<void> _loadCategories() async {
    setState(() => isLoadingCategories = true);
    try {
      final data = await _rentalService.getVehicleCategories();
      setState(() {
        categories = data;
        isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => isLoadingCategories = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading categories: $e')));
      }
    }
  }

  Future<void> _loadVehicles() async {
    setState(() => isLoadingVehicles = true);
    try {
      final data = await _rentalService.getVehicles(
        categoryId: selectedCategoryFilter,
      );
      setState(() {
        vehicles = data;
        isLoadingVehicles = false;
      });
    } catch (e) {
      setState(() => isLoadingVehicles = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading vehicles: $e')));
      }
    }
  }

  void _onCategoryFilterChanged(String? categoryId) {
    setState(() => selectedCategoryFilter = categoryId);
    _loadVehicles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CustomAppBar(
        title: 'Panel de Administración - Alquiler de Autos',
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 20.w,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10.0,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(height: 2.h),
                _buildSidebarItem(
                  icon: Icons.category,
                  label: 'Categorías',
                  isSelected: selectedTab == 'categories',
                  onTap: () => setState(() => selectedTab = 'categories'),
                ),
                _buildSidebarItem(
                  icon: Icons.directions_car,
                  label: 'Vehículos',
                  isSelected: selectedTab == 'vehicles',
                  onTap: () => setState(() => selectedTab = 'vehicles'),
                ),
                _buildSidebarItem(
                  icon: Icons.analytics,
                  label: 'Reportes',
                  isSelected: selectedTab == 'reports',
                  onTap: () => setState(() => selectedTab = 'reports'),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 3.h),
                  if (selectedTab == 'categories') _buildCategoriesSection(),
                  if (selectedTab == 'vehicles') _buildVehiclesSection(),
                  if (selectedTab == 'reports') _buildReportsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.5.h),
        margin: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.5.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B1538).withAlpha(26) : null,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF8B1538) : Colors.grey[600],
              size: 20.sp,
            ),
            SizedBox(width: 1.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF8B1538)
                      : Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B1538), Color(0xFFD4AF37)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(Icons.admin_panel_settings, color: Colors.white, size: 24.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de Precios',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Administra los precios de categorías y vehículos individuales',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withAlpha(230),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    if (isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Categorías de Vehículos',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            TextButton.icon(
              onPressed: _loadCategories,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2.w,
            mainAxisSpacing: 2.h,
            childAspectRatio: 1.2,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return CategoryPriceCardWidget(
              category: categories[index],
              onPriceUpdated: _loadCategories,
            );
          },
        ),
      ],
    );
  }

  Widget _buildVehiclesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gestión de Vehículos Individuales',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButton<String?>(
                    value: selectedCategoryFilter,
                    hint: const Text('Todas las categorías'),
                    underline: const SizedBox(),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todas las categorías'),
                      ),
                      ...categories.map(
                        (cat) => DropdownMenuItem(
                          value: cat['id'],
                          child: Text(cat['name']),
                        ),
                      ),
                    ],
                    onChanged: _onCategoryFilterChanged,
                  ),
                ),
                SizedBox(width: 2.w),
                TextButton.icon(
                  onPressed: _loadVehicles,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 2.h),
        VehicleManagementTableWidget(
          vehicles: vehicles,
          isLoading: isLoadingVehicles,
          onVehicleUpdated: _loadVehicles,
        ),
      ],
    );
  }

  Widget _buildReportsSection() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(Icons.analytics, size: 48.sp, color: Colors.grey[400]),
          SizedBox(height: 2.h),
          Text(
            'Reportes y Análisis',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Próximamente: Análisis de rentabilidad, tendencias de reservas y optimización de precios',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

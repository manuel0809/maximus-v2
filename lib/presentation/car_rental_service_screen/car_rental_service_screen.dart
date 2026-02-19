import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/car_rental_service.dart';
import './widgets/category_filter_widget.dart';
import './widgets/vehicle_card_rental_widget.dart';
import './widgets/date_location_search_widget.dart';
import './widgets/vehicle_filter_bottom_sheet.dart';

class CarRentalServiceScreen extends StatefulWidget {
  const CarRentalServiceScreen({super.key});

  @override
  State<CarRentalServiceScreen> createState() => _CarRentalServiceScreenState();
}

class _CarRentalServiceScreenState extends State<CarRentalServiceScreen> {
  final CarRentalService _rentalService = CarRentalService.instance;

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> vehicles = [];
  String? selectedCategoryId;
  bool isLoadingCategories = true;
  bool isLoadingVehicles = true;

  double? pickupLat;
  double? pickupLng;
  double? dropoffLat;
  double? dropoffLng;
  double? currentLat;
  double? currentLng;
  bool isLoadingLocation = true;

  String pickupLocation = '';
  String dropoffLocation = '';
  DateTime? pickupDate;
  DateTime? dropoffDate;

  // Advanced Filters
  double? minPrice;
  double? maxPrice;
  String? transmission;
  int? passengers;

  // Comparison Mode
  bool isComparisonMode = false;
  List<Map<String, dynamic>> selectedVehiclesForComparison = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadVehicles();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentLat = position.latitude;
        currentLng = position.longitude;
        pickupLat = position.latitude;
        pickupLng = position.longitude;
        isLoadingLocation = false;
      });
    } catch (e) {
      setState(() => isLoadingLocation = false);
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar categorías: $e')),
        );
      }
    }
  }

  Future<void> _loadVehicles() async {
    setState(() => isLoadingVehicles = true);
    try {
      final data = await _rentalService.getVehicles(
        categoryId: selectedCategoryId,
        isAvailable: true,
        minPrice: minPrice,
        maxPrice: maxPrice,
        transmission: transmission,
        passengers: passengers,
      );
      setState(() {
        vehicles = data;
        isLoadingVehicles = false;
      });
    } catch (e) {
      setState(() => isLoadingVehicles = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar vehículos: $e')),
        );
      }
    }
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      selectedCategoryId = categoryId;
    });
    _loadVehicles();
  }

  void _onSearchPressed() {
    if (pickupDate != null && dropoffDate != null) {
      _loadVehicles();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona fechas de recogida y devolución'),
        ),
      );
    }
  }

  String _getCategoryIcon(String? icon) {
    if (icon == null) return '🚗';
    return icon;
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VehicleFilterBottomSheet(
        initialMinPrice: minPrice,
        initialMaxPrice: maxPrice,
        initialTransmission: transmission,
        initialPassengers: passengers,
        onApply: (min, max, trans, pass) {
          setState(() {
            minPrice = min;
            maxPrice = max;
            transmission = trans;
            passengers = pass;
          });
          _loadVehicles();
        },
      ),
    );
  }

  void _toggleComparison(Map<String, dynamic> vehicle) {
    setState(() {
      if (selectedVehiclesForComparison.any((v) => v['id'] == vehicle['id'])) {
        selectedVehiclesForComparison.removeWhere((v) => v['id'] == vehicle['id']);
      } else {
        if (selectedVehiclesForComparison.length < 3) {
          selectedVehiclesForComparison.add(vehicle);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Puedes comparar hasta 3 vehículos')),
          );
        }
      }
    });
  }

  void _showComparisonDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Column(
          children: [
            AppBar(
              title: const Text('Comparar Vehículos'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              backgroundColor: const Color(0xFF8B1538),
              foregroundColor: Colors.white,
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: selectedVehiclesForComparison.map((v) => DataColumn(
                      label: Text('${v['brand']} ${v['model']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    )).toList(),
                    rows: [
                      DataRow(cells: selectedVehiclesForComparison.map((v) => DataCell(
                        Text('\$${v['price_per_day']}/día'),
                      )).toList()),
                      DataRow(cells: selectedVehiclesForComparison.map((v) => DataCell(
                        Text('${v['year']}'),
                      )).toList()),
                      DataRow(cells: selectedVehiclesForComparison.map((v) => DataCell(
                        Text('${v['transmission'] ?? 'Manual'}'),
                      )).toList()),
                      DataRow(cells: selectedVehiclesForComparison.map((v) => DataCell(
                        Text('${v['seats'] ?? 5} asientos'),
                      )).toList()),
                      DataRow(cells: selectedVehiclesForComparison.map((v) => DataCell(
                        Text(v['category_name'] ?? 'Económico'),
                      )).toList()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
// ... existing build parts
    return Scaffold(
      floatingActionButton: selectedVehiclesForComparison.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showComparisonDialog,
              backgroundColor: const Color(0xFF8B1538),
              label: Text('Comparar (${selectedVehiclesForComparison.length})'),
              icon: const Icon(Icons.compare_arrows, color: Colors.white),
            )
          : null,
      body: CustomScrollView(
// ... rest of build method will be updated in next chunks
        slivers: [
          SliverAppBar(
            expandedHeight: 25.h,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B1538), Color(0xFFE8B4B8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.navigation,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Tu ubicación actual:',
                              style: TextStyle(
                                color: Colors.white.withAlpha(230),
                                fontSize: 11.sp,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            if (isLoadingLocation)
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white.withAlpha(230),
                                  ),
                                ),
                              )
                            else if (currentLat != null && currentLng != null)
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 2.w,
                                    vertical: 0.5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(51),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Text(
                                    '${currentLat!.toStringAsFixed(4)}, ${currentLng!.toStringAsFixed(4)}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                            else
                              Text(
                                'No disponible',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(179),
                                  fontSize: 10.sp,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 1.5.h),
                        Text(
                          '🚗 Alquiler de Autos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Económicos, SUVs y de lujo • Encuentra autos cerca de ti',
                          style: TextStyle(
                            color: Colors.white.withAlpha(230),
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          SliverToBoxAdapter(
            child: Transform.translate(
              offset: Offset(0, -3.h),
              child: DateLocationSearchWidget(
                pickupLat: pickupLat,
                pickupLng: pickupLng,
                dropoffLat: dropoffLat,
                dropoffLng: dropoffLng,
                pickupDate: pickupDate,
                dropoffDate: dropoffDate,
                onPickupLocationChanged: (lat, lng) {
                  setState(() {
                    pickupLat = lat;
                    pickupLng = lng;
                  });
                },
                onDropoffLocationChanged: (lat, lng) {
                  setState(() {
                    dropoffLat = lat;
                    dropoffLng = lng;
                  });
                },
                onPickupDateChanged: (date) =>
                    setState(() => pickupDate = date),
                onDropoffDateChanged: (date) =>
                    setState(() => dropoffDate = date),
                onSearchPressed: _onSearchPressed,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categorías',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  isLoadingCategories
                      ? const Center(child: CircularProgressIndicator())
                      : CategoryFilterWidget(
                          categories: categories,
                          selectedCategoryId: selectedCategoryId,
                          onCategorySelected: _onCategorySelected,
                          getCategoryIcon: _getCategoryIcon,
                        ),
                  SizedBox(height: 3.h),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Autos disponibles',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _showFilters,
                    icon: Icon(
                      Icons.tune,
                      color: (minPrice != null || transmission != null || passengers != null)
                          ? const Color(0xFF8B1538)
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(4.w),
            sliver: isLoadingVehicles
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.h),
                        child: const CircularProgressIndicator(),
                      ),
                    ),
                  )
                : vehicles.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.h),
                        child: Text(
                          'No hay vehículos disponibles',
                          style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                : SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      mainAxisSpacing: 2.h,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final vehicle = vehicles[index];
                      final isSelected = selectedVehiclesForComparison.any((v) => v['id'] == vehicle['id']);
                      return VehicleCardRentalWidget(
                        vehicle: vehicle,
                        pickupDate: pickupDate,
                        dropoffDate: dropoffDate,
                        onReservePressed: () => _handleReservation(vehicle),
                        isSelected: isSelected,
                        onSelected: () => _toggleComparison(vehicle),
                      );
                    }, childCount: vehicles.length),
                  ),
          ),
        ],
      ),
    );
  }

  void _handleReservation(Map<String, dynamic> vehicle) {
    if (pickupDate == null || dropoffDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona fechas de recogida y devolución'),
        ),
      );
      return;
    }

    if (pickupLocation.isEmpty || dropoffLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor ingresa ubicaciones de recogida y devolución',
          ),
        ),
      );
      return;
    }

    final price = (vehicle['price_per_day'] is int)
        ? vehicle['price_per_day'].toDouble()
        : (vehicle['price_per_day'] as double);
    
    final breakdown = _rentalService.calculateRentalPrice(
      pricePerDay: price,
      pickupDate: pickupDate!,
      dropoffDate: dropoffDate!,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Reserva'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${vehicle['brand']} ${vehicle['model']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 2.h),
            _buildDetailRow('Recogida:', DateFormat('dd/MM/yyyy').format(pickupDate!)),
            _buildDetailRow('Devolución:', DateFormat('dd/MM/yyyy').format(dropoffDate!)),
            _buildDetailRow('Días:', '${breakdown['days']?.toInt()}'),
            const Divider(),
            _buildPriceRow('Precio Base:', '\$${breakdown['base_daily']?.toStringAsFixed(2)}/día'),
            if ((breakdown['dynamic_daily'] ?? 0) != (breakdown['base_daily'] ?? 0))
               _buildPriceRow(
                 'Precio Dinámico:', 
                 '\$${breakdown['dynamic_daily']?.toStringAsFixed(2)}/día',
                 isHighlight: true,
               ),
            _buildPriceRow('Subtotal:', '\$${breakdown['subtotal']?.toStringAsFixed(2)}'),
            _buildPriceRow('Seguro:', '\$${breakdown['insurance']?.toStringAsFixed(2)}'),
            _buildPriceRow('IVA (16%):', '\$${breakdown['tax']?.toStringAsFixed(2)}'),
            const Divider(),
            _buildPriceRow(
              'Total Estimado:', 
              '\$${breakdown['total']?.toStringAsFixed(2)}',
              isBold: true,
              color: const Color(0xFF8B1538),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _confirmReservation(vehicle, breakdown['total'] ?? 0),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1538),
            ),
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isHighlight = false, bool isBold = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: TextStyle(
              fontSize: 10.sp, 
              color: isHighlight ? Colors.blue : null,
              fontWeight: isBold ? FontWeight.bold : null,
            )
          ),
          Text(
            value, 
            style: TextStyle(
              fontSize: 11.sp, 
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            )
          ),
        ],
      ),
    );
  }

  double _calculateTotal(dynamic pricePerDay) {
    if (pickupDate == null || dropoffDate == null) return 0;
    final price = (pricePerDay is int)
        ? pricePerDay.toDouble()
        : (pricePerDay as double);
    final calculation = _rentalService.calculateRentalPrice(
      pricePerDay: price,
      pickupDate: pickupDate!,
      dropoffDate: dropoffDate!,
    );
    return calculation['total'] ?? 0;
  }

  Future<void> _confirmReservation(Map<String, dynamic> vehicle, double total) async {
    Navigator.pop(context);

    try {
      final price = (vehicle['price_per_day'] is int)
          ? vehicle['price_per_day'].toDouble()
          : vehicle['price_per_day'] as double;

      await _rentalService.createRental(
        vehicleId: vehicle['id'],
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        pickupDate: pickupDate!,
        dropoffDate: dropoffDate!,
        pricePerDay: price,
      );

      // Block vehicle availability
      await _rentalService.updateVehicleStatus(vehicle['id'], 'rented');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reserva creada exitosamente. Recibirás un correo de confirmación.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al crear reserva: $e')));
      }
    }
  }
}

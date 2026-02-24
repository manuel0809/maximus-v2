import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/car_rental_service.dart';
import '../../../widgets/custom_app_bar.dart';
import '../widgets/service_rates_editor_widget.dart';

class VehicleFormScreen extends StatefulWidget {
  final Map<String, dynamic>? vehicle;

  const VehicleFormScreen({super.key, this.vehicle});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final CarRentalService _carService = CarRentalService.instance;
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _plateController;
  late TextEditingController _vinController;
  late TextEditingController _priceController;
  late TextEditingController _mileageController;
  
  String _selectedTransmission = 'Automatic';
  String _selectedStatus = 'available';
  bool isSaving = false;
  
  Map<String, dynamic>? _serviceRates;
  Map<String, dynamic>? _metadata;
  
  File? _selectedImage;
  String? _currentImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _brandController = TextEditingController(text: v?['brand']);
    _modelController = TextEditingController(text: v?['model']);
    _yearController = TextEditingController(text: v?['year']?.toString());
    _plateController = TextEditingController(text: v?['plate']);
    _vinController = TextEditingController(text: v?['vin']);
    _priceController = TextEditingController(text: v?['price_per_day']?.toString());
    _mileageController = TextEditingController(text: v?['current_km']?.toString());
    _selectedTransmission = v?['transmission'] ?? 'Automatic';
    _selectedStatus = v?['status'] ?? 'available';
    _serviceRates = v?['service_rates'];
    _metadata = v?['metadata'];
    _currentImageUrl = v?['image_url'];
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);
    try {
      String? finalImageUrl = _currentImageUrl;
      if (_selectedImage != null) {
        finalImageUrl = await _carService.uploadVehicleImage(_selectedImage!);
      }

      final data = {
        'brand': _brandController.text,
        'model': _modelController.text,
        'year': int.tryParse(_yearController.text),
        'plate': _plateController.text,
        'vin': _vinController.text,
        'price_per_day': double.tryParse(_priceController.text),
        'current_km': int.tryParse(_mileageController.text),
        'transmission': _selectedTransmission,
        'status': _selectedStatus,
        'is_available': _selectedStatus == 'available',
        'service_rates': _serviceRates,
        'metadata': _metadata,
        'image_url': finalImageUrl,
      };

      if (widget.vehicle != null) {
        await _carService.updateVehicle(widget.vehicle!['id'], data);
      } else {
        await _carService.addVehicle(data);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: CustomAppBar(title: widget.vehicle == null ? 'Nuevo Vehículo' : 'Editar Vehículo'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(),
              SizedBox(height: 3.h),
              _buildSectionTitle('Información Básica'),
              _buildTextField('Marca', _brandController),
              _buildTextField('Modelo', _modelController),
              Row(
                children: [
                  Expanded(child: _buildTextField('Año', _yearController, keyboard: TextInputType.number)),
                  SizedBox(width: 4.w),
                  Expanded(child: _buildTextField('Placa', _plateController)),
                ],
              ),
              _buildTextField('VIN (Número de Serie)', _vinController),
              SizedBox(height: 3.h),
              _buildSectionTitle('Especificaciones'),
              _buildDropdown('Transmisión', ['Automatic', 'Manual'], (val) => setState(() => _selectedTransmission = val!)),
              _buildDropdown('Estado', ['available', 'rented', 'maintenance', 'out_of_service'], (val) => setState(() => _selectedStatus = val!)),
              Row(
                children: [
                  Expanded(child: _buildTextField('Precio por día', _priceController, keyboard: TextInputType.number)),
                  SizedBox(width: 4.w),
                  Expanded(child: _buildTextField('Km Actual', _mileageController, keyboard: TextInputType.number)),
                ],
              ),
              if (_serviceRates != null) ...[
                SizedBox(height: 3.h),
                _buildSectionTitle('Tarifas Especiales (Modo Transmporte)'),
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber[900]),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              'Este vehículo tiene configuradas tarifas dinámicas para Black, Black SUV, Por Hora y Eventos.',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.sp, color: Colors.amber[900]),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ServiceRatesEditorWidget(
                                initialRates: _serviceRates!,
                                onSave: (updatedRates) {
                                  setState(() => _serviceRates = updatedRates);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Tarifas actualizadas temporalmente (Guardar para aplicar)')),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_road),
                        label: const Text('Gestionar Tarifas de Transporte'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[800],
                          foregroundColor: Colors.white,
                          minimumSize: Size(double.infinity, 5.h),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 5.h),
              ElevatedButton(
                onPressed: isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 6.h),
                  backgroundColor: const Color(0xFF8B1538),
                  foregroundColor: Colors.white,
                ),
                child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar Vehículo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: DropdownButtonFormField<String>(
        initialValue: items.contains(_selectedTransmission) ? _selectedTransmission : items.first, // Simple mock logic
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 100.w - 8.w,
          height: 25.h,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: _selectedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                )
              : _currentImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(_currentImageUrl!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 40.sp, color: Colors.grey[600]),
                        SizedBox(height: 1.h),
                        Text('Agregar Foto del Auto', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
        ),
      ),
    );
  }
}

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import '../../services/storage_service.dart';
import '../../services/car_rental_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/signature_pad.dart';


class DigitalChecklistScreen extends StatefulWidget {
  final String rentalId;
  final bool isReturn; // true for return, false for pickup

  const DigitalChecklistScreen({
    super.key,
    required this.rentalId,
    this.isReturn = false,
  });

  @override
  State<DigitalChecklistScreen> createState() => _DigitalChecklistScreenState();
}

class _DigitalChecklistScreenState extends State<DigitalChecklistScreen> {
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService.instance;
  final CarRentalService _rentalService = CarRentalService.instance;

  final GlobalKey<SignaturePadState> _signatureKey = GlobalKey<SignaturePadState>();
  
  final Map<String, XFile?> _photos = {
    'Frente': null,
    'Trasera': null,
    'Lateral Izquierdo': null,
    'Lateral Derecho': null,
    'Tablero (Gas/Km)': null,
  };

  final Map<String, XFile?> _damagePhotos = {};

  double _gasLevel = 0.5; // 0.0 to 1.0
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _damageReportController = TextEditingController();
  bool _isSaving = false;

  Future<void> _takePhoto(String label) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
      );
      if (photo != null) {
        setState(() => _photos[label] = photo);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al capturar foto: $e')),
      );
    }
  }

  Future<void> _submitChecklist() async {
    // Validation
    if (_photos.values.any((v) => v == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor toma todas las fotos requeridas')),
      );
      return;
    }

    if (_mileageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa el kilometraje')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final Map<String, String> uploadedUrls = {};

      // Upload Photos
      for (var entry in _photos.entries) {
        final String path = 'checklists/${widget.rentalId}/${widget.isReturn ? 'return' : 'pickup'}_${entry.key.replaceAll(' ', '_')}.jpg';
        
        final bytes = await entry.value!.readAsBytes();
        final url = await _storageService.uploadFile(
          bucket: 'rentals',
          path: path,
          file: bytes,
        );
        uploadedUrls[entry.key] = url;
      }

      // Save Signature
      final signatureImage = await _signatureKey.currentState?.getSignatureImage();
      String? signatureUrl;
      if (signatureImage != null) {
        final byteData = await signatureImage.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final bytes = byteData.buffer.asUint8List();
          signatureUrl = await _storageService.uploadFile(
            bucket: 'rentals',
            path: 'signatures/${widget.rentalId}_${widget.isReturn ? 'return' : 'pickup'}.png',
            file: bytes,
          );
        }
      }

      // Save Checklist Data
      final checklistData = {
        'rental_id': widget.rentalId,
        'type': widget.isReturn ? 'return' : 'pickup',
        'gas_level': _gasLevel,
        'mileage': int.tryParse(_mileageController.text) ?? 0,
        'notes': _notesController.text,
        'damage_report': _damageReportController.text,
        'photos': uploadedUrls,
        'signature_url': signatureUrl,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _rentalService.saveDigitalChecklist(checklistData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checklist guardado correctamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar checklist: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Checklist Digital - ${widget.isReturn ? 'Devolución' : 'Entrega'}',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Fotos del Vehículo (Obligatorio)'),
            SizedBox(height: 2.h),
            _buildPhotoGrid(),
            SizedBox(height: 4.h),
            
            _buildSectionTitle('Estado del Vehículo'),
            SizedBox(height: 2.h),
            Text('Nivel de Combustible: ${(_gasLevel * 100).round()}%'),
            Slider(
              value: _gasLevel,
              onChanged: (val) => setState(() => _gasLevel = val),
              activeColor: const Color(0xFF8B1538),
            ),
            
            SizedBox(height: 2.h),
            TextField(
              controller: _mileageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kilometraje Actual',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.speed),
              ),
            ),
            
            SizedBox(height: 3.h),
            _buildSectionTitle(widget.isReturn ? 'Reporte de Daños' : 'Notas Adicionales'),
            SizedBox(height: 1.h),
            TextField(
              controller: widget.isReturn ? _damageReportController : _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: widget.isReturn ? 'Describe cualquier daño nuevo...' : 'Rayones, golpes o comentarios...',
                border: const OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 4.h),
            _buildSectionTitle('Firma de Conformidad'),
            SizedBox(height: 2.h),
            SignaturePad(
              key: _signatureKey,
            ),
            
            SizedBox(height: 5.h),
            SizedBox(
              width: double.infinity,
              height: 7.h,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submitChecklist,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1538),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar y Finalizar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 2.h,
      crossAxisSpacing: 4.w,
      childAspectRatio: 1.2,
      children: _photos.keys.map((label) => _buildPhotoCard(label)).toList(),
    );
  }

  Widget _buildPhotoCard(String label) {
    final photo = _photos[label];
    return GestureDetector(
      onTap: () => _takePhoto(label),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: photo != null ? Colors.green : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (photo == null) ...[
              const Icon(Icons.camera_alt, size: 30, color: Color(0xFF8B1538)),
              SizedBox(height: 1.h),
              Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 9.sp)),
            ] else ...[
              const Icon(Icons.check_circle, size: 30, color: Colors.green),
              SizedBox(height: 1.h),
              Text('Capturada', style: TextStyle(color: Colors.green, fontSize: 9.sp, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }
}

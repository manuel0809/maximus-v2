import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';
import '../../services/storage_service.dart';
import '../../services/user_service.dart';
import '../../widgets/custom_app_bar.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen> {
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService.instance;
  final UserService _userService = UserService.instance;

  XFile? _licenseImage;
  XFile? _selfieImage;
  bool _isUploading = false;

  Future<void> _pickImage(bool isLicense) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final XFile? selected = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (selected != null) {
        setState(() {
          if (isLicense) {
            _licenseImage = selected;
          } else {
            _selfieImage = selected;
          }
        });
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error al capturar imagen: $e')),
      );
    }
  }

  Future<void> _submitVerification() async {
    if (_licenseImage == null || _selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor captura ambas fotos')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = await _userService.getCurrentUser();
      if (user == null) throw Exception('Usuario no encontrado');

      final userId = user['id'];

      // Upload License
      final licenseBytes = await _licenseImage!.readAsBytes();
      final licenseUrl = await _storageService.uploadFile(
        bucket: 'verification_documents',
        path: '$userId/license.jpg',
        file: licenseBytes,
      );

      // Upload Selfie
      final selfieBytes = await _selfieImage!.readAsBytes();
      final selfieUrl = await _storageService.uploadFile(
        bucket: 'verification_documents',
        path: '$userId/selfie.jpg',
        file: selfieBytes,
      );

      // Update User Profile
      await _userService.updateVerificationDocuments(
        userId: userId,
        licenseUrl: licenseUrl,
        selfieUrl: selfieUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documentos enviados correctamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Verificación de Identidad'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Completa tu perfil',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text(
              'Para rentar vehículos es necesario verificar tu identidad legalmente.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: 4.h),
            _buildCaptureCard(
              title: 'Foto de Licencia de Conducir',
              subtitle: 'Asegúrate que los datos sean legibles',
              image: _licenseImage,
              onTap: () => _pickImage(true),
              icon: Icons.credit_card,
            ),
            SizedBox(height: 3.h),
            _buildCaptureCard(
              title: 'Foto Selfie Facial',
              subtitle: 'Mira directamente a la cámara',
              image: _selfieImage,
              onTap: () => _pickImage(false),
              icon: Icons.face,
            ),
            SizedBox(height: 6.h),
            SizedBox(
              width: double.infinity,
              height: 7.h,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1538),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Enviar para Verificación',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureCard({
    required String title,
    required String subtitle,
    required XFile? image,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: image != null ? Colors.green : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            if (image == null) ...[
              Icon(icon, size: 40, color: const Color(0xFF8B1538)),
              SizedBox(height: 2.h),
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(subtitle, style: theme.textTheme.bodySmall),
            ] else ...[
              const Icon(Icons.check_circle, size: 40, color: Colors.green),
              SizedBox(height: 2.h),
              Text('¡Capturada!', style: theme.textTheme.titleMedium?.copyWith(color: Colors.green, fontWeight: FontWeight.bold)),
              Text('Toca para cambiar la foto', style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/vault_service.dart';
import '../../widgets/custom_app_bar.dart';

class MyDocumentsScreen extends StatefulWidget {
  const MyDocumentsScreen({super.key});

  @override
  State<MyDocumentsScreen> createState() => _MyDocumentsScreenState();
}

class _MyDocumentsScreenState extends State<MyDocumentsScreen> {
  final VaultService _vaultService = VaultService.instance;
  List<Map<String, dynamic>> userDocs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final docs = await _vaultService.getUserDocuments();
    if (mounted) {
      setState(() {
        userDocs = docs;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Bóveda de Documentos',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined),
            onPressed: _showUploadOption,
            tooltip: 'Subir Documento',
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Validación de Identidad'),
                  if (userDocs.isEmpty)
                    _buildEmptyState(theme)
                  else
                    ...userDocs.map((doc) => _buildVaultTile(theme, doc)),
                  
                  SizedBox(height: 4.h),
                  _buildSectionHeader('Legales y Contratos'),
                  _buildMockDocumentTile(
                    theme,
                    icon: Icons.assignment_outlined,
                    title: 'Contrato de Renta #R-1025',
                    subtitle: 'Firmado digitalmente el 12/03/2026',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Text(
        title,
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildVaultTile(ThemeData theme, Map<String, dynamic> doc) {
    final status = doc['status'] ?? 'pending';
    Color statusColor = Colors.orange;
    String statusText = 'Pendiente';
    IconData statusIcon = Icons.hourglass_empty;

    if (status == 'approved') {
      statusColor = Colors.green;
      statusText = 'Verificado';
      statusIcon = Icons.check_circle;
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusText = 'Rechazado';
      statusIcon = Icons.error;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.badge_outlined, color: Color(0xFF8B1538)),
        ),
        title: Text(_mapDocType(doc['document_type'])),
        subtitle: Row(
          children: [
            Icon(statusIcon, size: 12, color: statusColor),
            SizedBox(width: 1.w),
            Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 9.sp)),
          ],
        ),
        trailing: const Icon(Icons.remove_red_eye_outlined),
        onTap: () {
           // Show document image/details
        },
      ),
    );
  }

  String _mapDocType(String type) {
    switch (type) {
      case 'driver_license': return 'Licencia de Conducir';
      case 'passport': return 'Pasaporte';
      default: return 'Identificación Oficial';
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          const Icon(Icons.upload_file, size: 40, color: Colors.grey),
          SizedBox(height: 1.h),
          const Text('Aún no has subido documentos de identidad.', textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildMockDocumentTile(ThemeData theme, {required IconData icon, required String title, required String subtitle}) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey),
        title: Text(title),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 9.sp)),
        trailing: const Icon(Icons.download_outlined),
        onTap: () {},
      ),
    );
  }

  void _showUploadOption() {
     // Implementation of document upload dialog...
     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abriendo selector de documentos...')));
  }
}

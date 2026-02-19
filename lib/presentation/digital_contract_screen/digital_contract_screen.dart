import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/document_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/signature_pad.dart';

class DigitalContractScreen extends StatefulWidget {
  final String rentalId;

  const DigitalContractScreen({super.key, required this.rentalId});

  @override
  State<DigitalContractScreen> createState() => _DigitalContractScreenState();
}

class _DigitalContractScreenState extends State<DigitalContractScreen> {
  final DocumentService _documentService = DocumentService.instance;
  final StorageService _storageService = StorageService.instance;
  final GlobalKey<SignaturePadState> _signatureKey = GlobalKey<SignaturePadState>();
  
  Map<String, dynamic>? contract;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadContract();
  }

  Future<void> _loadContract() async {
    final data = await _documentService.getContract(widget.rentalId);
    if (mounted) {
      setState(() {
        contract = data;
        isLoading = false;
      });
    }
  }

  Future<void> _handleSign() async {
    setState(() => isSaving = true);
    try {
      final signatureImage = await _signatureKey.currentState?.getSignatureImage();
      if (signatureImage != null) {
        final byteData = await signatureImage.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) throw Exception('Error al procesar la firma');
        final signatureBytes = byteData.buffer.asUint8List();

        final signatureUrl = await _storageService.uploadFile(
          bucket: 'signatures',
          path: 'contract_${widget.rentalId}.png',
          file: signatureBytes,
        );

        final success = await _documentService.signContract(contract!['id'], signatureUrl);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contrato firmado correctamente')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al firmar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(title: 'Contrato Digital'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContractContent(theme),
                  SizedBox(height: 4.h),
                  const Text('Firma del Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 1.h),
                  SignaturePad(key: _signatureKey),
                  SizedBox(height: 4.h),
                  _buildActionButtons(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildContractContent(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONTRATO DE ARRENDAMIENTO DE VEHÍCULO',
            style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
          ),
          SizedBox(height: 2.h),
          Text(
            'Por medio del presente contrato, MAXIMUS TRANSPORT (El Arrendador) otorga en uso el vehículo descrito en la reserva a ${contract?['rentals']?['profiles']?['full_name'] ?? 'El Cliente'} (El Arrendatario) bajo los siguientes términos...',
            textAlign: TextAlign.justify,
          ),
          SizedBox(height: 1.h),
          const Text('1. USO DEL VEHÍCULO: El vehículo se entrega en óptimas condiciones...', textAlign: TextAlign.justify),
          const Text('2. SEGURO: El vehículo cuenta con póliza de seguro de cobertura amplia...', textAlign: TextAlign.justify),
          const Text('3. DEVOLUCIÓN: El cliente se compromete a devolver el auto en la fecha pactada...', textAlign: TextAlign.justify),
          // More mock text...
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: ElevatedButton(
            onPressed: isSaving ? null : _handleSign,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1538),
              foregroundColor: Colors.white,
            ),
            child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Firmar Contrato'),
          ),
        ),
      ],
    );
  }
}

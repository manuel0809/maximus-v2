import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/vault_service.dart';

class DocumentReviewWidget extends StatefulWidget {
  const DocumentReviewWidget({super.key});

  @override
  State<DocumentReviewWidget> createState() => _DocumentReviewWidgetState();
}

class _DocumentReviewWidgetState extends State<DocumentReviewWidget> {
  final VaultService _vaultService = VaultService.instance;
  List<Map<String, dynamic>> pendingDocs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingDocs();
  }

  Future<void> _loadPendingDocs() async {
    setState(() => isLoading = true);
    try {
      final docs = await _vaultService.getPendingDocuments();
      setState(() {
        pendingDocs = docs;
      });
    } catch (e) {
      // Log error
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateStatus(String docId, String status, {String? reason}) async {
    try {
      await _vaultService.updateDocumentStatus(
        documentId: docId,
        status: status,
        rejectionReason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Documento ${status == 'approved' ? 'Aprobado' : 'Rechazado'}')),
        );
        _loadPendingDocs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (pendingDocs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No hay documentos pendientes de revisión'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pendingDocs.length,
      itemBuilder: (context, index) {
        final doc = pendingDocs[index];
        final user = doc['user_profiles'];
        return Card(
          margin: EdgeInsets.only(bottom: 2.h),
          child: ExpansionTile(
            leading: const CircleAvatar(
              child: Icon(Icons.description_outlined),
            ),
            title: Text('${user['full_name']} - ${_mapDocType(doc['document_type'])}'),
            subtitle: Text('Subido el: ${doc['created_at'].toString().split('T')[0]}'),
            children: [
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    _buildImagePreview(
                      'Vista del Documento',
                      doc['document_url'],
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _showRejectDialog(doc['id']),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Rechazar'),
                        ),
                        SizedBox(width: 3.w),
                        ElevatedButton(
                          onPressed: () => _updateStatus(doc['id'], 'approved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Aprobar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _mapDocType(String type) {
    switch (type) {
      case 'driver_license': return 'Licencia de Conducir';
      case 'passport': return 'Pasaporte';
      default: return 'Identificación';
    }
  }

  Widget _buildImagePreview(String label, String? url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 1.h),
        if (url != null)
          GestureDetector(
            onTap: () => _showLightbox(url),
            child: Container(
              height: 25.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(url),
                  fit: BoxFit.contain,
                ),
                color: Colors.black12,
              ),
            ),
          )
        else
          Container(
            height: 15.h,
            color: Colors.grey[300],
            child: const Center(child: Text('Sin imagen')),
          ),
      ],
    );
  }

  void _showLightbox(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(url),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(String docId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Documento'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Motivo del rechazo'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              _updateStatus(docId, 'rejected', reason: controller.text);
              Navigator.pop(context);
            },
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }
}

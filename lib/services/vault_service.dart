import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class VaultService {
  static VaultService? _instance;
  static VaultService get instance => _instance ??= VaultService._();

  VaultService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  /// Fetch user documents
  Future<List<Map<String, dynamic>>> getUserDocuments() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('user_documents')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Upload a document (Logic for storage would involve supabase.storage)
  Future<void> uploadDocument({
    required String type,
    required String url,
    DateTime? expiryDate,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('user_documents').insert({
        'user_id': userId,
        'document_type': type,
        'document_url': url,
        'expiry_date': expiryDate?.toIso8601String().split('T')[0],
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Error al subir documento: $e');
    }
  }

  /// Admin: Get pending documents for review
  Future<List<Map<String, dynamic>>> getPendingDocuments() async {
    try {
      final response = await _client
          .from('user_documents')
          .select('''
            *,
            user_profiles (full_name, email)
          ''')
          .eq('status', 'pending')
          .order('created_at', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Admin: Update document status
  Future<void> updateDocumentStatus({
    required String documentId,
    required String status,
    String? rejectionReason,
  }) async {
    try {
      await _client.from('user_documents').update({
        'status': status,
        'rejection_reason': rejectionReason,
        'verified_at': DateTime.now().toIso8601String(),
        'verified_by': _client.auth.currentUser?.id,
      }).eq('id', documentId);
    } catch (e) {
      throw Exception('Error al actualizar estado: $e');
    }
  }
}

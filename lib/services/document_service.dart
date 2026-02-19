import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class DocumentService {
  static DocumentService? _instance;
  static DocumentService get instance => _instance ??= DocumentService._();

  DocumentService._();

  final SupabaseClient _supabase = SupabaseService.instance.client;

  // Fetch digital contract for a specific rental
  Future<Map<String, dynamic>?> getContract(String rentalId) async {
    try {
      final response = await _supabase
          .from('contracts')
          .select('*, rentals(*, vehicles(*), profiles(*))')
          .eq('rental_id', rentalId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  // Sign a digital contract
  Future<bool> signContract(String contractId, String signatureUrl) async {
    try {
      await _supabase.from('contracts').update({
        'status': 'signed',
        'signed_at': DateTime.now().toIso8601String(),
        'signature_url': signatureUrl,
      }).eq('id', contractId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get insurance policy for a rental
  Future<Map<String, dynamic>?> getInsurancePolicy(String rentalId) async {
    try {
       // Mocking insurance data for now
       return {
         'policy_number': 'MAX-2026-0001',
         'provider': 'GMX Seguros',
         'coverage': 'Cobertura Amplia',
         'valid_until': '2026-12-31',
         'document_url': 'https://example.com/policy.pdf',
       };
    } catch (e) {
      return null;
    }
  }
}

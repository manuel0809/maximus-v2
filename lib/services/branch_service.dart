import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class BranchService {
  static BranchService? _instance;
  static BranchService get instance => _instance ??= BranchService._();

  BranchService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  /// Get all active branches
  Future<List<Map<String, dynamic>>> getBranches() async {
    try {
      final response = await _client.from('branches').select().order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Create a new branch
  Future<void> createBranch(Map<String, dynamic> data) async {
    await _client.from('branches').insert(data);
  }

  /// Update branch details
  Future<void> updateBranch(String id, Map<String, dynamic> data) async {
    await _client.from('branches').update(data).eq('id', id);
  }

  /// Delete a branch
  Future<void> deleteBranch(String id) async {
    await _client.from('branches').delete().eq('id', id);
  }

  /// Move a vehicle to a different branch
  Future<void> transferVehicle(String vehicleId, String targetBranchId) async {
    await _client.from('vehicles').update({
      'branch_id': targetBranchId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', vehicleId);
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();

  StorageService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  /// Upload a file to a specific bucket
  /// Returns the public URL of the uploaded file
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required dynamic file, // Can be File (io) or Uint8List (web/io)
  }) async {
    try {
      if (kIsWeb) {
        if (file is! Uint8List) {
          throw Exception('Web uploads require Uint8List');
        }
        await _client.storage.from(bucket).uploadBinary(path, file);
      } else {
        // We use dynamic to avoid direct File reference here which breaks web compilation
        // even if not running on web, some compilers are strict.
        await _client.storage.from(bucket).upload(path, file);
      }

      final String publicUrl = _client.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw Exception('Error al subir archivo: $e');
    }
  }

  /// Delete a file from a bucket
  Future<void> deleteFile(String bucket, String path) async {
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (e) {
      throw Exception('Error al eliminar archivo: $e');
    }
  }
}

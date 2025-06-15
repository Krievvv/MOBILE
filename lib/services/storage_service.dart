import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  static final _supabase = Supabase.instance.client;

  static Future<String?> uploadAvatar(XFile imageFile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('User not authenticated');
        throw Exception('User tidak terautentikasi');
      }

      print('Starting avatar upload for user: $userId');

      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      print('File name: $fileName');

      Uint8List imageBytes;
      if (kIsWeb) {
        imageBytes = await imageFile.readAsBytes();
      } else {
        imageBytes = await File(imageFile.path).readAsBytes();
      }

      print('Image bytes length: ${imageBytes.length}');

      // Upload to storage
      final uploadResponse = await _supabase.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      print('Upload response: $uploadResponse');

      // Get public URL
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);

      print('Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading avatar: $e');
      // Return a more specific error message
      if (e.toString().contains('not found')) {
        throw Exception('Storage bucket tidak ditemukan. Pastikan bucket "avatars" sudah dibuat.');
      } else if (e.toString().contains('permission')) {
        throw Exception('Tidak memiliki izin untuk upload. Periksa RLS policy.');
      } else {
        throw Exception('Gagal mengupload foto profil: ${e.toString()}');
      }
    }
  }

  static Future<String?> uploadBookCover(XFile imageFile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User tidak terautentikasi');

      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      Uint8List imageBytes;
      if (kIsWeb) {
        imageBytes = await imageFile.readAsBytes();
      } else {
        imageBytes = await File(imageFile.path).readAsBytes();
      }

      await _supabase.storage.from('book-covers').uploadBinary(
        fileName,
        imageBytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );

      final publicUrl = _supabase.storage.from('book-covers').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('Error uploading book cover: $e');
      throw Exception('Gagal mengupload cover buku: ${e.toString()}');
    }
  }

  static Future<bool> deleteFile(String bucket, String path) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // Test storage connection
  static Future<bool> testStorageConnection() async {
    try {
      final buckets = await _supabase.storage.listBuckets();
      print('Available buckets: ${buckets.map((b) => b.name).toList()}');
      return buckets.any((bucket) => bucket.name == 'avatars');
    } catch (e) {
      print('Error testing storage connection: $e');
      return false;
    }
  }
}

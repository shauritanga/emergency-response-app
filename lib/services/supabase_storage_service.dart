// File: lib/services/supabase_storage_service.dart
import 'dart:io';
import 'package:emergency_response_app/config/supabase_config.dart';
import 'package:emergency_response_app/services/supabase_auth_bridge.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class SupabaseStorageService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const _uuid = Uuid();

  /// Upload an image file to Supabase storage
  static Future<String?> uploadImage({
    required File file,
    String? customPath,
    String bucket = SupabaseConfig.imagesBucket,
  }) async {
    try {
      // Ensure authentication before upload
      await SupabaseAuthBridge.ensureAuthenticated();
      // Validate file size
      final fileSize = await file.length();
      if (fileSize > SupabaseConfig.maxImageSize) {
        throw Exception(
          'Image size exceeds ${SupabaseConfig.maxImageSize / (1024 * 1024)}MB limit',
        );
      }

      // Validate file extension
      final extension = path.extension(file.path).toLowerCase().substring(1);
      if (!SupabaseConfig.allowedImageExtensions.contains(extension)) {
        throw Exception(
          'Invalid image format. Allowed: ${SupabaseConfig.allowedImageExtensions.join(', ')}',
        );
      }

      // Generate unique filename
      final fileName = customPath ?? '${_uuid.v4()}.$extension';
      final filePath = 'images/$fileName';

      // Upload file
      await _supabase.storage.from(bucket).upload(filePath, file);

      // Get public URL
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(filePath);

      debugPrint('Image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Upload image from bytes (useful for web)
  static Future<String?> uploadImageFromBytes({
    required Uint8List bytes,
    required String fileName,
    String bucket = SupabaseConfig.imagesBucket,
  }) async {
    try {
      // Ensure authentication before upload
      await SupabaseAuthBridge.ensureAuthenticated();
      // Validate file size
      if (bytes.length > SupabaseConfig.maxImageSize) {
        throw Exception(
          'Image size exceeds ${SupabaseConfig.maxImageSize / (1024 * 1024)}MB limit',
        );
      }

      // Generate unique filename
      final extension = path.extension(fileName).toLowerCase().substring(1);
      final uniqueFileName = '${_uuid.v4()}.$extension';
      final filePath = 'images/$uniqueFileName';

      // Upload bytes
      await _supabase.storage.from(bucket).uploadBinary(filePath, bytes);

      // Get public URL
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(filePath);

      debugPrint('Image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image from bytes: $e');
      return null;
    }
  }

  /// Upload a video file to Supabase storage
  static Future<String?> uploadVideo({
    required File file,
    String? customPath,
    String bucket = SupabaseConfig.videosBucket,
    Function(double)? onProgress,
  }) async {
    try {
      // Ensure authentication before upload
      await SupabaseAuthBridge.ensureAuthenticated();
      // Validate file size
      final fileSize = await file.length();
      if (fileSize > SupabaseConfig.maxVideoSize) {
        throw Exception(
          'Video size exceeds ${SupabaseConfig.maxVideoSize / (1024 * 1024)}MB limit',
        );
      }

      // Validate file extension
      final extension = path.extension(file.path).toLowerCase().substring(1);
      if (!SupabaseConfig.allowedVideoExtensions.contains(extension)) {
        throw Exception(
          'Invalid video format. Allowed: ${SupabaseConfig.allowedVideoExtensions.join(', ')}',
        );
      }

      // Generate unique filename
      final fileName = customPath ?? '${_uuid.v4()}.$extension';
      final filePath = 'videos/$fileName';

      // Upload file with progress tracking
      await _supabase.storage
          .from(bucket)
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get public URL
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(filePath);

      debugPrint('Video uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading video: $e');
      return null;
    }
  }

  /// Delete a file from Supabase storage
  static Future<bool> deleteFile({
    required String filePath,
    String bucket = SupabaseConfig.imagesBucket,
  }) async {
    try {
      await _supabase.storage.from(bucket).remove([filePath]);

      debugPrint('File deleted successfully: $filePath');
      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  /// Get signed URL for private files
  static Future<String?> getSignedUrl({
    required String filePath,
    String bucket = SupabaseConfig.imagesBucket,
    int expiresIn = 3600, // 1 hour
  }) async {
    try {
      final signedUrl = await _supabase.storage
          .from(bucket)
          .createSignedUrl(filePath, expiresIn);

      return signedUrl;
    } catch (e) {
      debugPrint('Error creating signed URL: $e');
      return null;
    }
  }

  /// List files in a bucket
  static Future<List<FileObject>> listFiles({
    String bucket = SupabaseConfig.imagesBucket,
    String? path,
    int limit = 100,
  }) async {
    try {
      final files = await _supabase.storage
          .from(bucket)
          .list(
            path: path,
            searchOptions: SearchOptions(
              limit: limit,
              sortBy: SortBy(column: 'created_at', order: 'desc'),
            ),
          );

      return files;
    } catch (e) {
      debugPrint('Error listing files: $e');
      return [];
    }
  }

  /// Get file info
  static Future<FileObject?> getFileInfo({
    required String filePath,
    String bucket = SupabaseConfig.imagesBucket,
  }) async {
    try {
      final files = await _supabase.storage
          .from(bucket)
          .list(path: path.dirname(filePath));

      final fileName = path.basename(filePath);
      return files.firstWhere(
        (file) => file.name == fileName,
        orElse: () => throw Exception('File not found'),
      );
    } catch (e) {
      debugPrint('Error getting file info: $e');
      return null;
    }
  }

  /// Create storage buckets if they don't exist
  static Future<void> initializeBuckets() async {
    try {
      final buckets = [
        SupabaseConfig.imagesBucket,
        SupabaseConfig.videosBucket,
        SupabaseConfig.documentsBucket,
      ];

      for (final bucketName in buckets) {
        try {
          // First, try to list files in the bucket to check if it exists
          await _supabase.storage
              .from(bucketName)
              .list(searchOptions: const SearchOptions(limit: 1));
          debugPrint('Bucket $bucketName already exists and is accessible');
        } catch (e) {
          // If listing fails, try to create the bucket
          try {
            await _supabase.storage.createBucket(
              bucketName,
              BucketOptions(
                public: true,
                allowedMimeTypes:
                    bucketName == SupabaseConfig.imagesBucket
                        ? ['image/*']
                        : bucketName == SupabaseConfig.videosBucket
                        ? ['video/*']
                        : null,
                // Remove file size limit from bucket creation as it may cause issues
                // File size validation is handled in upload methods
              ),
            );
            debugPrint('Created bucket: $bucketName');
          } catch (createError) {
            // Bucket might already exist or we don't have permission to create it
            debugPrint('Bucket $bucketName might already exist: $createError');

            // Try to access the bucket to verify it exists
            try {
              await _supabase.storage
                  .from(bucketName)
                  .list(searchOptions: const SearchOptions(limit: 1));
              debugPrint('Bucket $bucketName exists and is accessible');
            } catch (accessError) {
              debugPrint('Cannot access bucket $bucketName: $accessError');
              debugPrint(
                'Please ensure the bucket exists in your Supabase dashboard and has proper RLS policies',
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error initializing buckets: $e');
    }
  }
}

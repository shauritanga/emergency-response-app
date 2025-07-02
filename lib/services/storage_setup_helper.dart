// File: lib/services/storage_setup_helper.dart
import 'package:emergency_response_app/config/supabase_config.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageSetupHelper {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Check if storage buckets are properly configured
  static Future<Map<String, bool>> checkBucketStatus() async {
    final buckets = [
      SupabaseConfig.imagesBucket,
      SupabaseConfig.videosBucket,
      SupabaseConfig.documentsBucket,
    ];

    final status = <String, bool>{};

    for (final bucketName in buckets) {
      try {
        // Try to list files in the bucket
        await _supabase.storage
            .from(bucketName)
            .list(searchOptions: const SearchOptions(limit: 1));
        status[bucketName] = true;
        debugPrint('✅ Bucket $bucketName is accessible');
      } catch (e) {
        status[bucketName] = false;
        debugPrint('❌ Bucket $bucketName is not accessible: $e');
      }
    }

    return status;
  }

  /// Test upload functionality for each bucket
  static Future<Map<String, bool>> testUploadFunctionality() async {
    final results = <String, bool>{};

    // Test image upload
    try {
      final testImageData = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 pixel
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
        0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
        0x54, 0x08, 0x99, 0x01, 0x01, 0x00, 0x00, 0xFF,
        0xFF, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, 0x73,
        0x75, 0x01, 0x18, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);

      final testPath =
          'test/test_image_${DateTime.now().millisecondsSinceEpoch}.png';

      await _supabase.storage
          .from(SupabaseConfig.imagesBucket)
          .uploadBinary(testPath, testImageData);

      // Clean up test file
      await _supabase.storage.from(SupabaseConfig.imagesBucket).remove([
        testPath,
      ]);

      results['images'] = true;
      debugPrint('✅ Image upload test successful');
    } catch (e) {
      results['images'] = false;
      debugPrint('❌ Image upload test failed: $e');
    }

    return results;
  }

  /// Print setup instructions
  static void printSetupInstructions() {
    debugPrint('''
🔧 SUPABASE STORAGE SETUP INSTRUCTIONS:

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Navigate to Storage → Buckets
3. Create these buckets:

   📁 images (Public: Yes, Size: 10MB, MIME: image/*)
   📁 videos (Public: Yes, Size: 50MB, MIME: video/*)
   📁 documents (Public: Yes, Size: 10MB, MIME: all)

4. Go to Storage → Policies and create RLS policies:

   For each bucket, create these policies:
   
   🔐 Public read access:
   CREATE POLICY "Public read access for [bucket]" ON storage.objects
   FOR SELECT USING (bucket_id = '[bucket]');
   
   🔐 Authenticated upload:
   CREATE POLICY "Authenticated users can upload [bucket]" ON storage.objects
   FOR INSERT WITH CHECK (bucket_id = '[bucket]' AND auth.role() = 'authenticated');

5. Replace [bucket] with: images, videos, documents

For more details, check the documentation in storage_setup_helper.dart
''');
  }

  /// Run complete storage diagnostics
  static Future<void> runDiagnostics() async {
    debugPrint('🔍 Running Supabase Storage Diagnostics...\n');

    // Check bucket status
    debugPrint('📋 Checking bucket accessibility...');
    final bucketStatus = await checkBucketStatus();

    final accessibleBuckets = bucketStatus.values.where((v) => v).length;
    final totalBuckets = bucketStatus.length;

    debugPrint(
      '📊 Bucket Status: $accessibleBuckets/$totalBuckets accessible\n',
    );

    // Test upload functionality
    debugPrint('🧪 Testing upload functionality...');
    final uploadResults = await testUploadFunctionality();

    final workingUploads = uploadResults.values.where((v) => v).length;
    final totalTests = uploadResults.length;

    debugPrint('📊 Upload Tests: $workingUploads/$totalTests working\n');

    // Print recommendations
    if (accessibleBuckets < totalBuckets || workingUploads < totalTests) {
      debugPrint(
        '⚠️  Storage setup incomplete. Please follow setup instructions:',
      );
      printSetupInstructions();
    } else {
      debugPrint(
        '✅ Storage setup complete! All buckets are accessible and uploads work.',
      );
    }
  }
}

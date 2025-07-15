import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emergency_response_app/services/supabase_storage_service.dart';

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Show image picker with better error handling
  static Future<File?> pickImageSafely(BuildContext context) async {
    try {
      return await pickImage(context);
    } on PlatformException catch (e) {
      debugPrint('Platform exception in image picker: $e');
      if (context.mounted) {
        _showErrorSnackBar(
          context,
          'Camera/Gallery access denied. Please check permissions.',
        );
      }
      return null;
    } catch (e) {
      debugPrint('Unexpected error in image picker: $e');
      if (context.mounted) {
        _showErrorSnackBar(context, 'Failed to pick image. Please try again.');
      }
      return null;
    }
  }

  /// Show error message to user
  static void _showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Show image source selection dialog
  /// Fixed: Prevents "Looking up a deactivated widget's ancestor" error
  /// by properly handling dialog context and checking widget mount state
  static Future<File?> pickImage(BuildContext context) async {
    final String? source = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(dialogContext).pop('camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(dialogContext).pop('gallery'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    // Handle the selected source
    if (source == null) return null;

    switch (source) {
      case 'camera':
        return await _pickImageFromCamera();
      case 'gallery':
        return await _pickImageFromGallery();
      default:
        return null;
    }
  }

  /// Pick image from camera with enhanced error handling
  static Future<File?> _pickImageFromCamera() async {
    try {
      debugPrint('📸 Starting camera image capture...');

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null && image.path.isNotEmpty) {
        debugPrint('📸 Camera captured image at: ${image.path}');

        final file = File(image.path);

        // Verify file exists and has content
        if (await file.exists()) {
          final fileSize = await file.length();
          debugPrint('📸 Image file size: $fileSize bytes');

          if (fileSize > 0) {
            debugPrint('✅ Camera image successfully captured and verified');
            return file;
          } else {
            debugPrint('❌ Camera image file is empty');
          }
        } else {
          debugPrint(
            '❌ Camera image file does not exist at path: ${image.path}',
          );
        }
      } else {
        debugPrint('❌ Camera capture returned null or empty path');
      }

      return null;
    } on PlatformException catch (e) {
      debugPrint('❌ Platform exception in camera: ${e.code} - ${e.message}');
      if (e.code == 'camera_access_denied') {
        debugPrint('❌ Camera permission denied');
      }
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected error in camera: $e');
      return null;
    }
  }

  /// Pick image from gallery
  static Future<File?> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null && image.path.isNotEmpty) {
        final file = File(image.path);
        // Verify file exists before returning
        if (await file.exists()) {
          return file;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick multiple images from gallery
  static Future<List<File>> pickMultipleImages({int maxImages = 5}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      // Limit the number of images and verify they exist
      final List<File> validFiles = [];
      final limitedImages = images.take(maxImages).toList();

      for (final xFile in limitedImages) {
        if (xFile.path.isNotEmpty) {
          final file = File(xFile.path);
          if (await file.exists()) {
            validFiles.add(file);
          }
        }
      }

      return validFiles;
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      return [];
    }
  }

  /// Upload image to Supabase and return URL
  static Future<String?> uploadImageToSupabase(
    File imageFile, {
    String? customPath,
  }) async {
    try {
      final imageUrl = await SupabaseStorageService.uploadImage(
        file: imageFile,
        customPath: customPath,
      );
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image to Supabase: $e');
      return null;
    }
  }

  /// Upload multiple images to Supabase
  static Future<List<String>> uploadMultipleImagesToSupabase(
    List<File> imageFiles, {
    Function(int current, int total)? onProgress,
  }) async {
    final List<String> uploadedUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      onProgress?.call(i + 1, imageFiles.length);

      final imageUrl = await uploadImageToSupabase(imageFiles[i]);
      if (imageUrl != null) {
        uploadedUrls.add(imageUrl);
      }
    }

    return uploadedUrls;
  }

  /// Validate image file
  static bool isValidImageFile(File file) {
    final String extension = file.path.split('.').last.toLowerCase();
    const List<String> allowedExtensions = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
    ];
    return allowedExtensions.contains(extension);
  }

  /// Get image file size in MB
  static Future<double> getImageSizeInMB(File file) async {
    final int bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  /// Compress image if needed (basic implementation)
  static Future<File?> compressImageIfNeeded(
    File file, {
    double maxSizeMB = 10.0,
  }) async {
    try {
      final double currentSizeMB = await getImageSizeInMB(file);

      if (currentSizeMB <= maxSizeMB) {
        return file; // No compression needed
      }

      // For now, we'll just return the original file
      // In a production app, you might want to use a package like flutter_image_compress
      debugPrint(
        'Image size (${currentSizeMB.toStringAsFixed(2)}MB) exceeds limit (${maxSizeMB}MB)',
      );
      return file;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return file;
    }
  }
}

/// Image upload progress model
class ImageUploadProgress {
  final int current;
  final int total;
  final String? currentFileName;
  final bool isComplete;

  ImageUploadProgress({
    required this.current,
    required this.total,
    this.currentFileName,
    this.isComplete = false,
  });

  double get progress => total > 0 ? current / total : 0.0;

  String get progressText => '$current/$total';

  int get progressPercentage => (progress * 100).round();
}

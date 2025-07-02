import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emergency_response_app/services/supabase_storage_service.dart';

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Show image source selection dialog
  static Future<File?> pickImage(BuildContext context) async {
    return await showDialog<File?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final file = await _pickImageFromCamera();
                  Navigator.of(context).pop(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final file = await _pickImageFromGallery();
                  Navigator.of(context).pop(file);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  /// Pick image from camera
  static Future<File?> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
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

      if (image != null) {
        return File(image.path);
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

      // Limit the number of images
      final limitedImages = images.take(maxImages).toList();
      
      return limitedImages.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      return [];
    }
  }

  /// Upload image to Supabase and return URL
  static Future<String?> uploadImageToSupabase(File imageFile, {String? customPath}) async {
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
    const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    return allowedExtensions.contains(extension);
  }

  /// Get image file size in MB
  static Future<double> getImageSizeInMB(File file) async {
    final int bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  /// Compress image if needed (basic implementation)
  static Future<File?> compressImageIfNeeded(File file, {double maxSizeMB = 10.0}) async {
    try {
      final double currentSizeMB = await getImageSizeInMB(file);
      
      if (currentSizeMB <= maxSizeMB) {
        return file; // No compression needed
      }
      
      // For now, we'll just return the original file
      // In a production app, you might want to use a package like flutter_image_compress
      debugPrint('Image size (${currentSizeMB.toStringAsFixed(2)}MB) exceeds limit (${maxSizeMB}MB)');
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

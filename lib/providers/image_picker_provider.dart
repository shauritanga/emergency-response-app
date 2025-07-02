import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emergency_response_app/services/image_picker_service.dart';

/// Provider for image picker service
final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return ImagePickerService();
});

/// State notifier for managing selected images
class SelectedImagesNotifier extends StateNotifier<List<File>> {
  SelectedImagesNotifier() : super([]);

  /// Add an image to the selection
  void addImage(File image) {
    if (state.length < 5) { // Limit to 5 images
      state = [...state, image];
    }
  }

  /// Remove an image from the selection
  void removeImage(int index) {
    if (index >= 0 && index < state.length) {
      final newList = List<File>.from(state);
      newList.removeAt(index);
      state = newList;
    }
  }

  /// Clear all selected images
  void clearImages() {
    state = [];
  }

  /// Replace all images
  void setImages(List<File> images) {
    state = images.take(5).toList(); // Limit to 5 images
  }
}

/// Provider for selected images state
final selectedImagesProvider = StateNotifierProvider<SelectedImagesNotifier, List<File>>((ref) {
  return SelectedImagesNotifier();
});

/// State notifier for managing image upload progress
class ImageUploadProgressNotifier extends StateNotifier<ImageUploadProgress?> {
  ImageUploadProgressNotifier() : super(null);

  /// Start upload progress
  void startUpload(int totalImages) {
    state = ImageUploadProgress(
      current: 0,
      total: totalImages,
      isComplete: false,
    );
  }

  /// Update upload progress
  void updateProgress(int current, int total, {String? currentFileName}) {
    state = ImageUploadProgress(
      current: current,
      total: total,
      currentFileName: currentFileName,
      isComplete: current >= total,
    );
  }

  /// Complete upload
  void completeUpload() {
    if (state != null) {
      state = ImageUploadProgress(
        current: state!.total,
        total: state!.total,
        isComplete: true,
      );
    }
  }

  /// Reset progress
  void resetProgress() {
    state = null;
  }
}

/// Provider for image upload progress
final imageUploadProgressProvider = StateNotifierProvider<ImageUploadProgressNotifier, ImageUploadProgress?>((ref) {
  return ImageUploadProgressNotifier();
});

/// Async provider for uploading images to Supabase
final uploadImagesProvider = FutureProvider.family<List<String>, List<File>>((ref, images) async {
  final progressNotifier = ref.read(imageUploadProgressProvider.notifier);
  
  progressNotifier.startUpload(images.length);
  
  final uploadedUrls = await ImagePickerService.uploadMultipleImagesToSupabase(
    images,
    onProgress: (current, total) {
      progressNotifier.updateProgress(current, total);
    },
  );
  
  progressNotifier.completeUpload();
  
  return uploadedUrls;
});

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

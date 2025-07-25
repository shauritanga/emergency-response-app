import 'dart:io';

import 'package:emergency_response_app/providers/emergency_provider.dart';
import 'package:emergency_response_app/providers/location_provider.dart';
import 'package:emergency_response_app/providers/image_picker_provider.dart';
import 'package:emergency_response_app/services/image_picker_service.dart';
import 'package:emergency_response_app/screens/citizen/setting_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:uuid/uuid.dart';
import '../../models/emergency.dart';
import '../../widgets/emergency_button.dart';
import '../../providers/auth_provider.dart';

class EmergencyReportScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;

  const EmergencyReportScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<EmergencyReportScreen> createState() =>
      _EmergencyReportScreenState();
}

class _EmergencyReportScreenState extends ConsumerState<EmergencyReportScreen>
    with SingleTickerProviderStateMixin {
  final _descriptionController = TextEditingController();
  String? _selectedType;
  String? _error;
  bool _isSubmitting = false;
  late AnimationController _animationController;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _animationController.dispose();
    // Clear selected images when leaving the screen
    ref.read(selectedImagesProvider.notifier).clearImages();
    super.dispose();
  }

  Future<void> _reportEmergency() async {
    final selectedImages = ref.read(selectedImagesProvider);

    if (_selectedType == null) {
      setState(() {
        _error = 'Please select emergency type';
      });
      return;
    }

    if (selectedImages.isEmpty) {
      setState(() {
        _error = 'Please add at least one image';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      // Use high accuracy location for emergency reporting
      debugPrint('🎯 Getting high accuracy location for emergency report...');
      final location = await ref
          .read(locationServiceProvider)
          .getHighAccuracyLocation(
            onStatusUpdate: (status) {
              debugPrint('📍 Location status: $status');
              // You could show this status to user if needed
            },
          );

      if (location == null) {
        setState(() {
          _error =
              'Could not get accurate location. Please ensure GPS is enabled and try again.';
          _isSubmitting = false;
        });
        return;
      }

      debugPrint(
        '✅ Got emergency location: ${location.latitude}, ${location.longitude} '
        '(±${location.accuracy?.toStringAsFixed(1) ?? 'unknown'}m accuracy)',
      );

      // Upload images to Supabase if any are selected
      final selectedImages = ref.read(selectedImagesProvider);
      List<String> imageUrls = [];

      if (selectedImages.isNotEmpty) {
        final uploadProgressNotifier = ref.read(
          imageUploadProgressProvider.notifier,
        );
        uploadProgressNotifier.startUpload(selectedImages.length);

        imageUrls = await ImagePickerService.uploadMultipleImagesToSupabase(
          selectedImages,
          onProgress: (current, total) {
            uploadProgressNotifier.updateProgress(current, total);
          },
        );

        uploadProgressNotifier.completeUpload();
      }

      final emergency = Emergency(
        id: const Uuid().v4(),
        userId: ref.read(authStateProvider).value!.uid,
        type: _selectedType!,
        latitude: location.latitude!,
        longitude: location.longitude!,
        description: _descriptionController.text,
        status: 'Pending',
        timestamp: DateTime.now(),
        imageUrls: imageUrls,
      );

      await ref.read(emergencyServiceProvider).reportEmergency(emergency);

      // Trigger notifications for department responders and nearby citizens
      // Make this non-blocking so emergency is still created if notifications fail
      try {
        await ref.read(emergencyServiceProvider).notifyEmergency(emergency);
      } catch (notificationError) {
        debugPrint(
          'Notification failed but emergency was created: $notificationError',
        );
        // Continue execution - emergency was still created successfully
      }

      // Notifications are now handled automatically by the enhanced notification service
      // No need for manual topic subscription

      // Show success animation
      setState(() {
        _isSubmitting = false;
        _showSuccess = true;
      });

      _animationController.forward();

      // Reset form after delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _selectedType = null;
            _descriptionController.clear();
            _error = null;
            _showSuccess = false;
          });
          _animationController.reset();
        }
      });

      // Only pop if not embedded
      if (!widget.isEmbedded) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return widget.isEmbedded
        ? Scaffold(
          appBar: AppBar(
            title: Text(
              'Report Emergency',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
              ),
            ],
          ),
          body: _buildContent(isDarkMode),
        )
        : Scaffold(
          appBar: AppBar(
            title: Text(
              'Report Emergency',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          body: _buildContent(isDarkMode),
        );
  }

  Widget _buildContent(bool isDarkMode) {
    if (_showSuccess) {
      return _buildSuccessView(isDarkMode);
    }

    return Stack(
      children: [
        // Background design elements
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // Main content
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Need Help?',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select the type of emergency and provide details',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),

                // Emergency Type Selection
                Text(
                  'Emergency Type',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Emergency buttons in a card
                Card(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        EmergencyButton(
                          type: 'Medical',
                          icon: HugeIcons.strokeRoundedMedicalMask,
                          isSelected: _selectedType == 'Medical',
                          onPressed:
                              () => setState(() => _selectedType = 'Medical'),
                        ),
                        EmergencyButton(
                          type: 'Fire',
                          icon: HugeIcons.strokeRoundedFire,
                          isSelected: _selectedType == 'Fire',
                          onPressed:
                              () => setState(() => _selectedType = 'Fire'),
                        ),
                        EmergencyButton(
                          type: 'Police',
                          icon: HugeIcons.strokeRoundedPoliceBadge,
                          isSelected: _selectedType == 'Police',
                          onPressed:
                              () => setState(() => _selectedType = 'Police'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Description Field
                Text(
                  'Emergency Details',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Describe what happened (Optional)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            hintText:
                                'Provide additional details (optional)...',
                            hintStyle: GoogleFonts.poppins(
                              color:
                                  isDarkMode ? Colors.white38 : Colors.black38,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color:
                                    isDarkMode
                                        ? Colors.white24
                                        : Colors.black12,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color:
                                    isDarkMode
                                        ? Colors.white24
                                        : Colors.black12,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor:
                                isDarkMode
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.02),
                          ),
                          style: GoogleFonts.poppins(),
                          maxLines: 5,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Image Selection Section
                Text(
                  'Add Photos (Required)',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                Card(
                  elevation: 4,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _buildImageSection(isDarkMode),
                  ),
                ),

                // Error message
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: GoogleFonts.poppins(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _reportEmergency,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: Colors.deepPurple.withOpacity(0.4),
                    ),
                    child:
                        _isSubmitting
                            ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'SUBMIT EMERGENCY',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),

                const SizedBox(height: 16),

                // Help text
                Center(
                  child: Text(
                    'Your location will be shared with emergency services',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection(bool isDarkMode) {
    final selectedImages = ref.watch(selectedImagesProvider);
    final uploadProgress = ref.watch(imageUploadProgressProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add photos to help responders understand the situation better',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 16),

        // Image selection buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : () => _pickSingleImage(),
                icon: const Icon(HugeIcons.strokeRoundedCamera01),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : () => _pickMultipleImages(),
                icon: const Icon(HugeIcons.strokeRoundedImage01),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Upload progress
        if (uploadProgress != null && !uploadProgress.isComplete)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: uploadProgress.progress,
                  backgroundColor: Colors.grey.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Uploading images... ${uploadProgress.progressText}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),

        // Selected images preview
        if (selectedImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.photo_library, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Selected Images (${selectedImages.length}/5)',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap:
                                    () => _showImagePreview(
                                      selectedImages[index],
                                    ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      selectedImages[index],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          width: 100,
                                          height: 100,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.error,
                                            color: Colors.red,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                              // Image index indicator
                              Positioned(
                                bottom: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _pickSingleImage() async {
    debugPrint('🔄 Starting image capture process...');

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening camera...'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    final image = await ImagePickerService.pickImageSafely(context);

    if (image != null) {
      debugPrint('✅ Image captured successfully, adding to selection');
      ref.read(selectedImagesProvider.notifier).addImage(image);

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 Photo captured successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      debugPrint('❌ Image capture failed or was cancelled');

      // Show failure feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to capture photo. Please try again.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _pickMultipleImages() async {
    final images = await ImagePickerService.pickMultipleImages(maxImages: 5);
    if (images.isNotEmpty) {
      ref.read(selectedImagesProvider.notifier).setImages(images);
    }
  }

  void _removeImage(int index) {
    ref.read(selectedImagesProvider.notifier).removeImage(index);
  }

  void _showImagePreview(File imageFile) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 48),
                              SizedBox(height: 16),
                              Text('Failed to load image'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSuccessView(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success animation
          Lottie.network(
            'https://assets10.lottiefiles.com/packages/lf20_s9lvjg9v.json',
            width: 200,
            height: 200,
            controller: _animationController,
          ),
          const SizedBox(height: 24),
          Text(
            'Emergency Reported',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Help is on the way. Stay calm and wait for emergency services to contact you.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          if (_selectedType != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _getTypeColor(_selectedType!).withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _getTypeColor(_selectedType!).withOpacity(0.3),
                ),
              ),
              child: Text(
                '${_selectedType!} Emergency',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getTypeColor(_selectedType!),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Medical':
        return Colors.deepPurple;
      case 'Fire':
        return Colors.purple;
      case 'Police':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}

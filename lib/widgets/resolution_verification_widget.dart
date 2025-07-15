import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/emergency.dart';
import '../models/emergency_status.dart';
import '../services/enhanced_emergency_service.dart';

class ResolutionVerificationWidget extends ConsumerStatefulWidget {
  final Emergency emergency;
  final VoidCallback? onVerificationComplete;

  const ResolutionVerificationWidget({
    super.key,
    required this.emergency,
    this.onVerificationComplete,
  });

  @override
  ConsumerState<ResolutionVerificationWidget> createState() =>
      _ResolutionVerificationWidgetState();
}

class _ResolutionVerificationWidgetState
    extends ConsumerState<ResolutionVerificationWidget> {
  final _notesController = TextEditingController();
  final _reasonController = TextEditingController();
  final List<File> _evidenceFiles = [];
  bool _isLoading = false;
  bool? _isConfirmed;

  @override
  void dispose() {
    _notesController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user, color: Colors.orange, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Resolution Verification Required',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'This emergency has been marked as resolved by a responder. '
              'Please verify if the issue has been properly addressed.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Verification options
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _setVerification(true),
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text('Confirm Resolved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isLoading ? null : () => _setVerification(false),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: const Text('Dispute Resolution'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            if (_isConfirmed != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Notes section
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText:
                      _isConfirmed!
                          ? 'Additional Comments (Optional)'
                          : 'Please explain why you dispute this resolution',
                  border: const OutlineInputBorder(),
                  hintText:
                      _isConfirmed!
                          ? 'Any additional feedback...'
                          : 'Describe what still needs to be addressed...',
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // Evidence section
              Row(
                children: [
                  Text(
                    'Evidence (Optional)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _isLoading ? null : _pickImage,
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Add Photo'),
                  ),
                ],
              ),

              if (_evidenceFiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _evidenceFiles.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _evidenceFiles[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
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
              ],

              const SizedBox(height: 16),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isConfirmed! ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            _isConfirmed!
                                ? 'Confirm Resolution'
                                : 'Submit Dispute',
                          ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _setVerification(bool confirmed) {
    setState(() {
      _isConfirmed = confirmed;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _evidenceFiles.add(File(pickedFile.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _evidenceFiles.removeAt(index);
    });
  }

  Future<void> _submitVerification() async {
    if (_isConfirmed == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final service = EnhancedEmergencyService();
      final success = await service.verifyResolution(
        emergencyId: widget.emergency.id,
        isConfirmed: _isConfirmed!,
        notes:
            _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
        evidenceFiles: _evidenceFiles.isEmpty ? null : _evidenceFiles,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isConfirmed!
                    ? 'Resolution confirmed successfully'
                    : 'Dispute submitted successfully',
              ),
              backgroundColor: _isConfirmed! ? Colors.green : Colors.orange,
            ),
          );
          widget.onVerificationComplete?.call();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit verification'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

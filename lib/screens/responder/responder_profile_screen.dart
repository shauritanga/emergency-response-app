import 'package:cached_network_image/cached_network_image.dart';
import 'package:emergency_response_app/screens/citizen/setting_screen.dart';
import 'package:emergency_response_app/screens/common/feedback_screen.dart';
import 'package:emergency_response_app/screens/common/help_support_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../providers/auth_provider.dart';
import '../../services/image_picker_service.dart';
import '../../utils/feedback_utils.dart';
import '../auth/login_screen.dart';

class ResponderProfileScreen extends ConsumerStatefulWidget {
  const ResponderProfileScreen({super.key});

  @override
  ConsumerState<ResponderProfileScreen> createState() =>
      _ResponderProfileScreenState();
}

class _ResponderProfileScreenState
    extends ConsumerState<ResponderProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _error;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    // Controllers will be initialized when data is loaded
  }

  void _toggleEditMode(data) {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _nameController.text = data.name;
        _phoneController.text = data.phone ?? '';
      }
    });
  }

  Future<void> _updateProfile() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'name': _nameController.text.trim(),
            'phone':
                _phoneController.text.trim().isEmpty
                    ? null
                    : _phoneController.text.trim(),
          });

      if (mounted) {
        FeedbackUtils.showSuccess(context, 'Profile updated successfully');
      }

      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error updating profile: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfilePicture() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Pick image
      final imageFile = await ImagePickerService.pickImage(context);
      if (imageFile == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Upload image to Supabase
      final imageUrl = await ImagePickerService.uploadImageToSupabase(
        imageFile,
      );
      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }

      // Update user profile with new photo URL
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'photoURL': imageUrl});

        // Invalidate the user data provider to refresh the UI
        ref.invalidate(userFutureProvider(user.uid));

        if (mounted) {
          FeedbackUtils.showSuccess(
            context,
            'Profile picture updated successfully',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(
          context,
          'Failed to update profile picture: $e',
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Color _getDepartmentColor(String? department) {
    switch (department) {
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

  IconData _getDepartmentIcon(String? department) {
    switch (department) {
      case 'Medical':
        return HugeIcons.strokeRoundedAmbulance;
      case 'Fire':
        return HugeIcons.strokeRoundedFire02;
      case 'Police':
        return HugeIcons.strokeRoundedPoliceCar;
      default:
        return HugeIcons.strokeRoundedBriefcase01;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Center(child: Text('Please log in'));
    }
    final userDataAsync = ref.watch(userFutureProvider(user.uid));

    return Scaffold(
      body: userDataAsync.when(
        data: (data) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header with gradient background
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getDepartmentColor(data!.department),
                        _getDepartmentColor(data.department).withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _getDepartmentColor(
                          data.department,
                        ).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _updateProfilePicture,
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundColor: Colors.white,
                                      child: CircleAvatar(
                                        radius: 38,
                                        backgroundImage:
                                            data.photoURL != null &&
                                                    data.photoURL!.isNotEmpty
                                                ? CachedNetworkImageProvider(
                                                  data.photoURL!,
                                                )
                                                : null,
                                        child:
                                            data.photoURL == null ||
                                                    data.photoURL!.isEmpty
                                                ? const Icon(
                                                  Icons.person,
                                                  size: 40,
                                                  color: Colors.grey,
                                                )
                                                : null,
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple,
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
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data.name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone_outlined,
                                        size: 16,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        data.phone ?? 'Not provided',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => _toggleEditMode(data),
                            icon: Icon(
                              _isEditing
                                  ? Icons.close_rounded
                                  : HugeIcons.strokeRoundedPencilEdit02,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getDepartmentIcon(data.department),
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${data.department ?? 'No'} Department',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Profile information section
                if (_isEditing)
                  _buildEditForm()
                else
                  _buildProfileInfo(data, isDarkMode),

                const SizedBox(height: 24),

                // Action buttons
                if (_isEditing) _buildUpdateButton() else _buildActionButtons(),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: GoogleFonts.poppins(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
        error:
            (error, stackTrace) => Center(
              child: Text(
                'Error loading profile: $error',
                style: GoogleFonts.poppins(),
              ),
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildProfileInfo(data, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Information',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        _buildInfoItem(
          icon: Icons.email_outlined,
          title: 'Email',
          value: data.email,
          isDarkMode: isDarkMode,
        ),
        const Divider(),
        _buildInfoItem(
          icon: Icons.phone_outlined,
          title: 'Phone',
          value: data.phone ?? 'Not provided',
          isDarkMode: isDarkMode,
        ),
        const Divider(),
        _buildInfoItem(
          icon: Icons.work_outline_rounded,
          title: 'Department',
          value: data.department ?? 'Not assigned',
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? Colors.grey.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit Profile',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: const Icon(Icons.phone_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _updateProfile,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      child: Text(
        'Save Changes',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
          icon: const Icon(Icons.notifications_outlined),
          label: Text('Notification Preferences', style: GoogleFonts.poppins()),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FeedbackScreen()),
            );
          },
          icon: const Icon(Icons.feedback_outlined),
          label: Text('Send Feedback', style: GoogleFonts.poppins()),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
            );
          },
          icon: const Icon(Icons.help_outline),
          label: Text('Help & Support', style: GoogleFonts.poppins()),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () async {
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
            );

            if (shouldLogout == true && mounted) {
              await ref.read(authServiceProvider).signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            }
          },
          icon: const Icon(Icons.logout_rounded),
          label: Text('Logout', style: GoogleFonts.poppins()),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

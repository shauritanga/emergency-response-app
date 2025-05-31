import 'package:cached_network_image/cached_network_image.dart';
import 'package:emergency_response_app/screens/citizen/setting_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class CitizenProfileScreen extends ConsumerStatefulWidget {
  const CitizenProfileScreen({super.key});

  @override
  ConsumerState<CitizenProfileScreen> createState() =>
      _CitizenProfileScreenState();
}

class _CitizenProfileScreenState extends ConsumerState<CitizenProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'name': _nameController.text.trim(),
              'phone': _phoneController.text.trim(),
            });
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Center(child: Text('Please log in'));
    }

    final userDataAsync = ref.watch(userFutureProvider(user.uid));

    return Scaffold(
      body: userDataAsync.when(
        data: (userData) {
          if (!_isEditing) {
            _nameController.text = userData?.name ?? '';
            _phoneController.text = userData?.phone ?? '';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Profile Header witconsth Avatar
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage:
                                userData?.photoURL != null
                                    ? CachedNetworkImageProvider(
                                      userData!.photoURL!,
                                    )
                                    : null,
                            child:
                                userData?.photoURL == null
                                    ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey,
                                    )
                                    : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userData?.name ?? 'User',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userData?.email ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Profile Information
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!_isEditing)
                              TextButton.icon(
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit'),
                                onPressed: () {
                                  setState(() {
                                    _isEditing = true;
                                  });
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (_isEditing) ...[
                          // Edit Mode
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                    // Reset controllers to original values
                                    _nameController.text = userData?.name ?? '';
                                    _phoneController.text =
                                        userData?.phone ?? '';
                                  });
                                },
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _updateProfile,
                                child:
                                    _isLoading
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text('Save'),
                              ),
                            ],
                          ),
                        ] else ...[
                          // View Mode
                          _buildInfoRow(
                            icon: Icons.person,
                            title: 'Name',
                            value: userData?.name ?? 'Not set',
                          ),
                          const Divider(),
                          _buildInfoRow(
                            icon: Icons.email,
                            title: 'Email',
                            value: userData?.email ?? 'Not set',
                          ),
                          const Divider(),
                          _buildInfoRow(
                            icon: Icons.phone,
                            title: 'Phone',
                            value: userData?.phone ?? 'Not set',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Settings and Logout
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Settings'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.feedback),
                        title: const Text('Send Feedback'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigate to feedback screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Feedback feature coming soon'),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.help),
                        title: const Text('Help & Support'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigate to help screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Help feature coming soon'),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () async {
                          await ref.read(authServiceProvider).signOut();
                          if (!mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // App Version
                Center(
                  child: Text(
                    'App Version 1.0.0',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}

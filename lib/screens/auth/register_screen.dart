import 'package:emergency_response_app/screens/citizen/citizen_home_screen.dart';
import 'package:emergency_response_app/screens/responder/responder_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _role = 'citizen';
  String? _department;
  String? _error;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_role == 'responder' && _department == null) {
      setState(() {
        _error = 'Please select a department';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await ref
          .read(authServiceProvider)
          .register(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            _role,
            department: _role == 'responder' ? _department : null,
          );
      if (user != null) {
        // Navigate to the appropriate home screen based on role
        if (!mounted) return;
        switch (_role) {
          case 'responder':
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ResponderHomeScreen()),
            );
            break;
          default:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CitizenHomeScreen()),
            );
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDarkMode
                    ? [
                      const Color(0xFF1A237E),
                      const Color(0xFF0D47A1),
                      const Color(0xFF01579B),
                    ]
                    : [
                      const Color(0xFFE3F2FD),
                      const Color(0xFFBBDEFB),
                      const Color(0xFF90CAF9),
                    ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create Account',
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : const Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sign up to get started',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color:
                                          isDarkMode
                                              ? Colors.white70
                                              : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                height: 60,
                                width: 60,
                                decoration: BoxDecoration(
                                  color:
                                      isDarkMode
                                          ? const Color(
                                            0xFF2979FF,
                                          ).withOpacity(0.1)
                                          : const Color(
                                            0xFF2979FF,
                                          ).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  HugeIcons.strokeRoundedUserAdd01,
                                  size: 30,
                                  color: const Color(0xFF2979FF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Name Field
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            icon: Icons.person_outline,
                            isDarkMode: isDarkMode,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Email Field
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'Enter your email address',
                            icon: Icons.email_outlined,
                            isDarkMode: isDarkMode,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Phone Field
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone (Optional)',
                            hint: 'Enter your phone number',
                            icon: Icons.phone_outlined,
                            isDarkMode: isDarkMode,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Create a password',
                            icon: Icons.lock_outline,
                            isDarkMode: isDarkMode,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Role Selection
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Role',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isDarkMode
                                          ? Colors.white70
                                          : Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color:
                                      isDarkMode
                                          ? Colors.white.withOpacity(0.08)
                                          : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        isDarkMode
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.grey.shade200,
                                  ),
                                ),
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                  ),
                                  dropdownColor:
                                      isDarkMode
                                          ? const Color(0xFF2C2C2C)
                                          : Colors.white,
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color:
                                        isDarkMode
                                            ? Colors.white54
                                            : Colors.grey.shade600,
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    color:
                                        isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                  ),
                                  isExpanded: true,
                                  value: _role,
                                  items:
                                      ['citizen', 'responder'].map((role) {
                                        return DropdownMenuItem(
                                          value: role,
                                          child: Text(
                                            role.substring(0, 1).toUpperCase() +
                                                role.substring(1),
                                            style: GoogleFonts.poppins(),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _role = value!;
                                      if (_role != 'responder')
                                        _department = null;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),

                          // Department Selection (for responders)
                          if (_role == 'responder') ...[
                            const SizedBox(height: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Department',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        isDarkMode
                                            ? Colors.white70
                                            : Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        isDarkMode
                                            ? Colors.white.withOpacity(0.08)
                                            : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color:
                                          isDarkMode
                                              ? Colors.white.withOpacity(0.1)
                                              : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                    ),
                                    dropdownColor:
                                        isDarkMode
                                            ? const Color(0xFF2C2C2C)
                                            : Colors.white,
                                    icon: Icon(
                                      Icons.arrow_drop_down,
                                      color:
                                          isDarkMode
                                              ? Colors.white54
                                              : Colors.grey.shade600,
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                    ),
                                    hint: Text(
                                      'Select your department',
                                      style: GoogleFonts.poppins(
                                        color:
                                            isDarkMode
                                                ? Colors.white38
                                                : Colors.grey.shade400,
                                      ),
                                    ),
                                    isExpanded: true,
                                    value: _department,
                                    items:
                                        ['Medical', 'Fire', 'Police'].map((
                                          dept,
                                        ) {
                                          IconData icon;
                                          switch (dept) {
                                            case 'Medical':
                                              icon =
                                                  HugeIcons
                                                      .strokeRoundedAmbulance;
                                              break;
                                            case 'Fire':
                                              icon =
                                                  HugeIcons.strokeRoundedFire02;
                                              break;
                                            case 'Police':
                                              icon =
                                                  HugeIcons
                                                      .strokeRoundedPoliceCar;
                                              break;
                                            default:
                                              icon = Icons.work_outline;
                                          }

                                          return DropdownMenuItem(
                                            value: dept,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  icon,
                                                  size: 18,
                                                  color: const Color(
                                                    0xFF2979FF,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  dept,
                                                  style: GoogleFonts.poppins(),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _department = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Error Message
                          if (_error != null)
                            Container(
                              margin: const EdgeInsets.only(top: 20),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                  ),
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

                          const SizedBox(height: 32),

                          // Register Button
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2979FF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Text(
                                        'Create Account',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Back to Login
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  isDarkMode
                                      ? Colors.white70
                                      : Colors.grey.shade700,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_back,
                                  size: 16,
                                  color:
                                      isDarkMode
                                          ? Colors.white70
                                          : Colors.grey.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Back to Login',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDarkMode,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: isDarkMode ? Colors.white38 : Colors.grey.shade400,
              fontSize: 15,
            ),
            prefixIcon: Icon(
              icon,
              color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
            ),
            suffixIcon:
                isPassword
                    ? IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color:
                            isDarkMode ? Colors.white54 : Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    )
                    : null,
            filled: true,
            fillColor:
                isDarkMode
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color:
                    isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.shade200,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: const Color(0xFF2979FF),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

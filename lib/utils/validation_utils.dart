/// Utility class for form validation
class ValidationUtils {
  /// Validates email format using a comprehensive regex pattern
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    // Comprehensive email validation regex
    // This pattern validates:
    // - Local part: alphanumeric, dots, hyphens, underscores
    // - Domain part: alphanumeric, dots, hyphens
    // - TLD: 2-4 characters
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      caseSensitive: false,
    );

    return emailRegex.hasMatch(email.trim());
  }

  /// Validates email and returns appropriate error message
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }

    final email = value.trim();

    if (!isValidEmail(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates password strength
  static String? validatePassword(
    String? value, {
    bool isRegistration = false,
  }) {
    if (value == null || value.isEmpty) {
      return isRegistration
          ? 'Please create a password'
          : 'Please enter your password';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    // For registration, enforce stronger password requirements
    if (isRegistration) {
      if (value.length < 8) {
        return 'Password must be at least 8 characters long';
      }

      // Check for at least one letter and one number
      if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
        return 'Password must contain at least one letter and one number';
      }
    }

    return null;
  }

  /// Validates full name
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }

    final name = value.trim();

    if (name.length < 2) {
      return 'Name must be at least 2 characters long';
    }

    // Check if name contains at least one letter
    if (!RegExp(r'[a-zA-Z]').hasMatch(name)) {
      return 'Please enter a valid name';
    }

    return null;
  }

  /// Validates phone number (optional field)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }

    final phone = value.trim();

    // Remove common phone number characters for validation
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    // Check if it contains only digits after cleaning
    if (!RegExp(r'^\d+$').hasMatch(cleanPhone)) {
      return 'Please enter a valid phone number';
    }

    // Check length (most phone numbers are 7-15 digits)
    if (cleanPhone.length < 7 || cleanPhone.length > 15) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Validates that a required dropdown selection is made
  static String? validateRequired(dynamic value, String fieldName) {
    if (value == null || (value is String && value.trim().isEmpty)) {
      return 'Please select $fieldName';
    }
    return null;
  }

  /// Sanitizes user input to prevent potential issues
  static String sanitizeInput(String input) {
    return input.trim();
  }

  /// Checks if a string contains only safe characters (no special characters that could cause issues)
  static bool isSafeInput(String input) {
    // Allow letters, numbers, spaces, and common punctuation
    final safePattern = RegExp(r'^[a-zA-Z0-9\s\.\,\-\_\@\+\(\)]+$');
    return safePattern.hasMatch(input);
  }
}

import 'package:skillresy/constants/app_strings.dart';

class Validators {
  Validators._();

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return AppStrings.invalidEmail;
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }

    // Strong password validation
    final strongPasswordResult = validateStrongPassword(value);
    if (strongPasswordResult != null) {
      return strongPasswordResult;
    }

    return null;
  }

  /// Validates strong password requirements
  static String? validateStrongPassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one digit';
    }

    if (!password.contains(RegExp(r'[!@#$%^&*(),.?\":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    // Check for common weak passwords
    final commonPasswords = [
      'password',
      '12345678',
      'qwerty123',
      'abc123456',
      'password123',
      '123456789',
    ];

    if (commonPasswords.contains(password.toLowerCase())) {
      return 'Password is too common. Please choose a stronger password';
    }

    return null;
  }

  /// Gets password strength level (0-4)
  static int getPasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int strength = 0;

    // Length check
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;

    // Character variety checks
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?\":{}|<>]'))) strength++;

    // Bonus for mixed case and numbers
    if (password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]'))) {
      strength++;
    }

    return strength.clamp(0, 4);
  }

  /// Gets password strength text
  static String getPasswordStrengthText(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Medium';
      case 4:
        return 'Strong';
      default:
        return 'Very Weak';
    }
  }

  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }

    if (value != password) {
      return AppStrings.passwordsDoNotMatch;
    }

    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    return null;
  }

  static String? validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }

    return null;
  }

  /// Validates LinkedIn URL
  static String? validateLinkedInUrl(String? value) {
    // LinkedIn URL is optional, so return null if empty
    if (value == null || value.isEmpty) {
      return null;
    }

    // Remove leading/trailing whitespace
    value = value.trim();

    // Check if it's a valid URL format
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&\/\/=]*)$',
      caseSensitive: false,
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    // Check if it's specifically a LinkedIn URL
    final linkedInRegex = RegExp(
      r'^https?:\/\/(www\.)?(linkedin\.com|linkedin\.[a-z]{2,3})\/(in|pub|company)\/[\w\-]+\/?$',
      caseSensitive: false,
    );

    if (!linkedInRegex.hasMatch(value)) {
      return 'Please enter a valid LinkedIn profile URL (e.g., https://www.linkedin.com/in/yourprofile)';
    }

    return null;
  }

  /// Validates personal website URL
  static String? validateWebsiteUrl(String? value) {
    // Website URL is optional, so return null if empty
    if (value == null || value.isEmpty) {
      return null;
    }

    // Remove leading/trailing whitespace
    value = value.trim();

    // Check if it's a valid URL format
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&\/\/=]*)$',
      caseSensitive: false,
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL (e.g., https://www.example.com)';
    }

    return null;
  }
}

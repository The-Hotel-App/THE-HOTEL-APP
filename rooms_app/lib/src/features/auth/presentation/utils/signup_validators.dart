/// Validation utilities for signup and hotel creation forms
class SignupValidators {
  /// Validates email format
  /// Returns error message if invalid, null if valid
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validates password length (minimum 6 characters)
  /// Returns error message if invalid, null if valid
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validates that confirm password matches the original password
  /// Returns error message if invalid, null if valid
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates hotel name (required, non-empty)
  /// Returns error message if invalid, null if valid
  static String? validateHotelName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Hotel name is required';
    }
    return null;
  }

  /// Validates address (required, non-empty)
  /// Returns error message if invalid, null if valid
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    return null;
  }
}

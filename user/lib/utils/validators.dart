class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validateEmailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number or email is required';
    }
    final trimmed = value.trim();
    if (trimmed.contains('@')) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(trimmed)) {
        return 'Please enter a valid email address';
      }
      return null;
    }

    final cleanPhone = trimmed.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (cleanPhone.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
      return 'Please enter a valid phone number or email';
    }
    if (cleanPhone.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 4) {
      return 'Password must be at least 4 characters long';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleanPhone = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final phoneRegex = RegExp(r'^(?:\+91)?[0-9]{10}$');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  static String? validateTxnId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Transaction ID / UTR is required';
    }
    return null;
  }
}

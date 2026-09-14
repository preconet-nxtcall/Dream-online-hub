import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/utils/validators.dart';

void main() {
  group('Phone Number Validation Tests (10 Digits Required)', () {
    test('Empty or null phone number fails validation', () {
      expect(Validators.validatePhone(null), equals('Phone number is required'));
      expect(Validators.validatePhone(''), equals('Phone number is required'));
      expect(Validators.validatePhone('   '), equals('Phone number is required'));
    });

    test('Less than 10 digits fails validation', () {
      expect(
        Validators.validatePhone('987654321'), // 9 digits
        equals('Please enter a valid 10-digit phone number'),
      );
      expect(
        Validators.validatePhone('12345'),
        equals('Please enter a valid 10-digit phone number'),
      );
    });

    test('More than 10 digits without country code fails validation', () {
      expect(
        Validators.validatePhone('987654321012'), // 12 digits
        equals('Please enter a valid 10-digit phone number'),
      );
    });

    test('Invalid non-numeric characters fail validation', () {
      expect(
        Validators.validatePhone('98765abcde'),
        equals('Please enter a valid 10-digit phone number'),
      );
    });

    test('Valid 10-digit phone number passes validation', () {
      expect(Validators.validatePhone('9876543210'), isNull);
      expect(Validators.validatePhone('8888888888'), isNull);
    });

    test('Valid 10-digit phone number with formatting spaces/dashes passes validation', () {
      expect(Validators.validatePhone('98765 43210'), isNull);
      expect(Validators.validatePhone('98765-43210'), isNull);
      expect(Validators.validatePhone('(987) 654-3210'), isNull);
    });

    test('Valid 10-digit phone number with +91 country code passes validation', () {
      expect(Validators.validatePhone('+919876543210'), isNull);
      expect(Validators.validatePhone('+91 98765 43210'), isNull);
    });
  });

  group('Email and Password Validation Baseline Tests', () {
    test('Valid email passes', () {
      expect(Validators.validateEmail('user@gmail.com'), isNull);
    });

    test('Invalid email fails', () {
      expect(Validators.validateEmail('invalid-email'), equals('Enter a valid email address'));
    });

    test('Password shorter than 4 chars fails', () {
      expect(Validators.validatePassword('123'), equals('Password must be at least 4 characters long'));
    });

    test('Valid password passes', () {
      expect(Validators.validatePassword('secret123'), isNull);
    });
  });
}

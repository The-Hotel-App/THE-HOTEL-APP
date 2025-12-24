import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:rooms/src/features/auth/presentation/utils/signup_validators.dart';

void main() {
  group('SignupValidators', () {
    // **Feature: owner-signup-flow, Property 2: Invalid email format rejected**
    group('Email Validation - Property Test', () {
      test('emails without @ are rejected', () {
        // Property: For any string that does not contain '@', validation should fail
        final random = Random(42); // Seeded for reproducibility
        
        for (int i = 0; i < 100; i++) {
          final invalidEmail = _generateStringWithout('@', random);
          final result = SignupValidators.validateEmail(invalidEmail);
          
          expect(
            result,
            isNotNull,
            reason: 'Email "$invalidEmail" should be rejected (no @ symbol)',
          );
          expect(
            result,
            equals('Please enter a valid email'),
            reason: 'Should return correct error message for invalid email',
          );
        }
      });

      test('empty email is rejected', () {
        expect(SignupValidators.validateEmail(null), 'Please enter your email');
        expect(SignupValidators.validateEmail(''), 'Please enter your email');
      });

      test('valid emails are accepted', () {
        final validEmails = [
          'test@example.com',
          'user@domain.org',
          'name@company.co.in',
          'a@b.c',
        ];
        
        for (final email in validEmails) {
          expect(
            SignupValidators.validateEmail(email),
            isNull,
            reason: 'Email "$email" should be accepted',
          );
        }
      });
    });

    // **Feature: owner-signup-flow, Property 3: Short password rejected**
    group('Password Length Validation - Property Test', () {
      test('passwords shorter than 6 characters are rejected', () {
        // Property: For any password with length < 6, validation should fail
        final random = Random(42);
        
        for (int i = 0; i < 100; i++) {
          final length = random.nextInt(6); // 0 to 5 characters
          final shortPassword = _generateRandomString(length, random);
          final result = SignupValidators.validatePassword(shortPassword);
          
          if (shortPassword.isEmpty) {
            expect(
              result,
              equals('Please enter your password'),
              reason: 'Empty password should show empty error',
            );
          } else {
            expect(
              result,
              equals('Password must be at least 6 characters'),
              reason: 'Password "$shortPassword" (length ${shortPassword.length}) should be rejected',
            );
          }
        }
      });

      test('passwords with 6 or more characters are accepted', () {
        // Property: For any password with length >= 6, validation should pass
        final random = Random(42);
        
        for (int i = 0; i < 100; i++) {
          final length = 6 + random.nextInt(20); // 6 to 25 characters
          final validPassword = _generateRandomString(length, random);
          final result = SignupValidators.validatePassword(validPassword);
          
          expect(
            result,
            isNull,
            reason: 'Password of length ${validPassword.length} should be accepted',
          );
        }
      });
    });

    // **Feature: owner-signup-flow, Property 4: Mismatched passwords rejected**
    group('Password Match Validation - Property Test', () {
      test('mismatched passwords are rejected', () {
        // Property: For any two different strings, validation should fail
        final random = Random(42);
        
        for (int i = 0; i < 100; i++) {
          final password1 = _generateRandomString(6 + random.nextInt(10), random);
          String password2;
          do {
            password2 = _generateRandomString(6 + random.nextInt(10), random);
          } while (password1 == password2);
          
          final result = SignupValidators.validateConfirmPassword(password2, password1);
          
          expect(
            result,
            equals('Passwords do not match'),
            reason: 'Mismatched passwords should be rejected',
          );
        }
      });

      test('matching passwords are accepted', () {
        final random = Random(42);
        
        for (int i = 0; i < 100; i++) {
          final password = _generateRandomString(6 + random.nextInt(10), random);
          final result = SignupValidators.validateConfirmPassword(password, password);
          
          expect(
            result,
            isNull,
            reason: 'Matching passwords should be accepted',
          );
        }
      });

      test('empty confirm password is rejected', () {
        expect(
          SignupValidators.validateConfirmPassword(null, 'password'),
          'Please confirm your password',
        );
        expect(
          SignupValidators.validateConfirmPassword('', 'password'),
          'Please confirm your password',
        );
      });
    });
  });
}

/// Generates a random string that does not contain the specified character
String _generateStringWithout(String excludeChar, Random random) {
  final length = 1 + random.nextInt(20); // 1 to 20 characters
  final chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-';
  final filteredChars = chars.replaceAll(excludeChar, '');
  
  return List.generate(
    length,
    (_) => filteredChars[random.nextInt(filteredChars.length)],
  ).join();
}

/// Generates a random alphanumeric string of the specified length
String _generateRandomString(int length, Random random) {
  if (length <= 0) return '';
  
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return List.generate(
    length,
    (_) => chars[random.nextInt(chars.length)],
  ).join();
}

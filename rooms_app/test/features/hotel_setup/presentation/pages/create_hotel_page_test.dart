import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:rooms/src/features/auth/presentation/utils/signup_validators.dart';

void main() {
  group('Hotel Creation Validation', () {
    // **Feature: owner-signup-flow, Property 5: Valid hotel data creates hotel**
    // Note: This tests the validation portion. Full creation requires integration tests.
    group('Hotel Name Validation - Property Test', () {
      test('empty hotel names are rejected', () {
        expect(
          SignupValidators.validateHotelName(null),
          'Hotel name is required',
        );
        expect(
          SignupValidators.validateHotelName(''),
          'Hotel name is required',
        );
        expect(
          SignupValidators.validateHotelName('   '),
          'Hotel name is required',
        );
      });

      test('non-empty hotel names are accepted', () {
        // Property: For any non-empty, non-whitespace string, validation should pass
        final random = Random(42);
        
        for (int i = 0; i < 100; i++) {
          final hotelName = _generateNonEmptyString(random);
          final result = SignupValidators.validateHotelName(hotelName);
          
          expect(
            result,
            isNull,
            reason: 'Hotel name "$hotelName" should be accepted',
          );
        }
      });
    });

    group('Address Validation - Property Test', () {
      test('empty addresses are rejected', () {
        expect(
          SignupValidators.validateAddress(null),
          'Address is required',
        );
        expect(
          SignupValidators.validateAddress(''),
          'Address is required',
        );
        expect(
          SignupValidators.validateAddress('   '),
          'Address is required',
        );
      });

      test('non-empty addresses are accepted', () {
        // Property: For any non-empty, non-whitespace string, validation should pass
        final random = Random(42);
        
        for (int i = 0; i < 100; i++) {
          final address = _generateNonEmptyString(random);
          final result = SignupValidators.validateAddress(address);
          
          expect(
            result,
            isNull,
            reason: 'Address "$address" should be accepted',
          );
        }
      });
    });
  });
}

/// Generates a random non-empty string with at least one non-whitespace character
String _generateNonEmptyString(Random random) {
  final length = 1 + random.nextInt(50); // 1 to 50 characters
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,';
  
  // Ensure at least one non-whitespace character
  final result = List.generate(
    length,
    (_) => chars[random.nextInt(chars.length)],
  ).join();
  
  // If all whitespace, add a character
  if (result.trim().isEmpty) {
    return 'a$result';
  }
  
  return result;
}

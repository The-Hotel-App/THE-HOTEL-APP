import 'package:flutter_test/flutter_test.dart';
import 'package:rooms/src/core/error/exceptions.dart';
import 'package:rooms/src/core/error/failures.dart';

void main() {
  group('Failures', () {
    test('ServerFailure has correct properties', () {
      const failure = ServerFailure(message: 'Server error', code: '500');

      expect(failure.message, 'Server error');
      expect(failure.code, '500');
    });

    test('AuthFailure has correct properties', () {
      const failure = AuthFailure(
        message: 'Invalid credentials',
        code: 'AUTH_INVALID',
      );

      expect(failure.message, 'Invalid credentials');
      expect(failure.code, 'AUTH_INVALID');
    });

    test('NetworkFailure has default message', () {
      const failure = NetworkFailure();

      expect(failure.message, 'No internet connection');
      expect(failure.code, 'NETWORK_ERROR');
    });

    test('ValidationFailure can include field errors', () {
      const failure = ValidationFailure(
        message: 'Validation failed',
        fieldErrors: {
          'email': 'Invalid email format',
          'password': 'Password too short',
        },
      );

      expect(failure.fieldErrors?['email'], 'Invalid email format');
      expect(failure.fieldErrors?['password'], 'Password too short');
    });

    test('PermissionFailure has default message', () {
      const failure = PermissionFailure();

      expect(
        failure.message,
        'You do not have permission to perform this action',
      );
    });
  });

  group('Exceptions', () {
    test('ServerException has statusCode', () {
      const exception = ServerException(
        message: 'Internal server error',
        statusCode: 500,
      );

      expect(exception.message, 'Internal server error');
      expect(exception.statusCode, 500);
    });

    test('AuthException has correct properties', () {
      const exception = AuthException(
        message: 'Session expired',
        code: 'SESSION_EXPIRED',
      );

      expect(exception.message, 'Session expired');
      expect(exception.code, 'SESSION_EXPIRED');
    });

    test('ValidationException can include field errors', () {
      const exception = ValidationException(
        message: 'Validation failed',
        fieldErrors: {'name': 'Name is required'},
      );

      expect(exception.fieldErrors?['name'], 'Name is required');
    });
  });
}

/// Base failure class for error handling
abstract class Failure {
  final String message;
  final String? code;
  final dynamic originalError;

  const Failure({required this.message, this.code, this.originalError});

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

/// Server/Network related failures
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Cache/Local storage failures
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code, super.originalError});
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code, super.originalError});
}

/// Validation failures
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    super.code,
    super.originalError,
    this.fieldErrors,
  });
}

/// Network connection failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection',
    super.code = 'NETWORK_ERROR',
    super.originalError,
  });
}

/// Permission/Authorization failures
class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'You do not have permission to perform this action',
    super.code = 'PERMISSION_DENIED',
    super.originalError,
  });
}

/// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'Resource not found',
    super.code = 'NOT_FOUND',
    super.originalError,
  });
}

/// Biometric failures
class BiometricFailure extends Failure {
  const BiometricFailure({
    required super.message,
    super.code = 'BIOMETRIC_ERROR',
    super.originalError,
  });
}

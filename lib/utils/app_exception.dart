/// An error with a message that is safe to show to the user.
class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Raised when a searched place does not exist.
class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

String friendlyError(Object? error) =>
    error is AppException ? error.message : 'Something went wrong. Please try again.';

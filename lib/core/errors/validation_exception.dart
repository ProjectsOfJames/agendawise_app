/// Thrown by repositories when input breaks a rule before it reaches the database.
class ValidationException implements Exception {
  const ValidationException(this.message);

  final String message;

  @override
  String toString() => 'ValidationException: $message';
}

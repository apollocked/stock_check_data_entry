enum AppExceptionType { network, storage, database }

class AppException implements Exception {
  /// Short text that is safe to show to the user.
  final String message;
  final AppExceptionType type;

  /// The original error, kept for logs only.
  final Object? cause;

  const AppException(
    this.message, [
    this.type = AppExceptionType.database,
    this.cause,
  ]);

  @override
  String toString() => message;
}

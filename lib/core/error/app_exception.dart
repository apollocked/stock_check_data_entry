enum AppExceptionType { network, storage, database }

class AppException implements Exception {
  final String message;
  final AppExceptionType type;

  const AppException(this.message, [this.type = AppExceptionType.database]);

  @override
  String toString() => message;
}

sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

final class DataException extends AppException {
  const DataException(super.message, {super.cause});
}

final class AuthenticationException extends AppException {
  const AuthenticationException(super.message, {super.cause});
}

final class ValidationException extends AppException {
  const ValidationException(super.message);
}

final class ConnectivityException extends AppException {
  const ConnectivityException(
      [super.message = 'Sem conexao. Tente novamente quando estiver online.']);
}

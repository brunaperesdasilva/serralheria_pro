import 'app_exception.dart';

abstract final class ErrorMessage {
  static String from(Object error) {
    if (error is AppException) return error.message;
    return 'Nao foi possivel concluir a operacao. Tente novamente.';
  }
}

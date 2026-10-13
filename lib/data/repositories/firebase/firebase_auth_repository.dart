import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/app_exception.dart';
import '../../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);
  final FirebaseAuth _auth;

  @override
  Stream<bool> get authenticationState =>
      _auth.authStateChanges().map((user) => user != null);
  @override
  bool get isAuthenticated => _auth.currentUser != null;
  @override
  String? get userId => _auth.currentUser?.uid;
  @override
  String? get email => _auth.currentUser?.email;

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(() => _auth.signInWithEmailAndPassword(
            email: _normalizeEmail(email),
            password: password,
          ));

  @override
  Future<void> register({required String email, required String password}) =>
      _guard(() => _auth.createUserWithEmailAndPassword(
            email: _normalizeEmail(email),
            password: password,
          ));

  @override
  Future<void> sendPasswordResetEmail(String email) => _guard(() async {
        await _auth.setLanguageCode('pt-BR');
        await _auth.sendPasswordResetEmail(email: _normalizeEmail(email));
        return null;
      });

  @override
  Future<void> signOut() => _auth.signOut();

  Future<void> _guard(Future<Object?> Function() operation) async {
    try {
      await operation();
    } on FirebaseAuthException catch (error) {
      throw AuthenticationException(_messageFor(error.code), cause: error);
    }
  }

  static String _messageFor(String code) => switch (code) {
        'invalid-email' => 'Informe um e-mail valido.',
        'invalid-credential' ||
        'user-not-found' ||
        'wrong-password' =>
          'E-mail ou senha incorretos.',
        'email-already-in-use' => 'Este e-mail ja esta cadastrado.',
        'user-disabled' => 'Esta conta foi desativada.',
        'weak-password' => 'Use uma senha mais forte.',
        'too-many-requests' =>
          'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
        'network-request-failed' =>
          'Sem conexao com a internet. Verifique sua rede.',
        'operation-not-allowed' =>
          'Login por e-mail ainda nao foi habilitado no Firebase.',
        _ => 'Nao foi possivel autenticar. Tente novamente.',
      };

  static String _normalizeEmail(String value) => value.trim().toLowerCase();
}

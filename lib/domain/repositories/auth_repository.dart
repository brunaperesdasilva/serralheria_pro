abstract interface class AuthRepository {
  Stream<bool> get authenticationState;
  bool get isAuthenticated;
  String? get userId;
  String? get email;
  Future<void> signIn({required String email, required String password});
  Future<void> register({required String email, required String password});
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
}

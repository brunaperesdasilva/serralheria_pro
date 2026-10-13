import 'package:firebase_auth/firebase_auth.dart';

import '../data/repositories/firebase/firebase_auth_repository.dart';
import '../domain/repositories/auth_repository.dart';

abstract final class AppAuth {
  static AuthRepository repository =
      FirebaseAuthRepository(FirebaseAuth.instance);
}

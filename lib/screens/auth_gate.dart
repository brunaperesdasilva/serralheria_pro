import 'package:flutter/material.dart';

import '../core/app_auth.dart';
import '../core/widgets/app_state_view.dart';
import '../data/cloud_data_bootstrap.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<void>? _initialization;
  String? _initializingUserId;

  Future<void> _initialize(String userId) {
    if (_initializingUserId != userId || _initialization == null) {
      _initializingUserId = userId;
      _initialization = CloudDataBootstrap.initialize(userId);
    }
    return _initialization!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: AppAuth.repository.authenticationState,
      initialData: AppAuth.repository.isAuthenticated,
      builder: (context, authSnapshot) {
        final userId = AppAuth.repository.userId;
        if (authSnapshot.data != true || userId == null) {
          return const LoginScreen();
        }
        return FutureBuilder<void>(
          future: _initialize(userId),
          builder: (context, cloudSnapshot) {
            if (cloudSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                  body: AppLoadingView(message: 'Sincronizando seus dados...'));
            }
            if (cloudSnapshot.hasError) {
              return Scaffold(
                body: AppStateView.error(
                  title: 'Não foi possível sincronizar os dados',
                  message: 'Verifique sua conexão e tente novamente.',
                  onAction: () => setState(() {
                    CloudDataBootstrap.reset();
                    _initialization = null;
                  }),
                ),
              );
            }
            return const MainScreen();
          },
        );
      },
    );
  }
}

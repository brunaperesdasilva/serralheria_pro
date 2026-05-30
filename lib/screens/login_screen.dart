import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usuarioController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  bool ocultarSenha = true;
  String mensagemErro = '';

  void realizarLogin() {
    final usuario = usuarioController.text.trim();
    final senha = senhaController.text.trim();

    if (usuario == 'admin' && senha == '1234') {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      setState(() {
        mensagemErro = 'Usuário ou senha inválidos.';
      });
    }
  }

  @override
  void dispose() {
    usuarioController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 210,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Bem-vindo',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.graphite,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Acesse sua conta para continuar',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.darkGray,
                        ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: usuarioController,
                    decoration: const InputDecoration(
                      labelText: 'Usuário',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: senhaController,
                    obscureText: ocultarSenha,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            ocultarSenha = !ocultarSenha;
                          });
                        },
                        icon: Icon(
                          ocultarSenha
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  if (mensagemErro.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      mensagemErro,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: realizarLogin,
                    child: const Text('Entrar'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      usuarioController.text = 'admin';
                      senhaController.text = '1234';

                      setState(() {
                        mensagemErro = '';
                      });
                    },
                    child: const Text(
                      'Usar acesso de teste',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
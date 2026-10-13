import 'package:flutter/material.dart';

import '../core/app_auth.dart';
import '../core/app_colors.dart';
import '../core/errors/error_message.dart';
import '../core/validation/form_validators.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final userController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;

  void login() async {
    final user = userController.text.trim();
    final pass = passwordController.text;

    if (!(formKey.currentState?.validate() ?? false)) return;

    setState(() {
      isLoading = true;
    });

    try {
      await AppAuth.repository.signIn(email: user, password: pass);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMessage.from(error))),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> resetPassword() async {
    final email = userController.text.trim();
    final validationError = FormValidators.email(email);
    if (validationError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }
    try {
      await AppAuth.repository.sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(
            'Se existir uma conta para $email, o Firebase enviará as instruções. Verifique também spam e lixo eletrônico.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMessage.from(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.lightGray),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 128,
                    ),
                    const SizedBox(height: 24),
                    Text('Bem-vindo',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    const Text(
                      'Acesse sua empresa para continuar',
                      style: TextStyle(color: AppColors.darkGray),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: userController,
                      validator: FormValidators.email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      validator: FormValidators.password,
                      obscureText: obscurePassword,
                      onFieldSubmitted: (_) => isLoading ? null : login(),
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: obscurePassword
                              ? 'Mostrar senha'
                              : 'Ocultar senha',
                          onPressed: () => setState(
                              () => obscurePassword = !obscurePassword),
                          icon: Icon(obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading ? null : resetPassword,
                        child: const Text('Esqueci minha senha'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: AppColors.white)
                            : const Text('Entrar'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Não tem conta? Cadastre-se',
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
      ),
    );
  }
}

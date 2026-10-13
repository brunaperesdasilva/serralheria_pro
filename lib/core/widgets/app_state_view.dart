import 'package:flutter/material.dart';

import '../app_colors.dart';

class AppStateView extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  const AppStateView.empty({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  })  : icon = Icons.inbox_outlined,
        isError = false;

  const AppStateView.error({
    super.key,
    this.title = 'Não foi possível carregar',
    this.message,
    this.actionLabel = 'Tentar novamente',
    this.onAction,
  })  : icon = Icons.error_outline,
        isError = true;

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Semantics(
            container: true,
            label: '$title${message == null ? '' : '. $message'}',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon,
                    size: 58,
                    color: isError ? AppColors.danger : AppColors.darkGray),
                const SizedBox(height: 16),
                Text(title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.darkGray)),
                ],
                if (onAction != null && actionLabel != null) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 240,
                    child: ElevatedButton(
                        onPressed: onAction, child: Text(actionLabel!)),
                  ),
                ],
              ]),
            ),
          ),
        ),
      );
}

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message = 'Carregando...'});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Semantics(
          liveRegion: true,
          label: message,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(message),
          ]),
        ),
      );
}

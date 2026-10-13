import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final double? minHeight;

  const AppCard({
    super.key,
    required this.child,
    this.margin,
    this.padding = const EdgeInsets.all(20),
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      constraints: minHeight == null
          ? null
          : BoxConstraints(
              minHeight: minHeight!,
            ),
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF18181B).withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    if (margin == null) {
      return card;
    }

    return Padding(
      padding: margin!,
      child: card,
    );
  }
}

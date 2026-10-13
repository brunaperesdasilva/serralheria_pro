import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../app_colors.dart';

class CompanyAvatar extends StatelessWidget {
  const CompanyAvatar({
    super.key,
    required this.logoBase64,
    required this.fallback,
    this.radius = 50,
  });

  final String? logoBase64;
  final String fallback;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeLogo();
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.8),
          width: radius >= 40 ? 3 : 1.5,
        ),
        boxShadow: radius >= 40
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: bytes == null
            ? ColoredBox(
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Center(
                  child: Text(
                    fallback,
                    style: TextStyle(
                      fontSize: radius * 0.65,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
            : Image.memory(
                bytes,
                fit: BoxFit.cover,
                width: radius * 2,
                height: radius * 2,
                gaplessPlayback: true,
              ),
      ),
    );
  }

  Uint8List? _decodeLogo() {
    final encoded = logoBase64;
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }
}

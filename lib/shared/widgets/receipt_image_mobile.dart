import 'dart:io';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class ReceiptImage extends StatelessWidget {
  final String path;
  final double height;
  const ReceiptImage({super.key, required this.path, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(path),
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        color: AppColors.bgTertiary,
        child: const Center(
          child: Icon(Icons.image_not_supported,
              size: 40, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

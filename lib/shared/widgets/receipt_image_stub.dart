import 'package:flutter/material.dart';

class ReceiptImage extends StatelessWidget {
  final String path;
  final double height;
  const ReceiptImage({super.key, required this.path, this.height = 200});

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: height, width: double.infinity);
}

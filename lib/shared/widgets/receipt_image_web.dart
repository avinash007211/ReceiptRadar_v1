import 'package:flutter/material.dart';

/// Web has no scanned receipt images (camera not supported).
/// This always returns an empty SizedBox of the requested height.
class ReceiptImage extends StatelessWidget {
  final String path;
  final double height;
  const ReceiptImage({super.key, required this.path, this.height = 200});

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 0, width: double.infinity);
}

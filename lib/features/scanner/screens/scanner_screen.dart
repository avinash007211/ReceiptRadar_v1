import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/receipt_parser.dart';
import '../../../core/services/receipt_store.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitializing = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'No cameras found on this device.';
        });
        return;
      }

      final rearCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        rearCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Camera error: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final tmpImage = await _controller!.takePicture();
      final savedPath = await _saveImage(tmpImage.path);
      await _processImage(savedPath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        setState(() => _isProcessing = false);
        return;
      }
      final savedPath = await _saveImage(picked.path);
      await _processImage(savedPath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isProcessing = false);
    }
  }

  Future<String> _saveImage(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final destPath = p.join(dir.path, 'receipts', 'receipt_$ts.jpg');
    final destFile = File(destPath);
    await destFile.parent.create(recursive: true);
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  Future<void> _processImage(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(inputImage);
      final ocrText = result.text;

      // Parse into structured receipt
      final receipt = ReceiptParser.parse(ocrText).copyWith(imagePath: imagePath);

      // Save to store
      await ref.read(receiptsProvider.notifier).add(receipt);

      if (!mounted) return;
      // Navigate to review screen
      context.pushReplacement('${AppRoutes.review}?id=${receipt.id}');
    } finally {
      await recognizer.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isInitializing)
            const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          else if (_errorMessage != null)
            _errorView()
          else if (_controller != null && _controller!.value.isInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.previewSize!.height,
                  height: _controller!.value.previewSize!.width,
                  child: CameraPreview(_controller!),
                ),
              ),
            ),

          // Corner overlay
          const Positioned.fill(child: _CornerOverlay()),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.close,
                    onTap: () => context.pop(),
                  ),
                  const Spacer(),
                  _RoundIconButton(
                    icon: Icons.photo_library_outlined,
                    onTap: _pickFromGallery,
                  ),
                ],
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 180,
            left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Fit the receipt inside the frame',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: Colors.white),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
          ),

          // Capture button
          Positioned(
            bottom: 48,
            left: 0, right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _isProcessing ? null : _captureAndProcess,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: Center(
                    child: _isProcessing
                        ? const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Container(
                            width: 62,
                            height: 62,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ).animate().scale(
                    delay: 200.ms,
                    curve: Curves.elasticOut,
                  ),
            ),
          ),

          // Processing overlay
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.bgDark,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Reading receipt...',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'AI is extracting the details',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Pick from Gallery instead'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _CornerOverlay extends StatelessWidget {
  const _CornerOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CornerPainter(),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const margin = 40.0;
    final top = size.height * 0.18;
    final bottom = size.height * 0.70;
    const cornerLen = 32.0;

    // Top-left
    canvas.drawLine(
        Offset(margin, top),
        Offset(margin + cornerLen, top), paint);
    canvas.drawLine(
        Offset(margin, top),
        Offset(margin, top + cornerLen), paint);
    // Top-right
    canvas.drawLine(
        Offset(size.width - margin, top),
        Offset(size.width - margin - cornerLen, top), paint);
    canvas.drawLine(
        Offset(size.width - margin, top),
        Offset(size.width - margin, top + cornerLen), paint);
    // Bottom-left
    canvas.drawLine(
        Offset(margin, bottom),
        Offset(margin + cornerLen, bottom), paint);
    canvas.drawLine(
        Offset(margin, bottom),
        Offset(margin, bottom - cornerLen), paint);
    // Bottom-right
    canvas.drawLine(
        Offset(size.width - margin, bottom),
        Offset(size.width - margin - cornerLen, bottom), paint);
    canvas.drawLine(
        Offset(size.width - margin, bottom),
        Offset(size.width - margin, bottom - cornerLen), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter _) => false;
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../core/constants/app_constants.dart';
import '../core/models/detection.dart';
import '../core/services/ml_model_service.dart';
import '../core/services/waste_detector.dart';

class PreviewPage extends StatefulWidget {
  final String imagePath;
  const PreviewPage({super.key, required this.imagePath});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  bool _isRecognizing = false;
  bool _showSuccessAnimation = false;

  List<Detection> _detections = [];

  Future<void> _recognizeWaste() async {
    if (_isRecognizing) return;

    setState(() {
      _isRecognizing = true;
      _detections = [];
    });

    try {
      // Model yüklü değilse yükle
      if (!MlModelService.instance.isLoaded ||
          MlModelService.instance.loadedTask != ModelTask.detect) {
        await WasteDetector.instance.loadDetectModel();
      }

      final dets = await WasteDetector.instance.predictDetections(
        widget.imagePath,
      );

      if (!mounted) return;

      setState(() {
        _detections = dets;
        _showSuccessAnimation = dets.isNotEmpty;
      });

      if (dets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Herhangi bir atık tespit edilemedi")),
        );
      }

      if (_showSuccessAnimation) {
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() => _showSuccessAnimation = false);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Tanıma hatası: $e")));
    } finally {
      if (!mounted) return;
      setState(() => _isRecognizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Önizleme')),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // ✅ Görsel + BBox overlay (640x640 referans)
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1, // 640x640 ile eşleşsin
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.cover, // kare alana otursun
                            ),
                          ),
                          CustomPaint(painter: _BoxPainter(_detections)),
                        ],
                      ),
                    ),
                  ),
                ),

                // Alt panel
                Container(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (_detections.isNotEmpty)
                        Text(
                          "Tespit: ${_detections.length} nesne",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      else if (!_isRecognizing)
                        const Text(
                          "Henüz sonuç yok",
                          style: TextStyle(color: Colors.grey),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isRecognizing ? null : _recognizeWaste,
                          icon: _isRecognizing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.analytics),
                          label: Text(
                            _isRecognizing ? 'Tanınıyor...' : 'Atık Tanı',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_showSuccessAnimation)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Lottie.asset(
                    AppConstants.doneAnimationPath,
                    fit: BoxFit.contain,
                    repeat: false,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BoxPainter extends CustomPainter {
  final List<Detection> dets;
  _BoxPainter(this.dets);

  @override
  void paint(Canvas canvas, Size size) {
    // Size = kare alan; bunu 640 referansına ölçekle
    final sx = size.width / 640.0;
    final sy = size.height / 640.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );

    for (final d in dets) {
      final rect = Rect.fromLTRB(
        d.box.left * sx,
        d.box.top * sy,
        d.box.right * sx,
        d.box.bottom * sy,
      );

      // basit renk: confidence’a göre (çok uğraşmadan sabit)
      paint.color = Colors.greenAccent;

      canvas.drawRect(rect, paint);

      final label = "${d.label} ${(d.confidence * 100).toStringAsFixed(1)}%";

      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black54,
        ),
      );
      textPainter.layout();

      final offset = Offset(rect.left, (rect.top - 16).clamp(0.0, size.height));
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant _BoxPainter oldDelegate) {
    return oldDelegate.dets != dets;
  }
}

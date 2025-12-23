import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../core/constants/app_constants.dart';
import '../core/models/waste_item.dart';

/// Fotoğraf önizleme sayfası
class PreviewPage extends StatefulWidget {
  final String imagePath;

  const PreviewPage({super.key, required this.imagePath});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  bool _isRecognizing = false;
  bool _showSuccessAnimation = false;
  WasteType? _recognizedWasteType;
  double _confidence = 0.0;

  /// Atık tanıma işlemini başlatır
  void _recognizeWaste() {
    setState(() {
      _isRecognizing = true;
      _recognizedWasteType = null;
      _confidence = 0.0;
    });

    // Simüle edilmiş tanıma işlemi (2 saniye)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Rastgele bir atık türü ve güven skoru seç (simülasyon için)
        final random = Random();
        final wasteTypes = WasteType.values;
        final randomType = wasteTypes[random.nextInt(wasteTypes.length)];
        final randomConfidence = 0.75 + (random.nextDouble() * 0.24);

        setState(() {
          _isRecognizing = false;
          _showSuccessAnimation = true;
          _recognizedWasteType = randomType;
          _confidence = randomConfidence;
        });

        // Animasyonu 2 saniye sonra gizle
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showSuccessAnimation = false;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Önizleme'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Bilgi'),
                  content: const Text(
                    'Fotoğrafınızı çektikten sonra "Atık Tanı" butonuna basarak atık türünü öğrenebilirsiniz.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Tamam'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Görüntü Önizleme
                Expanded(
                  child: Center(
                    child: Hero(
                      tag: 'preview_image',
                      child: Container(
                        margin: const EdgeInsets.all(AppConstants.defaultPadding),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Sonuç Kartı ve Aksiyon Butonları
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
                      // Sonuç Kartı
                      if (_recognizedWasteType != null)
                        _ResultCard(
                          wasteType: _recognizedWasteType!,
                          confidence: _confidence,
                        ),
                      if (_recognizedWasteType != null)
                        const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Yeni Fotoğraf Çek'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
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
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.analytics),
                          label: Text(_isRecognizing ? 'Tanınıyor...' : 'Atık Tanı'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Başarı Animasyonu Overlay
          if (_showSuccessAnimation)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: Lottie.asset(
                        AppConstants.doneAnimationPath,
                        fit: BoxFit.contain,
                        repeat: false,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Atık Başarıyla Tanındı!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget لعرض نتائج التعرف على النفايات
class _ResultCard extends StatelessWidget {
  final WasteType wasteType;
  final double confidence;

  const _ResultCard({
    required this.wasteType,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final ui = WasteUi.of(wasteType);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ui.dialogColor,
            ui.dialogColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ui.dialogColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Başlık
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Tanıma Başarılı!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Atık Türü
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(ui.icon, color: ui.iconColor, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Atık Türü:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ui.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Güven Skoru
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Güven Skoru:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${(confidence * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: confidence,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Bilgi Mesajı
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white70, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getWasteAdvice(wasteType),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getWasteAdvice(WasteType type) {
    switch (type) {
      case WasteType.glass:
        return 'Cam atıkları geri dönüşüm kutusuna atın. Temiz ve kırılmamış cam en iyisidir.';
      case WasteType.paper:
        return 'Kağıt atıkları kuru tutun ve geri dönüşüm kutusuna atın. Kirli kağıtlar geri dönüştürülemez.';
      case WasteType.metal:
        return 'Metal atıkları geri dönüşüm kutusuna atın. Alüminyum kutular değerlidir.';
      case WasteType.organic:
        return 'Organik atıkları kompost kutusuna atın veya organik çöp kutusuna bırakın.';
      case WasteType.plastic:
        return 'Plastik atıkları geri dönüşüm kutusuna atın. Temiz plastikler en iyisidir.';
    }
  }
}
